% F69 GUI の画面構成と表示 (DrawerGUILDA, DrawerModelGUI, DrawerResultGUI の第3-2b段階)
%
%   h = GUILDA.launch_gui(net);   % 英語の表示、凡例つきの情報の帯、隠せる実行記録、Display options
%
% アプリの文字がすべて英語であること、情報の帯の 2 行目が系統図の色の意味を書くこと、系統図をパネルに
% 合わせること (図自身が合わせ、アプリは範囲を変えない)、実行記録を隠すと系統図が広がること、Display options が図の操作パネルを出すこと、
% モデルの GUI の子の表を同じモデルの描き直しで使い回し、実行の後は作り直すこと、結果の GUI が開いたときに
% 要約と最初の図を記録せずに表示し、操作パネルを出せることを確かめる。図は見えない uifigure に作る。
%
% 実行: runtests("DebugScript.test_F69_gui_layout")  または  DebugScript.run_all("Features","F69")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% All the text of the app is English, also after a power flow
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
for s_key = ["pf", "opf", "cpf", "sim", "lin", "model"]
    select_tab(f, s_key);
end
press(findall(f, "Tag", "tab_pf"), "run");
select_tab(f, "pf");
sv_text = ui_text(f);
% The full-width brackets of the group headings of the log (HistoryGUILDA, not a GUI of this phase) are left out
l_cjk = ~cellfun(@isempty, regexp(erase(sv_text, ["【", "】"]), "[\x3000-\x9FFF\xFF00-\xFFEF]", "once"));
assert(~any(l_cjk), "non-English text: " + join(sv_text(l_cjk), " | "))
assert(isempty(setxor(string({findall(f, "Tag", "tab").Text}), ["Model", "Power flow", "OPF", "CPF", "Time simulation", "Linearization"])))


%% The info strip says what the colors mean, and the diagram is fitted to its panel
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
sv_info = string(findall(f, "Tag", "info").Text);
assert(numel(sv_info) == 2 && contains(sv_info(1), "9 buses") && contains(sv_info(2), "branch current |I| [pu]"))
assert(h.G.ColorbarLabel == "Branch current |I| [pu]")
% The app leaves the limits to the diagram (plot_diagram fits the drawing and its labels): they hold the drawing
ax = h.G.ax(1);
rv_x = ax.XLim;
rv_y = ax.YLim;
axis(ax, "tight");
assert(rv_x(1) <= ax.XLim(1) && rv_x(2) >= ax.XLim(2) && rv_y(1) <= ax.YLim(1) && rv_y(2) >= ax.YLim(2))
% The legend follows the tab; a power flow leaves the diagram and its legend at the equilibrium
select_tab(f, "pf");
assert(contains(findall(f, "Tag", "info").Text{2}, "Bus colors: slack red"))
press(findall(f, "Tag", "tab_pf"), "run");
assert(contains(findall(f, "Tag", "info").Text{2}, "Bus colors: slack red") && h.G.ColorMode == "none")


%% Hide log gives the height of the log to the diagram, Show log brings it back
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
h_left = findall(f, "Tag", "left");
assert(isequal(h_left.RowHeight{2}, "1x") && h_left.RowHeight{4} == 130)
h_toggle = findall(f, "Tag", "log_toggle");
h_toggle.ButtonPushedFcn(h_toggle, []);
assert(h_left.RowHeight{4} == 0 && h_toggle.Text == "Show log" && ~findall(f, "Tag", "log").Visible)
h_toggle.ButtonPushedFcn(h_toggle, []);
assert(h_left.RowHeight{4} == 130 && h_toggle.Text == "Hide log" && findall(f, "Tag", "log").Visible)


%% Display options shows the control panel of the diagram when it declares controls, and logs nothing
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
h_side = findall(f, "Tag", "diagram").Parent;
assert(h_side.ColumnWidth{2} == 0)
h_toggle = findall(f, "Tag", "diagram_controls");
h_toggle.Value = true;
h_toggle.ValueChangedFcn(h_toggle, []);
l_widget = has_widgets(h.G.h_controls);
assert(isequal(h_side.ColumnWidth{2}, 230) == l_widget)
assert(l_widget || contains(findall(f, "Tag", "info").Text{2}, "no display options"))
assert(isempty(h.history.tab_entry))
h_toggle.Value = false;
h_toggle.ValueChangedFcn(h_toggle, []);
assert(h_side.ColumnWidth{2} == 0 && isscalar(h_side.Children))


