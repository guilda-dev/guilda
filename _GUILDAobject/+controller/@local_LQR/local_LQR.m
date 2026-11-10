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
% equilibrium, so `net.initialize` only redesigns `K` at that equilibrium.
%
% Attach it with `comp.add_local_controller("local-LQR")`; it takes the place of an AVR
% (and of the PSS attached to that AVR). It needs the Control System Toolbox (`lqr`);
% without it, the constructor stops with GUILDA:require_toolbox:Unavailable. The output of a global controller (e.g. an
% AGC) on a driven input adds to its output, and the design of `K` does not take it
% into account (use `Input="Vfield"` with an AGC on Pmech to keep them apart).
%
% - Editing `Q`, `R` or `V0` makes the equilibrium and the handles of the controller
%   stale; `net.initialize` recomputes `K`. After a network Hz edit, `net.initialize`
%   rebuilds the handles and redesigns `K` when the equilibrium is up to date.
% - `sys_design` is the component connected to the infinite bus; its inputs are the
%   driven inputs and its outputs the states.
%
% <@Examples>
% Attach LQR controllers to two generators and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% net.a_Bus{1}.a_Component{1}.add_local_controller("local-LQR");
% net.a_Bus{2}.a_Component{1}.add_local_controller("local-LQR", parameter=struct(Input="Vfield", R=2));
% net.initialize;
% sc  = Scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% net.add_scenario(sc);
% sol = net.simulate([0,10], sc);
% ```
%
% See also Component.add_local_controller, controller.avr.abstract, controller.local_LQR_retrofit

    properties (Constant, Hidden) % Model definition
        key = "local-LQR"                     % Model key that selects this class in `Component.add_local_controller`.
        s_role = "local"                      % Role in Component.add_local_controller ("local": in the place of an AVR).
    end

    properties (SetAccess=protected, Hidden) % Signals
        sv_x = strings(0,1)                   % Names of the controller states (none).
        sv_u = "Xall"                         % Names of the observed signals ("Xall": all the states of the component).
        sv_y = strings(0,1)                   % Names of the driven inputs of the component.
        sv_para = strings(0,1)                % Names of the parameters (none).
    end

    properties % Design weights
        Q = []                                % State weight of the LQR (nx-by-nx; a vector is the diagonal, empty the identity). <@Stale> equilibrium, odefcn
        R = []                                % Input weight of the LQR (nu-by-nu; a vector is the diagonal, empty the identity). <@Stale> equilibrium, odefcn
        V0 = 1                                % [pu] Voltage of the infinite bus of the design model (complex scalar). <@Stale> equilibrium, odefcn
    end

    properties (SetAccess=private) % Design results
        K = zeros(0,0)                        % Feedback gain K in u = u* - K*(x - x*) (nu-by-nx).
        sys_design                            % Linear model used to compute K (ss).
    end

    properties (Access=private) % Internal
        sv_input (:,1) string = strings(0,1)  % Input as given (empty: all the inputs).
        rv_u0 (:,1) double = zeros(0,1)       % Equilibrium of the driven inputs.
        r_designHz double = []                % [Hz] Frequency K was designed for (empty: not designed).
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
            tools.require_toolbox("control", "controller.local_LQR");
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
    end

    methods (Hidden)
        sv_in = driven_inputs(obj, comp)
    end

    methods (Access=protected)
        resolve_ports(obj, comp)
        set_inputs(obj, sv_name)
    end
    methods (Access={?Component,?LocalController})
        set_odefcn(obj)
    end

    methods (Access=private)
        design_gain(obj, V, u)
        log_change(obj, s_name)
    end

    methods (Static)
        dx = fcn_dx(t, x, V, u, param, omega0)
        y = fcn_y(t, x, V, u, param, omega0)
        M = fcn_Mass(t, x, V, u, param, omega0)
        [Axx,Bxv,Bxu] = Jacobi_dx(t, x, V, u, param, omega0)
        [Cyx,Dyv,Dyu] = Jacobi_Y(t, x, V, u, param, omega0)
    end
end
