% F57 GUILDA のアプリの時間シミュレーションのタブ (DrawerGUILDA, tab_sim_*)
%
%   h = GUILDA.launch_gui(net);   % 「時間シミュレーション」のタブ
%
% シナリオの一覧 (追加・削除、ほかのタブや記録からの追加)、選んだシナリオのモデルの GUI での外乱の追加、
% 系統図での対象の強調、simulate のフォームと実行、res_ode と状態の行、「結果を解析」、実行後も系統図が
% 平衡点のまま (結果の図に替わらない) であること、書き出したスクリプトが別のワークスペースで同じ結果を作ることを確かめる。アプリは見えない図
% (DrawerGUILDA(..., Visible=false)) に作り、ダイアログは F55 と同じくタイマーで押す (ask は誰も押さなければ
% 10 秒以内に "" を返す)。シミュレーションは IEEE9bus で 1 秒だけ。
%
% 実行: runtests("DebugScript.test_F57_guilda_app_sim")  または  DebugScript.run_all("Features","F57")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% The tab lists no scenario at first; Add and Remove run add_scenario and remove_scenario
h = DrawerGUILDA(network.IEEE9bus, Visible=false);
f = h.h_figure;
select_tab(f, "sim");
p = sim_panel(f);
assert(isempty(p.h.list.Items) && isscalar(findall(p.h.scenario, "Tag", "sim_no_scenario")))
assert(p.h.add.Enable && ~p.h.remove.Enable && ~p.h.run.Enable && ~p.h.analyze.Enable)
assert(~isfield(p.h, "slider") && isempty(findall(f, "Tag", "sim_slider")))    % no time slider: the result is viewed in Analyze result
assert(isempty(findall(p.h.form, "Type", "uilabel")))
% 追加: add_scenario のフォーム
press_dialog(f, "sim_add", "PowerNetwork.add_scenario", ["s_tag", "case1"; "Time", "[0 1]"; "", "Run"]);
assert(h.history.tab_entry.Code(end) == "sc = net.add_scenario(""case1"", Time=[0 1]);", h.history.tab_entry.Code(end))
assert(h.history.tab_entry.Group(end) == "Time simulation" && h.history.tab_entry.Status(end) == "done")
p = sim_panel(f);
net = h.history.get_variable("net");
assert(isequal(string(p.h.list.Items), "case1") && string(p.h.list.Value) == "case1" && p.sc == net.a_Scenario{1})
assert(isa(p.gui, "DrawerModelGUI") && p.gui.a_target == net.a_Scenario{1} && p.gui.history == h.history)
assert(p.h.remove.Enable && p.h.run.Enable)
assert(startsWith(p.dlg.get_code(), "[res_ode, flag_ode] = net.simulate(""case1"""), p.dlg.get_code())
% 2 つ目は追加したものが選ばれる
press_dialog(f, "sim_add", "PowerNetwork.add_scenario", ["s_tag", "case2"; "", "Run"]);
p = sim_panel(f);
assert(isequal(string(p.h.list.Items), ["case1", "case2"]) && string(p.h.list.Value) == "case2" && p.gui.a_target == net.a_Scenario{2})
assert(startsWith(p.dlg.get_code(), "[res_ode, flag_ode] = net.simulate(""case2"""))
% 削除: 見えない図では確認なしで実行し、残ったものを選ぶ
press(f, "sim_remove");
assert(h.history.tab_entry.Code(end) == "net.remove_scenario(""case2"");" && h.history.tab_entry.Status(end) == "done")
p = sim_panel(f);
assert(isequal(string(p.h.list.Items), "case1") && string(p.h.list.Value) == "case1" && p.gui.a_target == net.a_Scenario{1})
% 取り消した追加は何も実行しない
n_entry = height(h.history.tab_entry);
press_dialog(f, "sim_add", "PowerNetwork.add_scenario", ["", "Cancel"]);
assert(height(h.history.tab_entry) == n_entry)


