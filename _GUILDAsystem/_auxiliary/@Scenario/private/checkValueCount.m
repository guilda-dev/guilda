function checkValueCount(c_lbl, s_value, values, s_name, names)
    % One value per name, or a single value for all the names
    if isempty(names) || ~(isscalar(values) || numel(values) == numel(names))
        error(msg("GUILDA:Scenario:ValueCountMismatch", c_lbl{:}, char(s_value), ...
                string(numel(values)), string(numel(names)), char(s_name)));
    end
end
