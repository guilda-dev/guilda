classdef IEEE68bus < PowerNetwork
% IEEE 68-bus test system (NETS-NYPS 16-machine) with AVRs and PSSs.
% The 68-bus, 16-machine reduced model of the New England Test System (NETS) and
% the New York Power System (NYPS) with three neighbouring areas, from B. Pal and
% B. Chaudhuri, "Robust Control in Power Systems", Springer, 2005, pp. 171-178.
% It is a standard benchmark for inter-area oscillations and wide-area control.
% It has 68 buses, 83 branches (64 lines and 19 transformers), 16 generators and
% 35 loads; 60 Hz, 100 MVA base.
%
% Bus types:
%
% - Slack bus: bus 16
% - PV buses: buses 1 to 15
% - PQ buses: buses 17 to 68
%
% Data:
%
% The values are those of the v2 CSV files (kept in `archive/IEEE68bus`); only the
% format is converted:
%
% - Branches with tap 0 in the v2 file are pi lines; the others are pi_transformer
%   branches with the v2 tap and phase. The line charging is given at each end
%   (`C = b/2`), as in the v2 files.
% - Generators are gen-1axis models with the v2 generator_1axis data (`M`, `D`, `Xd`,
%   `Xq`, `Xd_p`, `Td_p`), as network.build used them.
% - Loads are load-impedance models (constant impedance at the power-flow solution).
% - Each generator has an AVR and a PSS (data in `controller/avr`, `controller/pss`):
%   - The v2 AVR sadamoto2019 (`Ka`, `Te`) is controller.avr.AVR_ST1 with `kap = Ka`,
%     `tap = Te`, `ttr = 0` (no transducer lag), `kst = tst = 0` and no limits.
%   - The v2 PSS (`Kpss`, `Tpss`, `TL1p`, `TL1`, `TL2p`, `TL2`) has the transfer function
%     `Kpss/Tpss * Tpss*s/(1+Tpss*s) * (1+TL1p*s)/(1+TL1*s) * (1+TL2p*s)/(1+TL2*s)`,
%     which is controller.pss.PSS1 with `kpss = Kpss/Tpss`, `tWS = Tpss`, `tn1 = TL1p`,
%     `td1 = TL1`, `tn2 = TL2p`, `td2 = TL2`.
% - The bus coordinates `Xaxis`, `Yaxis` are the v2 `GraphX`, `GraphY`.
% - The v2 files have no voltage limits, base voltages or OPF data; these are the
%   GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for
%   generators and 0 for loads).
% - `archive/IEEE68bus` also has data that network.build did not use (generator_park,
%   avr_IEEE_ST1, excitation); they are not part of this network.
%
% Without the AVRs and PSSs (`LocalController=false`) the equilibrium is unstable.
%
% <@Examples>
% Run the power flow and simulate a fault at bus 1:
%
% ```matlab
% net = network.IEEE68bus();
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B001");
% sol = net.simulate([0,10], ev);
% ```
%
% See also controller.avr.AVR_ST1, controller.pss.PSS1, network.IEEE9bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEE68bus(opt)
            % Create the network from the CSV data in the class folder.
            arguments
                opt.LocalController (1,1) logical = true % true to add an AVR and a PSS to every generator.
            end
            arguments (Output)
                obj % IEEE68bus network.
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
