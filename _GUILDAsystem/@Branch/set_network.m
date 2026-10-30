function set_network(obj,a_PowerNetwork)
% Set the network of the branch; [] detaches it.
%
% Called by PowerNetwork.add_branch, remove_branch and remove_bus.
    arguments
        obj 
        a_PowerNetwork {mustBeScalarOrEmpty}   % PowerNetwork, or [] to detach.
    end
    if ~isempty(a_PowerNetwork)
        mustBeA(a_PowerNetwork, "PowerNetwork")
    end
    obj.a_PowerNetwork = a_PowerNetwork;
end
