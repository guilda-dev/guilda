classdef Test31bus < PowerNetwork
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

    properties(SetAccess=private)
        ver = 1.1
    end

    methods
        function obj = Test31bus()
            obj@PowerNetwork("Test31bus")

            % Bus
            obj.add_bus("V", 1.06, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.01, "Varg", 0);
            obj.add_bus("V", 1.02, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            obj.add_bus("V", 1.00, "Varg", 0);
            

            % Branch
            obj.add_branch("pi", [ 3, 4], "R",0.00019, "X",0.0059);
            obj.add_branch("pi", [ 3, 5], "R",0.00054, "X",0.0223);
            obj.add_branch("pi", [ 3,17], "R",0.00046, "X",0.0197);
            obj.add_branch("pi", [ 3,30], "R",0.00058, "X",0.0176);
            obj.add_branch("pi", [ 4, 5], "R",0.00056, "X",0.0173);
            obj.add_branch("pi", [ 5,17], "R",0.00067, "X",0.0171);
            obj.add_branch("pi", [ 5,27], "R",0.00013, "X",0.0042);
            obj.add_branch("pi", [ 5,28], "R",0.00034, "X",0.0198);
            obj.add_branch("pi", [ 5,29], "R",0.00122, "X",0.0255);
            obj.add_branch("pi", [ 6,20], "R",0.00066, "X",0.0130);
            obj.add_branch("pi", [ 6,22], "R",0.00045, "X",0.0110);
            obj.add_branch("pi", [ 6,23], "R",0.00031, "X",0.0084);
            obj.add_branch("pi", [ 7,18], "R",0.00127, "X",0.0270);
            obj.add_branch("pi", [ 7,20], "R",0.00082, "X",0.0102);
            obj.add_branch("pi", [ 7,21], "R",0.00022, "X",0.0199);
            obj.add_branch("pi", [ 8,11], "R",0.00034, "X",0.0123);
            obj.add_branch("pi", [ 9,10], "R",0.00175, "X",0.0237);
            obj.add_branch("pi", [10,11], "R",0.00036, "X",0.0018);
            obj.add_branch("pi", [11,12], "R",0.00030, "X",0.0109);
            obj.add_branch("pi", [12,13], "R",0.00108, "X",0.0398);
            obj.add_branch("pi", [12,16], "R",0.00130, "X",0.0288);
            obj.add_branch("pi", [13,14], "R",0.00035, "X",0.0457);
            obj.add_branch("pi", [14,15], "R",0.00016, "X",0.0348);
            obj.add_branch("pi", [15,19], "R",0.00070, "X",0.0275);
            obj.add_branch("pi", [16,18], "R",0.00080, "X",0.0125);
            obj.add_branch("pi", [18,19], "R",0.00063, "X",0.0044);
            obj.add_branch("pi", [23,24], "R",0.00020, "X",0.0353); 
            obj.add_branch("pi", [24,25], "R",0.00054, "X",0.0072);
            obj.add_branch("pi", [25,26], "R",0.00040, "X",0.0242);
            obj.add_branch("pi", [26,27], "R",0.00137, "X",0.0196);
            obj.add_branch("pi", [30,31], "R",0.00090, "X",0.0147);
            obj.add_branch("two_winding_transformer", [ 1, 5], "R", 0, "X", 0.10912, "Tap", 0.978);
            obj.add_branch("two_winding_transformer", [ 2, 6], "R", 0, "X", 0.05618, "Tap", 0.969);
            obj.add_branch("two_winding_transformer", [22, 6], "R", 0, "X", 0.15202, "Tap", 0.932);

            % Component: Generator
            M     = 10;     D     = 2;
            Td_p  = 5;      Td_pp = 0.03;
            Tq_p  = 5;      Tq_pp = 0.03;
            Xd    = 0.305;  Xd_p  = 0.25;       Xd_pp = 0.15;
            Xq    = 1;      Xq_p  = 0.75;       Xq_pp = 0.45;       X_ls  = 0;
            tab = table(M,D,Xd,Xd_p,Xd_pp,Xq,Xq_p,Xq_pp,X_ls,Td_p,Td_pp,Tq_p,Tq_pp);
            
            obj.a_Bus{ 1}.add_component("gen-park", "parameter", tab);
            obj.a_Bus{ 2}.add_component("gen-park", "parameter", tab, "P", 0.00);
            obj.a_Bus{ 3}.add_component("gen-park", "parameter", tab, "P", 0.08);
            obj.a_Bus{ 3}.add_component("gen-park", "parameter", tab, "P", 0.12);
            obj.a_Bus{ 3}.add_component("gen-park", "parameter", tab, "P", 0.05);
            obj.a_Bus{ 3}.add_component("gen-park", "parameter", tab, "P", 0.06);
            obj.a_Bus{ 4}.add_component("gen-park", "parameter", tab, "P", 0.08);
            obj.a_Bus{ 4}.add_component("gen-park", "parameter", tab, "P", 0.10);
            obj.a_Bus{ 4}.add_component("gen-park", "parameter", tab, "P", 0.03);
            obj.a_Bus{ 4}.add_component("gen-park", "parameter", tab, "P", 0.06);

            % Component: Load
            obj.a_Bus{ 3}.add_component("load-power", "P", -0.117, "Q", 0.127);
            obj.a_Bus{ 4}.add_component("load-power", "P", -0.142, "Q", 0.190);
            obj.a_Bus{ 6}.add_component("load-power", "P", -0.278, "Q", 0.039);
            obj.a_Bus{ 7}.add_component("load-power", "P", -0.076, "Q", 0.016);
            obj.a_Bus{ 8}.add_component("load-power", "P", -0.052, "Q", 0.075);
            obj.a_Bus{ 9}.add_component("load-power", "P", -0.295, "Q", 0.166);
            obj.a_Bus{10}.add_component("load-power", "P", -0.090, "Q", 0.058);
            obj.a_Bus{11}.add_component("load-power", "P", -0.035, "Q", 0.018);
            obj.a_Bus{12}.add_component("load-power", "P", -0.061, "Q", 0.016);
            obj.a_Bus{13}.add_component("load-power", "P", -0.135, "Q", 0.058);
            obj.a_Bus{14}.add_component("load-power", "P", -0.149, "Q", 0.050);
            obj.a_Bus{15}.add_component("load-power", "P", -0.035, "Q", 0.018);
            obj.a_Bus{16}.add_component("load-power", "P", -0.061, "Q", 0.016);
            obj.a_Bus{17}.add_component("load-power", "P", -0.135, "Q", 0.058);
            obj.a_Bus{18}.add_component("load-power", "P", -0.149, "Q", 0.050);
            obj.a_Bus{19}.add_component("load-power", "P", -0.135, "Q", 0.018);
            obj.a_Bus{20}.add_component("load-power", "P", -0.061, "Q", 0.016);
            obj.a_Bus{21}.add_component("load-power", "P", -0.135, "Q", 0.058);
            obj.a_Bus{22}.add_component("load-power", "P", -0.149, "Q", 0.050);
            obj.a_Bus{23}.add_component("load-power", "P", -0.235, "Q", 0.018);
            obj.a_Bus{24}.add_component("load-power", "P", -0.061, "Q", 0.016);
            obj.a_Bus{25}.add_component("load-power", "P", -0.135, "Q", 0.058);
            obj.a_Bus{26}.add_component("load-power", "P", -0.149, "Q", 0.050);
            obj.a_Bus{27}.add_component("load-power", "P", -0.135, "Q", 0.018);
            obj.a_Bus{28}.add_component("load-power", "P", -0.061, "Q", 0.016);
            obj.a_Bus{29}.add_component("load-power", "P", -0.135, "Q", 0.058);
            obj.a_Bus{30}.add_component("load-power", "P", -0.149, "Q", 0.050);
            obj.a_Bus{31}.add_component("load-power", "P", -0.085, "Q", 0.040);
            obj.a_Bus{ 5}.add_component("load-power", "P",  0.000, "Q", 0.000);
 
            b{1}.l_isSlack = true;
            obj.initialize;
        
        end
    end
end