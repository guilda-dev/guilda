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
% - The AVR is the rotating-exciter model LAT=1 of appendix figure 1.1, as
%   controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`, `Vap_max = 100`,
%   `Vap_min = -100`, `tex = 0.02`, `aex1 = 0.01`, `aex2 = bex = 0`, `tst = 0.5`,
%   `kst = 0.1`. `Vap` is the output of the first lag, with its +-100 limit, and
%   `0.02*dVfld/dt = -0.01*Vfld + Vap` is the exciter `100/(1 + 2*s)`, so the linear part
%   is the same. The field voltage setting EFS/100 of the figure is part of `Vref` here.
%   The limit `0 <= EF <= 4` of LAT=1 is `Vfld_max = 4`, `Vfld_min = 0`. The equilibrium
%   field voltages are inside it (1.54 to 2.26 at peak, 1.40 to 2.21 at night).
% - The source's PSS variant LAT=102 is not part of the base case and is not included.
% - The governors are those of table 4.2 and appendix figure 1.2, in
%   `controller/governor/parameter.csv` (columns Bus, LPT, Prate, PLM):
%   controller.governor.IEEJ_LPT1 for the thermal and nuclear machines (LPT=1) and
%   controller.governor.IEEJ_LPT4 for the hydro machines G3 and G5 (LPT=4), with the
%   constants of the figure. `Prate` is the rated MW of table 4.2 divided by 1000, and
%   `PLM` is 5, or -10 (load-limit operation) for G2 and G7. At night G3 and G5 are
%   pumping with locked governors (LPT=0), so they have no governor and constant
%   `Pmech`. `Governor=false` leaves out all governors, and `LocalController=false`
%   leaves out the AVRs and the governors.
% - Loads are load-impedance models. The source model NLT=2 has constant-current P
%   (constant impedance below 0.7 pu), constant-impedance Q, and frequency
%   characteristics of 4 %/Hz (P) and -2 %/Hz (Q). So Q is the same, P depends on
%   `V^2` instead of `V` above 0.7 pu, and there is no frequency characteristic.
% - The source has no bus coordinates, voltage limits, base voltages or OPF data; these
%   are the GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost
%   `HP = fP = 1` for generators and 0 for loads).
%
% Comparison with the report:
%
% - The power flow matches figure 4.3 at the shown digits where checked, for example
%   G3 at 5.632+j1.437 (peak) and G6 at 6.586+j1.866 (night).
% - With the AVRs and governors (the default) both equilibria are stable: the largest
%   real part apart from the zero mode of the common angle is `-0.0086` (peak, real) and
%   `-0.045 +- 3.17i` (night). With the AVRs only (`Governor=false`) the peak
%   equilibrium is slightly unstable (`0.0204 +- 2.13i`) and the night one is stable.
%   Without controllers (`LocalController=false`) the peak equilibrium has an unstable
%   real eigenvalue `0.167`.
% - The long-period oscillation is about 2.7 s (peak) and 2.0 s (night) with governors,
%   2.9 s and 2.1 s without; the report states about 2 s and 3 s for its model.
% - The 44 fault cases of table 4.3 are compared with the report in
%   `_GUILDAverification/IEEJ_EAST10/` (scenarios, report verdicts and the comparison
%   script; see its README.md for the criterion and the measured agreement).
%
% <@Examples>
% Run the power flow of the night section, and simulate a fault at bus 36 at peak:
%
% ```matlab
% net = network.IEEJ_EAST10(Section="night");
% res = net.calculate_powerflow();
% net = network.IEEJ_EAST10();
% sc  = Scenario("fault");
% sc.add_fault("B036", [1,1.07]);
% net.add_scenario(sc);
% sol = net.simulate([0,10], sc);
% ```
%
% Fault at bus 36 for 70 ms, then open one circuit of the line from bus 36 to 17
% (card 36) for good, without governors:
%
% ```matlab
% net  = network.IEEJ_EAST10(Governor=false);
% sc   = Scenario("fault-open", Time=[0,20]);
% sc.add_fault("B036", [0,0.07]);
% sc.add_open_branch("EL065", [0.07,20]);
% net.add_scenario(sc);
% sol  = net.simulate(sc, Tolerance=1e-6, AbsoluteTolerance=1e-6);
% ```
%
% See also controller.avr.AVR_DC1, controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT4, component.generator.park, network.IEEE68bus

    properties(Constant) % Data
        ver = 2 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_EAST10(opt)
            % Create the network from the CSV data of one power-flow section.
            arguments (Input)
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak" % Power-flow section.
                opt.LocalController (1,1) logical = true % true to add an AVR to every generator; false for no AVR and no governor.
                opt.Governor (1,1) logical = true % true to add the governors of controller/governor (with LocalController).
            end
            arguments (Output)
                obj % IEEJ_EAST10 network.
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
    arguments (Input)
        net         (1,1) PowerNetwork  % Network being built.
        str_dirpath                     % Folder that holds the controller/ CSV files.
    end
    tab_avr = readtable(fullfile(str_dirpath, "controller", "avr", "parameter.csv"));
    for i = 1:height(tab_avr)
        i_bus = tab_avr.Bus(i);
        c_avr = namedargs2cell(table2struct(removevars(tab_avr(i,:), "Bus")));
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr" + i_bus, c_avr{:}));
    end
end


function add_governor(net, str_dirpath)
% controller/governor/parameter.csv : governor of the generator at each Bus
%   LPT selects controller.governor.IEEJ_LPT<LPT>; the other columns are its parameters.
    arguments (Input)
        net         (1,1) PowerNetwork  % Network being built.
        str_dirpath                     % Folder that holds the controller/ CSV files.
    end
    tab_gov = readtable(fullfile(str_dirpath, "controller", "governor", "parameter.csv"));
    for i = 1:height(tab_gov)
        i_bus = tab_gov.Bus(i);
        c_gov = namedargs2cell(table2struct(removevars(tab_gov(i,:), ["Bus","LPT"])));
        f_gov = str2func("controller.governor.IEEJ_LPT" + tab_gov.LPT(i));
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(f_gov("gov" + i_bus, c_gov{:}));
    end
end
