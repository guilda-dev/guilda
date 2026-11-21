function picker_event(h_fig, s_event, value)
% Handle an event of the picker window of DrawerTagPicker.pick: search, selection, double click, choose or cancel.
%
% The state of the call is the appdata "sct_state" of the window: the table, the text
% searched per row, the values returned, the rows chosen (lv_selected, over all rows), the
% rows shown (iv_shown), whether the window is open for the user (l_open: pick sets it once
% the window is filled, and other events are ignored before) and, once answered, l_done and
% sv_result. The selection of the uitable
% is over the rows shown; lv_selected keeps the rows chosen that the search hides. The
% components are those of the appdata "sct_handle" (kept by pick when it made the window).
    arguments (Input)
        h_fig            % Figure of the picker.
        s_event (1,1) string  % "search", "select", "double", "ok" or "cancel".
        value            % search: the text typed; select: Selection of the uitable (rows shown); double: the row double-clicked; else [].
    end
    arguments (Output)
    end
    sct = getappdata(h_fig, "sct_state");
    if isempty(sct) || sct.l_done || (~sct.l_open && s_event ~= "search")
        return    % no call waits (a late event), or the window is still being set up
    end
    switch s_event
        case "search"
            sv_word = split(lower(strtrim(string(value))));
            sv_word = sv_word(sv_word ~= "");
            lv_shown = true(size(sct.sv_text));
            for k = 1:numel(sv_word)
                lv_shown = lv_shown & contains(sct.sv_text, sv_word(k));
            end
            sct.iv_shown = find(lv_shown);
        case "select"
            iv_row = sct.iv_shown(unique(reshape(value, [], 1)));
            if ~sct.l_multiple
                sct.lv_selected(:) = false;
            else
                sct.lv_selected(sct.iv_shown) = false;    % the rows hidden by the search stay chosen
            end
            sct.lv_selected(iv_row) = true;
        case "double"
            if sct.l_multiple || isempty(value)
                return
            end
            sct.lv_selected(:) = false;
            sct.lv_selected(sct.iv_shown(value)) = true;
            sct.l_done = true;
            sct.sv_result = reshape(sct.sv_value(sct.lv_selected), 1, []);
        case "ok"
            sct.l_done = true;
            sct.sv_result = reshape(sct.sv_value(sct.lv_selected), 1, []);
        case "cancel"
            sct.l_done = true;
            sct.sv_result = strings(1, 0);
    end
    % The state is stored before the window changes: setting the table can run a queued
    % callback (a button press), which must see the new state and not be overwritten.
    setappdata(h_fig, "sct_state", sct);
    sct_handle = getappdata(h_fig, "sct_handle");    % the table, search box and count of the window
    if s_event == "search"
        sct_handle.h_table.Data = sct.tab(sct.iv_shown, :);
        sct_handle.h_table.Selection = reshape(find(sct.lv_selected(sct.iv_shown)), 1, []);
    end
    sct_handle.h_count.Text = sprintf("%d chosen  /  %d shown  /  %d in all", ...
        nnz(sct.lv_selected), numel(sct.iv_shown), numel(sct.lv_selected));
    if sct.l_done
        uiresume(h_fig)    % no effect when pick waits in its loop (hidden window), which reads l_done
    end
end
