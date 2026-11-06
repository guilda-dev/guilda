function set_network(obj, net)
% Set the network of the bus; net = [] detaches it (PowerNetwork.remove_bus).
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        net   % PowerNetwork, or [] to detach the bus.
    end
    obj.a_PowerNetwork = net;
end
