% F66 オプションのフォームの配置・既定値の表示・条件付きの表示・ピッカーの組み込み (DrawerOptionDialog)
%
%   dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", History=h);
%   s_code = dlg.get_code();
%
% _GUILDAsystem/resources/gui_forms.json による並び (必須の入力、主なオプション、閉じたグループ) と
% 載っていないシグネチャの名前による分類、条件付きの表示 (initialize の Method、OPF の安定度)、
% 既定値の表示 (NaN は auto/none、Inf は none、"" は空、文章の既定値は横のヒント、obj のプロパティ、
% クラスのプロパティの既定値)、単位、変えた欄の強調と既定値に戻すボタン、Select... からのピッカー
% (1 つ、複数、Key、ローカル制御器、種類の混ざった表)、get_code が変えていないオプションを書かないことを
% 確かめる。ピッカーは見えない親の図に作り、タイマーから表とボタンを操作する (pick は誰も押さなければ
% 10 秒以内に戻る)。時間の確認 (IEEE68bus の OPF のフォームとピッカー。目標は 2 回目以降が 0.3 秒未満。
% 他のセッションの負荷に左右されないよう、決まった基準の作業との比と、大きな絶対の上限で判定する) は large。
%
% 実行: runtests("DebugScript.test_F66_gui_forms")  または  DebugScript.run_all("Features","F66")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% The entry of gui_forms.json orders the fields and closes the groups
h = history_of(network.IEEE9bus());
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", Output="comp", History=h);
% 必須の入力、主なオプション (P, Q, parameter) の順。閉じたグループの欄はまだない
assert(isequal(field_rows(fig, ["Key", "P", "Q", "parameter"]), sort(field_rows(fig, ["Key", "P", "Q", "parameter"]))))
assert(field_rows(fig, "Key") < field_rows(fig, "P"))
assert(isempty(findall(fig, "Tag", "Pmin")) && isempty(findall(fig, "Tag", "OPFcost_HP")) && isempty(findall(fig, "Tag", "DX")))
sv_header = header_texts(fig);
assert(isequal(extractBetween(sv_header, "▸ ", "  ("), ["Limits"; "OPF"; "Graph"; "Advanced"]), join(sv_header, " | "))
assert(startsWith(sv_header(1), "▸ Limits  (4)"))
% 開くとその場で欄を作り、ファイルの順に並べる
open_group(fig, "Limits");
assert(isequal(field_rows(fig, ["Pmin", "Pmax", "Qmin", "Qmax"]), sort(field_rows(fig, ["Pmin", "Pmax", "Qmin", "Qmax"]))))
assert(field_rows(fig, "Pmin") > field_rows(fig, "parameter") && startsWith(header_texts(fig, "Limits"), "▾ Limits"))
open_group(fig, "OPF");
assert(field_rows(fig, "OPFcost_HP") < field_rows(fig, "OPFinit_P0") && field_rows(fig, "OPFcost_HP") > field_rows(fig, "Qmax"))
assert(label_of(fig, "OPFcost_HP").Text == "Cost P (quadratic)" && contains(label_of(fig, "OPFcost_HP").Tooltip, "OPFcost_HP"))
assert(field_rows(fig, "OPFcost_fQ") < field_rows(fig, "OPFcost_c") && field_rows(fig, "OPFcost_c") < field_rows(fig, "OPFinit_P0"))   % 定数の費用 c は OPF のグループ
assert(label_of(fig, "OPFcost_c").Text == "Cost (constant)")
% 閉じると欄は隠れ (高さ 0 の行)、値はそのまま
set_field(fig, "Pmax", "2");
open_group(fig, "Limits");
s_key = string(findall(fig, "Tag", "Key").Value);
assert(~findall(fig, "Tag", "Pmax").Visible && dlg.get_code() == "comp = net.a_Bus{3}.add_component(""" + s_key + """, Pmax=2);", dlg.get_code())
assert(contains(header_texts(fig, "Limits"), "1 changed"))
% 項目にないオプションは Advanced (add_global_controller の a_Unit は必須なので先頭)
fig = uifigure("Visible", "off");
DrawerOptionDialog("PowerNetwork.add_scenario", fig, Object="net", History=h);
assert(isequal(extractBetween(header_texts(fig), "▸ ", "  ("), "Copy"))


%% A signature missing from gui_forms.json is grouped by the names of its options
% ResultLIN.get_ss は gui_forms.json にない: Format は Advanced、それ以外は主なオプション
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("ResultLIN.get_ss", fig, Object="res", Output="sys");
assert(isequal(extractBetween(header_texts(fig), "▸ ", "  ("), "Advanced"))
assert(isscalar(findall(fig, "Tag", "Port")) && isscalar(findall(fig, "Tag", "Input")) && isempty(findall(fig, "Tag", "Format")))
open_group(fig, "Advanced");
assert(isscalar(findall(fig, "Tag", "Format")) && dlg.get_code() == "sys = res.get_ss();", dlg.get_code())
% 名前で分類できるものがなければグループはない
fig = uifigure("Visible", "off");
DrawerOptionDialog("PowerNetwork.remove_bus", fig, Object="net");
assert(isempty(header_texts(fig)) && isscalar(findall(fig, "Tag", "RemoveBranches")))


%% initialize shows the OPF options only for Method OPF and leaves hidden ones out
h = history_of(network.IEEE9bus());
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.initialize", fig, Object="net", History=h);
assert(string(findall(fig, "Tag", "Method").Value) == "powerflow")
assert(~group_header(fig, "OPF").Visible && ~group_header(fig, "Stability").Visible && group_header(fig, "Advanced").Visible)
assert(startsWith(header_texts(fig, "Advanced"), "▸ Advanced  (3)"))    % WarmStart, PlotFcn, Progress
set_field(fig, "Method", "OPF");
assert(group_header(fig, "OPF").Visible && group_header(fig, "Stability").Visible)
assert(startsWith(header_texts(fig, "Stability"), "▸ Stability  (2)"))    % MinDampingRatio, MaxRealPart のみ
open_group(fig, "OPF");
set_field(fig, "DefaultCost", "false");
assert(dlg.get_code() == "net.initialize(Method=""OPF"", DefaultCost=false);", dlg.get_code())
open_group(fig, "Stability");
set_field(fig, "MaxRealPart", "-0.1");
assert(startsWith(header_texts(fig, "Stability"), "▾ Stability  (6, 1 changed)"))    % Stability* も出る
assert(findall(fig, "Tag", "StabilityBand").Visible)
% FixedInput では OPF の欄も PlotFcn も隠れ (Progress は残る)、変えた値も書かない
set_field(fig, "Method", "FixedInput");
assert(~findall(fig, "Tag", "DefaultCost").Visible && ~group_header(fig, "OPF").Visible)
assert(dlg.get_code() == "net.initialize(Method=""FixedInput"");", dlg.get_code())
assert(startsWith(header_texts(fig, "Advanced"), "▸ Advanced  (2)"))


%% OPF shows the stability options for AC OPF and the Stability ones when a limit is set
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.calculate_optimal_powerflow", fig, Object="net", Output=["res", "flag"]);
set_field(fig, "Method", "DC OPF");
assert(~group_header(fig, "Stability").Visible)
set_field(fig, "Method", "AC OPF");
open_group(fig, "Stability");
assert(findall(fig, "Tag", "MinDampingRatio").Visible && ~findall(fig, "Tag", "StabilityStep").Visible)
assert(string(findall(fig, "Tag", "MaxRealPart").Value) == "none")    % NaN for none
set_field(fig, "MinDampingRatio", "0.05");
assert(findall(fig, "Tag", "StabilityStep").Visible && findall(fig, "Tag", "StabilityBand").Visible)
assert(contains(dlg.get_code(), "MinDampingRatio=0.05"), dlg.get_code())
set_field(fig, "MinDampingRatio", "none");    % 既定値 NaN に戻る
assert(~findall(fig, "Tag", "StabilityStep").Visible && ~contains(dlg.get_code(), "MinDampingRatio"), dlg.get_code())


%% add_branch shows Tap and Phase only for a branch with a transformer
h = history_of(network.IEEE9bus());
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.add_branch", fig, Object="net", Output="br", History=h);
set_field(fig, "Key", "pi_transformer");
assert(findall(fig, "Tag", "Tap").Visible && findall(fig, "Tag", "Phase").Visible)
set_field(fig, "Tap", "0.97");
assert(contains(dlg.get_code(), "Tap=0.97"), dlg.get_code())
for s_key = ["pi", "T"]   % 線路は変圧器を持たない: 欄を隠し、呼び出しにも書かない
    set_field(fig, "Key", s_key);
    assert(~findall(fig, "Tag", "Tap").Visible && ~findall(fig, "Tag", "Phase").Visible, s_key)
    assert(~contains(dlg.get_code(), "Tap"), dlg.get_code())
end


%% Every field shows its default: auto, none, empty and a hint for a default in words
h = history_of(network.IEEE9bus());
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", History=h);
for s_group = ["Limits", "Graph"]
    open_group(fig, s_group);
end
assert(string(findall(fig, "Tag", "parameter").Value) == "auto")    % NaN uses the class defaults
assert(string(findall(fig, "Tag", "Pmax").Value) == "none" && string(findall(fig, "Tag", "Pmin").Value) == "none")
assert(string(findall(fig, "Tag", "DX").Value) == "auto" && string(findall(fig, "Tag", "MarkerSize").Value) == "auto")
assert(string(findall(fig, "Tag", "Color").Value) == "" && string(findall(fig, "Tag", "Shape").Value) == "circle")
s_base = dlg.get_code();
s_key = string(findall(fig, "Tag", "Key").Value);
% 言葉のまま、または数で入れ直しても変わらない。none は既定値の向き (-Inf) で書く
set_field(fig, "DX", "NaN");
set_field(fig, "Pmax", "Inf");
set_field(fig, "Pmin", "none");
assert(dlg.get_code() == s_base, dlg.get_code())
set_field(fig, "Pmax", "3");
set_field(fig, "Qmin", "-1");
set_field(fig, "DX", "0.5");
assert(endsWith(dlg.get_code(), "(""" + s_key + """, Pmax=3, Qmin=-1, DX=0.5);"), dlg.get_code())
set_field(fig, "Qmin", "none");
set_field(fig, "DX", "auto");
assert(endsWith(dlg.get_code(), "(""" + s_key + """, Pmax=3);"), dlg.get_code())
% 既定値が限界でないもの: none は既定値と違う値 (-Inf) として書く
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.add_bus", fig, Object="net");
open_group(fig, "Limits");
assert(string(findall(fig, "Tag", "Vmin").Value) == "0.5")
set_field(fig, "Vmin", "none");
assert(dlg.get_code() == "net.add_bus(Vmin=-Inf);", dlg.get_code())
% NaN の言葉とヒントを gui_forms.json の labels で与える (add_fault の Point: NaN は母線の故障)
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Scenario.add_fault", fig, Object="sc", Value=struct("target", """B004""", "time", "[0.1 0.15]"));
assert(string(findall(fig, "Tag", "Point").Value) == "bus" && contains(findall(fig, "Tag", "hint_Point").Text, "along a branch"))
assert(dlg.get_code() == "sc.add_fault(""B004"", [0.1 0.15]);", dlg.get_code())
set_field(fig, "Point", "0.3");
assert(endsWith(dlg.get_code(), ", Point=0.3);"), dlg.get_code())
set_field(fig, "Point", "bus");    % 言葉で既定値 (NaN) に戻る
assert(dlg.get_code() == "sc.add_fault(""B004"", [0.1 0.15]);", dlg.get_code())
% 既定値が文章: 空の欄と、横の薄いヒント (欄の値には見えない)。書かない
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.initialize", fig, Object="net");
h_hint = findall(fig, "Tag", "hint_Solver");
assert(string(findall(fig, "Tag", "Solver").Value) == "" && h_hint.Text == "default: from GUILDA.setting")
assert(h_hint.FontAngle == "italic" && isequal(h_hint.FontColor, tools.gui_palette().rv_subtext) && contains(h_hint.Tooltip, "Method runs"))
set_field(fig, "Method", "OPF");
open_group(fig, "OPF");
assert(findall(fig, "Tag", "hint_DefaultCost").Text == "default: true" && findall(fig, "Tag", "hint_ReferenceBus").Text == "default: ""auto""")
assert(dlg.get_code() == "net.initialize(Method=""OPF"");", dlg.get_code())


