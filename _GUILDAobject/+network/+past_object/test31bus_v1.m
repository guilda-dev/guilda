% ============================================================================================================================================================================================                                                                                  
% ============================================================================================================================================================================================                                                                                  
%
%                                 ////////     ////        //////     //   //     ////          ////   ////      /////      //////      ////////      //
%                                      //       //        //   //    //   //    //             // // // //     //   //     //   //     //            //
%                                  /////       //   ===  //////     //   //     ////          //  ///  //     //   //     //    //    //////        //
%                                    //       //        //   //    //   //         //        //       //     //   //     //   //     //            //
%                             ////////      ////       //////      /////      /////         //       //      /////      //////      ////////      /////////
%
% ============================================================================================================================================================================================ 
% ============================================================================================================================================================================================                                                                                  
%
%                                           510 (8)   
%                                            ||
%                                        ┌---||---┐
%                                        |   ||   |
%                                        LL       |
%                                                 |
%                                                 | 
%                             530 (9)   520 (10)  |  500 (11)          320 (12)      340 (13)           330 (14)          350 (15)      
%                               ||         ||     └---||                  ||-------------||----------------||----------------||                   
%                           ┌---||---------||---------||------------------||             ||                ||                ||                   
%                           |   ||         ||---┐     ||---┐          ┌---||---┐         ||---┐        ┌---||        ┌-------||---┐            100 (3)      
%                           |                   |          |          |        |              |        |             |            |               ||    
%                           LL                  LL         LL         LL       |              LL       LL            |            LL              ||-----SG
%                                                                              | ┌---LL                              |                            ||    
%                                                                              | |                                   |                            ||         
%                                                                  310 (16) =======                                  |               110 (17)     ||    
%                                                                              |                                     |                  ||        ||-----SG
%                                                                              |                                     |         ┌--------||--------||    
%                                                                              | ┌---LL                              |         |    ┌---||        ||         
%                                                                              | |                                   |         |    |             ||    
%                                                                           ======= 300 (18)             360 (19)    |         |    LL            ||-----SG
%                                         250 (20)          260 (7)          |   |                         ||        |         |                  ||    
%                                           ||               ||--------------┘   └-------------------------||--------┘         |                  ||         
%                                      ┌----||---------------||         370 (21)                           ||---┐              |     ┌------------||    
%                                      |    ||---┐           ||            ||                                   |              |     |            ||-----SG
%                                      |         |           ||------------||---┐                               LL             |     |            ||    
%                                      |         LL          ||            ||   |                                              |     |            ||
%                                      |                     ||---┐             LL                         1311 (1)            |     |       ┌----||--------------------┐
%                                      |                          |                                         ||                 |     |       |    ||------┐             |
%                                      |                          LL                                 ┌------||----SG           |     |       LL           |             |
%                                      |                                                             |      ||                 |     |                    |         ========= 170 (30)
%                                      |                                                             |                         |     |                    |             |  |
%                                      |                                             130 (5) ============================================                 |             |  LL
%                                      |                                                       |           |            |            |            ||------┘             |
%           2412 (2)    240 (6)        |                                                       |           |            |            |            ||                    |
%                ||        ||          |                                                       |           |            |            |            ||                 ======= 180 (31)  
%          SC----||--------||----------┘                                                       |           |            |            |            ||-----SG             |  
%                ||        ||                                                                  |           |            |            |            ||                    |  
%                          ||----┐                                                             |           |            |            └------------||                    LL
%                          ||    |                                                             |           |            |                         ||
%             270 (22)     ||    LL   230 (23)   220 (24)    210 (25)   200 (26)    150 (27)   |           |            |                         ||-----SG
%                ||        ||          ||          ||          ||          ||          ||      |           |            |                         ||
%           ┌----||--------||----------||----------||----------||----------||----------||------┘           |            |                    ┌----||
%           |    ||        ||          ||---┐      ||---┐      ||---┐      ||---┐      ||---┐              |            |                    |    ||
%           LL                              |           |           |           |           |   140 (28) =====        ===== 160 (29)         |    ||-----SG
%                                           LL          LL          LL          LL          LL             |            |                    LL   ||
%                                                                                                          |            |                         ||
%                                                                                                          LL           LL                        ||
%                                                                                                                                                 ||-----SG
%                                                                                                                                                 ||
%                                                                                                                                                 ||
%                                                                                                                                                120 (4)
%
%
%
%  < symbol >         < name >
%     --, |   :   Transmission Line
%
%      >>
%      >>     :   Transformer
%      >>
%
%      SG     :   Synchronous Generator
%      SC     :   Synchronous Compensator
%      LL     :   Load
%    ===, ||  :   Bus
%      (.)    :   Bus Number

