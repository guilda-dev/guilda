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
        obj.reset_edit(false);   % edits made before do not belong to the new parent; not initialized there yet
    end
    obj.resolve_observe();        % inputs read on the component (also of nested controllers)
    obj.mark_odefcn();        % the handles read the frequency of the parent's network
end