%% Defaults on the object (Event edit) and from the property defaults of a class
net = network.IEEE9bus();
sc = net.add_scenario("case1");
ev = sc.add_fault("B004", [0.1, 0.15]);
h = history_of(net);
h.set_variable("ev", ev);
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("EventFault.edit", fig, Object="ev", History=h);
assert(string(findall(fig, "Tag", "Target").Value) == "B004" && string(findall(fig, "Tag", "Time").Value) == "[0.1 0.15]")
assert(string(findall(fig, "Tag", "Status").Value) == "BG" && dlg.get_code() == "ev.edit();", dlg.get_code())
assert(string(findall(fig, "Tag", "Point").Value) == "bus")    % 母線の故障の Point (NaN)
set_field(fig, "Time", "[0.2 0.25]");
assert(dlg.get_code() == "ev.edit(Time=[0.2 0.25]);", dlg.get_code())
% plot_diagram (opt.?GraphNetDiagram): 既定値と説明は GraphNetDiagram のプロパティから
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("ResultPF.plot_diagram", fig, Object="res", Exclude="Parent");
assert(string(findall(fig, "Tag", "Dimension").Value) == "2D" && string(findall(fig, "Tag", "FlowMode").Value) == "P")
open_group(fig, "Sizes");
assert(string(findall(fig, "Tag", "MarkerSizeRange").Value) == "[5 10]" && label_of(fig, "MarkerSizeRange").Text == "MarkerSizeRange [pt]")
assert(contains(findall(fig, "Tag", "MarkerSizeRange").Tooltip, "Range [min max] of the bus and component sizes"))
open_group(fig, "Colors");
assert(string(findall(fig, "Tag", "Colormap").Value) == "turbo" && string(findall(fig, "Tag", "ColorLimits").Value) == "auto")    % [NaN NaN]: only NaN, shown as auto
assert(dlg.get_code() == "res.plot_diagram();", dlg.get_code())
set_field(fig, "MarkerSizeRange", "[6 12]");
assert(dlg.get_code() == "res.plot_diagram(MarkerSizeRange=[6 12]);", dlg.get_code())
set_field(fig, "ColorLimits", "[0 2]");
assert(dlg.get_code() == "res.plot_diagram(ColorLimits=[0 2], MarkerSizeRange=[6 12]);", dlg.get_code())
set_field(fig, "ColorLimits", "auto");    % 既定値 [NaN NaN] に戻り、書かない
assert(dlg.get_code() == "res.plot_diagram(MarkerSizeRange=[6 12]);", dlg.get_code())


