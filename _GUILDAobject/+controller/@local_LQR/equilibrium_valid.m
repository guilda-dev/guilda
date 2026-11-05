function l = equilibrium_valid(obj)
% True when the component is in a network whose equilibrium is up to date
    arguments (Input)
        obj
    end
    arguments (Output)
        l  % True when the equilibrium of the network is up to date.
    end
    comp = obj.a_Component;
    if isempty(comp) || isempty(comp.a_Bus) || isempty(comp.a_Bus.a_PowerNetwork)
        l = false;
    else
        l = ~comp.a_Bus.a_PowerNetwork.l_staleEquilibrium;
    end
end
