% F52 解析結果の GUI (ResultBase.launch_gui, DrawerResultGUI)
%
%   h = res.launch_gui();                     % 新しい uifigure、HistoryGUILDA(Echo=true)
%   h = res.launch_gui(container, History=hist, Variable="res_pf");
%   h.history.get_script()                    % ボタンで実行したコード
%
% 5 つの結果クラスについて、小さな系統の結果を見えない uifigure に描き、メソッドの一覧
% (functionSignatures.json から作る)、パネルへの描画、disp の文字、get の値、一時フォルダへの
% export、実行記録、書き出したスクリプトを別のワークスペースで実行して新しい図に描き直すことを
% 確かめる。オプションのダイアログ (DrawerOptionDialog.ask) の操作はタイマーで行う
% (ダイアログができるまで 0.2 秒ごとに待つ。誰も押さなければ ask は 10 秒でキャンセルする)。
%
% 実行: runtests("DebugScript.test_F52_result_gui")  または  DebugScript.run_all("Features","F52")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% ResultPF: list, plot with options, disp, export and the script
res = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_powerflow());
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
assert(isa(h, "DrawerResultGUI") && h.a_target == res && h.history.get_variable("res") == res)
% 一覧: functionSignatures.json の ResultPF.plot_* / disp_* / get_* / export を、Plot, Display, Get, Export の順に
sv_method = method_list(fig);
sv_expect = ["plot_voltage", "plot_branch", "plot_convergence", "plot_network", "plot_spring_model", "plot_diagram", ...
             "disp_summary", "disp_bus", "disp_branch", "disp_violation", "get_summary", "export"];
