% F56 GUILDA のアプリの解析のタブ (潮流計算・最適潮流計算・連続潮流計算・近似線形解析)
%
%   h = DrawerGUILDA(net, Visible=false);   % タブを押す → フォーム → 実行 → 結果を解析
%
% 各タブの実行 (フォームのコードを実行記録で実行し、結果の変数を上書きする)、状態の行、
% 「結果を解析」が同じ実行記録の DrawerResultGUI を開くこと、実行の前後の系統図、
% 古い状態の帯 → initialize、書き出したスクリプトが別のワークスペースで同じ計算を再現することを
% 確かめる。小さな系統 (IEEE9bus) を見えない図で使う。ダイアログは使わない (待ちなし)。
%
% 実行: runtests("DebugScript.test_F56_guilda_app_analysis")  または  DebugScript.run_all("Features","F56")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% Power flow: the form runs calculate_powerflow into res_pf and the diagram stays at the equilibrium
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
select_tab(f, "pf");
h_tab = findall(f, "Tag", "tab_pf");
assert(isempty(findall(h_tab, "Tag", "stale_banner")))
h_form = findall(h_tab, "Tag", "form");
assert(isscalar(findall(h_form, "Tag", "Solver")) && isempty(findall(h_form, "Tag", "Format")))
% フォームは内容の高さだけを取る (行は "fit"。グループの開閉で下の行が追従し、間に空白が残らない)
h_init = findall(h_tab, "Tag", "form_pf_initialize");
assert(isa(h_form, "matlab.ui.container.GridLayout") && string(h_form.RowHeight{1}) == "fit" && string(h_init.RowHeight{1}) == "fit")
assert(all(cellfun(@(c) isequal(string(c), "fit"), h_form.Parent.RowHeight([4 6]))), "form rows")
assert(status_text(h_tab) == "Not run yet." && ~findall(h_tab, "Tag", "analyze").Enable)
% 実行前の図: 母線の種類で色分け、潮流の色なし。帯の 2 行目が色の意味を書く
G = h.G;
assert(isa(G, "GraphNetDiagram") && isequal(bus_color(G, "B001"), [214 39 40] / 255) && isequal(bus_color(G, "B002"), [31 119 180] / 255))
assert(G.ColorMode == "none" && contains(info_text(f), "Bus colors: slack red, PV blue, PQ gray"))
press(h_tab, "run");
tab = h.history.tab_entry;
assert(tab.Code(end) == "[res_pf, flag_pf] = net.calculate_powerflow();" && tab.Status(end) == "done" && tab.Group(end) == "Power flow", tab.Code(end) + " " + tab.Detail(end))
flag = h.history.get_variable("flag_pf");
assert(isa(h.history.get_variable("res_pf"), "ResultPF") && isscalar(flag))
assert(startsWith(status_text(h_tab), "✔ Last run: flag_pf = " + flag + " · ") && endsWith(status_text(h_tab), " s — open Analyze result"), status_text(h_tab))
assert(findall(h_tab, "Tag", "analyze").Enable)
% 実行後の図: 平衡点の系統図のまま (同じ図に描き直し、母線は種類の色、潮流の色なし)。結果は Analyze result で見る
assert(h.G == G && isequal(bus_color(h.G, "B001"), [214 39 40] / 255) && isequal(bus_color(h.G, "B002"), [31 119 180] / 255))
assert(h.G.ColorMode == "none" && contains(info_text(f), "Bus colors: slack red, PV blue, PQ gray"))
assert(contains(info_text(f), "Open Analyze result"))
% 変えたオプションだけを書く。2 回目の結果は同じ変数を上書きする
set_field(h_form, "Solver", "fsolve");
res_old = h.history.get_variable("res_pf");
press(h_tab, "run");
assert(h.history.tab_entry.Code(end) == "[res_pf, flag_pf] = net.calculate_powerflow(Solver=""fsolve"");" || GUILDA.config("PowerFlowCalculation", "Solver") == "fsolve")
assert(h.history.get_variable("res_pf") ~= res_old)
% 失敗は状態の行に出る (変数は前のまま)
set_field(h_form, "MaxIteration", "-1");
press(h_tab, "run");
assert(h.history.tab_entry.Status(end) == "fail" && startsWith(status_text(h_tab), "✖"), status_text(h_tab))
% 平衡点の設定は initialize のフォーム。既定値が文章の欄は空で書かない
h_init = findall(h_tab, "Tag", "form_pf_initialize");
assert(string(findall(h_init, "Tag", "Method").Value) == "powerflow")
assert(string(findall(h_init, "Tag", "Solver").Value) == "" && string(findall(h_init, "Tag", "Tolerance").Value) == "")
h_verbose = findall(h_init, "Tag", "Verbose");
assert(isa(h_verbose, "matlab.ui.control.DropDown") && string(h_verbose.Value) == "")
press(h_tab, "pf_initialize");
assert(h.history.tab_entry.Code(end) == "net.initialize();" && h.history.tab_entry.Status(end) == "done")
set_field(h_init, "Verbose", "false");
set_field(h_init, "Tolerance", "1e-9");
press(h_tab, "pf_initialize");
assert(h.history.tab_entry.Code(end) == "net.initialize(Tolerance=1e-9, Verbose=false);" && h.history.tab_entry.Status(end) == "done", ...
    h.history.tab_entry.Code(end) + " " + h.history.tab_entry.Detail(end))
