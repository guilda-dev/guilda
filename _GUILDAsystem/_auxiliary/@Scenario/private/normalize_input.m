function d = normalize_input(d, s_scenario)
% Input value as stored: a constant column, or a time series [t, v_1, ..., v_n] with its method.
%
% A table (variables Time and the input names, in any order) becomes the matrix of its
% columns in the order of InputName. A numeric matrix, or a row of 1 + n_name values, is a
% series; any other numeric value is a constant. A series without InputMethod takes "foh";
% InputMethod given for a constant stops with GUILDA:Scenario:MethodWithoutSeries. The
% values of a series are checked by validate_disturbance.
    arguments (Input)
        d           % Disturbance record (struct with the fields of add_disturbance).
        s_scenario  % Tag of the scenario (for the messages).
    end
    arguments (Output)
        d           % The record with InputValue and InputMethod as stored.
    end
    c_lbl = {char(d.Tag), char(s_scenario)};
    v = d.InputValue;
    n_name = numel(d.InputName);
    if istable(v)
        sv_var  = string(v.Properties.VariableNames);
        sv_need = ["Time"; d.InputName(:)].';
        if ~all(ismember(sv_need, sv_var)) || ~all(ismember(sv_var, sv_need))
            error(msg("GUILDA:Scenario:InvalidInputSeries", c_lbl{:}, ...
                char("the table has the variables " + join(sv_var, ", ") + ", not Time and " + join(d.InputName, ", "))));
        end
        c_col = cellfun(@(s) v.(s), cellstr(sv_need), 'UniformOutput', false);
        if ~all(cellfun(@(c) isnumeric(c) && iscolumn(c), c_col))
            error(msg("GUILDA:Scenario:InvalidInputSeries", c_lbl{:}, "a variable of the table is not a numeric column"));
        end
        v = double([c_col{:}]);
        l_series = true;
    else
        l_series = isnumeric(v) && ((size(v,1) > 1 && size(v,2) > 1) || (isrow(v) && numel(v) == 1 + n_name && n_name > 0));
    end
    if l_series
        if d.InputMethod == ""
            d.InputMethod = "foh";
        end
    else
        if d.InputMethod ~= ""
            error(msg("GUILDA:Scenario:MethodWithoutSeries", c_lbl{:}, char(d.InputMethod)));
        end
        v = v(:);
    end
    d.InputValue = v;
end
