function sct_hook = tab_sim_build(h_panel, sct_app)
% Time simulation tab: the scenarios of the network, the model GUI of the one selected and the simulate form.
%
% From top to bottom (Tags in parentheses):
%
% - The stale banner (simulate needs the equilibrium).
% - Scenarios: the list of net.a_Scenario (sim_list) with Add (sim_add, the form of
%   PowerNetwork.add_scenario in a dialog: `sc = net.add_scenario(...);`) and Remove
%   (sim_remove, `net.remove_scenario("<tag>");` after a confirmation on a visible figure).
%   The scenario selected is shown below in its model GUI (sim_scenario_gui:
%   `net.a_Scenario{k}.launch_gui(<panel>, History=<history of the app>)`), which adds and
%   removes the events.
% - Simulation: a heading with Run (sim_run; simulate shows its own progress) and Analyze result
%   (sim_analyze: `res_ode.launch_gui(History=<history>, Variable="res_ode")` in a new
%   window) on the same line, a status line (sim_status) and the form of
%   PowerNetwork.simulate (sim_form, DrawerOptionDialog with `s_scenario` set to the
%   scenario selected, outputs `[res_ode, flag_ode]`).
%
% The diagram (tab_sim_diagram) shows the network at the equilibrium with the targets of
% the scenario selected, before and after a run; the result is viewed in the Analyze result
% window. The state of the tab is in h_panel.UserData (widgets, the network and scenario
% shown, the model GUI, the form, the last result and the result opened); tab_sim_refresh
% updates the list after every run of the history (f_changed), and tab_sim_action runs the
% buttons and the list.
    arguments (Input)
        h_panel  % Panel of the tab.
        sct_app  % Tab API (see tab_list).
    end
    arguments (Output)
        sct_hook (1,1) struct  % Hooks f_show, f_changed, f_diagram and f_legend.
    end
    sct_color = tools.gui_palette();
    sct_label = {"FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_background};
    sct_button = {"FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_card};
    h_grid = uigridlayout(h_panel, [8 1], "RowHeight", {0, "fit", "fit", 72, "1x", "fit", "fit", "fit"}, ...
        "Padding", [12 8 12 8], "RowSpacing", 6, "BackgroundColor", sct_color.rv_background);
    sct_app.f_stale_banner(h_grid, 1);

    % Scenarios
    h_title = uilabel(h_grid, "Text", sct_app.s_title, "FontSize", 16, "FontWeight", "bold", ...
        "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_background);
    h_title.Layout.Row = 2;
    h_bar = uigridlayout(h_grid, [1 3], "ColumnWidth", {"1x", 80, 80}, "Padding", 0, ...
        "BackgroundColor", sct_color.rv_background);
    h_bar.Layout.Row = 3;
    uilabel(h_bar, "Text", "Scenarios", "FontWeight", "bold", sct_label{:});
    sct_h.add = uibutton(h_bar, "Text", "Add", "Tag", "sim_add", sct_button{:}, ...
        "Tooltip", "Add a scenario with the form of net.add_scenario", ...
        "ButtonPushedFcn", @(~, ~) tab_sim_action("add", h_panel, sct_app));
    sct_h.remove = uibutton(h_bar, "Text", "Remove", "Tag", "sim_remove", sct_button{:}, ...
        "Tooltip", "Remove the scenario selected (net.remove_scenario)", ...
        "ButtonPushedFcn", @(~, ~) tab_sim_action("remove", h_panel, sct_app));
    sct_h.list = uilistbox(h_grid, "Items", {}, "Tag", "sim_list", "FontColor", sct_color.rv_text, ...
        "BackgroundColor", sct_color.rv_card, ...
        "ValueChangedFcn", @(~, ~) tab_sim_action("select", h_panel, sct_app));
    sct_h.list.Layout.Row = 4;
    sct_h.scenario = uipanel(h_grid, "Tag", "sim_scenario_gui", "BorderType", "none", ...
        "BackgroundColor", sct_color.rv_background);
    sct_h.scenario.Layout.Row = 5;

    % Simulation: heading with Run and Analyze result, the status line and the form
    h_run = uigridlayout(h_grid, [1 3], "ColumnWidth", {"1x", 90, 130}, "Padding", 0, ...
        "BackgroundColor", sct_color.rv_background);
    h_run.Layout.Row = 6;
    uilabel(h_run, "Text", "Simulation", "FontWeight", "bold", sct_label{:});
    sct_h.run = uibutton(h_run, "Text", "Run", "Tag", "sim_run", "FontWeight", "bold", ...
        "FontColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue, ...
        "Tooltip", "Run net.simulate with the options below", ...
        "ButtonPushedFcn", @(~, ~) tab_sim_action("run", h_panel, sct_app));
    sct_h.analyze = uibutton(h_run, "Text", "Analyze result", "Tag", "sim_analyze", "Enable", "off", sct_button{:}, ...
        "Tooltip", "Open res_ode.launch_gui(...) in a new window", ...
        "ButtonPushedFcn", @(~, ~) tab_sim_action("analyze", h_panel, sct_app));
    sct_h.status = uilabel(h_grid, "Text", "", "Tag", "sim_status", "WordWrap", "on", ...
        "FontColor", sct_color.rv_subtext, "BackgroundColor", sct_color.rv_background);
    sct_h.status.Layout.Row = 7;
    sct_h.form = uigridlayout(h_grid, [1 1], "RowHeight", {"fit"}, "Padding", 0, "Tag", "sim_form", ...
        "BackgroundColor", sct_color.rv_background);    % its row fits the form
    sct_h.form.Layout.Row = 8;


    h_panel.UserData = struct("h", sct_h, "net", [], "sv_tag", strings(1, 0), "sc", [], ...
        "gui", [], "dlg", [], "res", [], "s_res_scenario", "", "s_run_scenario", "", "l_stale", false, ...
        "res_opened", []);
    tab_sim_refresh(h_panel, sct_app);
    sct_hook = struct( ...
        "f_show",    @() tab_sim_action("show", h_panel, sct_app), ...
        "f_changed", @() tab_sim_refresh(h_panel, sct_app), ...
        "f_diagram", @(G, h_parent) tab_sim_diagram(G, h_parent, h_panel, sct_app), ...
        "f_legend",  @() tab_sim_legend(h_panel));
end
