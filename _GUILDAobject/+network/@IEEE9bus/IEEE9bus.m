classdef IEEE9bus < PowerNetwork
% <@Desc>
% test code of ieee-9bus system
%==================================================================================
%                     <<< IEEE 9-Bus System (WSCC 3-machine) >>>
%==================================================================================
%
%   The 9-bus, 3-machine system of the Western System Coordinating Council, as it
%  was used in the simulator that preceded GUILDA (network.IEEE9bus_past of
%  GUILDA v2). 60 Hz, 100 MVA base.
%
%                       =<< System Overview >>=
%
%   The model includes 9 buses, 3 generators, 3 loads, 6 transmission lines and
%  3 transformers. Buses are classified as:
%
%  ・Slack Bus (Bus 1)   : The reference bus with a fixed voltage and angle.
%  ・PV Buses  (Bus 2, 3): Have fixed voltage and real power.
%  ・PQ Buses  (The rest): Have fixed real and reactive power loads.
%
%                       =<< Data >>=
%
%   The values are those of the v2 CSV files (kept in archive/IEEE9bus_past); only
%  the format is converted:
%  ・Lines are pi lines and transformers pi_transformer branches (tap 1); the line
%    charging is given at each end (C = b/2), as in the v2 files.
%  ・Generators are gen-1axis models. Their M, D and reactances are the values of
%    the earlier simulator, not the textbook (Anderson & Fouad) machine data.
%  ・Loads are load-impedance models (constant impedance at the power-flow solution).
%  ・Each generator has an AVR and a PSS (controller/avr, controller/pss):
%    - The v2 AVR sadamoto2019 (Ka, Te) is controller.avr.AVR_ST1 with kap = Ka,
%      tap = Te, ttr = 0 (no transducer lag), kst = tst = 0 and no limits.
%    - The v2 PSS (Kpss, Tpss, TL1p, TL1, TL2p, TL2) has the transfer function
%      Kpss/Tpss * Tpss*s/(1+Tpss*s) * (1+TL1p*s)/(1+TL1*s) * (1+TL2p*s)/(1+TL2*s),
%      which is controller.pss.PSS1 with kpss = Kpss/Tpss, tWS = Tpss, tn1 = TL1p,
%      td1 = TL1, tn2 = TL2p, td2 = TL2.
%  ・The v2 files have no voltage limits, base voltages or OPF data; these are the
%    GUILDA defaults (Vmin 0.5, Vmax 1.5, baseKV 230, OPF cost HP = fP = 1).
%
%==================================================================================
%
%                    =<< IEEE 9-Bus System Diagram >>=
%
%
%                (2)          (7)        (8)        (9)          (3)
%        SG ---=====--~~~--=======-----=====-----=======--~~~--=====--- SG
%                              |          |          |
%                              |          LL         |
%                              |                     |
%                          LL ===== (5)        (6) ===== LL
%                              |                     |
%                              └-------┐     ┌-------┘
%                                      |     |
%                                     ======== (4)
%                                         |
%                                        ~~~
%                                         |
%                                       ===== (1)
%                                         |
%                                         SG
%
%   < symbol >       < name >
%     --, | :   Transmission Line
%      ~~~  :   Transformer
%      SG   :   Synchronous Generator
%      LL   :   Load
%      ===  :   Bus
%      (.)  :   Bus Number
%
%  <Summary>
%   Bus       : 9
%   Branch    : 9
%   Component : 6
%    > SG     : 3
%    > Load   : 3
%    > Others : 0
% ====================================================================================
% <@Model> IEEE9bus
% <@Summary> The PowerNetwork class for the IEEE (WSCC) 9-bus model with AVRs and PSSs
% <@Role> PowerNetwork Constructor
% <@Constructor>
%  net = network.IEEE9bus()
%  net = network.IEEE9bus(LocalController=false)
%  LocalController=false builds the generators without the AVRs and PSSs.

    properties(Constant)
        ver = 1
    end

    methods
        function obj = IEEE9bus(opt)
            arguments
                opt.LocalController (1,1) logical = true
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
