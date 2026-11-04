function set_bus(obj,bus)
% Set the bus of the component; [] detaches it.
%
% Called by Bus.add_component, replace_component and remove_component.
%
% <@Group> Construction and editing
    obj.a_Bus = bus;
    obj.mark_odefcn();    % the handles read the frequency of the network the bus belongs to
end