%% A scenario added from the log or another tab appears in the list and is selected; a list click selects another
h = DrawerGUILDA(network.IEEE9bus, Visible=false);
f = h.h_figure;
h.history.run("Model building", "Add", "net.add_scenario(""early"");");
select_tab(f, "sim");    % 作る前に追加したもの
p = sim_panel(f);
assert(isequal(string(p.h.list.Items), "early") && string(p.h.list.Value) == "early")
h.history.run("Model building", "Add", "net.add_scenario(""late"");");    % 作った後に追加したもの
p = sim_panel(f);
assert(isequal(string(p.h.list.Items), ["early", "late"]) && string(p.h.list.Value) == "late")
gui = p.gui;
h.history.run("Model building", "Edit", "net.a_Bus{1}.tab_parameter.powerflow.V = 1.0;");    % 一覧が同じなら作り直さない
p = sim_panel(f);
assert(p.gui == gui)
select_list(f, "early");
p = sim_panel(f);
assert(string(p.h.list.Value) == "early" && p.gui.a_target == h.history.get_variable("net").a_Scenario{1} && p.gui ~= gui)
assert(startsWith(p.dlg.get_code(), "[res_ode, flag_ode] = net.simulate(""early"""))
% 系統を入れ替えると一覧も入れ替わる
h.history.run("Model building", "New", "net = network.Tutorial3bus();");
p = sim_panel(f);
assert(isempty(p.h.list.Items) && isempty(p.gui) && isempty(p.dlg) && ~p.h.run.Enable)


