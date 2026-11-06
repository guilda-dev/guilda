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
        s_log = obj.s_tag + ": attached to " + net.s_tag;
        obj.sct_stale.equilibrium(end+1,1) = s_log;
        obj.sct_stale.odefcn(end+1,1)      = s_log;
    end
end
