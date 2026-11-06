function set_bus(obj,bus)
% Set the bus of the component; [] detaches it.
%
% Called by Bus.add_component, replace_component and remove_component.
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        bus   % Bus of the component, or [] to detach it.
    end
    obj.a_Bus = bus;
    if ~isempty(bus)
        obj.reset_edit(false);   % edits made before do not belong to the new network; not initialized there yet
    end
end