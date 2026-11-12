function tab = powerflow_table(sv_bus, rm_pf)
% Solution of a power flow as the table of Format "powerflow(tab)".
%
% The columns of the "powerflow(mat)" array as table variables: V and I complex, P and Q
% real; row names = bus tags.
    arguments (Input)
        sv_bus (:,1) string  % Bus tags (row order of rm_pf).
        rm_pf  (:,4) double  % [pu] Columns V, I, P, Q (powerflow_matrix).
    end
    arguments (Output)
        tab table            % Variables V, I, P, Q [pu]; row names = bus tags.
    end
    tab = table(rm_pf(:,1), rm_pf(:,2), real(rm_pf(:,3)), real(rm_pf(:,4)), ...
                'VariableNames', ["V","I","P","Q"], 'RowNames', sv_bus);
end
