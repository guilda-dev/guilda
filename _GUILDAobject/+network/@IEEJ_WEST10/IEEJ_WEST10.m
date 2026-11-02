classdef IEEJ_WEST10 < PowerNetwork
% IEEJ WEST 10-machine standard model (power flow data only).
% The West 10-machine model of the IEEJ (Institute of Electrical Engineers of Japan)
% standard power system models. It is a longitudinal system with 27 buses, 42 branches
% (32 lines and 10 transformers), 10 generators and 17 loads; 60 Hz, 1000 MVA base.
% `Section` selects the peak or the night power-flow section.
%
% The dynamic constants are not complete: the source data has no machine reactances
% and time constants, no damping and no AVR parameters. The network therefore supports
% calculate_powerflow only. The constructor warns (GUILDA:IEEJ_WEST10:NoDynamics) and
% does not initialize it; net.initialize gives NaN states and only warns, so do not
% run simulate or linearize on it. See Data.
%
% Bus types (the bus tags `B001` to `B030` are the bus numbers of the source data, and
% 10, 11 and 20 do not exist):
%
% - Slack bus: `B030`
% - PV buses: `B021` to `B029` (generators, 1.03 pu), and `B001`, `B009`, `B012` to
%   `B019` (loads, 1.00 pu)
% - PQ buses: `B002` to `B008`
%
% Data:
%
% The values are converted from the fixed-column data files of the model (2000). These
% files do not document their columns; the meanings below come from the column headers
% of the one-machine deck of the same data set and from the checks stated here.
%
% - The data are per unit on the system base of the source, 1000 MVA.
% - A `T` card with `P = 2` is two parallel pi branches and `P = 1` one branch: `P` is
%   read as the number of circuits, with `R`, `X`, `Y` per circuit. With this reading
%   the connection of every 10000 MVA machine has the same impedance, whether it is
%   written as two cards (LINE120) or one (LINE130 to 170, LINE190), and that of the
%   5000 MVA machine (LINE180) has twice the impedance. A branch from a `P = 2` card has
%   the card name with `-1` or `-2`.
% - The `Y` of a `T` card is the charging at each end (`C = Y`). The files do not say
%   this, nor the voltage. It is read from the surge impedance: on an assumed 500 kV
%   base, `Y` at each end gives 254 ohm, the usual value of a 500 kV line, and `Y` as the
%   total gives 359 ohm. In the power flow, the other reading changes V by at most 0.005 pu.
% - `X` cards are pi_transformer branches with `R = 0`, `C = 0`, `tap = 1`, `phase = 0`.
% - A nonzero `Vset` of a bus without generation is read as a voltage-controlled bus, as
%   for the generators. The load there has `Q = NaN`, so its `Q` includes the reactive
%   support that holds the voltage. The deck gives `QL = 0` on all these buses.
% - Generators have `P = PG`, `Q = NaN`, and the machine rating `baseMVA = GMVA`. `M` is
%   the `MG` column (read as being on the machine base) converted to the system base,
%   `M = MG*GMVA/1000`.
% - Loads are load-impedance models (constant impedance at the power-flow solution). The
%   `L` card holds load characteristics in undocumented columns and is not used.
% - The source has no voltage limits, base voltages or OPF data; these are the GUILDA
%   defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for generators
%   and 0 for loads).
%
% Not in the data:
%
% - The generators are stored as gen-1axis with `D`, `Xd`, `Xq`, `Xd_p`, `Td_p` = NaN.
%   The `G1` cards select them only by the codes `LGT` and `Ngt`, and the source has no
%   `G3` to `G5` cards. gen-1axis is a placeholder for the machine model.
% - The `DG` column of the `G1` cards is blank. The column before it, `PLM`, differs
%   between the sections; its meaning is unknown and it is not used.
% - The `G2` cards refer to AVR 1, and the source has no `A` cards, so there are no AVR
%   parameters and no `LocalController` option.
%
% <@Examples>
% Run the power flow of the night section:
%
% ```matlab
% net = network.IEEJ_WEST10(Section="night");
% res = net.calculate_powerflow();
% res.tab_bus
% ```
%
% See also PowerNetwork.calculate_powerflow, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_WEST10(opt)
            % Create the network from the CSV data of the section in the class folder.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak" % Power-flow section.
            end
            arguments (Output)
                obj % IEEJ_WEST10 network.
            end
            str_dirpath = fileparts(mfilename("fullpath"));
            PowerNetwork.import_csv(fullfile(str_dirpath, opt.Section), Network=obj, Initialize=false);
            warning("GUILDA:IEEJ_WEST10:NoDynamics", ...
                    "The source data has no machine reactances, damping or AVR parameters. Only calculate_powerflow is usable on this network.");
        end
    end
end
