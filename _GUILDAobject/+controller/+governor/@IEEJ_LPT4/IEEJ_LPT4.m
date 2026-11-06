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
% gen.add_local_controller("gov-LPT4", parameter=struct(Prate=1.5, PLM=10));
% net.initialize;
% ```
%
% See also controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT3, controller.governor.abstract

    properties (Constant, Hidden) % Model definition
        key = "gov-LPT4"  % Model key that selects this class in `Component.add_local_controller`.
    end

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

            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct( ...
                   "Prate", param.Prate, ...
                     "PLM", param.PLM, ...
                   "droop", param.droop, ...
                      "Tg", param.Tg, ...
                      "Kt", param.Kt, ...
                      "Tt", param.Tt, ...
                      "Ts", param.Ts, ...
                "rate_max", param.rate_max, ...
                "rate_min", param.rate_min, ...
                 "pos_max", param.pos_max, ...
                 "pos_min", param.pos_min, ...
                      "Tw", param.Tw, ...
                      "Kw", param.Kw, ...
                      "Kv", param.Kv));

            obj.sv_x    = ["Pgov"; "Pdr"; "Psv"; "Pw"];
            obj.sv_para = ["Prate"; "PLM"; "droop"; "Tg"; "Kt"; "Tt"; "Ts"; "rate_max"; "rate_min"; ...
                           "pos_max"; "pos_min"; "Tw"; "Kw"; "Kv"];
        end
    end

    methods (Static)
        Mass = fcn_Mass(t, x, V, I, u, param, omega0)
        dx = fcn_dx(t, x, V, I, u, param, omega0)
        y = fcn_y(t, x, V, I, u, param, omega0)
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0)
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0)
    end
end
