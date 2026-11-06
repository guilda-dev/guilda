function set_parent(obj,net)
% Set the network of the controller; net = [] detaches it (PowerNetwork.remove_global_controller).
%
% <@Group> Construction and attachment
    arguments (Input)
        obj
        net   % PowerNetwork, or [] to detach the controller.
    end
    obj.a_PowerNetwork = net;
    if ~isempty(net)
        % the network frequency may differ
        obj.mark_stale(["equilibrium","odefcn"], obj.s_tag + ": attached to " + net.s_tag);
    end
end
