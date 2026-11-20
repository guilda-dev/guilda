function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x) %#ok<INUSD>
% Return the equilibrium state and input of the PSS: 0 (nothing is stored).
% An error is raised when a lead-lag block has `td = 0` and `tn ~= 0` (an improper block).
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
        u  % [pu] Equilibrium input of the generator (unused).
        x = zeros(0,1)  % State of the component at the point (unused).
    end
    arguments (Output)
        rv_Xequilibrium  % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium  % Equilibrium input in the order of `sv_u`.
    end
    % A lead-lag block with td = 0 and tn ~= 0 is improper (1 + tn*s) and has no state equation
    tab = obj.tab_parameter.dynamics;
    for k = 1:2
        tn = tab{:, "tn"+k};
        td = tab{:, "td"+k};
        if td == 0 && tn ~= 0
            error(msg("GUILDA:PSS1:ImproperLeadLag", char(obj.s_tag), "td"+k, "tn"+k, num2str(tn)))
        end
    end
    rv_Xequilibrium = zeros(3,1);
    rv_Uequilibrium = 0;
end
