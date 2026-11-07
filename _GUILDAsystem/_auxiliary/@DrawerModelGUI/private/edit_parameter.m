function edit_parameter(h_table, a_para, a_target, h_stale)
% Write the edited table to tab_parameter of its container; restore it on an error.
%
% Parameter.set.tab_parameter checks, logs and marks what is stale; nothing else is done here.
    arguments (Input)
        h_table   % Edited uitable.
        a_para    % Parameter container of the table.
        a_target  % Model shown.
        h_stale   % Label of the stale state.
    end
    arguments (Output)
    end
    try
        a_para.tab_parameter = h_table.Data;
    catch ME
        h_table.Data = a_para.tab_parameter;
        show_alert(h_table, ME.message, "Parameter " + string(a_para.s_tag));
        return
    end
    update_stale(h_stale, a_target);
end
