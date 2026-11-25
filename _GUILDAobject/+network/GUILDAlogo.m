classdef GUILDAlogo < PowerNetwork
% Demonstration network whose diagram reads as the letters GUILDA.
% It is not a real grid and has no published source: its buses carry diagram positions
% (X, Y) and its lines bend points (Path), so that plot_diagram draws the hollow block
% letters G, U, I, L, D and A, each as the outline of the letter, with every generator
% and load inside a letter, and the dispatch is chosen so that the branch currents spread
% over the whole colormap. It is the network of the animation on the Home tab of the
% documentation site.
% It has 43 buses, 52 branches (46 pi lines and 6 pi_transformer), 6 generators and 15
% loads; 60 Hz, 100 MVA base. It is built with add_bus, add_branch and add_component and
% is initialized by the constructor.
%
% Layout:
%
% - Each letter is a ring: the lines run along the outline of the letter, 6 high and with
%   strokes 1.2 wide, and bend at right angles or at 45 degrees. Buses 1-5 are on G, 6-11
%   on U, 12-16 on I, 17-21 on L, 22-29 on D and 30-37 on A.
% - D and A also have a ring around their hole (buses 27-29 and 35-37). It is fed by two
%   short lines across the stroke: from the top and the bottom of D, and from the
%   crossbar and the right side of A.
% - Short ties join neighboring letters near the baseline (D-A at the height of the
%   crossbar). There is no line outside the letters; the network has 10 independent
%   loops.
% - Buses 38-43 are the generator buses, one in each letter, behind a step-up
%   transformer that runs into the letter: into the upper counter of G, the counter of U,
%   the stems of I and L (from their tops) and the holes of D and A (from their bottoms).
%
% Models:
%
% - Generators: gen-park at buses 38 (slack, V = 1.04, G), 41 (L) and 43 (A), gen-1axis
%   at buses 39 (U) and 42 (D), gen-2axis at bus 40 (I), with the default controllers
%   (Static AVR and governor). Their data are row NGT2 of the generator parameter.csv on
%   each machine rating (200 to 400 MVA): the reactances divided and M and D multiplied by
%   the rating.
% - Loads: load-impedance at 15 buses, P from 0.3 to 1.6 pu and Q = 0.3 P; each hangs
%   from the outline into the stroke or the counter of its letter.
% - Lines: X = 0.008 pu per unit length of their drawn path, R = X/10 and C = X/2;
%   transformers: X 0.02 or 0.03 pu, tap 1.
%
% Operating point: the voltages are 0.997-1.040 pu, and the larger end current of the
% branches spreads over the range from 0.05 to 1.9 pu, so that the default
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
                2.0,  6,    1      % 01 top
                0,    3,    1      % 02 left
                2.0,  0,    1      % 03 bottom
                4.0,  0.6,  1      % 04 lower right (tie to U)
                1.2,  4.0,  1      % 05 inner left (step-up)
                % U (06-11)
                4.8,  0.6,  1      % 06 left (tie to G)
                5.4,  0,    1      % 07 bottom of the left stem
                8.6,  0.6,  1      % 08 right (tie to I)
                8.0,  6,    1      % 09 top of the right stem
                6.7,  1.2,  1      % 10 inner bottom (step-up)
                5.4,  6,    1      % 11 top of the left stem
                % I (12-16)
                9.4,  0.6,  1      % 12 left (tie to U)
                10.7, 0,    1      % 13 bottom
                12.0, 0.6,  1      % 14 right (tie to L)
                10.7, 6,    1      % 15 top (step-up)
                10.1, 2.4,  1      % 16 stem, left
                % L (17-21)
                12.8, 0.6,  1      % 17 left (tie to I)
                15.8, 0.6,  1      % 18 right (tie to D)
                15.0, 1.2,  1      % 19 top of the foot
                14.0, 2.4,  1      % 20 stem, right
                13.4, 6,    1      % 21 top (step-up)
                % D (22-29): outline 22-26, ring around the hole 27-29
                16.6, 0.6,  1      % 22 left (tie to L)
                18.4, 0,    1      % 23 bottom
                20.4, 2.2,  1      % 24 right (tie to A)
                18.4, 6,    1      % 25 top
                16.6, 3.0,  1      % 26 left
                18.4, 1.2,  1      % 27 hole, bottom (step-up)
                19.2, 3.0,  1      % 28 hole, right
                18.4, 4.8,  1      % 29 hole, top
                % A (30-37): outline 30-34, ring around the hole 35-37
                21.2, 2.2,  1      % 30 left (tie to D)
                23.3, 6,    1      % 31 top
                25.4, 3.4,  1      % 32 right
                24.8, 0,    1      % 33 right foot
                23.3, 1.6,  1      % 34 under the crossbar
                23.3, 2.8,  1      % 35 hole, bottom (step-up)
                24.2, 3.4,  1      % 36 hole, right
                22.4, 3.4,  1      % 37 hole, left
                % generator buses (38-43), inside the letters
                2.6,  4.0,  1.04   % 38 G, upper counter (slack)
                6.7,  2.7,  1.03   % 39 U, counter
                10.7, 4.5,  1.03   % 40 I, stem
                13.4, 4.5,  1.03   % 41 L, stem
                18.4, 2.6,  1.03   % 42 D, hole
                23.3, 3.8,  1.03   % 43 A, hole
                };

            % Lines (pi): from, to, path (bend points); X is 0.008 per unit length of the path
            c_line = {
                % G
                1,  2,  [0, 6]
                2,  3,  [0, 0]
                3,  4,  [4, 0]
                4,  5,  [4, 3.2; 2, 3.2; 2, 2; 2.8, 2; 2.8, 1.2; 1.2, 1.2]
                5,  1,  [1.2, 4.8; 4, 4.8; 4, 6]
                % U
                6,  7,  [4.8, 0]
                7,  8,  [8.6, 0]
                8,  9,  [8.6, 6]
                9,  10, [7.4, 6; 7.4, 1.2]
                10, 11, [6, 1.2; 6, 6]
                11, 6,  [4.8, 6]
                % I
                12, 13, [9.4, 0]
                13, 14, [12, 0]
                14, 15, [12, 1.2; 11.3, 1.2; 11.3, 4.8; 12, 4.8; 12, 6]
                15, 16, [9.4, 6; 9.4, 4.8; 10.1, 4.8]
                16, 12, [10.1, 1.2; 9.4, 1.2]
                % L
                17, 18, [12.8, 0; 15.8, 0]
                18, 19, [15.8, 1.2]
                19, 20, [14, 1.2]
                20, 21, [14, 6]
                21, 17, [12.8, 6]
                % D: outline, ring around the hole, and the two lines across the stroke
                22, 23, [16.6, 0]
                23, 24, [19, 0; 20.4, 1.4]
                24, 25, [20.4, 4.6; 19, 6]
                25, 26, [16.6, 6]
                26, 22, []
                27, 28, [18.5, 1.2; 19.2, 1.9]
                28, 29, [19.2, 4.1; 18.5, 4.8]
                29, 27, [17.8, 4.8; 17.8, 1.2]
                25, 29, []
                23, 27, []
                % A: outline, ring around the hole, and the two lines across the stroke
                30, 31, [21.2, 4.6; 22.6, 6]
                31, 32, [24, 6; 25.4, 4.6]
                32, 33, [25.4, 0]
                33, 34, [24.2, 0; 24.2, 1.6]
                34, 30, [22.4, 1.6; 22.4, 0; 21.2, 0]
                35, 36, [24.2, 2.8]
                36, 37, [24.2, 4.1; 23.5, 4.8; 23.1, 4.8; 22.4, 4.1]
                37, 35, [22.4, 2.8]
                34, 35, []
                32, 36, []
                % ties between the letters
                4,  6,  []
                8,  12, []
                14, 17, []
                18, 22, []
                24, 30, []
                };
            % Step-up transformers: generator bus, letter bus, X
            c_trans = {
                38, 5,  0.020
                39, 10, 0.030
                40, 15, 0.030
                41, 21, 0.030
                42, 27, 0.030
                43, 35, 0.030
                };

            % Generators: bus, class, P, rating [100 MVA], DX, DY (the slack generator at bus 38
            % balances the rest)
            c_gen = {
                38, "gen-park",  0,   4,  0.5,  0
                39, "gen-1axis", 1.8, 2,  0,    0.5
                40, "gen-2axis", 0.9, 2,  0,    -0.5
                41, "gen-park",  0.9, 2,  0,    -0.5
                42, "gen-1axis", 1.5, 3,  0,    0.5
                43, "gen-park",  1.8, 3,  0,    0.45
                };
            % Loads (load-impedance): bus, P, Q, DX, DY, shape (pointing away from the bus)
            c_load = {
                1,  0.3, 0.09, 0,    -0.5, "v"
                2,  0.3, 0.09, 0.5,  0,    ">"
                3,  0.3, 0.09, 0,    0.5,  "^"
                7,  0.3, 0.09, 0,    0.5,  "^"
                9,  0.3, 0.09, 0,    -0.5, "v"
                11, 0.3, 0.09, 0,    -0.5, "v"
                13, 1.6, 0.48, 0,    0.5,  "^"
                16, 1.2, 0.36, 0.5,  0,    ">"
                19, 1.6, 0.48, 0,    -0.5, "v"
                20, 1.1, 0.33, -0.5, 0,    "<"
                26, 0.3, 0.09, 0.5,  0,    ">"
                28, 0.3, 0.09, 0.5,  0,    ">"
                31, 0.3, 0.09, 0,    -0.5, "v"
                33, 0.3, 0.09, 0,    0.5,  "^"
                37, 0.3, 0.09, -0.5, 0,    "<"
                };

            rm_xy = cell2mat(c_bus(:, 1:2));
            for i = 1:height(c_bus)
                obj.add_bus(V=c_bus{i, 3}, X=c_bus{i, 1}, Y=c_bus{i, 2}, Shape="circle");
            end
            for k = 1:height(c_line)
                rm_path = c_line{k, 3};
                rm_all  = [rm_xy(c_line{k, 1}, :); rm_path; rm_xy(c_line{k, 2}, :)];
                r_x     = 0.008*sum(vecnorm(diff(rm_all, 1, 1), 2, 2));
                if isempty(rm_path)
                    rm_path = "";
                end
                obj.add_branch("pi", [c_line{k, 1}, c_line{k, 2}], R=r_x/10, X=r_x, C=r_x/2, Path=rm_path);
            end
            for k = 1:height(c_trans)
                obj.add_branch("pi_transformer", [c_trans{k, 1}, c_trans{k, 2}], X=c_trans{k, 3}, ...
                    Style="transformer", Path="");
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
            evalc("obj.a_Bus{38}.l_isSlack = true;");   % the slack bus (GUILDA never selects one)

            obj.initialize;
        end
    end
end