%% A changed field is highlighted and its reset button restores the default
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}");
h_p = findall(fig, "Tag", "P");
assert(isempty(findall(fig, "Tag", "reset_P")) && isequal(h_p.BackgroundColor, tools.gui_palette().rv_card))
set_field(fig, "P", "0.5");
h_reset = findall(fig, "Tag", "reset_P");
assert(isscalar(h_reset) && h_reset.Visible && ~isequal(h_p.BackgroundColor, tools.gui_palette().rv_card))
assert(isequal(label_of(fig, "P").FontColor, tools.gui_palette().rv_blue) && contains(dlg.get_code(), "P=0.5"))
h_reset.ButtonPushedFcn(h_reset, []);
assert(string(h_p.Value) == "0" && ~h_reset.Visible && isequal(h_p.BackgroundColor, tools.gui_palette().rv_card))
assert(~contains(dlg.get_code(), "P="), dlg.get_code())
% チェックボックスとドロップダウンも戻す
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.calculate_powerflow", fig, Object="net");
b_verbose = findall(fig, "Tag", "Verbose").Value;
set_field(fig, "Verbose", ~b_verbose);
set_field(fig, "Solver", "fsolve");
press(fig, "reset_Verbose");
press(fig, "reset_Solver");
assert(findall(fig, "Tag", "Verbose").Value == b_verbose && dlg.get_code() == "net.calculate_powerflow();", dlg.get_code())
% Value で渡した値は既定値と違えば強調する
fig = uifigure("Visible", "off");
DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", Value=struct("Q", "0.2"));
assert(findall(fig, "Tag", "reset_Q").Visible)


