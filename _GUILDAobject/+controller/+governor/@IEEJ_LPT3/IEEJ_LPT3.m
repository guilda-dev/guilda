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
% gen.add_local_controller(controller.governor.IEEJ_LPT3("gov2", Prate=2, PLM=10));
% net.initialize;
% ```
%
% See also controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT4, controller.governor.abstract

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

            obj.para_dynamics.add_entry(   "Prate", param.Prate   , "double", ...
                                             "PLM", param.PLM     , "double", ...
                                           "droop", param.droop   , "double", ...
                                              "Tg", param.Tg      , "double", ...
                                              "Ts", param.Ts      , "double", ...
                                        "rate_max", param.rate_max, "double", ...
                                        "rate_min", param.rate_min, "double", ...
                                         "pos_max", param.pos_max , "double", ...
                                         "pos_min", param.pos_min , "double");

            obj.sv_x    = ["Pgov"; "Psv"];
            obj.sv_para = ["Prate"; "PLM"; "droop"; "Tg"; "Ts"; "rate_max"; "rate_min"; "pos_max"; "pos_min"];
        end

        function get_equilibrium(obj, V, u) %#ok<INUSL>
        % Set the equilibrium state and the inputs Pref (65M) and Plimit (77M).
        % The servo position is the turbine output `Pmech/Prate` of the generator's
        % equilibrium, and PLM sets Pref and Plimit (see controller.governor.abstract).
        % An error is raised when it is outside `[pos_min, pos_max]`.
            arguments (Input)
                obj
                V    % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
                u    % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
            end
            tab = obj.tab_parameter.dynamics;
            r_P0 = obj.initial_output(u);
            if ~(r_P0 >= tab{:,'pos_min'} && r_P0 <= tab{:,'pos_max'})
                error(msg("GUILDA:IEEJ_LPT3:OutputOutOfRange", char(obj.s_tag), num2str(r_P0), num2str(tab{:,'Prate'}), ...
                          num2str(tab{:,'pos_min'}), num2str(tab{:,'pos_max'})))
            end
            [r_Pref, r_Plimit] = obj.load_setting(r_P0, tab{:,'PLM'}, 1, tab{:,'pos_max'});

            obj.rv_Xequilibrium = [0; r_P0];
            obj.rv_Uequilibrium = [0; r_Pref; r_Plimit];
        end
    end

    methods (Static)
        function Mass = fcn_Mass(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the mass matrix `diag([Tg, 1])` of the state equation.
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
            Mass = diag([param(4), 1]);
        end

        function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the right-hand side `f` of `M*dx/dt = f` (M: fcn_Mass).
            arguments (Input)
                t      double        % [s] Time.
                x      double        % [pu] State `[Pgov; Psv]`.
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
            dx = [-x(1) + 100/param(3)*u(1);
                  r_rate];
        end

        function y = fcn_y(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the output `Pmech = Prate*Psv` [pu on the system base].
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
            y = param(1)*x(2);
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
            Axx = [-1,             0;
                   -r_slope*l_ref, -r_slope];
            Bxv = zeros(2,2);
            Bxi = zeros(2,2);
            Bxu = [100/param(3), 0,             0;
                   0,            r_slope*l_ref, r_slope*~l_ref];
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
            Cyx = [0, param(1)];
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
    [r_gate, l_ref] = controller.governor.abstract.lvg(u(2) - x(1), u(3));
    [r_rate, r_slope] = controller.governor.abstract.servo_rate(r_gate - x(2), x(2), 1/param(5), ...
                                                                param(7), param(6), param(9), param(8));
end
