function tab_sim_action(s_action, h_panel, sct_app)
% Run a control of the time simulation tab: a button, the list or a hook.
%
% - "add": the form of PowerNetwork.add_scenario in a dialog (DrawerOptionDialog.ask), run
%   as `sc = net.add_scenario(...);`; the new scenario becomes the selection (tab_sim_refresh).
% - "remove": `net.remove_scenario("<tag>");` of the selection, after a uiconfirm on a
%   visible figure outside matlab -batch.
% - "select": show the scenario selected in the list (model GUI, form, diagram).
% - "run": the code of the simulate form, without a progress dialog of the app (simulate
%   shows its own, ProgressGUILDA). The scenario selected
%   is remembered for the result (tab_sim_refresh); a form value that is invalid or a
%   failed run is written in the status line.
% - "analyze": `res_ode.launch_gui(History=<history>, Variable="res_ode")` in a new
%   window (a hidden one when the app is hidden); the DrawerResultGUI is kept in the
%   UserData of the button. The result becomes the one opened (res_opened), so Run and
%   Analyze result get their normal styles back.
% - "show": the hook f_show. The model GUI is drawn again when a run ended while the tab
%   was hidden (l_stale: the scenario may have been edited elsewhere). The diagram of the
%   tab is its own, so it stays as it is.
%
% Nothing but add, remove and run is logged.
    arguments (Input)
        s_action (1,1) string {mustBeMember(s_action, ["add", "remove", "select", "run", "analyze", "show"])}  % Control.
        h_panel  % Panel of the tab (UserData: the state, see tab_sim_build).
        sct_app  % Tab API (see tab_list).
    end
    arguments (Output)
    end
    if ~isvalid(h_panel)
        return
    end
    sct = h_panel.UserData;
    h_fig = sct_app.app.h_figure;
    l_visible = h_fig.Visible && ~batchStartupOptionUsed;
    switch s_action
        case "add"
            s_code = DrawerOptionDialog.ask(h_fig, "PowerNetwork.add_scenario", Object="net", Output="sc", ...
                History=sct_app.history);
            if s_code ~= ""
                sct_app.f_run("Add a scenario", s_code);
            end
        case "remove"
            s_tag = string(sct.h.list.Value);
            if isempty(s_tag) || s_tag == ""
                return
            end
            if l_visible && uiconfirm(h_fig, "Remove scenario " + s_tag + "?", "Remove a scenario", ...
                    "Options", ["Remove", "Cancel"], "DefaultOption", 2, "CancelOption", 2, "Icon", "warning") ~= "Remove"
                return
            end
            sct_app.f_run("Remove a scenario", "net.remove_scenario(""" + replace(s_tag, """", """""") + """);");
        case "select"
            tab_sim_refresh(h_panel, sct_app, string(sct.h.list.Value));
            sct_app.f_redraw();
        case "run"
            if isempty(sct.dlg) || ~isvalid(sct.dlg)
                return
            end
            s_code = sct.dlg.get_code();
            if s_code == ""
                sct.h.status.Text = "Check the values of the form.";
                return
            end
            sct.s_run_scenario = string(sct.h.list.Value);
            h_panel.UserData = sct;
            [l_ok, s_detail] = sct_app.f_run("Simulate", s_code);    % simulate shows its own progress
            if isvalid(h_panel)
                h_panel.UserData.s_run_scenario = "";
                if ~l_ok
                    h_panel.UserData.h.status.Text = "Failed: " + regexprep(s_detail, " \(\d+\.\d+ s\)$", "");
                end
            end
        case "analyze"
            res = sct_app.history.get_variable("res_ode");
            h_panel.UserData.res_opened = res;
            tab_sim_refresh(h_panel, sct_app);
            h_window = [];    % a new window
            if ~h_fig.Visible    % hidden app (tests): a hidden window
                h_window = uifigure("Name", "ResultODE res_ode", "Visible", "off");
            end
            sct.h.analyze.UserData = res.launch_gui(h_window, History=sct_app.history, Variable="res_ode");
        case "show"
            if sct.l_stale && ~isempty(sct.gui) && isvalid(sct.gui)
                h_panel.UserData.l_stale = false;
                sct.gui.render();
            end
    end
end
