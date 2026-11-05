function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj)
% Return the equilibrium of the AGC: zero integrator state and zero frequency deviations.
    arguments (Input)
        obj
    end
    arguments (Output)
        rv_Xequilibrium % [pu*s] Equilibrium integrator state (0).
        rv_Uequilibrium % [pu] Equilibrium frequency deviations (0), one per controlled generator.
    end
    nCU = numel(obj.controlledUnits);
    rv_Xequilibrium = 0;
    rv_Uequilibrium = zeros(nCU,1);
end
