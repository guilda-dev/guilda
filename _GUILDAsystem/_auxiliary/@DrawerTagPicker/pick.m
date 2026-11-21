function sv_tag = pick(h_parent_figure, tab, opt)
% Show a table in a modal picker window with a search box and return the values chosen; strings(1,0) on cancel.
%
% The window shows tab in a uitable, one row per element, under a search box that filters
% the rows as the user types (every word, case-insensitive, over all the columns). Select
% (Tag "picker_ok") returns the values of the column Column of the chosen rows, in the order
% of tab; Cancel (Tag "picker_cancel") or closing the window returns strings(1,0). In single mode a double
% click on a row chooses it at once. With Multiple=true the rows chosen stay chosen while the
% search hides them. Selected preselects the rows whose Column value is in it (values that
% are not in the table are ignored).
%
% One hidden window is kept per parent figure (one more for no parent) and reused: a call
% only swaps the data, title and mode, so the second opening is fast. The window is created
% again when it was deleted, and is deleted with its parent figure.
%
% A visible window waits for the user (uiwait). A hidden window (hidden parent) or one in
% `matlab -batch` has no user: it waits at most 10 s for a program (a test) to press its
% buttons and then returns strings(1,0) as a cancel, so it never blocks indefinitely.
%
% <@Examples>
% ```matlab
% net = network.IEEE68bus();
% fig = uifigure();
% sv_tag = DrawerTagPicker.pick(fig, DrawerTagPicker.element_table(net, "Component"), Title="Component")
% sv_tag = DrawerTagPicker.pick(fig, DrawerTagPicker.element_table(net, "Bus"), Multiple=true, Selected="B001")
% s_key = DrawerTagPicker.pick(fig, DrawerTagPicker.key_table("Component"), Column="Key")
% ```
%
% See also DrawerTagPicker.element_table, DrawerTagPicker.key_table, DrawerOptionDialog.ask
    arguments (Input)
        h_parent_figure                    % uifigure the window belongs to, or [] for none.
        tab table                          % Rows to choose from, e.g. DrawerTagPicker.element_table(net, "Bus").
        opt.Multiple (1,1) logical = false % Whether several rows can be chosen.
        opt.Selected (1,:) string = strings(1,0)  % Values of Column chosen when the window opens.
        opt.Title    (1,1) string = "Select"  % Title of the window.
        opt.Column   (1,1) string = "Tag"  % Column whose values are returned ("Key" for a key table).
    end
    arguments (Output)
        sv_tag (1,:) string  % Values of Column of the chosen rows, in the order of tab; strings(1,0) on cancel.
    end
    if ~ismember(opt.Column, string(tab.Properties.VariableNames))
        error(msg("GUILDA:DrawerTagPicker:NoColumn", opt.Column, join(string(tab.Properties.VariableNames), ", ")))
    end

    % The window of the parent: reused while it exists
    h_fig = [];
    if isempty(h_parent_figure)
        h_fig = findall(groot, "Type", "figure", "Tag", "DrawerTagPicker_none");
    elseif isappdata(h_parent_figure, "DrawerTagPicker")
        h_fig = getappdata(h_parent_figure, "DrawerTagPicker");
    end
    if isempty(h_fig) || ~isvalid(h_fig(1))
        sct_color = tools.gui_palette();
        h_fig = uifigure("Visible", "off", "WindowStyle", "modal", "Tag", "DrawerTagPicker", ...
            "Color", sct_color.rv_background, "Position", [100 100 720 520]);
        if isprop(h_fig, "Theme")
            h_fig.Theme = "light";
        end
        h_grid = uigridlayout(h_fig, [3 1], "RowHeight", {"fit", "1x", "fit"}, "BackgroundColor", sct_color.rv_background);
        h_search = uieditfield(h_grid, "Tag", "picker_search", "Placeholder", "Search: tag, bus, class... (words separated by spaces)", ...
            "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text, ...
            "ValueChangingFcn", @(h, evt) picker_event(h_fig, "search", evt.Value));
        h_table = uitable(h_grid, "Tag", "picker_table", "SelectionType", "row", "RowStriping", "on", ...
            "BackgroundColor", [sct_color.rv_card; sct_color.rv_stripe], "ForegroundColor", sct_color.rv_text, ...
            "SelectionChangedFcn", @(h, ~) picker_event(h_fig, "select", h.Selection), ...
            "DoubleClickedFcn", @(~, evt) picker_event(h_fig, "double", evt.InteractionInformation.Row));
        h_button = uigridlayout(h_grid, [1 3], "ColumnWidth", {"1x", 100, 100}, "Padding", 0, ...
            "BackgroundColor", sct_color.rv_background);
        h_count = uilabel(h_button, "Tag", "picker_count", "Text", "", "FontColor", sct_color.rv_subtext);
        setappdata(h_fig, "sct_handle", struct("h_search", h_search, "h_table", h_table, "h_count", h_count));
        uibutton(h_button, "Tag", "picker_ok", "Text", "Select", "BackgroundColor", sct_color.rv_blue, ...
            "FontColor", sct_color.rv_header_text, "ButtonPushedFcn", @(~, ~) picker_event(h_fig, "ok", []));
        uibutton(h_button, "Tag", "picker_cancel", "Text", "Cancel", "BackgroundColor", sct_color.rv_card, ...
            "FontColor", sct_color.rv_text, "ButtonPushedFcn", @(~, ~) picker_event(h_fig, "cancel", []));
        h_fig.CloseRequestFcn = @(~, ~) picker_event(h_fig, "cancel", []);
        if isempty(h_parent_figure)
            h_fig.Tag = "DrawerTagPicker_none";
        else
            setappdata(h_parent_figure, "DrawerTagPicker", h_fig);
            addlistener(h_parent_figure, "ObjectBeingDestroyed", @(~, ~) delete(h_fig(isvalid(h_fig))));
        end
    end
    h_fig = h_fig(1);

    % New data: the text searched is built once per call, one string per row
    n_row = height(tab);
    sv_text = strings(n_row, 1);
    if n_row > 0
        sm_cell = strings(n_row, width(tab));
        for k = 1:width(tab)
            sm_cell(:, k) = string(tab{:, k});
        end
        sv_text = lower(join(sm_cell, " ", 2));
    end
    sv_value = string(tab.(opt.Column));
    lv_selected = ismember(sv_value, opt.Selected);
    if ~opt.Multiple
        i_first = find(lv_selected, 1);    % one row at most
        lv_selected(:) = false;
        lv_selected(i_first) = true;
    end
    setappdata(h_fig, "sct_state", struct("tab", tab, "sv_text", sv_text, "sv_value", sv_value, ...
        "lv_selected", lv_selected, "iv_shown", (1:n_row)', "l_multiple", opt.Multiple, "l_open", false, "l_done", false, "sv_result", strings(1, 0)));
    h_fig.Name = opt.Title;
    sct_handle = getappdata(h_fig, "sct_handle");    % the components of the window (no search per call)
    if sct_handle.h_table.Multiselect ~= opt.Multiple
        sct_handle.h_table.Multiselect = opt.Multiple;
    end
    sct_handle.h_search.Value = "";
    picker_event(h_fig, "search", "");    % shows all rows, the selection and the count

    l_visible = true;
    if ~isempty(h_parent_figure)
        rv_pos = h_parent_figure.Position;
        h_fig.Position(1:2) = rv_pos(1:2) + (rv_pos(3:4) - h_fig.Position(3:4)) / 2;
        l_visible = logical(h_parent_figure.Visible);
    end
    h_fig.Visible = l_visible;
    sct = getappdata(h_fig, "sct_state");    % open for the user: the events before were set-up only
    sct.l_open = true;
    setappdata(h_fig, "sct_state", sct);
    if l_visible && ~batchStartupOptionUsed
        uiwait(h_fig)    % a user answers
    else
        % Nobody can answer a hidden window: wait at most 10 s for a program to press a button
        % (pause runs the callbacks and timers), then cancel. drawnow first flushes the graphics
        % queue (see DrawerOptionDialog.ask).
        t_start = tic;
        while isvalid(h_fig) && ~getappdata(h_fig, "sct_state").l_done && toc(t_start) < 10
            drawnow
            pause(0.05)
        end
    end
    sv_tag = strings(1, 0);
    if isvalid(h_fig)
        sv_tag = getappdata(h_fig, "sct_state").sv_result;    % strings(1,0) unless Select was pressed
        h_fig.Visible = "off";
        setappdata(h_fig, "sct_state", []);    % the window keeps no data of the call
    end
end
