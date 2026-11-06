classdef (Sealed = true) IEEJ_LPT3 < controller.governor.abstract
% Governor of hydro units of the IEEJ standard models, model 1 (LPT = 3).
% The model of fig. A1.2 (b) of the IEEJ technical report on the standard power
% system models (appendix 1, section 3). It observes the speed deviation of the
% generator and drives its mechanical power input.
%
% **Dynamic model**
% The controller is a dynamical system with state $x$, input $u$ and output $y$.
%
% **State variables** $x$ (`sv_x`, in pu of the rated MW)
% - `Pgov`: Speed governor output.
% - `Psv`: Servo position.
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
% T_g\,\dot{P}_\mathrm{gov} &= -P_\mathrm{gov} + \frac{100}{\mathrm{droop}}\,\omega \\
% T_s\,\dot{P}_\mathrm{sv} &= g - P_\mathrm{sv}
% \end{aligned}
% \right.
% ```
% with the low value gate and the output
% ```math
% g = \min(P_\mathrm{ref} - P_\mathrm{gov},\ P_\mathrm{limit}), \qquad P_\mathrm{mech} = P_\mathrm{rate}\,P_\mathrm{sv}
% ```
%
% The servo rate $\dot{P}_\mathrm{sv}$ is limited to `[rate_min, rate_max]`, and `Psv` is
% frozen while it is at `pos_max` or `pos_min` and pushed further out (non-windup).
%
% The turbine output is the servo position.
%
% `Prate` is the rated MW of the machine divided by the system base and `PLM` [%]
% the governor margin, which sets `Pref` and `Plimit` at the equilibrium (see
% controller.governor.abstract). The other defaults are the values of the figure.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% gen = net.a_Bus{2}.a_Component{1};
% gen.add_local_controller("gov-LPT3", parameter=struct(Prate=2, PLM=10));
% net.initialize;
% ```
%
% See also controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT4, controller.governor.abstract

    properties (Constant, Hidden) % Model definition
        key = "gov-LPT3"  % Model key that selects this class in `Component.add_local_controller`.
    end

    methods
        function obj = IEEJ_LPT3(tag, param)
        % Create an IEEJ_LPT3 governor with the tag "CG" + tag.
            arguments (Input)
                tag            (1,1) string % Tag suffix; the controller tag is "CG" + tag.
                param.Prate    (1,1) double {mustBePositive} = 1 % [pu] Rated MW of the machine divided by the system base.
                param.PLM      (1,1) double = 5 % [%] Governor margin (of the rated MW); negative for load-limit operation.
                param.droop    (1,1) double {mustBePositive} = 5.0 % [%] Speed droop (the gain is 100/droop).
                param.Tg       (1,1) double {mustBeNonnegative} = 10.0 % [s] Time constant of the speed governor.
                param.Ts       (1,1) double {mustBePositive} = 0.3 % [s] Time constant of the servo (its gain is 1/Ts).
                param.rate_max (1,1) double = 0.1 % [pu/s] Upper limit of the servo speed.
                param.rate_min (1,1) double = -1000 % [pu/s] Lower limit of the servo speed.
                param.pos_max  (1,1) double = 1.05 % [pu] Upper limit of the servo position.
                param.pos_min  (1,1) double = 0 % [pu] Lower limit of the servo position.
            end
            arguments (Output)
                obj % IEEJ_LPT3 object.
            end
            obj@controller.governor.abstract(tag)

            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct( ...
                   "Prate", param.Prate, ...
                     "PLM", param.PLM, ...
                   "droop", param.droop, ...
                      "Tg", param.Tg, ...
                      "Ts", param.Ts, ...
                "rate_max", param.rate_max, ...
                "rate_min", param.rate_min, ...
                 "pos_max", param.pos_max, ...
                 "pos_min", param.pos_min));

            obj.sv_x    = ["Pgov"; "Psv"];
            obj.sv_para = ["Prate"; "PLM"; "droop"; "Tg"; "Ts"; "rate_max"; "rate_min"; "pos_max"; "pos_min"];
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
