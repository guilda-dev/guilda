classdef local_LQR < LocalController
% <@Desc>
% State-feedback LQR controller of one component. It observes all the states of the
% component (the reserved input "X") and drives the inputs Input of the component:
%   u = u* - K (x - x*)
% where x*, u* are the equilibrium of the component. The gain K = lqr(A, B, Q, R) is
% computed by net.initialize from the linear model of the component (comp.get_sys
% without its controllers) connected to an infinite bus of voltage V0 through the
% admittance that gives the equilibrium current (as in GUILDA v2).
% Attach it with comp.add_local_controller(lqr); it takes the place of an AVR.
% Its outputs replace the driven inputs, so a global controller (e.g. an AGC) must not
% drive the same input (use Input="Vfield" with an AGC on Pmech).
% <@Role> Controller
% <@Summary> State-feedback LQR controller of a component.
% <@Constructor>
%  lqr = controller.local_LQR(tag)
%  lqr = controller.local_LQR(tag, Q=Q, R=R, Input=["Vfield"], V0=1)
% <@Parameters>
% [
%   {"Name": "tag", "Type": "string scalar", "Description": "Tag of the controller (\"CL\" + tag).", "Required": true, "Default": "-"},
%   {"Name": "Q", "Type": "double vector | square matrix", "Description": "Weight of the states sv_x of the component (a vector is its diagonal).", "Required": false, "Default": "identity"},
%   {"Name": "R", "Type": "double vector | square matrix", "Description": "Weight of the driven inputs Input (a vector is its diagonal).", "Required": false, "Default": "identity"},
%   {"Name": "Input", "Type": "string vector", "Description": "Inputs sv_u of the component that the controller drives.", "Required": false, "Default": "all the inputs"},
%   {"Name": "V0", "Type": "double scalar (complex)", "Description": "Voltage of the infinite bus of the design model.", "Required": false, "Default": "1"}
% ]

    properties (SetAccess=protected, Hidden)
        key     = "local"
        sv_x    = strings(0,1)
        sv_u    = "X"
        sv_y    = strings(0,1)
        sv_para = strings(0,1)
    end

    properties
        % <@Desc> Weight of the states of the component (a vector is the diagonal).
        % Editing it makes the equilibrium stale; net.initialize recomputes K.
        % <@Role> Parameter
        % <@Type> double
        % <@Size> nx x nx
        Q = []
        % <@Desc> Weight of the driven inputs (a vector is the diagonal).
        % Editing it makes the equilibrium stale; net.initialize recomputes K.
        % <@Role> Parameter
        % <@Type> double
        % <@Size> nu x nu
        R = []
        % <@Desc> Voltage of the infinite bus of the design model.
        % <@Role> Parameter
        % <@Type> double
        % <@Size> 1x1
        V0 = 1
    end

    properties (SetAccess=private)
        % <@Desc> Feedback gain (u = u* - K (x - x*)), computed by net.initialize.
        % <@Role> SteadyState
        % <@Type> double
        % <@Size> nu x nx
        K = zeros(0,0)
        % <@Desc> Linear model of the component and the infinite bus used to compute K
        % (inputs: the driven inputs, outputs: the states).
        % <@Role> SteadyState
        % <@Type> ss
        % <@Size> 1x1
        sys_design
    end

    properties (Access=private)
        sv_input (:,1) string = strings(0,1)   % Input as given (empty: all the inputs)
        rv_u0    (:,1) double = zeros(0,1)     % equilibrium of the driven inputs
    end

    methods
        function obj = local_LQR(tag, opt)
            arguments
                tag        (1,1) string
                opt.Q      double = []
                opt.R      double = []
                opt.Input  (:,1) string = strings(0,1)
                opt.V0     (1,1) double = 1
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
            % Called by the component after its equilibrium is set: the inputs of the
            % controller are the states x* and its outputs the inputs u* of the component.
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
            dx = zeros(0,1);
        end
        function y = fcn_y(t, x, V, I, u, param, omega0) %#ok
            y = param.u0 - param.K * (u - param.x0);
        end
        function M = fcn_Mass(t, x, V, I, u, param, omega0) %#ok
            M = zeros(0,0);
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0) %#ok
            Axx = zeros(0,0);
            Bxv = zeros(0,2);
            Bxi = zeros(0,2);
            Bxu = zeros(0,numel(u));
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0) %#ok
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