assert(isequal(sv_method, sv_expect), join(sv_method))
h_group = findall(fig, "Tag", "group");
assert(isequal(sort(string({h_group.Text})), ["Display", "Export", "Get", "Plot"]))
assert(findall(fig, "Tag", "status").Text == " success ")
% Readable labels with the method in the tooltip; the default view (not logged): the summary and the first plot
h_button = findall(fig, "Type", "uibutton", "Tag", "method");
sv_label = string({h_button.Text});
assert(all(ismember(["Voltage", "Spring model", "Summary", "Export to file"], sv_label)) && ~any(contains(sv_label, "_")))
assert(all(string({h_button.Tooltip}) == string({h_button.UserData})))
assert(isempty(h.history.tab_entry) && contains(join(string(findall(fig, "Type", "uitextarea", "Tag", "text").Value), newline), "B001"))
h_plot = findall(fig, "Type", "uipanel", "Tag", "plot");
assert(~isempty(findall(h_plot, "Type", "axes")) && findall(fig, "Tag", "view").SelectedTab.Tag == "plot")
assert(contains(findall(fig, "Tag", "summary").Text, "PowerNetwork"))
% plot_voltage: ダイアログで Quantity を選び、パネルに描く
press(fig, "plot_voltage", "ResultPF.plot_voltage", ["Quantity", "angle"; "", "Run"]);
s_code = h.history.tab_entry.Code(end);
assert(s_code == "G = res.plot_voltage(Quantity=""angle"", Parent=h_parent);", s_code)
h_plot = findall(fig, "Type", "uipanel", "Tag", "plot");
assert(isa(h.history.get_variable("G"), "GraphChart") && ancestor(h.history.get_variable("G").ax(1), "uipanel") == h_plot)
% 2 回目の描画は前の図を消す
press(fig, "plot_spring_model", "ResultPF.plot_spring_model", ["", "Run"]);
assert(numel(h_plot.Children) == 1 && isa(h.history.get_variable("G"), "GraphSpring2D"))
% disp_summary: オプションがないのでダイアログなしで実行し、文字欄に出す
press(fig, "disp_summary");
sv_text = string(findall(fig, "Type", "uitextarea", "Tag", "text").Value);
assert(startsWith(sv_text(1), "Power flow of PowerNetwork") && ~any(contains(sv_text, "<a ")), join(sv_text, newline))
assert(h.history.tab_entry.Code(end) == "s_text = res.disp_summary();" + newline + "disp(s_text)")
% export: 見えない図では tempdir のファイル。Table を選ぶ
press(fig, "export", "ResultPF.export", ["Table", "branch"; "", "Run"]);
s_file = h.history.get_variable("s_file");
c_file = onCleanup(@() delete_file(s_file));
assert(isfile(s_file) && startsWith(s_file, string(tempdir)), s_file)
assert(h.history.tab_entry.Code(end) == "s_file = res.export(""" + s_file + """, Table=""branch"");", h.history.tab_entry.Code(end))
assert(any(contains(string(findall(fig, "Type", "uitextarea", "Tag", "text").Value), s_file)))
% 記録: h_parent = [] は最初の描画の前に 1 回だけ
tab = h.history.tab_entry;
assert(isequal(tab.Label', ["Draw the plots in new figures", "plot_voltage", "plot_spring_model", "disp_summary", "export"]), join(tab.Label))
assert(all(tab.Status == "done") && tab.Code(1) == "h_parent = [];" && all(tab.Group == "Result res"))
% スクリプトは別のワークスペースで新しい図に描き直す
check_script(h, res, 2);


%% ResultPF: the buttons whose defaults are several values or empty run
% disp_violation (Class の既定値が配列)、disp_bus・disp_branch・plot_convergence (Bus などの既定値が strings(1,0))
res = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_powerflow());
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
press(fig, "disp_violation", "ResultPF.disp_violation", ["", "Run"]);
press(fig, "disp_bus", "ResultPF.disp_bus", ["Sort", "V"; "", "Run"]);
assert(any(contains(string(findall(fig, "Type", "uitextarea", "Tag", "text").Value), "B001")))
press(fig, "disp_branch", "ResultPF.disp_branch", ["", "Run"]);
press(fig, "plot_convergence", "ResultPF.plot_convergence", ["", "Run"]);
tab = h.history.tab_entry;
assert(all(tab.Status == "done"), join(tab.Detail, newline))
assert(isequal(tab.Code', ["s_text = res.disp_violation();" + newline + "disp(s_text)", ...
    "s_text = res.disp_bus(Sort=""V"");" + newline + "disp(s_text)", "s_text = res.disp_branch();" + newline + "disp(s_text)", ...
    "h_parent = [];", "G = res.plot_convergence(Parent=h_parent);"]), join(tab.Code, " | "))
check_script(h, res, 1);


%% ResultOPF: plot_iteration gives two graphs, get_lmp, disp_summary
res = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_optimal_powerflow(Method="AC OPF"));
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
sv_method = method_list(fig);
assert(isequal(sv_method, ["plot_dispatch", "plot_lmp", "plot_iteration", "disp_summary", "disp_binding", "get_lmp", "get_summary", "export"]), join(sv_method))
% plot_iteration: Parent のほかに入力がないのでダイアログなし。出力の名前は署名から
press(fig, "plot_iteration");
assert(h.history.tab_entry.Code(end) == "[G_chart, G_net] = res.plot_iteration(Parent=h_parent);", h.history.tab_entry.Code(end))
assert(isa(h.history.get_variable("G_chart"), "GraphChart") && isa(h.history.get_variable("G_net"), "GraphNetDiagram"))
h_plot = findall(fig, "Type", "uipanel", "Tag", "plot");
assert(ancestor(h.history.get_variable("G_net").ax, "uipanel", "toplevel") == ancestor(h_plot, "uipanel", "toplevel"))
press(fig, "get_lmp");
sv_text = string(findall(fig, "Type", "uitextarea", "Tag", "text").Value);
assert(sv_text(1) == "tab =" && istable(h.history.get_variable("tab")), join(sv_text, newline))
press(fig, "disp_summary");
assert(numel(string(findall(fig, "Type", "uitextarea", "Tag", "text").Value)) > 2)
% disp_binding (Kind の既定値が配列)
press(fig, "disp_binding", "ResultOPF.disp_binding", ["", "Run"]);
assert(h.history.tab_entry.Code(end) == "s_text = res.disp_binding();" + newline + "disp(s_text)", h.history.tab_entry.Code(end))
assert(all(h.history.tab_entry.Status == "done"))
check_script(h, res, 1);


%% ResultCPF: plot_pvcurve and export
net = network.IEEE9bus();
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=["B005", "B006", "B008"]));
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
assert(isequal(method_list(fig), ["plot_pvcurve", "plot_diagram", "plot_spring_model", "plot_stability_index", ...
    "plot_generator", "plot_branch", "get_point", "export"]), join(method_list(fig)))
press(fig, "plot_pvcurve", "ResultCPF.plot_pvcurve", ["", "Run"]);
assert(h.history.tab_entry.Code(end) == "G = res.plot_pvcurve(Parent=h_parent);", h.history.tab_entry.Code(end))
% export: オプションがないのでダイアログなし
press(fig, "export");
s_file = h.history.get_variable("s_file");
c_file = onCleanup(@() delete_file(s_file));
assert(isfile(s_file) && endsWith(s_file, "_CPF.csv"), s_file)
assert(all(h.history.tab_entry.Status == "done"))
check_script(h, res, 1);


%% ResultODE: plot_trajectory, get_point with a required input, a failed run
net = network.IEEE9bus();
sc = net.add_scenario("fault");
sc.add_fault("B004", [0.1, 0.15]);
res = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 0.5]));
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
assert(isequal(method_list(fig), ["plot_trajectory", "plot_spring_model", "plot_diagram", "get_trajectory", "get_point", "export"]), join(method_list(fig)))
press(fig, "plot_trajectory", "ResultODE.plot_trajectory", ["", "Run"]);
assert(isa(h.history.get_variable("G"), "GraphChart"))
press(fig, "get_point", "ResultODE.get_point", ["t", "0.3"; "", "Run"]);
assert(h.history.tab_entry.Code(end) == "rv = res.get_point(0.3);", h.history.tab_entry.Code(end))
assert(string(findall(fig, "Type", "uitextarea", "Tag", "text").Value{1}) == "rv =")
% 失敗した実行は記録に残り、文字欄にメッセージ、スクリプトには入らない
press(fig, "get_point", "ResultODE.get_point", ["t", "100"; "", "Run"]);
assert(h.history.tab_entry.Status(end) == "fail")
assert(startsWith(string(findall(fig, "Type", "uitextarea", "Tag", "text").Value{1}), "Error in ResultODE.get_point"))
assert(~contains(h.history.get_script(), "get_point(100)"))
% キャンセルは何も実行しない
n_entry = height(h.history.tab_entry);
press(fig, "plot_diagram", "ResultODE.plot_diagram", ["", "Cancel"]);
assert(height(h.history.tab_entry) == n_entry)
check_script(h, res, 1);


%% ResultLIN: plot_eigenvalue and get_ss with a chosen Format
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize());
res = DebugScript.helper.quiet(@() net.get_sys());
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
% ResultBase の export (Unsupported) は署名がないので一覧にない
assert(isequal(method_list(fig), ["plot_eigenvalue", "plot_eigenvalue_path", "disp_summary", "disp_mode", "get_mode", "get_participation", "get_ss", "get_contribution", ...
    "get_eigenvalue", "get_eigenvector", "get_kernel", "get_reduced_matrix"]), join(method_list(fig)))
press(fig, "plot_eigenvalue", "ResultLIN.plot_eigenvalue", ["", "Run"]);
assert(isa(h.history.get_variable("G"), "GraphChart"))
press(fig, "get_ss", "ResultLIN.get_ss", ["", "group_Advanced"; "Format", "struct"; "", "Run"]);    % Format は閉じたグループ Advanced
assert(h.history.tab_entry.Code(end) == "sys = res.get_ss(Format=""struct"");", h.history.tab_entry.Code(end))
assert(isstruct(h.history.get_variable("sys")))
assert(all(h.history.tab_entry.Status == "done"))
check_script(h, res, 1);


%% Embedded in a panel with the history of a host, and a new window
hist = HistoryGUILDA();
hist.run("Power flow", "Calculate", "net = network.IEEE9bus(); res_pf = net.calculate_powerflow();");
res = hist.get_variable("res_pf");
fig = uifigure("Visible", "off");
h_grid = uigridlayout(fig, [1 2]);
uilabel(h_grid, "Text", "host");
p = uipanel(h_grid);
h = res.launch_gui(p, History=hist, Variable="res_pf");
assert(h.history == hist && ~isempty(findall(p, "Tag", "DrawerResultGUI")))
assert(~isempty(findall(fig, "Type", "uilabel", "Text", "host")))
press(fig, "disp_summary");
assert(hist.tab_entry.Code(end) == "s_text = res_pf.disp_summary();" + newline + "disp(s_text)", hist.tab_entry.Code(end))
% 2 つ目の GUI も同じ記録を使い、h_parent = [] は 1 回だけ
res2 = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_powerflow());
hist.set_variable("res_b", res2);
fig2 = uifigure("Visible", "off");
h2 = res2.launch_gui(fig2, History=hist, Variable="res_b");
press(fig, "plot_branch", "ResultPF.plot_branch", ["", "Run"]);
press(fig2, "plot_branch", "ResultPF.plot_branch", ["", "Run"]);
assert(sum(hist.tab_entry.Code == "h_parent = [];") == 1)
% 図はそれぞれの GUI のパネルに描かれる
assert(numel(findall(findall(fig, "Type", "uipanel", "Tag", "plot"), "Type", "axes")) >= 1)
assert(numel(findall(findall(fig2, "Type", "uipanel", "Tag", "plot"), "Type", "axes")) >= 1)
assert(h2.history == hist)
% 変数が別の結果なら止める
try
    res2.launch_gui(fig2, History=hist, Variable="res_pf");
    error("F52:NoError", "an error was expected")
catch ME
    assert(string(DebugScript.helper.msg_id(ME)) == "GUILDA:ResultBase:OtherVariable", ME.message)
end
% figure() は使えない
try
    res.launch_gui(figure("Visible", "off"));
    error("F52:NoError", "an error was expected")
catch ME
    assert(string(DebugScript.helper.msg_id(ME)) == "GUILDA:DrawerResultGUI:NotUIContainer", ME.message)
end
% 容器なしでは新しい uifigure と Echo の記録
a_before = findall(groot, "Type", "figure");
h3 = res.launch_gui();
fig3 = findall(groot, "Type", "figure");
fig3 = fig3(~ismember(fig3, a_before));
fig3.Visible = "off";
assert(isscalar(fig3) && fig3.Name == "ResultPF res" && h3.history.get_variable("res") == res)
assert(startsWith(h3.history.get_script(), "% Actions of the result GUI of ResultPF."), h3.history.get_script())


function sv = method_list(fig)
% GUI のメソッドのボタンの名前 (表示の順)
    h = findall(fig, "Type", "uibutton", "Tag", "method");
    [~, iv] = sort(arrayfun(@(b) b.Layout.Row, h));
    sv = reshape(extractAfter(string({h(iv).UserData}), "."), 1, []);    % the label is readable, UserData is the signature
end

function press(fig, s_method, s_dialog, sm_step)
% メソッドのボタンを押す。s_dialog があれば、そのダイアログの欄の入力とボタンの押下をタイマーで行う
    if nargin > 2
        t = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, s_dialog, sm_step));
        c_timer = onCleanup(@() delete_timer(t));
        start(t);
    end
    h = findall(fig, "Type", "uibutton", "Tag", "method");
    h = h(endsWith(string({h.UserData}), "." + s_method));
    assert(isscalar(h), "button " + s_method)
    h.ButtonPushedFcn(h, []);
end

function press_in_dialog(t, s_name, sm_step)
% ask のダイアログで、欄への入力とボタンの押下を順に行う ([タグ, 値] または ["", ボタンの文字か Tag])
% ダイアログとボタンができるまでは何もせず、タイマーの次の回を待つ。終えたらタイマーを止める
    h_fig = findall(groot, "Type", "figure", "Name", s_name);
    if ~isscalar(h_fig) || isempty(findall(h_fig, "Type", "uibutton", "Text", "Cancel"))
        return
    end
    stop(t);
    for i = 1:size(sm_step, 1)
        if ~isvalid(h_fig)
            return
        end
        % ask は前の呼び出しのフォームを隠したパネルに残すので、欄とグループは表示中のフォームで探す
        h_form = findobj(h_fig.Children(1).Children, "flat", "Type", "uipanel", "Visible", "on");
        if sm_step(i, 1) == ""
            h = findall(h_fig, "Type", "uibutton", "Text", sm_step(i, 2));
            if isempty(h)    % グループの見出し (Tag group_<名前>)
                h = findall(h_form, "Type", "uibutton", "Tag", sm_step(i, 2));
            end
            assert(isscalar(h), "button " + sm_step(i, 2))
            h.ButtonPushedFcn(h, []);
        else
            h = findall(h_form, "Tag", sm_step(i, 1));
            assert(isscalar(h), "field " + sm_step(i, 1))
            h.Value = sm_step(i, 2);
            h.ValueChangedFcn(h, []);
        end
        drawnow
    end
end

function check_script(h, res, n_plot)
% 書き出したスクリプトを、結果だけを置いたワークスペースで実行し、描画の数だけ新しい図ができること
    s_file = string(tempname) + ".m";
    h.history.export_script(s_file);
    c_file = onCleanup(@() delete_file(s_file));
    s_script = string(fileread(s_file));
    assert(contains(s_script, "h_parent = [];") == (n_plot > 0), s_script)
    a_before = findall(groot, "Type", "figure");
    run_script(s_file, res);
    a_new = findall(groot, "Type", "figure");
    a_new = a_new(~ismember(a_new, a_before));
    assert(numel(a_new) == n_plot, "new figures: " + numel(a_new))
    assert(all(arrayfun(@(f) ~isprop(f, "isUIFigure"), a_new)))    % figure() of the plots, not the GUI
end

function run_script(s_file, res) %#ok<INUSD> res はスクリプトが使う
% 書き出したスクリプトを、このテストと共有しないワークスペースで実行する
    evalc("run(s_file)");
end

function delete_file(s_file)
% 一時ファイルを消す
    if isfile(s_file)
        delete(s_file)
    end
end

function delete_timer(t)
% タイマーを止めて消す
    if isvalid(t)
        stop(t);
        delete(t);
    end
end

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end
