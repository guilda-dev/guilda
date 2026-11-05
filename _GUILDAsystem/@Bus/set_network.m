function set_network(obj, net)
% Set the network of the bus; net = [] detaches it (PowerNetwork.remove_bus).
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        net   % PowerNetwork, or [] to detach the bus.
    end
    obj.a_PowerNetwork = net;
    if ~isempty(net)
        obj.reset_edit(false);   % edits made before do not belong to the new network; not initialized there yet
    end
end
