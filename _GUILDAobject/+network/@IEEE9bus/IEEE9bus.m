classdef IEEE9bus < PowerNetwork
% IEEE 9-bus test system (WSCC 3-machine), with AVRs and PSSs on request.
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
% - By default (`LocalController=false`) each generator keeps the Static AVR and governor
%   (`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.
%   With `LocalController=true` each generator has an AVR and a PSS
%   (`local_controller/avr-ST1`, `local_controller/pss-PSS1`):
%   - The v2 AVR sadamoto2019 (`Ka`, `Te`) is controller.avr.AVR_ST1 with `kap = Ka`,
%     `tap = Te`, `ttr = 0` (no transducer lag), `kst = tst = 0` and no limits
%     (`Vap_max = Inf`, `Vap_min = -Inf`, `Limiter = 1`).
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
% <@Citations>
% - P. M. Anderson and A. A. Fouad, *Power System Control and Stability*, 2nd ed.
%   Piscataway, NJ, USA: IEEE Press / Wiley-Interscience, 2003, doi:
%   [10.1109/9780470545577](https://doi.org/10.1109/9780470545577).
%
% <@Examples>
% Run the power flow and simulate a fault at bus 7:
%
% ```matlab
% net = network.IEEE9bus();      % Static AVRs and governors only
% res = net.calculate_powerflow();
% sc  = net.add_scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% sol = net.simulate("fault");
%
% % With the AVRs and PSSs
% net = network.IEEE9bus(LocalController=true);
% ```
%
% See also controller.avr.AVR_ST1, controller.pss.PSS1, network.IEEE68bus

    properties(Constant) % Data
        ver = 1  % Version of the bundled network data.
    end

    methods
        function obj = IEEE9bus(opt)
            % Create the network from the CSV data in the class folder.
            arguments (Input)
                opt.LocalController (1,1) logical = false  % true to add an AVR and a PSS to every generator; false keeps the default Static AVR and governor (avr-static, gov-static) on the generators.
            end
            arguments (Output)
                obj  % IEEE9bus network.
            end
            s_filepath   = mfilename("fullpath");
            s_dirpath    = fileparts(s_filepath);
            PowerNetwork.import(s_dirpath, Network=obj, Initialize=false);   % with the controllers of local_controller/
            if ~opt.LocalController
                % no controller of local_controller/: the generators keep the default Static AVR and governor
                for b = 1:numel(obj.a_Bus)
                    for comp = reshape(obj.a_Bus{b}.a_Component, 1, [])
                        for con = reshape(comp{1}.a_LocalController, 1, [])
                            if con{1}.key ~= "avr-static" && con{1}.key ~= "gov-static"
                                s_role = con{1}.s_role;
                                comp{1}.remove_local_controller(con{1}.s_tag, RemoveNested=true);   % the PSS under an AVR too
                                if s_role == "avr"
                                    comp{1}.add_local_controller("avr-static");
                                elseif s_role == "governor"
                                    comp{1}.add_local_controller("gov-static");
                                end
                            end
                        end
                    end
                end
            end
            obj.initialize;
        end
    end
end
