classdef IEEE68bus < PowerNetwork
% IEEE 68-bus test system (NETS-NYPS 16-machine), with AVRs and PSSs on request.
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
% - By default (`LocalController=false`) each generator keeps the Static AVR and governor
%   (`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.
%   With `LocalController=true` each generator has an AVR and a PSS
%   (`local_controller/avr-ST1`, `local_controller/pss-PSS1`):
%   - The v2 AVR sadamoto2019 (`Ka`, `Te`) is controller.avr.AVR_ST1 with `kap = Ka`,
%     `tap = Te`, `ttr = 0` (no transducer lag) and `kst = tst = 0`.
%   - The AVRs have the limiter on (`Limiter = 1`) with `Vap_max = 5`, `Vap_min = -5`
%     [pu], which the v2 data does not have. +-5 pu is the field voltage limit of the
%     static exciters in the 68-bus data: generator 9 of the PST v3 `data16m.m`
%     (G. Rogers and J. Chow, Power System Toolbox), all 16 machines of the SNL PSTess
%     `data16m.m`, and the SEXS of generator 9 in the PSS/E dyr file of the IEEE PES
%     Task Force benchmark. The equilibrium field voltages (1.03 to 2.43 pu) are inside
%     the limits, so the equilibrium and the linearization do not depend on them.
%   - Setting `Limiter` to false on every AVR reproduces the v2/v3 results without
%     limits (see the examples).
%   - The v2 PSS (`Kpss`, `Tpss`, `TL1p`, `TL1`, `TL2p`, `TL2`) has the transfer function
%     `Kpss/Tpss * Tpss*s/(1+Tpss*s) * (1+TL1p*s)/(1+TL1*s) * (1+TL2p*s)/(1+TL2*s)`,
%     which is controller.pss.PSS1 with `kpss = Kpss/Tpss`, `tWS = Tpss`, `tn1 = TL1p`,
%     `td1 = TL1`, `tn2 = TL2p`, `td2 = TL2`.
% - The diagram layout (bus `X`, `Y`, `Shape`, `Length`, branch `Path`, `FromOffset`,
%   `ToOffset`, `Style` and component `DX`, `DY`, `Shape`, `Offset`) follows Figure 1 of
%   A. K. Singh and B. C. Pal, "IEEE PES Task Force on Benchmark Systems for Stability
%   Controls: Report on the 68-Bus, 16-Machine, 5-Area System", ver. 3.3, 2013. The figure
%   draws some double circuits as two lines and the branch 63-58 as a line from bus 64;
%   the layout draws each branch of this network once.
% - The v2 files have no voltage limits, base voltages or OPF data; these are the
%   GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for
%   generators and 0 for loads).
% - `archive/IEEE68bus` also has data that network.build did not use (generator_park,
%   avr_IEEE_ST1, excitation); they are not part of this network.
%
% With the Static AVRs and governors only (`LocalController=false`, the default) the
% equilibrium is unstable: one real eigenvalue is about +0.13 1/s. With the AVRs and PSSs
% (`LocalController=true`) it is stable; the largest real part apart from the zero mode
% of the common angle is about -0.0051 1/s.
%
% <@Examples>
% Run the power flow and simulate a fault at bus 1, with the AVRs and PSSs:
%
% ```matlab
% net = network.IEEE68bus(LocalController=true);
% res = net.calculate_powerflow();
% sc  = net.add_scenario("fault");
% sc.add_fault("B001", [1,1.05]);
% sol = net.simulate("fault");
% ```
%
% Switch the AVR limiters off to reproduce the v2/v3 results:
%
% ```matlab
% net = network.IEEE68bus(LocalController=true);
% for i = 1:16
%     avr = net.a_Bus{i}.a_Component{1}.avr;
%     avr.tab_parameter.dynamics.Limiter = false;
% end
% net.initialize();
% ```
%
% See also controller.avr.AVR_ST1, controller.pss.PSS1, network.IEEE9bus

    properties(Constant) % Data
        ver = 1  % Version of the bundled network data.
    end

    methods
        function obj = IEEE68bus(opt)
            % Create the network from the CSV data in the class folder.
            arguments (Input)
                opt.LocalController (1,1) logical = false  % true to add an AVR and a PSS to every generator; false keeps the default Static AVR and governor (avr-static, gov-static) on the generators.
            end
            arguments (Output)
                obj  % IEEE68bus network.
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
