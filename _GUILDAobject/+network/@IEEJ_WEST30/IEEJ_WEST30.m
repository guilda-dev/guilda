classdef IEEJ_WEST30 < PowerNetwork
% IEEJ WEST 30-machine standard power system model with AVRs.
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
% - Transformers are `pi_transformer` branches with `R = 0`. All have one bank and tap 1.
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
%   `Xq_p = Xq`, which decouples `Ed`. Its equilibrium divides by `Xq - Xq_p`, so
%   `Xq_p = Xq*(1 - 1e-6)`. `Tq_p` is the unused card value; it has no effect at this
%   coupling.
% - Armature resistance and air-gap saturation of the Y-method model are not modeled;
%   the cards give `TA` and the negative- and zero-sequence reactances, which are unused.
% - The AVR is the rotating-exciter model LAT = 1 of Fig. A1.1 with its constants, which
%   is controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`, `tex = 0.02`,
%   `aex1 = 0.01`, `aex2 = 0`, `tst = 0.5`, `kst = 0.1`, `Vap_max = 100`, `Vap_min = -100`:
%   the exciter `100/(1+2s)` is `1/(0.01+0.02s)`, and `Vref` holds the report's offset
%   `EFS/100`. AVR_DC1 has no limit on `Vfield`, so the report's limit from 0 to 4 pu is
%   missing, and the regulator limit is shifted by `EFS/100`.
% - The report has governors (LPT = 1 and 3, and locked for pumping machines). GUILDA has
%   no governor model, so `Pmech` is constant for all machines.
% - The report's load is NLT = 2: P is constant current down to 0.7 pu and constant
%   impedance below it, with 3.33 %/Hz frequency dependence; Q is constant impedance.
%   Loads here are load-impedance, the closest model: Q is the same, P is proportional
%   to `V^2` and not `V`, with no frequency dependence. The report shows that constant
%   impedance changes a stable case to unstable.
% - In the night section the pumping machines at nodes 3080, 3140, 3240 and 3250
%   (buses 8, 14, 24, 25; -2,620 MW) are PQ nodes with `Q = 0`. A generator bus is always
%   a PV bus here, so their bus `V` is the voltage of the solution with these nodes as PQ,
%   which gives the same power flow with `Q` about 0.
% - The data has no bus coordinates, voltage limits, base voltages or OPF data; these
%   are the GUILDA defaults.
%
% - The bus columns `V0`, `Varg0` hold the power-flow solution as the initial guess. From
%   the flat start the bus current residual stays near 1e-9 at night, and simulate then
%   stops at the first phase with GUILDA:odeSimulator:UnfeasibleDAE.
%
% The power flow gives the generation and load totals of table 4.10 of the report and
% agrees with its flow diagrams within their rounding, in both sections.
%
% The dynamics differ from the report. The equilibrium with the AVRs is unstable in both
% sections, with growing oscillations near 0.25 Hz, and every 70 ms bus fault of
% the report's points A to F ends in loss of synchronism, where its table 4.13 has stable
% cases. The missing constant-current load and governors change this result, and
% net.simulate has no line opening, which those cases use.
%
% <@Examples>
% Run the power flow of the night section and simulate a fault at node 1220:
%
% ```matlab
% net = network.IEEJ_WEST30(Section="night");
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.07], "FaultBus", "B1220");
% sol = net.simulate([0,5], ev);
% ```
%
% See also controller.avr.AVR_DC1, component.generator.park, component.load.impedance, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_WEST30(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section, ["peak","night"])} = "peak" % Power-flow section: "peak" or "night".
                opt.LocalController (1,1) logical = true % true to add an AVR to every generator.
            end
            arguments (Output)
                obj % IEEJ_WEST30 network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            str_section  = fullfile(str_dirpath, opt.Section);
            PowerNetwork.import_csv(str_section, Network=obj, Initialize=false);
            if opt.LocalController
                add_avr(obj, str_section);
            end
            obj.initialize;
        end
    end
end


function add_avr(net, str_section)
% controller/avr/parameter.csv : AVR_DC1 parameters of the generator at each Bus
    tab_avr = readtable(fullfile(str_section, "controller", "avr", "parameter.csv"));
    for i = 1:height(tab_avr)
        i_bus = tab_avr.Bus(i);
        c_avr = namedargs2cell(table2struct(removevars(tab_avr(i,:), "Bus")));
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr" + i_bus, c_avr{:}));
    end
end
