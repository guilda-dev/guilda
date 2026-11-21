classdef IEEJ_EAST10 < PowerNetwork
% IEEJ EAST 10-machine standard model, with a peak and a night power-flow section.
% The EAST 10-machine model of the Institute of Electrical Engineers of Japan (IEEJ)
% for the 50 Hz loop system, from the IEEJ report on standard power system models
% (http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html, section 4.2, tables 4.1
% to 4.3 and appendices 1 and 2) and its Y-method input data.
% It has 47 buses, 100 branches (78 line circuits and 22 transformers), 10 generators
% and 12 loads; 50 Hz, 1000 MVA base. As in table 4.1, each circuit of a line is one
% branch, and each transformer card is one branch.
%
% Bus types:
%
% - Slack bus: bus 3 (peak), bus 6 (night)
% - PV buses: the other buses of 1 to 10
% - PQ buses: buses 11 to 47; buses 18, 19, 38 to 47 have loads
%
% Data:
%
% - A line card has 2 circuits; each circuit is a branch.pi with the per-circuit `r`,
%   `x` and `C = y = Y/2` of the card. The circuits of the `k`-th line card (in the order
%   of the data) are the branches `EL(2k-1)` and `EL(2k)`, so one circuit can be opened
%   with a Scenario (add_open_branch). Parallel cards stay separate (for example cards 17 and 117 from bus
%   12 to 13 are EL013 to EL016). The bus voltages and angles are the same as with one
%   branch of `r/2`, `x/2`, `2*y` per card (difference below 1e-14).
% - A transformer card is a branch.pi_transformer with `tap = 1/t`, `t` being TAPR.
% - Every branch has `circuit = 1` (column `circuit` of `branch/parameter.csv`): a line
%   branch is one circuit, and a transformer is taken as one bank (the data give no bank
%   count).
% - Generators use the source PG and Vset; the PG of the slack bus and QG are not used.
%   `baseMVA` is the rating of table 4.2.
% - The generators are gen-park models. The source model LGT=4 has one damper in each
%   axis, the standard constants of appendix table 1.1 selected by NGT (2 thermal,
%   6 nuclear, 8 hydro), and no saturation data. The conversions are:
%   - `M` (machine MVA base) and all reactances are moved to the 1000 MVA system base
%     by `GMVA/1000`.
%   - The table gives short-circuit time constants; the open-circuit ones are
%     `Td_p = Td'*Xd/Xd'`, `Td_pp = Td''*Xd'/Xd''`, `Tq_pp = Tq''*Xq/Xq''`.
%   - `Xq_p = Xq` removes the q-axis transient circuit, which LGT=4 does not have: `Ed`
%     stays 0, and `Tq_p = 1` has no effect.
%   - `D = 0`: the DG field of the source is blank.
%   - The armature time constant `Ta` has no counterpart in gen-park and is not used.
% - By default (`LocalController=false`) every generator keeps the Static AVR and governor
%   (`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.
%   `LocalController=true` adds the AVRs and governors below.
% - The AVR is the rotating-exciter model LAT=1 of appendix figure 1.1, as
%   controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`, `Vap_max = 100`,
%   `Vap_min = -100`, `tex = 0.02`, `aex1 = 0.01`, `aex2 = bex = 0`, `tst = 0.5`,
%   `kst = 0.1`. `Vap` is the output of the first lag, with its +-100 limit, and
%   `0.02*dVfld/dt = -0.01*Vfld + Vap` is the exciter `100/(1 + 2*s)`, so the linear part
%   is the same. The field voltage setting EFS/100 of the figure is part of `Vref` here.
%   The limit `0 <= EF <= 4` of LAT=1 is `Vfld_max = 4`, `Vfld_min = 0`. The equilibrium
%   field voltages are inside it (1.54 to 2.26 at peak, 1.40 to 2.21 at night).
%   `Limiter = 1` applies both limits; set it to false to ignore them.
% - The source's PSS variant LAT=102 is not part of the base case and is not included.
% - The governors are those of table 4.2 and appendix figure 1.2, in
%   `local_controller/gov-LPT1` and `local_controller/gov-LPT4`:
%   controller.governor.IEEJ_LPT1 for the thermal and nuclear machines (LPT=1) and
%   controller.governor.IEEJ_LPT4 for the hydro machines G3 and G5 (LPT=4), with the
%   constants of the figure. `Prate` is the rated MW of table 4.2 divided by 1000, and
%   `PLM` is 5, or -10 (load-limit operation) for G2 and G7. At night G3 and G5 are
%   pumping with locked governors (LPT=0), so they have the Static governor and constant
%   `Pmech`. `Governor=false` (with `LocalController=true`) gives every generator the Static
%   governor, and `LocalController=false` keeps the Static AVR and governor on every
%   generator, whatever `Governor` is.
% - Loads are load-ZIP models with the default parameters, which are the voltage
%   characteristic of the source model NLT=2: constant-current P (constant impedance below
%   0.7 pu) and constant-impedance Q. The frequency characteristics of NLT=2, 4 %/Hz (P)
%   and -2 %/Hz (Q), are not represented: the load power does not depend on the frequency.
% - The source has no bus coordinates, voltage limits, base voltages or OPF data; these
%   are the GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost
%   `HP = fP = 1` for generators and 0 for loads).
%
% Comparison with the report:
%
% - The power flow matches figure 4.3 within one unit of the last printed digit for all
%   the values read from it (174 per section: bus voltages and angles, generator
%   outputs, loads and line flows), for example G3 at 5.632+j1.437 (peak) and G6 at
%   6.586+j1.866 (night); see `+PF/README.md` of each section folder below.
% - With the AVRs and governors (`LocalController=true`) both equilibria are stable: the largest
%   real part apart from the zero mode of the common angle is `-0.0086` (peak, real) and
%   `-0.061 +- 2.90i` (night). With the AVRs only (`Governor=false`) both are stable too,
%   apart from the zero modes of the common angle and frequency: `-0.064 +- 1.52i` (peak)
%   and `-0.084 +- 2.74i` (night). With the Static AVRs and governors only (`LocalController=false`,
%   the default) each section has an unstable real eigenvalue: `0.033` (peak) and `0.100`
%   (night).
% - The long-period oscillation is about 2.0 s (peak) and 2.2 s (night) with governors,
%   2.0 s and 2.3 s without; the report states about 2 s and 3 s for its model.
% - The verification against the report is in `_GUILDAverification/IEEJ_EAST10_peak/`
%   and `_GUILDAverification/IEEJ_EAST10_night/`, one folder per section: `+PF` compares
%   the input data with the Y-method data and the power flow with figure 4.3, and
%   `+TimeResponse` compares the dynamic parameters with the source and the fault cases
%   of table 4.3 (21 at peak, 23 at night) with the report. See the README.md of each
%   folder for the criterion and the measured agreement.
%
% <@Examples>
% Run the power flow of the night section, and simulate a fault at bus 36 at peak with the
% AVRs and governors:
%
% ```matlab
% net = network.IEEJ_EAST10(Section="night");
% res = net.calculate_powerflow();
% net = network.IEEJ_EAST10(LocalController=true);
% sc  = net.add_scenario("fault");
% sc.add_fault("B036", [1,1.07]);
% sol = net.simulate("fault");
% ```
%
% Fault at bus 36 for 70 ms, then open one circuit of the line from bus 36 to 17
% (card 36) for good, with the AVRs and without governors:
%
% ```matlab
% net  = network.IEEJ_EAST10(LocalController=true, Governor=false);
% sc   = net.add_scenario("fault-open", Time=[0,20]);
% sc.add_fault("B036", [0,0.07]);
% sc.add_open_branch("EL065", 0.07);
% sol  = net.simulate("fault-open", Tolerance=1e-6, AbsoluteTolerance=1e-6);
% ```
%
% See also controller.avr.AVR_DC1, controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT4, component.generator.park, network.IEEE68bus

    properties(Constant) % Data
        ver = 2  % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_EAST10(opt)
            % Create the network from the CSV data of one power-flow section.
            arguments (Input)
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak"  % Power-flow section.
                opt.LocalController (1,1) logical = false  % true for the controllers of local_controller/ (an AVR on every generator, and the governors); false keeps the default Static AVR and governor (avr-static, gov-static) on the generators.
                opt.Governor (1,1) logical = true         % true for the governors of local_controller/; false gives every generator the Static governor (with LocalController).
            end
            arguments (Output)
                obj  % IEEJ_EAST10 network.
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
