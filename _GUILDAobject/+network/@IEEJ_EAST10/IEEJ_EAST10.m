classdef IEEJ_EAST10 < PowerNetwork
% IEEJ EAST 10-machine standard model, with a peak and a night power-flow section.
% The EAST 10-machine model of the Institute of Electrical Engineers of Japan (IEEJ)
% for the 50 Hz loop system, from the IEEJ report on standard power system models
% (http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html, section 4.2, tables 4.1
% to 4.3 and appendices 1 and 2) and its Y-method input data.
% It has 47 buses, 61 branches (39 line cards and 22 transformer cards), 10 generators
% and 12 loads; 50 Hz, 1000 MVA base. Lines and transformers are one branch per card.
%
% Bus types:
%
% - Slack bus: bus 3 (peak), bus 6 (night)
% - PV buses: the other buses of 1 to 10
% - PQ buses: buses 11 to 47; buses 18, 19, 38 to 47 have loads
%
% Data:
%
% - A line card is a branch.pi with `R = r/n`, `X = x/n`, `C = n*y`: `n` is the circuit
%   count of the card (always 2) and `r`, `x`, `y = Y/2` are per circuit. Parallel
%   cards stay parallel branches (for example two from bus 12 to 13).
% - A transformer card is a branch.pi_transformer with `tap = 1/t`, `t` being TAPR.
% - Generators use the source PG and Vset; the PG of the slack bus and QG are not used.
%   `baseMVA` is the rating of table 4.2. PLM (5, or -10 for G2 and G7) is the governor
%   margin and is not used.
% - The generators are gen-park models. The source model LGT=4 has one damper in each
%   axis, the standard constants of appendix table 1.1 selected by NGT (2 thermal,
%   6 nuclear, 8 hydro), and no saturation data. The conversions are:
%   - `M` (machine MVA base) and all reactances are moved to the 1000 MVA system base
%     by `GMVA/1000`.
%   - The table gives short-circuit time constants; the open-circuit ones are
%     `Td_p = Td'*Xd/Xd'`, `Td_pp = Td''*Xd'/Xd''`, `Tq_pp = Tq''*Xq/Xq''`.
%   - `Xq_p = Xq*(1-1e-6)` removes the q-axis transient circuit, which LGT=4 does not
%     have: `Ed` stays near 0 (below 1e-6), and `Tq_p = 1` has no measurable effect. The
%     small margin is needed because gen-park divides by `Xq - Xq_p`.
%   - `D = 0`: the DG field of the source is blank.
%   - The armature time constant `Ta` has no counterpart in gen-park and is not used.
% - The AVR is the rotating-exciter model LAT=1 of appendix figure 1.1, as
%   controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`, `Vap_max = 100`,
%   `Vap_min = -100`, `tex = 0.02`, `aex1 = 0.01`, `aex2 = bex = 0`, `tst = 0.5`,
%   `kst = 0.1`. `Vap` is the output of the first lag, with its +-100 limit, and
%   `0.02*dVfld/dt = -0.01*Vfld + Vap` is the exciter `100/(1 + 2*s)`, so the linear part
%   is the same. The field voltage setting EFS/100 of the figure is part of `Vref` here.
%   The limit `0 <= EF <= 4` of LAT=1 is not modeled: AVR_DC1 has no limit on `Vfield`.
%   In simulations of table 4.3 the unlimited EF reached 7.9.
% - The source's PSS variant LAT=102 is not part of the base case and is not included.
% - The source has governors (LPT=1 or 4, locked for pumping machines at night). GUILDA
%   has no governor class, so `Pmech` is constant.
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
% - The peak equilibrium with AVRs is slightly unstable (eigenvalue
%   `0.0204 +- 2.13i`); the night one has no unstable mode apart from the zero mode of
%   the common angle. Without the AVRs (`LocalController=false`) the peak equilibrium
%   has an unstable real eigenvalue `0.167`.
% - The long-period oscillation is about 3.0 s (peak) and 2.1 s (night); the report
%   states about 2 s and 3 s for its model.
% - For the 44 cases of table 4.3 (70 ms three-phase fault at the From end, then opening
%   the circuits), the stable or out-of-step result agreed in 35. ODEevent cannot
%   open a branch, so these used a separate integrator of the same equations outside
%   this class; net.simulate gives only the bus fault.
%
% <@Examples>
% Run the power flow of the night section, and simulate a fault at bus 36 at peak:
%
% ```matlab
% net = network.IEEJ_EAST10(Section="night");
% res = net.calculate_powerflow();
% net = network.IEEJ_EAST10();
% ev  = ODEevent("fault", net, "TimeSpan", [1,1.07], "FaultBus", "B036");
% sol = net.simulate([0,10], ev);
% ```
%
% See also controller.avr.AVR_DC1, component.generator.park, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_EAST10(opt)
            % Create the network from the CSV data of one power-flow section.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak" % Power-flow section.
                opt.LocalController (1,1) logical = true % true to add an AVR to every generator.
            end
            arguments (Output)
                obj % IEEJ_EAST10 network.
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
