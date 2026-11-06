function handle_edit(obj, a_layer, tag, log)
% Mark the stale tags of the component for its own edits (LayerPackage.log_edit).
%   dynamics (its para_dynamics)          equilibrium, odefcn
%   Topology (local controller add, replace, remove)   equilibrium
% Edits of other layers, and powerflow edits (the power flow of the network), are not
% the component's.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        a_layer        % Edited layer.
        tag string     % Kind of edit.
        log string     % Message of the edit.
    end
    if tag == "dynamics" && a_layer == obj.para_dynamics
        obj.mark_stale(["equilibrium","odefcn"], log);
    elseif tag == "Topology" && a_layer == obj
        obj.mark_stale("equilibrium", log);
    end
end
