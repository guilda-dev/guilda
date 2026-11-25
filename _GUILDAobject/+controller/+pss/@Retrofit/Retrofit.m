classdef (Sealed) Retrofit < LocalController
% Retrofit power system stabilizer: an LQR on the generator alone with an exact compensator.
% Based on retrofit control (textbook section 5.4, Eqs. (5.36)-(5.42)). The controller
% goes under the Static AVR of a generator (role "pss", like a PSS) and drives its
% `Vpss` input, so that `Vfield = Vfd_ref + Vpss`. It observes all the states `x` of the
% generator ("Xall") and holds a copy `hat_x` of them, driven by the generator model
% with its inputs at the equilibrium:
%
% ```math
% E\,\dot{\hat{x}} = f(x, V, u^*) - A_d\,(x - \hat{x}), \qquad
% V_\mathrm{pss} = -K\,(x - \hat{x})
% ```
%
% where `E dx/dt = f(x, V, u)` is the generator, `u* = [Pmech*; Vfield*]` its
% equilibrium input, `A_d = df/dx` and `B = df/dVfield` at the equilibrium (`V` and
% `u` fixed there), and `K = lqr(E\A_d, E\B, Q, R)`.
%
% Properties:
%
% - The error `e = x - hat_x` follows `E de/dt = (A_d - B K) e` exactly, because `f`
%   is linear in `Vfield`. The controller only acts on what starts in the generator
%   itself (an initial-value disturbance of its states).
% - At the equilibrium `hat_x = x` and `Vpss = 0`, so attaching it does not move the
%   equilibrium.
% - A disturbance that enters through the voltage `V` (e.g. a fault on a distant bus)
%   drives `x` and `hat_x` in the same way: `e` stays 0 and so does `Vpss`.
% - The eigenvalues of the linearized network are those without the controller plus
%   `eig(E\(A_d - B K))`.
%
% `Pmech` is not observed, so the compensator uses its equilibrium value. This is exact
% with the default Static governor ("gov-static"); with a governor that moves `Pmech`
% (e.g. "gov-LPT1") or an AGC on `Pmech` it is an approximation, and `e` is no longer
% independent of the rest of the network.
%
% Design weights and what is guaranteed:
%
% - With the default weights (`Q = I`, `R = 1`, as in local-LQR) the effect can be very
%   small. Give a smaller `R` (e.g. `R = 0.01`) to make it act.
% - Only the decay of the error `e` is guaranteed. The swing of the generator as a whole
%   does not always get smaller: `x = hat_x + e`, and `hat_x` is driven by the rest of the
%   network through `V` (e.g. with an initial-value disturbance of the rotor angle, the
%   integral of `|omega|` can grow).
%
% It goes only under the Static AVR ("avr-static"): attaching it under another AVR, or
% replacing the Static AVR above it, stops with an error and leaves the generator as it
% was; remove the controller first. The generator must have an invertible mass matrix
% `E` (no algebraic state). It needs the Control System Toolbox (`lqr`); without it, the
% constructor stops with GUILDA:require_toolbox:Unavailable.
%
% - `net.initialize` designs `K` at the equilibrium of the generator; editing `Q` or `R`
%   makes the equilibrium and the handles stale. After a network Hz edit,
%   `net.initialize` rebuilds the handles and redesigns `K`.
% - `sys_design` is `ss(E\A_d, E\B, I, 0)`: the generator alone with its voltage and
%   `Pmech` at the equilibrium, from `Vfield` to the states.
% - At another operating point (a step of `net.calculate_continuation_powerflow`, a point
%   of the stability-constrained OPF) `hat_x` is the state `x` of the generator there,
%   so `Vpss = 0`, while `K`, `A_d` and `u*` stay as designed by `net.initialize`. The
%   point is then not exactly an equilibrium of the controller: `E dhat_x/dt = f(x, V, u*)`
%   is not 0 when the input of the generator there differs from `u*`.
%
% **State variables** $x$ (`sv_x`)
% - `hat_<name>` for each state `<name>` of the generator: the compensator copy of it.
%
% **Input signals** $u$ (`sv_u`)
% - All the states of the generator ("Xall").
%
% **Output signals** $y$ (`sv_y`)
% - `Vpss` [pu]: the `Vpss` input of the Static AVR.
%
% <@Citations>
% - 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学
%   ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),
%   計測自動制御学会 編, コロナ社, 2022, Sect. 5.4, ISBN 978-4-339-03384-7,
%   [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).
% - T. Ishizaki, T. Sadamoto, J. Imura, H. Sandberg, and K. H. Johansson, "Retrofit
%   control: Localization of controller design and implementation," *Automatica*, vol. 95,
%   pp. 336–346, 2018, doi:
%   [10.1016/j.automatica.2018.05.033](https://doi.org/10.1016/j.automatica.2018.05.033).
% - T. Sadamoto, A. Chakrabortty, T. Ishizaki, and J. Imura, "Retrofit control of
%   wind-integrated power systems," *IEEE Trans. Power Syst.*, vol. 33, no. 3, pp.
%   2804–2815, 2018, doi:
%   [10.1109/TPWRS.2017.2750411](https://doi.org/10.1109/TPWRS.2017.2750411).
% - H. Sasahara, T. Ishizaki, T. Sadamoto, T. Masuta, Y. Ueda, H. Sugihara, N. Yamaguchi,
%   and J. Imura, "Damping performance improvement for PV-integrated power grids via
%   retrofit control," *Control Eng. Pract.*, vol. 84, pp. 92–101, 2019, doi:
%   [10.1016/j.conengprac.2018.11.004](https://doi.org/10.1016/j.conengprac.2018.11.004).
% - T. Ishizaki, T. Kawaguchi, H. Sasahara, and J. Imura, "Retrofit control with
%   approximate environment modeling," *Automatica*, vol. 107, pp. 442–453, 2019, doi:
%   [10.1016/j.automatica.2019.06.010](https://doi.org/10.1016/j.automatica.2019.06.010).
% - T. Ishizaki, H. Sasahara, M. Inoue, T. Kawaguchi, and J. Imura, "Modularity-in-design
%   of dynamical network systems: Retrofit control approach," *IEEE Trans. Autom.
%   Control*, vol. 66, no. 11, pp. 5205–5220, 2021, doi:
%   [10.1109/TAC.2020.3035631](https://doi.org/10.1109/TAC.2020.3035631).
%
% <@Examples>
% Put a generator back on its Static AVR, attach the controller and simulate an
% initial-value disturbance:
%
% ```matlab
% net = network.IEEE9bus(LocalController=true);
% gen = net.a_Bus{2}.a_Component{1};
% gen.remove_local_controller(gen.avr.s_tag, RemoveNested=true);   % AVR_ST1 and PSS1
% gen.add_local_controller("avr-static");
% gen.add_local_controller("pss-retrofit", parameter=struct(R=0.01));
% net.initialize;
% sc = net.add_scenario("kick", Time=[0 10]);
% sc.add_offset(gen.s_tag, "Eq", 0.1, 0);    % initial-value disturbance at t = 0
% sol = net.simulate("kick");
% ```
%
% See also controller.local_LQR, controller.avr.Static, Component.add_local_controller

    properties (Constant, Hidden) % Model definition
        key = "pss-retrofit"                  % Model key that selects this class in `Component.add_local_controller`.
        s_role = "pss"                        % Role in Component.add_local_controller ("pss": under the AVR of the component).
    end

    properties (SetAccess=protected, Hidden) % Signals
        sv_x = strings(0,1)                   % Names of the states: "hat_" + the states of the generator (set on attachment).
        sv_u = "Xall"                         % Names of the observed signals ("Xall": all the states of the generator).
        sv_y = "Vpss"                         % Names of the outputs: the Vpss input of the AVR.
        sv_para = strings(0,1)                % Names of the parameters (none).
    end

    properties % Design weights
        Q = []                                % State weight of the LQR (nx-by-nx; a vector is the diagonal, empty the identity). <@Stale> equilibrium, odefcn
        R = []                                % Input weight of the LQR (1-by-1; empty is 1). <@Stale> equilibrium, odefcn
    end

    properties (SetAccess=private) % Design results
        K = zeros(0,0)                        % Feedback gain K in Vpss = -K*(x - hat_x) (1-by-nx).
        sys_design                            % Linear model of the generator used to compute K (ss).
    end

    methods (Access={?Component})
        function obj = Retrofit(tag, opt)
        % Create a retrofit stabilizer with the tag "CP" + tag.
            arguments (Input)
                tag    (1,1) string  % Tag suffix; the controller tag is "CP" + tag.
                opt.Q  double = []   % State weight: nx-by-nx matrix or its diagonal (default: identity).
                opt.R  double = []   % Input weight: scalar (default: 1).
            end
            arguments (Output)
                obj  % Retrofit object.
            end
            tools.require_toolbox("control", "controller.pss.Retrofit");
            obj@LocalController("CP"+tag)
            obj.Q = opt.Q;
            obj.R = opt.R;
        end
    end
    methods
        function set.Q(obj, val)
            obj.Q = weight(val, "Q");
            if ~isempty(obj.a_Component)
                obj.log_edit("edit Q: " + tools.value_text(obj.Q), "dynamics");
            end
        end
        function set.R(obj, val)
            obj.R = weight(val, "R");
            if ~isempty(obj.a_Component)
                obj.log_edit("edit R: " + tools.value_text(obj.R), "dynamics");
            end
        end
    end

    methods (Hidden)
        sv_in = driven_inputs(obj, target)
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

    methods (Static)
        dx = fcn_dx(t, x, V, u, param, omega0)
        y = fcn_y(t, x, V, u, param, omega0)
        M = fcn_Mass(t, x, V, u, param, omega0)
        [Axx,Bxv,Bxu] = Jacobi_dx(t, x, V, u, param, omega0)
        [Cyx,Dyv,Dyu] = Jacobi_Y(t, x, V, u, param, omega0)
    end
end
