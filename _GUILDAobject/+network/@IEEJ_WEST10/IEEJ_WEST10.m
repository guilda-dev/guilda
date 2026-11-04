classdef IEEJ_WEST10 < PowerNetwork
% IEEJ WEST 10-machine standard model with rotating-exciter AVRs and governors.
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
%   is two branches, named with `-1` and `-2`, so that one circuit can be opened
%   (Scenario.add_open_branch). The bus voltages and angles are the same as with one branch of
%   `R/2`, `X/2`, `2*C` per card (within 1e-14).
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
%   and the standard constants have no q-axis transient values. The q-axis transient
%   circuit of gen-park is removed with `Xq_p = Xq`, which keeps `Ed` at 0; `Tq_p = 1` is
%   not a report value and has no effect then. The q-axis damper is `Xq_pp` with `Tq_pp`.
% - The source gives short-circuit time constants; gen-park uses open-circuit ones:
%   `Td_p = Td'*Xd/Xd'` and `Td_pp = Td''*Xd'/Xd''` (the usual approximations), and
%   `Tq_pp = Tq''*Xq/Xq''`, which is exact for the single q-axis circuit left with
%   `Xq_p = Xq` (`Xq'/Xq''` is the same factor).
% - `D = 0`: the `DG` field of the input data is blank.
% - The armature time constant `Ta` (0.40 s) is not used: GUILDA has no stator transients.
%   The input data have no saturation.
%
% Local controllers (`LocalController=true`; false adds neither AVRs nor governors):
%
% - AVRs (Y-method `LAT = 1`, appendix figure 1.1 (a), `controller/avr`): the block
%   diagram is controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2` and the limit
%   `Vap_max = 100`, `Vap_min = -100` on the first lag, then `tex = 0.02`, `aex1 = 0.01`,
%   `aex2 = bex = 0`, which is the source's `100/(1 + 2s)`, the field voltage limit
%   `Vfld_max = 4`, `Vfld_min = 0`, and `kst = 0.1`, `tst = 0.5`. `Vref` takes the place of
%   the field setting `EFS`. The equilibrium field voltages are 2.10 (peak) and 1.64 to
%   1.97 (night).
% - Governors (`Governor=true`, `controller/governor`): every generator has `LPT = 1` with
%   the standard constants (appendix figure 1.2 (a)), so the column `LPT` gives
%   controller.governor.IEEJ_LPT1 with its default constants, `Prate` = the rated output
%   of the input data (0.9 of `GMVA`) / 1000 MVA, and `PLM` = 5 % at peak and 3 % at
%   night. At peak the machines run at their rated output except G10 (servo position
%   0.9975), so the margin of 5 % reaches the servo limit 1.05.
%
% Differences from the report:
%
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
% - Without governors the equilibrium is stable with the AVRs and unstable without them
%   (largest real part 0.055 at peak). The slowest swing mode at peak then has a period
%   of 4.79 s and a damping ratio of only 0.004. The governors damp it; the least damped
%   modes are then of 1.5 s at peak (damping ratio 0.009) and of 2.0 s at night, which
%   is slightly unstable (real part +0.0013; the 2.1 s night mode has -0.12 without
%   governors). The report gives periods of about 3 s (peak) and 2.5 s (night).
% - The stability results of table 4.5 are mostly not reproduced (scenario/run_table4_5),
%   and the cause is not identified. 9 of the 26 cases agree, with and without governors:
%   at peak only the two out-of-step cases A and L (the report has the other 11 stable,
%   G8 with a growing swing); at night A and the cases E to I, with governors also the G8
%   trip and without them J. The other cases go out of step, mostly within 3 to 8 s (E at
%   peak after a growing swing of about 1.5 s), or stop the solver (see run_table4_5).
%   The swing periods of the stable night cases are mostly 2.0 to 2.4 s (the report: 2.2
%   to 2.5 s). In a separate check the results depended strongly on `Tq_pp`.
%
% Scenarios: the folder `scenario` holds the cases of table 4.5 (`table4_5.csv`: the
% fault bus, the opened circuit, the timing and the verdict of the report) and
% `run_table4_5`, which simulates them and compares; see its help for the criterion and
% how to run it (MATLAB does not run files inside a class folder, so it runs from a copy).
%
% Simulation: runs without an event stay at the equilibrium (both sections, with and
% without governors, over 60 s), and a fault at `B003` at peak completes with the default
% settings and with `Tolerance` 1e-6 and `AbsoluteTolerance` 1e-8. Out-of-step runs can
% stop the solver (flag -1) once the angles are large.
%
% <@Examples>
% Run the power flow of the night section and simulate case E of table 4.5: a fault at
% bus 4 for 70 ms, then one circuit of line 50 opened for good:
%
% ```matlab
% net   = network.IEEJ_WEST10(Section="night");
% res   = net.calculate_powerflow();
% sc    = Scenario("fault-open", Time=[0,20]);
% sc.add_fault("B004", [0.1,0.17]);
% sc.add_open_branch("LINE50-1", [0.17,20]);
% net.add_scenario(sc);
% sol   = net.simulate(sc);
% ```
%
% See also controller.avr.AVR_DC1, controller.governor.IEEJ_LPT1, component.generator.park, Scenario

    properties(Constant) % Data
        ver = 2 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_WEST10(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak" % Power-flow section.
                opt.LocalController (1,1) logical = true % true to add the local controllers (AVRs, and governors with Governor=true); false adds none.
                opt.Governor (1,1) logical = true % true to add the governor of the report to every generator listed in controller/governor (needs LocalController=true).
            end
            arguments (Output)
                obj % IEEJ_WEST10 network.
            end
            str_dirpath = fullfile(fileparts(mfilename("fullpath")), opt.Section);
            PowerNetwork.import_csv(str_dirpath, Network=obj, Initialize=false);
            if opt.LocalController
                add_avr(obj, str_dirpath);
                if opt.Governor
                    add_governor(obj, str_dirpath);
                end
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


function add_governor(net, str_dirpath)
% controller/governor/parameter.csv : governor (LPT = 1, 3 or 4 -> controller.governor.IEEJ_LPT1/3/4)
% and its parameters for the generator at each Bus
    tab_gov = readtable(fullfile(str_dirpath, "controller", "governor", "parameter.csv"));
    for i = 1:height(tab_gov)
        i_bus = tab_gov.Bus(i);
        str_cls = "controller.governor.IEEJ_LPT" + tab_gov.LPT(i);
        c_gov = namedargs2cell(table2struct(removevars(tab_gov(i,:), ["Bus","LPT"])));
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(feval(str_cls, "gov" + i_bus, c_gov{:}));
    end
end
