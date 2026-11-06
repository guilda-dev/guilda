function handle_edit(obj, a_layer, tag, log)
% Mark the stale tags of the global controller for its own edits (LayerPackage.log_edit).
%   dynamics (its para_dynamics, or a property of the controller itself)   equilibrium, odefcn
%   Topology (of the controller: its addition to the network)           equilibrium
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
