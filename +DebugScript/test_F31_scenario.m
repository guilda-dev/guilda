% F31 シミュレーションのシナリオ (Scenario)
%
%   sc = net.add_scenario("case1", Time=[0,20]);   % 系統の子として作る (net.a_Scenario, sc.a_PowerNetwork)
%   sc.add_fault("B008", [0.10,0.17]);           % 地絡
%   sc.add_open_branch("EL003", [0.17,20]);      % その後の回線開放 (終わりまで)
%   result  = net.simulate("case1");             % タグで選び、シナリオの Time で実行
%
% 複数の外乱を持つシナリオ、系統の子としての作成・改名・削除・複製、タグの検査、入力の時系列を確認する。
% シナリオのファイル scenario/<タグ>.json (net.export / PowerNetwork.import) の内容と往復も確かめる
% (系統のフォルダ全体の往復は F16)。判定は F38 (ResultODE.judge_out_of_step)。
%
% 実行: runtests("DebugScript.test_F31_scenario")  または  DebugScript.run_all("Features","F31")

% 各テストは新しい系統で始める (共通設定の handle はテストの間で共有されるため)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% A fault then a permanent opening: two rows per target with one tag
net = new_ieee14();
sc = net.add_scenario("case1", Time=[0,3]);
assert(sc.add_fault("B008", [1,1.07]) == "Fault001")
assert(sc.add_open_branch("EL003", [1.07,3]) == "Parallel001")
tab = sc.tab_event;
assert(isequal(string(tab.Properties.VariableNames), ["Tag","Target","Time","Status","Point"]))
assert(isequal(tab.Tag, ["Fault001";"Fault001";"Parallel001";"Parallel001"]) && isequal(tab.Target, ["B008";"B008";"EL003";"EL003"]))
assert(isequal(tab.Time, [1;1.07;1.07;3]) && isequal(tab.Status, ["BG";"none";"6open";"close"]) && all(isnan(tab.Point)))
assert(height(sc.tab_offset) == 0 && height(sc.tab_input) == 0)
[r_sc, flag, out_sc] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
assert(flag == 1 && r_sc.rv_t(end) == 3)
assert(isequal(string(out_sc.phases.Properties.VariableNames), ["t1","t2","Fault001","Parallel001","NoAction1"]))
% "6open" は既定 (旧 OpenBranch と同じ)
net2 = new_ieee14();
sc2 = net2.add_scenario("case1", Time=[0,3]);
sc2.add_fault("B008", [1,1.07]);
sc2.add_open_branch("EL003", [1.07,3], Status="6open");
[r_ev, ~, out_ev] = DebugScript.helper.quiet(@() net2.simulate("case1"));
assert(isequaln(r_sc.rm_variable, r_ev.rm_variable) && isequaln(r_sc.rv_t, r_ev.rv_t))
assert(isequal(out_sc.phases, out_ev.phases) && isequaln(sc.tab_event, sc2.tab_event))
% 対象が複数なら対象ごとに 2 行 (開始, 終了)
sc3 = net2.add_scenario("multi");
sc3.add_trip(["B002SG1"; "B003SG1"], [1,2]);
assert(isequal(sc3.tab_event.Target, ["B002SG1";"B002SG1";"B003SG1";"B003SG1"]) && isequal(sc3.tab_event.Status, ["open";"close";"open";"close"]))


%% The general form and the convenience methods give the same rows
net = new_ieee14();
sc1 = net.add_scenario("a");
sc1.add_disturbance("os", TimeSpan=0, OffsetUnit="B001SG1", OffsetState="delta", OffsetValue=0.1);
sc1.add_disturbance("in", TimeSpan=[1,2], InputUnit="B002SG1", InputName="Pmech", InputValue=0.01);
sc2 = net.add_scenario("b");
sc2.add_offset("B001SG1", "delta", 0.1, 0, Tag="os");
sc2.add_input("B002SG1", "Pmech", 0.01, [1,2], Tag="in");
assert(isequaln(sc1.tab_offset, sc2.tab_offset) && isequaln(sc1.tab_input, sc2.tab_input) && height(sc1.tab_event) == 0)
assert(isequal(string(sc1.tab_offset.Properties.VariableNames), ["Tag","TimeSpan","OffsetUnit","OffsetState","OffsetValue"]))
assert(isequal(string(sc1.tab_input.Properties.VariableNames), ["Tag","TimeSpan","InputUnit","InputName","InputValue","InputMethod"]))
% オフセットと入力を 1 つのタグで: 2 つの表に 1 行ずつ (オフセットは t_start)
sc1.add_disturbance("both", TimeSpan=[2,3], OffsetUnit="B001SG1", OffsetState="delta", OffsetValue=0.1, ...
                    InputUnit="B002SG1", InputName="Pmech", InputValue=0.01);
