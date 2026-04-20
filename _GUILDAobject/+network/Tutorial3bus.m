classdef Tutorial3bus < PowerNetwork

    methods
        function obj = Tutorial3bus()

            obj.add_bus("Varg",0, "V",2);
            obj.add_bus("Varg",0, "V",2);
            obj.add_bus("Varg",0, "V",0);

            obj.add_branch("pi", [1,2], "R",0.010, "X",0.085, "C", 0);
            obj.add_branch("pi", [2,3], "R",0.017, "X",0.092, "C", 0);

            Xd   = [1.569; 1.220];
            Xd_p = [0.963; 0.667];
            Xq   = [0.963; 0.667];
            Td_p = [5.140; 8.970];
            M    = [  100;    12];
            D    = [   10;    10];

            para = table(M,D,Xd,Xd_p,Xq,Td_p);

            obj.a_Bus{1}.add_component( "gen-1axis", "P", 0.0, "parameter",para(1,:));
            obj.a_Bus{2}.add_component( "gen-1axis", "P", 0.5, "parameter",para(1,:));
            obj.a_Bus{3}.add_component("load-power", "P",-3.0, "Q",0);

            obj.initialize;
        end
    end
end