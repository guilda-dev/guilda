% F51 モデルの GUI の操作 (追加・削除・パラメータの編集、DrawerModelGUI + HistoryGUILDA)
%
%   hist = HistoryGUILDA();
%   h = net.launch_gui(h_panel, History=hist);   % 操作はすべて hist.run で実行するコード
%   disp(hist.get_script())                      % GUI の操作を再現するスクリプト
%
% 追加ボタン (DrawerOptionDialog.ask のフォーム)、子の表の行のメニューの Remove、Scenario の外乱の
% 追加と削除、パラメータの編集がコードとして記録されること、書き出したスクリプトが別の
% ワークスペースで同じモデルを作ること、ModelChanged の通知を確かめる。見えない uifigure の上で
% 操作し、ask の待ちの間のボタン操作は F50 と同じくタイマーで行う (ask は誰も押さなければ
% 10 秒以内に "" を返すので、止まり続けることはない)。削除の確認 (uiconfirm) は見えない図では出ない。
%
% 実行: runtests("DebugScript.test_F51_model_gui_actions")  または  DebugScript.run_all("Features","F51")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% The default history echoes the code and holds the root variable named after its class
net = network.IEEE9bus;
h = net.a_Bus{2}.launch_gui(uipanel(uifigure("Visible", "off")));
assert(isa(h.history, "HistoryGUILDA") && h.history.get_variable("net") == net)
% A history whose root variable is another model is refused
hist = HistoryGUILDA();
hist.set_variable("net", network.IEEE9bus);
assert(error_id(@() net.launch_gui(uipanel(uifigure("Visible", "off")), History=hist)) == "GUILDA:DrawerModelGUI:OtherRoot")
% A model of another tree, shown by a host with render, has no actions
h = net.launch_gui(uipanel(uifigure("Visible", "off")));
net2 = network.IEEE9bus;
h.render(net2.a_Bus{1});
assert(h.a_target == net2.a_Bus{1} && isempty(findobj(h.h_container, "Type", "uibutton", "Tag", "add")))
c_tab = findobj(h.h_container, "Type", "uihtml", "Tag", "body").Data.tabs;
assert(~any(cellfun(@(q) q.editable, c_tab{1}.panels)) && isempty(findall(h.h_container.Parent, "Type", "uimenu", "Text", "Remove")))


