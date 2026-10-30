classdef IEEE14bus < PowerNetwork
% IEEE 14-bus test system (MATPOWER case14).
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
% The power-flow and OPF data are those of MATPOWER case14: line constants
% (`C = b/2` at each end), transformer taps, loads, the bus shunt, bus voltage
% limits 0.94-1.06, generator limits and the gencost (`HP = c2*100^2`,
% `fP = c1*100`). GUILDA-specific choices:
%
% - Every generator (the compensators at buses 3, 6 and 8 too) is a gen-park
%   model with the same dynamic parameters; case14 has no dynamic data.
% - Bus 7 has a load with zero power, so a load can be changed there.
% - Loads have no OPF cost (`HP = fP = 0`); a fixed load's cost would only add a constant.
% - Branch 7-9 (a transformer winding in case14, tap 1) is a pi line.
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
% net = network.IEEE14bus();
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
% sol = net.simulate([0,10], ev);
% ```
%
% See also network.IEEE14bus_NoTap, network.IEEE14bus_lossless, PowerNetwork.import_matpower

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEE14bus()
            % Create the network from the CSV data in the class folder.
            arguments (Output)
                obj % IEEE14bus network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
