function get_equilibrium(obj, V, u)
% Set the equilibrium state and the inputs Pref (65M) and Plimit (77M).
% The turbine output is `Pmech/Prate` of the generator's equilibrium; the servo
% position follows from it (`Pt = (Kw + Kv)*Psv` at a steady state), and PLM
% sets Pref and Plimit (see controller.governor.abstract). An error is raised
% when the servo position is outside `[pos_min, pos_max]`.
    arguments (Input)
        obj
        V    % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
        u    % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
    end
    tab = obj.tab_parameter.dynamics;
    r_gain = tab{:,'Kw'} + tab{:,'Kv'};
    r_P0   = obj.initial_output(u);
    r_pos0 = r_P0 / r_gain;
    if ~(r_pos0 >= tab{:,'pos_min'} && r_pos0 <= tab{:,'pos_max'})
        error(msg("GUILDA:IEEJ_LPT4:OutputOutOfRange", char(obj.s_tag), num2str(r_P0), num2str(tab{:,'Prate'}), ...
                  num2str(r_pos0), num2str(tab{:,'pos_min'}), num2str(tab{:,'pos_max'})))
    end
    [r_Pref, r_Plimit] = obj.load_setting(r_pos0, tab{:,'PLM'}, r_gain, tab{:,'pos_max'});

    obj.rv_Xequilibrium = [0; 0; r_pos0; r_pos0];
    obj.rv_Uequilibrium = [0; r_Pref; r_Plimit];
end