assert(sc1.tab_offset.Tag(end) == "both" && sc1.tab_offset.TimeSpan(end) == 2)
assert(sc1.tab_input.Tag(end) == "both" && isequal(sc1.tab_input.TimeSpan(end,:), [2,3]))
[~, flag, out] = DebugScript.helper.quiet(@() net.simulate(sc1.s_tag, Time=[0,4]));
assert(flag == 1 && isequal(string(out.phases.Properties.VariableNames), ["t1","t2","os","both","in","NoAction4"]))
assert(isequal(out.phases.both.', [false, false, true, false]), "1 つのタグは 1 つの列")
% add_disturbance は故障・解列・開放を持たない
assert(error_id(@() sc1.add_disturbance("f", TimeSpan=[1,2], FaultBus="B008")) ~= "")
% 自動のタグ: 故障と並列は 3 桁の番号、オフセットと入力は種類ごと
sc2.add_trip("B002SG1", [2,3]);
sc2.add_trip("B003SG1", [2,3]);
sc2.add_fault("B008", [1,1.05]);
sc2.add_input("B002SG1", "Pmech", 0.01, [2,3]);
assert(isequal(unique(sc2.tab_event.Tag, "stable").', ["Parallel001","Parallel002","Fault001"]))
assert(isequal(sc2.tab_input.Tag.', ["in","input1"]))
% remove_disturbance は 3 つの表からタグのすべての行を消す。番号は再利用しない
sc2.remove_disturbance(["Parallel001","os"]);
assert(isequal(sc2.tab_event.Tag.', ["Parallel002","Parallel002","Fault001","Fault001"]) && height(sc2.tab_offset) == 0)
assert(sc2.add_trip("B002SG1", [5,6]) == "Parallel003")
sc1.remove_disturbance("both");
assert(~ismember("both", [sc1.tab_offset.Tag; sc1.tab_input.Tag]))
assert(error_id(@() sc2.remove_disturbance("none")) == "GUILDA:Scenario:DisturbanceNotFound")
assert(error_id(@() sc2.add_offset("B001SG1", "delta", 0.1, 0, Tag="in")) == "GUILDA:Scenario:DuplicateTag")
assert(error_id(@() sc2.add_offset("B001SG1", "delta", 0.1, 0, Tag="t1")) == "GUILDA:Scenario:ReservedTag")
assert(error_id(@() sc2.add_offset("B001SG1", "delta", 0.1, 0, Tag="Fault001")) == "GUILDA:Scenario:ReservedTag")
assert(error_id(@() sc2.add_input("B002SG1", "Pmech", 0.01, [1,2], Tag="Parallel9")) == "GUILDA:Scenario:ReservedTag")
assert(error_id(@() sc2.add_fault("B003", [1,1])) == "GUILDA:Scenario:ZeroLengthTimeSpan")
assert(error_id(@() sc2.add_fault("B003", [2,1])) == "GUILDA:Scenario:InvalidTimeSpan")
% 利用者はタグを指定できない
assert(error_id(@() sc2.add_fault("B003", [1,2], Tag="f")) ~= "")
assert(error_id(@() sc2.add_trip("B003SG1", [1,2], Tag="f")) ~= "")
assert(error_id(@() sc2.add_open_branch("EL003", [1,2], Tag="f")) ~= "")


%% Overlapping and touching events of one target
net = new_ieee14();
sc = net.add_scenario("ov", Time=[0,3]);
sc.add_fault("B008", [1,1.05]);
assert(error_id(@() sc.add_fault("B008", [1.02,3])) == "GUILDA:Scenario:OverlappingEvents")
assert(error_id(@() sc.add_fault(["B003";"B008"], [0.5,1.02])) == "GUILDA:Scenario:OverlappingEvents")
assert(height(sc.tab_event) == 2, "失敗したら追加しない")
assert(sc.add_fault("B008", [1.05,1.1]) == "Fault002", "接する期間は重なりではない")
sc.add_open_branch("EL003", [1,1.05]);
assert(error_id(@() sc.add_open_branch("EL003", [0.5,1.02])) == "GUILDA:Scenario:OverlappingEvents")
assert(error_id(@() sc.add_open_branch("EL003", [1.02,2.5], Status="3open")) == "GUILDA:Scenario:OverlappingEvents")
[~, flag, out] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
assert(flag == 1 && isequal(out.phases.t1.', [0, 1, 1.05, 1.1]))
assert(isequal(out.phases.Fault001.', [false, true, false, false]) && isequal(out.phases.Fault002.', [false, false, true, false]))
assert(isequal(out.phases.Parallel001.', [false, true, false, false]))
% 故障と並列は独立: 同じブランチの地絡と開放の重なりは許す (ブランチの地絡はまだ計算できない)
s_tag = sc.add_fault("EL003", [1.02,1.03], Status="6LG", Point=0.5);
assert(error_id(@() net.simulate(sc.s_tag)) == "GUILDA:Scenario:NotYetSupported")
sc.remove_disturbance(s_tag);


%% Branch faults, one-circuit openings and local controller trips
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
s_lc = comp.a_LocalController{1}.s_tag;
sc = net.add_scenario("branch", Time=[0,2]);
s_f = sc.add_fault("EL003", [1,1.05], Status="3LG", Point=0.3);
tab = sc.tab_event(sc.tab_event.Tag == s_f, :);
assert(isequal(tab.Status, ["3LG";"none"]) && isequal(tab.Point, [0.3;0.3]))
assert(sc.add_fault("EL004", [1,1.05], Status="6LG", Point=0.99) == "Fault002")
% ブランチの Status と Point は必須。母線は "BG" だけで Point なし。範囲は開区間
assert(error_id(@() sc.add_fault("EL005", [1,2])) == "GUILDA:Scenario:InvalidFaultStatus")
assert(error_id(@() sc.add_fault("EL005", [1,2], Status="3LG")) == "GUILDA:Scenario:InvalidFaultStatus")
assert(error_id(@() sc.add_fault("EL005", [1,2], Point=0.3)) == "GUILDA:Scenario:InvalidFaultStatus")
assert(error_id(@() sc.add_fault("B008", [1,2], Status="3LG")) == "GUILDA:Scenario:InvalidFaultStatus")
assert(error_id(@() sc.add_fault("B008", [1,2], Point=0.3)) == "GUILDA:Scenario:InvalidFaultStatus")
for p = [0, 1, 1.2, -0.1]
    assert(error_id(@() sc.add_fault("EL005", [1,2], Status="3LG", Point=p)) == "GUILDA:Scenario:InvalidPoint")
end
assert(error_id(@() sc.add_fault(["B008";"EL005"], [1,2])) == "GUILDA:Scenario:MixedFaultTarget")
assert(error_id(@() sc.add_fault("B999", [1,2])) == "GUILDA:Scenario:UnknownFaultTarget")
assert(error_id(@() sc.add_open_branch("EL005", [1,2], Status="2open")) ~= "")
% 1 回線の開放とローカル制御器の解列は加えられる (計算はまだできない)
s_o = sc.add_open_branch("EL005", [1,2], Status="3open");
assert(isequal(sc.tab_event.Status(sc.tab_event.Tag == s_o), ["3open";"close"]))
s_t = sc.add_trip(s_lc, [1,2]);
assert(isequal(sc.tab_event.Target(sc.tab_event.Tag == s_t), [s_lc; s_lc]))
assert(error_id(@() net.simulate(sc.s_tag)) == "GUILDA:Scenario:NotYetSupported")
sc.remove_disturbance([s_f, "Fault002", s_o]);
ME = caught(@() net.simulate(sc.s_tag));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Scenario:NotYetSupported" && contains(ME.message, s_lc), ME.message)
sc.remove_disturbance(s_t);
assert(height(sc.tab_event) == 0)


%% Stored time; the Time and the settings of the call win for that call
net = new_ieee14();
sc = net.add_scenario("stored", Time=[0,2]);
sc.add_fault("B008", [1,1.05]);
res = DebugScript.helper.quiet(@() net.simulate("stored"));
assert(res.rv_t(end) == 2 && res.options.Tolerance == GUILDA.config("TimeSimulation", "Tolerance"))
res = DebugScript.helper.quiet(@() net.simulate("stored", Time=[0,1.5], Tolerance=1e-5));
assert(res.rv_t(end) == 1.5 && res.options.Tolerance == 1e-5 && isequal(sc.Time, [0,2]), "sc.Time は変わらない")
assert(GUILDA.config("TimeSimulation", "Tolerance") ~= 1e-5, "GUILDA.setting は変わらない")
% シナリオは設定を持たない (Options は廃止)
assert(~isprop(sc, "Options"))
assert(error_id(@() set_options(sc, struct("Tolerance", 1e-6))) ~= "")
assert(error_id(@() net.simulate("stored", Time=[2,1])) ~= "")
assert(error_id(@() net.add_scenario("x", Time=[2,1])) == "GUILDA:mustBeSimulationTime:InvalidTime")
assert(error_id(@() set_time(sc, [1,1])) == "GUILDA:mustBeSimulationTime:InvalidTime")
assert(error_id(@() set_time(sc, [])) ~= "", "Time は空にできない")
assert(~ismember("x", string(net.a_Scenario)), "失敗したら作らない")


%% Time defaults to [0, 10]; the disturbances do not change it
net = new_ieee14();
sc = net.add_scenario("free");
assert(isequal(sc.Time, [0,10]) && sc.Description == "")
sc.add_fault("B008", [1,1.05]);
sc.add_open_branch("EL003", [25,30]);            % 時間の外: 警告だけで時間は変わらない
lastwarn("");
ws = warning("off", "GUILDA:Scenario:OutsideTimeSpan");  c_ws = onCleanup(@() warning(ws));
res = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
clear c_ws
assert(res.rv_t(1) == 0 && res.rv_t(end) == 10)
assert(string(DebugScript.helper.msg_id()) == "GUILDA:Scenario:OutsideTimeSpan")
% 外乱のないシナリオも [0, 10]
net.add_scenario("empty");
res = DebugScript.helper.quiet(@() net.simulate("empty"));
assert(res.rv_t(1) == 0 && res.rv_t(end) == 10)
% タグのないシナリオ、シナリオのない系統は ScenarioNotFound で、タグの一覧か作り方を示す
ME = caught(@() net.simulate("nope"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:ScenarioNotFound" && contains(ME.message, "'free'") && contains(ME.message, "'empty'"), ME.message)
n0 = new_ieee14();
ME = caught(@() n0.simulate("free"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:ScenarioNotFound" && contains(ME.message, "add_scenario"), ME.message)
for k = 1:12
    n0.add_scenario("s" + k);
end
ME = caught(@() n0.simulate("nope"));
assert(contains(ME.message, "'s10'") && ~contains(ME.message, "'s11'") && contains(ME.message, "12 in all"), ME.message)


%% Children of the network: create, rename, copy, remove
net = new_ieee14();
st0 = net.sct_stale;
sc = net.add_scenario("own", Description="first");
assert(isa(sc, "Scenario") && sc.a_PowerNetwork == net && numel(net.a_Scenario) == 1 && net.a_Scenario{1} == sc)
assert(sc.s_tag == "own" && sc.Description == "first" && height(sc.tab_event) == 0 && height(sc.tab_offset) == 0 && height(sc.tab_input) == 0)
assert(isempty(sc.tab_parameter) && width(sc.tab_event) == 5 && width(sc.tab_offset) == 5 && width(sc.tab_input) == 6)
sc.add_fault("B008", [1,1.05]);
assert(DebugScript.helper.edit_flag(net) == "initialized", "シナリオは平衡点を古くしない")
[~, flag] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag, Time=[0,2]));
assert(flag == 1)
assert(error_id(@() Scenario(net, "direct")) == "MATLAB:class:MethodRestricted")

% タグは母線などの子と同じ名前空間: 重なれば番号を足し、INFO で示す
s_out = evalc("dup = net.add_scenario(""own"");");
assert(dup.s_tag == "own002" && contains(s_out, "own002"), s_out)
s_out = evalc("onbus = net.add_scenario(""B001"");");
assert(onbus.s_tag == "B001002" && contains(s_out, "Info") && contains(s_out, "B001002"), s_out)
assert(numel(net.a_Scenario) == 3)
% 改名も同じ規則。改名と外乱の編集は何も古くしない
onbus.s_tag = "B002";
assert(onbus.s_tag == "B002002")
onbus.s_tag = "renamed";
onbus.add_trip("B003SG1", [1,2]);
assert(onbus.s_tag == "renamed" && isequal(net.sct_stale, st0))
assert(DebugScript.helper.edit_flag(net) == "initialized")
% disp_tree はシナリオを子として表示する
s_tree = net.disp_tree();
assert(contains(s_tree, "own ") && contains(s_tree, "@Scenario"), s_tree)

% From: 外乱 (3 つの表、タグのまま) と Time, Description を別の系統へ複製する (元は残る)
sc.Time = [0,3];
sc.add_offset("B001SG1", "delta", 0.01, 0);
sc.add_disturbance("both", TimeSpan=[1.2,1.5], OffsetUnit="B001SG1", OffsetState="delta", OffsetValue=0.01, ...
                   InputUnit="B002SG1", InputName="Pmech", InputValue=[0, 0; 0.3, 0.01]);
net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
cp = net2.add_scenario("own", From=sc);
assert(cp ~= sc && cp.a_PowerNetwork == net2 && sc.a_PowerNetwork == net && cp.s_tag == "own")
assert(isequaln(cp.tab_event, sc.tab_event) && isequaln(cp.tab_offset, sc.tab_offset) && isequaln(cp.tab_input, sc.tab_input))
assert(isequal(cp.Time, [0,3]) && cp.Description == "first")
cp2 = net2.add_scenario("own2", From=sc, Time=[0,2], Description="second");
assert(isequal(cp2.Time, [0,2]) && cp2.Description == "second" && isequal(sc.Time, [0,3]))
r1 = DebugScript.helper.quiet(@() net.simulate(sc.s_tag, Time=[0,2]));
r2 = DebugScript.helper.quiet(@() net2.simulate(cp.s_tag, Time=[0,2]));
assert(isequaln(r1.rm_variable, r2.rm_variable))
% simulate はその系統のシナリオをタグで選ぶ (別の系統のシナリオは選べない)
assert(error_id(@() net.simulate("own2")) == "GUILDA:PowerNetwork:ScenarioNotFound")
% 複製先の系統にない対象は検査で止まり、何も作らない
n9 = DebugScript.helper.quiet(@() network.IEEE9bus());
far = net.add_scenario("far");
far.add_fault("B014", [1,1.05]);
assert(error_id(@() n9.add_scenario("far", From=far)) == "GUILDA:Scenario:UnknownFaultTarget")
assert(isempty(n9.a_Scenario))

% 削除: シナリオを delete する
net2.remove_scenario("own");
assert(~isvalid(cp) && numel(net2.a_Scenario) == 1 && isvalid(sc))
assert(error_id(@() net2.remove_scenario("own")) == "GUILDA:PowerNetwork:ScenarioNotFound")
assert(error_id(@() net.remove_scenario(["own","nosuch"])) == "GUILDA:PowerNetwork:ScenarioNotFound")
assert(numel(net.a_Scenario) == 4, "失敗したら何も外さない")
net.remove_scenario(["own002","renamed"]);
assert(~isvalid(dup) && ~isvalid(onbus) && numel(net.a_Scenario) == 2)
assert(DebugScript.helper.edit_flag(net) == "initialized")


%% Unknown tags at add and at run time
net = new_ieee14();
% 系統に属するシナリオへの追加はその場で検査し、失敗したら追加しない
sc = net.add_scenario("tags");
assert(error_id(@() sc.add_fault("B999", [1,2])) == "GUILDA:Scenario:UnknownFaultTarget")
assert(error_id(@() sc.add_open_branch("EL999", [1,2])) == "GUILDA:Scenario:UnknownParallelTarget")
assert(error_id(@() sc.add_trip("B999SG1", [1,2])) == "GUILDA:Scenario:UnknownParallelTarget")
assert(error_id(@() sc.add_open_branch("B001SG1", [1,2])) == "GUILDA:Scenario:InvalidEventRows", "機器の開放は open (add_trip)")
assert(error_id(@() sc.add_offset("B001SG1", "nosuch", 0.1)) == "GUILDA:Scenario:UnknownOffsetState")
assert(error_id(@() sc.add_input("B002SG1", "nosuch", 0.1, [1,2])) == "GUILDA:Scenario:UnknownInputName")
assert(height(sc.tab_event) == 0 && height(sc.tab_offset) == 0 && height(sc.tab_input) == 0)

% 実行時に、そのときの系統で再び検査する (系統の編集後)
agc = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
sc.add_trip(agc.s_tag, [1,2]);
[~, flag] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag, Time=[0,2]));
assert(flag == 1)
net.remove_global_controller(agc.s_tag);
DebugScript.helper.quiet(@() net.initialize);
assert(error_id(@() net.simulate(sc.s_tag, Time=[0,2])) == "GUILDA:Scenario:UnknownParallelTarget")


%% One scenario per run, chosen by tag
net = new_ieee14();
a = net.add_scenario("A");  a.add_fault("B008", [1,1.05]);
b = net.add_scenario("B");  b.add_fault("B003", [2,2.05]);
assert(error_id(@() net.simulate(["A","B"])) ~= "")
assert(error_id(@() net.simulate("A", "B")) ~= "")
% 別の系統のシナリオのタグは ScenarioNotFound
other = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() other.initialize);
other.add_scenario("o").add_fault("B008", [1,1.05]);
assert(error_id(@() net.simulate("o")) == "GUILDA:PowerNetwork:ScenarioNotFound")


%% Input time series: storage, interpolation and checks
net = new_ieee14();
g2  = net.a_Bus{2}.a_Component{1};
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
sc = net.add_scenario("series", Time=[0,4]);
% 行列 [t, v] と table は同じ行になる。時系列の既定の補間は "foh"、一定値は ""
s1 = sc.add_input("B002SG1", "Pmech", [0, 0; 2, 0.02], [1,3]);
s2 = sc.add_input("B002SG1", "Pmech", table([0; 0.02], [0; 2], 'VariableNames', ["Pmech","Time"]), [1,3]);
assert(s1 == "input1" && s2 == "input2")
tab = sc.tab_input;
assert(isequal(tab.InputValue{1}, [0, 0; 2, 0.02]) && isequal(tab.InputValue{2}, tab.InputValue{1}))
assert(all(tab.InputMethod == "foh"))
sc.add_input("B002SG1", ["Vfield";"Pmech"], [0.01; 0], [1,2], Tag="const");
assert(sc.tab_input.InputMethod(end) == "" && isequal(sc.tab_input.InputValue{end}, [0.01; 0]))
sc.add_disturbance("zoh", TimeSpan=[1,3], InputUnit="B002SG1", InputName="Pmech", InputValue=[0, 0.1; 1, 0], InputMethod="zoh");
assert(sc.tab_input.InputMethod(end) == "zoh")
% 関数ハンドルを持たない
assert(~any(cellfun(@(v) isa(v, "function_handle"), sc.tab_input.InputValue)))
sct = struct(sc, false);
assert(isequaln(sct.tab_input, sc.tab_input) && isequal(sct.Time, [0,4]))

% 計算: 2 つの "foh" の傾き (各 0.01/s) と "zoh" (最初の 1 s だけ 0.1)、一定値の和。最後の点の後は値を保つ
r  = DebugScript.helper.quiet(@() net.simulate(sc.s_tag)).odeResults;
Pm = r.Bus(2).Component(1).U.Pmech;
f_expect = @(t) 2*0.01*min(max(t-1, 0), 2) + 0.1*(t >= 1 & t < 2);
lv = (r.t > 1.001 & r.t < 1.999) | (r.t > 2.001 & r.t < 2.999);
assert(max(abs(Pm(lv) - (Pm0 + f_expect(r.t(lv))))) < 1e-8)
assert(max(abs(Pm(r.t > 3.001) - Pm0)) < 1e-8)

% 検査: 時刻、列の数、table の変数、一定値への Method、関数
assert(error_id(@() sc.add_input("B002SG1", "Pmech", [1, 0; 2, 0.1], [1,3])) == "GUILDA:Scenario:InvalidInputSeries")
assert(error_id(@() sc.add_input("B002SG1", "Pmech", [0, 0; 0, 0.1], [1,3])) == "GUILDA:Scenario:InvalidInputSeries")
assert(error_id(@() sc.add_input("B002SG1", "Pmech", [0, 0; 1, NaN], [1,3])) == "GUILDA:Scenario:InvalidInputSeries")
assert(error_id(@() sc.add_input("B002SG1", "Pmech", [0, 0, 0; 1, 0.1, 0], [1,3])) == "GUILDA:Scenario:InvalidInputSeries")
assert(error_id(@() sc.add_input("B002SG1", "Pmech", table([0; 1], [0; 0.1], 'VariableNames', ["t","Pmech"]), [1,3])) == "GUILDA:Scenario:InvalidInputSeries")
assert(error_id(@() sc.add_input("B002SG1", "Pmech", 0.1, [1,3], Method="zoh")) == "GUILDA:Scenario:MethodWithoutSeries")
assert(error_id(@() sc.add_disturbance("m", TimeSpan=[1,3], InputUnit="B002SG1", InputName="Pmech", InputValue=0.1, InputMethod="foh")) == "GUILDA:Scenario:MethodWithoutSeries")
assert(error_id(@() sc.add_input("B002SG1", "Pmech", @(t) 0.01*t, [1,3])) == "MATLAB:validators:mustBeA")
assert(height(sc.tab_input) == 4, "失敗したら追加しない")

% 1 点の時系列は同じ一定値と同じ軌道
net = new_ieee14();
a = net.add_scenario("one", Time=[0,2]);  a.add_input("B002SG1", "Pmech", [0, 0.05], [1,2]);
b = net.add_scenario("con", Time=[0,2]);  b.add_input("B002SG1", "Pmech", 0.05, [1,2]);
assert(a.tab_input.InputMethod == "foh" && b.tab_input.InputMethod == "")
ra = DebugScript.helper.quiet(@() net.simulate(a.s_tag));
rb = DebugScript.helper.quiet(@() net.simulate(b.s_tag));
assert(isequaln(ra.rm_variable, rb.rm_variable))


%% Scenario files: the content, the time series and its method round trip
net = DebugScript.helper.build_ieee14();
sc = net.add_scenario("series", Time=[0, 5], Description="inputs");
sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.02; 2, 0.01], [1, 4], Method="spline");
sc.add_input("B002SG1", ["Pmech"; "Vfield"], [0, 0.1, 0.2], [1, 2], Method="zoh");
sc.add_input("B002SG1", "Vfield", 0.01, [2, 3]);
sc.add_offset("B001SG1", ["delta"; "omega"], [0.1; 1e-3], 0.5);
sc.add_fault("EL003", [1, Inf], Status="3LG", Point=0.3);
sc.add_trip("B003SG1", [1, 2]);
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
s_file = fullfile(s_path, "scenario", "series.json");
sct = jsondecode(fileread(s_file));
assert(sct.Format == "GUILDAscenario" && sct.version == 2 && ~isfield(sct, "Tag"), "タグはファイル名だけ")
assert(isequal(sort(string(fieldnames(sct))).', sort(["Format","version","Description","Time","Event","Offset","Input"])))
assert(isequal(sct.Time(:).', [0, 5]) && sct.Description == "inputs")
assert(isequal(string({sct.Event.Tag}), ["Fault001","Fault001","Parallel001","Parallel001"]))
assert(isequal([sct.Event.Time], [1, Inf, 1, 2]) && isequaln([sct.Event.Point], [0.3, 0.3, NaN, NaN]), "Infinity と NaN")
e = sct.Input{1};
assert(isequal(e.InputValue.Time(:).', [0, 1, 2]) && e.InputMethod == "spline")
assert(~isfield(e, "OffsetUnit"), "空の項目は書かない")
assert(~isfield(sct.Input{3}, "InputMethod") && sct.Input{3}.InputValue == 0.01)
assert(sct.Offset.TimeSpan == 0.5, "オフセットの時刻は 1 つ")
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
sc2 = net2.a_Scenario{1};
assert(isequaln(sc2.tab_event, sc.tab_event) && isequaln(sc2.tab_offset, sc.tab_offset) && isequaln(sc2.tab_input, sc.tab_input))
assert(isequal(sc2.tab_input.InputMethod, ["spline"; "zoh"; ""]))
% A scenario holds no function handles: struct and the table are plain data
c_val = struct2cell(DebugScript.helper.quiet(@() struct(sc)));
assert(~any(cellfun(@(v) isa(v, "function_handle"), c_val)))
assert(~any(cellfun(@(v) isa(v, "function_handle"), sc.tab_input.InputValue)))


%% Scenario files: a series without InputMethod reads as "foh"
net = DebugScript.helper.build_ieee14();
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
mkdir(fullfile(s_path, "scenario"));
writelines(['{"Format": "GUILDAscenario", "version": 2, "Input": [' ...
            '{"Tag": "ramp", "TimeSpan": [1, 3], "InputUnit": "B002SG1", "InputName": ["Pmech"], ' ...
            '"InputValue": {"Time": [0, 2], "Value": [[0], [0.02]]}}], ' ...
            '"Event": [{"Tag": "Parallel007", "Target": "B003SG1", "Time": 1, "Status": "open", "Point": 0.5}, ' ...
            '{"Tag": "Parallel007", "Target": "B003SG1", "Time": 2, "Status": "close"}]}'], ...
           fullfile(s_path, "scenario", "hand.json"));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
tab = net2.a_Scenario{1}.tab_input;
assert(tab.InputMethod == "foh" && isequal(tab.InputValue{1}, [0, 0; 2, 0.02]))
assert(isequal(net2.a_Scenario{1}.Time, [0, 10]), "Time を省くと既定")
tab = net2.a_Scenario{1}.tab_event;
assert(isequal(tab.Tag, ["Parallel007";"Parallel007"]) && all(isnan(tab.Point)), "タグのまま、並列の Point は NaN")
assert(net2.a_Scenario{1}.add_trip("B002SG1", [1,2]) == "Parallel008")


%% Scenario files: version 1 and malformed events are not read
net = DebugScript.helper.build_ieee14();
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
mkdir(fullfile(s_path, "scenario"));
s_file = fullfile(s_path, "scenario", "old.json");
writelines('{"Format": "GUILDAscenario", "version": 1, "Disturbances": [{"Tag": "f", "TimeSpan": [1, 2], "FaultBus": ["B008"]}]}', s_file);
ME = caught(@() PowerNetwork.import(s_path, Initialize=false));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:ScenarioJson" && contains(ME.message, "version 1"), ME.message)
writelines('{"Format": "GUILDAscenario", "version": 2, "Event": [{"Tag": "fault1", "Target": "B008", "Time": 1, "Status": "BG"}]}', s_file);
ME = caught(@() PowerNetwork.import(s_path, Initialize=false));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:ScenarioJson" && contains(ME.message, "fault1"), ME.message)
writelines('{"Format": "GUILDAscenario", "version": 2, "Event": [{"Tag": "Fault001", "Target": "B008", "Status": "BG"}]}', s_file);
assert(error_id(@() PowerNetwork.import(s_path, Initialize=false)) == "GUILDA:PowerNetwork:ScenarioJson")
writelines('{"Format": "GUILDAscenario", "version": 2, "Event": [{"Tag": "Fault001", "Target": "B008", "Time": 1, "Status": "BG"}]}', s_file);
assert(error_id(@() PowerNetwork.import(s_path, Initialize=false)) == "GUILDA:Scenario:InvalidEventRows", "終了の行がない")


function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end

function set_options(sc, s)
    sc.Options = s;
end

function ME = caught(f)
    ME = [];
    try
        DebugScript.helper.quiet(f);
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end

function set_time(sc, t)
    sc.Time = t;
end

function net = new_ieee14()
    net = DebugScript.helper.build_ieee14();
    DebugScript.helper.quiet(@() net.initialize);
end

function [s_dir, c] = temp_folder()
    s_dir = tempname;
    mkdir(s_dir);
    c = onCleanup(@() rmdir(s_dir, "s"));
end
