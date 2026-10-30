function set_bus(obj,bus)
% Set the bus of the component; [] detaches it.
%
% Called by Bus.add_component, replace_component and remove_component.
    obj.a_Bus = bus;
    obj.rebuild_odefcn_tree();    % use the frequency of the network the bus belongs to
end