%% Units come from the purpose; labels from gui_forms.json
fig = uifigure("Visible", "off");
DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}");
assert(label_of(fig, "P").Text == "P [pu]" && label_of(fig, "Key").Text == "Key *")
open_group(fig, "Advanced");
assert(label_of(fig, "baseMVA").Text == "baseMVA [MVA]")
fig = uifigure("Visible", "off");
DrawerOptionDialog("Scenario.add_fault", fig, Object="sc");
assert(label_of(fig, "time").Text == "time [s] *")
fig = uifigure("Visible", "off");
DrawerOptionDialog("PowerNetwork.add_bus", fig, Object="net");
assert(label_of(fig, "FullTag").Text == "Tag" && contains(label_of(fig, "FullTag").Tooltip, "FullTag: "))
assert(label_of(fig, "V").Text == "V [pu]")


%% Select... picks one tag, several tags and a model key
net = network.IEEE9bus();
sc = net.add_scenario("case1");
h = history_of(net);
h.set_variable("sc", sc);
% 複数: タグの欄 (", " 区切り)。表は母線の表で、選んだタグを書く
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.remove_bus", fig, Object="net", History=h);
assert(isa(findall(fig, "Tag", "sr_BusTag"), "matlab.ui.control.EditField"))
select_with(fig, "sr_BusTag", @(hp) [observe("columns", string(h_table(hp).Data.Properties.VariableNames)), ...
    observe("multi", h_table(hp).Multiselect), select_rows(hp, [1 3]), press(hp, "picker_ok")]);
