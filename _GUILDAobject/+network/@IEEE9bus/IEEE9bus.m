classdef IEEE9bus < PowerNetwork
% IEEE 9-bus test system (WSCC 3-machine) with AVRs and PSSs.
% The 9-bus, 3-machine system of the Western System Coordinating Council, as it
% was used in the simulator that preceded GUILDA (network.IEEE9bus_past of
% GUILDA v2). It has 9 buses, 9 branches (6 lines and 3 transformers),
% 3 generators and 3 loads; 60 Hz, 100 MVA base.
%
% Bus types:
%
% - Slack bus: bus 1
% - PV buses: buses 2 and 3
% - PQ buses: the other buses
%
% Data:
%
% The values are those of the v2 CSV files (kept in `archive/IEEE9bus_past`); only
% the format is converted:
%
% - Lines are pi lines and transformers pi_transformer branches (tap 1); the line
%   charging is given at each end (`C = b/2`), as in the v2 files.
% - Generators are gen-1axis models. Their `M`, `D` and reactances are the values of
%   the earlier simulator, not the textbook (Anderson & Fouad) machine data.
% - Loads are load-impedance models (constant impedance at the power-flow solution).
% - Each generator has an AVR and a PSS (data in `controller/avr`, `controller/pss`):
%   - The v2 AVR sadamoto2019 (`Ka`, `Te`) is controller.avr.AVR_ST1 with `kap = Ka`,
%     `tap = Te`, `ttr = 0` (no transducer lag), `kst = tst = 0` and no limits.
%   - The v2 PSS (`Kpss`, `Tpss`, `TL1p`, `TL1`, `TL2p`, `TL2`) has the transfer function
%     `Kpss/Tpss * Tpss*s/(1+Tpss*s) * (1+TL1p*s)/(1+TL1*s) * (1+TL2p*s)/(1+TL2*s)`,
%     which is controller.pss.PSS1 with `kpss = Kpss/Tpss`, `tWS = Tpss`, `tn1 = TL1p`,
%     `td1 = TL1`, `tn2 = TL2p`, `td2 = TL2`.
% - The v2 files have no voltage limits, base voltages or OPF data; these are the
%   GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for
%   generators and 0 for loads).
%
% Diagram:
%
% ```
%              (2)          (7)        (8)        (9)          (3)
%      SG ---=====--~~~--=======-----=====-----=======--~~~--=====--- SG
%                            |          |          |
%                            |          LL         |
%                            |                     |
%                        LL ===== (5)        (6) ===== LL
%                            |                     |
%                            └-------┐     ┌-------┘
%                                    |     |
%                                   ======== (4)
%                                       |
%                                      ~~~
%                                       |
%                                     ===== (1)
%                                       |
%                                       SG
%
% < symbol >       < name >
%   --, | :   Transmission Line
%    ~~~  :   Transformer
%    SG   :   Synchronous Generator
%    LL   :   Load
%    ===  :   Bus
%    (.)  :   Bus Number
% ```
%
% <@Examples>
% Run the power flow and simulate a fault at bus 7:
%
% ```matlab
% net = network.IEEE9bus();
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B007");
% sol = net.simulate([0,10], ev);
%
% % Without the AVRs and PSSs
% net = network.IEEE9bus(LocalController=false);
% ```
%
% See also controller.avr.AVR_ST1, controller.pss.PSS1, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEE9bus(opt)
            % Create the network from the CSV data in the class folder.
            arguments
                opt.LocalController (1,1) logical = true % true to add an AVR and a PSS to every generator.
            end
            arguments (Output)
                obj % IEEE9bus network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj, Initialize=false);
            if opt.LocalController
                add_avr_pss(obj, str_dirpath);
            end
            obj.initialize;
        end
    end
end


function add_avr_pss(net, str_dirpath)
% controller/avr/parameter.csv : AVR_ST1 parameters of the generator at each Bus
% controller/pss/parameter.csv : PSS1 parameters of the generator at each Bus
    tab_avr = readtable(fullfile(str_dirpath, "controller", "avr", "parameter.csv"));
    tab_pss = readtable(fullfile(str_dirpath, "controller", "pss", "parameter.csv"));
    for i = 1:height(tab_avr)
        i_bus = tab_avr.Bus(i);
        c_avr = namedargs2cell(table2struct(removevars(tab_avr(i,:), "Bus")));
        avr   = controller.avr.AVR_ST1("avr" + i_bus, c_avr{:});
        i_pss = find(tab_pss.Bus == i_bus);
        gen   = net.a_Bus{i_bus}.a_Component{1};
        if isempty(i_pss)
            gen.add_local_controller(avr);
        else
            c_pss = namedargs2cell(table2struct(removevars(tab_pss(i_pss,:), "Bus")));
            gen.add_local_controller(avr, controller.pss.PSS1("pss" + i_bus, c_pss{:}));
        end
    end
end
