% F50 GUI の実行記録とオプション入力 (HistoryGUILDA, DrawerOptionDialog)
%
%   h = HistoryGUILDA(Header="...");             % 実行記録 (コード文字列をそのまま eval する)
%   [l_ok, s_detail] = h.run(グループ, ラベル, コード);
%   s = h.get_script();  h.export_script("x.m");
%   dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{1}");
%   s_code = dlg.get_code();
%   s_code = DrawerOptionDialog.ask(fig, "PowerNetwork.calculate_powerflow", Object="net");
%
% 実行の成否と変数の引き継ぎ、スクリプト (失敗の除外・節・ヘッダー)、書き出したスクリプトを
% 別のワークスペースで実行した結果、get_code (既定値の省略・Key の選択肢・GUILDA.config の既定値)、
% 見えない uifigure の上のフォームとモーダルダイアログを確認する。ask の待ち (uiwait) の間の
% ボタン操作はタイマーで行う (ダイアログができるまで 0.2 秒ごとに待つ)。
%
% 実行: runtests("DebugScript.test_F50_gui_history_option")  または  DebugScript.run_all("Features","F50")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% run records a success and a failure without throwing
h = HistoryGUILDA();
[l_ok, s_detail] = h.run("Model", "New network", "net = PowerNetwork();");
assert(l_ok && contains(s_detail, " s)"), s_detail)
[l_ok, s_detail] = h.run("Model", "Bad call", "a = 5; net.no_such_method();");
assert(~l_ok && contains(s_detail, "no_such_method"), s_detail)
assert(isequal(h.tab_entry.Status', ["done", "fail"]))
assert(isequal(h.tab_entry.Properties.VariableNames, {'Group','Label','Code','Status','Detail'}))
assert(isa(h.get_variable("net"), "PowerNetwork"))
% 失敗した実行はワークスペースを変えない
try
    h.get_variable("a");
    error("F50:NoError", "a must not exist")
catch ME
    assert(contains(ME.message, """a"""), ME.message)
end


%% Changed is notified when an entry starts and when it ends
h = HistoryGUILDA();
c_status_push();    % 記録を空にする
l = addlistener(h, "Changed", @(src, ~) c_status_push(src));
h.run("G", "x", "x = 1;");
h.run("G", "y", "error(""F50:Bad"", ""bad"");");
delete(l)
s_log = c_status_push();
assert(isequal(s_log, ["run", "done", "run", "fail"]), join(s_log))


%% Variables carry over between runs and the helper names do not collide
h = HistoryGUILDA();
h.set_variable("k", 3);
assert(h.run("G", "use k", "y = k * 2;"))
assert(h.get_variable("y") == 6)
% run / eval の内部で使いそうな名前もユーザーの変数として使える
assert(h.run("G", "names", "obj = 1; s_code = 2; l_ok = 3; s_detail = 4; i_entry = 5; ME = 6;"))
assert(h.run("G", "read", "z = obj + s_code + l_ok + s_detail + i_entry + ME;"))
assert(h.get_variable("z") == 21)
% 複数行のコードと制御構文
assert(h.run("G", "loop", "w = 0;" + newline + "for q = 1:3" + newline + "    w = w + q;" + newline + "end"))
assert(h.get_variable("w") == 6)
% clear した変数は消える
assert(h.run("G", "clear", "clear w"))
assert(~h.run("G", "use w", "w2 = w;"))
% varargin と varargout は使えない
for s_name = ["varargin", "varargout"]
    try
        h.set_variable(s_name, 1);
        error("F50:NoError", "reserved name accepted")
    catch ME
        assert(contains(ME.message, s_name), ME.message)
    end
end


%% Detail keeps the first lines of the output; Echo prints the code and the output
h = HistoryGUILDA();
[~, s_detail] = h.run("G", "show", "disp(""hello GUILDA"")");
assert(startsWith(s_detail, "hello GUILDA"), s_detail)
[~, s_detail] = h.run("G", "quiet", "x = 1;");
assert(startsWith(s_detail, "done"), s_detail)
% 警告: evalc が付ける "[" char(8) ... "]" char(8) と制御文字を除く (実行記録の一覧にあると exportapp が失敗する)
[~, s_detail] = h.run("G", "warn", "warning(""GUILDA:test:Warn"", ""careful"" + char(9) + ""now"");");
rv_char = double(char(s_detail));
assert(contains(s_detail, "careful") && ~any(rv_char < 32) && ~startsWith(s_detail, "["), s_detail)
s_out = evalc("h.run(""G"", ""show"", ""disp(""""quiet"""")"");");
assert(s_out == "", "Echo=false prints nothing: " + s_out)
h = HistoryGUILDA(Echo=true);    %#ok<NASGU> evalc の中で使う
s_out = string(evalc("h.run(""G"", ""show"", ""x = 1"");"));
assert(contains(s_out, ">> x = 1") && contains(s_out, "x ="), s_out)


%% get_script leaves out failed entries, keeps the order and starts with the header
h = HistoryGUILDA(Header=["Built in the GUILDA GUI", "% already a comment"]);
h.run("Model", "New network", "net = PowerNetwork();");
h.run("Model", "Bad", "net.no_such_method();");
h.run("Model", "Two buses", "net.add_bus();" + newline + "net.add_bus();");
h.run("Power flow", "Size", "n = numel(net.a_Bus);");
h.run("Model", "Third bus", "net.add_bus();");
sv = splitlines(strip(h.get_script(), "right", newline));
sv_expect = ["% Built in the GUILDA GUI"; "% already a comment"; ""
    "%% Model"; "% New network"; "net = PowerNetwork();"; "% Two buses"; "net.add_bus();"; "net.add_bus();"; ""
    "%% Power flow"; "% Size"; "n = numel(net.a_Bus);"; ""
    "%% Model"; "% Third bus"; "net.add_bus();"];
assert(isequal(sv, sv_expect), join(sv, newline))
assert(~contains(h.get_script(), "no_such_method"))
% 失敗した記録は表には残る
assert(sum(h.tab_entry.Status == "fail") == 1)
assert(HistoryGUILDA().get_script() == "")


%% export_script writes a script that rebuilds the network in a fresh workspace
h = HistoryGUILDA(Header="F50 round trip");
fig = uifigure("Visible", "off");
h.run("Model", "New network", "net = PowerNetwork();");
h.run("Model", "Buses", "net.add_bus(V=1.02);" + newline + "net.add_bus();");
dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{2}", Output="comp", Exclude="parameter");
set_field(fig, "Key", "load-power");
set_field(fig, "P", "-0.5");
s_code = dlg.get_code();
assert(s_code == "comp = net.a_Bus{2}.add_component(""load-power"", P=-0.5);", s_code)
assert(h.run("Model", "Load", s_code))
h.run("Model", "Bad", "net.add_bus(NoSuchOption=1);");
s_file = string(tempname) + ".m";
c_file = onCleanup(@() delete(s_file(isfile(s_file))));
h.export_script(s_file);
assert(string(fileread(s_file, "Encoding", "UTF-8")) == h.get_script())
net = run_script(s_file);
net_gui = h.get_variable("net");
assert(numel(net.a_Bus) == 2 && numel(net.a_Bus) == numel(net_gui.a_Bus))
assert(net.a_Bus{1}.tab_parameter.powerflow.V == 1.02)
assert(isscalar(net.a_Bus{2}.a_Component) && isa(net.a_Bus{2}.a_Component{1}, class(net_gui.a_Bus{2}.a_Component{1})))
assert(net.a_Bus{2}.a_Component{1}.tab_parameter.powerflow.P == -0.5)
try
    h.export_script(string(tempname) + ".txt");
    error("F50:NoError", "a .txt file was accepted")
catch ME
    assert(contains(ME.message, ".m"), ME.message)
end


%% attach_view shows each entry and its code lines and follows Changed
h = HistoryGUILDA();
fig = uifigure("Visible", "off");
h_list = h.attach_view(fig);
assert(isa(h_list, "matlab.ui.control.ListBox") && isscalar(h_list.Items))
h.run("Model", "New network", "net = PowerNetwork();");
h.run("Model", "Bad", "net.no_such_method();");
h.run("Power flow", "Buses", "n = 1;" + newline + "m = 2;");
sv = string(h_list.Items(:));
assert(numel(sv) == 9 && isequal(sv([1 3 5 6]), ["【Model】"; "    >> net = PowerNetwork();"; "    >> net.no_such_method();"; "【Power flow】"]), join(sv, newline))
assert(startsWith(sv(2), "✔ New network  → ") && startsWith(sv(4), "✖ Bad  → "))
assert(startsWith(sv(7), "✔ Buses  → ") && isequal(sv(8:9), ["    >> n = 1;"; "    >> m = 2;"]))
% グリッドのセルにも置ける。図を閉じたあとの実行は描画しない
g = uigridlayout(uifigure("Visible", "off"), [1 2]);
uilabel(g, "Text", "host");
h_list2 = h.attach_view(g);
assert(h_list2.Parent == g && numel(h_list2.Items) == numel(sv))
delete(fig)
assert(h.run("Model", "After close", "k = 1;"))
assert(numel(h_list2.Items) == numel(sv) + 3)    % 【Model】、見出し、コード
try
    h.attach_view(figure("Visible", "off"));
    error("F50:NoError", "figure() was accepted")
catch ME
    assert(contains(ME.message, "uifigure"), ME.message)
end


%% get_code leaves out the defaults and offers the model keys
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", Output="comp", Exclude=["parameter", "OPFcost_startup"]);
h_key = findall(fig, "Tag", "Key");
assert(isa(h_key, "matlab.ui.control.DropDown"))
assert(isequal(sort(string(h_key.Items)), sort(keys(GUILDA.keymap("Component"))).'))
assert(isempty(findall(fig, "Tag", "parameter")) && isempty(findall(fig, "Tag", "OPFcost_startup")))
assert(dlg.get_code() == "comp = net.a_Bus{3}.add_component(""" + string(h_key.Items{1}) + """);")
set_field(fig, "Key", "gen-park");
set_field(fig, "P", "0.5");
assert(isempty(findall(fig, "Tag", "Shape")))    % 閉じたグループの欄は開いたときに作る
open_group(fig, "Graph");
set_field(fig, "Shape", "^");
assert(dlg.get_code() == "comp = net.a_Bus{3}.add_component(""gen-park"", P=0.5, Shape=""^"");", dlg.get_code())
% 既定値に戻すと書かない。Inf や NaN の既定値も比べる
set_field(fig, "P", "0");
open_group(fig, "Limits");
set_field(fig, "Pmax", "Inf");
set_field(fig, "DX", "NaN");
assert(dlg.get_code() == "comp = net.a_Bus{3}.add_component(""gen-park"", Shape=""^"");", dlg.get_code())
% 出力なし・複数の出力
dlg = DrawerOptionDialog("PowerNetwork.add_bus", uifigure("Visible", "off"), Object="net");
assert(dlg.get_code() == "net.add_bus();")
dlg = DrawerOptionDialog("PowerNetwork.simulate", uifigure("Visible", "off"), Object="net", Output=["res", "flag"]);
assert(dlg.get_code() == "", "s_scenario is required")


%% Invalid values show a message in the form and give no code
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.simulate", fig, Object="net", Output="res");
h_message = findall(fig, "Type", "uilabel", "FontColor", tools.gui_palette().rv_stale_text);
assert(isscalar(h_message))
set_field(fig, "s_scenario", "sc1");
set_field(fig, "Time", "[0 10]");
assert(dlg.get_code() == "res = net.simulate(""sc1"", Time=[0 10]);", dlg.get_code())
assert(h_message.Text == "")
h_tol = findall(fig, "Tag", "Tolerance");
h_tol.Value = "abc";
h_tol.ValueChangedFcn(h_tol, []);    % コールバックはエラーを投げずにメッセージを出す
assert(contains(h_message.Text, "Tolerance") && dlg.get_code() == "")
assert(isequal(h_tol.BackgroundColor, tools.gui_palette().rv_stale_back))
set_field(fig, "Tolerance", "1e-6");
assert(h_message.Text == "" && contains(dlg.get_code(), "Tolerance=1e-6"))
set_field(fig, "s_scenario", "");
assert(dlg.get_code() == "" && contains(h_message.Text, "s_scenario"))
% 知らないシグネチャ、Object なし
for c_bad = {{"PowerNetwork.no_such_method", fig, "Object", "net"}, {"Bus.add_component", fig}}
    try
        DrawerOptionDialog(c_bad{1}{:});
        error("F50:NoError", "accepted")
    catch ME
        assert(contains(ME.message, ["no_such_method", "Object"]), ME.message)
    end
end


%% Options of the analysis methods start from GUILDA.config and are left out while unchanged
c_cfg = DebugScript.helper.user_config("PowerFlowCalculation", struct("Solver", "fsolve", "Tolerance", 1e-7)); %#ok<NASGU>
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.calculate_powerflow", fig, Object="net", Output="res_pf");
assert(dlg.get_code() == "res_pf = net.calculate_powerflow();", dlg.get_code())
assert(string(findall(fig, "Tag", "Solver").Value) == "fsolve")
assert(str2double(findall(fig, "Tag", "Tolerance").Value) == 1e-7)
h_verbose = findall(fig, "Tag", "Verbose");
assert(isa(h_verbose, "matlab.ui.control.CheckBox") && h_verbose.Value == GUILDA.config("PowerFlowCalculation", "Verbose"))
set_field(fig, "Solver", "newton");
h_verbose.Value = ~h_verbose.Value;
assert(dlg.get_code() == "res_pf = net.calculate_powerflow(Solver=""newton"", Verbose=" + mat2str(h_verbose.Value) + ");", dlg.get_code())
% PlotFcn (型なし) は MATLAB の式の欄で、設定値の文字列を表示する (グループ Advanced)
open_group(fig, "Advanced");
assert(string(findall(fig, "Tag", "PlotFcn").Value) == """" + string(GUILDA.config("PowerFlowCalculation", "PlotFcn")) + """")
clear c_cfg
% OPF も同じ
dlg = DrawerOptionDialog("PowerNetwork.calculate_optimal_powerflow", uifigure("Visible", "off"), Object="net", Output="res");
assert(dlg.get_code() == "res = net.calculate_optimal_powerflow();", dlg.get_code())


%% Defaults of several values, an empty string default and a form without fields
% choices の既定値が配列: 複数を選べる一覧で、既定の値をすべて選んだ状態 (変えなければ書かない)
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("ResultPF.disp_violation", fig, Object="res", Output="s_text");
h_class = findall(fig, "Tag", "Class");
assert(isa(h_class, "matlab.ui.control.ListBox") && isequal(string(h_class.Value), ["Bus", "Component", "Branch"]))
assert(dlg.get_code() == "s_text = res.disp_violation();", dlg.get_code())
h_class.Value = {'Bus'};
assert(dlg.get_code() == "s_text = res.disp_violation(Class=""Bus"");", dlg.get_code())
h_class.Value = {'Bus', 'Branch'};
assert(dlg.get_code() == "s_text = res.disp_violation(Class=[""Bus"", ""Branch""]);", dlg.get_code())
h_class.Value = {};
assert(dlg.get_code() == "s_text = res.disp_violation(Class=strings(1,0));", dlg.get_code())
dlg = DrawerOptionDialog("ResultOPF.disp_binding", uifigure("Visible", "off"), Object="res");
assert(dlg.get_code() == "res.disp_binding();", dlg.get_code())
% 文字列の既定値が空 (strings(1,0)): 空の欄 (既定値どおりなので文章のヒントもない)
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("ResultPF.disp_bus", fig, Object="res");
h_bus = findall(fig, "Tag", "Bus");
assert(isa(h_bus, "matlab.ui.control.EditField") && string(h_bus.Value) == "" && isempty(findall(fig, "Tag", "hint_Bus")))
assert(dlg.get_code() == "res.disp_bus();", dlg.get_code())
set_field(fig, "Bus", "B003");
assert(dlg.get_code() == "res.disp_bus(Bus=""B003"");", dlg.get_code())
for s_sig = ["ResultPF.disp_branch", "ResultPF.plot_convergence"]
    dlg = DrawerOptionDialog(s_sig, uifigure("Visible", "off"), Object="res", Exclude="Parent");
    assert(dlg.get_code() == "res." + extractAfter(s_sig, ".") + "();", dlg.get_code())
end
% 欄のないシグネチャ (obj だけ、または Exclude で全部を除く)
dlg = DrawerOptionDialog("ResultPF.disp_summary", uifigure("Visible", "off"), Object="res", Output="s_text");
assert(dlg.get_code() == "s_text = res.disp_summary();", dlg.get_code())
dlg = DrawerOptionDialog("ResultOPF.plot_iteration", uifigure("Visible", "off"), Object="res", Output=["G_chart", "G_net"], Exclude="Parent");
assert(dlg.get_code() == "[G_chart, G_net] = res.plot_iteration();", dlg.get_code())
% add_branch の from_to (既定値 [1,2]): History なしでも、母線のタグの一覧でも作れる
dlg = DrawerOptionDialog("PowerNetwork.add_branch", uifigure("Visible", "off"), Object="net");
assert(startsWith(dlg.get_code(), "net.add_branch("""), dlg.get_code())
h = HistoryGUILDA();
h.set_variable("net", network.IEEE9bus());
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.add_branch", fig, Object="net", History=h);
h_from_to = findall(fig, "Tag", "from_to");    % タグの欄と Select... (既定値 [1,2] は番号なので空の欄とヒント)
assert(isa(h_from_to, "matlab.ui.control.EditField") && string(h_from_to.Value) == "" && h_from_to.Placeholder == "default: [1,2]")
assert(isscalar(findall(fig, "Tag", "select_from_to")))
assert(startsWith(dlg.get_code(), "net.add_branch("""), dlg.get_code())


%% Value shows initial values; the call compares them with the default
% 必須の入力は常に書く。オプションは既定値と違うときだけ書く (Value で渡しただけでも書く)
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.simulate", fig, Object="net", Output=["res", "flag"], ...
    Value=struct("s_scenario", """case1""", "Time", "[0 5]", "Solver", """ode23t""", "Verbose", "true"));
assert(string(findall(fig, "Tag", "s_scenario").Value) == "case1")
assert(string(findall(fig, "Tag", "Time").Value) == "[0 5]")
assert(string(findall(fig, "Tag", "Solver").Value) == "ode23t")
assert(findall(fig, "Tag", "Verbose").Value)
s_expect = "[res, flag] = net.simulate(""case1"", Time=[0 5], Solver=""ode23t""";
if ~GUILDA.config("TimeSimulation", "Verbose")
    s_expect = s_expect + ", Verbose=true";
end
assert(dlg.get_code() == s_expect + ");", dlg.get_code())
% 既定値と同じ値を渡すと書かない
dlg = DrawerOptionDialog("PowerNetwork.calculate_powerflow", uifigure("Visible", "off"), Object="net", ...
    Value=struct("Format", """GUILDAorigin""", "Tolerance", mat2str(GUILDA.config("PowerFlowCalculation", "Tolerance"))));
assert(dlg.get_code() == "net.calculate_powerflow();", dlg.get_code())
% タグの一覧 (History あり): 渡したタグを選ぶ。一覧にないタグは一覧に加える
h = HistoryGUILDA();
h.set_variable("net", network.IEEE9bus());
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.add_branch", fig, Object="net", History=h, Value=struct("from_to", "[""B002"", ""B004""]"));
assert(string(findall(fig, "Tag", "from_to").Value) == "B002, B004")
assert(contains(dlg.get_code(), "[""B002"", ""B004""]"), dlg.get_code())
fig = uifigure("Visible", "off");
DrawerOptionDialog("PowerNetwork.simulate", fig, Object="net", History=h, Value=struct("s_scenario", """new"""));
assert(string(findall(fig, "Tag", "s_scenario").Value) == "new")
% シナリオがないとき (候補が空の必須の入力) は、Value がなければ空のドロップダウンで、コードは作らない
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.simulate", fig, Object="net", History=h);
assert(string(findall(fig, "Tag", "s_scenario").Value) == "" && dlg.get_code() == "")
% 知らない入力名と、欄に表示できない値はエラー
for c_bad = {struct("NoSuchInput", "1"), struct("Verbose", """abc"""), struct("Solver", "[1 2]")}
    try
        DrawerOptionDialog("PowerNetwork.calculate_powerflow", uifigure("Visible", "off"), Object="net", Value=c_bad{1});
        error("F50:NoError", "accepted")
    catch ME
        assert(ismember(string(DebugScript.helper.msg_id(ME)), ["GUILDA:DrawerOptionDialog:UnknownValue", "GUILDA:DrawerOptionDialog:InvalidValue"]), ME.message)
    end
end


%% A text default gives an empty field that is left out; string arrays in an expression field
% get_sys の Input (Default: all inputs.) は空の欄で、横に文章のヒント (グループ Advanced)
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerSystemModel.get_sys", fig, Object="net", Output=["res_lin", "flag_lin"], Exclude="Format");
open_group(fig, "Advanced");
h_input = findall(fig, "Tag", "Input");
assert(string(h_input.Value) == "" && contains(findall(fig, "Tag", "hint_Input").Tooltip, "all inputs"))
assert(string(findall(fig, "Tag", "point").Value) == "[]")
assert(dlg.get_code() == "[res_lin, flag_lin] = net.get_sys();", dlg.get_code())
% 既定値が文章の logical (initialize の Verbose) は "", "true", "false" の一覧で、"" は書かない
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.initialize", fig, Object="net", Value=struct("WarmStart", "true"));
h_verbose = findall(fig, "Tag", "Verbose");
assert(isa(h_verbose, "matlab.ui.control.DropDown") && isequal(string(h_verbose.Items), ["", "true", "false"]) && string(h_verbose.Value) == "")
assert(string(findall(fig, "Tag", "Solver").Value) == "" && string(findall(fig, "Tag", "MaxIteration").Value) == "")
assert(dlg.get_code() == "net.initialize(WarmStart=true);", dlg.get_code())
set_field(fig, "Verbose", "false");
set_field(fig, "WarmStart", "");
assert(dlg.get_code() == "net.initialize(Verbose=false);", dlg.get_code())
% CPF の LoadBus (Default: obj.solver_CPF.LoadBus): 空なら空の欄、文字列の配列なら ["B005", "B006"]
h = HistoryGUILDA();
net = network.IEEE9bus();
h.set_variable("net", net);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.calculate_continuation_powerflow", fig, Object="net", History=h);
assert(string(findall(fig, "Tag", "LoadBus").Value) == "" && dlg.get_code() == "net.calculate_continuation_powerflow();", dlg.get_code())
net.solver_CPF.LoadBus = ["B005", "B006"];
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.calculate_continuation_powerflow", fig, Object="net", History=h);
assert(string(findall(fig, "Tag", "LoadBus").Value) == "[""B005"", ""B006""]" && dlg.get_code() == "net.calculate_continuation_powerflow();", dlg.get_code())


%% A scalar tag input is a dropdown; a tag input without scalar takes several tags
% 実物の functionSignatures.json ("scalar" あり) で確かめる。"scalar" がある間は当面の規則
% (既定値が 1 つの string の Name-Value で 2 つ以上を選ぶと止まる) は使わない
net = network.IEEE9bus();
sc = net.add_scenario("fault");
sc.add_fault("B004", [0.1, 0.15]);
res = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 0.2]));
h = HistoryGUILDA();
h.set_variable("res", res);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("ResultODE.plot_trajectory", fig, Object="res", Exclude="Parent", History=h);
% Quantity ("scalar"): ドロップダウン
h_quantity = findall(fig, "Tag", "Quantity");
assert(isa(h_quantity, "matlab.ui.control.DropDown") && string(h_quantity.Value) == "Vabs" && ismember("P", string(h_quantity.Items)))
set_field(fig, "Quantity", "P");
assert(dlg.get_code() == "res.plot_trajectory(Quantity=""P"");", dlg.get_code())
% Bus ("scalar" なし、既定値 "all"): 複数を選べる一覧で、2 つ選んでも止まらない
h_bus = findall(fig, "Tag", "Bus");
assert(isa(h_bus, "matlab.ui.control.ListBox") && string(h_bus.Multiselect) == "on")
h_bus.Value = {'B001', 'B002'};
assert(dlg.get_code() == "res.plot_trajectory(Quantity=""P"", Bus=[""B001"", ""B002""]);", dlg.get_code())
% "scalar" の付いた数値 (add_component の P) はこれまでどおり数値の欄
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", Exclude="parameter");
h_p = findall(fig, "Tag", "P");
assert(isa(h_p, "matlab.ui.control.EditField") && string(h_p.Value) == "0")
set_field(fig, "P", "0.5");
assert(endsWith(dlg.get_code(), ", P=0.5);"), dlg.get_code())
% Scenario のタグの入力 (add_offset の unit、"scalar") もドロップダウン
h.set_variable("sc", sc);
fig = uifigure("Visible", "off");
DrawerOptionDialog("Scenario.add_offset", fig, Object="sc", History=h);
assert(isa(findall(fig, "Tag", "unit"), "matlab.ui.control.DropDown"))


