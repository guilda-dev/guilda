function set_network(obj,a_PowerNetwork)
    % a_PowerNetwork = [] detaches the branch (PowerNetwork.remove_branch / remove_bus)
    arguments
        obj 
        a_PowerNetwork {mustBeScalarOrEmpty}
    end
    if ~isempty(a_PowerNetwork)
        mustBeA(a_PowerNetwork, "PowerNetwork")
    end
    obj.a_PowerNetwork = a_PowerNetwork;
end
