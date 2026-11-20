% F75 モデルの GUI の速さ (DrawerModelGUI.render の部品の使い回し、uihtml の本体、列幅)
%
%   h = net.a_Bus{1}.launch_gui(panel);
%   h.render(net.a_Bus{2});       % 部品を作り直さず、文字・子の表・本体の Data を書き換える
%
% 別のモデルへの描き直しが部品を作り直さず、本体 (Parameter タブとページの uihtml) に Data を 1 回送る
% だけであること、作った部品を外した後に付け直すこと、ページの表が列と文字をすべて持つこと、移動と
% 新しい GUI の時間 (基準の作業との比) を確かめる。図は見えない uifigure に作る。
%
% 実行: runtests("DebugScript.test_F75_model_gui_speed")  または  DebugScript.run_all("Features","F75")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));
s_vis = get(groot, "DefaultFigureVisible");
set(groot, "DefaultFigureVisible", "off");
c_vis = onCleanup(@() set(groot, "DefaultFigureVisible", s_vis));


%% A render to another model of the same kind keeps every component and sends the new data in one message
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
fig = uifigure("Visible", "off");
h = net.a_Bus{2}.launch_gui(uipanel(uigridlayout(fig, [1 1])));
h_before = all_components(h);
h_body = findobj(h.h_container, "Type", "uihtml", "Tag", "body");
h.render(net.a_Bus{3});
h_after = all_components(h);
assert(isequal(sort(double(h_before)), sort(double(h_after))), "components made or deleted from bus to bus")
sct = panel_of(h_body, "powerflow");
assert(string(sct.table.rows{string(sct.table.rownames) == "V"}) == compose("%.6g", net.a_Bus{3}.tab_parameter.powerflow.V))
h_label = findobj(h.h_container, "Type", "uilabel");
assert(contains(strjoin(arrayfun(@(l) strjoin(string(l.Text)), h_label)), "B003"))
% A render of the same model sends nothing (the Data did not change)
n_send = h_body.Data.n;
h.render();
assert(h_body.Data.n == n_send)
% The edit goes to the bus shown now
hist = h.history;
h_body.HTMLEventReceivedFcn(h_body, struct("HTMLEventName", "edit", ...
    "HTMLEventData", struct("index", sct.index, "var", "V", "row", 1, "value", "1.0123")));
assert(net.a_Bus{3}.tab_parameter.powerflow.V == 1.0123 && contains(string(hist.tab_entry.Code(height(hist.tab_entry))), "a_Bus{3}"))


%% Parts not needed are hidden or detached and come back: the child table, the add buttons and the tabs
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
sc = net.add_scenario("case1");
fig = uifigure("Visible", "off");
h = net.launch_gui(uipanel(uigridlayout(fig, [1 1])));
h_body = findobj(h.h_container, "Type", "uihtml", "Tag", "body");
h_children = findobj(h.h_container, "Type", "uitable", "Tag", "children");
h.render(net.a_Branch{1});    % no children, no add buttons
assert(isempty(findobj(h.h_container, "Tag", "children")) && isempty(findobj(h.h_container, "Tag", "add")))
assert(findobj(h.h_container, "Tag", "DrawerModelGUI").ColumnWidth{1} == 0)    % the left column is hidden, not removed
h.render(sc);                 % no Parameter tab; the event tables can remove a row
assert(isequal(tab_titles(h_body), ["Events","Offsets","Inputs","Settings"]))
assert(isequal(cellfun(@(t) t.events, h_body.Data.tabs), [true true true false]))
h.render(net);
assert(findobj(h.h_container, "Type", "uitable", "Tag", "children") == h_children)
assert(isequal(findobj(h.h_container, "Tag", "DrawerModelGUI").ColumnWidth, {300, '1x'}))
assert(isequal(tab_titles(h_body), ["Parameter","Summary","Equilibrium"]))
assert(isscalar(findall(fig, "Type", "uicontextmenu")))    % the menu of the child tables only
h_add = findobj(h.h_container, "Type", "uibutton", "Tag", "add");
assert(isequal(sort(string({h_add.Text})), sort(["+ Bus", "+ Branch", "+ Controller", "+ Scenario"])))
% The tab chosen in the page stays selected from one bus to the next, and the first tab otherwise
h.render(net.a_Bus{1});
h_body.HTMLEventReceivedFcn(h_body, struct("HTMLEventName", "select", "HTMLEventData", struct("title", "Equilibrium")));
h.render(net.a_Bus{2});
assert(h_body.Data.selected == "Equilibrium")
h.render(sc);
assert(h_body.Data.selected == "Events")
% A deleted grid (another GUI in the same container) is built again
delete(findobj(h.h_container.Children, "flat", "Tag", "DrawerModelGUI"));
h.render(net.a_Bus{3});
assert(isscalar(findobj(h.h_container.Children, "flat", "Tag", "DrawerModelGUI")) && h.a_target == net.a_Bus{3})


