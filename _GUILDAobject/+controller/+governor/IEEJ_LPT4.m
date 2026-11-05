classdef (Sealed = true) IEEJ_LPT4 < controller.governor.abstract
% Governor of hydro units of the IEEJ standard models, model 2 (LPT = 4).
% The model of fig. A1.2 (c) of the IEEJ technical report on the standard power
% system models (appendix 1, section 3). It observes the speed deviation of the
% generator and drives its mechanical power input.
%
% **Dynamic model**
% The controller is a dynamical system with state $x$, input $u$ and output $y$.
%
% **State variables** $x$ (`sv_x`, in pu of the rated MW)
% - `Pgov`: Speed governor output.
% - `Pdr`: Temporary droop state.
% - `Psv`: Servo position.
% - `Pw`: Water column output.
%
% **Input signals** $u$ (`sv_u`)
% - `omega` [pu]: Speed deviation of the generator.
% - `Pref` [pu of the rated MW]: Load setting (65M), kept at its equilibrium.
% - `Plimit` [pu of the rated MW]: Load limiter (77M), kept at its equilibrium.
%
% **Output signals** $y$ (`sv_y`)
% - `Pmech` [pu on the system base]: Mechanical power, the `Pmech` input of the generator.
%
% **Equations**
% ```math
% \left\{
% \begin{aligned}
% T_g\,\dot{P}_\mathrm{gov} &= -\omega - \frac{\mathrm{droop}}{100}\,P_\mathrm{gov} - \frac{K_t}{T_t}\,(P_\mathrm{gov} - P_\mathrm{dr}) \\
% T_t\,\dot{P}_\mathrm{dr} &= -P_\mathrm{dr} + P_\mathrm{gov} \\
% T_s\,\dot{P}_\mathrm{sv} &= g - P_\mathrm{sv} \\
% T_w\,\dot{P}_\mathrm{w} &= -P_\mathrm{w} + P_\mathrm{sv}
% \end{aligned}
% \right.
% ```
% with the low value gate and the output
% ```math
% g = \min(P_\mathrm{ref} + P_\mathrm{gov},\ P_\mathrm{limit}), \qquad P_\mathrm{mech} = P_\mathrm{rate}\,(K_wP_\mathrm{w} + K_vP_\mathrm{sv})
% ```
%
% The servo rate $\dot{P}_\mathrm{sv}$ is limited to `[rate_min, rate_max]`, and `Psv` is
% frozen while it is at `pos_max` or `pos_min` and pushed further out (non-windup).
%
% The speed governor is an integrator with the permanent droop `droop/100` and the
% temporary droop $K_t s/(1 + T_t s)$ in its feedback. With the defaults the turbine is
% `(1 - 3s)/(1 + 1.5s)`.
%
% `Prate` is the rated MW of the machine divided by the system base and `PLM` [%]
% the governor margin, which sets `Pref` and `Plimit` at the equilibrium (see
% controller.governor.abstract). The other defaults are the values of the figure.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% gen = net.a_Bus{3}.a_Component{1};
% gen.add_local_controller(controller.governor.IEEJ_LPT4("gov3", Prate=1.5, PLM=10));
% net.initialize;
% ```
%
% See also controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT3, controller.governor.abstract

    methods
        function obj = IEEJ_LPT4(tag, param)
        % Create an IEEJ_LPT4 governor with the tag "CG" + tag.
            arguments (Input)
                tag            (1,1) string % Tag suffix; the controller tag is "CG" + tag.
                param.Prate    (1,1) double {mustBePositive} = 1 % [pu] Rated MW of the machine divided by the system base.
                param.PLM      (1,1) double = 5 % [%] Governor margin (of the rated MW); negative for load-limit operation.
                param.droop    (1,1) double {mustBePositive} = 4.0 % [%] Permanent speed droop.
                param.Tg       (1,1) double {mustBePositive} = 4.0 % [s] Time constant of the integrator of the speed governor.
                param.Kt       (1,1) double {mustBeNonnegative} = 0.6 % [s] Gain of the temporary droop Kt*s/(1 + Tt*s).
                param.Tt       (1,1) double {mustBePositive} = 12.0 % [s] Time constant of the temporary droop.
                param.Ts       (1,1) double {mustBePositive} = 7.0 % [s] Time constant of the servo (its gain is 1/Ts).
                param.rate_max (1,1) double = 0.1 % [pu/s] Upper limit of the servo speed.
                param.rate_min (1,1) double = -1000 % [pu/s] Lower limit of the servo speed.
                param.pos_max  (1,1) double = 1.02 % [pu] Upper limit of the servo position.
                param.pos_min  (1,1) double = 0 % [pu] Lower limit of the servo position.
                param.Tw       (1,1) double {mustBeNonnegative} = 1.5 % [s] Time constant of the water column lag.
                param.Kw       (1,1) double = 3.0 % Gain of the path through the water column lag.
                param.Kv       (1,1) double = -2.0 % Gain of the direct path from the servo position.
            end
            arguments (Output)
                obj % IEEJ_LPT4 object.
            end
            obj@controller.governor.abstract(tag)

            obj.para_dynamics.add_entry(   "Prate", param.Prate   , "double", ...
                                             "PLM", param.PLM     , "double", ...
                                           "droop", param.droop   , "double", ...
                                              "Tg", param.Tg      , "double", ...
                                              "Kt", param.Kt      , "double", ...
                                              "Tt", param.Tt      , "double", ...
                                              "Ts", param.Ts      , "double", ...
                                        "rate_max", param.rate_max, "double", ...
                                        "rate_min", param.rate_min, "double", ...
                                         "pos_max", param.pos_max , "double", ...
                                         "pos_min", param.pos_min , "double", ...
                                              "Tw", param.Tw      , "double", ...
                                              "Kw", param.Kw      , "double", ...
                                              "Kv", param.Kv      , "double");

            obj.sv_x    = ["Pgov"; "Pdr"; "Psv"; "Pw"];
            obj.sv_para = ["Prate"; "PLM"; "droop"; "Tg"; "Kt"; "Tt"; "Ts"; "rate_max"; "rate_min"; ...
                           "pos_max"; "pos_min"; "Tw"; "Kw"; "Kv"];
        end

        function get_equilibrium(obj, V, u) %#ok<INUSL>
        % Set the equilibrium state and the inputs Pref (65M) and Plimit (77M).
        % The turbine output is `Pmech/Prate` of the generator's equilibrium; the servo
        % position follows from it (`Pt = (Kw + Kv)*Psv` at a steady state), and PLM
        % sets Pref and Plimit (see controller.governor.abstract). An error is raised
        % when the servo position is outside `[pos_min, pos_max]`.
            arguments (Input)
                obj
                V    % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
                u    % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
            end
            tab = obj.tab_parameter.dynamics;
            r_gain = tab{:,'Kw'} + tab{:,'Kv'};
            r_P0   = obj.initial_output(u);
            r_pos0 = r_P0 / r_gain;
            if ~(r_pos0 >= tab{:,'pos_min'} && r_pos0 <= tab{:,'pos_max'})
                error(msg("GUILDA:IEEJ_LPT4:OutputOutOfRange", char(obj.s_tag), num2str(r_P0), num2str(tab{:,'Prate'}), ...
                          num2str(r_pos0), num2str(tab{:,'pos_min'}), num2str(tab{:,'pos_max'})))
            end
            [r_Pref, r_Plimit] = obj.load_setting(r_pos0, tab{:,'PLM'}, r_gain, tab{:,'pos_max'});

            obj.rv_Xequilibrium = [0; 0; r_pos0; r_pos0];
            obj.rv_Uequilibrium = [0; r_Pref; r_Plimit];
        end
    end

    methods (Static)
        function Mass = fcn_Mass(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the mass matrix `diag([Tg, Tt, 1, Tw])` of the state equation.
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  double        % Dynamic parameters in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                Mass  % Mass matrix of the state equation.
            end
            Mass = diag([param(4), param(6), 1, param(12)]);
        end

        function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the right-hand side `f` of `M*dx/dt = f` (M: fcn_Mass).
            arguments (Input)
                t      double        % [s] Time.
                x      double        % [pu] State `[Pgov; Pdr; Psv; Pw]`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % [pu] Input `[omega; Pref; Plimit]`.
                param  double        % Parameter vector in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                dx  % Right side of the state equation in the order of `sv_x`.
            end
            [r_rate, ~] = rate(x, u, param);
            dx = [-u(1) - param(3)/100*x(1) - param(5)/param(6)*(x(1) - x(2));
                  -x(2) + x(1);
                  r_rate;
                  -x(4) + x(3)];
        end

        function y = fcn_y(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the output `Pmech = Prate*(Kw*Pw + Kv*Psv)` [pu on the system base].
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  double        % Dynamic parameters in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                y  % Outputs in the order of `sv_y`.
            end
            y = param(1)*(param(13)*x(4) + param(14)*x(3));
        end

        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the Jacobians of fcn_dx on the active branch of the gate and the limits.
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  double        % Dynamic parameters in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                Axx  % Jacobian of `fcn_dx` with respect to `x`.
                Bxv  % Jacobian of `fcn_dx` with respect to `V` `[real; imag]`.
                Bxi  % Jacobian of `fcn_dx` with respect to `I` `[real; imag]`.
                Bxu  % Jacobian of `fcn_dx` with respect to `u`.
            end
            [~, r_slope, l_ref] = rate(x, u, param);
            r_kt = param(5)/param(6);
            Axx = [-param(3)/100 - r_kt, r_kt, 0,         0;
                    1,                   -1,   0,         0;
                    r_slope*l_ref,       0,    -r_slope,  0;
                    0,                   0,    1,        -1];
            Bxv = zeros(4,2);
            Bxi = zeros(4,2);
            Bxu = [-1, 0,             0;
                    0, 0,             0;
                    0, r_slope*l_ref, r_slope*~l_ref;
                    0, 0,             0];
        end

        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0) %#ok<INUSD>
        % Return the Jacobians of fcn_y.
            arguments (Input)
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                param  double        % Dynamic parameters in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                Cyx  % Jacobian of `fcn_y` with respect to `x`.
                Dyv  % Jacobian of `fcn_y` with respect to `V` `[real; imag]`.
                Dyi  % Jacobian of `fcn_y` with respect to `I` `[real; imag]`.
                Dyu  % Jacobian of `fcn_y` with respect to `u`.
            end
            Cyx = param(1)*[0, 0, param(14), param(13)];
            Dyv = zeros(1,2);
            Dyi = zeros(1,2);
            Dyu = zeros(1,3);
        end
    end
end

function [r_rate, r_slope, l_ref] = rate(x, u, param)
% Servo speed after the low value gate and the limits, its slope and the gate branch
    arguments (Input)
        x      double  % [pu] State of the governor.
        u      double  % [pu] Input `[omega; Pref; Plimit]`.
        param  double  % Parameter vector in the order of `sv_para`.
    end
    arguments (Output)
        r_rate   % Speed of the servo position.
        r_slope  % Derivative of r_rate with respect to the error of the servo position.
        l_ref    % True when the load setting passes the low value gate.
    end
    [r_gate, l_ref] = controller.governor.abstract.lvg(u(2) + x(1), u(3));
    [r_rate, r_slope] = controller.governor.abstract.servo_rate(r_gate - x(3), x(3), 1/param(7), ...
                                                                param(9), param(8), param(11), param(10));
end
