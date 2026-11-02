classdef IEEJ_EAST10 < PowerNetwork
% IEEJ EAST 10-machine standard model (power flow data; machine constants are missing).
% The EAST 10-machine model of the Institute of Electrical Engineers of Japan (IEEJ),
% from the data files dated 2000, in its peak and night power-flow sections.
% It has 47 buses, 61 branches (39 line cards and 22 transformer cards), 10 generators
% and 12 loads; 50 Hz, 1000 MVA base.
%
% The network is not ready for dynamic analysis. The source files select the machine
% and AVR models by a type number and give no reactances, time constants or AVR
% parameters, so `Xd`, `Xq`, `Xd_p`, `Td_p` are NaN. calculate_powerflow works;
% initialize and simulate give NaN states. The constructor warns about this with
% GUILDA:IEEJ_EAST10:MissingMachineConstants.
%
% Bus types:
%
% - Slack bus: bus 3 (peak), bus 6 (night)
% - PV buses: the other buses of 1 to 10
% - PQ buses: buses 11 to 47; buses 18, 19, 38 to 47 have loads
%
% Data:
%
% The source format has no column definitions for these files. The conversions below
% were chosen because they reproduce the power flow results stored in the source.
%
% - Each line card is one branch.pi with `R = r/n`, `X = x/n`, `C = n*y`: `n` is the
%   circuit count of the card (always 2) and `r`, `x`, `y` are per circuit, with `y` at
%   each end. Parallel cards stay parallel branches (for example two from bus 12 to 13).
% - Each transformer card is one branch.pi_transformer with `tap = 1/t`: the source
%   ratio `t` scales the voltage of the From bus. It has no resistance or charging.
% - Generators have the P of the source and voltage control at the source V. The P of
%   the slack bus is not used, and `Q` is solved by the power flow.
% - `M` and `D` are the source values converted from the machine base to the 1000 MVA
%   system base by `GMVA/1000`. That the base is GMVA is an assumption. `D` = -10 of
%   generators 2 and 7 is kept as given; its meaning in the source is not known.
% - `baseMVA` of a generator is the GMVA of the source.
% - Loads are load-impedance models. The source has a load characteristic card that is
%   not used, because its meaning is not known.
% - The source has no bus coordinates, voltage limits, base voltages or OPF data; these
%   are the GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost
%   `HP = fP = 1` for generators and 0 for loads).
%
% Compared with the values stored in the source, the slack P is 0.0231 pu lower (peak)
% and 0.0092 pu lower (night), and the generator Q differs by at most 0.0148 pu (peak)
% and 0.0050 pu (night). The cause is not known.
%
% <@Examples>
% Run the power flow of the night section:
%
% ```matlab
% net = network.IEEJ_EAST10(Section="night");
% res = net.calculate_powerflow();
% res.tab_bus
% ```
%
% See also PowerNetwork.calculate_powerflow, network.IEEE68bus

    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = IEEJ_EAST10(opt)
            % Create the network from the CSV data of one power-flow section.
            arguments
                opt.Section (1,1) string {mustBeMember(opt.Section,["peak","night"])} = "peak" % Power-flow section.
            end
            arguments (Output)
                obj % IEEJ_EAST10 network.
            end
            str_dirpath = fullfile(fileparts(mfilename("fullpath")), opt.Section);
            PowerNetwork.import_csv(str_dirpath, Network=obj, Initialize=false);
            warning("GUILDA:IEEJ_EAST10:MissingMachineConstants", ...
                "The machine constants of IEEJ_EAST10 are not available (NaN): use it for the power flow only.");
        end
    end
end
