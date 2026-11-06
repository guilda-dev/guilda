function add_global_controller(obj, a_Gcon)
% Add a global controller to the network.
%
% `a_Gcon` is a GlobalController built for this network; its tag must not be in use
% yet. Its controlled units must be components of this network that have the states
% `sv_u` and the inputs `sv_y` of the controller. The addition is a "Topology" edit of the
% controller: its own equilibrium and handles are stale until net.initialize(); the power
% flow is not.
%
% See also PowerNetwork.remove_global_controller, GlobalController
%
% <@Group> Model building
    arguments (Input)
        obj
        a_Gcon (1,1) GlobalController   % Global controller built for this network.
    end
    if ismember(a_Gcon.s_tag, string(obj.a_GlobalController))
        error(msg("GUILDA:PowerNetwork:GconTagInUse", char(a_Gcon.s_tag), char(obj.s_tag)))
    end
    for idx = 1:numel(a_Gcon.controlledUnits)
        unit = a_Gcon.controlledUnits{idx};
        % Compare handles: isequal would accept an identical copy of the network
        if isempty(unit.a_Bus) || isempty(unit.a_Bus.a_PowerNetwork) || unit.a_Bus.a_PowerNetwork ~= obj
            error(msg("GUILDA:PowerNetwork:GconOtherNetwork", char(a_Gcon.s_tag), char(unit.s_tag), char(obj.s_tag)))
        end
        sv_missing = ["state "+a_Gcon.sv_u(~ismember(a_Gcon.sv_u, unit.sv_x)); ...
                       "input "+a_Gcon.sv_y(~ismember(a_Gcon.sv_y, unit.sv_u))];
        if ~isempty(sv_missing)
            error(msg("GUILDA:PowerNetwork:GconPorts", char(a_Gcon.s_tag), char(unit.s_tag), class(unit), char(strjoin(sv_missing, ", "))))
        end
    end
    obj.a_GlobalController = [obj.a_GlobalController; {a_Gcon}];
    a_Gcon.a_PowerNetwork = obj;
    a_Gcon.log_edit("added to " + obj.s_tag, "Topology");
end