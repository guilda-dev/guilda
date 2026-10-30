classdef IEEE14bus_lossless < PowerNetwork
% <@Desc> 
% test code of ieee-14bus system without transmission losses
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
%   The same data as network.IEEE14bus (MATPOWER case14 on a 100 MVA base) with the
%  resistance R of every branch set to 0, so the network has no real-power loss.
%  The other data are kept on purpose:
%  ・Line charging C and the bus shunt (bus 9, Bshunt = 0.19) stay; they are pure
%    susceptances and take no real power. Every bus has Gshunt = 0.
%  ・The transformer taps (4-7, 4-9, 5-6) stay.
%  ・Bus voltages, loads, generator limits and costs are those of network.IEEE14bus.
%   With these data the generator outputs sum exactly to the loads.
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
% <@Model> IEEE14bus(lossless)
% <@Summary> The PowerNetwork class for the IEEE 14-bus model, which ignores transmission losses
% <@Role> PowerNetwork Constructor
% <@Constructor> 
%  net = network.IEEE14bus_lossless()
 
    properties(Constant)
        ver = 1
    end

    methods
        function obj = IEEE14bus_lossless()
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
