function initialize(obj, l_equilibrium)
% Bring the global controller up to date (PowerNetwork.initialize, after every
% component).
%
% Rebuilds the handles when they are stale (the stale tag odefcn, or a network frequency
% other than r_odefcnHz), and computes the equilibrium
% (get_equilibrium) and stores it when it is stale or l_equilibrium is true (the
% equilibria of the controlled units may have changed in this initialize).
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        l_equilibrium (1,1) logical = false  % Compute the equilibrium even when it is not stale.
    end
    obj.set_odefcn();
    if l_equilibrium || ~isempty(obj.sct_stale.equilibrium)
        [obj.rv_Xequilibrium, obj.rv_Uequilibrium] = obj.get_equilibrium();
        obj.sct_stale.equilibrium = strings(0,1);
    end
end