%% The child table of a model is reused by the next render of that model and built again after a run
hist = HistoryGUILDA();
hist.run("Model building", "Load", "net = network.IEEE9bus();");
net = hist.get_variable("net");
h = net.launch_gui(uipanel(uifigure("Visible", "off")), History=hist);
h_kind = findobj(h.h_container, "Tag", "kind");
assert(string(h_kind.Items{1}) == "Bus (9)", join(string(h_kind.Items)))
h_table = findobj(h.h_container, "Tag", "children");
tab = h_table.Data;
h.render();
h_table = findobj(h.h_container, "Tag", "children");
assert(isequal(h_table.Data, tab))
hist.run("Model building", "Add a bus", "net.add_bus();");
h.render();
assert(string(findobj(h.h_container, "Tag", "kind").Items{1}) == "Bus (10)" && height(findobj(h.h_container, "Tag", "children").Data) == 10)
% The local controllers of a component: rows of that component only (their tags repeat on other components)
l_con = cellfun(@(b) any(cellfun(@(c) ~isempty(c.a_LocalController), b.a_Component)), net.a_Bus);
i_bus = find(l_con, 1, "last");
comp = net.a_Bus{i_bus}.a_Component{find(cellfun(@(c) ~isempty(c.a_LocalController), net.a_Bus{i_bus}.a_Component), 1)};
h.render(comp);
h_table = findobj(h.h_container, "Tag", "children");
assert(isequal(string(h_table.Data.Properties.VariableNames), ["Tag", "Role", "Class"]))
assert(isequal(h_table.Data.Class, reshape(string(cellfun(@class, h_table.UserData, "UniformOutput", false)), [], 1)))
assert(isequal(h_table.Data.Role, reshape(string(cellfun(@(c) c.s_role, h_table.UserData, "UniformOutput", false)), [], 1)))
% A load without controllers: the add button only, in a column as wide as the button
l_load = cellfun(@(b) ~isempty(b.a_Component) && isempty(b.a_Component{1}.a_LocalController), net.a_Bus);
h.render(net.a_Bus{find(l_load, 1)}.a_Component{1});
assert(isempty(findobj(h.h_container, "Tag", "children")) && findobj(h.h_container, "Tag", "add").Text == "+ Controller")
assert(findobj(h.h_container, "Tag", "DrawerModelGUI").ColumnWidth{1} == "fit")


%% The result GUI opens on the summary and the first plot without logging, and shows the plot controls
res = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_powerflow());
fig = uifigure("Visible", "off");
hist = HistoryGUILDA();
hist.set_variable("res_pf", res);
h = res.launch_gui(fig, History=hist, Variable="res_pf");
assert(isempty(hist.tab_entry))
assert(contains(join(string(findall(fig, "Type", "uitextarea", "Tag", "text").Value), newline), "B001"))
assert(~isempty(findall(findall(fig, "Type", "uipanel", "Tag", "plot"), "Type", "axes")))
% The spring model declares controls: Display options puts them right of the plot
h_button = findall(fig, "Type", "uibutton", "Tag", "method");
h_button = h_button(string({h_button.UserData}) == "ResultPF.plot_spring_model");
assert(h_button.Text == "Spring model")
press_with_dialog(h_button, "ResultPF.plot_spring_model");
assert(isa(hist.get_variable("G"), "GraphSpringBase"), "the plot did not run")
h_grid = findall(fig, "Tag", "plot_grid");
assert(h_grid.ColumnWidth{2} == 0)
h_toggle = findall(fig, "Tag", "controls");
h_toggle = h_toggle(arrayfun(@(x) isa(x, "matlab.ui.control.StateButton"), h_toggle));
h_toggle.Value = true;
h_toggle.ValueChangedFcn(h_toggle, []);
assert(h_grid.ColumnWidth{2} == 230 && has_widgets(hist.get_variable("G").h_controls))
n_entry = height(hist.tab_entry);
h_toggle.Value = false;
h_toggle.ValueChangedFcn(h_toggle, []);
assert(h_grid.ColumnWidth{2} == 0 && height(hist.tab_entry) == n_entry)


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

function sv = ui_text(f)
% 図の部品の文字 (Text、Title、Tooltip、Placeholder、Items) をすべて集める
% MATLAB が軸に付けるメニュー (データヒントなど) は MATLAB の言語なので除く
    sv = strings(0, 1);
    h_all = findall(f);
    h_all = h_all(~arrayfun(@(h) isa(h, "matlab.ui.container.Menu") || isa(h, "matlab.ui.container.ContextMenu"), h_all));
    for h = reshape(h_all, 1, [])
        for s_prop = ["Text", "Title", "Tooltip", "Placeholder", "Items"]
            if isprop(h, s_prop)
                value = h.(s_prop);
                if (ischar(value) || isstring(value) || iscellstr(value)) && ~isempty(value)
                    sv = [sv; reshape(string(value), [], 1)]; %#ok<AGROW>
                end
            end
        end
    end
end

function l = has_widgets(h_panel)
% 操作パネルに部品 (ラベルと入れ物のほか) があるか
    l = false;
    if isempty(h_panel) || ~isgraphics(h_panel)
        return
    end
    h_all = findall(h_panel);
    l = any(~arrayfun(@(h) isa(h, "matlab.ui.container.Panel") || isa(h, "matlab.ui.container.GridLayout") ...
        || isa(h, "matlab.ui.control.Label"), h_all));
end

function press_with_dialog(h_button, s_name)
% ボタンを押し、開いた ask のダイアログの実行ボタンをタイマーで押す (F52 と同じ方法)
    t = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_run(t, s_name));
    c_timer = onCleanup(@() delete_timer(t));
    start(t);
    h_button.ButtonPushedFcn(h_button, []);
end

function press_run(t, s_name)
% ask のダイアログの Run を押す (ダイアログとボタンができるまでは何もしない)
    h_fig = findall(groot, "Type", "figure", "Name", s_name);
    if ~isscalar(h_fig) || isempty(findall(h_fig, "Type", "uibutton", "Text", "Cancel"))
        return
    end
    stop(t);
    h_ok = findall(h_fig, "Type", "uibutton", "Text", "Run");
    h_ok(1).ButtonPushedFcn(h_ok(1), []);
end

function delete_timer(t)
    if isvalid(t)
        stop(t);
        delete(t);
    end
end