%% ask returns the code of Run and "" on Cancel
fig = uifigure("Visible", "off");
% 実行: まず無効な値で押し (ダイアログは閉じない)、直してから押す
t_run = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, "Bus.add_component", ["P", "abc"; "", "Run"; "P", "0.5"; "", "Run"]));
c_timer = onCleanup(@() delete_timers(t_run));
start(t_run);
s_code = DrawerOptionDialog.ask(fig, "Bus.add_component", Object="net.a_Bus{1}", Output="comp", Exclude="parameter");
assert(startsWith(s_code, "comp = net.a_Bus{1}.add_component(") && endsWith(s_code, ", P=0.5);"), "code: " + s_code)
assert(isempty(findall(groot, "Type", "figure", "Name", "Bus.add_component")))
% キャンセル
t_cancel = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, "PowerNetwork.calculate_powerflow", ["Solver", "fsolve"; "", "Cancel"]));
c_timer2 = onCleanup(@() delete_timers(t_cancel));
start(t_cancel);
s_code = DrawerOptionDialog.ask(fig, "PowerNetwork.calculate_powerflow", Object="net", Output="res_pf");
assert(s_code == "", "code: " + s_code)
assert(isempty(findall(groot, "Type", "figure", "Name", "PowerNetwork.calculate_powerflow")))


