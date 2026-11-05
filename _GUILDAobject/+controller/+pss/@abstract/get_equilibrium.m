function get_equilibrium(obj, V, u)
% Set the equilibrium state and input of the PSS to 0.
    arguments (Input)
        obj
        V    % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
        u    % [pu] Equilibrium input of the generator (unused).
    end
    obj.rv_Xequilibrium = 0;
    obj.rv_Uequilibrium = 0;
end
