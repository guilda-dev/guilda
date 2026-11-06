function initialize(obj, l_equilibrium)
% Bring the global controller up to date (PowerNetwork.initialize, after every
% component).
%
% Rebuilds the handles when they are stale, and computes the equilibrium
% (get_equilibrium) when it is stale or l_equilibrium is true: the equilibrium may read
% the controlled units, whose equilibria this initialize may have changed.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        l_equilibrium (1,1) logical = false  % Compute the equilibrium even when it is not stale.
    end
    if obj.odefcn_stale()
        obj.build_odefcn();
    end
    if l_equilibrium || ~isempty(obj.sct_stale.equilibrium)
        [obj.rv_Xequilibrium, obj.rv_Uequilibrium] = obj.get_equilibrium();
        obj.clear_stale("equilibrium");
    end
end
