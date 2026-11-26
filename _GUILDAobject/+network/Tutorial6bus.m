classdef Tutorial6bus < PowerNetwork
% 6-bus network of four classical generators for the spring-mass picture of the tutorial.
% It has 6 buses, 5 lossless lines and 4 classical generators (gen-classical) at buses
% 1-4; buses 5 and 6 have no component. The generators at buses 3 and 4 have a negative
% active power: they run as synchronous motors. The network has no governor, AVR or
% load; 50 Hz, 100 MVA base. It is built with add_bus, add_branch and add_component and
% is initialized by the constructor.
%
% | Bus  | Type  | Component                          | M  | D | Xd = Xq |
% |------|-------|------------------------------------|----|---|---------|
% | B001 | slack | gen-classical, V = 0.9             | 10 | 5 | 0.20    |
% | B002 | PV    | gen-classical, P = 1.0, V = 1.3    | 8  | 5 | 0.20    |
% | B003 | PV    | gen-classical, P = -0.7, V = 1.289197 | 6  | 5 | 0.25    |
% | B004 | PV    | gen-classical, P = -0.8, V = 1.010786 | 6  | 5 | 0.25    |
% | B005 | PQ    | none                               |    |   |         |
% | B006 | PQ    | none                               |    |   |         |
%
% Lines (pi, R = 0, C = 0): 1-5 X 0.35, 2-5 X 0.20, 5-6 X 0.20, 3-6 X 0.30, 4-6 X 0.35.
% A generator is a PV source in GUILDA, so the voltages at buses 3 and 4 are those of the
% operating point with Q = 0.8 at bus 3 and Q = -0.2 at bus 4. The slack generator at
% bus 1 supplies P = 0.5 (the lines are lossless).
%
% <@Examples>
% Generators 3 and 4 take 0.1 pu more from t = 1 s, without governors:
%
% ```matlab
% net = network.Tutorial6bus();
% sc  = net.add_scenario("step", Time=[0, 20]);
% sc.add_input("B003SG1", "Pmech", -0.1, [1, 20]);
% sc.add_input("B004SG1", "Pmech", -0.1, [1, 20]);
% res = net.simulate("step");
% G = res.plot_spring_model();
% G.animate();
% ```
%
% See also network.Tutorial3bus, network.Tutorial10bus, ResultODE.plot_spring_model

    methods
        function obj = Tutorial6bus()
            % Create the network and initialize it.

            arguments (Output)
                obj  % Tutorial6bus network.
            end

            obj.tab_parameter.base.Hz = 50;

            % layout: B001/B002 on the left, B003/B004 on the right, joined by the
            % vertical bars B005 and B006 with horizontal lines
            obj.add_bus("V",0.9,      "X",0.15, "Y",0.75, "Shape","vbar", "Length",0.12);
            obj.add_bus("V",1.3,      "X",0.15, "Y",0.25, "Shape","vbar", "Length",0.12);
            obj.add_bus("V",1.289197, "X",0.90, "Y",0.75, "Shape","vbar", "Length",0.12);   % gives Q = 0.8 at bus 3
            obj.add_bus("V",1.010786, "X",0.90, "Y",0.25, "Shape","vbar", "Length",0.12);   % gives Q = -0.2 at bus 4
            obj.add_bus(              "X",0.40, "Y",0.50, "Shape","vbar", "Length",0.56);
            obj.add_bus(              "X",0.65, "Y",0.50, "Shape","vbar", "Length",0.56);

            obj.add_branch("pi", [1,5], "R",0, "X",0.35, "C",0, "FromOffset",0, "ToOffset", 0.25);
            obj.add_branch("pi", [2,5], "R",0, "X",0.20, "C",0, "FromOffset",0, "ToOffset",-0.25);
            obj.add_branch("pi", [5,6], "R",0, "X",0.20, "C",0, "FromOffset",0, "ToOffset", 0);
            obj.add_branch("pi", [3,6], "R",0, "X",0.30, "C",0, "FromOffset",0, "ToOffset", 0.25);
            obj.add_branch("pi", [4,6], "R",0, "X",0.35, "C",0, "FromOffset",0, "ToOffset",-0.25);

            M  = [10; 8; 6; 6];
            D  = [ 5; 5; 5; 5];
            Xd = [0.20; 0.20; 0.25; 0.25];
            Xq = Xd;
            para = table(M,D,Xd,Xq);

            rv_P  = [0, 1.0, -0.7, -0.8];
            rv_DX = [-0.08, -0.08, 0.08, 0.08];   % the generators point outward
            for i = 1:4
                obj.a_Bus{i}.add_component("gen-classical", "P",rv_P(i), "parameter",para(i,:), "DX",rv_DX(i), "DY",0);
            end
            evalc("obj.a_Bus{1}.l_isSlack = true;");   % the slack bus (GUILDA never selects one)

            obj.initialize;
        end
    end
end
