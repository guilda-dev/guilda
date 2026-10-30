classdef local_LQR < LocalController
% State-feedback LQR controller of one component.
% The controller observes all the states `x` of the component it is attached to
% (the reserved input name "Xall") and drives the inputs `Input` of the component
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
% gives the equilibrium current (as in GUILDA v2).
%
% Attach it with `comp.add_local_controller(lqr)`; it takes the place of an AVR
% (and of the PSS attached to that AVR). Its outputs replace the driven inputs,
% so a global controller (e.g. an AGC) must not drive the same input (use
% `Input="Vfield"` with an AGC on Pmech).
%
% <@Examples>
% Attach LQR controllers to two generators and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% net.a_Bus{1}.a_Component{1}.add_local_controller(controller.local_LQR("lqr1"));
% net.a_Bus{2}.a_Component{1}.add_local_controller(controller.local_LQR("lqr2", Input="Vfield", R=2));
% net.initialize;
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B007");
% sol = net.simulate([0,10], ev);
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
        % An nu-by-nx matrix computed by net.initialize.
        K = zeros(0,0)
        % Linear model used to compute K (ss).
        % The component connected to the infinite bus; its inputs are the driven
        % inputs and its outputs the states.
        sys_design
    end

    properties (Access=private) % Internal
        sv_input (:,1) string = strings(0,1)   % Input as given (empty: all the inputs)
        rv_u0    (:,1) double = zeros(0,1)     % equilibrium of the driven inputs
    end

    methods
        function obj = local_LQR(tag, opt)
        % Create a state-feedback LQR controller with the tag "CL" + tag.
            arguments
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
            obj.set_odefcn(obj.r_Hz)
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
            %
            % Inputs:
            % - `V` [pu] Complex terminal voltage of the component at the equilibrium.
            % - `u` Equilibrium input of the component (in the order of its sv_u).
            comp = obj.a_Component;
            if ~isa(comp, "Component")
                error("GUILDA:local_LQR:NotOnComponent", "%s must be attached directly to a component.", obj.str_tag)
            end
            x0 = comp.rv_Xequilibrium;
            I0 = comp.c_Iequilibrium;
            [~, iv_u] = ismember(obj.sv_y, comp.sv_u);

            obj.rv_Xequilibrium = zeros(0,1);
            obj.rv_Uequilibrium = x0;
            obj.rv_u0 = u(iv_u);

            % Design model: the component connected to the infinite bus V0 through the
            % admittance y = I*/(V* - V0), so that dI = y dV
            if abs(V - obj.V0) < 1e-9
                error("GUILDA:local_LQR:DesignModel", ...
                      "%s: the bus voltage equals V0 = %g; choose another V0 for the design model.", obj.str_tag, obj.V0)
            end
            y_inf = tools.complex2matrix(I0 / (V - obj.V0));
            sys   = comp.get_sys(x0, [real(V); imag(V)], [real(I0); imag(I0)], u, ...
                                 "full", false, "tag", false, "con", false, "rec", false);
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
                error("GUILDA:local_LQR:WeightSize", "%s: Q must be %dx%d (states %s) and R %dx%d (inputs %s).", ...
                      obj.str_tag, nx, nx, join(comp.sv_x, ","), nu, nu, join(obj.sv_y, ","))
            end
            obj.K = lqr(A, Bu, Qw, Rw);
            obj.set_odefcn(obj.r_Hz)
        end
    end

    methods (Access=protected)
        function resolve_ports(obj, comp)
            % The driven inputs: Input, or all the inputs of the component
            if isempty(obj.sv_input)
                sv_in = comp.sv_u;
            else
                sv_in = obj.sv_input;
                lv = ismember(sv_in, comp.sv_u);
                if ~all(lv)
                    error("GUILDA:local_LQR:UnknownInput", "%s: %s is not an input of %s (%s).", ...
                          obj.str_tag, join(sv_in(~lv), ","), comp.str_tag, join(comp.sv_u, ","))
                end
            end
            obj.sv_y = sv_in(:);
        end

        function set_inputs(obj, sv_name)
            obj.sv_u = sv_name;
        end

        function set_odefcn(obj, omega0)
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
            obj.l_staleOdefcn = false;
        end
    end

    methods (Access=private)
        function log_change(obj, str_name)
            % A weight edit changes K, which net.initialize recomputes
            if ~isempty(obj.a_Component)
                obj.log_edit(obj.str_tag + " edit " + str_name, "Parameter(dynamics)");
            end
        end
    end

    methods (Static)
        function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok
            % State equation of the controller (no state).
            %
            % Outputs:
            % - `dx` Empty state derivative (0-by-1).
            dx = zeros(0,1);
        end
        function y = fcn_y(t, x, V, I, u, param, omega0) %#ok
            % Output equation `y = u* - K*(u - x*)`, where `u` is the observed state of the component.
            %
            % Inputs:
            % - `u` Observed states `x` of the component.
            % - `param` Struct with the gain `K`, the equilibrium state `x0` and input `u0`.
            %
            % Outputs:
            % - `y` Driven inputs of the component.
            y = param.u0 - param.K * (u - param.x0);
        end
        function M = fcn_Mass(t, x, V, I, u, param, omega0) %#ok
            % Mass matrix of the controller (no state).
            %
            % Outputs:
            % - `M` Empty mass matrix (0-by-0).
            M = zeros(0,0);
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0) %#ok
            % Jacobian of the state equation (empty: no state).
            %
            % Outputs:
            % - `Axx`, `Bxv`, `Bxi`, `Bxu` Empty Jacobians with respect to x, V, I and u.
            Axx = zeros(0,0);
            Bxv = zeros(0,2);
            Bxi = zeros(0,2);
            Bxu = zeros(0,numel(u));
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0) %#ok
            % Jacobian of the output equation.
            %
            % Outputs:
            % - `Cyx` Jacobian with respect to x (ny-by-0).
            % - `Dyv`, `Dyi` Jacobians with respect to V and I (zero).
            % - `Dyu` Jacobian with respect to the observed states (`-K`).
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
    if isempty(W)
        W = [];
    elseif isvector(W) && ~isscalar(W)
        W = diag(W);
    elseif size(W,1) ~= size(W,2)
        error("GUILDA:local_LQR:WeightSize", "%s must be a vector or a square matrix.", str_name)
    end
end
