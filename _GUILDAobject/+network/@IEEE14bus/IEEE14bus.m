classdef IEEE14bus < PowerNetwork
% <@Desc> 
% test code of ieee-14bus system
%==================================================================================
%                          <<< IEEE 14-Bus System >>>                              
%==================================================================================
%                                                                                  
%   The IEEE 14-bus system is a standard test case for power system analysis.      
%  It represents a small part of the American Electric Power System and is         
%  widely used to test power flow, stability, and contingency analysis.            
%                                                                                  
%                       =<< System Overview >>=                                    
%                                                                                  
%   The model includes 14 buses, 5 generators, 12 loads, 16
%  transmission lines, and 4 transformers. Buses are classified as:
%
%  ・Slack Bus (Bus 1)         : The reference bus with a fixed voltage and angle.
%  ・PV Buses  (Bus 2, 3, 6, 8): Have fixed voltage and real power.
%  ・PQ Buses  (The rest)      : Have fixed real and reactive power loads.
%
%                       =<< Data >>=
%
%   The power-flow and OPF data are those of MATPOWER case14 on a 100 MVA base:
%  line constants (C = b/2 at each end), transformer taps, loads, the bus shunt,
%  bus voltage limits 0.94-1.06, generator limits and the gencost
%  (HP = c2*100^2, fP = c1*100). GUILDA-specific choices:
%  ・Every generator (the compensators at buses 3, 6, 8 too) is a gen-park model
%    with the same dynamic parameters; case14 has no dynamic data.
%  ・Bus 7 has a load with zero power, so a load can be changed there.
%  ・Loads have no OPF cost (HP = fP = 0); a fixed load's cost would only add a
%    constant.
%  ・Branch 7-9 (a transformer winding in case14, tap 1) is a pi line.
%   network.IEEE14bus_NoTap is the same network with every transformer tap 1.     
%
%==================================================================================
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
%  <Summary>
%   Bus       : 14
%   Branch    : 20
%   Component : 17
%    > SG     : 5
%    > Load   : 12
%    > Others : 0
% ====================================================================================
% <@Model> IEEE14bus
% <@Summary> The PowerNetwork Class in the IEEE 14-Bus Model
% <@Role> PowerNetwork Constructor
% <@Constructor> 
%  net = network.IEEE14bus()
 
    properties(Constant)
        ver = 1
    end

    methods
        function obj = IEEE14bus()
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
