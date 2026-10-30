classdef Tutorial3bus < PowerNetwork
% 3-bus network for the GUILDA tutorial.
% It has 3 buses, 2 pi lines (1-2 and 2-3), 2 generators (gen-park) at buses 1
% and 2 and a constant-power load (load-power, 3 pu) at bus 3. The network is
% built with add_bus, add_branch and add_component and is initialized by the
% constructor.
%
% <@Examples>
% Simulate a fault at bus 3:
%
% ```matlab
% net = network.Tutorial3bus();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B003");
% sol = net.simulate([0,10], ev);
% ```
%
% See also network.Txt3Bus, PowerNetwork.add_bus, PowerNetwork.add_branch

    methods
        function obj = Tutorial3bus()
            % Create the network and initialize it.

            arguments (Output)
                obj % Tutorial3bus network.
            end

            obj.add_bus("Varg",0, "V",2);
            obj.add_bus("Varg",0, "V",2);
            obj.add_bus("Varg",0, "V",0);

            obj.add_branch("pi", [1,2], "R",0.010, "X",0.085, "C", 0);
            obj.add_branch("pi", [2,3], "R",0.017, "X",0.092, "C", 0);

            Xd    = [1.569; 1.220];
            Xd_p  = [0.963; 0.667];
            Xd_pp = [0.963; 0.667]*0.8;
            Xq    = [0.963; 0.667];
            Xq_p  = [0.963; 0.667]*0.9;
            Xq_pp = [0.963; 0.667]*0.8;
            Td_p  = [5.140; 8.970];
            Td_pp = [5.140; 8.970];
            Tq_p  = [5.140; 8.970];
            Tq_pp = [5.140; 8.970];
            X_ls  = [0.100; 0.100];
            M     = [  100;    12];
            D     = [   10;    10];
            para = table(Xd,Xd_p,Xd_pp,Xq,Xq_p,Xq_pp,X_ls,Td_p,Td_pp,Tq_p,Tq_pp,M,D);

            obj.a_Bus{1}.add_component( "gen-park", "P", 0.0, "parameter",para(1,:));
            obj.a_Bus{2}.add_component( "gen-park", "P", 0.5, "parameter",para(2,:));
            obj.a_Bus{3}.add_component("load-power", "P",-3.0, "Q",0);

            obj.initialize;
        end
    end
end