function sct_hook = tab_analysis_panel(h_panel, sct_app, sct_spec)
% Panel of an analysis tab: Run, Analyze result and the status of the last run over the option form of its method.
%
% The analysis tabs (pf, opf, cpf, lin) call it from their build functions. From top to bottom:
%
% - the stale banner (sct_spec.l_banner; tabs that need the equilibrium),
% - the title of the tab,
% - the buttons Run (Tag "run"), which runs dlg.get_code() through the history (no progress
%   dialog of the app: the analysis shows its own), and Analyze result (Tag "analyze"), and the status line (Tag
%   "status") next to them: the flag and the elapsed time of the last run, or its error,
% - the form DrawerOptionDialog(s_signature, Object="net", Output=sv_output, History=<app>),
%   with the initial values of f_value(net) (DrawerOptionDialog Value),
% - an optional second form sct_extra of another method on net (e.g. net.initialize of the
%   power flow tab): a heading with its button (Tag s_tag) on the same line, then the form
%   (panel Tag "form_<s_tag>", no outputs); the button runs its code the same way,
% - the note of the tab (Tag "note", a hint on the inputs; "" leaves no row).
%
% Every row takes the height of its content ("fit"): a form is a 1x1 grid (Tag "form" or
% "form_<s_tag>") whose row fits the grid of the DrawerOptionDialog, so the rows below follow
% the form when a group opens or closes. The space left stays under the last row; the panel
% scrolls when the forms are taller than the tab.
%
% The latest result overwrites the variable sv_output(1) of the history (one per tab).
% Analyze result is enabled while that variable holds a ResultBase. While the result of the
% last run is new (not opened from the tab yet; analyze_highlight), Analyze result is the
% filled logo-blue button with bold white text, Run takes the plain style and the status
% line ends with "open Analyze result"; opening the result, or a failed run, puts the two
% buttons back. It opens
% res.launch_gui(History=<app>, Variable=sv_output(1)) in a new window (a uifigure as
% visible as the app; Tag "result_gui"), so the actions of the result GUI go to the same log
% and script. Opening it is not logged: it changes no variable, and a script that opens
% windows would not repeat the analysis.
%
% The form is built for the network `net` of the history and built again when `net`
% becomes another network (the choices and defaults on obj, e.g. LoadBus). The hook
% f_changed follows the history: the status and the Run and Analyze result buttons. The
% state is in h_panel.UserData (net, dlg, h_form, dlg_extra, h_form_extra, h_status, h_run,
% h_analyze, res_opened: the result last opened).
    arguments (Input)
        h_panel   % Panel of the tab.
        sct_app   % Tab API (see tab_list).
        sct_spec (1,1) struct  % s_signature, sv_output ([result, flag]), s_label (log), l_banner, sv_exclude, f_value (@(net) struct of DrawerOptionDialog Value), s_note, sct_extra (0 or 1: s_signature, s_title, s_text and s_tag of the button, s_label).
    end
    arguments (Output)
        sct_hook (1,1) struct  % Hook f_changed (the diagram hooks are added by the tab).
    end
    sct_color = tools.gui_palette();
    l_extra = ~isempty(sct_spec.sct_extra);
    c_extra = {0, 0};
    if l_extra
        c_extra = {"fit", "fit"};
    end
    c_note = {0};
    if sct_spec.s_note ~= ""
        c_note = {"fit"};
    end
    h_grid = uigridlayout(h_panel, [7 1], "RowHeight", [{0, "fit", "fit", "fit"}, c_extra, c_note], ...
        "Padding", [16 12 16 12], "RowSpacing", 8, "Scrollable", "on", "BackgroundColor", sct_color.rv_background);
    if sct_spec.l_banner
        sct_app.f_stale_banner(h_grid, 1);
    end
    h_title = uilabel(h_grid, "Text", sct_app.s_title, "FontSize", 16, "FontWeight", "bold", ...
        "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_background);
    h_title.Layout.Row = 2;

    % Run, Analyze result and the status line
    h_buttons = uigridlayout(h_grid, [1 3], "ColumnWidth", {110, 130, "1x"}, "ColumnSpacing", 10, ...
        "Padding", 0, "BackgroundColor", sct_color.rv_background);
    h_buttons.Layout.Row = 3;
    h_run = uibutton(h_buttons, "Text", "Run", "Tag", "run", "FontWeight", "bold", "BackgroundColor", sct_color.rv_blue, ...
        "FontColor", sct_color.rv_header_text, "Tooltip", "Run " + sct_spec.s_signature + " with the options below", ...
        "ButtonPushedFcn", @(~, ~) run_form(h_panel, sct_app, "dlg", sct_spec.s_label));
    h_analyze = uibutton(h_buttons, "Text", "Analyze result", "Tag", "analyze", "Enable", "off", ...
        "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text, ...
        "Tooltip", "Open " + sct_spec.sv_output(1) + ".launch_gui(...) in a new window", ...
        "ButtonPushedFcn", @(~, ~) open_result(h_panel, sct_app, sct_spec));
    h_status = uilabel(h_buttons, "Text", "", "Tag", "status", "WordWrap", "on", ...
        "FontColor", sct_color.rv_subtext, "BackgroundColor", sct_color.rv_background);
    h_form = uigridlayout(h_grid, [1 1], "RowHeight", {"fit"}, "Padding", 0, "Tag", "form", ...
        "BackgroundColor", sct_color.rv_background);
    h_form.Layout.Row = 4;
    h_note = uilabel(h_grid, "Text", sct_spec.s_note, "Tag", "note", "WordWrap", "on", ...
        "FontColor", sct_color.rv_subtext, "BackgroundColor", sct_color.rv_background);
    h_note.Layout.Row = 7;

    % Second form (sct_extra): heading and its button on one line, then the form
    h_form_extra = [];
    if l_extra
        sct_x = sct_spec.sct_extra;
        h_row = uigridlayout(h_grid, [1 2], "ColumnWidth", {"1x", "fit"}, "Padding", [0 6 0 0], ...
            "BackgroundColor", sct_color.rv_background);
        h_row.Layout.Row = 5;
        uilabel(h_row, "Text", sct_x.s_title, "FontWeight", "bold", ...
            "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_background);
        uibutton(h_row, "Text", sct_x.s_text, "Tag", sct_x.s_tag, "FontWeight", "bold", ...
            "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text, ...
            "ButtonPushedFcn", @(~, ~) run_form(h_panel, sct_app, "dlg_extra", sct_x.s_label));
        h_form_extra = uigridlayout(h_grid, [1 1], "RowHeight", {"fit"}, "Padding", 0, ...
            "Tag", "form_" + sct_x.s_tag, "BackgroundColor", sct_color.rv_background);
        h_form_extra.Layout.Row = 6;
    end

    h_panel.UserData = struct("net", [], "dlg", [], "h_form", h_form, "dlg_extra", [], "h_form_extra", h_form_extra, ...
        "h_status", h_status, "h_run", h_run, "h_analyze", h_analyze, "res_opened", []);
    sct_hook = struct("f_changed", @() update_panel(h_panel, sct_app, sct_spec));
    update_panel(h_panel, sct_app, sct_spec);
end

function update_panel(h_panel, sct_app, sct_spec)
% Build the form for the network of the history (again when it changed), then show the
% status of the last run of the form and style Run and Analyze result (analyze_highlight).
    arguments (Input)
        h_panel   % Panel of the tab (UserData: the state).
        sct_app   % Tab API (see tab_list).
        sct_spec  % Spec of the tab (see tab_analysis_panel).
    end
    arguments (Output)
    end
    if ~isvalid(h_panel)
        return
    end
    sct_color = tools.gui_palette();
    try
        net = sct_app.history.get_variable("net");
    catch    % no network
        net = [];
    end
    sct_state = h_panel.UserData;
    if isa(net, "PowerNetwork") && isscalar(net) && isvalid(net) ...
            && ~(isa(sct_state.net, "PowerNetwork") && isvalid(sct_state.net) && sct_state.net == net)
        delete(sct_state.h_form.Children);
        sct_state.net = net;
        sct_state.dlg = DrawerOptionDialog(sct_spec.s_signature, sct_state.h_form, Object="net", ...
            Output=sct_spec.sv_output, Exclude=sct_spec.sv_exclude, History=sct_app.history, ...
            Value=sct_spec.f_value(net));
        if ~isempty(sct_spec.sct_extra)
            delete(sct_state.h_form_extra.Children);
            sct_state.dlg_extra = DrawerOptionDialog(sct_spec.sct_extra.s_signature, sct_state.h_form_extra, ...
                Object="net", History=sct_app.history);
        end
        h_panel.UserData = sct_state;
    end
    % Status: the last ended entry that ran the method of the tab
    h_status = sct_state.h_status;
    tab = sct_app.history.tab_entry;
    s_call = "[" + join(sct_spec.sv_output, ", ") + "] = net." + extractAfter(sct_spec.s_signature, ".") + "(";
    i_last = [];
    if ~isempty(tab)
        i_last = find(startsWith(tab.Code, s_call) & tab.Status ~= "run", 1, "last");
    end
    if isempty(i_last)
        h_status.Text = "Not run yet.";
        h_status.FontColor = sct_color.rv_subtext;
    else
        s_time = string(regexp(tab.Detail(i_last), "\((\d+\.\d+) s\)$", "tokens", "once"));
        if tab.Status(i_last) == "done"
            s_flag = "";
            try
                flag = sct_app.history.get_variable(sct_spec.sv_output(2));
                s_flag = sct_spec.sv_output(2) + " = " + join(string(flag), " ") + " · ";
            catch    % no flag
            end
            h_status.Text = "✔ Last run: " + s_flag + s_time + " s";
            h_status.FontColor = sct_color.rv_text;
        else
            h_status.Text = "✖ The last run failed (" + s_time + " s): " ...
                + regexprep(tab.Detail(i_last), " \(\d+\.\d+ s\)$", "");
            h_status.FontColor = sct_color.rv_stale_text;
        end
    end
    l_new = analyze_highlight(sct_app.history, s_call, sct_spec.sv_output(1), sct_state.res_opened, ...
        sct_state.h_run, sct_state.h_analyze);
    if l_new
        h_status.Text = h_status.Text + " — open Analyze result";
    end
end

function run_form(h_panel, sct_app, s_dlg, s_label)
% Run the code of a form of the tab; an invalid value only shows the message of the form.
%
% No progress dialog of the app: the analysis shows its own progress (ProgressGUILDA, in
% the figure Tagged "GUILDA:app"), and two dialogs in one figure would both stay open.
    arguments (Input)
        h_panel   % Panel of the tab (UserData: the state).
        sct_app   % Tab API (see tab_list).
        s_dlg (1,1) string       % Field of the state with the form: "dlg" or "dlg_extra".
        s_label (1,1) string     % Label of the log entry.
    end
    arguments (Output)
    end
    s_code = h_panel.UserData.(s_dlg).get_code();
    if s_code ~= ""
        sct_app.f_run(s_label, s_code);
    end
end

function open_result(h_panel, sct_app, sct_spec)
% Open the result GUI of the result variable in a new window, on the history of the app (not logged).
%
% The result becomes the one opened (res_opened), so Run and Analyze result get their
% normal styles back.
    arguments (Input)
        h_panel   % Panel of the tab (UserData: the state).
        sct_app   % Tab API (see tab_list).
        sct_spec  % Spec of the tab (see tab_analysis_panel).
    end
    arguments (Output)
    end
    sct_color = tools.gui_palette();
    res = sct_app.history.get_variable(sct_spec.sv_output(1));
    h_panel.UserData.res_opened = res;
    update_panel(h_panel, sct_app, sct_spec);
    h_fig = uifigure("Name", sct_spec.sv_output(1) + " (" + class(res) + ")", "Tag", "result_gui", ...
        "Position", [120 80 1100 680], "Color", sct_color.rv_background, ...
        "Visible", sct_app.app.h_figure.Visible);
    if isprop(h_fig, "Theme")
        h_fig.Theme = "light";
    end
    res.launch_gui(h_fig, History=sct_app.history, Variable=sct_spec.sv_output(1));
end
