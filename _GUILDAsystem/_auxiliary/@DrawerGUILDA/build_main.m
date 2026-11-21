function build_main(obj)
% Draw the main layout in place of the start screen and show the model tab.
%
% Left half, from top to bottom: the info strip (Tag "info", two lines) with the toggle
% "Display options" (Tag "diagram_controls"); the diagram panel (Tag "diagram") in the first
% column of h_side, whose second column (0 px while the toggle is off) holds the control
% panel of the diagram; the header of the log with "Hide log" (Tag "log_toggle") and
% "Export script" (Tag "export"); the run log (130 px, 0 when hidden). The diagram gets all
% the height left; its panel holds a grid in which each tab draws into a panel of its own
% (redraw). Right half: one hidden uipanel per tab (Tag "tab_<key>"), all in the
% same cell; show_tab builds and shows them.
    arguments (Input)
        obj
    end
    arguments (Output)
    end
    sct_color = tools.gui_palette();
    delete(findobj(obj.h_root, "-depth", 1, "Tag", "start"))
    h_body = uigridlayout(obj.h_root, [1 2], "ColumnWidth", {"1x", "1x"}, "Padding", [8 8 8 8], ...
        "ColumnSpacing", 8, "Tag", "main", "BackgroundColor", sct_color.rv_background);
    h_body.Layout.Row = 2;

    % Left half: info strip, diagram and log
    r_log = 130;    % [px] height of the log when shown
    h_left = uigridlayout(h_body, [4 1], "RowHeight", {"fit", "1x", "fit", r_log}, "Padding", 0, ...
        "RowSpacing", 4, "BackgroundColor", sct_color.rv_background, "Tag", "left");
    h_top = uigridlayout(h_left, [1 2], "ColumnWidth", {"1x", "fit"}, "Padding", 0, ...
        "ColumnSpacing", 6, "BackgroundColor", sct_color.rv_background);
    obj.h_info = uilabel(h_top, "Text", "", "Tag", "info", "FontColor", sct_color.rv_text, ...
        "BackgroundColor", sct_color.rv_card, "WordWrap", "on");
    obj.h_toggle = uibutton(h_top, "state", "Text", "Display options", "Tag", "diagram_controls", ...
        "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_card, ...
        "Tooltip", "Show the control panel of the diagram (G.show_controls); its changes are not logged", ...
        "ValueChangedFcn", @(~, ~) obj.redraw());
    obj.h_side = uigridlayout(h_left, [1 2], "ColumnWidth", {"1x", 0}, "Padding", 0, ...
        "ColumnSpacing", 4, "BackgroundColor", sct_color.rv_background);
    obj.h_diagram = uipanel(obj.h_side, "Tag", "diagram", "BorderType", "none", ...
        "BackgroundColor", sct_color.rv_card);
    obj.h_diagram.Layout.Column = 1;
    uigridlayout(obj.h_diagram, [1 1], "Padding", 0, "BackgroundColor", sct_color.rv_card);    % the diagram panels of the tabs (redraw)
    h_head = uigridlayout(h_left, [1 3], "ColumnWidth", {"1x", "fit", "fit"}, "Padding", 0, ...
        "ColumnSpacing", 6, "BackgroundColor", sct_color.rv_background);
    uilabel(h_head, "Text", "Log", "FontWeight", "bold", "FontColor", sct_color.rv_subtext, ...
        "BackgroundColor", sct_color.rv_background);
    uibutton(h_head, "Text", "Hide log", "Tag", "log_toggle", "FontColor", sct_color.rv_text, ...
        "BackgroundColor", sct_color.rv_card, "Tooltip", "Hide or show the log; the diagram takes the space", ...
        "ButtonPushedFcn", @(src, ~) toggle_log(src, h_left, r_log));
    uibutton(h_head, "Text", "Export script", "Tag", "export", "FontColor", sct_color.rv_text, ...
        "BackgroundColor", sct_color.rv_card, "Tooltip", "Write the log as a MATLAB script", ...
        "ButtonPushedFcn", @(src, ~) export_log(obj, src));
    h_log = uigridlayout(h_left, [1 1], "Padding", 0, "BackgroundColor", sct_color.rv_background, "Tag", "log");
    obj.history.attach_view(h_log);

    % Right half: a panel per tab, built on its first show
    h_right = uigridlayout(h_body, [1 1], "Padding", 0, "BackgroundColor", sct_color.rv_background);
    for i = 1:numel(obj.sct_tab)
        h_panel = uipanel(h_right, "Tag", "tab_" + obj.sct_tab(i).s_key, "Visible", "off", ...
            "BorderType", "none", "BackgroundColor", sct_color.rv_background);
        h_panel.Layout.Row = 1;
        h_panel.Layout.Column = 1;
        obj.sct_tab(i).h_panel = h_panel;
        obj.sct_tab(i).h_button.Enable = "on";
    end
    obj.show_tab(obj.sct_tab(1).s_key);
end

function toggle_log(h_button, h_left, r_log)
% Hide the log (row height 0, the diagram grows) or show it again at r_log pixels.
    arguments (Input)
        h_button  % Button "Hide log" / "Show log".
        h_left    % Grid of the left half (the log is its row 4).
        r_log     % [px] Height of the log when shown.
    end
    arguments (Output)
    end
    l_hide = h_button.Text == "Hide log";
    h_log = findobj(h_left, "-depth", 1, "Tag", "log");
    h_log.Visible = ~l_hide;
    if l_hide
        h_left.RowHeight{4} = 0;
        h_button.Text = "Show log";
    else
        h_left.RowHeight{4} = r_log;
        h_button.Text = "Hide log";
    end
end

function export_log(obj, h_button)
% Write the script of the history: to the file chosen with uiputfile, or to tempdir on a hidden figure.
%
% The path written is kept in the UserData of the button.
    arguments (Input)
        obj       % The app.
        h_button  % Button "Export script".
    end
    arguments (Output)
    end
    if obj.h_figure.Visible && ~batchStartupOptionUsed
        [s_file, s_dir] = uiputfile("*.m", "Export script", "guilda_script.m");
        figure(obj.h_figure);
        if isequal(s_file, 0)
            return
        end
        s_path = fullfile(s_dir, s_file);
    else
        s_path = fullfile(tempdir, "guilda_app_script.m");
    end
    obj.history.export_script(s_path);
    h_button.UserData = string(s_path);
end
