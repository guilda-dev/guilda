% F87 ほかの入力に依存する選択肢・既定値のフォーム (DrawerOptionDialog)
%
%   dlg = DrawerOptionDialog("Scenario.add_input", fig, Object="sc", History=h);
%   s_code = dlg.get_code();
%
% choices= の式がほかの入力を参照するとき (Scenario.add_input の name が unit を、EventInput.edit の
% Name が Unit の既定値 obj.s_unit を参照する)、その入力の今の値で選択肢を作り、その入力が変わった
% ときだけ作り直すこと (残せる選択は残す、unit が空のときは項目なしで "Select unit first")、
% PowerNetwork.add_scenario の Time ("From.Time, else [0, 10]") が From が空なら [0 10]、From が
% 変数なら From.Time、評価できなければ空欄とヒントになり、既定のままなら Time を書かないこと、
% add_trip と add_open_branch が 1 つの時刻を取り正しいコードを書くことを確かめる。
%
% 実行: runtests("DebugScript.test_F87_gui_dependent_forms")  または  DebugScript.run_all("Features","F87")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% add_input lists the input names of the chosen unit and keeps the names still among them
net = network.IEEE9bus();
sc = net.add_scenario("case1");
h = history_with(net, "sc", sc);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Scenario.add_input", fig, Object="sc", History=h);
h_unit = findall(fig, "Tag", "unit");
h_name = findall(fig, "Tag", "name");
s_gen  = string(h_unit.Value);    % 最初の機器 (同期発電機)
s_load = string(net.a_Bus{5}.a_Component{1});
assert(isa(h_name, "matlab.ui.control.ListBox"), class(h_name))
assert(isequal(string(h_name.Items), net.get_element(s_gen).sv_u(:)'), join(string(h_name.Items)))
assert(string(findall(fig, "Tag", "hint_name").Text) == "")
set_field(fig, "name", {'Pmech'});
set_field(fig, "value", "0.1");
set_field(fig, "time", "[1 2]");
assert(dlg.get_code() == "sc.add_input(""" + s_gen + """, ""Pmech"", 0.1, [1 2]);", dlg.get_code())
% unit を変えると name の選択肢だけを作り直し、なくなった名前は外れる
set_field(fig, "unit", char(s_load));
assert(isequal(string(h_name.Items), net.get_element(s_load).sv_u(:)'), join(string(h_name.Items)))
assert(isempty(h_name.Value) && dlg.get_code() == "", dlg.get_code())    % name は必須
set_field(fig, "name", {'R'});
assert(dlg.get_code() == "sc.add_input(""" + s_load + """, ""R"", 0.1, [1 2]);", dlg.get_code())
% 同じ名前を持つ機器に変えると選択は残る
s_gen2 = string(net.a_Bus{2}.a_Component{1});
set_field(fig, "unit", char(s_gen));
set_field(fig, "name", {'Pmech', 'Vfield'});
set_field(fig, "unit", char(s_gen2));
assert(isequal(string(h_name.Value), ["Pmech", "Vfield"]), join(string(h_name.Value)))
% ほかの欄を変えても選択肢は作り直さない (同じ Items のオブジェクトのまま、値も残る)
c_items = h_name.Items;
set_field(fig, "Tag", "in1");
assert(isequal(h_name.Items, c_items) && isequal(string(h_name.Value), ["Pmech", "Vfield"]))

%% Without a unit the names have no items and the hint asks for the unit; without History a text field
net = network.IEEE9bus();
sc = net.add_scenario("case1");
h = history_with(net, "sc", sc);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Scenario.add_input", fig, Object="sc", History=h, Value=struct("unit", """"""));
h_name = findall(fig, "Tag", "name");
assert(isempty(h_name.Items) && string(findall(fig, "Tag", "hint_name").Text) == "Select unit first")
assert(dlg.get_code() == "")    % エラーにならず、コードは書かない
set_field(fig, "unit", char(string(net.a_Bus{1}.a_Component{1})));
assert(~isempty(h_name.Items) && string(findall(fig, "Tag", "hint_name").Text) == "")
% History がなければ式を評価できず、これまでどおり文字の欄
fig = uifigure("Visible", "off");
DrawerOptionDialog("Scenario.add_input", fig, Object="sc");
assert(isa(findall(fig, "Tag", "name"), "matlab.ui.control.EditField") && isempty(findall(fig, "Tag", "hint_name")))

%% EventInput.edit lists the input names of its unit and follows the Unit field
net = network.IEEE9bus();
sc = net.add_scenario("case1");
s_gen = string(net.a_Bus{1}.a_Component{1});
s_load = string(net.a_Bus{5}.a_Component{1});
ev = sc.add_input(s_gen, "Pmech", 0.1, [1 2]);
h = history_with(net, "ev", ev);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("EventInput.edit", fig, Object="ev", History=h);
h_name = findall(fig, "Tag", "Name");
assert(isa(h_name, "matlab.ui.control.ListBox") && isempty(findall(fig, "Tag", "select_Name")))    % 入力の名前: 機器の表ではない
assert(isequal(string(h_name.Items), ["Pmech", "Vfield"]) && isequal(string(h_name.Value), "Pmech"))
assert(dlg.get_code() == "ev.edit();", dlg.get_code())
set_field(fig, "Unit", char(s_load));
assert(isequal(string(h_name.Items), ["R", "X"]) && isempty(h_name.Value), join(string(h_name.Items)))
set_field(fig, "Name", {'R'});
assert(dlg.get_code() == "ev.edit(Unit=""" + s_load + """, Name=""R"");", dlg.get_code())
set_field(fig, "Unit", char(s_gen));    % 元の機器: 既定の名前は選び直す
set_field(fig, "Name", {'Pmech'});
assert(dlg.get_code() == "ev.edit();", dlg.get_code())

%% add_scenario shows Time [0 10], the Time of From when From is a variable, else a hint
net = network.IEEE9bus();
sc0 = net.add_scenario("long", Time=[0, 20]);
h = history_with(net, "sc0", sc0);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.add_scenario", fig, Object="net", Output="sc", History=h);
h_time = findall(fig, "Tag", "Time");
assert(string(findall(fig, "Tag", "s_tag").Value) == "CASE" && string(h_time.Value) == "[0 10]", string(h_time.Value))
assert(dlg.get_code() == "sc = net.add_scenario();", dlg.get_code())    % 既定のまま: Time を書かない
open_group(fig, "Copy");
set_field(fig, "From", "sc0");
assert(string(h_time.Value) == "[0 20]" && dlg.get_code() == "sc = net.add_scenario(From=sc0);", dlg.get_code())
set_field(fig, "From", "net.a_Scenario{1}");    % 変数とプロパティと数の添字だけ
assert(string(h_time.Value) == "[0 20]")
set_field(fig, "From", "copy_of(sc0)");    % 関数の呼び出しは評価しない: 空欄と言葉のヒント
assert(string(h_time.Value) == "" && startsWith(findall(fig, "Tag", "hint_Time").Text, "default: From.Time"))
assert(dlg.get_code() == "sc = net.add_scenario(From=copy_of(sc0));", dlg.get_code())
set_field(fig, "From", "Scenario.empty");    % From の既定値に戻すと [0 10]
assert(string(h_time.Value) == "[0 10]" && string(findall(fig, "Tag", "hint_Time").Text) == "")
assert(dlg.get_code() == "sc = net.add_scenario();", dlg.get_code())
% 変えた Time は From を変えても残り、書かれる
set_field(fig, "Time", "[0 5]");
set_field(fig, "From", "sc0");
assert(string(h_time.Value) == "[0 5]" && dlg.get_code() == "sc = net.add_scenario(Time=[0 5], From=sc0);", dlg.get_code())

%% A trip and an opening take one time and write it as a number
net = network.IEEE9bus();
sc = net.add_scenario("case1");
h = history_with(net, "sc", sc);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Scenario.add_trip", fig, Object="sc", History=h);
assert(string(findall(fig, "Tag", "unit").Value) == "" && string(findall(fig, "Tag", "time").Value) == "")
assert(dlg.get_code() == "")    % 必須の入力が空
s_unit = string(net.a_Bus{3}.a_Component{1});
set_field(fig, "unit", char(s_unit));
set_field(fig, "time", "1");
assert(dlg.get_code() == "sc.add_trip(""" + s_unit + """, 1);", dlg.get_code())
eval(char(dlg.get_code()));    % 書いたコードはそのまま動く
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Scenario.add_open_branch", fig, Object="sc", History=h);
assert(string(findall(fig, "Tag", "Status").Value) == "6open" && string(findall(fig, "Tag", "time").Value) == "")
s_branch = string(net.a_Branch{4});
set_field(fig, "branch", char(s_branch));
set_field(fig, "time", "0.5");
assert(dlg.get_code() == "sc.add_open_branch(""" + s_branch + """, 0.5);", dlg.get_code())
eval(char(dlg.get_code()));
assert(numel(sc.a_Event) == 2 && isa(sc.a_Event{1}, "EventTrip") && isa(sc.a_Event{2}, "EventOpenBranch"))


function h = history_with(net, s_name, value)
% net と変数 1 つを持つ実行記録
    h = HistoryGUILDA();
    h.set_variable("net", net);
    h.set_variable(s_name, value);
end

function open_group(fig, s_name)
% グループの見出しを押す (開く・閉じる)
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

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end
