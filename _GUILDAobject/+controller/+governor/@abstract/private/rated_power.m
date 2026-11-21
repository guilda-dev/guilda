function r_Prate = rated_power(obj)
% Prate [pu] in use: the given value, or for NaN the operation Pmax of the generator (1 if not finite and positive).
    arguments (Input)
        obj  % Governor.
    end
    arguments (Output)
        r_Prate  % [pu] Rated MW of the machine divided by the system base.
    end
    r_Prate = obj.tab_parameter.dynamics{:, 'Prate'};
    if ~isnan(r_Prate)
        return
    end
    r_Prate = 1;
    tab = obj.a_Component.tab_parameter;
    if ismember("operation", tab.Properties.VariableNames) && ismember("Pmax", tab.operation.Properties.VariableNames)
        r_Pmax = tab.operation{:, 'Pmax'};
        if isfinite(r_Pmax) && r_Pmax > 0
            r_Prate = r_Pmax;
        end
    end
end
