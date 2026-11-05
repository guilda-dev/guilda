classdef local_LQR < LocalController
% State-feedback LQR controller of one component.
% The controller observes all the state variables `x` of the component it is attached to
% (the reserved input signal name "Xall") and drives the inputs `Input` of the component
% (by name, e.g. "Vfield" [pu] or "Pmech" [pu]; all its inputs by default):
%
% ```
% u = u* - K*(x - x*)
% ```
%
% where `x*` and `u*` are the equilibrium of the component. It has no state of
% its own. `net.initialize` computes the gain `K = lqr(A, B, Q, R)` from the
% linear model of the component (`comp.get_sys` without its controllers)
% connected to an infinite bus of voltage `V0` [pu] through the admittance that
% gives the equilibrium current (as in GUILDA v2). A network Hz edit keeps the
% equilibrium, so the edit redesigns `K` at that equilibrium without `net.initialize`.
%
% Attach it with `comp.add_local_controller(lqr)`; it takes the place of an AVR
% (and of the PSS attached to that AVR). The output of a global controller (e.g. an
% AGC) on a driven input adds to its output, and the design of `K` does not take it
% into account (use `Input="Vfield"` with an AGC on Pmech to keep them apart).
%
% <@Examples>
% Attach LQR controllers to two generators and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% net.a_Bus{1}.a_Component{1}.add_local_controller(controller.local_LQR("lqr1"));
% net.a_Bus{2}.a_Component{1}.add_local_controller(controller.local_LQR("lqr2", Input="Vfield", R=2));
% net.initialize;
% sc  = Scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% net.add_scenario(sc);
% sol = net.simulate([0,10], sc);
% ```
%
% See also Component.add_local_controller, controller.avr.abstract, controller.local_LQR_retrofit

    properties (SetAccess=protected, Hidden) % Signals
        key     = "local"           % Controller kind ("local": in the place of an AVR).
        sv_x    = strings(0,1)      % Names of the controller states (none).
        sv_u    = "Xall"            % Names of the observed signals ("Xall": all the states of the component).
        sv_y    = strings(0,1)      % Names of the driven inputs of the component.
        sv_para = strings(0,1)      % Names of the parameters (none).
    end

    properties % Design weights
        % State weight of the LQR.
        % An nx-by-nx matrix for the states of the component; a vector is its
        % diagonal (empty: identity). Editing it makes the equilibrium stale;
        % net.initialize recomputes K.
        Q = []
        % Input weight of the LQR.
        % An nu-by-nu matrix for the driven inputs; a vector is its diagonal
        % (empty: identity). Editing it makes the equilibrium stale;
        % net.initialize recomputes K.
        R = []
        % [pu] Voltage of the infinite bus of the design model.
        % A complex scalar.
        V0 = 1
    end

    properties (SetAccess=private) % Design results
        % Feedback gain `K` in `u = u* - K*(x - x*)`.
        % An nu-by-nx matrix computed by net.initialize and, after a network Hz edit,
        % by the next analysis when the equilibrium is up to date.
        K = zeros(0,0)
        % Linear model used to compute K (ss).
        % The component connected to the infinite bus; its inputs are the driven
        % inputs and its outputs the states.
        sys_design
    end

    properties (Access=private) % Internal
        sv_input (:,1) string = strings(0,1)   % Input as given (empty: all the inputs)
        rv_u0    (:,1) double = zeros(0,1)     % equilibrium of the driven inputs
        r_designHz double = []                 % [Hz] frequency K was designed for (empty: not designed)
    end

    methods
        function obj = local_LQR(tag, opt)
        % Create a state-feedback LQR controller with the tag "CL" + tag.
            arguments (Input)
                tag        (1,1) string                 % Tag suffix; the controller tag is "CL" + tag.
                opt.Q      double = []                  % State weight: nx-by-nx matrix or its diagonal (default: identity).
                opt.R      double = []                  % Input weight: nu-by-nu matrix or its diagonal (default: identity).
                opt.Input  (:,1) string = strings(0,1)  % Names of the inputs of the component to drive (default: all).
                opt.V0     (1,1) double = 1             % [pu] Infinite-bus voltage of the design model (complex).
            end
            arguments (Output)
                obj % local_LQR object.
            end
            obj@LocalController("CL"+tag)
            obj.sv_input = opt.Input;
            obj.sv_y     = opt.Input;
            obj.Q  = opt.Q;
            obj.R  = opt.R;
            obj.V0 = opt.V0;
        end

        function set.Q(obj, val)
            obj.Q = weight(val, "Q");
            obj.log_change("Q");
        end
        function set.R(obj, val)
            obj.R = weight(val, "R");
            obj.log_change("R");
        end
        function set.V0(obj, val)
            obj.V0 = val;
            obj.log_change("V0");
        end

        function get_equilibrium(obj, V, u)
            % Set the equilibrium of the controller and design the gain K.
            % The component calls this after its equilibrium is set: the observed
            % signals of the controller are the states `x*` and its outputs the
            % driven inputs `u*` of the component.
            arguments (Input)
                obj
                V  % [pu] Complex terminal voltage of the component at the equilibrium.
                u  % Equilibrium input of the component (in the order of its sv_u).
            end
            comp = obj.a_Component;
            if ~isa(comp, "Component")
                error(msg("GUILDA:local_LQR:NotOnComponent", obj.str_tag))
            end
            [~, iv_u] = ismember(obj.sv_y, comp.sv_u);

            obj.rv_Xequilibrium = zeros(0,1);
            obj.rv_Uequilibrium = comp.rv_Xequilibrium;
            obj.rv_u0 = u(iv_u);
            obj.design_gain(V, u);
            obj.set_odefcn()
        end
    end

    methods (Hidden)
        function sv_in = driven_inputs(obj, comp)
            % The driven inputs on the component comp: Input, or all the inputs of comp
            arguments (Input)
                obj
                comp  Component  % Component the controller is attached to.
            end
            arguments (Output)
                sv_in  % Names of the driven inputs on comp.
            end
            if isempty(obj.sv_input)
                sv_in = reshape(string(comp.sv_u), [], 1);
            else
                sv_in = obj.sv_input;   % checked by Component.add_local_controller
            end
        end
    end

    methods (Access=protected)
        function resolve_ports(obj, comp)
            % The driven inputs: Input, or all the inputs of the component
            arguments (Input)
                obj
                comp  Component  % Component the controller is attached to.
            end
            obj.sv_y = obj.driven_inputs(comp);
        end

        function set_inputs(obj, sv_name)
            arguments (Input)
                obj
                sv_name  % Names of the observed signals.
            end
            obj.sv_u = sv_name;
        end

        function set_odefcn(obj)
            % Called by check_edit when the handles are not up to date (str_odefcn "unset" or
            % "editted": a dynamics edit, a network Hz edit or an attach since the last build).
            % A Hz edit keeps the equilibrium, so K is redesigned here, at the first analysis
            % after the edit (check_edit has already built the component, the parent). When
            % the equilibrium is not up to date, net.initialize redesigns K instead.
            arguments (Input)
                obj
            end
            omega0 = obj.get_Hz();
            if ~isempty(obj.r_designHz) && obj.r_designHz ~= omega0 && obj.equilibrium_valid()
                try
                    obj.design_gain(obj.a_Component.c_Vequilibrium, obj.a_Component.rv_Uequilibrium);
                catch ME
                    % A warning, not an error: check_edit goes on to build the other layers.
                    % K stays for the old frequency, so the record makes the equilibrium stale
                    % and the analysis that runs check_edit asks for net.initialize.
                    warning(msg("GUILDA:local_LQR:RedesignFailed", obj.str_tag, sprintf("%g", omega0), ME.message))
                    obj.log_edit(obj.str_tag + " redesign failed", "Parameter(dynamics)");
                end
            end

            % u = u* - K (x - x*); before net.initialize the gain is zero
            nu = numel(obj.sv_y);
            nx = numel(obj.sv_u);
            param.K  = zeros(nu, nx);
            param.x0 = zeros(nx, 1);
            param.u0 = zeros(nu, 1);
            if isequal(size(obj.K), [nu nx]) && numel(obj.rv_Uequilibrium) == nx && numel(obj.rv_u0) == nu
                param.K  = obj.K;
                param.x0 = obj.rv_Uequilibrium;
                param.u0 = obj.rv_u0;
            end
            obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, param, omega0);
            obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, param, omega0);
            obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t, x, V, I, u, param, omega0);
            obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
            obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
            obj.s_edit.str_odefcn = "updated";
        end
    end

    methods (Access=private)
        function design_gain(obj, V, u)
            % Design K at the equilibrium of the component; the caller builds the handles.
            arguments (Input)
                obj
                V  % [pu] Complex terminal voltage of the component at the equilibrium.
                u  % Equilibrium input of the component (in the order of its sv_u).
            end
            comp = obj.a_Component;
            x0 = comp.rv_Xequilibrium;
            I0 = comp.c_Iequilibrium;
            [~, iv_u] = ismember(obj.sv_y, comp.sv_u);

            % Design model: the component connected to the infinite bus V0 through the
            % admittance y = I*/(V* - V0), so that dI = y dV
            if abs(V - obj.V0) < 1e-9
                error(msg("GUILDA:local_LQR:DesignModel", obj.str_tag, sprintf("%g", obj.V0)))
            end
            y_inf = tools.complex2matrix(I0 / (V - obj.V0));
            sys   = comp.get_sys_alone(x0, [real(V); imag(V)], [real(I0); imag(I0)], u);
            [A, B, C, D, E] = dssdata(sys);
            Bv = B(:,1:2);   Bu = B(:,2+iv_u);
            Dv = D(:,1:2);   Du = D(:,2+iv_u);
            M  = y_inf - Dv;            % (y - Dv) dV = C dx + Du du
            A  = E \ (A + Bv * (M \ C));
            Bu = E \ (Bu + Bv * (M \ Du));
            obj.sys_design = ss(A, Bu, eye(size(A)), 0, ...
                                'StateName', cellstr(comp.sv_x), 'InputName', cellstr(obj.sv_y), 'OutputName', cellstr(comp.sv_x));

            nx = numel(x0);  nu = numel(iv_u);
            Qw = obj.Q;  if isempty(Qw); Qw = eye(nx); end
            Rw = obj.R;  if isempty(Rw); Rw = eye(nu); end
            if ~isequal(size(Qw), [nx nx]) || ~isequal(size(Rw), [nu nu])
                error(msg("GUILDA:local_LQR:WeightSize", obj.str_tag, string(nx), string(nx), join(comp.sv_x, ","), string(nu), string(nu), join(obj.sv_y, ",")))
            end
            obj.K = lqr(A, Bu, Qw, Rw);
            obj.r_designHz = obj.get_Hz();
        end

        function l = equilibrium_valid(obj)
            % True when the component is in a network whose equilibrium is up to date
            arguments (Input)
                obj
            end
            arguments (Output)
                l  % True when the equilibrium of the network is up to date.
            end
            comp = obj.a_Component;
            if isempty(comp) || isempty(comp.a_Bus) || isempty(comp.a_Bus.a_PowerNetwork)
                l = false;
            else
                s = comp.a_Bus.a_PowerNetwork.s_edit;
                l = s.str_flag ~= "unset" && ~s.l_staleEquilibrium;
            end
        end

        function log_change(obj, str_name)
            % A weight edit changes K, which net.initialize recomputes
            arguments (Input)
                obj
                str_name  % Name of the edited weight.
            end
            if ~isempty(obj.a_Component)
                obj.log_edit(obj.str_tag + " edit " + str_name, "Parameter(dynamics)");
            end
        end
    end

    methods (Static)
        function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok
            % State equation of the controller (no state).
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                dx  % Empty state derivative (0-by-1).
            end
            dx = zeros(0,1);
        end
        function y = fcn_y(t, x, V, I, u, param, omega0) %#ok
            % Output equation `y = u* - K*(u - x*)`, where `u` is the observed state of the component.
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Observed states `x` of the component.
                param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                y  % Driven inputs of the component.
            end
            y = param.u0 - param.K * (u - param.x0);
        end
        function M = fcn_Mass(t, x, V, I, u, param, omega0) %#ok
            % Mass matrix of the controller (no state).
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                M  % Empty mass matrix (0-by-0).
            end
            M = zeros(0,0);
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0) %#ok
            % Jacobian of the state equation (empty: no state).
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                Axx  % Empty Jacobian with respect to x (0-by-0).
                Bxv  % Empty Jacobian with respect to V (0-by-2).
                Bxi  % Empty Jacobian with respect to I (0-by-2).
                Bxu  % Empty Jacobian with respect to u (0-by-nu).
            end
            Axx = zeros(0,0);
            Bxv = zeros(0,2);
            Bxi = zeros(0,2);
            Bxu = zeros(0,numel(u));
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0) %#ok
            % Jacobian of the output equation.
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                Cyx  % Jacobian with respect to x (ny-by-0).
                Dyv  % Jacobian with respect to V (zero).
                Dyi  % Jacobian with respect to I (zero).
                Dyu  % Jacobian with respect to the observed states (`-K`).
            end
            ny  = size(param.K,1);
            Cyx = zeros(ny,0);
            Dyv = zeros(ny,2);
            Dyi = zeros(ny,2);
            Dyu = -param.K;
        end
    end
end

function W = weight(W, str_name)
    % A vector is the diagonal of the weight
    arguments (Input)
        W         % Weight as given: a matrix, its diagonal or empty.
        str_name  % Name of the weight ("Q" or "R"), for the error message.
    end
    arguments (Output)
        W  % Weight matrix, or empty.
    end
    if isempty(W)
        W = [];
    elseif isvector(W) && ~isscalar(W)
        W = diag(W);
    elseif size(W,1) ~= size(W,2)
        error(msg("GUILDA:local_LQR:WeightShape", str_name))
    end
end