% モデルのタブに戻ると、種類の色を引き継がない新しい図
select_tab(f, "model");
assert(h.G ~= G && ~isequal(bus_color(h.G, "B001"), [214 39 40] / 255))


%% Analyze result opens a DrawerResultGUI on the history of the app
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
select_tab(f, "pf");
h_tab = findall(f, "Tag", "tab_pf");
press(h_tab, "run");
n_entry = height(h.history.tab_entry);
press(h_tab, "analyze");
h_result = findall(groot, "Type", "figure", "Tag", "result_gui");
assert(isscalar(h_result) && ~h_result.Visible && contains(h_result.Name, "res_pf"))
assert(height(h.history.tab_entry) == n_entry)    % 開くことは記録しない
% 結果の GUI のボタンは同じ記録に入る
h_button = findall(h_result, "Type", "uibutton", "Tag", "method");
h_button = h_button(string({h_button.UserData}) == "ResultPF.disp_summary");
assert(isscalar(h_button))
h_button.ButtonPushedFcn(h_button, []);
assert(h.history.tab_entry.Code(end) == "s_text = res_pf.disp_summary();" + newline + "disp(s_text)" ...
    || startsWith(h.history.tab_entry.Code(end), "s_text = res_pf.disp_summary();"), h.history.tab_entry.Code(end))
assert(h.history.tab_entry.Status(end) == "done")


%% Optimal power flow: res_opf, and the diagram keeps the components with a cost selected
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
select_tab(f, "opf");
h_tab = findall(f, "Tag", "tab_opf");
% 実行前の図: コストのある機器 (発電機) を選択
assert(isa(h.G, "GraphNetDiagram") && all(ismember(["B001SG1", "B002SG1", "B003SG1"], h.G.Selection)) && ~any(contains(h.G.Selection, "LRX")))
set_field(h_tab, "Method", "DC OPF");
press(h_tab, "run");
tab = h.history.tab_entry;
assert(startsWith(tab.Code(end), "[res_opf, flag_opf] = net.calculate_optimal_powerflow(") && tab.Status(end) == "done", tab.Detail(end))
assert(isa(h.history.get_variable("res_opf"), "ResultOPF") && findall(h_tab, "Tag", "analyze").Enable)
% 実行後の図: 同じ系統図のまま、コストのある機器を選択 (LMP の図は Analyze result で見る)
G = h.G;
assert(isa(G, "GraphNetDiagram") && ~contains(G.ColorbarLabel, "LMP") && G.ColorbarLabel == "Branch current |I| [pu]")
assert(all(ismember(["B001SG1", "B002SG1", "B003SG1"], G.Selection)) && ~any(contains(G.Selection, "LRX")))
assert(contains(info_text(f), "Selected: the components with a cost"))


