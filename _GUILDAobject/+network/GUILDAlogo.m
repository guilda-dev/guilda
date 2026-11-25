classdef GUILDAlogo < PowerNetwork
% Demonstration network whose diagram reads as the letters GUILDA.
% It is not a real grid and has no published source: its buses carry diagram positions
% (X, Y) and its lines bend points (Path), so that plot_diagram draws the hollow block
% letters G, U, I, L, D and A, each as the outline of the letter, and the dispatch is
% chosen so that the branch currents spread over the whole colormap. It is the network of
% the animation on the Home tab of the documentation site.
% It has 45 buses, 57 branches (51 pi lines and 6 pi_transformer), 6 generators and 15
% loads; 60 Hz, 100 MVA base. It is built with add_bus, add_branch and add_component and
% is initialized by the constructor.
%
% Layout:
%
% - Each letter is a ring: the lines run along the outline of the letter, 4 high and with
%   strokes 0.8 wide, and bend at right angles or at 45 degrees. Buses 1-5 are on G, 6-11
%   on U, 12-16 on I, 17-21 on L, 22-28 on D and 29-36 on A.
% - D and A also have a ring around their hole (buses 26-28 and 34-36). It is fed by two
%   short lines across the stroke, from the top of the letter and from its bottom (D) or
%   crossbar (A).
% - Short ties join the letters near the baseline (D-A at the height of the crossbar), and
%   a backbone (buses 37-39) runs below the letters from the bottom of G to the right foot
%   of A, with drops to I and D. The network has 13 independent loops.
% - Buses 40-45 are the generator buses behind the step-up transformers: left of G, above
%   U, I, D and A, and right of the backbone.
%
% Models:
%
% - Generators: gen-park at buses 40 (slack, V = 1.04), 43 and 45, gen-1axis at buses 41
%   and 44, gen-2axis at bus 42, with the default controllers (Static AVR and governor).
%   Their data are row NGT2 of the generator parameter.csv on each machine rating (200 to
%   400 MVA): the reactances divided and M and D multiplied by the rating.
% - Loads: load-impedance at 15 buses, P from 0.3 to 1.8 pu and Q = 0.3 P; they hang
%   outward from the outlines, into the counters of the letters or below the backbone.
% - Lines: R = X/10 (X/20 for the backbone) and X about 0.012 pu per unit length of the
%   drawing; transformers: X 0.02 or 0.03 pu, tap 1.
%
% Operating point: the voltages are 0.960-1.040 pu, and the larger end current of the
% branches spreads over the range from 0.02 to 1.8 pu, so that the default
% ColorMode "I" of plot_diagram shows the whole colormap. Linearization: one eigenvalue
% of get_sys(Type="ODE") is 0 (the common rotor angle, as no bus voltage is fixed); all
% the others have a negative real part. A three-phase fault of 50 ms on a bus settles.
%
% <@Examples>
% Draw the power flow with the flow dots, and simulate a fault at bus 19:
%
% ```matlab
% net = network.GUILDAlogo();
% res = net.calculate_powerflow();
% G   = res.plot_diagram(LabelMode="none", BranchWidthMode="I");
% sc  = net.add_scenario("fault", Time=[0, 10]);
% sc.add_fault("B019", [1, 1.05]);
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

            % Buses: x, y (diagram position), V (voltage setting of the generator buses)
            c_bus = {
                % G (01-05)
                1.4,  4,    1      % 01 top
                0,    2,    1      % 02 left (step-up of the slack plant)
                1.4,  0,    1      % 03 bottom (backbone)
                2.8,  0.4,  1      % 04 lower right (tie to U)
                0.8,  2.6,  1      % 05 inner left, above the bar
                % U (06-11)
                4.0,  4,    1      % 06 top of the left stem
                3.6,  0.4,  1      % 07 left (tie to G)
                5.0,  0,    1      % 08 bottom
                6.4,  0.4,  1      % 09 right (tie to I)
                6.0,  4,    1      % 10 top of the right stem (step-up)
                5.0,  0.8,  1      % 11 inner bottom
                % I (12-16)
                8.2,  4,    1      % 12 top (step-up)
                7.2,  0.4,  1      % 13 left (tie to U)
                8.2,  0,    1      % 14 bottom (backbone)
                9.2,  0.4,  1      % 15 right (tie to L)
                7.8,  2,    1      % 16 stem, left
                % L (17-21)
                10.4, 4,    1      % 17 top
                10.0, 0.4,  1      % 18 left (tie to I)
                11.2, 0,    1      % 19 bottom
                12.4, 0.4,  1      % 20 right (tie to D)
                10.8, 2.4,  1      % 21 stem, right
                % D (22-28): outline 22-25, ring around the hole 26-28
                14.3, 4,    1      % 22 top (step-up)
                13.2, 0.4,  1      % 23 left (tie to L)
                14.3, 0,    1      % 24 bottom (backbone)
                16.0, 1.2,  1      % 25 right (tie to A)
                14.3, 3.2,  1      % 26 hole, top
                14.3, 0.8,  1      % 27 hole, bottom
                15.2, 2,    1      % 28 hole, right
                % A (29-36): outline 29-33, ring around the hole 34-36
                18.3, 4,    1      % 29 apex (step-up)
                16.8, 1.2,  1      % 30 left (tie to D)
                18.3, 1.0,  1      % 31 under the crossbar
                19.4, 0,    1      % 32 right foot (backbone)
                19.8, 2,    1      % 33 right
                18.3, 3.2,  1      % 34 hole, top
                18.3, 1.8,  1      % 35 hole, bottom
                19.0, 2.2,  1      % 36 hole, right
                % backbone (37-39)
                8.2,  -1,   1      % 37 below I
                14.3, -1,   1      % 38 below D
                19.4, -1,   1      % 39 below A (step-up of the right plant)
                % generator buses (40-45)
                -1.1, 2,    1.04   % 40 left of G (slack)
                6.0,  4.9,  1.03   % 41 above U
                8.2,  4.9,  1.03   % 42 above I
                14.3, 4.9,  1.03   % 43 above D
                18.3, 4.9,  1.03   % 44 above A
                21.0, -1,   1.03   % 45 right of the backbone
                };

            % Branches: from, to, class, R, X, C, path
            c_branch = {
                % G
                1,  2,  "pi", 0.0053, 0.053, 0.026, [0, 4]
                2,  3,  "pi", 0.0053, 0.053, 0.026, [0, 0]
                3,  4,  "pi", 0.0034, 0.034, 0.017, [2.8, 0]
                4,  5,  "pi", 0.0110, 0.110, 0.055, [2.8, 2.2; 1.4, 2.2; 1.4, 1.5; 2, 1.5; 2, 0.8; 0.8, 0.8]
                5,  1,  "pi", 0.0070, 0.070, 0.035, [0.8, 3.2; 2.8, 3.2; 2.8, 4]
                % U
                6,  7,  "pi", 0.0060, 0.060, 0.030, [3.6, 4]
                7,  8,  "pi", 0.0034, 0.034, 0.017, [3.6, 0]
                8,  9,  "pi", 0.0034, 0.034, 0.017, [6.4, 0]
                9,  10, "pi", 0.0060, 0.060, 0.030, [6.4, 4]
                10, 11, "pi", 0.0062, 0.062, 0.031, [5.6, 4; 5.6, 0.8]
                11, 6,  "pi", 0.0062, 0.062, 0.031, [4.4, 0.8; 4.4, 4]
                % I
                12, 15, "pi", 0.0082, 0.082, 0.041, [9.2, 4; 9.2, 3.2; 8.6, 3.2; 8.6, 0.8; 9.2, 0.8]
                15, 14, "pi", 0.0029, 0.029, 0.015, [9.2, 0]
                14, 13, "pi", 0.0029, 0.029, 0.015, [7.2, 0]
                13, 16, "pi", 0.0038, 0.038, 0.019, [7.2, 0.8; 7.8, 0.8]
                16, 12, "pi", 0.0055, 0.055, 0.028, [7.8, 3.2; 7.2, 3.2; 7.2, 4]
                % L
                17, 18, "pi", 0.0060, 0.060, 0.030, [10, 4]
                18, 19, "pi", 0.0031, 0.031, 0.015, [10, 0]
                19, 20, "pi", 0.0031, 0.031, 0.015, [12.4, 0]
                20, 21, "pi", 0.0055, 0.055, 0.028, [12.4, 0.8; 10.8, 0.8]
                21, 17, "pi", 0.0036, 0.036, 0.018, [10.8, 4]
                % D: outline, ring around the hole, and the two lines across the stroke
                22, 23, "pi", 0.0068, 0.068, 0.034, [13.2, 4]
                23, 24, "pi", 0.0030, 0.030, 0.015, [13.2, 0]
                24, 25, "pi", 0.0040, 0.040, 0.020, [15.1, 0; 16, 0.9]
                25, 22, "pi", 0.0060, 0.060, 0.030, [16, 3.1; 15.1, 4]
                26, 27, "pi", 0.0048, 0.048, 0.024, [14, 3.2; 14, 0.8]
                27, 28, "pi", 0.0034, 0.034, 0.017, [14.77, 0.8; 15.2, 1.23]
                28, 26, "pi", 0.0034, 0.034, 0.017, [15.2, 2.77; 14.77, 3.2]
                22, 26, "pi", 0.0022, 0.022, 0.011, []
                27, 24, "pi", 0.0022, 0.022, 0.011, []
                % A: outline, ring around the hole, and the two lines across the stroke
                29, 33, "pi", 0.0046, 0.046, 0.023, [18.7, 4; 19.8, 2.9]
                33, 32, "pi", 0.0041, 0.041, 0.021, [19.8, 0]
                32, 31, "pi", 0.0037, 0.037, 0.018, [19, 0; 19, 1]
                31, 30, "pi", 0.0056, 0.056, 0.028, [17.6, 1; 17.6, 0; 16.8, 0]
                30, 29, "pi", 0.0056, 0.056, 0.028, [16.8, 2.9; 17.9, 4]
                34, 35, "pi", 0.0041, 0.041, 0.021, [18.23, 3.2; 17.6, 2.57; 17.6, 1.8]
                35, 36, "pi", 0.0025, 0.025, 0.013, [19, 1.8]
                36, 34, "pi", 0.0028, 0.028, 0.014, [19, 2.57; 18.37, 3.2]
                29, 34, "pi", 0.0022, 0.022, 0.011, []
                35, 31, "pi", 0.0022, 0.022, 0.011, []
                % ties between the letters
                4,  7,  "pi", 0.0022, 0.022, 0.011, []
                9,  13, "pi", 0.0022, 0.022, 0.011, []
                15, 18, "pi", 0.0022, 0.022, 0.011, []
                20, 23, "pi", 0.0022, 0.022, 0.011, []
                25, 30, "pi", 0.0022, 0.022, 0.011, []
                % backbone below the letters and its drops
                3,  37, "pi", 0.0047, 0.094, 0.113, [1.4, -1]
                14, 37, "pi", 0.0024, 0.024, 0.012, []
                37, 38, "pi", 0.0036, 0.073, 0.088, []
                24, 38, "pi", 0.0024, 0.024, 0.012, []
                38, 39, "pi", 0.0030, 0.061, 0.073, []
                32, 39, "pi", 0.0024, 0.024, 0.012, []
                % step-up transformers
                40, 2,  "pi_transformer", 0, 0.020, 0, []
                41, 10, "pi_transformer", 0, 0.030, 0, []
                42, 12, "pi_transformer", 0, 0.030, 0, []
                43, 22, "pi_transformer", 0, 0.030, 0, []
                44, 29, "pi_transformer", 0, 0.030, 0, []
                45, 39, "pi_transformer", 0, 0.020, 0, []
                };

            % Generators: bus, class, P, rating [100 MVA], DX, DY (the slack generator at bus 40
            % balances the rest)
            c_gen = {
                40, "gen-park",  0,   4,  -0.45, 0
                41, "gen-1axis", 1.2, 2,   0,    0.4
                42, "gen-2axis", 1.7, 2,   0,    0.4
                43, "gen-park",  1.3, 2,   0,    0.4
                44, "gen-1axis", 1.8, 2,   0,    0.4
                45, "gen-park",  1.8, 2,   0.45, 0
                };
            % Loads (load-impedance): bus, P, Q, DX, DY, shape (pointing away from the bus)
            c_load = {
                1,  0.3, 0.09, 0,     0.45,  "^"
                5,  0.3, 0.09, 0.45,  0,     ">"
                6,  0.4, 0.12, 0,     0.45,  "^"
                8,  0.9, 0.27, 0,     -0.45, "v"
                11, 0.3, 0.09, 0,     0.45,  "^"
                16, 0.3, 0.09, -0.45, 0,     "<"
                17, 0.3, 0.09, 0,     0.45,  "^"
                19, 0.7, 0.21, 0,     -0.45, "v"
                21, 1.8, 0.54, 0.45,  0,     ">"
                28, 0.3, 0.09, -0.45, 0,     "<"
                31, 1.0, 0.30, 0,     -0.45, "v"
                33, 0.4, 0.12, 0.45,  0,     ">"
                36, 0.4, 0.12, -0.4,  0,     "<"
                37, 1.7, 0.51, 0,     -0.45, "v"
                38, 0.3, 0.09, 0,     -0.45, "v"
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
                    Shape=c_load{k, 6}, DX=c_load{k, 4}, DY=c_load{k, 5});
            end
            evalc("obj.a_Bus{40}.l_isSlack = true;");   % the slack bus (GUILDA never selects one)

            obj.initialize;
        end
    end
end
