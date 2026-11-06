function set_parent(obj,a_Component)
% Set the parent of the controller; a_Component = [] detaches it (Component.add_local_controller).
%
% <@Group> Construction and attachment
    arguments (Input)
        obj
        a_Component   % Component, the AVR for a PSS, or [] to detach.
    end
    obj.a_Component = a_Component;
    if ~isempty(a_Component)
        % the equilibrium follows the new parent, and the network frequency may differ
        s_log = obj.s_tag + ": attached to " + a_Component.s_tag;
        obj.sct_stale.equilibrium(end+1,1) = s_log;
        obj.sct_stale.odefcn(end+1,1)      = s_log;
    end
    obj.resolve_observe();        % inputs read on the component (also of nested controllers)
end
