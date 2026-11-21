classdef IEEJ_WEST10 < PowerNetwork
% IEEJ WEST 10-machine standard model, with rotating-exciter AVRs and governors on request.
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
%   is two branches, named with `_1` and `_2` (e.g. `LINE20_1`, `LINE20_2`), so that one
%   circuit can be opened (Scenario.add_open_branch). The bus voltages and angles are the
%   same as with one branch of `R/2`, `X/2`, `2*C` per card (within 1e-14).
% - Transformers are pi_transformer branches with the input `X` (0.14 pu on the machine
%   rating), `R = 0`, `C = 0`, `tap = 1`, `phase = 0`.
% - Every branch has `circuit = 1` (column `circuit` of `branch/parameter.csv`): a line
%   branch is one circuit, and a transformer is taken as one bank (the data give no bank
%   count).
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
% Local controllers (`LocalController=true`; with false, the default, every generator keeps
% the Static AVR and governor, `avr-static` and `gov-static`):
%
% - AVRs (Y-method `LAT = 1`, appendix figure 1.1 (a), `local_controller/avr-DC1`): the block
%   diagram is controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2` and the limit
%   `Vap_max = 100`, `Vap_min = -100` on the first lag, then `tex = 0.02`, `aex1 = 0.01`,
%   `aex2 = bex = 0`, which is the source's `100/(1 + 2s)`, the field voltage limit
%   `Vfld_max = 4`, `Vfld_min = 0`, and `kst = 0.1`, `tst = 0.5`. `Vref` takes the place of
%   the field setting `EFS`. The equilibrium field voltages are 2.10 (peak) and 1.64 to
%   1.97 (night). `Limiter = 1` applies both limits; set it to false to ignore them.
% - Governors (`Governor=true`, `local_controller/gov-LPT1`): every generator has `LPT = 1`
%   with the standard constants (appendix figure 1.2 (a)), which is
%   controller.governor.IEEJ_LPT1 with its default constants, `Prate` = the rated output
%   of the input data (0.9 of `GMVA`) / 1000 MVA, and `PLM` = 5 % at peak and 3 % at
%   night. At peak the machines run at their rated output except G10 (servo position
%   0.9975), so the margin of 5 % reaches the servo limit 1.05.
%
% Differences from the report:
%
% - Loads are load-ZIP models with the default parameters, which are the voltage
%   characteristic of the report's load (`NLT = 2`): constant-current `P`, changing to
%   constant impedance below 0.7 pu, and constant-impedance `Q`. The frequency
%   characteristic of `NLT = 2`, 3.33 %/Hz for `P`, is not represented: the load power
%   does not depend on the frequency.
%
% Comparison with the report:
%
% - The power flow matches the flow diagrams of figure 4.10 within one unit of the last
%   printed digit (bus voltages and angles, generator outputs, slack power, load
%   reactive power and line flows), except two values that look like misprints of the
%   figure: at peak the flow from bus 2 to 3 is printed 1.428 (GUILDA 1.4824), and at
%   night G7 is printed 3.600+j1.472 while the Y-method data give PG = 3.00 (GUILDA
%   3.000+j1.427). See `+PF/README.md` of each section folder below.
% - Without governors the equilibrium is stable with the AVRs (largest real part -0.14 at
%   peak and -0.091 at night, apart from the zero modes of the common angle and
%   frequency) and unstable without them (`LocalController=false`, the default: the Static AVRs and
%   governors only) at peak (real part 0.069); the night one is then stable (largest real
%   part -0.025). With the governors
%   the least damped modes are of 1.5 s at peak, which is slightly unstable (real part
%   +0.0011), and of 2.1 s at night, with almost no damping (real part -0.0009). The
%   slowest swing modes are of 2.5 s (peak) and 2.1 s (night) with governors, and 2.9 s
%   and 2.3 s without. The report gives periods of about 3 s (peak) and 2.5 s (night).
% - The verification against the report is in `_GUILDAverification/IEEJ_WEST10_peak/`
%   and `_GUILDAverification/IEEJ_WEST10_night/`, one folder per section: `+PF` compares
%   the input data with the Y-method data and the power flow with figure 4.10, and
%   `+TimeResponse` compares the dynamic parameters with the source and the transient
%   stability cases of table 4.5 (13 per section) with the report. See the README.md of
%   each folder for the criterion and the latest agreement.
%   The report states that its case C at peak is stable with `NLT = 2` and not with
%   constant-impedance loads; here it is out of step with the load-ZIP loads too.
%
% Simulation: runs without an event stay at the equilibrium (both sections, with and
% without governors, over 60 s), and a fault at `B003` at peak completes with the default
% settings and with `Tolerance` 1e-6 and `AbsoluteTolerance` 1e-8. Out-of-step runs can
% stop the solver (flag -1) once the angles are large.
%
% <@Examples>
% Run the power flow of the night section and simulate case E of table 4.5 (with the AVRs
% and governors): a fault at
% bus 4 for 70 ms, then one circuit of line 50 opened for good:
%
% ```matlab
% net   = network.IEEJ_WEST10(Section="night", LocalController=true);
% res   = net.calculate_powerflow();
% sc    = net.add_scenario("fault-open", Time=[0,20]);
% sc.add_fault("B004", [0.1,0.17]);
% sc.add_open_branch("LINE50_1", 0.17);
% sol   = net.simulate("fault-open");
% ```
%
% See also controller.avr.AVR_DC1, controller.governor.IEEJ_LPT1, component.generator.park, Scenario

    properties(Constant) % Data
        ver = 2  % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_WEST10(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments (Input)
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak"  % Power-flow section.
                opt.LocalController (1,1) logical = false  % true to add the local controllers (AVRs, and governors with Governor=true); false keeps the default Static AVR and governor (avr-static, gov-static) on the generators.
                opt.Governor (1,1) logical = true         % true for the governors of the report in local_controller/; false gives every generator the Static governor (needs LocalController=true).
            end
            arguments (Output)
                obj  % IEEJ_WEST10 network.
            end
            s_dirpath = fullfile(fileparts(mfilename("fullpath")), opt.Section);
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