function net = test31bus_v1

    b = cell(31,1);
    l = cell(31,1);
    c = cell(39,1);
    
    net = PowerNetwork("TEST39BUS");
    
    b{1}  = Bus("B001"); 
    b{2}  = Bus("B002"); 
    b{3}  = Bus("B003"); 
    b{4}  = Bus("B004"); 
    b{5}  = Bus("B005"); 
    b{6}  = Bus("B006"); 
    b{7}  = Bus("B007"); 
    b{8}  = Bus("B008");
    b{9}  = Bus("B009");
    b{10} = Bus("B010"); 
    b{11} = Bus("B011"); 
    b{12} = Bus("B012"); 
    b{13} = Bus("B013"); 
    b{14} = Bus("B014");
    b{15} = Bus("B015"); 
    b{16} = Bus("B016"); 
    b{17} = Bus("B017"); 
    b{18} = Bus("B018"); 
    b{19} = Bus("B019"); 
    b{20} = Bus("B020"); 
    b{21} = Bus("B021"); 
    b{22} = Bus("B022");
    b{23} = Bus("B023");
    b{24} = Bus("B024"); 
    b{25} = Bus("B025"); 
    b{26} = Bus("B026"); 
    b{27} = Bus("B027"); 
    b{28} = Bus("B028");
    b{29} = Bus("B029"); 
    b{30} = Bus("B030"); 
    b{31} = Bus("B031"); 

    cellfun(@(BUS) net.add_bus(BUS), b);
    
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
    
    c{1}  = component.generator.park("PARK001", tab(1,:));
    c{2}  = component.generator.park("PARK002", tab(1,:));
    c{3}  = component.generator.park("PARK003", tab(1,:));
    c{4}  = component.generator.park("PARK004", tab(1,:));
    c{5}  = component.generator.park("PARK005", tab(1,:));
    c{6}  = component.generator.park("PARK006", tab(1,:));
    c{7}  = component.generator.park("PARK007", tab(1,:));
    c{8}  = component.generator.park("PARK008", tab(1,:));
    c{9}  = component.generator.park("PARK009", tab(1,:));
    c{10} = component.generator.park("PARK010", tab(1,:));
    c{11} = component.load.power("PQ001");
    c{12} = component.load.power("PQ002");
    c{13} = component.load.power("PQ003");
    c{14} = component.load.power("PQ004");
    c{15} = component.load.power("PQ005");
    c{16} = component.load.power("PQ006");
    c{17} = component.load.power("PQ007");
    c{18} = component.load.power("PQ008");
    c{19} = component.load.power("PQ009");
    c{20} = component.load.power("PQ010");
    c{21} = component.load.power("PQ011");
    c{22} = component.load.power("PQ012");
    c{23} = component.load.power("PQ013");
    c{24} = component.load.power("PQ014");
    c{25} = component.load.power("PQ015");
    c{26} = component.load.power("PQ016");
    c{27} = component.load.power("PQ017");
    c{28} = component.load.power("PQ018");
    c{29} = component.load.power("PQ019");
    c{30} = component.load.power("PQ020");
    c{31} = component.load.power("PQ021");
    c{32} = component.load.power("PQ022");
    c{33} = component.load.power("PQ023");
    c{34} = component.load.power("PQ024");
    c{35} = component.load.power("PQ025");
    c{36} = component.load.power("PQ026");
    c{37} = component.load.power("PQ027");
    c{38} = component.load.power("PQ028");
    c{39} = component.load.power("PQ029");

    l{1}  = branch.pi("L001", "Rij",0.00019, "Xij",0.0059); 
    l{2}  = branch.pi("L002", "Rij",0.00054, "Xij",0.0223);
    l{3}  = branch.pi("L003", "Rij",0.00046, "Xij",0.0197);
    l{4}  = branch.pi("L004", "Rij",0.00058, "Xij",0.0176);
    l{5}  = branch.pi("L005", "Rij",0.00056, "Xij",0.0173);
    l{6}  = branch.pi("L006", "Rij",0.00067, "Xij",0.0171);
    l{7}  = branch.pi("L007", "Rij",0.00013, "Xij",0.0042);
    l{8}  = branch.pi("L008", "Rij",0.00034, "Xij",0.0198);
    l{9}  = branch.pi("L009", "Rij",0.00122, "Xij",0.0255);
    l{10} = branch.pi("L010", "Rij",0.00066, "Xij",0.0130);
    l{11} = branch.pi("L011", "Rij",0.00045, "Xij",0.0110);
    l{12} = branch.pi("L012", "Rij",0.00031, "Xij",0.0084);
    l{13} = branch.pi("L013", "Rij",0.00127, "Xij",0.0270);
    l{14} = branch.pi("L014", "Rij",0.00082, "Xij",0.0102);
    l{15} = branch.pi("L015", "Rij",0.00022, "Xij",0.0199);
    l{16} = branch.pi("L016", "Rij",0.00034, "Xij",0.0123);
    l{17} = branch.pi("L017", "Rij",0.00175, "Xij",0.0237);
    l{18} = branch.pi("L018", "Rij",0.00036, "Xij",0.0018);
    l{19} = branch.pi("L019", "Rij",0.00030, "Xij",0.0109);
    l{20} = branch.pi("L020", "Rij",0.00108, "Xij",0.0398);
    l{21} = branch.pi("L021", "Rij",0.00130, "Xij",0.0288);
    l{22} = branch.pi("L022", "Rij",0.00035, "Xij",0.0457);
    l{23} = branch.pi("L023", "Rij",0.00016, "Xij",0.0348);
    l{24} = branch.pi("L024", "Rij",0.00070, "Xij",0.0275);
    l{25} = branch.pi("L025", "Rij",0.00080, "Xij",0.0125);
    l{26} = branch.pi("L026", "Rij",0.00063, "Xij",0.0044);
    l{27} = branch.pi("L027", "Rij",0.00020, "Xij",0.0353);
    l{28} = branch.pi("L028", "Rij",0.00054, "Xij",0.0072);
    l{29} = branch.pi("L029", "Rij",0.00040, "Xij",0.0242);
    l{30} = branch.pi("L030", "Rij",0.00137, "Xij",0.0196);
    l{31} = branch.pi("L031", "Rij",0.00090, "Xij",0.0147);
    l{32} = branch.two_winding_transformer("L032", "Rij", 0, "Xij", 0.10912, "Tap", 0.978);
    l{33} = branch.two_winding_transformer("L033", "Rij", 0, "Xij", 0.05618, "Tap", 0.969);
    l{34} = branch.two_winding_transformer("L034", "Rij", 0, "Xij", 0.15202, "Tap", 0.932);

    net.add_branch(l{1} , [3,  4])  
    net.add_branch(l{2} , [3,  5]) 
    net.add_branch(l{3} , [3, 17]) 
    net.add_branch(l{4} , [3, 30]) 
    net.add_branch(l{5} , [4,  5]) 
    net.add_branch(l{6} , [5, 17]) 
    net.add_branch(l{7} , [5, 27]) 
    net.add_branch(l{8} , [5, 28]) 
    net.add_branch(l{9} , [5, 29]) 
    net.add_branch(l{10}, [6, 20]) 
    net.add_branch(l{11}, [6, 22]) 
    net.add_branch(l{12}, [6, 23]) 
    net.add_branch(l{13}, [7, 18]) 
    net.add_branch(l{14}, [7, 20]) 
    net.add_branch(l{15}, [7, 21]) 
    net.add_branch(l{16}, [8, 11]) 
    net.add_branch(l{17}, [9, 10]) 
    net.add_branch(l{18}, [10,11])
    net.add_branch(l{19}, [11, 12])
    net.add_branch(l{20}, [12, 13])
    net.add_branch(l{21}, [12, 16])
    net.add_branch(l{22}, [13, 14])
    net.add_branch(l{23}, [14, 15])
    net.add_branch(l{24}, [15, 19])
    net.add_branch(l{25}, [16, 18])
    net.add_branch(l{26}, [18, 19])
    net.add_branch(l{27}, [23, 24])
    net.add_branch(l{28}, [24, 25])
    net.add_branch(l{29}, [25, 26])
    net.add_branch(l{30}, [26, 27])
    net.add_branch(l{31}, [30,31])
    net.add_branch(l{32}, [1,5])
    net.add_branch(l{33}, [2,6])
    net.add_branch(l{34}, [22,6])

    net.a_Bus{1}.add_component(c{1});
    net.a_Bus{2}.add_component(c{2});
    net.a_Bus{3}.add_component(c{3});
    net.a_Bus{3}.add_component(c{4});
    net.a_Bus{3}.add_component(c{5});
    net.a_Bus{3}.add_component(c{6});
    net.a_Bus{3}.add_component(c{11});
    net.a_Bus{4}.add_component(c{7});
    net.a_Bus{4}.add_component(c{8});
    net.a_Bus{4}.add_component(c{9});
    net.a_Bus{4}.add_component(c{10});
    net.a_Bus{4}.add_component(c{12});
    net.a_Bus{5}.add_component(c{39});
    net.a_Bus{6}.add_component(c{13});
    net.a_Bus{7}.add_component(c{14});
    net.a_Bus{8}.add_component(c{15});
    net.a_Bus{9}.add_component(c{16});
    net.a_Bus{10}.add_component(c{17});
    net.a_Bus{11}.add_component(c{18});
    net.a_Bus{12}.add_component(c{19});
    net.a_Bus{13}.add_component(c{20});
    net.a_Bus{14}.add_component(c{21});
    net.a_Bus{15}.add_component(c{22});
    net.a_Bus{16}.add_component(c{23});
    net.a_Bus{17}.add_component(c{24});
    net.a_Bus{18}.add_component(c{25});
    net.a_Bus{19}.add_component(c{26});
    net.a_Bus{20}.add_component(c{27});
    net.a_Bus{21}.add_component(c{28});
    net.a_Bus{22}.add_component(c{29});
    net.a_Bus{23}.add_component(c{30});
    net.a_Bus{24}.add_component(c{31});
    net.a_Bus{25}.add_component(c{32});
    net.a_Bus{26}.add_component(c{33});
    net.a_Bus{27}.add_component(c{34});
    net.a_Bus{28}.add_component(c{35});
    net.a_Bus{29}.add_component(c{36});
    net.a_Bus{30}.add_component(c{37});
    net.a_Bus{31}.add_component(c{38});


    net.set_pf_set("B001","V",1.06,"Varg",0)
    net.set_pf_set("B002","V",1.00)
    net.set_pf_set("B003","V",1.01)
    net.set_pf_set("B004","V",1.02)
    net.set_pf_set("PARK002","P",0);
    net.set_pf_set("PARK003","P",0.08);
    net.set_pf_set("PARK004","P",0.12);
    net.set_pf_set("PARK005","P",0.05);
    net.set_pf_set("PARK006","P",0.06);
    net.set_pf_set("PARK007","P",0.08);
    net.set_pf_set("PARK008","P",0.10);
    net.set_pf_set("PARK009","P",0.03);
    net.set_pf_set("PARK010","P",0.06);
    net.set_pf_set("PQ001","P",-0.117, "Q",0.127);
    net.set_pf_set("PQ002","P",-0.142, "Q",0.190);
    net.set_pf_set("PQ003","P",-0.278, "Q",0.039);
    net.set_pf_set("PQ004","P",-0.076, "Q",0.016);
    net.set_pf_set("PQ005","P",-0.052, "Q",0.075);
    net.set_pf_set("PQ006","P",-0.295, "Q",0.166);
    net.set_pf_set("PQ007","P",-0.090, "Q",0.058);
    net.set_pf_set("PQ008","P",-0.035, "Q",0.018);
    net.set_pf_set("PQ009","P",-0.061, "Q",0.016);
    net.set_pf_set("PQ010","P",-0.135, "Q",0.058);
    net.set_pf_set("PQ011","P",-0.149, "Q",0.050);
    net.set_pf_set("PQ012","P",-0.035, "Q",0.018);
    net.set_pf_set("PQ013","P",-0.061, "Q",0.016);
    net.set_pf_set("PQ014","P",-0.135, "Q",0.058);
    net.set_pf_set("PQ015","P",-0.149, "Q",0.050);
    net.set_pf_set("PQ016","P",-0.135, "Q",0.018);
    net.set_pf_set("PQ017","P",-0.061, "Q",0.016);
    net.set_pf_set("PQ018","P",-0.135, "Q",0.058);
    net.set_pf_set("PQ019","P",-0.149, "Q",0.050);
    net.set_pf_set("PQ020","P",-0.235, "Q",0.018);
    net.set_pf_set("PQ021","P",-0.061, "Q",0.016);
    net.set_pf_set("PQ022","P",-0.135, "Q",0.058);
    net.set_pf_set("PQ023","P",-0.149, "Q",0.050);
    net.set_pf_set("PQ024","P",-0.135, "Q",0.018);
    net.set_pf_set("PQ025","P",-0.061, "Q",0.016);
    net.set_pf_set("PQ026","P",-0.135, "Q",0.058);
    net.set_pf_set("PQ027","P",-0.149, "Q",0.050);
    net.set_pf_set("PQ028","P",-0.085, "Q",0.040);
    net.set_pf_set("PQ029","P",0     , "Q",0    );
    
    
    b{1}.l_isSlack = true;
    net.initialize;

end