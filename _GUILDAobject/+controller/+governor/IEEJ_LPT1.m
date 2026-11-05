classdef (Sealed = true) IEEJ_LPT1 < controller.governor.abstract
% Governor of thermal and nuclear units of the IEEJ standard models (LPT = 1).
% The model of fig. A1.2 (a) of the IEEJ technical report on the standard power
% system models (appendix 1, section 3). It observes the speed deviation of the
% generator and drives its mechanical power input.
%
% **Dynamic model**
% The controller is a dynamical system with state $x$, input $u$ and output $y$.
%
% **State variables** $x$ (`sv_x`, in pu of the rated MW)
% - `Pgov`: Speed governor output.
% - `Psv`: Servo position.
% - `Pch`: Steam chest output.
% - `Prh`: Reheater output.
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
% \dot{P}_\mathrm{sv} &= K_s\,(g - P_\mathrm{sv}) \\
% T_\mathrm{ch}\dot{P}_\mathrm{ch} &= -P_\mathrm{ch} + P_\mathrm{sv} \\
% T_\mathrm{rh}\dot{P}_\mathrm{rh} &= -P_\mathrm{rh} + P_\mathrm{ch}
% \end{aligned}
% \right.
% ```
% with the low value gate and the output
% ```math
% g = \min(P_\mathrm{ref} - P_\mathrm{gov},\ P_\mathrm{limit}), \qquad P_\mathrm{mech} = P_\mathrm{rate}\,(F_\mathrm{hp}P_\mathrm{ch} + F_\mathrm{rh}P_\mathrm{rh})
% ```
%
% The servo rate $\dot{P}_\mathrm{sv}$ is limited to `[rate_min, rate_max]`, and `Psv` is
% frozen while it is at `pos_max` or `pos_min` and pushed further out (non-windup).
%
% `Prate` is the rated MW of the machine divided by the system base and `PLM` [%]
% the governor margin, which sets `Pref` and `Plimit` at the equilibrium (see
% controller.governor.abstract). The other defaults are the values of the figure.
%
% <@Examples>
% Attach a governor beside the AVR of a generator and trip a load:
%
% ```matlab
% net = network.IEEE9bus();
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.governor.IEEJ_LPT1("gov1", Prate=2.5, PLM=5));
% net.initialize;
% sc  = Scenario("trip");
% sc.add_trip(net.a_Bus{5}.a_Component{1}.s_tag, [1,Inf]);
% net.add_scenario(sc);
% sol = net.simulate([0,30], sc);
% ```
%
% See also controller.governor.IEEJ_LPT3, controller.governor.IEEJ_LPT4, controller.governor.abstract, controller.avr.AVR_DC1

    methods
        function obj = IEEJ_LPT1(tag, param)
        % Create an IEEJ_LPT1 governor with the tag "CG" + tag.
            arguments
                tag            (1,1) string % Tag suffix; the controller tag is "CG" + tag.
                param.Prate    (1,1) double {mustBePositive} = 1 % [pu] Rated MW of the machine divided by the system base.
                param.PLM      (1,1) double = 5 % [%] Governor margin (of the rated MW); negative for load-limit operation.
                param.droop    (1,1) double {mustBePositive} = 4.0 % [%] Speed droop (the gain is 100/droop).
                param.Tg       (1,1) double {mustBeNonnegative} = 0.2 % [s] Time constant of the speed governor.
                param.Ks       (1,1) double {mustBePositive} = 5.0 % [1/s] Gain of the servo.
                param.rate_max (1,1) double = 0.2 % [pu/s] Upper limit of the servo speed.
                param.rate_min (1,1) double = -1000 % [pu/s] Lower limit of the servo speed.
                param.pos_max  (1,1) double = 1.05 % [pu] Upper limit of the servo position.
                param.pos_min  (1,1) double = 0 % [pu] Lower limit of the servo position.
                param.Tch      (1,1) double {mustBeNonnegative} = 0.25 % [s] Time constant of the steam chest.
                param.Trh      (1,1) double {mustBeNonnegative} = 9.0 % [s] Time constant of the reheater.
                param.Fhp      (1,1) double = 0.3 % Fraction of the output after the steam chest.
                param.Frh      (1,1) double = 0.7 % Fraction of the output after the reheater.
            end
            arguments (Output)
                obj % IEEJ_LPT1 object.
            end
            obj@controller.governor.abstract(tag)

            obj.para_dynamics.add_entry(   "Prate", param.Prate   , "double", ...
                                             "PLM", param.PLM     , "double", ...
                                           "droop", param.droop   , "double", ...
                                              "Tg", param.Tg      , "double", ...
                                              "Ks", param.Ks      , "double", ...
                                        "rate_max", param.rate_max, "double", ...
                                        "rate_min", param.rate_min, "double", ...
                                         "pos_max", param.pos_max , "double", ...
                                         "pos_min", param.pos_min , "double", ...
                                             "Tch", param.Tch     , "double", ...
                                             "Trh", param.Trh     , "double", ...
                                             "Fhp", param.Fhp     , "double", ...
                                             "Frh", param.Frh     , "double");

            obj.sv_x    = ["Pgov"; "Psv"; "Pch"; "Prh"];
            obj.sv_para = ["Prate"; "PLM"; "droop"; "Tg"; "Ks"; "rate_max"; "rate_min"; ...
                           "pos_max"; "pos_min"; "Tch"; "Trh"; "Fhp"; "Frh"];
        end

        function get_equilibrium(obj, V, u) %#ok<INUSL>
        % Set the equilibrium state and the inputs Pref (65M) and Plimit (77M).
        % The turbine output is `Pmech/Prate` of the generator's equilibrium; the servo
        % position follows from it, and PLM sets Pref and Plimit (see
        % controller.governor.abstract). An error is raised when the servo position is
        % outside `[pos_min, pos_max]`.
        %
        % Inputs:
        % - `V` [pu] Complex terminal voltage of the generator at the equilibrium (unused).
        % - `u` [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
            tab = obj.tab_parameter.dynamics;
            r_gain = tab{:,'Fhp'} + tab{:,'Frh'};
            r_P0   = obj.initial_output(u);
            r_pos0 = r_P0 / r_gain;
            if ~(r_pos0 >= tab{:,'pos_min'} && r_pos0 <= tab{:,'pos_max'})
                error(msg("GUILDA:IEEJ_LPT1:OutputOutOfRange", char(obj.s_tag), num2str(r_P0), num2str(tab{:,'Prate'}), ...
                          num2str(r_pos0), num2str(tab{:,'pos_min'}), num2str(tab{:,'pos_max'})))
            end
            [r_Pref, r_Plimit] = obj.load_setting(r_pos0, tab{:,'PLM'}, r_gain, tab{:,'pos_max'});

            obj.rv_Xequilibrium = [0; r_pos0; r_pos0; r_pos0];
            obj.rv_Uequilibrium = [0; r_Pref; r_Plimit];
        end
    end

    methods (Static)
        function Mass = fcn_Mass(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the mass matrix `diag([Tg, 1, Tch, Trh])` of the state equation.
            Mass = diag([param(4), 1, param(10), param(11)]);
        end

        function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the right-hand side `f` of `M*dx/dt = f` (M: fcn_Mass).
        %
        % Inputs:
        % - `x` [pu] State `[Pgov; Psv; Pch; Prh]`.
        % - `u` [pu] Input `[omega; Pref; Plimit]`.
        % - `param` Parameter vector in the order of `sv_para`.
            [r_rate, ~] = rate(x, u, param);
            dx = [-x(1) + 100/param(3)*u(1);
                  r_rate;
                  -x(3) + x(2);
                  -x(4) + x(3)];
        end

        function y = fcn_y(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the output `Pmech = Prate*(Fhp*Pch + Frh*Prh)` [pu on the system base].
            y = param(1)*(param(12)*x(3) + param(13)*x(4));
        end

        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0) %#ok<INUSL>
        % Return the Jacobians of fcn_dx on the active branch of the gate and the limits.
            [~, r_slope, l_ref] = rate(x, u, param);
            Axx = [-1,             0,        0,  0;
                   -r_slope*l_ref, -r_slope, 0,  0;
                    0,             1,       -1,  0;
                    0,             0,        1, -1];
            Bxv = zeros(4,2);
            Bxi = zeros(4,2);
            Bxu = [100/param(3), 0,             0;
                   0,            r_slope*l_ref, r_slope*~l_ref;
                   0,            0,             0;
                   0,            0,             0];
        end

        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0) %#ok<INUSD>
        % Return the Jacobians of fcn_y.
            Cyx = param(1)*[0, 0, param(12), param(13)];
            Dyv = zeros(1,2);
            Dyi = zeros(1,2);
            Dyu = zeros(1,3);
        end
    end
end

function [r_rate, r_slope, l_ref] = rate(x, u, param)
% Servo speed after the low value gate and the limits, its slope and the gate branch
    [r_gate, l_ref] = controller.governor.abstract.lvg(u(2) - x(1), u(3));
    [r_rate, r_slope] = controller.governor.abstract.servo_rate(r_gate - x(2), x(2), param(5), ...
                                                                param(7), param(6), param(9), param(8));
end
