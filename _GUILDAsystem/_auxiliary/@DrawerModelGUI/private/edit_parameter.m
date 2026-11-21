function l_restore = edit_parameter(h_body, sct_edit, a_target, h_stale, s_expr, f_run)
% Write an edited cell of the Parameter tab as code through the history; restore the body on an error.
%
% The cell (sct_edit from model_body.html: index of the container in a_Parameter, var,
% row and value, a text or a logical) is put into a copy of the table of the container:
% a number column takes the text as a number (several numbers for a row vector, "NaN" for
% NaN), a logical column true or false, a string column the text. Each changed variable is
% one line on tab_parameter of the model, e.g. `net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;`
% (a row index `(2)` in a table of several rows). Parameter.set.tab_parameter checks, logs
% and marks what is stale. On an error, or a text that is not a value of the column, an
% alert shows the message and l_restore asks the caller to send the stored values again.
    arguments (Input)
        h_body    % uihtml of the body (for the alert).
        sct_edit  % Edit sent by the page: fields index, var, row and value.
        a_target  % Model shown.
        h_stale   % Label of the stale state.
        s_expr (1,1) string  % Expression of the model shown.
        f_run     % run_code of the GUI.
    end
    arguments (Output)
        l_restore (1,1) logical  % True when the body must show the stored values again (an error).
    end
    l_restore = false;
    i_para = double(sct_edit.index);
    a_para = a_target.a_Parameter{i_para};
    s_tag   = string(a_para.s_tag);
    s_label = "Parameter " + s_tag + " of " + string(a_target.s_tag);
    tab_old = a_para.tab_parameter;
    s_var = string(sct_edit.var);
    i_row = double(sct_edit.row);
    if height(tab_old) == 1
        i_row = 1;    % a vertical table: one row per parameter of the one row
    end
    value = sct_edit.value;
    try
        old = tab_old.(s_var);
        if islogical(old)
            if ~islogical(value)
                value = any(strcmpi(strtrim(string(value)), ["true", "1"]));
            end
        elseif isnumeric(old)
            s_text = strtrim(erase(string(value), ["[", "]", ","]));
            value = str2double(split(s_text, whitespacePattern)).';
            if s_text == "" || any(isnan(value) & ~strcmpi(split(s_text, whitespacePattern).', "NaN")) || numel(value) ~= size(old, 2)
                error(msg("GUILDA:DrawerModelGUI:NotANumber", string(sct_edit.value), s_var))
            end
            if ~isreal(old) || ~isa(old, "double")
                value = cast(value, "like", old);
            end
        else
            value = string(value);
        end
        tab_new = tab_old;
        tab_new.(s_var)(i_row, :) = value;
    catch ME    % a value the variable cannot hold
        l_restore = true;
        show_alert(h_body, string(ME.message), s_label);
        return
    end
    new = tab_new.(s_var);
    if isequaln(new, old)
        return
    end
    s_lhs = s_expr + ".tab_parameter." + s_tag + "." + s_var;
    if height(tab_new) > 1
        s_col = "";
        if size(new, 2) > 1
            s_col = ",:";
        end
        s_code = s_lhs + "(" + i_row + s_col + ") = " + mat2str(new(i_row, :)) + ";";
    else
        s_code = s_lhs + " = " + mat2str(new) + ";";
    end
    if ~f_run(s_label, s_code, "Render", false)
        l_restore = true;
        return
    end
    update_stale(h_stale, a_target);
end
