classdef IEEJ_WEST10 < PowerNetwork
% IEEJ WEST 10-machine standard model with rotating-exciter AVRs.
% The WEST 10-machine model of the standard power system models of the Institute of
% Electrical Engineers of Japan: a longitudinal 60 Hz, 500 kV system that shows the
% long-period oscillations of the Japanese 60 Hz grid. It has 27 buses, 42 branches
% (32 lines and 10 transformers), 10 generators and 17 loads; 60 Hz, 1000 MVA base.
% `Section` selects the peak (daytime) or the night power-flow section; the generator
% ratings and the transformer reactances differ between them.
%
% Source: IEEJ report on the standard models, section 4.3 and appendices 1 and 2,
% http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html, and its input data in the
% format of the Y-method program of CRIEPI.
%
% Bus types (the bus tags `B001` to `B030` are the node numbers of the report; 10, 11
% and 20 do not exist):
%
% - Slack bus: `B030` (generator G10)
% - PV buses: `B021` to `B029` (generators, 1.03 pu), and `B001`, `B009`, `B012` to
%   `B019` (loads, 1.00 pu)
% - PQ buses: `B002` to `B008`
%
% Data:
%
% - Lines are pi branches with the per-circuit `R`, `X` of the input data and `C = YC`
%   (the input data give the charging at each end, `YC = Y/2`). A card with two circuits
%   is two branches, named with `-1` and `-2`.
% - Transformers are pi_transformer branches with the input `X` (0.14 pu on the machine
%   rating), `R = 0`, `C = 0`, `tap = 1`, `phase = 0`.
% - Generators have `P = PG`, `Q = NaN`, and the rating `baseMVA = GMVA` of the section.
%   Reactances and `M` (7 s) are converted from the machine rating to the system base:
%   `X*1000/GMVA`, `M*GMVA/1000`.
% - The buses with a set voltage and no generation hold it with the load (`Q = NaN`). The
%   report treats the reactive support in the same way, as the power factor of the load.
% - The report gives no bus limits or OPF data; these are the GUILDA defaults (`Vmin`
%   0.5, `Vmax` 1.5, OPF cost `HP = fP = 1` for generators and 0 for loads). `baseKV` is
%   500; the report gives no voltage for the generator buses, and the value is not used
%   in any calculation.
%
% Generators (Y-method `LGT = 4`, standard constants `NGT = 2`, appendix table 1.1):
%
% - They are gen-park models. `LGT = 4` has a field circuit and one damper on each axis,
%   and the standard constants have no q-axis transient values. The q-axis circuit of
%   gen-park that is not in the source is removed with `Xq_p = Xq*(1 - 1e-6)`: exactly
%   `Xq_p = Xq` leaves `Ed` constant at 0, but makes get_equilibrium singular. `Tq_p = 1`
%   is not a report value and has no effect. The q-axis damper is `Xq_pp` with `Tq_pp`.
% - The source gives short-circuit time constants; gen-park uses open-circuit ones,
%   converted by the usual approximations: `Td_p = Td'*Xd/Xd'`, `Td_pp = Td''*Xd'/Xd''`,
%   `Tq_pp = Tq''*Xq/Xq''`.
% - `D = 0`: the `DG` field of the input data is blank.
% - The armature time constant `Ta` (0.40 s) is not used: GUILDA has no stator transients.
%   The input data have no saturation.
%
% AVRs (Y-method `LAT = 1`, appendix figure 1.1 (a), `LocalController=true`):
%
% - The block diagram is controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2` and
%   the limit `Vap_max = 100`, `Vap_min = -100` on the first lag, then `tex = 0.02`,
%   `aex1 = 0.01`, `aex2 = bex = 0`, which is the source's `100/(1 + 2s)`, and `kst = 0.1`,
%   `tst = 0.5`. `Vref` takes the place of the field setting `EFS`.
% - Difference: the field voltage limit of the source, `0 <= EF <= 4`, is not in AVR_DC1.
%
% Differences from the report:
%
% - No governors: GUILDA has no governor class, so `Pmech` is constant (the report uses
%   `LPT = 1` with the margin `PLM` of 5 % at peak and 3 % at night).
% - Loads are load-impedance models. The report (`NLT = 2`) has constant-current `P`,
%   changing to constant impedance below 0.7 pu, constant-impedance `Q` and a frequency
%   characteristic of 3.33 %/Hz for `P`. So `Q` is the same, `P` depends more on the
%   voltage, and frequency has no effect. The report states that constant-impedance
%   loads are less stable: its case C at peak is stable with `NLT = 2` and not with them.
%
% Comparison with the report:
%
% - The power flow matches the flow diagrams of the report (generator outputs, slack
%   power, load reactive power and angles to the digits shown).
% - The equilibrium is stable with the AVRs and unstable without them (largest real
%   part 0.055 at peak). With these constant-impedance loads the slowest swing mode at
%   peak has a period of 4.79 s and a damping ratio of only 0.004. The report gives
%   periods of about 3 s (peak) and 2.5 s (night).
% - The stability results of table 4.5 of the report are not reproduced, and the cause is
%   not identified. The report has 10 of its 13 peak cases stable. With a line opening
%   added in a separate check, none is stable with this model, and one with the
%   constant-current load, governors and load frequency characteristic of the report.
%   These results depend strongly on `Tq_pp`. GUILDA's simulate has no line opening.
%
% Simulation:
%
% With the default solver settings simulate can stop at the initial condition
% (GUILDA:SolverODE:UnfeasibleDAE): at peak, runs without an event over some time spans
% do. The warning that the initial condition of a phase moved the differential states means
% that the rotor angles have jumped and the result is wrong; Tolerance 1e-6 and
% AbsoluteTolerance 1e-8 give it for a fault at `B003` at peak. Discard such a run.
%
% <@Examples>
% Run the power flow of the night section and simulate a fault at bus 2:
%
% ```matlab
% net = network.IEEJ_WEST10(Section="night");
% res = net.calculate_powerflow();
% ev  = EventODE("fault", net, "TimeSpan", [1,1.07], "FaultBus", "B002");
% sol = net.simulate([0,20], ev);
% ```
%
% See also controller.avr.AVR_DC1, component.generator.park, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_WEST10(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak" % Power-flow section.
                opt.LocalController (1,1) logical = true % true to add an AVR to every generator.
            end
            arguments (Output)
                obj % IEEJ_WEST10 network.
            end
            str_dirpath = fullfile(fileparts(mfilename("fullpath")), opt.Section);
            PowerNetwork.import_csv(str_dirpath, Network=obj, Initialize=false);
            if opt.LocalController
                add_avr(obj, str_dirpath);
            end
            obj.initialize;
        end
    end
end


function add_avr(net, str_dirpath)
% controller/avr/parameter.csv : AVR_DC1 parameters of the generator at each Bus
    tab_avr = readtable(fullfile(str_dirpath, "controller", "avr", "parameter.csv"));
    for i = 1:height(tab_avr)
        i_bus = tab_avr.Bus(i);
        c_avr = namedargs2cell(table2struct(removevars(tab_avr(i,:), "Bus")));
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr" + i_bus, c_avr{:}));
    end
end
