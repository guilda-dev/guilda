function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x) %#ok<INUSD>
% Return the equilibrium state and the inputs Pref (65M) and Plimit (77M); nothing is stored.
% The servo position is the turbine output `Pmech/Prate` of the generator's
% equilibrium, and PLM sets Pref and Plimit (see controller.governor.abstract).
% An error is raised when it is outside `[pos_min, pos_max]`.
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
        u  % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
        x = zeros(0,1)  % State of the component at the point (unused).
    end
    arguments (Output)
        rv_Xequilibrium  % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium  % Equilibrium input in the order of `sv_u`.
    end
    tab = obj.tab_parameter.dynamics;
    [r_P0, r_Prate] = obj.initial_output(u);
    if ~(r_P0 >= tab{:,'pos_min'} && r_P0 <= tab{:,'pos_max'})
        error(msg("GUILDA:IEEJ_LPT3:OutputOutOfRange", char(obj.s_tag), num2str(r_P0), num2str(r_Prate), ...
                  num2str(tab{:,'pos_min'}), num2str(tab{:,'pos_max'})))
    end
    [r_Pref, r_Plimit] = obj.load_setting(r_P0, tab{:,'PLM'}, 1, tab{:,'pos_max'});

    rv_Xequilibrium = [0; r_P0];
    rv_Uequilibrium = [0; r_Pref; r_Plimit];
end
