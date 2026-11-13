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

%% A fault then a permanent opening equals the general form
net = new_ieee14();
sc = net.add_scenario("case1", Time=[0,3]);
assert(sc.add_fault("B008", [1,1.07]) == "fault1")
assert(sc.add_open_branch("EL003", [1.07,3]) == "open1")
assert(height(sc.tab_disturbance) == 2)
[r_sc, flag, out_sc] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
assert(flag == 1 && r_sc.rv_t(end) == 3)

net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
sc2 = net2.add_scenario("case1", Time=[0,3]);
sc2.add_disturbance("fault1", TimeSpan=[1,1.07], FaultBus="B008");
sc2.add_disturbance("open1", TimeSpan=[1.07,3], OpenBranch="EL003");
[r_ev, ~, out_ev] = DebugScript.helper.quiet(@() net2.simulate("case1"));
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
assert(sc.s_tag == "own" && sc.Description == "first" && height(sc.tab_disturbance) == 0)
assert(isempty(sc.tab_parameter) && width(sc.tab_disturbance) == 12)
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

% From: 外乱と Time, Description を別の系統へ複製する (元は残る)
sc.Time = [0,3];
net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
cp = net2.add_scenario("own", From=sc);
assert(cp ~= sc && cp.a_PowerNetwork == net2 && sc.a_PowerNetwork == net && cp.s_tag == "own")
assert(isequaln(cp.tab_disturbance, sc.tab_disturbance) && isequal(cp.Time, [0,3]) && cp.Description == "first")
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
[~, flag] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag, Time=[0,2]));
assert(flag == 1)
net.remove_global_controller(agc.s_tag);
DebugScript.helper.quiet(@() net.initialize);
assert(error_id(@() net.simulate(sc.s_tag, Time=[0,2])) == "GUILDA:Scenario:UnknownTripUnit")


%% One scenario per run, chosen by tag
net = new_ieee14();
a = net.add_scenario("A");  a.add_fault("B008", [1,1.05], Tag="ev");
b = net.add_scenario("B");  b.add_fault("B003", [2,2.05], Tag="ev");
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
assert(height(sc.tab_disturbance) == 4, "失敗したら追加しない")

% 1 点の時系列は同じ一定値と同じ軌道
net = new_ieee14();
a = net.add_scenario("one", Time=[0,2]);  a.add_input("B002SG1", "Pmech", [0, 0.05], [1,2]);
b = net.add_scenario("con", Time=[0,2]);  b.add_input("B002SG1", "Pmech", 0.05, [1,2]);
assert(a.tab_disturbance.InputMethod == "foh" && b.tab_disturbance.InputMethod == "")
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
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
s_file = fullfile(s_path, "scenario", "series.json");
sct = jsondecode(fileread(s_file));
assert(sct.Format == "GUILDAscenario" && sct.version == 1 && ~isfield(sct, "Tag"), "タグはファイル名だけ")
assert(isequal(sct.Time(:).', [0, 5]) && sct.Description == "inputs")
e = sct.Disturbances{1};
assert(isequal(e.InputValue.Time(:).', [0, 1, 2]) && e.InputMethod == "spline")
assert(~isfield(e, "FaultBus") && ~isfield(e, "OffsetUnit"), "空の項目は書かない")
assert(~isfield(sct.Disturbances{3}, "InputMethod") && sct.Disturbances{3}.InputValue == 0.01)
assert(sct.Disturbances{4}.TimeSpan == 0.5, "オフセットの時刻は 1 つ")
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
assert(isequaln(net2.a_Scenario{1}.tab_disturbance, sc.tab_disturbance))
assert(isequal(net2.a_Scenario{1}.tab_disturbance.InputMethod, ["spline"; "zoh"; ""; ""]))
% A scenario holds no function handles: struct and the table are plain data
c_val = struct2cell(DebugScript.helper.quiet(@() struct(sc)));
assert(~any(cellfun(@(v) isa(v, "function_handle"), c_val)))
assert(~any(cellfun(@(v) isa(v, "function_handle"), sc.tab_disturbance.InputValue)))


%% Scenario files: a series without InputMethod reads as "foh"
net = DebugScript.helper.build_ieee14();
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
mkdir(fullfile(s_path, "scenario"));
writelines(['{"Format": "GUILDAscenario", "version": 1, "Disturbances": [' ...
            '{"Tag": "ramp", "TimeSpan": [1, 3], "InputUnit": "B002SG1", "InputName": ["Pmech"], ' ...
            '"InputValue": {"Time": [0, 2], "Value": [[0], [0.02]]}}]}'], ...
           fullfile(s_path, "scenario", "hand.json"));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
tab = net2.a_Scenario{1}.tab_disturbance;
assert(tab.InputMethod == "foh" && isequal(tab.InputValue{1}, [0, 0; 2, 0.02]))
assert(isequal(net2.a_Scenario{1}.Time, [0, 10]), "Time を省くと既定")


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