%% Each add button opens the form of its method and runs the code through the history
hist = HistoryGUILDA();
hist.run("Model building", "New network", "net = PowerNetwork();");
net = hist.get_variable("net");
fig = uifigure("Visible", "off");
h = net.launch_gui(uipanel(uigridlayout(fig, [1 1])), History=hist);
assert(isequal(add_buttons(h), ["+ Bus", "+ Branch", "+ Controller", "+ Scenario"]))
count_changed();
c_listener = listener(h, "ModelChanged", @(~, ~) count_changed(1)); %#ok<NASGU>
press_add(h, "+ Bus", "PowerNetwork.add_bus", ["", "Run"]);
press_add(h, "+ Bus", "PowerNetwork.add_bus", ["V", "1.02"; "", "Run"]);
assert(numel(net.a_Bus) == 2 && hist.tab_entry.Code(end) == "net.add_bus(V=1.02);", join(hist.tab_entry.Code + " | " + hist.tab_entry.Detail, " ;; "))
assert(numel(cards(h)) == 2)    % drawn again
% The from_to list holds the bus tags of the network: two are selected
press_add(h, "+ Branch", "PowerNetwork.add_branch", ["Key", "pi"; "from_to", "B001|B002"; "X", "0.1"; "", "Run"]);
assert(isscalar(net.a_Branch) && hist.tab_entry.Code(end) == "net.add_branch(""pi"", [""B001"", ""B002""], X=0.1);", hist.tab_entry.Code(end))
% Bus: a component; Component: an AVR; the AVR: a PSS under it (added to the component)
h.render(net.a_Bus{1});
assert(isequal(add_buttons(h), "+ Component"))
press_add(h, "+ Component", "Bus.add_component", ["Key", "gen-1axis"; "", "Run"]);
h.render(net.a_Bus{2});
press_add(h, "+ Component", "Bus.add_component", ["Key", "load-impedance"; "", "Run"]);
gen = net.a_Bus{1}.a_Component{1};
assert(isa(gen, "component.generator.one_axis") && isscalar(net.a_Bus{2}.a_Component))
h.render(gen);
assert(isequal(add_buttons(h), "+ Controller"))
press_add(h, "+ Controller", "Component.add_local_controller", ["Key", "avr-DC1"; "", "Run"]);
assert(hist.tab_entry.Code(end) == "net.a_Bus{1}.a_Component{1}.add_local_controller(""avr-DC1"");")
h.render(gen.a_LocalController{1});
press_add(h, "+ Controller", "Component.add_local_controller", ["Key", "pss-PSS1"; "", "Run"]);
assert(hist.tab_entry.Code(end) == "net.a_Bus{1}.a_Component{1}.add_local_controller(""pss-PSS1"");")
assert(isscalar(gen.a_LocalController{1}.a_LocalController))
% PowerNetwork: a global controller and a scenario
h.render(net);
press_add(h, "+ Controller", "PowerNetwork.add_global_controller", ["Key", "agc-PI"; "a_Unit", """" + gen.s_tag + """"; "", "Run"]);
press_add(h, "+ Scenario", "PowerNetwork.add_scenario", ["s_tag", "case1"; "", "Run"]);
assert(isscalar(net.a_GlobalController) && isscalar(net.a_Scenario) && net.a_Scenario{1}.s_tag == "case1")
assert(all(hist.tab_entry.Status == "done") && height(hist.tab_entry) == 10)
assert(count_changed() == 9)
% キャンセルは何も実行しない
press_add(h, "+ Bus", "PowerNetwork.add_bus", ["", "Cancel"]);
assert(height(hist.tab_entry) == 10 && count_changed() == 0)


%% A failed add is logged as failed, shows a warning and does not notify ModelChanged
net = network.IEEE9bus;
hist = HistoryGUILDA();
h = net.launch_gui(uipanel(uifigure("Visible", "off")), History=hist);
count_changed();
c_listener = listener(h, "ModelChanged", @(~, ~) count_changed(1)); %#ok<NASGU>
lastwarn("");
DebugScript.helper.quiet(@() press_add(h, "+ Scenario", "PowerNetwork.add_scenario", ["s_tag", "case1"; "Time", "[5 1]"; "", "Run"]));
assert(hist.tab_entry.Status(end) == "fail" && isempty(net.a_Scenario))
assert(contains(lastwarn(), "Add Scenario to"), lastwarn())
assert(count_changed() == 0 && hist.get_script() == "")


%% Remove in the context menu of a row of the child table runs the remove_* method of the parent
net = network.IEEE9bus;
hist = HistoryGUILDA();
h = net.launch_gui(uipanel(uifigure("Visible", "off")), History=hist);
n_bus = numel(net.a_Bus);
s_branch = string(net.a_Branch{end}.s_tag);
remove_card(h, s_branch);
assert(hist.tab_entry.Code(end) == "net.remove_branch(""" + s_branch + """);" && hist.tab_entry.Status(end) == "done")
assert(~any(string(net.a_Branch) == s_branch) && ~any(cellfun(@(c) string(c.s_tag) == s_branch, cards(h))))
% A component of a bus
h.render(net.a_Bus{5});
s_load = string(net.a_Bus{5}.a_Component{1}.s_tag);
remove_card(h, s_load);
assert(hist.tab_entry.Code(end) == "net.a_Bus{5}.remove_component(""" + s_load + """);" && isempty(net.a_Bus{5}.a_Component))
% A local controller with a PSS under it: removed with RemoveNested
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-DC1");
gen.add_local_controller("pss-PSS1");
h.render(gen);
s_avr = string(avr.s_tag);
remove_card(h, s_avr);
assert(endsWith(hist.tab_entry.Code(end), ".remove_local_controller(""" + s_avr + """, RemoveNested=true);"), hist.tab_entry.Code(end))
assert(isscalar(gen.a_LocalController) && gen.a_LocalController{1}.key == "gov-static")   % 調速機の枠は既定の Static
% The PSS row of an AVR is removed from the component
avr = gen.add_local_controller("avr-DC1");
pss = gen.add_local_controller("pss-PSS1");
h.render(avr);
s_pss = string(pss.s_tag);
remove_card(h, s_pss);
assert(hist.tab_entry.Code(end) == "net.a_Bus{1}.a_Component{1}.remove_local_controller(""" + s_pss + """);", hist.tab_entry.Code(end))
assert(isempty(avr.a_LocalController))
% A bus of the network (one without branches)
net.add_bus(FullTag="B010");
h.render(net);
remove_card(h, "B010");
assert(numel(net.a_Bus) == n_bus && hist.tab_entry.Code(end) == "net.remove_bus(""B010"");", hist.tab_entry.Detail(end))
assert(all(hist.tab_entry.Status == "done"))


%% A Scenario: add a fault and an offset with the forms, remove one from its table row
net = network.IEEE9bus;
hist = HistoryGUILDA();
sc = net.add_scenario("case1");
h = sc.launch_gui(uipanel(uifigure("Visible", "off")), History=hist);
assert(isequal(add_buttons(h), ["+ Fault", "+ Trip", "+ Open branch", "+ Offset", "+ Input"]))
% target は網の母線と送電線のタグの一覧
press_add(h, "+ Fault", "Scenario.add_fault", ["target", "B004"; "time", "[1 1.05]"; "", "Run"]);
assert(hist.tab_entry.Code(end) == "net.a_Scenario{1}.add_fault(""B004"", [1 1.05]);", hist.tab_entry.Code(end))
press_add(h, "+ Offset", "Scenario.add_offset", ["unit", "B001SG1"; "state", "delta"; "value", "0.1"; "Tag", "kick"; "", "Run"]);
assert(height(sc.tab_event) == 2 && height(sc.tab_offset) == 1, hist.tab_entry.Detail(end))
% "Remove event" in the menu of a row of an event table (model_body.html sends the tags of the rows)
h_body = findobj(h.h_container, "Type", "uihtml", "Tag", "body");
c_tab = h_body.Data.tabs;
assert(all(cellfun(@(t) t.events, c_tab(1:3))) && ~c_tab{4}.events)
h_body.HTMLEventReceivedFcn(h_body, struct("HTMLEventName", "remove_event", "HTMLEventData", struct("tags", {{'kick'}})));
assert(hist.tab_entry.Code(end) == "net.a_Scenario{1}.remove_event(""kick"");" && height(sc.tab_offset) == 0)
% The removal choices of remove_event are the tags of the scenario
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Scenario.remove_event", fig, Object="net.a_Scenario{1}", History=hist);
h_tag = findall(fig, "Tag", "tag");
assert(isa(h_tag, "matlab.ui.control.ListBox") && isequal(string(h_tag.Items), "Fault001"), join(string(h_tag.Items)))
h_tag.Value = {'Fault001'};
assert(dlg.get_code() == "net.a_Scenario{1}.remove_event(""Fault001"");")


%% A parameter edit is logged as code; an invalid value is refused and restored
net = network.IEEE9bus;
hist = HistoryGUILDA();
h = net.a_Bus{2}.launch_gui(uipanel(uifigure("Visible", "off")), History=hist);
count_changed();
c_listener = listener(h, "ModelChanged", @(~, ~) count_changed(1));
% powerflow has one row: a vertical Name/Value table, whose row is the parameter
edit_cell(h, "powerflow", "V", 1, "1.02");
assert(hist.tab_entry.Code(end) == "net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;", hist.tab_entry.Code(end))
assert(net.a_Bus{2}.tab_parameter.powerflow.V == 1.02 && count_changed() == 1)
n_entry = height(hist.tab_entry);
lastwarn("");
DebugScript.helper.quiet(@() edit_cell(h, "powerflow", "V", 1, "abc"));    % text: refused before any code runs
assert(height(hist.tab_entry) == n_entry && contains(lastwarn(), "Parameter powerflow of B002"), lastwarn())
assert(net.a_Bus{2}.tab_parameter.powerflow.V == 1.02 && count_changed() == 0)
% A value refused by the parameter check is logged as failed
DebugScript.helper.quiet(@() edit_cell(h, "powerflow", "V", 1, "-1"));
assert(hist.tab_entry.Status(end) == "fail" || net.a_Bus{2}.tab_parameter.powerflow.V == -1)
% A table of several rows: the changed row only
agc = net.add_global_controller("agc-PI", {"B001SG1", "B002SG1"});
h.render(agc);
edit_cell(h, "dynamics", "kP", 2, "120");
assert(hist.tab_entry.Code(end) == "net.a_GlobalController{1}.tab_parameter.dynamics.kP(2) = 120;", hist.tab_entry.Code(end))
assert(isequal(agc.tab_parameter.dynamics.kP, [100; 120]))


%% The exported script rebuilds the same model in a fresh workspace
hist = HistoryGUILDA(Header="F51 round trip");
hist.run("Model building", "New network", "net = network.IEEE9bus();");
net = hist.get_variable("net");
h = net.launch_gui(uipanel(uifigure("Visible", "off")), History=hist);
press_add(h, "+ Bus", "PowerNetwork.add_bus", ["FullTag", "B010"; "", "Run"]);
press_add(h, "+ Branch", "PowerNetwork.add_branch", ["Key", "pi"; "from_to", "B009|B010"; "X", "0.2"; "", "Run"]);
remove_card(h, string(net.a_Branch{1}.s_tag));
h.render(net.a_Bus{10});
press_add(h, "+ Component", "Bus.add_component", ["Key", "load-impedance"; "", "Run"]);
edit_cell(h, "powerflow", "V", 1, "0.98");
h.render(net);
press_add(h, "+ Scenario", "PowerNetwork.add_scenario", ["s_tag", "case1"; "", "Run"]);
h.render(net.a_Scenario{1});
press_add(h, "+ Fault", "Scenario.add_fault", ["target", "B010"; "time", "[1 1.1]"; "", "Run"]);
hist.run("Model building", "Bad", "net.no_such_method();");
assert(all(hist.tab_entry.Status(1:end-1) == "done"), join(hist.tab_entry.Detail, newline))
s_file = string(tempname) + ".m";
c_file = onCleanup(@() delete(s_file(isfile(s_file))));
hist.export_script(s_file);
net2 = DebugScript.helper.quiet(@() run_script(s_file));
assert(net2 ~= net)
assert(isequal(string(net2.a_Bus), string(net.a_Bus)) && isequal(string(net2.a_Branch), string(net.a_Branch)))
assert(isequal(string(net2.a_Bus{10}.a_Component), string(net.a_Bus{10}.a_Component)))
assert(net2.a_Bus{10}.tab_parameter.powerflow.V == 0.98)
assert(isequal(string(net2.a_Scenario), "case1") && isequal(net2.a_Scenario{1}.tab_event.Tag, net.a_Scenario{1}.tab_event.Tag))


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function net = run_script(s_file) %#ok<STOUT> net はスクリプトが作る
% 書き出したスクリプトを、このテストと共有しないワークスペースで実行する
    run(s_file);
end

function n = count_changed(n_add)
% ModelChanged の回数を数える (引数なしで呼ぶと回数を返して 0 に戻す)
    persistent n_count
    if isempty(n_count)
        n_count = 0;
    end
    if nargin == 0
        n = n_count;
        n_count = 0;
        return
    end
    n_count = n_count + n_add;
end

function sv = add_buttons(h)
% 追加ボタンの文字 (並んだ順)
    h_add = findobj(h.h_container, "Type", "uibutton", "Tag", "add");
    sv = strings(1, 0);
    if isempty(h_add)
        return
    end
    h_child = h_add(1).Parent.Children;    % 作った順
    h_child = h_child(arrayfun(@(c) c.Tag == "add", h_child));
    sv = string({h_child.Text});
end

function edit_cell(h, s_tag, s_var, i_row, value)
% Parameter タブのセルの編集 (model_body.html が送るイベントの代わり)
    h_body = findobj(h.h_container, "Type", "uihtml", "Tag", "body");
    c_tab = h_body.Data.tabs;
    c_panel = c_tab{1}.panels;
    sct = c_panel{cellfun(@(q) q.tag == s_tag, c_panel)};
    e = struct("HTMLEventName", "edit", "HTMLEventData", struct("index", sct.index, "var", s_var, "row", i_row, "value", value));
    h_body.HTMLEventReceivedFcn(h_body, e);
end

function c_model = cards(h)
% 子の表のすべての種類の子 (種類の順、行の順)。最後に最初の種類に戻す
    c_model = cell(0, 1);
    h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");
    if isempty(h_table)
        return
    end
    h_kind = findobj(h.h_container, "Tag", "kind");
    for k = string(h_kind.ItemsData)
        h_kind.Value = k;
        h_kind.ValueChangedFcn(h_kind, []);
        h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");    % one table per kind of child
        c_model = [c_model; reshape(h_table.UserData, [], 1)]; %#ok<AGROW>
    end
    h_kind.Value = h_kind.ItemsData{1};
    h_kind.ValueChangedFcn(h_kind, []);
end

function press_add(h, s_text, s_signature, sm_step)
% 追加ボタンを押し、開いたフォームでタイマーが欄の入力とボタンの押下を行う
    h_add = findobj(h.h_container, "Type", "uibutton", "Tag", "add", "Text", s_text);
    assert(isscalar(h_add), "button " + s_text)
    t = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, s_signature, sm_step), ...
        "ErrorFcn", @(t, e) set(t, "UserData", "error: " + string(e.Data.message)));
    c_timer = onCleanup(@() delete_timers(t));
    start(t);
    n_entry = height(h.history.tab_entry);
    t_start = tic;
    h_add.ButtonPushedFcn(h_add, []);
    assert(isempty(findall(groot, "Type", "figure", "Name", s_signature)))
    % 実行を押したのに何も記録されないなら、タイマーがダイアログを操作できなかった
    assert(sm_step(end, 2) ~= "Run" || height(h.history.tab_entry) > n_entry, ...
        sprintf("%s: nothing ran after %.1f s (timer pressed: %s)", s_text, toc(t_start), string(t.UserData)))
end

function remove_card(h, s_tag)
% 子の表で s_tag の行を探し、その行のメニューの Remove を選ぶ (見えない図なので確認は出ない)
    h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");
    h_kind = findobj(h.h_container, "Tag", "kind");
    i_row = [];
    for k = string(h_kind.ItemsData)
        h_kind.Value = k;
        h_kind.ValueChangedFcn(h_kind, []);
        h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");    % one table per kind of child
        i_row = find(cellfun(@(c) string(c.s_tag) == s_tag, h_table.UserData));
        if ~isempty(i_row)
            break
        end
    end
    assert(isscalar(i_row), "row " + s_tag)
    h_item = findobj(h_table.ContextMenu, "Text", "Remove");
    h_item.MenuSelectedFcn(h_item, struct("InteractionInformation", struct("Row", i_row)));
end

function press_in_dialog(t, s_name, sm_step)
% ask のダイアログで、欄への入力とボタンの押下を順に行う ([タグ, 値] または ["", ボタンの文字])
% 一覧 (uilistbox) の値は "B001|B002" のように | で区切る。ダイアログができるまでは何もしない
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
            assert(isscalar(h), "field " + sm_step(i, 1))
            if isa(h, "matlab.ui.control.ListBox")
                h.Value = cellstr(split(sm_step(i, 2), "|")).';
            else
                h.Value = char(sm_step(i, 2));
            end
            h.ValueChangedFcn(h, []);
        end
        drawnow
    end
end

function delete_timers(a_timer)
% タイマーを止めて消す
    for t = a_timer
        if isvalid(t)
            stop(t);
            delete(t);
        end
    end
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
