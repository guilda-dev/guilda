function set_bus(obj,bus)
    obj.a_Bus = bus;
    obj.rebuild_odefcn_tree();    % use the frequency of the network the bus belongs to
end