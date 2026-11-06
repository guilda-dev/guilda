function handle_edit(obj, a_layer, tag, log)
% Mark the stale tags of the component for its own edits (LayerPackage.log_edit).
%   dynamics (its para_dynamics)                       equilibrium, odefcn
%   Topology (local controller add, replace, remove)   equilibrium
% Edits of other layers, and powerflow edits (the power flow of the network), are not
% the component's.
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
