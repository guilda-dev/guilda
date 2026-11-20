classdef IEEJ_EAST30 < PowerNetwork
% IEEJ EAST 30-machine standard model (peak and night sections), exciters and governors on request.
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
% - Every branch has `circuit = 1` (column `circuit` of `branch/parameter.csv`): a line
%   branch is one circuit, and a transformer is one bank.
% - Shunts: `YC` of the N card is `Bshunt` (capacitors at peak, a reactor at night).
% - Loads: `P = -PL`, `Q = -QL`; negative `PL` of the data is kept.
% - Night section: nodes 3016 and 3020 pump with `PG`, `QG` given and no voltage. gen-park
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
%   filled, some zero) are not used. One q-axis circuit is obtained with `Xq_p = Xq`,
%   which removes the transient q-axis circuit: `Ed` stays 0 and `Tq_p` (1 s, not report
%   data) has no effect. `Tq_pp = Tq''*Xq/Xq''`.
% - `X_ls` is `XL` of G5. At node 2002 it exceeds `Xd''` and `Xq''` in the report too.
% - `D = 0`: the cards give no damping.
%
% Exciters:
%
% By default (`LocalController=false`) every generator keeps the Static AVR and governor
% (`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.
% `LocalController=true` adds the rotating-exciter model LAT=1 (report figure A1.1(a)),
% used for all machines, as controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`,
% `Vap_max = 100`, `Vap_min = -100`, `tex = 0.02`, `aex1 = 0.01`, `aex2 = bex = 0`,
% `tst = 0.5`, `kst = 0.1`, `Vfld_max = 4`, `Vfld_min = 0`. The exciter gain
% `100/(1 + 2s)` of the figure is `1/(aex1 + tex*s)`, the first lag with its limit is the
% amplifier, and `EF` is limited to 0 to 4 pu as in the figure. `EFS/100` of the figure
% is the steady amplifier output, which AVR_DC1 includes in `Vref`. The field voltages at
% the equilibrium are 1.20 to 2.19 pu at peak and 1.19 to 2.12 pu at night.
% `Limiter = 1` applies both limits; set it to false to ignore them.
%
% Governors:
%
% `Governor=true` (with `LocalController=true`) keeps the governor of each machine in
% `local_controller/gov-LPT1` and `local_controller/gov-LPT4`, from `LPT` of its G2 card: LPT=1 (report figure
% A1.2(a), thermal and nuclear) as controller.governor.IEEJ_LPT1 and LPT=4 (figure
% A1.2(c), hydro) as controller.governor.IEEJ_LPT4, with the constants of the figures.
% `Prate` is the rated MW of the G1 card over the 1000 MVA base and `PLM` the governor
% margin of the G1 card: 5 % for the thermal units, -10 % (load-limit operation) for the
% nuclear units at nodes 2001, 2005, 3001, 3002 and 3017, and 0 for the hydro units.
%
% - Peak: 30 governors, LPT=1 at the 22 thermal and nuclear units and LPT=4 at the eight
%   hydro units (nodes 3012 to 3016 and 3018 to 3020).
% - Night: 22 governors (LPT=1). The eight hydro units all pump (negative `P`), and the
%   night cards give them `LPT = 0`, a locked governor, so they have the Static governor and
%   keep `Pmech` constant.
%
% Not represented (differences from the report):
%
% - The frequency characteristics of the load NLT=2, 4 %/Hz (`P`) and -2 %/Hz (`Q`). The
%   loads are load-ZIP models with the default parameters, which are the voltage
%   characteristic of NLT=2 (`P` constant current above 0.7 pu and constant impedance
%   below, `Q` constant impedance), and their power does not depend on the frequency.
% - The report's variants LAT=2 and LAT=102. PSS1 observes `omega`, not `-Pg`, so
%   it does not match the delta-P PSS of LAT=102.
% - Generator saturation.
%
% With the exciters, with or without the governors, the equilibrium is stable: apart from
% the zero eigenvalue of the common angle (and of the common frequency without the
% governors, as `D = 0`), the largest real parts are about -0.0086 1/s at peak and
% -0.094 1/s at night with the governors, and -0.11 1/s at peak and -0.12 1/s at night
% without them. With the Static AVRs and governors only (`LocalController=false`, the
% default), apart from the zero modes of the common angle and frequency, both equilibria
% are unstable. The peak one has a very slow unstable real mode, about +0.00056 1/s (a
% time constant of about 30 min) in the angles and speeds of the machines, B3007SG1 and
% B2001SG1 most; the other real parts are -0.024 1/s or less. This mode lies close to
% the zero modes and its eigenvalue is ill-conditioned (accurate to about 1e-4 1/s), but
% it is not a rounding error: it stays the same with a power-flow Tolerance of 1e-12, and
% the linearized response along it grows at this rate. The night one has two unstable
% real eigenvalues, about +0.073 and +0.039 1/s.
%
% Verification:
%
% The comparisons with the report are in `_GUILDAverification/IEEJ_EAST30_peak/` and
% `_GUILDAverification/IEEJ_EAST30_night/` of the repository, one folder per section:
% `+PF/README.md` (network data, generator, exciter and governor constants, and the
% power flow against the flow diagram, fig. 4.17) and `+TimeResponse/README.md` (the
% transient stability cases of table 4.9, 3LG-O faults), each with its data and script.
%
% <@Examples>
% Run the power flow of the night section with the exciters and governors, and simulate a fault at node 3105 cleared by
% opening both circuits of the line 3105-3104 (card 3104, branches `EL047` and `EL048`):
%
% ```matlab
% net = network.IEEJ_EAST30(Section="night", LocalController=true);
% res = net.calculate_powerflow();
% sc  = net.add_scenario("fault-open", Time=[0,10]);
% sc.add_fault("B3105", [1,1.07]);
% sc.add_open_branch(["EL047";"EL048"], 1.07);
% sol = net.simulate("fault-open");
% ```
%
% See also controller.avr.AVR_DC1, controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT4, component.generator.park, network.IEEE68bus

    properties(Constant) % Data
        ver = 2  % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_EAST30(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments (Input)
                opt.Section         (1,1) string {mustBeMember(opt.Section, ["peak","night"])} = "peak"  % Power-flow section: "peak" or "night".
                opt.LocalController (1,1) logical = false  % true to add the local controllers (exciters, and governors if Governor is true); false keeps the default Static AVR and governor (avr-static, gov-static) on the generators.
                opt.Governor        (1,1) logical = true  % true for the governors (IEEJ_LPT1, IEEJ_LPT4) of local_controller/; false gives every generator the Static governor. Used only when LocalController is true.
            end
            arguments (Output)
                obj  % IEEJ_EAST30 network.
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
