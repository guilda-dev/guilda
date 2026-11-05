 classdef power < component.load.abstract
% Legacy constant-power load model with the v1 component interface.
%
% The model has no states and two input ports, `RealPower` and `ReactivePower`
% (`naming_port`). It uses the old interface (`get_dx_constraint`,
% `get_linear_matrix`) and does not define the model constants of `Component`
% (`key`, `sv_x`, `sv_u`, `sv_y`, `sv_para`), so it cannot be created or added to a
% bus.
%
% <@Deprecated> Use `component.load.power` (key `"load-power"`).
%
% See also component.load.power
    
    properties % Steady state
        PQ_st  % [pu] Steady power [P; Q], set by get_equilibrium.
    end

end