assert(isequal(observed("columns"), ["Tag", "Index", "Type", "Components"]) && observed("multi"))
assert(string(findall(fig, "Tag", "sr_BusTag").Value) == "B001, B003")
assert(dlg.get_code() == "net.remove_bus([""B001"", ""B003""]);", dlg.get_code())
% 開くと今のタグを選んだ状態。キャンセルでは変わらない
select_with(fig, "sr_BusTag", @(hp) [observe("sel", h_table(hp).Selection), press(hp, "picker_cancel")]);
assert(isequal(observed("sel"), [1 3]) && string(findall(fig, "Tag", "sr_BusTag").Value) == "B001, B003")
% 手で入れたタグも読み、ないタグは知らせる
set_field(fig, "sr_BusTag", "B002 | B004");
assert(dlg.get_code() == "net.remove_bus([""B002"", ""B004""]);", dlg.get_code())
set_field(fig, "sr_BusTag", "B002, B999");
assert(dlg.get_code() == "" && contains(message_of(fig), "B999"))
% 1 つ ("scalar"): ドロップダウンと Select...。機器の表 (母線、母線での位置、クラス)
fig = uifigure("Visible", "off");
DrawerOptionDialog("Scenario.add_offset", fig, Object="sc", History=h);
assert(isa(findall(fig, "Tag", "unit"), "matlab.ui.control.DropDown"))
select_with(fig, "unit", @(hp) [observe("columns", string(h_table(hp).Data.Properties.VariableNames)), ...
    observe("multi", h_table(hp).Multiselect), select_rows(hp, 2), press(hp, "picker_ok")]);
