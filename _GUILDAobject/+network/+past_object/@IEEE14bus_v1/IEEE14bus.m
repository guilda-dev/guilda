classdef IEEE14bus < PowerNetwork
% <@Desc> 
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
% <@Role> PowerNetwork COnstructor
% <@Constructor> 
%  net = IEEE14bus()
 

    properties(Constant)
        ver = 1.1
    end

    methods
        function obj = IEEE14bus()
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            CsvNetHandler.import(str_dirpath, obj);
        end
    end
end
