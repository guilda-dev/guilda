function get_equilibrium(obj, V, u)      
% Set the equilibrium state and input of the AVR and of its PSS.
% The base AVR stores the field voltage `u(2)` as its equilibrium state.
    arguments (Input)
        obj
        V    % [pu] Complex terminal voltage of the generator at the equilibrium.
        u    % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
    end
    obj.rv_Xequilibrium = u(2);
    obj.rv_Uequilibrium = [];
    cellfun(@(c) c.get_equilibrium(V,u), obj.a_LocalController);
end
