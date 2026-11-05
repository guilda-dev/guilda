function set_network(obj,a_PowerNetwork)
% Set the network of the branch; [] detaches it.
%
% Called by PowerNetwork.add_branch, remove_branch and remove_bus.
%
% <@Group> Construction and editing
    arguments (Input)
        obj 
        a_PowerNetwork {mustBeScalarOrEmpty}   % PowerNetwork, or [] to detach.
    end
    if ~isempty(a_PowerNetwork)
        mustBeA(a_PowerNetwork, "PowerNetwork")
    end
    obj.a_PowerNetwork = a_PowerNetwork;
    if ~isempty(a_PowerNetwork)
        obj.reset_edit(false);   % edits made before do not belong to the new network; not initialized there yet
    end
end
