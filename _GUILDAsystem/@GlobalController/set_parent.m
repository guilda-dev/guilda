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
        obj.reset_edit(false);   % edits made before do not belong to the new network; not initialized there yet
    end
    obj.mark_odefcn();        % the handles read the frequency of the network
end
