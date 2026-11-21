function tab_sim_refresh(h_panel, sct_app, s_select)
% Update the time simulation tab from the history: the scenario list, the model GUI and form of the selection, the result.
%
% The hook f_changed of the tab, also called on the build and when the list selection
% changes (s_select). The selection is the scenario selected before (followed by object,
% so a renamed scenario stays selected), a scenario that has just been added (also from
% the model tab or the log), or the first one. The model GUI is built again only when the
% scenario selected or the network changes, and the form of simulate when the selection
% or the list of tags changes (its s_scenario lists the tags); each is built in a new
% container, so a model GUI still running an action draws nothing into the new one.
%
% A ResultODE in `res_ode` of the history, other than the last one seen, that appears
% during a run of Run is the result of the scenario then selected (s_run_scenario): the
% status line names that scenario. The status line and Analyze result follow
% `res_ode` of the history: while the result of the last simulate is new (not opened from
% the tab yet; analyze_highlight), Analyze result is the filled primary button, Run the
% plain one, and the status line ends with "open Analyze result".
    arguments (Input)
        h_panel                             % Panel of the tab (UserData: the state, see tab_sim_build).
        sct_app                             % Tab API (see tab_list).
        s_select (1,1) string = missing     % Tag to select (the list selection); missing keeps the rule above.
    end
    arguments (Output)
    end
    if ~isvalid(h_panel)
        return
    end
    sct = h_panel.UserData;
    sct_color = tools.gui_palette();
    try
        net = sct_app.history.get_variable("net");
    catch    % no network
        net = [];
    end
    sv_tag = strings(1, 0);
    if isa(net, "PowerNetwork") && isscalar(net) && isvalid(net)
        sv_tag = reshape(string(cellfun(@(s) string(s.s_tag), net.a_Scenario, "UniformOutput", false)), 1, []);
    else
        net = [];
    end
    l_sameNet = ~isempty(net) && ~isempty(sct.net) && isvalid(sct.net) && sct.net == net;

    % Selection
    k = [];
    if ~ismissing(s_select)
        k = find(sv_tag == s_select, 1);
    elseif l_sameNet && numel(sv_tag) > numel(sct.sv_tag) && ~isempty(setdiff(sv_tag, sct.sv_tag))
        k = find(sv_tag == string(setdiff(sv_tag, sct.sv_tag, "stable")), 1, "last");    % just added
    elseif l_sameNet && ~isempty(sct.sc) && isvalid(sct.sc)
        k = find(cellfun(@(s) s == sct.sc, net.a_Scenario), 1);
    end
    if isempty(k) && ~isempty(sv_tag)
        k = 1;
    end
    sc = [];
    s_tag = "";
    if ~isempty(k)
        sc = net.a_Scenario{k};
        s_tag = sv_tag(k);
    end
    l_sameScenario = l_sameNet && isequal(isempty(sc), isempty(sct.sc)) ...
        && (isempty(sc) || (isvalid(sct.sc) && sct.sc == sc));
    sct.h.list.Items = cellstr(sv_tag);
    if s_tag ~= ""
        sct.h.list.Value = char(s_tag);
    end
    sct.h.remove.Enable = s_tag ~= "";
    sct.h.add.Enable = ~isempty(net);

    % Model GUI of the scenario, in a new container; kept for the same scenario, and drawn
    % again on the next show (tab_sim_action "show") after a run while the tab is hidden
    sct.l_stale = l_sameScenario && (sct.l_stale || ~h_panel.Visible);
    if ~l_sameScenario
        delete(sct.h.scenario.Children);
        sct.gui = [];
        h_box = uigridlayout(sct.h.scenario, [1 1], "Padding", 0, "BackgroundColor", sct_color.rv_background);
        if isempty(sc)
            uilabel(h_box, "Text", "No scenario yet. Create one with Add.", ...
                "Tag", "sim_no_scenario", "FontColor", sct_color.rv_subtext, "BackgroundColor", sct_color.rv_background);
        else
            sct.gui = sc.launch_gui(h_box, History=sct_app.history);
        end
    end

    % Form of simulate, for the scenario selected
    if ~l_sameScenario || ~isequal(sv_tag, sct.sv_tag) || isempty(sct.dlg) || ~isvalid(sct.dlg)
        delete(sct.h.form.Children);
        sct.dlg = [];
        if ~isempty(sc)
            sct.dlg = DrawerOptionDialog("PowerNetwork.simulate", sct.h.form, Object="net", ...
                Output=["res_ode", "flag_ode"], History=sct_app.history, Exclude="Format", ...
                Value=struct("s_scenario", """" + replace(s_tag, """", """""") + """"));
        end
    end
    sct.h.run.Enable = ~isempty(sc);

    % Result of the last run
    [l_new, res] = analyze_highlight(sct_app.history, "[res_ode, flag_ode] = net.simulate(", "res_ode", ...
        sct.res_opened, sct.h.run, sct.h.analyze);
    if ~isa(res, "ResultODE")
        res = [];
    end
    if ~isempty(res) && sct.s_run_scenario ~= "" ...
            && (isempty(sct.res) || ~isvalid(sct.res) || sct.res ~= res)
        sct.res = res;
        sct.s_res_scenario = sct.s_run_scenario;
    end
    if isempty(res)
        sct.h.status.Text = "";
    else
        s_status = sprintf("res_ode: flag %s, t = %.4g – %.4g s (%d points), %.2f s", string(res.flag), ...
            res.rv_t(1), res.rv_t(end), numel(res.rv_t), res.r_elapsed);
        if ~isempty(sct.res) && isvalid(sct.res) && sct.res == res
            s_status = s_status + "  [" + sct.s_res_scenario + "]";
        end
        if l_new
            s_status = s_status + " — open Analyze result";
        end
        sct.h.status.Text = s_status;
    end

    sct.net = net;
    sct.sv_tag = sv_tag;
    sct.sc = sc;
    h_panel.UserData = sct;
end
