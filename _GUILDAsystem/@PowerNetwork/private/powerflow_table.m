function tab = powerflow_table(sv_bus, cv_V, cv_I)
% Solution of a power flow as the table of Format "powerflow(tab)".
%
% One row per bus (row names = bus tags): V and I are the complex voltage and current
% injection phasors, P and Q the real power injections into the network (S = V.*conj(I)).
    arguments (Input)
        sv_bus (:,1) string  % Bus tags.
        cv_V   (:,1) double  % [pu] Complex bus voltages.
        cv_I   (:,1) double  % [pu] Complex current injections into the network.
    end
    arguments (Output)
        tab table            % Variables V, I, P, Q [pu]; row names = bus tags.
    end
    cv_S = cv_V .* conj(cv_I);
    tab  = table(cv_V, cv_I, real(cv_S), imag(cv_S), ...
                 'VariableNames', ["V","I","P","Q"], 'RowNames', sv_bus);
end
