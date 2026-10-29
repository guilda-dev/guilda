classdef IEEE14bus_NoTap < PowerNetwork
% <@Desc>
% IEEE 14-bus network (MATPOWER case14) with every transformer tap set to 1
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
%   network.IEEE14bus with the transformers 4-7, 4-9 and 5-6 modeled at tap 1
%  (plain series impedance, phase 0). All other data are those of IEEE14bus.
%  For the full MATPOWER case14 data, including the off-nominal taps 0.978,
%  0.969 and 0.932, use network.IEEE14bus.
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
% <@Model> IEEE14bus_NoTap
% <@Summary> IEEE 14-bus network (case14 data) with every transformer tap set to 1
% <@Role> PowerNetwork Constructor
% <@Constructor>
%  net = network.IEEE14bus_NoTap()

    properties(Constant)
        ver = 1
    end

    methods
        function obj = IEEE14bus_NoTap()
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            CsvNetHandler.import(str_dirpath, obj);
        end
    end
end
