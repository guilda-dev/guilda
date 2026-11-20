function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x) %#ok<INUSD>
% Return the equilibrium of the Static AVR: no state, and `Vfd_ref` = the equilibrium `Vfield` of the generator (read by name) and `Vpss` = 0; nothing is stored.
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
        u  % [pu] Equilibrium input of the generator, in the order of its sv_u.
        x = zeros(0,1)  % State of the component at the point (unused).
    end
    arguments (Output)
        rv_Xequilibrium  % Equilibrium state, 0x1.
        rv_Uequilibrium  % Equilibrium input `[Vfd_ref; Vpss]`.
    end
    rv_Xequilibrium = zeros(0,1);
    rv_Uequilibrium = [u(obj.a_Component.sv_u == "Vfield"); 0];    % Vpss is 0 at the equilibrium
end
