% F76 GUILDA のアプリの速さ (GUILDA.launch_gui, DrawerGUILDA の性能 P1)
%
%   h = GUILDA.launch_gui(net);   % タブごとの系統図、切り替えでは描き直さない
%
% タブごとに自分の系統図 (パネル Tag "diagram_<key>") を持ち、実行記録の実行が終わっていない切り替えでは
% 描き直さないこと、実行の後は表示中のタブだけを描き直し、隠れたタブは次に表示したときに描き直すこと、
% 流れのアニメーション (FlowAnimation) は表示中のタブの図だけが動かすこと、Display options の操作パネルが
% タブごとに切り替わることを確かめる。図を描き直したかどうかは、軸の範囲をわざと変えておき、図が自分で
% 合わせ直したか (plot_diagram は描くたびにパネルへ合わせる) で見る。
% 時間 (large): 切り替え、作成、母線の値の編集のあとの描き直しを、F66 と同じ基準の作業との比で判定する。
% アプリは見えない図 (DrawerGUILDA(..., Visible=false)) に作る。
%
% 実行: runtests("DebugScript.test_F76_guilda_app_speed")  または  DebugScript.run_all("Features","F76")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));
s_visible = get(groot, "DefaultFigureVisible");
set(groot, "DefaultFigureVisible", "off");
c_visible = onCleanup(@() set(groot, "DefaultFigureVisible", s_visible));


%% A tab switch without a run draws nothing; a run draws the active tab and the others on their next show
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
sv_key = ["model", "pf", "opf", "cpf", "sim", "lin"];
for s_key = [sv_key(2:end), "model"]
    select_tab(f, s_key);
end
% 各タブに図のパネルが 1 つずつあり、見えるのは表示中のタブのものだけ
h_panel = arrayfun(@(s) findall(f, "Tag", "diagram_" + s), sv_key);
assert(numel(h_panel) == 6 && isequal(logical([h_panel.Visible]), sv_key == "model"))
c_G = cell(1, 6);
for k = 1:6
    select_tab(f, sv_key(k));
    c_G{k} = h.G;
    assert(isa(h.G, "GraphNetDiagram") && isequal(ancestor(h.G.ax(1), "uipanel"), h_panel(k)), sv_key(k))
    mark(h.G);
end
% 実行なしの切り替え: どの図も描き直されない (範囲はわざと変えたまま、図も同じ)
for k = [2:6, 1]
    select_tab(f, sv_key(k));
    assert(h.G == c_G{k} && is_marked(h.G), "redrawn on a switch: " + sv_key(k))
end
% 実行の後: 表示中のタブ (model) だけを描き直し、ほかは次に表示したときに描き直す
h.history.run("Model building", "Edit V", "net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;");
assert(~is_marked(c_G{1}) && h.G == c_G{1}, "the model tab is not redrawn in place (Graph=G)")
assert(all(cellfun(@is_marked, c_G(2:6))), "a hidden tab was redrawn")
select_tab(f, "lin");
assert(~is_marked(h.G) && h.G == c_G{6})
select_tab(f, "cpf");
assert(~is_marked(h.G) && h.G == c_G{4})    % 系統の図は Graph=G で描き直す
select_tab(f, "pf");
assert(~is_marked(h.G) && h.G == c_G{2})
mark(h.G);
select_tab(f, "lin");
select_tab(f, "pf");
assert(is_marked(h.G))
% 消された図 (delete(G)) は使い続けず、次の実行で新しく描く
select_tab(f, "lin");
G_lin = h.G;
delete(G_lin);
select_tab(f, "pf");
select_tab(f, "lin");    % 実行がなければ描かない (消えた図のまま、エラーにならない)
h.history.run("Model building", "Edit V", "net.a_Bus{2}.tab_parameter.powerflow.V = 1.03;");
assert(isa(h.G, "GraphNetDiagram") && isvalid(h.G) && h.G ~= G_lin)


%% A run redraws the network diagram of the tab in place; the flow animation runs on the active tab only
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
select_tab(f, "pf");
G_net = h.G;
press(findall(f, "Tag", "tab_pf"), "run");
assert(h.G == G_net && h.G.ColorMode == "none", "a run draws into the same network diagram (Graph=G)")
h.history.run("Model building", "Edit V", "net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;");
press(findall(f, "Tag", "tab_pf"), "run");
assert(h.G == G_net && isvalid(G_net))
% 隠れたタブの図は FlowAnimation を止め、表示したときにその値に戻す
G_pf = h.G;
select_tab(f, "model");
G_model = h.G;
assert(~G_pf.FlowAnimation && G_model.FlowAnimation)
G_model.FlowAnimation = false;    % 利用者が止めた値は残る
select_tab(f, "pf");
assert(G_pf.FlowAnimation && ~G_model.FlowAnimation)
select_tab(f, "model");
assert(~G_model.FlowAnimation && ~G_pf.FlowAnimation)