tab = DrawerTagPicker.element_table(net, "Component");
assert(isequal(observed("columns"), ["Tag", "Bus", "BusIndex", "Position", "Class", "Key"]) && ~observed("multi"))
assert(string(findall(fig, "Tag", "unit").Value) == tab.Tag(2))
% Key: キーの表から選ぶ
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", Output="comp", History=h);
select_with(fig, "Key", @(hp) [observe("columns", string(h_table(hp).Data.Properties.VariableNames)), ...
    search(hp, "load-impedance"), select_rows(hp, 1), press(hp, "picker_ok")]);
assert(isequal(observed("columns"), ["Key", "Class", "Description"]))
assert(dlg.get_code() == "comp = net.a_Bus{3}.add_component(""load-impedance"");", dlg.get_code())
% gui_forms.json の pick: CPF の LoadBus (式の欄) に母線のタグを書く
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("PowerNetwork.calculate_continuation_powerflow", fig, Object="net", History=h);
select_with(fig, "LoadBus", @(hp) [select_rows(hp, [5 6]), press(hp, "picker_ok")]);
assert(string(findall(fig, "Tag", "LoadBus").Value) == "[""B005"", ""B006""]")
assert(dlg.get_code() == "net.calculate_continuation_powerflow(LoadBus=[""B005"", ""B006""]);", dlg.get_code())
% History がなければネットワークがないので Select... はない
fig = uifigure("Visible", "off");
DrawerOptionDialog("PowerNetwork.remove_bus", fig, Object="net");
assert(isempty(findall(fig, "Tag", "select_sr_BusTag")))


