% F31 シミュレーションのシナリオ (Scenario)
%
%   sc = net.add_scenario("case1", Time=[0,20]);   % 系統の子として作る (net.a_Scenario, sc.a_PowerNetwork)
%   sc.add_fault("B008", [0.10,0.17]);           % 地絡
%   sc.add_open_branch("EL003", [0.17,20]);      % その後の回線開放 (終わりまで)
%   result  = net.simulate(sc);                  % 保存した Time と Options で実行
%
% 複数の外乱を持つシナリオ、系統の子としての作成・改名・削除・複製、タグの検査、入力の時系列を確認する。
% CSV の入出力は S6 (系統のファイルの scenario/*.json) で、判定は S3 (ResultODE.judge_out_of_step) で
% 新しいテストに置き換える。
%
% 実行: runtests("DebugScript.test_F31_scenario")  または  DebugScript.run_all("Features","F31")

% 各テストは新しい系統で始める (共通設定の handle はテストの間で共有されるため)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% A fault then a permanent opening equals two old-style events
net = new_ieee14();
sc = net.add_scenario("case1", Time=[0,3]);
assert(sc.add_fault("B008", [1,1.07]) == "fault1")
assert(sc.add_open_branch("EL003", [1.07,3]) == "open1")
assert(height(sc.tab_disturbance) == 2)
[r_sc, flag, out_sc] = DebugScript.helper.quiet(@() net.simulate(sc));
assert(flag == 1 && r_sc.rv_t(end) == 3)

net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
ev1 = DebugScript.helper.scenario("fault1", net2, "TimeSpan", [1,1.07], "FaultBus", "B008");
ev2 = DebugScript.helper.scenario("open1",  net2, "TimeSpan", [1.07,3], "OpenBranch", "EL003");
[r_ev, ~, out_ev] = DebugScript.helper.quiet(@() net2.simulate([0,3], ev1, ev2));
assert(isequaln(r_sc.rm_variable, r_ev.rm_variable) && isequaln(r_sc.rv_t, r_ev.rv_t))
assert(isequal(out_sc.phases, out_ev.phases))
assert(isequal(string(out_sc.phases.Properties.VariableNames), ["t1","t2","fault1","open1","NoAction1"]))


%% The general form and the convenience methods give the same rows
net = new_ieee14();
sc1 = net.add_scenario("a");
sc1.add_disturbance("f", TimeSpan=[1,1.05], FaultBus="B008");
sc1.add_disturbance("os", TimeSpan=0, OffsetUnit="B001SG1", OffsetState="delta", OffsetValue=0.1);
sc2 = net.add_scenario("b");
sc2.add_fault("B008", [1,1.05], Tag="f");
sc2.add_offset("B001SG1", "delta", 0.1, 0, Tag="os");
assert(isequaln(sc1.tab_disturbance, sc2.tab_disturbance))
% 自動のタグは種類ごとに番号を付ける
sc2.add_trip("B002SG1", [2,3]);
sc2.add_trip("B003SG1", [2,3]);
sc2.add_input("B002SG1", "Pmech", 0.01, [1,2]);
assert(isequal(sc2.tab_disturbance.Tag.', ["f","os","trip1","trip2","input1"]))
sc2.remove_disturbance(["trip1","os"]);
assert(isequal(sc2.tab_disturbance.Tag.', ["f","trip2","input1"]))
assert(error_id(@() sc2.remove_disturbance("none")) == "GUILDA:Scenario:DisturbanceNotFound")
assert(error_id(@() sc2.add_fault("B003", [1,2], Tag="f")) == "GUILDA:Scenario:DuplicateTag")
assert(error_id(@() sc2.add_fault("B003", [1,2], Tag="t1")) == "GUILDA:Scenario:ReservedTag")
assert(error_id(@() sc2.add_fault("B003", [1,1])) == "GUILDA:Scenario:ZeroLengthTimeSpan")


%% Stored time and options; the call wins
net = new_ieee14();
sc = net.add_scenario("stored", Time=[0,2]);
sc.Options = struct("Tolerance", 1e-6, "AbsoluteTolerance", 1e-6);
sc.add_fault("B008", [1,1.05]);
res = DebugScript.helper.quiet(@() net.simulate(sc));
assert(res.rv_t(end) == 2 && res.options.Tolerance == 1e-6 && res.options.AbsoluteTolerance == 1e-6)
res = DebugScript.helper.quiet(@() net.simulate([0,1.5], sc, Tolerance=1e-5));
assert(res.rv_t(end) == 1.5 && res.options.Tolerance == 1e-5 && res.options.AbsoluteTolerance == 1e-6)
assert(GUILDA.config("TimeSimulation", "Tolerance") ~= 1e-6, "GUILDA.setting は変わらない")
% 異なる Time や Options のシナリオを一緒に実行するときは呼び出しで与える
other = net.add_scenario("other", Time=[0,3]);
other.Options = struct("Tolerance", 1e-5);
other.add_offset("B002SG1", "delta", 0.01, 0);
assert(error_id(@() net.simulate(sc, other)) == "GUILDA:PowerNetwork:ScenarioTimeConflict")
assert(error_id(@() net.simulate([0,2], sc, other)) == "GUILDA:PowerNetwork:ScenarioOptionConflict")
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,2], sc, other, Tolerance=1e-6));
assert(flag == 1)
assert(error_id(@() set_options(sc, struct("Tol", 1))) == "GUILDA:Scenario:UnknownOption")
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
res = DebugScript.helper.quiet(@() net.simulate(sc));
clear c_ws
assert(res.rv_t(1) == 0 && res.rv_t(end) == 10)
assert(string(DebugScript.helper.msg_id()) == "GUILDA:Scenario:OutsideTimeSpan")
% シナリオも時間もなければ [0, 10]
res = DebugScript.helper.quiet(@() net.simulate());
assert(res.rv_t(1) == 0 && res.rv_t(end) == 10)


%% Children of the network: create, rename, copy, remove
net = new_ieee14();
st0 = net.sct_stale;
sc = net.add_scenario("own", Description="first");
assert(isa(sc, "Scenario") && sc.a_PowerNetwork == net && numel(net.a_Scenario) == 1 && net.a_Scenario{1} == sc)
assert(sc.s_tag == "own" && sc.Description == "first" && height(sc.tab_disturbance) == 0)
assert(isempty(sc.tab_parameter) && width(sc.tab_disturbance) == 12)
sc.add_fault("B008", [1,1.05]);
assert(DebugScript.helper.edit_flag(net) == "initialized", "シナリオは平衡点を古くしない")
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,2], sc));
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

% From: 外乱と設定を別の系統へ複製する (元は残る)
sc.Time = [0,3];
sc.Options = struct("Tolerance", 1e-6);
net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
cp = net2.add_scenario("own", From=sc);
assert(cp ~= sc && cp.a_PowerNetwork == net2 && sc.a_PowerNetwork == net && cp.s_tag == "own")
assert(isequaln(cp.tab_disturbance, sc.tab_disturbance) && isequal(cp.Time, [0,3]) && cp.Description == "first")
assert(isequal(cp.Options, sc.Options))
cp2 = net2.add_scenario("own2", From=sc, Time=[0,2], Description="second");
assert(isequal(cp2.Time, [0,2]) && cp2.Description == "second" && isequal(sc.Time, [0,3]))
r1 = DebugScript.helper.quiet(@() net.simulate([0,2], sc));
r2 = DebugScript.helper.quiet(@() net2.simulate([0,2], cp));
assert(isequaln(r1.rm_variable, r2.rm_variable))
assert(error_id(@() net.simulate([0,2], cp)) == "GUILDA:Scenario:OtherNetwork")
% 複製先の系統にない対象は検査で止まり、何も作らない
n9 = DebugScript.helper.quiet(@() network.IEEE9bus());
far = net.add_scenario("far");
far.add_fault("B014", [1,1.05]);
assert(error_id(@() n9.add_scenario("far", From=far)) == "GUILDA:Scenario:UnknownFaultBus")
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
assert(error_id(@() sc.add_fault("B999", [1,2])) == "GUILDA:Scenario:UnknownFaultBus")
assert(error_id(@() sc.add_open_branch("EL999", [1,2])) == "GUILDA:Scenario:UnknownOpenBranch")
assert(error_id(@() sc.add_trip("B999SG1", [1,2])) == "GUILDA:Scenario:UnknownTripUnit")
assert(error_id(@() sc.add_offset("B001SG1", "nosuch", 0.1)) == "GUILDA:Scenario:UnknownOffsetState")
assert(error_id(@() sc.add_input("B002SG1", "nosuch", 0.1, [1,2])) == "GUILDA:Scenario:UnknownInputName")
assert(height(sc.tab_disturbance) == 0)

% 実行時に、そのときの系統で再び検査する (系統の編集後)
agc = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
sc.add_trip(agc.s_tag, [1,2]);
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,2], sc));
assert(flag == 1)
net.remove_global_controller(agc.s_tag);
DebugScript.helper.quiet(@() net.initialize);
assert(error_id(@() net.simulate([0,2], sc)) == "GUILDA:Scenario:UnknownTripUnit")


%% Disturbance tags of scenarios simulated together are unique
net = new_ieee14();
a = net.add_scenario("A");  a.add_fault("B008", [1,1.05], Tag="ev");
b = net.add_scenario("B");  b.add_fault("B003", [2,2.05], Tag="ev");
assert(error_id(@() net.simulate([0,3], a, b)) == "GUILDA:Scenario:DuplicateRunTag")
assert(error_id(@() net.simulate([0,3], [a, b])) == "GUILDA:Scenario:ScenarioArray")


%% Scenarios of another network are rejected
net = new_ieee14();
other = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() other.initialize);
sc_o = other.add_scenario("o");
sc_o.add_fault("B008", [1,1.05]);
ok = net.add_scenario("ok");
ok.add_fault("B008", [1,1.05]);
assert(error_id(@() net.simulate([0,2], sc_o)) == "GUILDA:Scenario:OtherNetwork")
assert(error_id(@() net.simulate([0,2], ok, sc_o)) == "GUILDA:Scenario:OtherNetwork")


%% Input time series: storage, interpolation and checks
net = new_ieee14();
g2  = net.a_Bus{2}.a_Component{1};
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
sc = net.add_scenario("series", Time=[0,4]);
% 行列 [t, v] と table は同じ行になる。時系列の既定の補間は "foh"、一定値は ""
s1 = sc.add_input("B002SG1", "Pmech", [0, 0; 2, 0.02], [1,3]);
s2 = sc.add_input("B002SG1", "Pmech", table([0; 0.02], [0; 2], 'VariableNames', ["Pmech","Time"]), [1,3]);
assert(s1 == "input1" && s2 == "input2")
tab = sc.tab_disturbance;
assert(isequal(tab.InputValue{1}, [0, 0; 2, 0.02]) && isequal(tab.InputValue{2}, tab.InputValue{1}))
assert(all(tab.InputMethod == "foh"))
sc.add_input("B002SG1", ["Vfield";"Pmech"], [0.01; 0], [1,2], Tag="const");
assert(sc.tab_disturbance.InputMethod(end) == "" && isequal(sc.tab_disturbance.InputValue{end}, [0.01; 0]))
sc.add_disturbance("zoh", TimeSpan=[1,3], InputUnit="B002SG1", InputName="Pmech", InputValue=[0, 0.1; 1, 0], InputMethod="zoh");
assert(sc.tab_disturbance.InputMethod(end) == "zoh")
% 関数ハンドルを持たない
assert(~any(cellfun(@(v) isa(v, "function_handle"), sc.tab_disturbance.InputValue)))
sct = struct(sc, false);
assert(isequaln(sct.tab_disturbance, sc.tab_disturbance) && isequal(sct.Time, [0,4]))

% 計算: 2 つの "foh" の傾き (各 0.01/s) と "zoh" (最初の 1 s だけ 0.1)、一定値の和。最後の点の後は値を保つ
r  = DebugScript.helper.quiet(@() net.simulate(sc)).odeResults;
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
assert(height(sc.tab_disturbance) == 4, "失敗したら追加しない")

% 1 点の時系列は同じ一定値と同じ軌道
net = new_ieee14();
a = net.add_scenario("one", Time=[0,2]);  a.add_input("B002SG1", "Pmech", [0, 0.05], [1,2]);
b = net.add_scenario("con", Time=[0,2]);  b.add_input("B002SG1", "Pmech", 0.05, [1,2]);
assert(a.tab_disturbance.InputMethod == "foh" && b.tab_disturbance.InputMethod == "")
ra = DebugScript.helper.quiet(@() net.simulate(a));
rb = DebugScript.helper.quiet(@() net.simulate(b));
assert(isequaln(ra.rm_variable, rb.rm_variable))


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

function set_time(sc, t)
    sc.Time = t;
end

function net = new_ieee14()
    net = DebugScript.helper.build_ieee14();
    DebugScript.helper.quiet(@() net.initialize);
end