%% Disturbances added in the embedded scenario GUI are highlighted in the diagram
h = DrawerGUILDA(network.IEEE9bus, Visible=false);
f = h.h_figure;
net = h.history.get_variable("net");
h.history.run("Time simulation", "Add", "net.add_scenario(""case1"", Time=[0 1]);");
select_tab(f, "sim");
assert(isa(h.G, "GraphNetDiagram") && isempty(h.G.Selection))
p = sim_panel(f);
press_add(p.gui, "+ Fault", "Scenario.add_fault", ["target", "B007"; "time", "[0.1 0.15]"; "", "Run"]);
assert(h.history.tab_entry.Code(end) == "net.a_Scenario{1}.add_fault(""B007"", [0.1 0.15]);", h.history.tab_entry.Code(end))
assert(isequal(sort(string(h.G.Selection)), "B007"))
assert(sim_panel(f).gui == p.gui && p.gui.a_target == net.a_Scenario{1})    % 外乱の追加では GUI を作り直さない
% 送電線の開放、機器の入力、AVR の解列 (その機器を強調)
s_branch = string(net.a_Branch{1}.s_tag);
comp1 = net.a_Bus{1}.a_Component{1};
comp2 = net.a_Bus{2}.a_Component{1};
h.history.run("Model building", "Open", "net.a_Scenario{1}.add_open_branch(""" + s_branch + """, 0.5);");
h.history.run("Model building", "Input", "net.a_Scenario{1}.add_input(""" + string(comp2.s_tag) + """, ""Pmech"", 0.01, [0.2 0.4]);");
h.history.run("Model building", "Trip", "net.a_Scenario{1}.add_trip(""" + string(comp1.a_LocalController{1}.s_tag) + """, 0.3);");
assert(isequal(sort(string(h.G.Selection)), sort(["B007", s_branch, string(comp2.s_tag), string(comp1.s_tag)])), strjoin(string(h.G.Selection)))
% 外乱のないシナリオは強調しない
h.history.run("Time simulation", "Add", "net.add_scenario(""empty"");");
assert(isempty(h.G.Selection))
% 系統モデルの作成タブに戻ると強調は消える
select_tab(f, "model");
assert(isempty(h.G.Selection))


%% Run simulates the scenario selected; the diagram keeps its targets at the equilibrium; Analyze result opens its GUI
h = DrawerGUILDA(network.IEEE9bus, Visible=false);
f = h.h_figure;
h.history.run("Time simulation", "Add", "net.add_scenario(""case1"", Time=[0 1]); net.a_Scenario{1}.add_fault(""B007"", [0.1 0.15]);");
select_tab(f, "sim");
G_net = h.G;
press(f, "sim_run");
tab = h.history.tab_entry;
assert(tab.Code(end) == "[res_ode, flag_ode] = net.simulate(""case1"");" && tab.Status(end) == "done", tab.Code(end) + " " + tab.Detail(end))
assert(tab.Group(end) == "Time simulation")
res = h.history.get_variable("res_ode");
assert(isa(res, "ResultODE") && h.history.get_variable("flag_ode") == 1 && abs(res.rv_t(end) - 1) < 1e-9)
p = sim_panel(f);
assert(p.res == res && p.s_res_scenario == "case1" && ~isfield(p, "G_res"))
% 実行後の図: 平衡点の系統図のまま (同じ図、1 時刻)。シナリオの対象 (故障の母線) を選択したまま
assert(h.G == G_net && numel(h.G.rv_t) == 1 && ismember("B007", h.G.Selection))
assert(contains(p.h.status.Text, "flag 1") && contains(p.h.status.Text, "[case1]"), p.h.status.Text)
assert(p.h.analyze.Enable)
assert(h.G.ColorbarLabel == "Branch current |I| [pu]" && contains(join(string(findall(f, "Tag", "info").Text)), "Selected: the targets of scenario case1"))
% 結果を解析
press(f, "sim_analyze");
gui_res = findall(f, "Tag", "sim_analyze").UserData;
assert(isa(gui_res, "DrawerResultGUI") && gui_res.history == h.history && gui_res.a_target == res)
assert(h.history.get_variable("res_ode") == res)
h_new = findall(groot, "Type", "figure", "Name", "ResultODE res_ode");
assert(isscalar(h_new) && ~h_new.Visible)    % 見えないアプリからは見えない窓
% ほかのシナリオを選ぶとその対象 (なし) の図、戻すと case1 の対象。どちらも平衡点の 1 時刻
h.history.run("Time simulation", "Add", "net.add_scenario(""other"");");
p = sim_panel(f);
assert(string(p.h.list.Value) == "other" && isempty(h.G.Selection) && numel(h.G.rv_t) == 1)
select_list(f, "case1");
assert(ismember("B007", h.G.Selection) && numel(h.G.rv_t) == 1)
% タブを切り替えて戻っても同じ系統図
G_net = h.G;
select_tab(f, "model");
select_tab(f, "sim");
assert(h.G == G_net && numel(h.G.rv_t) == 1)


%% An invalid form value or a failed run is written in the status line
h = DrawerGUILDA(network.IEEE9bus, Visible=false);
f = h.h_figure;
h.history.run("Time simulation", "Add", "net.add_scenario(""case1"", Time=[0 1]);");
select_tab(f, "sim");
h_tol = findall(sim_panel(f).h.form, "Tag", "Tolerance");
h_tol.Value = 'abc';
n_entry = height(h.history.tab_entry);
press(f, "sim_run");
assert(height(h.history.tab_entry) == n_entry && sim_panel(f).h.status.Text == "Check the values of the form.")
h_tol.Value = '-1';    % simulate の検査で止まる
press(f, "sim_run");
assert(h.history.tab_entry.Status(end) == "fail" && startsWith(sim_panel(f).h.status.Text, "Failed: "))


%% The exported script repeats the simulation in another workspace
h = DrawerGUILDA([], Visible=false);
f = h.h_figure;
h_sample = findall(f, "Tag", "start_sample");
h_sample.Value = "IEEE9bus";
press(f, "start_sample_load");
select_tab(f, "sim");
press_dialog(f, "sim_add", "PowerNetwork.add_scenario", ["s_tag", "case1"; "Time", "[0 1]"; "", "Run"]);
press_add(sim_panel(f).gui, "+ Fault", "Scenario.add_fault", ["target", "B007"; "time", "[0.1 0.15]"; "", "Run"]);
press(f, "sim_run");
assert(h.history.tab_entry.Status(end) == "done")
res = h.history.get_variable("res_ode");
press(f, "export");
s_file = findall(f, "Tag", "export").UserData;
c_file = onCleanup(@() delete(s_file));
s_script = string(fileread(s_file));
assert(contains(s_script, "%% Time simulation") && contains(s_script, "[res_ode, flag_ode] = net.simulate(""case1"");"))
res2 = DebugScript.helper.quiet(@() run_script(s_file));
assert(isa(res2, "ResultODE") && isequal(size(res2.rm_variable), size(res.rm_variable)))
assert(max(abs(res2.rm_variable - res.rm_variable), [], "all") < 1e-8)


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function res_ode = run_script(s_file) %#ok<STOUT> res_ode はスクリプトが作る
% 書き出したスクリプトを、このテストと共有しないワークスペースで実行する
    run(s_file);
end

function sct = sim_panel(f)
% 時間シミュレーションのタブの状態 (tab_sim_build)
    sct = findall(f, "Tag", "tab_sim").UserData;
    assert(isstruct(sct) && isfield(sct, "h"))
end

function press(h_parent, s_tag)
% Tag のボタンを押す
    h = findall(h_parent, "Tag", s_tag);
    assert(isscalar(h), "button " + s_tag)
    h.ButtonPushedFcn(h, []);
end

function select_tab(f, s_key)
% タブのボタンを押す
    h = findall(f, "Tag", "tab", "UserData", s_key);
    h.Value = true;
    h.ValueChangedFcn(h, []);
end

function select_list(f, s_tag)
% シナリオの一覧で選ぶ
    h = findall(f, "Tag", "sim_list");
    h.Value = char(s_tag);
    h.ValueChangedFcn(h, []);
end

function press_dialog(f, s_button, s_signature, sm_step)
% タブのボタンでダイアログを開き、タイマーが欄の入力とボタンの押下を行う
    h_button = findall(f, "Tag", s_button);
    assert(isscalar(h_button), "button " + s_button)
    t = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, s_signature, sm_step));
    c_timer = onCleanup(@() delete_timer(t));
    start(t);
    h_button.ButtonPushedFcn(h_button, []);
    assert(t.UserData == "yes", s_button + ": the timer did not find the dialog (" + string(t.UserData) + ")")
end

function press_add(gui, s_text, s_signature, sm_step)
% モデルの GUI の追加ボタンを押し、開いたフォームでタイマーが欄の入力とボタンの押下を行う
    h_add = findall(gui.h_container, "Type", "uibutton", "Tag", "add", "Text", s_text);
    assert(isscalar(h_add), "button " + s_text)
    t = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, s_signature, sm_step));
    c_timer = onCleanup(@() delete_timer(t));
    start(t);
    n_entry = height(gui.history.tab_entry);
    h_add.ButtonPushedFcn(h_add, []);
    assert(height(gui.history.tab_entry) > n_entry, s_text + ": nothing ran (timer pressed: " + string(t.UserData) + ")")
end

function press_in_dialog(t, s_name, sm_step)
% ask のダイアログで、欄への入力とボタンの押下を順に行う ([タグ, 値] または ["", ボタンの文字])
    h_fig = findall(groot, "Type", "figure", "Name", s_name);
    if ~isscalar(h_fig) || isempty(findall(h_fig, "Type", "uibutton", "Text", "Cancel"))
        t.UserData = sprintf("no (%d figures)", numel(h_fig));
        return
    end
    stop(t);
    t.UserData = "yes";
    for i = 1:size(sm_step, 1)
        if ~isvalid(h_fig)
            return
        end
        if sm_step(i, 1) == ""
            h = findall(h_fig, "Type", "uibutton", "Text", sm_step(i, 2));
            h.ButtonPushedFcn(h, []);
        else
            h = findall(h_fig, "Tag", sm_step(i, 1));
            if isa(h, "matlab.ui.control.ListBox") && h.Multiselect
                h.Value = {char(sm_step(i, 2))};
            else
                h.Value = char(sm_step(i, 2));
            end
            h.ValueChangedFcn(h, []);
        end
        drawnow
    end
end

function delete_timer(t)
% タイマーを止めて消す
    if isvalid(t)
        stop(t);
        delete(t);
    end
end