%% Display options keeps a control panel per diagram and shows the one of the active tab
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
h_side = findall(f, "Tag", "diagram").Parent;
h_toggle = findall(f, "Tag", "diagram_controls");
h_toggle.Value = true;
h_toggle.ValueChangedFcn(h_toggle, []);
G_model = h.G;
h_model = G_model.h_controls;
assert(isscalar(h_model) && isgraphics(h_model) && h_model.Visible)
select_tab(f, "lin");
assert(isgraphics(h.G.h_controls) && h.G.h_controls.Visible && ~h_model.Visible)
select_tab(f, "model");
assert(G_model.h_controls == h_model && h_model.Visible && ~findall(f, "Tag", "diagram_lin").Visible)
h.history.run("Model building", "Edit V", "net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;");
assert(G_model.h_controls == h_model && isgraphics(h_model))    % Graph=G の描き直しでパネルは残る
h_toggle.Value = false;
h_toggle.ValueChangedFcn(h_toggle, []);
assert(h_side.ColumnWidth{2} == 0 && isscalar(h_side.Children) && height(h.history.tab_entry) == 1)    % 記録は編集だけ


%% A tab switch, a launch and a redraw after an edit stay fast on IEEE68bus
% 時間の判定 (他のセッションの MATLAB の負荷に左右されないように、F66 と同じ方法):
% - 各回の直前に決まった基準の作業 (隠れた図に 20 行の uilabel と uieditfield を作って drawnow) を測り、
%   1 回目を除いた最小どうしの比で判定する (負荷で両方が同じように遅くなる)。絶対の上限は大きな退行用。
% - 切り替え (6 タブ、目標 0.3 秒): 比 < 4、上限 1 秒。描き直していた頃は IEEE68 で 1 回 1〜4 秒。
% - 作成 (DrawerGUILDA(net, Visible=false)、目標 3 秒は見える図での値): 比 < 120、上限 10 秒。
% - 母線の値の編集の後の描き直し (モデルのタブ、Graph=G): 比 < 20、上限 4 秒。隠れたタブも更新していた頃は比 30 前後。
fig_ref = uifigure("Visible", "off");
c_ref = onCleanup(@() delete(fig_ref));
net = network.IEEE68bus();
sv_key = ["pf", "opf", "cpf", "sim", "lin", "model"];
n_run = 4;
rv_ref = zeros(1, n_run);
rv_launch = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    t_start = tic;
    h = DrawerGUILDA(net, Visible=false);
    drawnow
    rv_launch(r) = toc(t_start);
    if r < n_run
        delete(h.h_figure);
    end
end
check_time("Launch", rv_launch, rv_ref, 120, 10, 3);
f = h.h_figure;
for s_key = sv_key
    select_tab(f, s_key);    % 1 回目はタブを作る
end
n_run = 8;
rv_ref = zeros(1, n_run);
rv_switch = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    s_key = sv_key(mod(r - 1, numel(sv_key)) + 1);
    t_start = tic;
    select_tab(f, s_key);
    drawnow
    rv_switch(r) = toc(t_start);
end
check_time("Tab switch", rv_switch, rv_ref, 4, 1, 0.3);
select_tab(f, "model");
rv_edit = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    t_start = tic;
    h.history.run("Model building", "Edit V", sprintf("net.a_Bus{2}.tab_parameter.powerflow.V = %.3f;", 1 + r/1000));
    drawnow
    rv_edit(r) = toc(t_start);
end
check_time("Edit and redraw", rv_edit, rv_ref, 20, 4, 0.5);


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function select_tab(f, s_key)
% タブのボタンを押す
    h = findall(f, "Tag", "tab", "UserData", s_key);
    h.Value = true;
    h.ValueChangedFcn(h, []);
end

function press(h_parent, s_tag)
% Tag のボタンを押す
    h = findall(h_parent, "Tag", s_tag);
    assert(isscalar(h), "button " + s_tag)
    h.ButtonPushedFcn(h, []);
end

function mark(G)
% 図の軸の範囲をわざと広げる (描き直すと図が範囲を合わせ直すので消える)
    ax = G.ax(1);
    ax.XLim = ax.XLim + [-100 100];
end

function l = is_marked(G)
% mark の範囲が残っている (描き直されていない)
    l = diff(G.ax(1).XLim) > 150;
end

function t = reference_time(fig)
% 決まった基準の作業の時間 (F66 と同じ): 20 行の uilabel と uieditfield の格子を作って描く
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

function check_time(s_name, rv_time, rv_ref, r_ratio, r_limit, r_target)
% 2 回目以降の最小を、基準の最小との比と絶対の上限で判定し、目標との比較を表示する
    r_time = min(rv_time(2:end));
    r_ref  = min(rv_ref(2:end));
    fprintf("F76 %s (IEEE68bus): first %.2f s, second and later min %.3f s (target %.1f s), median %.3f s; reference min %.3f s, ratio %.2f (limit %g)\n", ...
        s_name, rv_time(1), r_time, r_target, median(rv_time(2:end)), r_ref, r_time / r_ref, r_ratio);
    assert(r_time / r_ref < r_ratio, sprintf("%s: %.3f s is %.1f times the reference (%.3f s)", s_name, r_time, r_time / r_ref, r_ref))
    assert(r_time < r_limit, sprintf("%s: %.3f s", s_name, r_time))
end