%% ask on a hidden figure that nobody answers returns "" after at most 10 s
fig = uifigure("Visible", "off");
t_start = tic;
s_code = DrawerOptionDialog.ask(fig, "PowerNetwork.add_bus", Object="net");
assert(s_code == "" && toc(t_start) < 20, "code: " + s_code)
assert(isempty(findall(groot, "Type", "figure", "Name", "PowerNetwork.add_bus")))


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function open_group(fig, s_name)
% グループの見出しを押して開く
    h = findall(fig, "Tag", "group_" + replace(s_name, " ", "_"));
    assert(isscalar(h), "group " + s_name)
    h.ButtonPushedFcn(h, []);
end

function set_field(fig, s_tag, value)
% フォームの欄に値を入れ、ユーザーの操作と同じくコールバックを呼ぶ
    h = findall(fig, "Tag", s_tag);
    assert(isscalar(h), "field " + s_tag)
    h.Value = value;
    h.ValueChangedFcn(h, []);
end

function net = run_script(s_file) %#ok<STOUT> net はスクリプトが作る
% 書き出したスクリプトを、このテストと共有しないワークスペースで実行する
    run(s_file);
end

function sv = c_status_push(src)
% Changed の通知ごとの最後の状態を記録する (引数なしで呼ぶと記録を返して消す)
    persistent sv_log
    if nargin == 0
        sv = sv_log;
        sv_log = strings(1, 0);
        return
    end
    if isempty(sv_log)
        sv_log = strings(1, 0);
    end
    sv_log(end+1) = src.tab_entry.Status(end);
end

function press_in_dialog(t, s_name, sm_step)
% ask のダイアログで、欄への入力とボタンの押下を順に行う ([タグ, 値] または ["", ボタンの文字])
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
        if sm_step(i, 1) == ""
            h = findall(h_fig, "Type", "uibutton", "Text", sm_step(i, 2));
            h.ButtonPushedFcn(h, []);
        else
            set_field(h_fig, sm_step(i, 1), sm_step(i, 2));
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
