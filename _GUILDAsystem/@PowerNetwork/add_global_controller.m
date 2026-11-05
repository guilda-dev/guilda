function add_global_controller(obj, a_Gcon)
% Add a global controller to the network.
%
% `a_Gcon` is a GlobalController built for this network; its tag must not be in use
% yet. Its controlled units must be components of this network that have the states
% `sv_u` and the inputs `sv_y` of the controller. The addition is logged as a "Topology" edit.
%
% See also PowerNetwork.remove_global_controller, GlobalController
%
% <@Group> Model building
    arguments (Input)
        obj
        a_Gcon (1,1) GlobalController   % Global controller built for this network.
    end
    if ismember(a_Gcon.str_tag, string(obj.a_GlobalController))
        error(msg("GUILDA:PowerNetwork:GconTagInUse", char(a_Gcon.str_tag), char(obj.str_tag)))
    end
    for idx = 1:numel(a_Gcon.controlledUnits)
        unit = a_Gcon.controlledUnits{idx};
        % Compare handles: isequal would accept an identical copy of the network
        if isempty(unit.a_Bus) || isempty(unit.a_Bus.a_PowerNetwork) || unit.a_Bus.a_PowerNetwork ~= obj
            error(msg("GUILDA:PowerNetwork:GconOtherNetwork", char(a_Gcon.str_tag), char(unit.str_tag), char(obj.str_tag)))
        end
        str_missing = ["state "+a_Gcon.sv_u(~ismember(a_Gcon.sv_u, unit.sv_x)); ...
                       "input "+a_Gcon.sv_y(~ismember(a_Gcon.sv_y, unit.sv_u))];
        if ~isempty(str_missing)
            error(msg("GUILDA:PowerNetwork:GconPorts", char(a_Gcon.str_tag), char(unit.str_tag), class(unit), char(strjoin(str_missing, ", "))))
        end
    end
    obj.a_GlobalController = [obj.a_GlobalController; {a_Gcon}];
    a_Gcon.set_parent(obj);
    obj.log_edit(obj.str_tag+" <<-Add--- "+a_Gcon.str_tag,"Topology");
end