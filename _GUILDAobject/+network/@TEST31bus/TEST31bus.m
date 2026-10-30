classdef TEST31bus < PowerNetwork
% 31-bus test system with 10 generators.
% It has 31 buses, 34 branches, 10 generators (gen-park) and 29 loads
% (load-power) on a 100 MVA base. The bus names
% in the diagram (510, 530, ...) are given with the GUILDA bus numbers in
% parentheses.
%
% Diagram:
%
% ```
%                                          510 (8)
%                                           ||
%                                       ┌---||---┐
%                                       |   ||   |
%                                       LL       |
%                                                |
%                                                |
%                            530 (9)   520 (10)  |  500 (11)          320 (12)      340 (13)           330 (14)          350 (15)
%                              ||         ||     └---||                  ||-------------||----------------||----------------||
%                          ┌---||---------||---------||------------------||             ||                ||                ||
%                          |   ||         ||---┐     ||---┐          ┌---||---┐         ||---┐        ┌---||        ┌-------||---┐            100 (3)
%                          |                   |          |          |        |              |        |             |            |               ||
%                          LL                  LL         LL         LL       |              LL       LL            |            LL              ||-----SG
%                                                                             | ┌---LL                              |                            ||
%                                                                             | |                                   |                            ||
%                                                                 310 (16) =======                                  |               110 (17)     ||
%                                                                             |                                     |                  ||        ||-----SG
%                                                                             |                                     |         ┌--------||--------||
%                                                                             | ┌---LL                              |         |    ┌---||        ||
%                                                                             | |                                   |         |    |             ||
%                                                                          ======= 300 (18)             360 (19)    |         |    LL            ||-----SG
%                                        250 (20)          260 (7)          |   |                         ||        |         |                  ||
%                                          ||               ||--------------┘   └-------------------------||--------┘         |                  ||
%                                     ┌----||---------------||         370 (21)                           ||---┐              |     ┌------------||
%                                     |    ||---┐           ||            ||                                   |              |     |            ||-----SG
%                                     |         |           ||------------||---┐                               LL             |     |            ||
%                                     |         LL          ||            ||   |                                              |     |            ||
%                                     |                     ||---┐             LL                         1311 (1)            |     |       ┌----||--------------------┐
%                                     |                          |                                         ||                 |     |       |    ||------┐             |
%                                     |                          LL                                 ┌------||----SG           |     |       LL           |             |
%                                     |                                                             |      ||                 |     |                    |         ========= 170 (30)
%                                     |                                                             |                         |     |                    |             |  |
%                                     |                                             130 (5) ============================================                 |             |  LL
%                                     |                                                       |           |            |            |            ||------┘             |
%          2412 (2)    240 (6)        |                                                       |           |            |            |            ||                    |
%               ||        ||          |                                                       |           |            |            |            ||                 ======= 180 (31)
%         SC----||--------||----------┘                                                       |           |            |            |            ||-----SG             |
%               ||        ||                                                                  |           |            |            |            ||                    |
%                         ||----┐                                                             |           |            |            └------------||                    LL
%                         ||    |                                                             |           |            |                         ||
%            270 (22)     ||    LL   230 (23)   220 (24)    210 (25)   200 (26)    150 (27)   |           |            |                         ||-----SG
%               ||        ||          ||          ||          ||          ||          ||      |           |            |                         ||
%          ┌----||--------||----------||----------||----------||----------||----------||------┘           |            |                    ┌----||
%          |    ||        ||          ||---┐      ||---┐      ||---┐      ||---┐      ||---┐              |            |                    |    ||
%          LL                              |           |           |           |           |   140 (28) =====        ===== 160 (29)         |    ||-----SG
%                                          LL          LL          LL          LL          LL             |            |                    LL   ||
%                                                                                                         |            |                         ||
%                                                                                                         LL           LL                        ||
% < symbol >         < name >                                                                                                                    ||-----SG
%    --, |   :   Transmission Line                                                                                                               ||
%                                                                                                                                                ||
%     >>                                                                                                                                        120 (4)
%     >>     :   Transformer
%     >>
%
%     SG     :   Synchronous Generator
%     SC     :   Synchronous Compensator
%     LL     :   Load
%   ===, ||  :   Bus
%     (.)    :   Bus Number
% ```
%
% <@Examples>
% Run the power flow and simulate a rotor-angle offset of the generator at bus 1:
%
% ```matlab
% net = network.TEST31bus();
% res = net.calculate_powerflow();
% ev  = odeEventSet("offset", net, "TimeSpan", 1, "OffsetUnit", "SG1B001", ...
%                   "OffsetState", "delta", "OffsetValue", 0.1);
% sol = net.simulate([0,10], ev);
% ```
%
% See also network.IEEE14bus

    properties(Constant) % Data
        ver = 1.1 % Version of the bundled network data.
    end

    methods
        function obj = TEST31bus()
            % Create the network from the CSV data in the class folder.
            arguments (Output)
                obj % TEST31bus network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
