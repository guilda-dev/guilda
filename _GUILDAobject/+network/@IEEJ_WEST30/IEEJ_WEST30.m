classdef IEEJ_WEST30 < PowerNetwork
% IEEJ WEST 30-machine standard power system model, with AVRs and governors on request.
% The WEST 30-machine model of the Institute of Electrical Engineers of Japan (IEEJ),
% section 4.5 of the report at http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html
% It is a longitudinal 60 Hz system with long-period oscillations, reduced from a real
% system. It has 115 buses, 129 branches (99 lines and 30 transformers), 30 generators
% and two power-flow sections, peak and night; 1000 MVA base.
%
% Bus types:
%
% - Slack bus: bus 15 (node 3150)
% - PV buses: the other generator buses, buses 1 to 30
% - PQ buses: buses 31 to 115
%
% Data:
%
% The values are converted from the Y-method data of the report (files `s` of `west30p`
% and `west30n`), with the card format of its appendix 2. The folders `peak/` and
% `night/` have the same layout.
%
% - The sparse node numbers map to consecutive buses: nodes 3010 to 3300 (generators)
%   are buses 1 to 30, nodes 1010 to 1550 are buses 31 to 85, and nodes 2010 to 2300
%   are buses 86 to 115. The bus tag keeps the node number, for example `B3010`.
% - Lines are `pi` branches. A card gives `R`, `X` and `YC = Y/2` per circuit and the
%   number of circuits `n`, so `R/n`, `X/n` and `C = YC*n`.
%   The branch has `circuit = n` (column `circuit` of `branch/parameter.csv`): 36 lines
%   have 2 circuits and 63 have 1.
% - Transformers are `pi_transformer` branches with `R = 0`. All have one bank and tap 1.
%   They have `circuit = 1`.
% - The node value `YC` is the bus shunt `Bshunt`: positive for capacitors, negative
%   for shunt reactors.
% - Generators are gen-park models, with data on the machine MVA of each section, which
%   is converted to the system base: `M = MG*GMVA/1000`, reactances times `1000/GMVA`.
%   The damping `D` is 0 as in the data.
% - The time constants of the data are short-circuit values. The open-circuit values of
%   gen-park are `Td_p = Td'*Xd/Xd'`, `Td_pp = Td''*Xd'/Xd''`, `Tq_pp = Tq''*Xq/Xq''`.
% - The report uses LGT = 4: a field and one damper in the d-axis, one damper in the
%   q-axis, with no `Xq'` or `Tq'`. Its machine table does not list them, and the values
%   in those fields of the cards are unused by this model. gen-park reduces to it with
%   `Xq_p = Xq` exactly, which decouples `Ed`. `Tq_p = 1` is not report data and has no
%   effect at `Xq_p = Xq`.
% - Armature resistance and air-gap saturation of the Y-method model are not modeled;
%   the cards give `TA` and the negative- and zero-sequence reactances, which are unused.
% - The AVR is the rotating-exciter model LAT = 1 of Fig. A1.1 with its constants, which
%   is controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`, `tex = 0.02`,
%   `aex1 = 0.01`, `aex2 = 0`, `tst = 0.5`, `kst = 0.1`, `Vap_max = 100`, `Vap_min = -100`:
%   the exciter `100/(1+2s)` is `1/(0.01+0.02s)`, and `Vref` holds the report's offset
%   `EFS/100`. The report's field limit is `Vfld_max = 4`, `Vfld_min = 0`; the field
%   voltages of the equilibrium are 1.02 to 2.03 pu, inside it. The regulator limit is
%   shifted by `EFS/100`. `Limiter = 1` applies both limits; set it to false to ignore
%   them.
% - The governors are those of the G2 cards: LPT = 1 (thermal and nuclear) is
%   controller.governor.IEEJ_LPT1 and LPT = 3 (hydro) controller.governor.IEEJ_LPT3, with
%   the standard constants of the report (NPT = 0), which are the defaults of the classes.
%   `Prate` is the rated MW of the G1 card over the base (`GMW/1000`) and `PLM` [%] the
%   governor margin of the card; it is negative (load-limit operation) for the machines at
%   buses 7, 16, 26 and 30. At peak the machines at buses 2, 8, 14, 24 and 25 are LPT = 3
%   and the others LPT = 1. At night the pumping machines at buses 8, 14, 24 and 25 have a
%   locked governor (LPT = 0), which is the Static governor here, the machine at bus 2 is LPT = 3
%   and the others LPT = 1. The data is in `local_controller/gov-LPT1` and
%   `local_controller/gov-LPT3`. With `Governor=false` every machine has the Static
%   governor and keeps `Pmech` at its equilibrium; `LocalController=false` (the default) adds neither AVRs nor governors: every
%   generator keeps the Static AVR and governor (`avr-static`, `gov-static`).
% - The report's load is NLT = 2: P is constant current down to 0.7 pu and constant
%   impedance below it, with 3.33 %/Hz frequency dependence; Q is constant impedance.
%   Loads here are load-ZIP models with the default parameters, which have this voltage
%   characteristic; the frequency dependence is not represented.
% - In the night section the pumping machines at nodes 3080, 3140, 3240 and 3250
%   (buses 8, 14, 24, 25; -2,620 MW) are PQ nodes with `Q = 0`. A generator bus is always
%   a PV bus here, so their bus `V` is the voltage of the solution with these nodes as PQ,
%   which gives the same power flow with `Q` about 0.
% - The data has no bus coordinates, voltage limits, base voltages or OPF data; these
%   are the GUILDA defaults (OPF cost `HP = fP = 1` for generators and 0 for loads).
%
% - The data has no initial voltages: the power flow starts from the flat start (or the
%   last solution, WarmStart). With the default Tolerance (1e-8) the equilibrium of both
%   sections drifts by at most a few 1e-12 in 10 s of simulate without events.
%
% The power flow gives the generation and load totals of table 4.10 of the report and
% agrees with its flow diagrams within their rounding, in both sections.
%
% With the governors the night equilibrium is stable (largest real part -0.061, apart
% from the zero mode of the common angle) and the peak one is slightly unstable: a mode
% of 1.6 s has the real part +0.005. Without the governors the peak equilibrium is
% unstable, with a growing oscillation of 0.27 Hz (real part 0.14), and the night one is
% stable (largest real part -0.049, apart from the zero modes of the common angle and
% frequency). These are with `LocalController=true`. With the Static AVRs and governors
% only (`LocalController=false`, the default) both are unstable: the largest real
% eigenvalues are about +0.20 1/s at peak and +0.18 1/s at night.
%
% The comparisons with the report are in `_GUILDAverification/IEEJ_WEST30_peak/` and
% `_GUILDAverification/IEEJ_WEST30_night/` of the repository, one folder per section:
% `+PF/README.md` (network data, generator, exciter and governor constants, and the
% power flow against the flow diagram, fig. 4.24) and `+TimeResponse/README.md` (the
% transient stability cases of table 4.13), each with its reference, data, script and
% measured agreement.
%
% <@Citations>
% - 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,
%   電気学会技術報告 第754号, 1999.
% - 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,
%   [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)
%   (accessed 2026-11-25).
%
% <@Examples>
% Run the power flow of the night section and simulate case B of table 4.13 (with the AVRs
% and governors): a fault at
% node 1220 for 70 ms, cleared by opening one circuit of the line to node 1240 (EL042):
%
% ```matlab
% net = network.IEEJ_WEST30(Section="night", LocalController=true);
% res = net.calculate_powerflow();
% sc  = net.add_scenario("fault-open", Time=[0,10]);
% sc.add_fault("B1220", [0.1,0.17]);
% sc.add_open_branch("EL042", 0.17);
% sol = net.simulate("fault-open");
% ```
%
% See also controller.avr.AVR_DC1, controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT3, component.generator.park, component.load.ZIP, Scenario

    properties(Constant) % Data
        ver = 2  % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_WEST30(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments (Input)
                opt.Section (1,1) string {mustBeMember(opt.Section, ["peak","night"])} = "peak"  % Power-flow section: "peak" or "night".
                opt.LocalController (1,1) logical = false  % true to add the local controllers (AVRs and governors); false keeps the default Static AVR and governor (avr-static, gov-static) on the generators.
                opt.Governor (1,1) logical = true         % true for the governors of the report beside the AVRs (local_controller/); false gives every generator the Static governor (with LocalController).
            end
            arguments (Output)
                obj  % IEEJ_WEST30 network.
            end
            s_filepath   = mfilename("fullpath");
            s_dirpath    = fileparts(s_filepath);
            s_section    = fullfile(s_dirpath, opt.Section);
            PowerNetwork.import(s_section, Network=obj, Initialize=false);   % with the controllers of local_controller/
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
            elseif ~opt.Governor
                % the governors of local_controller/ go: their generators get the Static governor
                for b = 1:numel(obj.a_Bus)
                    for comp = reshape(obj.a_Bus{b}.a_Component, 1, [])
                        for con = reshape(comp{1}.a_LocalController, 1, [])
                            if con{1}.s_role == "governor" && con{1}.key ~= "gov-static"
                                comp{1}.remove_local_controller(con{1}.s_tag);
                                comp{1}.add_local_controller("gov-static");
                            end
                        end
                    end
                end
            end
            obj.initialize;
        end
    end
end
