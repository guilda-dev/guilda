function net = test14bus_v1
    %% test code of ieee-14bus system
    %%%==================================================================================%%% 
    %%%                          <<< IEEE 14-Bus System >>>                              %%%
    %%%==================================================================================%%%
    %%%                                                                                  %%%
    %%%   The IEEE 14-bus system is a standard test case for power system analysis.      %%%
    %%%  It represents a small part of the American Electric Power System and is         %%%
    %%%  widely used to test power flow, stability, and contingency analysis.            %%%
    %%%                                                                                  %%%
    %%%                       =<< System Overview >>=                                    %%%
    %%%                                                                                  %%%
    %%%   The model includes 14 buses, 5 generators, 11 loads, 16                        %%%
    %%%  transmission lines, and 2 transformers. Buses are classified as:                %%%
    %%%                                                                                  %%%
    %%%  ・Slack Bus (Bus 1)         : The reference bus with a fixed voltage and angle. %%%
    %%%  ・PV Buses  (Bus 2, 3, 6, 8): Have fixed voltage and real power.                %%%
    %%%  ・PQ Buses  (The rest)      : Have fixed real and reactive power loads.         %%%
    %%%                                                                                  %%%
    %%%==================================================================================%%%
    % 
    %                    =<< IEEE 14-Bus System Diagram >>=
    % 
    %
    %                             LL             LL             
    %                             |              |
    %                   (13) ===========       ===== (14)
    %                         |   |   |         | |
    %               LL        |   |   └---------┘ └------------┐
    %               |         |   |                            |
    %        (12) =====       |   |        LL      LL          |
    %              | |        |   |        |       |           |
    %              | └--------┘   | (11) =====   ===== (10)    |
    %              |              |       | |     | |          |
    %              └----------┐   |   ┌---┘ └-----┘ └-----┐    |
    %                         |   |   |                   |    |   ┌-- LL
    %                         |   |   |                   |    |   |
    %                        =========== (6)       (9) ==============
    %                         |   |   |                 |   |      | ┌-----------┐
    %                         SC  |   LL               ///  |      | |           |
    %                            ~~~                       ~~~    ~~~~~ (7)     === (8)
    %                             |                         |       |            |                                                                    
    %     SG               LL --┐ |                         |       |            SC
    %     |                     | |                     ============== (4)
    %   ===== (1)              ======= (5)               |  |  |    |
    %    | |                    | | |                    |  |  |    LL
    %    | └--------------------┘ | └--------------------┘  |  |
    %    └----------┐  ┌----------┘                         |  |
    %               |  |  ┌---------------------------------┘  |
    %               |  |  |                                    |
    %               |  |  |                       ┌------------┘ 
    %              ========= (2)                  |          
    %               |  |  |                       |          
    %               SG LL |                       |
    %                     └-------------------┐   |
    %                                         |   |
    %                                         |   |
    %                                        ======= (3)
    %                                         |   |
    %                                         SC  LL
    %
    %
    %   < symbol >       < name >
    %     --, | :   Transmission Line
    %      ~~~  :   Transformer
    %      SG   :   Synchronous Generator
    %      SC   :   Synchronous Compensator
    %      LL   :   Load
    %      ===  :   Bus
    %      (.)  :   Bus Number
    %      ///  :   Shunt (bus)
    %
    % ====================================================================================

    net = PowerNetwork("TEST");
    
    b = cell(6,1);
    l = cell(6,1);
    c = cell(9,1);    
    t = cell(2,1);
        
    b{1}  = Bus("B001"); 
    b{2}  = Bus("B002"); 
    b{3}  = Bus("B003"); 
    b{4}  = Bus("B004"); 
    b{5}  = Bus("B005"); 
    b{6}  = Bus("B006"); 
    b{7}  = Bus("B007"); 
    b{8}  = Bus("B008");
    b{9}  = Bus("B009", "Bshunt", 0.19);
    b{10} = Bus("B010"); 
    b{11} = Bus("B011"); 
    b{12} = Bus("B012"); 
    b{13} = Bus("B013"); 
    b{14} = Bus("B014");

    M     = 10;
    D     = 2;
    Td_p  = 5;
    Td_pp = 0.03;
    Tq_p  = 5;
    Tq_pp = 0.03;
    Xd    = 0.305;
    Xd_p  = 0.25;
    Xd_pp = 0.15;
    Xq    = 1;
    Xq_p  = 0.75;    
    Xq_pp = 0.45;
    X_ls  = 0;
    tab = table(M,D,Xd,Xd_p,Xd_pp,Xq,Xq_p,Xq_pp,X_ls,Td_p,Td_pp,Tq_p,Tq_pp);
    
    c{1}  = component.generator.park("PARK01", tab(1,:));
    c{2}  = component.generator.park("PARK02", tab(1,:));
    c{3}  = component.generator.park("PARK03", tab(1,:));
    c{4}  = component.generator.park("PARK04", tab(1,:));
    c{5}  = component.generator.park("PARK05", tab(1,:));
    c{6}  = component.load.power("PQ01");
    c{7}  = component.load.power("PQ02");
    c{8}  = component.load.power("PQ03");
    c{9}  = component.load.power("PQ04");
    c{10} = component.load.power("PQ05");
    c{11} = component.load.power("PQ06");
    c{12} = component.load.power("PQ07");
    c{13} = component.load.power("PQ08");
    c{14} = component.load.power("PQ09");
    c{15} = component.load.power("PQ10");
    c{16} = component.load.power("PQ11");
    c{17} = component.load.power("PQ12");    
    
    l{1}  = branch.pi("L001", "Rij",0.01938, "Xij",0.05917, "cij",0.0528); 
    l{2}  = branch.pi("L002", "Rij",0.05403, "Xij",0.22304, "cij",0.0492);
    l{3}  = branch.pi("L003", "Rij",0.04699, "Xij",0.19797, "cij",0.0438);
    l{4}  = branch.pi("L004", "Rij",0.05811, "Xij",0.17632, "cij",0.0374);
    l{5}  = branch.pi("L005", "Rij",0.05695, "Xij",0.17388, "cij",0.0340);
    l{6}  = branch.pi("L006", "Rij",0.06701, "Xij",0.17103, "cij",0.0346);
    l{7}  = branch.pi("L007", "Rij",0.01335, "Xij",0.04211, "cij",0.0128);
    l{8}  = branch.pi("L008", "Rij",0.09498, "Xij",0.19890);
    l{9}  = branch.pi("L009", "Rij",0.12291, "Xij",0.25581);
    l{10} = branch.pi("L010", "Rij",0.06615, "Xij",0.13027);
    l{11} = branch.pi("L011", "Rij",0      , "Xij",0.11001);
    l{12} = branch.pi("L012", "Rij",0.03181, "Xij",0.08450);
    l{13} = branch.pi("L013", "Rij",0.12711, "Xij",0.27038);
    l{14} = branch.pi("L014", "Rij",0.08205, "Xij",0.19207);
    l{15} = branch.pi("L015", "Rij",0.22092, "Xij",0.19988);
    l{16} = branch.pi("L016", "Rij",0.17093, "Xij",0.34802);
    
    
    t{1} = branch.two_winding_transformer("TRANS01", "Rij", 0, "Xij", 0.20912, "Tap", 0.978);
    t{2} = branch.two_winding_transformer("TRANS02", "Rij", 0, "Xij", 0.55618, "Tap", 0.969);
    t{3} = branch.two_winding_transformer("TRANS03", "Rij", 0, "Xij", 0.25202, "Tap", 0.932);
    t{4} = branch.two_winding_transformer("TRANS04", "Rij", 0, "Xij", 0.17615, "Tap", 1);
    
    cellfun(@(bs) net.add_bus(bs), b)
    
    net.a_Bus{1}.add_component( c{1} );
    net.a_Bus{2}.add_component( c{2} );
    net.a_Bus{2}.add_component( c{6} );
    net.a_Bus{3}.add_component( c{3} );
    net.a_Bus{3}.add_component( c{7} );
    net.a_Bus{4}.add_component( c{8} );
    net.a_Bus{5}.add_component( c{9} );
    net.a_Bus{6}.add_component( c{4} );
    net.a_Bus{6}.add_component( c{10} );
    net.a_Bus{7}.add_component( c{17} );
    net.a_Bus{8}.add_component( c{5} );
    net.a_Bus{9}.add_component( c{11} );
    net.a_Bus{10}.add_component( c{12} );
    net.a_Bus{11}.add_component( c{13} );
    net.a_Bus{12}.add_component( c{14} );
    net.a_Bus{13}.add_component( c{15} );
    net.a_Bus{14}.add_component( c{16} );
    
    net.add_branch(l{1}, [1,2]);
    net.add_branch(l{2}, [1,5]);
    net.add_branch(l{3}, [2,3]);
    net.add_branch(l{4}, [2,4]);
    net.add_branch(l{5}, [2,5]);
    net.add_branch(l{6}, [3,4]);
    net.add_branch(l{7}, [4,5]);
    net.add_branch(l{8}, [6,11]);    
    net.add_branch(l{9}, [6,12]);
    net.add_branch(l{10}, [6,13]);
    net.add_branch(l{11}, [7,9]);
    net.add_branch(l{12}, [9,10]);
    net.add_branch(l{13}, [9,14]);
    net.add_branch(l{14}, [10,11]);
    net.add_branch(l{15}, [12,13]);
    net.add_branch(l{16}, [13,14]);    

    net.add_branch(t{1}, [4,7]);    
    net.add_branch(t{2}, [4,9]);    
    net.add_branch(t{3}, [5,6]);    
    net.add_branch(t{4}, [7,8]);    
        
    net.set_pf_set("B001", "V",1.06, "Varg",0)
    net.set_pf_set("B002", "V",1.045)
    net.set_pf_set("B003", "V",1.01)
    net.set_pf_set("B006", "V",1.07)
    net.set_pf_set("B008", "V",1.09)
    net.set_pf_set("PARK02", "P",0.4);
    net.set_pf_set("PARK03", "P",0);
    net.set_pf_set("PARK04", "P",0);
    net.set_pf_set("PARK05", "P",0);
    net.set_pf_set("PQ01", "P",-0.217, "Q",0.127);
    net.set_pf_set("PQ02", "P",-0.942, "Q",0.190);
    net.set_pf_set("PQ03", "P",-0.478, "Q",0.039);
    net.set_pf_set("PQ04", "P",-0.076, "Q",0.016);
    net.set_pf_set("PQ05", "P",-0.112, "Q",0.075);
    net.set_pf_set("PQ06", "P",-0.295, "Q",0.166);
    net.set_pf_set("PQ07", "P",-0.090, "Q",0.058);
    net.set_pf_set("PQ08", "P",-0.035, "Q",0.018);
    net.set_pf_set("PQ09", "P",-0.061, "Q",0.016);
    net.set_pf_set("PQ10", "P",-0.135, "Q",0.058);
    net.set_pf_set("PQ11", "P",-0.149, "Q",0.050);
    net.set_pf_set("PQ12", "P",0     , "Q",0    );
    
    net.initialize;
end


% c{2}  = component.generator.park("PARK02", tab(1,:));
% c{3}  = component.generator.park("PARK03", tab(1,:));
% c{4}  = component.generator.park("PARK04", tab(1,:));
% c{5}  = component.generator.park("PARK05", tab(1,:));
% c{6}  = component.load.PQload("PQ01");
% c{7}  = component.load.PQload("PQ02");
% c{8}  = component.load.PQload("PQ03");
% c{9}  = component.load.PQload("PQ04");
% c{10} = component.load.PQload("PQ05");
% c{11} = component.load.PQload("PQ06");
% c{12} = component.load.PQload("PQ07");
% c{13} = component.load.PQload("PQ08");
% c{14} = component.load.PQload("PQ09");
% c{15} = component.load.PQload("PQ10");
% c{16} = component.load.PQload("PQ11");
% c{17} = component.load.PQload("PQ12");    