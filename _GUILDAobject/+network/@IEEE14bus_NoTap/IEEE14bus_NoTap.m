classdef IEEE14bus_NoTap < PowerNetwork
% IEEE 14-bus test system (MATPOWER case14) with every transformer tap set to 1.
% The IEEE 14-bus system represents a part of the American Electric Power
% System and is a standard test case for power flow, stability and
% contingency analysis. It has 14 buses, 20 branches (16 lines and 4
% transformers in case14), 5 generators and 12 loads on a 100 MVA base.
%
% Bus types:
%
% - Slack bus: bus 1
% - PV buses: buses 2, 3, 6 and 8
% - PQ buses: the other buses
%
% Data:
%
% This is network.IEEE14bus with the transformers 4-7, 4-9 and 5-6 modeled at
% tap 1 (plain series impedance, phase 0). All other data are those of
% network.IEEE14bus. For the full case14 data, including the off-nominal taps
% 0.978, 0.969 and 0.932, use network.IEEE14bus.
%
% Diagram:
%
% ```
%                           LL             LL
%                           |              |
%                 (13) ===========       ===== (14)
%                       |   |   |         | |
%             LL        |   |   └---------┘ └------------┐
%             |         |   |                            |
%      (12) =====       |   |        LL      LL          |
%            | |        |   |        |       |           |
%            | └--------┘   | (11) =====   ===== (10)    |
%            |              |       | |     | |          |
%            └----------┐   |   ┌---┘ └-----┘ └-----┐    |
%                       |   |   |                   |    |   ┌-- LL
%                       |   |   |                   |    |   |
%                      =========== (6)       (9) ==============
%                       |   |   |                 |   |      | ┌-----------┐
%                       SC  |   LL               ///  |      | |           |
%                          ~~~                       ~~~    ~~~~~ (7)     === (8)
%                           |                         |       |            |
%   SG               LL --┐ |                         |       |            SC
%   |                     | |                     ============== (4)
% ===== (1)              ======= (5)               |  |  |    |
%  | |                    | | |                    |  |  |    LL
%  | └--------------------┘ | └--------------------┘  |  |
%  └----------┐  ┌----------┘                         |  |
%             |  |  ┌---------------------------------┘  |
%             |  |  |                                    |
%             |  |  |                       ┌------------┘
%            ========= (2)                  |
%             |  |  |                       |
%             SG LL |                       |
%                   └-------------------┐   |
%                                       |   |
%                                       |   |
%                                      ======= (3)
%                                       |   |
%                                       SC  LL
%
%
% < symbol >       < name >
%   --, | :   Transmission Line
%    ~~~  :   Transformer
%    SG   :   Synchronous Generator
%    SC   :   Synchronous Compensator
%    LL   :   Load
%    ===  :   Bus
%    (.)  :   Bus Number
%    ///  :   Shunt (bus)
% ```
%
% <@Examples>
% Run the power flow and simulate a fault at bus 8:
%
% ```matlab
% net = network.IEEE14bus_NoTap();
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
% sol = net.simulate([0,10], ev);
% ```
%
% See also network.IEEE14bus, network.IEEE14bus_lossless

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEE14bus_NoTap()
            % Create the network from the CSV data in the class folder.
            arguments (Output)
                obj % IEEE14bus_NoTap network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
