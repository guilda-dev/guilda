classdef GUILDAlogo < PowerNetwork
% Demonstration network whose diagram reads as the letters GUILDA.
% It is not a real grid and has no published source: its buses carry diagram positions
% (X, Y) and its lines bend points (Path), so that plot_diagram draws the letters G, U, I,
% L, D and A, and the dispatch is chosen so that the branch currents spread over the whole
% colormap. It is the network of the animation on the Home tab of the documentation site.
% It has 44 buses, 49 branches (46 pi lines and 3 pi_transformer), 8 generators and 18
% loads; 60 Hz, 100 MVA base. It is built with add_bus, add_branch and add_component and
% is initialized by the constructor.
%
% Layout:
%
% - Buses 1-8 form G (an arc with its bar), 9-15 U, 16-22 I (with serifs), 23-27 L, 28-35
%   D and 36-42 A. Curves are bend points of the lines.
% - Ties join the letters (G-U at mid-height and at the bottom, U-I, I-L, L-D and D-A on
%   the baseline, D-A also from the bow of D to the crossbar of A), and a backbone of two
%   long lines runs below the letters from the bottom of G to L and on to the right foot of
%   A. With D (straight stroke and bow) and A (legs and crossbar), the network has 6
%   independent loops.
% - Buses 43 (left of G) and 44 (right of A) are generator buses behind step-up
%   transformers; the stem of I is a transformer too.
%
% Models:
%
% - Generators: gen-park at buses 43 (slack, V = 1.04), 17, 36 and 44, gen-1axis at buses
%   1 and 23, gen-2axis at buses 15 and 31, with the default controllers (Static AVR and
%   governor). Their data are row NGT2 of the generator parameter.csv on each machine
%   rating (100 to 500 MVA): the reactances divided and M and D multiplied by the rating.
% - Loads: load-impedance at 18 buses, P from 0.2 to 1.5 pu and Q = 0.3 P.
% - Lines: R about X/10 (X/20 for the backbone), X from 0.025 to 0.16 pu, C from 0.01
%   to 0.25 pu; transformers: X from 0.018 to 0.04 pu, tap 1.
%
% Operating point: the voltages are 0.957-1.040 pu, and the larger end current of the
% branches spreads from 0.02 to 2.0 pu, close to evenly, so that the default
% ColorMode "I" of plot_diagram shows the whole colormap. Linearization: one eigenvalue
% of get_sys(Type="ODE") is 0 (the common rotor angle, as no bus voltage is fixed); all
% the others have a negative real part. A three-phase fault of 50 ms on a bus settles.
%
% <@Examples>
% Draw the power flow with the flow dots, and simulate a fault at bus 26:
%
% ```matlab
% net = network.GUILDAlogo();
% res = net.calculate_powerflow();
% G   = res.plot_diagram(LabelMode="none", BranchWidthMode="I");
% sc  = net.add_scenario("fault", Time=[0, 10]);
% sc.add_fault("B026", [1, 1.05]);
% sol = net.simulate("fault");
% ```
%
% See also network.Tutorial10bus, network.IEEE14bus, ResultPF.plot_diagram

    methods
        function obj = GUILDAlogo()
            % Create the network and initialize it.

            arguments (Output)
                obj  % GUILDAlogo network.
            end

            H = 4.4;                                   % letter height
            arc = @(cx, cy, rx, ry, th) [cx + rx*cosd(th(:)), cy + ry*sind(th(:))];
            xA = @(y) 13.9 + 1.4*y/H;                  % left leg of A

            % Buses: x, y (diagram position), V (voltage setting of the generator buses)
            c_bus = {
                % G (01-08): arc centered (1.7, 2.2), radii 1.7 x 2.2
                1.7 + 1.7*cosd(40),  2.2 + 2.2*sind(40),  1.03   % 01 upper end
                1.7 + 1.7*cosd(100), 2.2 + 2.2*sind(100), 1      % 02 top
                0,                   2.2,                 1      % 03 left
                1.7 + 1.7*cosd(220), 2.2 + 2.2*sind(220), 1      % 04 lower left
                1.7 + 1.7*cosd(275), 2.2 + 2.2*sind(275), 1      % 05 bottom
                1.7 + 1.7*cosd(330), 2.2 + 2.2*sind(330), 1      % 06 lower right
                1.7 + 1.7*cosd(330), 2.0,                 1      % 07 bar, right
                1.9,                 2.0,                 1      % 08 bar, inner end
                % U (09-15)
                3.9, H,   1.03   % 09
                3.9, 2.4, 1      % 10
                3.9, 1.1, 1      % 11
                5.0, 0,   1      % 12
                6.1, 1.1, 1      % 13
                6.1, 2.6, 1      % 14
                6.1, H,   1.03   % 15
                % I (16-22)
                6.9, H,   1      % 16
                7.5, H,   1.02   % 17
                8.1, H,   1      % 18
                7.5, 2.2, 1      % 19
                6.9, 0,   1      % 20
                7.5, 0,   1      % 21
                8.1, 0,   1      % 22
                % L (23-27)
                8.9,  H,   1.02  % 23
                8.9,  2.2, 1     % 24
                8.9,  0,   1     % 25
                9.75, 0,   1     % 26
                10.6, 0,   1     % 27
                % D (28-35): bow centered (12.1, 2.2), radii 1.3 x 2.2
                11.3, H,   1     % 28
                11.3, 2.2, 1     % 29
                11.3, 0,   1     % 30
                12.1, H,   1.03  % 31
                12.1 + 1.3*cosd(40),  2.2 + 2.2*sind(40),  1  % 32
                13.4, 2.2, 1     % 33
                12.1 + 1.3*cosd(-40), 2.2 + 2.2*sind(-40), 1  % 34
                12.1, 0,   1     % 35
                % A (36-42)
                15.3,      H,   1.03  % 36 apex
                13.9,      0,   1     % 37 left foot
                16.7,      0,   1     % 38 right foot
                xA(1.6),   1.6, 1     % 39 crossbar left
                30.6-xA(1.6), 1.6, 1  % 40 crossbar right
                xA(3.0),   3.0, 1     % 41 left leg, upper
                30.6-xA(3.0), 3.0, 1  % 42 right leg, upper
                % step-up buses of the two large plants (43-44)
                -0.8, 2.2, 1.04  % 43 left of G
                17.5, 0,   1.04  % 44 right of A
                };

            % Branches: from, to, class, R, X, C, path
            c_branch = {
                % G
                1,  2,  "pi", 0.006, 0.060, 0.030, arc(1.7, 2.2, 1.7, 2.2, 50:10:90)
                2,  3,  "pi", 0.007, 0.070, 0.035, arc(1.7, 2.2, 1.7, 2.2, 110:10:170)
                3,  4,  "pi", 0.005, 0.050, 0.025, arc(1.7, 2.2, 1.7, 2.2, 190:10:210)
                4,  5,  "pi", 0.006, 0.055, 0.028, arc(1.7, 2.2, 1.7, 2.2, 230:10:265)
                5,  6,  "pi", 0.005, 0.050, 0.025, arc(1.7, 2.2, 1.7, 2.2, 285:10:320)
                6,  7,  "pi", 0.004, 0.030, 0.010, []
                7,  8,  "pi", 0.005, 0.045, 0.015, []
                % U
                9,  10, "pi", 0.006, 0.060, 0.030, []
                10, 11, "pi", 0.004, 0.040, 0.020, []
                11, 12, "pi", 0.005, 0.050, 0.025, arc(5.0, 1.1, 1.1, 1.1, 190:10:260)
                12, 13, "pi", 0.005, 0.050, 0.025, arc(5.0, 1.1, 1.1, 1.1, 280:10:350)
                13, 14, "pi", 0.004, 0.045, 0.020, []
                14, 15, "pi", 0.005, 0.055, 0.025, []
                % I
                16, 17, "pi", 0.003, 0.025, 0.010, []
                17, 18, "pi", 0.003, 0.025, 0.010, []
                17, 19, "pi_transformer", 0, 0.040, 0, []
                19, 21, "pi", 0.006, 0.060, 0.030, []
                20, 21, "pi", 0.003, 0.025, 0.010, []
                21, 22, "pi", 0.003, 0.025, 0.010, []
                % L
                23, 24, "pi", 0.006, 0.060, 0.030, []
                24, 25, "pi", 0.006, 0.060, 0.030, []
                25, 26, "pi", 0.004, 0.035, 0.015, []
                26, 27, "pi", 0.004, 0.035, 0.015, []
                % D
                28, 29, "pi", 0.006, 0.060, 0.030, []
                29, 30, "pi", 0.006, 0.060, 0.030, []
                28, 31, "pi", 0.004, 0.035, 0.015, []
                31, 32, "pi", 0.004, 0.040, 0.020, arc(12.1, 2.2, 1.3, 2.2, 80:-10:50)
                32, 33, "pi", 0.004, 0.040, 0.020, arc(12.1, 2.2, 1.3, 2.2, 30:-10:10)
                33, 34, "pi", 0.004, 0.040, 0.020, arc(12.1, 2.2, 1.3, 2.2, -10:-10:-30)
                34, 35, "pi", 0.004, 0.040, 0.020, arc(12.1, 2.2, 1.3, 2.2, -50:-10:-80)
                35, 30, "pi", 0.004, 0.035, 0.015, []
                % A
                37, 39, "pi", 0.005, 0.045, 0.020, []
                39, 41, "pi", 0.005, 0.045, 0.020, []
                41, 36, "pi", 0.005, 0.045, 0.020, []
                36, 42, "pi", 0.005, 0.045, 0.020, []
                42, 40, "pi", 0.005, 0.045, 0.020, []
                40, 38, "pi", 0.005, 0.045, 0.020, []
                39, 40, "pi", 0.006, 0.050, 0.025, []
                % step-up transformers
                43, 3,  "pi_transformer", 0, 0.020, 0, []
                44, 38, "pi_transformer", 0, 0.018, 0, []
                % ties between the letters
                7,  10, "pi", 0.004, 0.040, 0.020, []
                6,  11, "pi", 0.003, 0.030, 0.015, []
                13, 20, "pi", 0.004, 0.035, 0.015, []
                22, 25, "pi", 0.003, 0.030, 0.015, []
                27, 30, "pi", 0.003, 0.030, 0.015, []
                35, 37, "pi", 0.005, 0.045, 0.020, []
                33, 39, "pi", 0.004, 0.035, 0.015, []
                % backbone below the letters
                5,  26, "pi", 0.008, 0.160, 0.250, [1.7 + 1.7*cosd(275), -0.75; 9.75, -0.75]
                26, 38, "pi", 0.008, 0.150, 0.230, [9.75, -0.75; 16.7, -0.75]
                };

            % Generators: bus, class, P, rating [100 MVA], DX, DY (the slack generator at bus 43
            % balances the rest)
            c_gen = {
                43, "gen-park",  0,   2,  -0.5,  0
                1,  "gen-1axis", 0.3, 1,   0,   -0.55
                15, "gen-2axis", 0.2, 1,   0,    0.45
                17, "gen-park",  0.5, 1,   0,    0.45
                23, "gen-1axis", 1.4, 2,   0,    0.45
                31, "gen-2axis", 2.6, 3,   0,    0.45
                36, "gen-park",  4.1, 5,   0,    0.45
                44, "gen-park",  1.5, 2,   0.5,  0
                };
            % Loads (load-impedance): bus, P, Q, DX, DY
            c_load = {
                2,  0.2, 0.06,  0,     0.45
                4,  1.1, 0.33, -0.45,  0
                8,  0.6, 0.18, -0.45,  0
                10, 0.2, 0.06,  0.45,  0
                12, 1.4, 0.42,  0,    -0.35
                14, 0.2, 0.06, -0.45,  0
                16, 0.3, 0.09,  0,     0.45
                19, 0.3, 0.09,  0.4,   0
                20, 0.4, 0.12,  0,    -0.35
                22, 0.2, 0.06,  0,    -0.35
                24, 0.2, 0.06,  0.45,  0
                25, 0.9, 0.27,  0,    -0.35
                27, 0.7, 0.21,  0,    -0.35
                29, 1.1, 0.33,  0.45,  0
                35, 0.6, 0.18,  0,    -0.35
                39, 1.5, 0.45,  0,    -0.45
                40, 0.4, 0.12,  0,    -0.45
                42, 0.7, 0.21,  0.45,  0
                };

            for i = 1:height(c_bus)
                obj.add_bus(V=c_bus{i, 3}, X=c_bus{i, 1}, Y=c_bus{i, 2}, Shape="circle");
            end
            for k = 1:height(c_branch)
                rm_path = c_branch{k, 7};
                if isempty(rm_path)
                    rm_path = "";
                end
                if c_branch{k, 3} == "pi_transformer"
                    obj.add_branch(c_branch{k, 3}, [c_branch{k, 1}, c_branch{k, 2}], X=c_branch{k, 5}, ...
                        Style="transformer", Path=rm_path);
                else
                    obj.add_branch(c_branch{k, 3}, [c_branch{k, 1}, c_branch{k, 2}], R=c_branch{k, 4}, ...
                        X=c_branch{k, 5}, C=c_branch{k, 6}, Path=rm_path);
                end
            end
            for k = 1:height(c_gen)
                obj.a_Bus{c_gen{k, 1}}.add_component(c_gen{k, 2}, P=c_gen{k, 3}, parameter="NGT2", ...
                    baseMVA=100*c_gen{k, 4}, DX=c_gen{k, 5}, DY=c_gen{k, 6});
            end
            % Machine data NGT2 on the rating of each generator: reactances / rating, M and D x rating
            tab = obj.get_parameter("dynamics", Key=unique([c_gen{:, 2}]));
            [~, iv_gen] = ismember(string(tab.Properties.RowNames), compose("B%03dSG1", [c_gen{:, 1}]'));
            rv_rate = [c_gen{iv_gen, 4}]';
            for s_col = intersect(["Xd","Xq","Xd_p","Xq_p","Xd_pp","Xq_pp","X_ls"], tab.Properties.VariableNames)
                tab.(s_col) = tab.(s_col) ./ rv_rate;
            end
            tab.M = tab.M .* rv_rate;
            tab.D = tab.D .* rv_rate;
            obj.set_parameter("dynamics", tab);
            for k = 1:height(c_load)
                obj.a_Bus{c_load{k, 1}}.add_component("load-impedance", P=-c_load{k, 2}, Q=-c_load{k, 3}, ...
                    Shape=">", DX=c_load{k, 4}, DY=c_load{k, 5});
            end
            evalc("obj.a_Bus{43}.l_isSlack = true;");   % the slack bus (GUILDA never selects one)

            obj.initialize;
        end
    end
end