%% Continuation power flow: the stale banner, the default LoadBus and the selected load buses
net = network.IEEE9bus();
h = DrawerGUILDA(net, Visible=false);
f = h.h_figure;
h.history.run("Model building", "Edit V", "net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;");
select_tab(f, "cpf");
h_tab = findall(f, "Tag", "tab_cpf");
h_banner = findall(h_tab, "Tag", "stale_banner");
assert(isscalar(h_banner) && h_banner.Visible)
% LoadBus の初期値は負荷のある母線 (net.solver_CPF.LoadBus が空のため)
assert(string(findall(h_tab, "Tag", "LoadBus").Value) == "[""B005"", ""B006"", ""B008""]")
% 古いまま実行すると失敗し、帯の initialize の後は成功する
press(h_tab, "run");
assert(h.history.tab_entry.Status(end) == "fail")
press(h_banner, "initialize");
assert(h.history.tab_entry.Code(end) == "net.initialize();" && ~h_banner.Visible)
assert(isempty(h.G.Selection))    % 実行前は選択なし
press(h_tab, "run");
tab = h.history.tab_entry;
assert(tab.Code(end) == "[res_cpf, flag_cpf] = net.calculate_continuation_powerflow(LoadBus=[""B005"", ""B006"", ""B008""]);" ...
    && tab.Status(end) == "done", tab.Code(end) + " " + tab.Detail(end))
assert(isa(h.history.get_variable("res_cpf"), "ResultCPF"))
assert(isequal(sort(h.G.Selection(:)), ["B005"; "B006"; "B008"]))


%% Linearization: get_sys at the equilibrium into res_lin
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
select_tab(f, "lin");
h_tab = findall(f, "Tag", "tab_lin");
assert(isscalar(findall(h_tab, "Tag", "stale_banner")) && isscalar(findall(h_tab, "Tag", "point")))
press(h_tab, "run");
tab = h.history.tab_entry;
assert(tab.Code(end) == "[res_lin, flag_lin] = net.get_sys();" && tab.Status(end) == "done", tab.Detail(end))
assert(isa(h.history.get_variable("res_lin"), "ResultLIN") && findall(h_tab, "Tag", "analyze").Enable)
assert(isa(h.G, "GraphNetDiagram"))


%% The exported script repeats the runs of the tabs in a fresh workspace
h = DrawerGUILDA([], Visible=false);
f = h.h_figure;
h_sample = findall(f, "Tag", "start_sample");
h_sample.Value = "IEEE9bus";
press(f, "start_sample_load");
for s_key = ["pf", "cpf", "lin"]
    select_tab(f, s_key);
    press(findall(f, "Tag", "tab_" + s_key), "run");
    assert(h.history.tab_entry.Status(end) == "done", s_key + ": " + h.history.tab_entry.Detail(end))
end
s_file = [tempname, '.m'];
c_file = onCleanup(@() delete(s_file));
h.history.export_script(s_file);
sct = DebugScript.helper.quiet(@() run_script(s_file));
assert(abs(sct.res_pf.tab_bus.V(3) - h.history.get_variable("res_pf").tab_bus.V(3)) < 1e-10)
assert(abs(sct.res_cpf.r_lambdaMax - h.history.get_variable("res_cpf").r_lambdaMax) < 1e-8)
assert(isa(sct.res_lin, "ResultLIN") && sct.flag_lin == h.history.get_variable("flag_lin"))


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function sct = run_script(s_file)
% 書き出したスクリプトを、このテストと共有しないワークスペースで実行し、結果の変数を返す
    run(s_file);
    sct = struct("res_pf", res_pf, "res_cpf", res_cpf, "res_lin", res_lin, "flag_lin", flag_lin);
end

function press(h_parent, s_tag)
% Tag のボタンを押す
    h = findall(h_parent, "Tag", s_tag);
    assert(isscalar(h), "button " + s_tag)
    h.ButtonPushedFcn(h, []);
end

function set_field(h_parent, s_tag, value)
% フォームの欄に値を入れ、ユーザーの操作と同じくコールバックを呼ぶ
    h = findall(h_parent, "Tag", s_tag);
    assert(isscalar(h), "field " + s_tag)
    h.Value = value;
    h.ValueChangedFcn(h, []);
end

function select_tab(f, s_key)
% タブのボタンを押す
    h = findall(f, "Tag", "tab", "UserData", s_key);
    h.Value = true;
    h.ValueChangedFcn(h, []);
end

function s = info_text(f)
% 図の上の情報の帯 (2 行を改行でつなぐ)
    s = join(string(findall(f, "Tag", "info").Text), newline);
end

function s = status_text(h_tab)
% タブの状態の行
    s = string(findall(h_tab, "Tag", "status").Text);
end

function rv = bus_color(G, s_tag)
% 図の母線の色 (BusColor の行)
    rv = G.BusColor(G.tab_element.Index(G.tab_element.Tag == s_tag & G.tab_element.Kind == "bus"), :);
end
