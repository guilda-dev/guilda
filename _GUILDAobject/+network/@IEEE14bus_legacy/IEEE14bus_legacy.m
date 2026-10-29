classdef IEEE14bus_legacy < PowerNetwork
% <@Desc> 
% IEEE 14-bus network with the data GUILDA used before the case14 correction
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
%   The model includes 14 buses, 5 generators, 11 loads, 16                        
%  transmission lines, and 2 transformers. Buses are classified as:                
%                                                                                  
%  ・Slack Bus (Bus 1)         : The reference bus with a fixed voltage and angle. 
%  ・PV Buses  (Bus 2, 3, 6, 8): Have fixed voltage and real power.                
%  ・PQ Buses  (The rest)      : Have fixed real and reactive power loads.         
%                                                                                  
%                       =<< Legacy Data >>=                                        
%                                                                                  
%   This network reproduces the results of network.IEEE14bus from before the       
%  MATPOWER case14 correction and the CSV tap-import fix. Use it to compare with   
%  or rerun earlier studies. For the standard case14 data use network.IEEE14bus.   
%  Differences from case14: every transformer tap is 1 (the old importer ignored   
%  the taps), line C is the total charging b (and b of 2-4, 2-5, 3-4, 4-5 is       
%  shifted by one row), load Q has the opposite sign except at bus 4, generator    
%  limits are +-Inf, bus voltage limits are 0.5-1.5, and every component,          
%  loads included, has the OPF cost HP = fP = 1.                                   
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
% <@Model> IEEE14bus_legacy
% <@Summary> IEEE 14-bus network with the pre-case14 GUILDA data (reproduces earlier results)
% <@Role> PowerNetwork Constructor
% <@Constructor> 
%  net = network.IEEE14bus_legacy()
 
    properties(Constant)
        ver = 1
    end

    methods
        function obj = IEEE14bus_legacy()
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            CsvNetHandler.import(str_dirpath, obj);
        end
    end
end
