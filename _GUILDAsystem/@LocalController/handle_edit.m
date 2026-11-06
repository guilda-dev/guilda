function handle_edit(obj, a_layer, tag, log)
% Mark the stale tags of the controller for its own edits (LayerPackage.log_edit).
%   dynamics (its para_dynamics, or a design property of the controller itself,
%             e.g. Q, R, V0 of local_LQR)            equilibrium, odefcn
%   Topology (of the controller: a nested controller)  equilibrium
% Edits of other layers are not the controller's.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        a_layer        % Edited layer.
        tag string     % Kind of edit.
        log string     % Message of the edit.
    end
    if tag == "dynamics" && (a_layer == obj.para_dynamics || a_layer == obj)
        obj.mark_stale(["equilibrium","odefcn"], log);
    elseif tag == "Topology" && a_layer == obj
        obj.mark_stale("equilibrium", log);
    end
end
