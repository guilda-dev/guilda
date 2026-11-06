function handle_edit(obj, a_layer, tag, log)
% Mark the stale tags of the controller for its own edits (LayerPackage.log_edit).
%   dynamics (its para_dynamics, or a property of the controller itself,
%             e.g. Q, R, V0 of local_LQR)   equilibrium, odefcn
%   Topology (a nested controller)          equilibrium
% Edits of other layers are not the controller's.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        a_layer        % Edited layer (the owner for a parameter edit).
        tag string     % Kind of edit.
        log string     % Message of the edit.
    end
    if a_layer ~= obj
        return
    end
    if tag == "dynamics"
        obj.sct_stale.equilibrium(end+1,1) = log;
        obj.sct_stale.odefcn(end+1,1)      = log;
    elseif tag == "Topology"
        obj.sct_stale.equilibrium(end+1,1) = log;
    end
end
