classdef Tutorial3bus < PowerNetwork

    methods
        function obj = Tutorial3bus()

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