classdef IEEE14bus_lossless < PowerNetwork
% IEEE 14-bus test system (MATPOWER case14) without branch resistance.
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
% The data are those of network.IEEE14bus with the resistance `R` of every
% branch set to 0, so the network has no real-power loss. The other data are
% kept on purpose:
%
% - Line charging `C` and the bus shunt (bus 9, `Bshunt = 0.19`) stay; they are
%   pure susceptances and take no real power. Every bus has `Gshunt = 0`.
% - The transformer taps (4-7, 4-9, 5-6) stay.
% - Bus voltages, loads, generator limits and costs are those of network.IEEE14bus.
%
% With these data the generator outputs sum exactly to the loads.
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
% net = network.IEEE14bus_lossless();
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
% sol = net.simulate([0,10], ev);
% ```
%
% See also network.IEEE14bus, network.IEEE14bus_NoTap

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEE14bus_lossless()
            % Create the network from the CSV data in the class folder.
            arguments (Output)
                obj % IEEE14bus_lossless network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
