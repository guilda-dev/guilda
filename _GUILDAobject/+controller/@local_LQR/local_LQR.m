classdef local_LQR < LocalController
% State-feedback LQR controller of one component.
% The controller observes all the state variables `x` of the component it is attached to
% (the reserved input signal name "Xall") and drives the inputs `Input` of the component
% (by name, e.g. "Vfield" [pu] or "Pmech" [pu]; all its inputs by default) with
% `u = u* - K*(x - x*)`, where `x*` and `u*` are the equilibrium of the component (see
% Equations below). It has no state of
% its own. `net.initialize` computes the gain `K = lqr(A, B, Q, R)` from the
% linear model of the component alone (`comp.get_linear_matrix`)
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
% - At another operating point (a step of `net.calculate_continuation_powerflow`, a point
%   of the stability-constrained OPF) the observed signals are the state `x` of the
%   component there, while `K`, `x*` and `u*` stay as designed by `net.initialize`. The
%   point is then not exactly an equilibrium with the controller: its output
%   `u* - K*(x - x*)` differs from the input of the component at the point.
%
% **Dynamic model**
% The controller is a static map from its input $x$ (the states of the component) to its
% output $u$ (the driven inputs of the component). It has no state and no parameter.
%
% **Input signals** $x$ (`sv_u`)
% - `Xall`: All the states of the component, in the order of its `sv_x`.
%
% **Output signals** $u$ (`sv_y`; the inputs `Input` of the component)
% - `<name>`: The input `<name>` of the component, one for each driven input, in the order
%   of `Input` (by default all the inputs in the order of its `sv_u`; e.g. `Vfield` [pu],
%   `Pmech` [pu]).
%
% **Equations** ($x^*$, $u^*$ and $V^*$ are the equilibrium of the component; $Q$, $R$ and
% $V_0$ are the properties `Q`, `R` and `V0`)
% ```math
% u = u^* - K\,(x - x^*), \quad K = \mathrm{lqr}(A, B, Q, R)
% ```
% with the design model, the component $E\dot{x} = f(x, V, u)$, $I = g(x, V, u)$ linearized
% at the equilibrium and connected to the infinite bus $V_0$ through $y_\infty$ (the bus
% voltage $V$ and current $I$ as real 2-vectors, $y_\infty$ as the real 2-by-2 matrix of
% the complex admittance)
% ```math
% A = E^{-1}\bigl(f_x + f_V M^{-1} g_x\bigr), \quad
% B = E^{-1}\bigl(f_u + f_V M^{-1} g_u\bigr), \quad
% M = y_\infty - g_V, \quad y_\infty = \frac{I^*}{V^* - V_0}
% ```
% where $f_x = \partial f/\partial x$ and so on, and $f_u$, $g_u$ take only the columns of
% the driven inputs.
%
% <@Examples>
% Attach LQR controllers to two generators and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% net.a_Bus{1}.a_Component{1}.add_local_controller("local-LQR");
% net.a_Bus{2}.a_Component{1}.add_local_controller("local-LQR", parameter=struct(Input="Vfield", R=2));
% net.initialize;
% sc  = net.add_scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% sol = net.simulate("fault");
% ```
%
% See also Component.add_local_controller, controller.avr.abstract, controller.pss.Retrofit

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

    methods (Access={?Component})
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
                obj  % local_LQR object.
            end
            tools.require_toolbox("control", "controller.local_LQR");
            obj@LocalController("CL"+tag)
            obj.sv_input = opt.Input;
            obj.sv_y     = opt.Input;
            obj.Q  = opt.Q;
            obj.R  = opt.R;
            obj.V0 = opt.V0;
        end
    end
    methods
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
        sct = get_option(obj)
    end

    methods (Access=protected)
        resolve_ports(obj, comp)
        set_inputs(obj, sv_name)
    end
    methods (Access={?Component,?LocalController})
        initialize(obj, l_equilibrium)
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
