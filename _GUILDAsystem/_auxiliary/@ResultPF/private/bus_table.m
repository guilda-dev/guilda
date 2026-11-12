function tab = bus_table(tab_powerflow)
% tab_bus of the result from the solution table (V, I, P, Q)
    arguments (Input)
        tab_powerflow table % V, I (complex phasors), P, Q [pu]; row names = bus tags.
    end
    arguments (Output)
        tab table           % Varg, V, P, Q, Vphasor, Iphasor; same row names.
    end
    if width(tab_powerflow) == 0
        tab = table();
        return
    end
    cv_V = tab_powerflow.V;
    tab  = table(angle(cv_V), abs(cv_V), tab_powerflow.P, tab_powerflow.Q, cv_V, tab_powerflow.I, ...
                 'VariableNames', ["Varg","V","P","Q","Vphasor","Iphasor"], ...
                 'RowNames', tab_powerflow.Properties.RowNames);
end