%% The page tables keep every column and the whole text: the page fits the columns to them
% (Scenario の表の列が切れて読めなかった件。model_body.html の表は見出しと中身の幅に合わせ、横にスクロールする)
net = DebugScript.helper.build_ieee14();
sc = net.add_scenario("case1", Description="a description longer than its header");
sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.1], [1,3]);
fig = uifigure("Visible", "off");
h = sc.launch_gui(uipanel(uigridlayout(fig, [1 1])));
h_body = findobj(h.h_container, "Type", "uihtml", "Tag", "body");
c_tab = h_body.Data.tabs;
for k = 1:3    % Events, Offsets, Inputs: the columns of the event tables, also when empty
    tab = h_body.UserData.content{k};
    assert(isequal(string(c_tab{k}.table.cols), string(tab.Properties.VariableNames)) && numel(c_tab{k}.table.rows) == height(tab))
end
assert(isequal(string(c_tab{3}.table.rows{1}), string(h_body.UserData.content{3}{1, :})))
assert(string(c_tab{4}.table.rows{2}{2}) == sc.Description)
s_html = fileread(fullfile(fileparts(which("DrawerModelGUI")), "private", "model_body.html"));
assert(contains(s_html, "white-space: nowrap") && contains(s_html, "overflow-x: auto"))


%% Moving between models and a new GUI take a small multiple of a reference workload on IEEE68bus
% 時間の判定 (F66 と同じ方法。他のセッションの MATLAB の負荷に左右されないように):
% - 各回の直前に決まった基準の作業 (隠れた図に 20 行の uilabel と uieditfield を作って drawnow) を測り、
%   1 回目を除いた最小どうしの比で判定する (負荷で両方が同じように遅くなる)。絶対の上限は大きな退行用。
% - 移動 (母線→母線、→機器、→ネットワーク、→ブランチ) の目標は 0.3 秒、新しい GUI は 0.5 秒 (表示するだけ)。
net = network.IEEE68bus();
DebugScript.helper.quiet(@() net.initialize);
fig = uifigure("Visible", "off");
fig_ref = uifigure("Visible", "off");
c_ref = onCleanup(@() delete(fig_ref));
p = uipanel(uigridlayout(fig, [1 1]));
h = net.a_Bus{1}.launch_gui(p);
drawnow
n_run = 7;
rv_ref = zeros(1, n_run);
rm_move = zeros(4, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    a_model = {net.a_Bus{1 + r}, net.a_Bus{1 + r}.a_Component{1}, net, net.a_Branch{r}};
    for k = 1:4
        t_start = tic;
        h.render(a_model{k});
        drawnow
        rm_move(k, r) = toc(t_start);
    end
end
sv_move = ["bus", "component", "network", "branch"];
for k = 1:4
    check_time("render to a " + sv_move(k), rm_move(k, :), rv_ref, 0.3, 4);
end
rv_new = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    delete(p.Children);
    t_start = tic;
    net.a_Bus{1 + r}.launch_gui(p);
    drawnow
    rv_new(r) = toc(t_start);
end
check_time("new launch_gui", rv_new, rv_ref, 0.5, 8);


function h_all = all_components(h)
% GUI のすべての部品 (コンテナの中と、図に属するコンテキストメニュー)
    h_all = [findall(h.h_container); findall(ancestor(h.h_container, "figure"), "Type", "uicontextmenu")];
    h_all = h_all(h_all ~= h.h_container);
end

function sct = panel_of(h_body, s_tag)
% パラメータのコンテナ s_tag のパネル
    c_panel = h_body.Data.tabs{1}.panels;
    sct = c_panel{cellfun(@(q) q.tag == s_tag, c_panel)};
end

function sv = tab_titles(h_body)
% 本体のタブの題
    sv = string(cellfun(@(t) t.title, h_body.Data.tabs, "UniformOutput", false));
end

function t = reference_time(fig)
% 決まった基準の作業の時間: 20 行の uilabel と uieditfield の格子を作って描く (F66 と同じ)
    t_start = tic;
    g = uigridlayout(fig, [20 2]);
    for k = 1:20
        uilabel(g, "Text", "label " + k);
        uieditfield(g, "text", "Value", string(k));
    end
    drawnow
    t = toc(t_start);
    delete(g);
end

function check_time(s_name, rv_time, rv_ref, r_target, r_ratio)
% 2 回目以降の最小を、基準の最小との比 (r_ratio 未満) と絶対の上限 (1.5 秒) で判定し、目標との比較を表示する
    r_time = min(rv_time(2:end));
    r_ref  = min(rv_ref(2:end));
    fprintf("F75 %s (IEEE68bus): first %.2f s, second and later min %.3f s (target %.1f s), median %.3f s; reference min %.3f s, ratio %.2f\n", ...
        s_name, rv_time(1), r_time, r_target, median(rv_time(2:end)), r_ref, r_time / r_ref);
    assert(r_time / r_ref < r_ratio, sprintf("%s: %.3f s is %.1f times the reference (%.3f s)", s_name, r_time, r_time / r_ref, r_ref))
    assert(r_time < 1.5, sprintf("%s: %.3f s", s_name, r_time))
end

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end
