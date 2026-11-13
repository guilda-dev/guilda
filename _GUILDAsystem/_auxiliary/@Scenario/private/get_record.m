function d = get_record(tab, k)
% Record of row k of tab_offset or tab_input (the fields of add_disturbance; the others blank)
    arguments (Input)
        tab table           % tab_offset or tab_input.
        k   (1,1) double    % Row.
    end
    arguments (Output)
        d (1,1) struct      % Record (see blank_record).
    end
    d = blank_record(tab.Tag(k), tab.TimeSpan(k,:));
    for s_var = string(tab.Properties.VariableNames(3:end))
        x = tab.(s_var)(k);
        if iscell(x)
            x = x{1};
        end
        d.(s_var) = x;
    end
end
