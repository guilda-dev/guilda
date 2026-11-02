classdef IEEJ_WEST30 < PowerNetwork
% IEEJ WEST 30-machine standard power system model.
% The WEST 30-machine model of the Institute of Electrical Engineers of Japan, a
% longitudinal system for stability studies. It has 115 buses, 129 branches (99 lines
% and 30 transformers), 30 generators and two power-flow sections, peak and night;
% 60 Hz, 1000 MVA base. The generators have no AVR, PSS or governor: the source data
% has no parameters for them (see Data).
%
% Bus types:
%
% - Slack bus: bus 15 (node 3150)
% - PV buses: the other generator buses, buses 1 to 30
% - PQ buses: buses 31 to 115
%
% Data:
%
% The values are converted from the Y-method data deck of the model (September 2000
% distribution, the `s` files of `west30p` and `west30n`). The deck does not document
% its columns. Their meanings below are inferred from the column headers of the
% one-machine model in the same distribution and from the checks stated here. The CSV
% files in `peak/` and `night/` have the same layout.
%
% - The sparse node numbers map to consecutive buses: nodes 3010 to 3300 (generators)
%   are buses 1 to 30, nodes 1010 to 1550 are buses 31 to 85, and nodes 2010 to 2300
%   are buses 86 to 115. The bus tag keeps the node number, for example `B3010`.
% - Lines (`pi`): the column `P` is the number of parallel circuits and `R`, `X`, `Y`
%   are per circuit, so `R` and `X` are divided by `P` and `Y` is multiplied by `P`.
%   `Y/X` is the same for `P = 1` and `P = 2`, which rules out totals.
%   `Y` is the charging at each end, so `C = Y*P`. As total charging `Y` would give a
%   surge impedance far from a 500 kV line and bus voltages down to 0.950 pu at peak,
%   against 0.991 pu with the conversion used here.
% - The R values of lines 1190, 1430 and 1890 do not follow the `R/X` of 0.033 of the
%   other lines, and may be misprints. They are kept as written.
% - Transformers (`pi_transformer`): `R = 0`, and `X` and the tap (1 for all) as written.
% - The column `YC` is the bus shunt susceptance `Bshunt`, positive for a capacitor.
%   This sign gives voltages near 1 pu; the night section has negative values at
%   lightly loaded buses, as shunt reactors would be.
% - The generator data is on the machine MVA of each section (`GMVA`), which differs
%   between peak and night, and is converted to the 1000 MVA base: `M = MG*GMVA/1000`
%   and reactances are multiplied by `1000/GMVA`. Time constants are as written.
%   `MG` is taken as `2H` on `GMVA`.
% - Generators are gen-park models. The cards `G3` and `G4` are read as `Xd`, `Xd_p`,
%   `Xd_pp`, `Td_p`, `Td_pp` and `Xq`, `Xq_p`, `Xq_pp`, `Tq_p`, `Tq_pp`, and the first
%   column of `G5` as `X_ls`. The other columns of `G3`, `G4` and `G5` and the columns
%   `PLM` and `Ngt` of `G1` are not used; armature resistance and saturation are not
%   modeled. The damping `D` is 0, as in the deck.
% - Node 3300 has `Xq_p` smaller than `Xq_pp`. It is kept as written.
% - Node 3140 has `Xq_p = Xq`, for which the equilibrium of gen-park divides by zero.
%   Its `Xq_p` is `Xq*(1 - 1e-4)`.
% - In the night section the pumping machines at nodes 3080, 3140, 3240 and 3250
%   (buses 8, 14, 24, 25) are given as `P < 0`, `Q = 0` with no voltage setting. A
%   generator bus is always a PV bus here, so their bus `V` is the voltage of the
%   solution with these buses as PQ, which gives the same power flow with `Q = 0`.
% - The cards `G2` give the AVR type `LAT = 1` and no parameters: the deck has no `A`
%   card. The generators therefore have constant `Vfield` and `Pmech`, and this class
%   has no option `LocalController`.
% - Loads are load-impedance models (constant impedance at the power-flow solution).
%   The file `s` activates a nonlinear load card (`NLT = 2`) that is not converted; the
%   deck labels its variant without that card (`s0`) as constant impedance. The two
%   files have the same network and machine data, and `s107` differs in the load card
%   only.
% - The deck has no bus coordinates, voltage limits, base voltages or OPF data; these
%   are the GUILDA defaults.
%
% The specified generation of the night section does not match the losses of the
% solved power flow: the slack generator gives 1.38 pu against the specified 1.30 pu
% (peak: 3.804 pu against 3.80 pu).
%
% The equilibrium is unstable in both sections, because the generators have constant
% field voltage, and a fault leads to loss of synchronism. Add local controllers to
% use the network for transient studies; this class does not provide their parameters.
%
% <@Examples>
% Run the power flow of the night section and simulate a fault at node 1040:
%
% ```matlab
% net = network.IEEJ_WEST30(Section="night");
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.07], "FaultBus", "B1040");
% sol = net.simulate([0,10], ev);
% ```
%
% See also component.generator.park, component.load.impedance, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_WEST30(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section, ["peak","night"])} = "peak" % Power-flow section: "peak" or "night".
            end
            arguments (Output)
                obj % IEEJ_WEST30 network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(fullfile(str_dirpath, opt.Section), Network=obj, Initialize=false);
            obj.initialize;
        end
    end
end
