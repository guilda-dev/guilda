classdef IEEJ_EAST30 < PowerNetwork
% IEEJ EAST 30-machine standard model (peak and night sections), without controllers.
% The EAST 30-machine power system model of the Institute of Electrical Engineers
% of Japan (IEEJ). It has 107 buses, 123 branches (68 double-circuit lines and 55
% transformers), 30 generators and 31 loads; 50 Hz, 1000 MVA base. `Section` selects
% the peak or the night power-flow section.
%
% Bus types:
%
% - Slack bus: the bus tagged `B3010`
% - PV buses: the other 29 generator buses
% - PQ buses: the other 77 buses
%
% Buses:
%
% The deck numbers its nodes sparsely. The buses are numbered consecutively in the
% order of the deck, and each bus tag is `B` + the deck node, so `B3104` is node 3104.
% Generator nodes come first: buses 1 to 8 are nodes 2001 to 2008 and buses 9 to 30
% are nodes 3001 to 3022. `bus/parameter.csv` lists the others.
%
% Data:
%
% The values come from the fixed-column cards of the IEEJ data deck (Y-method format,
% 2000). The deck has no column documentation, so the meanings below are inferred, with
% the evidence given. The conversions are:
%
% - Lines (T cards): `R`, `X`, `Y` are per circuit and `Y` is the charging at each end,
%   for the number of circuits `P` (2 on all cards). The two circuits are one pi branch
%   with `R/2`, `X/2`, `C = 2*Y`, so one circuit cannot be tripped alone.
% - Transformers (X cards): pi_transformer branches from the first node to the second
%   with `X = Z1X`, `R = C = 0` and `tap = 1/TAPR`.
% - The line and transformer meanings were selected by solving the power flow for each
%   candidate against the deck's generator `QG`. With this one the peak section differs
%   by at most 0.0005 pu; every other candidate differs by at least 0.38 pu or diverges.
% - Shunts: `YC` of the N card is `Bshunt`. Positive is capacitive, as in the peak
%   section, where this reproduces `QG`.
% - Loads: load-impedance models with `P = -PL`, `Q = -QL`. Some are negative in the deck
%   (for example node 3304) and are kept.
% - Generators: gen-park models. On G3 and G4 the seven columns are `X`, `X'`, `X''`,
%   `T'`, `T''`, `T0'`, `T0''`, since `T' = T0'*X'/X` holds on all 30 G3 cards to 0.1 %.
%   `G1` gives the rating `GMVA` and `MG`. Reactances are converted from the machine
%   base to the system base by `1000/GMVA`, and `M = MG*GMVA/1000`.
% - `M` assumes that `MG` is on `GMVA`, not on `GMW`. The data do not settle this.
% - `X_ls` is the first column of G5. This is an inference: at node 2002 it exceeds
%   `Xd_pp` and `Xq_pp`, which a leakage reactance should not. Replacing it there with
%   the third G5 column changes the rightmost eigenvalue by less than 0.001 1/s. The
%   other G5 columns are not used.
% - `D = 0`: the deck has no damping column value. The column `PLM` of G1 (-10, 5, 0 for
%   the three machine groups) has no known meaning and is not used.
% - q axis with one circuit: on 11 machines G4 has no transient circuit (`Xq' = 0` or
%   `Tq0' = 0`: nodes 2001, 2004, 2006, 3012 to 3016, 3018 to 3020). For them
%   `Tq'' = Tq0''*Xq''/Xq` holds, except at node 2001, which has no `Tq0''`, and within
%   20 % at node 2006. They use `Xq_p = Xq*(1 - 1e-6)` and `Tq_p = 1`, so `Ed` stays
%   near 0 and decays alone. gen-park cannot take `Xq_p = Xq`: its equilibrium
%   divides by `Xq - Xq_p`. `Tq_p` is not deck data and has almost no effect.
% - Node 2001 has no `Td0''` and no `Tq0''`. They are derived from the given `Td''` and
%   `Tq''`: `Td0'' = Td''*Xd'/Xd''` and `Tq0'' = Tq''*Xq/Xq''`.
% - Night section: nodes 3016 and 3020 are pumping machines with `PG`, `QG` given and no
%   `Vset`. gen-park buses are PV buses, so their `V` is the voltage at which the power
%   flow gives the deck's `QG`.
% - Night section: the deck's `PG` of node 3015 is -0.65, but its slack and `QG` values
%   fit -0.75. The card value -0.65 is kept. The slack power is then 1.417 pu, against
%   1.520 pu in the deck, and `QG` differs by up to 0.024 pu.
% - The deck has no bus coordinates, voltage limits, base voltages or OPF data; these
%   are the GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1`
%   for generators and 0 for loads).
%
% Not included:
%
% - AVRs, PSSs and governors. The cards select them by built-in type numbers that the
%   deck does not define, and the one explicit AVR card (`A 102`) has no column
%   meanings, so no controller is added. The inputs `Pmech` and `Vfield` stay constant.
% - The load characteristic (L card, values 4 and -2) has no column meanings. The loads
%   are constant impedance, which may differ from the deck.
% - Saturation and the deck's fault sequences.
%
% The equilibrium is unstable: one real eigenvalue is +0.057 1/s for peak and +0.029 1/s
% for night. The oscillatory modes are all damped. Adding `D` does not remove this
% eigenvalue. Adding controller.avr.AVR_ST1 to every generator does, so it is attributed
% to the constant field voltage; that AVR without a PSS (`kap` 20 or 50) then gives
% unstable oscillatory modes instead, so it is not a substitute for the deck's controllers.
%
% <@Examples>
% Run the power flow of the night section and simulate a fault at node 3104:
%
% ```matlab
% net = network.IEEJ_EAST30(Section="night");
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.07], "FaultBus", "B3104");
% sol = net.simulate([0,5], ev);
% ```
%
% See also component.generator.park, network.IEEE68bus, PowerNetwork.import_csv

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_EAST30(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section, ["peak","night"])} = "peak" % Power-flow section: "peak" or "night".
            end
            arguments (Output)
                obj % IEEJ_EAST30 network.
            end
            str_dirpath = fileparts(mfilename("fullpath"));
            PowerNetwork.import_csv(fullfile(str_dirpath, opt.Section), Network=obj);
        end
    end
end
