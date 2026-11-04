classdef IEEJ_EAST30 < PowerNetwork
% IEEJ EAST 30-machine standard model (peak and night sections) with exciters.
% The EAST 30-machine power system model of the Institute of Electrical Engineers of
% Japan (IEEJ), a reduction of the 50 Hz system with long-period swings, from the IEEJ
% technical report on standard power system models:
% http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html (section 4.4, tables 4.6 to
% 4.9, appendices 1 and 2). It has 107 buses, 191 branches (136 line circuits and 55
% transformers), 30 generators and 31 loads; 50 Hz, 1000 MVA base. `Section` selects
% the peak (daytime, heavy load) or the night (light load, pumping) power-flow section.
%
% Bus types:
%
% - Slack bus: the bus tagged `B3010`
% - PV buses: the other 29 generator buses
% - PQ buses: the other 77 buses
%
% Buses:
%
% The report numbers its nodes sparsely. The buses are numbered consecutively in the
% order of the data, and each bus tag is `B` + the node, so `B3104` is node 3104.
% Generator nodes come first: buses 1 to 8 are nodes 2001 to 2008 and buses 9 to 30 are
% nodes 3001 to 3022. `bus/parameter.csv` lists the others.
%
% Data:
%
% The values come from the Y-method data cards of the report (format in its appendix 2).
% The conversions are:
%
% - Lines (T cards): pi branches, one per circuit, with the card values `ZR`, `ZX` and
%   `C = YC`, where `YC = Y/2` is the charging at each end. Each card has two circuits.
%   These are reduced values, not the report's standard per-km values, and are not
%   normalized. The two circuits of a card are separate parallel branches.
% - Transformers (X cards): pi_transformer branches from `NF` to `NT` with `X = ZX`
%   (one bank on all cards), `R = C = 0` and `tap = 1/TAPR`. The report's 0.14 pu
%   transformer rule does not apply to this model.
% - Shunts: `YC` of the N card is `Bshunt` (capacitors at peak, a reactor at night).
% - Loads: `P = -PL`, `Q = -QL`; negative `PL` of the data is kept.
% - Night section: nodes 3016 and 3020 pump with `PG`, `QG` given and no `V0`. gen-park
%   buses are PV buses, so their `V` is the voltage at which the power flow gives `QG`.
% - Night section: the node data's `PG` of node 3015 is -0.65, and the slack and `QG`
%   values on the same cards fit -0.75. The report's pumping total (9,270 MW) and its
%   flow diagram agree with -0.65, which is kept; slack `P` is then 1.417 pu, not the
%   1.520 pu on the card.
% - The data have no bus coordinates, voltage limits or OPF data, and these are the
%   GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for
%   generators and 0 for loads).
%
% Generators:
%
% The report uses LGT=4, a Park model with one damper on each axis, for all machines.
% They are gen-park models on the system base (reactances times `1000/GMVA`,
% `M = MG*GMVA/1000`, where `MG` is `2H` on `GMVA`):
%
% - d axis: `Xd`, `Xd_p`, `Xd_pp`, with `Td_p = Td'*Xd/Xd'` and `Td_pp = Td''*Xd'/Xd''`
%   from the short-circuit constants, which are the values of the report's table 4.7.
% - q axis: LGT=4 has no `Xq'` or `Tq'`, so the `Xq'`, `Tq'`, `Tqo'` fields of G4 (some
%   filled, some zero) are not used. One q-axis circuit is obtained with
%   `Xq_p = Xq*(1 - 1e-6)` and `Tq_p = 1`, so `Ed` stays near 0 and decays alone:
%   gen-park cannot take `Xq_p = Xq`, since its equilibrium divides by `Xq - Xq_p`. These
%   two values are not report data. `Tq_pp = Tq''*Xq/Xq''`.
% - `X_ls` is `XL` of G5. At node 2002 it exceeds `Xd''` and `Xq''` in the report too.
% - `D = 0`: the cards give no damping.
%
% Exciters:
%
% `LocalController=true` adds the rotating-exciter model LAT=1 (report figure A1.1(a)),
% used for all machines, as controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`,
% `Vap_max = 100`, `Vap_min = -100`, `tex = 0.02`, `aex1 = 0.01`, `aex2 = bex = 0`,
% `tst = 0.5`, `kst = 0.1`. The exciter gain `100/(1 + 2s)` of the figure is
% `1/(aex1 + tex*s)`, and the first lag with its limit is the amplifier. `EFS/100` of the
% figure is the steady amplifier output, which AVR_DC1 includes in `Vref`. The one
% difference from LAT=1 is that `EF` has no limit 0 to 4 pu: AVR_DC1 has no such limit.
%
% Not represented (differences from the report):
%
% - Governors (LPT=1 and 4, `PLM`): GUILDA has no governor controller, so `Pmech` is
%   constant.
% - Load NLT=2: `P` is constant current above 0.7 pu and constant impedance below, and
%   `Q` is constant impedance, with frequency characteristics of 4 %/Hz and -2 %/Hz.
%   These are load-impedance models: `Q` and `P` below 0.7 pu match, `P` above 0.7 pu
%   varies with the square of the voltage rather than linearly, and frequency has no effect.
% - The report's variants LAT=2 and LAT=102. PSS1 observes `omega`, not `-Pg`, so
%   it does not match the delta-P PSS of LAT=102.
% - Generator saturation.
% - Opening a line: simulate has a bus fault but no branch switching, so the report's
%   3LG-O sequence cannot be run directly.
%
% With the exciters the equilibrium is stable. Without them (`LocalController=false`)
% one real eigenvalue is unstable: about +0.057 1/s at peak and +0.029 1/s at night.
%
% <@Examples>
% Run the power flow of the night section and simulate a fault at node 3104:
%
% ```matlab
% net = network.IEEJ_EAST30(Section="night");
% res = net.calculate_powerflow();
% ev  = EventODE("fault", net, "TimeSpan", [1,1.07], "FaultBus", "B3104");
% sol = net.simulate([0,5], ev);
% ```
%
% See also controller.avr.AVR_DC1, component.generator.park, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_EAST30(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments
                opt.Section         (1,1) string {mustBeMember(opt.Section, ["peak","night"])} = "peak" % Power-flow section: "peak" or "night".
                opt.LocalController (1,1) logical = true % true to add the LAT=1 exciter (AVR_DC1) to every generator.
            end
            arguments (Output)
                obj % IEEJ_EAST30 network.
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
