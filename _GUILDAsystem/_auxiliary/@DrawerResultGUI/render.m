function render(obj)
% Draw the GUI in the container: header, method list and view area, then the default view.
%
% Only the grid drawn before (Tag "DrawerResultGUI") is replaced, so an app may keep other
% components in the container. The method list is read from both functionSignatures.json
% files (read_signatures): the entries "<class>_<method>" (as jsondecode names them) of the
% class of the result and of its superclasses, the nearest class first, with the prefixes
% plot_, disp_, get_ and the method export. Each button shows a readable label (e.g.
% "Voltage" for plot_voltage, "LMP" for get_lmp) under the heading of its group, and the
% method in its tooltip.
%
% The default view is drawn without logging (it changes no variable of the history): the
% Text tab shows the summary of the result (disp_summary when the class has it, else the
% display of the object), and the Plot tab the first plot_* method of the list called with
% its defaults (Parent = the plot panel). The Plot tab is selected when that plot is drawn,
% the Text tab otherwise. The Log tab gets the view of the log (HistoryGUILDA.attach_view)
% when it is first opened (show_log), not here. The frame is drawn before the default view,
% so the window is usable while the first plot is drawn. A first plot that animates starts
% playing (autoplay).
    arguments (Input)
        obj
    end
    arguments (Output)
    end
    h_old = obj.h_container.Children;
    h_old = h_old(arrayfun(@(c) isprop(c, "Tag") && c.Tag == "DrawerResultGUI", h_old));
    h_layout = [];
    if ~isempty(h_old)
        h_layout = h_old(1).Layout;
        delete(h_old)
    end
    sct_color = tools.gui_palette();
    a_target  = obj.a_target;
    s_class   = string(class(a_target));
    h_grid = uigridlayout(obj.h_container, [2 2], "RowHeight", {"fit", "1x"}, "ColumnWidth", {190, "1x"}, ...
        "Padding", [0 0 0 0], "RowSpacing", 0, "ColumnSpacing", 0, "Tag", "DrawerResultGUI", ...
        "BackgroundColor", sct_color.rv_background);
    if isa(h_layout, "matlab.ui.layout.GridLayoutOptions")
        h_grid.Layout = h_layout;
    end

    % Header: variable, class, success state, Docs and Display options, then the summary line, over a lime line
    h_header = uigridlayout(h_grid, [2 1], "RowHeight", {"fit", 3}, "Padding", [0 0 0 0], ...
        "RowSpacing", 0, "BackgroundColor", sct_color.rv_lime);
    h_header.Layout.Row    = 1;
    h_header.Layout.Column = [1 2];
    h_band = uigridlayout(h_header, [2 1], "RowHeight", {"fit", "fit"}, "Padding", [10 6 10 6], ...
        "RowSpacing", 2, "BackgroundColor", sct_color.rv_blue);
    h_info = uigridlayout(h_band, [1 6], "ColumnWidth", {"fit", "fit", "fit", "fit", "1x", "fit"}, "Padding", [0 0 0 0], ...
        "ColumnSpacing", 10, "BackgroundColor", sct_color.rv_blue);
    uilabel(h_info, "Text", obj.s_variable, "FontSize", 16, "FontWeight", "bold", ...
        "FontColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue);
    uilabel(h_info, "Text", s_class, "FontColor", sct_color.rv_header_subtext, ...
        "BackgroundColor", sct_color.rv_blue);
    if a_target.l_success
        uilabel(h_info, "Text", " success ", "Tag", "status", "FontWeight", "bold", ...
            "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_lime);
    else
        uilabel(h_info, "Text", " failed ", "Tag", "status", "FontWeight", "bold", ...
            "FontColor", sct_color.rv_stale_text, "BackgroundColor", sct_color.rv_stale_back);
    end
    uibutton(h_info, "Text", "Docs", "Tag", "docs", "Tooltip", "Open the reference page of " + s_class, ...
        "FontWeight", "bold", "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_card, ...
        "ButtonPushedFcn", @(~, ~) GUILDA.doc("class", s_class));
    h_toggle = uibutton(h_info, "state", "Text", "Display options", "Tag", "controls", ...
        "Tooltip", "Show the control panel of the plot (G.show_controls); its changes are not logged", ...
        "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_card, ...
        "ValueChangedFcn", @(~, ~) obj.show_plot_controls());
    h_toggle.Layout.Column = 6;
    s_flag = strjoin(string(a_target.flag(:).'), " ");
    s_summary = "network " + a_target.s_network + "  ·  solver " + a_target.s_solver ...
        + "  ·  flag " + s_flag + "  ·  " + sprintf("%.3g s", a_target.r_elapsed);
    uilabel(h_band, "Text", s_summary, "Tag", "summary", "FontColor", sct_color.rv_header_subtext, ...
        "BackgroundColor", sct_color.rv_blue);

    % Method list: the signed methods of the class and its superclasses, by group
    sv_key = string(fieldnames(read_signatures()));
    sv_method   = strings(0, 1);
    sv_signature = strings(0, 1);
    for s_owner = [s_class; string(superclasses(a_target))].'
        sv_name = extractAfter(sv_key(startsWith(sv_key, s_owner + "_")), s_owner + "_");
        sv_name = sv_name(~ismember(sv_name, sv_method) ...
            & (startsWith(sv_name, ["plot_", "disp_", "get_"]) | sv_name == "export"));
        sv_method    = [sv_method; sv_name];                      %#ok<AGROW>
        sv_signature = [sv_signature; s_owner + "." + sv_name];   %#ok<AGROW>
    end
    sm_group = ["Plot", "plot_"; "Display", "disp_"; "Get", "get_"; "Export", "export"];
    sm_word = ["lmp", "LMP"; "pv", "PV"; "pvcurve", "PV curve"; "ode", "ODE"; "ss", "State-space model"; ...
        "opf", "OPF"; "pf", "PF"; "cpf", "CPF"; "eigenvalue", "Eigenvalues"; "export", "Export to file"];
    h_list = uigridlayout(h_grid, [1 1], "Scrollable", "on", "Padding", [8 8 8 8], "RowSpacing", 4, ...
        "BackgroundColor", sct_color.rv_background, "Tag", "methods");
    h_list.Layout.Row    = 2;
    h_list.Layout.Column = 1;
    n_row = 0;
    for i = 1:size(sm_group, 1)
        lv = startsWith(sv_method, sm_group(i, 2));
        if ~any(lv)
            continue
        end
        n_row = n_row + 1;
        h = uilabel(h_list, "Text", sm_group(i, 1), "Tag", "group", "FontWeight", "bold", ...
            "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_background);
        h.Layout.Row = n_row;
        for k = reshape(find(lv), 1, [])
            n_row = n_row + 1;
            s_sig = sv_signature(k);
            % Readable label: the words after the prefix, the first one capitalized, known abbreviations in capitals
            sv_word = split(regexprep(sv_method(k), "^(plot|disp|get)_", ""), "_").';
            [l_known, iv_word] = ismember(sv_word, sm_word(:, 1));
            sv_word(l_known) = sm_word(iv_word(l_known), 2);
            s_label = join(sv_word, " ");
            s_label = upper(extractBefore(s_label, 2)) + extractAfter(s_label, 1);
            h = uibutton(h_list, "Text", s_label, "Tag", "method", "UserData", s_sig, ...
                "Tooltip", s_sig, "HorizontalAlignment", "left", "FontColor", sct_color.rv_text, ...
                "BackgroundColor", sct_color.rv_card, "ButtonPushedFcn", @(~, ~) obj.run_method(s_sig));
            h.Layout.Row = n_row;
        end
    end
    h_list.RowHeight = repmat({"fit"}, 1, max(n_row, 1));

    % View area: plot panel (with the column of the control panel), text and log
    obj.h_tabs = uitabgroup(h_grid, "Tag", "view");
    obj.h_tabs.Layout.Row    = 2;
    obj.h_tabs.Layout.Column = 2;
    h_tab = uitab(obj.h_tabs, "Title", "Plot", "Tag", "plot", "BackgroundColor", sct_color.rv_card);
    h_plotGrid = uigridlayout(h_tab, [1 2], "ColumnWidth", {"1x", 0}, "Padding", 0, "ColumnSpacing", 4, ...
        "BackgroundColor", sct_color.rv_card, "Tag", "plot_grid");
    obj.h_plot = uipanel(h_plotGrid, "BorderType", "none", "Tag", "plot", "BackgroundColor", [1 1 1]);
    obj.h_plot.Layout.Column = 1;
    h_tab = uitab(obj.h_tabs, "Title", "Text", "Tag", "text", "BackgroundColor", sct_color.rv_card);
    obj.h_text = uitextarea(uigridlayout(h_tab, [1 1], "Padding", 4, "BackgroundColor", sct_color.rv_card), ...
        "Editable", "off", "Tag", "text", "FontName", char(get(groot, "FixedWidthFontName")), ...
        "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_card);
    uitab(obj.h_tabs, "Title", "Log", "Tag", "log", "BackgroundColor", sct_color.rv_card);
    obj.h_tabs.SelectionChangedFcn = @(~, evt) obj.show_log(evt.NewValue);    % the view of the log when the tab is first opened

    % The frame is drawn now, so the buttons can be used while the default view below is drawn
    drawnow

    % Default view, not logged: the summary text and the first plot
    try
        if ismember("disp_summary", sv_method)
            s_text = "";
            evalc("s_text = a_target.disp_summary();");
            sv_text = regexprep(string(s_text(:)), "<a\s[^>]*>|</a>", "");
        else
            sv_text = string(formattedDisplayText(a_target, "SuppressMarkup", true));
        end
        obj.h_text.Value = splitlines(join(sv_text, newline));
    catch ME
        obj.h_text.Value = "No summary: " + string(ME.message);
    end
    obj.h_tabs.SelectedTab = obj.h_text.Parent.Parent;
    obj.G_plot = [];
    s_first = sv_method(find(startsWith(sv_method, "plot_"), 1));
    if ~isempty(s_first)
        try
            G = [];
            evalc("G = a_target.(s_first)(Parent=obj.h_plot);");
            if isa(G, "GraphBase")
                obj.G_plot = G;
            end
            obj.h_tabs.SelectedTab = obj.h_plot.Parent.Parent;
        catch    % a plot that needs more than its defaults: the summary stays in front
            delete(obj.h_plot.Children)
        end
    end
    obj.autoplay();
end