%% Local controllers are picked from the component of the call; a trip lists every kind
net = network.IEEE68bus();
sc = net.add_scenario("case1");
h = history_of(net);
h.set_variable("sc", sc);
gen = net.a_Bus{1}.a_Component{1};
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Component.remove_local_controller", fig, Object="net.a_Bus{1}.a_Component{1}", History=h);
select_with(fig, "s_tag", @(hp) [observe("tab", h_table(hp).Data), select_rows(hp, 2), press(hp, "picker_ok")]);
tab = observed("tab");
assert(height(tab) == numel(DrawerTagPicker.element_table(net, "LocalController").Tag(DrawerTagPicker.element_table(net, "LocalController").Component == gen.s_tag)))
assert(all(tab.Component == gen.s_tag) && height(tab) >= 2)
assert(dlg.get_code() == "net.a_Bus{1}.a_Component{1}.remove_local_controller(""" + tab.Tag(2) + """);", dlg.get_code())
% add_trip の unit: 機器、ローカル制御器、グローバル制御器を 1 つの表 (Kind 列) に
fig = uifigure("Visible", "off");
dlg = DrawerOptionDialog("Scenario.add_trip", fig, Object="sc", History=h);
select_with(fig, "unit", @(hp) [observe("tab", h_table(hp).Data), search(hp, "avr B001"), select_rows(hp, 1), press(hp, "picker_ok")]);
tab = observed("tab");
assert(isequal(string(tab.Properties.VariableNames), ["Tag", "Kind", "Bus", "Detail", "Class"]))
assert(all(ismember(["Component", "LocalController"], tab.Kind)))
assert(string(findall(fig, "Tag", "unit").Value) == "B001SG1CA1", string(findall(fig, "Tag", "unit").Value))
set_field(fig, "time", "1");
assert(dlg.get_code() == "sc.add_trip(""B001SG1CA1"", 1);", dlg.get_code())


%% An OPF form and a picker open in under 0.3 s the second time on IEEE68bus
% 時間の判定 (他のセッションの MATLAB の負荷に左右されないように):
% - 1 回目 (作成の準備) を除き、各回の直前に決まった基準の作業 (隠れた図に 20 行の uilabel と
%   uieditfield を作って drawnow) を測り、フォームまたはピッカーとの組で 8 回の最小を取る。
% - 判定は基準との比 (負荷で両方が同じように遅くなる) が 6 未満 (負荷平均 2〜12 で 1〜2.5 程度)
%   と、絶対の上限 1.5 秒 (大きな退行)。目標の 0.3 秒は表示するだけ。
% 退行で実際の時間が 2.5〜3 倍になれば比で失敗する。
net = network.IEEE68bus();
h = history_of(net);
fig = uifigure("Visible", "off");
fig_ref = uifigure("Visible", "off");
c_ref = onCleanup(@() delete(fig_ref));
n_run = 9;
rv_ref = zeros(1, n_run);
rv_form = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    delete(fig.Children);
    t_start = tic;
    DrawerOptionDialog("PowerNetwork.calculate_optimal_powerflow", fig, Object="net", Output=["res", "flag"], History=h);
    drawnow
    rv_form(r) = toc(t_start);
end
check_time("OPF form", rv_form, rv_ref);
delete(fig.Children);
DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", History=h);
rv_pick = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    t_start = tic;
    select_with(fig, "Key", @(hp) [observe("ready", toc(t_start)), press(hp, "picker_ok")], 0.005);
    rv_pick(r) = observed("ready");
end
check_time("Select... of Key", rv_pick, rv_ref);
fig = uifigure("Visible", "off");
DrawerOptionDialog("Scenario.add_trip", fig, Object="sc", History=history_with_scenario(net));
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    t_start = tic;
    select_with(fig, "unit", @(hp) [observe("ready", toc(t_start)), press(hp, "picker_ok")], 0.005);
    rv_pick(r) = observed("ready");
end
check_time("Select... of add_trip units", rv_pick, rv_ref);


function t = reference_time(fig)
% 決まった基準の作業の時間: 20 行の uilabel と uieditfield の格子を作って描く
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

function check_time(s_name, rv_time, rv_ref)
% 2 回目以降の最小を、基準の最小との比 (6 未満) と絶対の上限 (1.5 秒) で判定し、目標 0.3 秒との比較を表示する
    r_time = min(rv_time(2:end));
    r_ref  = min(rv_ref(2:end));
    fprintf("F66 %s (IEEE68bus): first %.2f s, second and later min %.3f s (target 0.3 s), median %.3f s; reference min %.3f s, ratio %.2f\n", ...
        s_name, rv_time(1), r_time, median(rv_time(2:end)), r_ref, r_time / r_ref);
    assert(r_time / r_ref < 6, sprintf("%s: %.3f s is %.1f times the reference (%.3f s)", s_name, r_time, r_time / r_ref, r_ref))
    assert(r_time < 1.5, sprintf("%s: %.3f s", s_name, r_time))
end

function h = history_of(net)
% net を持つ実行記録 (scenario sc と結果 res は使う節で加える)
    h = HistoryGUILDA();
    h.set_variable("net", net);
end

function h = history_with_scenario(net)
% net とそのシナリオ sc を持つ実行記録
    h = history_of(net);
    h.set_variable("sc", net.add_scenario("timing"));
end

function iv = field_rows(fig, sv_tag)
% 欄の行 (グリッドの Layout.Row)
    iv = arrayfun(@(s) findall(fig, "Tag", s).Layout.Row, sv_tag);
end

function sv = header_texts(fig, s_name)
% グループの見出しの文字 (上から)。名前を渡すとそのグループだけ
    if nargin == 2
        sv = string(group_header(fig, s_name).Text);
        return
    end
    h = findall(fig, "Type", "uibutton", "-regexp", "Tag", "^group_");
    if isempty(h)
        sv = strings(0, 1);
        return
    end
    [~, iv] = sort(arrayfun(@(x) x.Layout.Row, h));
    sv = reshape(string({h(iv).Text}), [], 1);
    sv = sv(arrayfun(@(x) x.Visible, h(iv)));
end

function h = group_header(fig, s_name)
% グループの見出しのボタン
    h = findall(fig, "Tag", "group_" + replace(s_name, " ", "_"));
    assert(isscalar(h), "group " + s_name)
end

function open_group(fig, s_name)
% グループの見出しを押す (開く・閉じる)
    h = group_header(fig, s_name);
    h.ButtonPushedFcn(h, []);
end

function h = label_of(fig, s_tag)
% 欄のラベル (同じ行の 1 列目)
    h_field = findall(fig, "Tag", s_tag);
    h = findall(h_field.Parent, "Type", "uilabel");
    h = h(arrayfun(@(x) x.Layout.Row == h_field.Layout.Row && isequal(x.Layout.Column, 1), h));
    assert(isscalar(h), "label " + s_tag)
end

function s = message_of(fig)
% フォームのメッセージ
    h = findall(fig, "Type", "uilabel", "FontColor", tools.gui_palette().rv_stale_text);
    s = string(h(1).Text);
end

function set_field(fig, s_tag, value)
% フォームの欄に値を入れ、ユーザーの操作と同じくコールバックを呼ぶ
    h = findall(fig, "Tag", s_tag);
    assert(isscalar(h), "field " + s_tag)
    h.Value = value;
    h.ValueChangedFcn(h, []);
end

function out = press(h_fig, s_tag)
% ボタンを押す
    h = findall(h_fig, "Tag", s_tag);
    assert(isscalar(h), "button " + s_tag)
    h.ButtonPushedFcn(h, []);
    out = [];
end

function select_with(fig, s_name, f_action, r_period)
% 欄の Select... を押し、開いたピッカーでタイマーから f_action(ピッカーの図) を実行する
    if nargin < 4
        r_period = 0.05;
    end
    tm = timer("StartDelay", 0.001, "Period", r_period, "ExecutionMode", "fixedSpacing", "TimerFcn", @(t, ~) act(t, f_action));
    c_timer = onCleanup(@() delete(tm));
    observed();
    start(tm);
    press(fig, "select_" + s_name);
    observed("error");    % タイマーの中のエラー
end

function act(tm, f_action)
% 開いて待っているピッカーがあれば操作する (タイマーの中のエラーは observed("error") に残す)
    h_fig = findall(groot, "Type", "figure", "-regexp", "Tag", "^DrawerTagPicker");
    h_fig = h_fig(arrayfun(@(h) isstruct(getappdata(h, "sct_state")) && getappdata(h, "sct_state").l_open && ~getappdata(h, "sct_state").l_done, h_fig));
    if isempty(h_fig)
        return
    end
    stop(tm);
    try
        f_action(h_fig(1));
    catch ME
        observe("error", ME.message);
        press(h_fig(1), "picker_cancel");
    end
end

function v = observed(s_key, v)
% タイマーの中で見た値を記録し (2 引数)、読む (1 引数)。引数なしで消す
    persistent sct
    if nargin == 0 || isempty(sct)
        sct = struct("error", "");
    end
    if nargin == 2
        sct.(s_key) = v;
    elseif nargin == 1
        assert(s_key == "error" || sct.error == "", "timer: " + sct.error)
        if s_key == "error"
            assert(sct.error == "", "timer: " + sct.error)
            v = [];
            return
        end
        v = sct.(s_key);
    end
end

function out = observe(s_key, v)
% observed に記録する (配列の中で呼べるよう空を返す)
    observed(s_key, v);
    out = [];
end

function out = search(h_fig, s_text)
% 検索欄に入力する
    h = findall(h_fig, "Tag", "picker_search");
    h.Value = s_text;
    h.ValueChangingFcn(h, struct("Value", s_text));
    out = [];
end

function out = select_rows(h_fig, iv_row)
% 表示中の行を選ぶ
    h = h_table(h_fig);
    h.Selection = iv_row;
    h.SelectionChangedFcn(h, []);
    out = [];
end

function h = h_table(h_fig)
% ピッカーの表
    h = findall(h_fig, "Tag", "picker_table");
end

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end
