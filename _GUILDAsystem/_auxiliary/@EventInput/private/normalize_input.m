function [value, s_method] = normalize_input(value, sv_name, s_method, c_lbl)
% Input value as stored: a constant column, or a time series [t, v_1, ..., v_n] with its method.
%
% A table (variables Time and the input names, in any order) becomes the matrix of its
% columns in the order of sv_name. A numeric matrix, or a row of 1 + n_name values, is a
% series; any other numeric value is a constant. A series without a method takes "foh"; a
% method given for a constant stops with GUILDA:EventInput:MethodWithoutSeries. The values
% of a series are checked by the scenario (validate_disturbance).
    arguments (Input)
        value               % Constants, a time series [t, v_1, ..., v_n], or a table.
        sv_name (:,1) string     % Names of the inputs.
        s_method (1,1) string    % Interpolation given ("" for none).
        c_lbl cell               % {tag, scenario} for the messages.
    end
    arguments (Output)
        value     % Constant column or time series matrix.
        s_method  % "zoh", "foh", "spline", or "" for a constant.
    end
    n_name = numel(sv_name);
    if istable(value)
        sv_var  = string(value.Properties.VariableNames);
        sv_need = ["Time"; sv_name].';
        if ~all(ismember(sv_need, sv_var)) || ~all(ismember(sv_var, sv_need))
            error(msg("GUILDA:EventInput:InvalidInputTable", c_lbl{:}, ...
                char("the table has the variables " + join(sv_var, ", ") + ", not Time and " + join(sv_name, ", "))));
        end
        c_col = cellfun(@(s) value.(s), cellstr(sv_need), 'UniformOutput', false);
        if ~all(cellfun(@(c) isnumeric(c) && iscolumn(c), c_col))
            error(msg("GUILDA:EventInput:InvalidInputTable", c_lbl{:}, "a variable of the table is not a numeric column"));
        end
        value = double([c_col{:}]);
        l_series = true;
    else
        l_series = isnumeric(value) && ((size(value,1) > 1 && size(value,2) > 1) ...
                   || (isrow(value) && numel(value) == 1 + n_name && n_name > 0));
    end
    if l_series
        if s_method == ""
            s_method = "foh";
        end
    else
        if s_method ~= ""
            error(msg("GUILDA:EventInput:MethodWithoutSeries", c_lbl{:}, char(s_method)));
        end
        value = value(:);
    end
end
