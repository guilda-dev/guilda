% F31 シミュレーションのシナリオ (Scenario)
%
%   sc = Scenario("case1", Time=[0,20]);
%   sc.add_fault("B008", [0.10,0.17]);           % 地絡
%   sc.add_open_branch("EL003", [0.17,20]);      % その後の回線開放 (終わりまで)
%   net.add_scenario(sc);                        % net.a_Scenario, sc.a_PowerNetwork
%   result  = net.simulate(sc);                  % 保存した Time と Options で実行
%   verdict = sc.judge(result);                  % "stable" / "out-of-step" / "incomplete"
%
% 複数の外乱を持つシナリオ、系統との所有関係、タグの検査、CSV の入出力、判定関数、
% 旧 ODEevent の互換を確認する。
%
% 実行: runtests("DebugScript.test_F31_scenario")  または  DebugScript.run_all("Features","F31")

% 各テストは新しい系統で始める (共通設定の handle はテストの間で共有されるため)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% A fault then a permanent opening equals two old-style events
net = new_ieee14();
sc = Scenario("case1", Time=[0,3]);
assert(sc.add_fault("B008", [1,1.07]) == "fault1")
assert(sc.add_open_branch("EL003", [1.07,3]) == "open1")
net.add_scenario(sc);
assert(height(sc.tab_disturbance) == 2)
[r_sc, flag, out_sc] = DebugScript.helper.quiet(@() net.simulate(sc));
assert(flag == 1 && r_sc.rv_t(end) == 3)

net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
ws = warning("off", "all");  c_ws = onCleanup(@() warning(ws));
ev1 = ODEevent("fault1", net2, "TimeSpan", [1,1.07], "FaultBus", "B008");
ev2 = ODEevent("open1",  net2, "TimeSpan", [1.07,3], "OpenBranch", "EL003");
clear c_ws
[r_ev, ~, out_ev] = DebugScript.helper.quiet(@() net2.simulate([0,3], ev1, ev2));
assert(isequaln(r_sc.rm_variable, r_ev.rm_variable) && isequaln(r_sc.rv_t, r_ev.rv_t))
assert(isequal(out_sc.phases, out_ev.phases))
assert(isequal(string(out_sc.phases.Properties.VariableNames), ["t1","t2","fault1","open1","NoAction1"]))


%% The general form and the convenience methods give the same rows
net = new_ieee14();
sc1 = Scenario("a");
sc1.add_disturbance("f", TimeSpan=[1,1.05], FaultBus="B008");
sc1.add_disturbance("os", TimeSpan=0, OffsetUnit="B001SG1", OffsetState="delta", OffsetValue=0.1);
sc2 = Scenario("b");
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
sc = Scenario("stored", Time=[0,2], Options=struct("Tolerance", 1e-6, "AbsoluteTolerance", 1e-6));
sc.add_fault("B008", [1,1.05]);
net.add_scenario(sc);
res = DebugScript.helper.quiet(@() net.simulate(sc));
assert(res.rv_t(end) == 2 && res.options.Tolerance == 1e-6 && res.options.AbsoluteTolerance == 1e-6)
res = DebugScript.helper.quiet(@() net.simulate([0,1.5], sc, Tolerance=1e-5));
assert(res.rv_t(end) == 1.5 && res.options.Tolerance == 1e-5 && res.options.AbsoluteTolerance == 1e-6)
assert(GUILDA.config("TimeSimulation", "Tolerance") ~= 1e-6, "GUILDA.setting は変わらない")
% 異なる Time や Options のシナリオを一緒に実行するときは呼び出しで与える
other = Scenario("other", Time=[0,3], Options=struct("Tolerance", 1e-5));
other.add_offset("B002SG1", "delta", 0.01, 0);
net.add_scenario(other);
assert(error_id(@() net.simulate(sc, other)) == "GUILDA:PowerNetwork:ScenarioTimeConflict")
assert(error_id(@() net.simulate([0,2], sc, other)) == "GUILDA:PowerNetwork:ScenarioOptionConflict")
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,2], sc, other, Tolerance=1e-6));
assert(flag == 1)
assert(error_id(@() set_options(sc, struct("Tol", 1))) == "GUILDA:Scenario:UnknownOption")
assert(error_id(@() Scenario("x", Time=[2,1])) == "GUILDA:Scenario:InvalidTime")


%% Ownership: add, remove, move, copy
net = new_ieee14();
sc = Scenario("own");
sc.add_fault("B008", [1,1.05]);
assert(isempty(sc.a_PowerNetwork))
net.add_scenario(sc);
assert(sc.a_PowerNetwork == net && numel(net.a_Scenario) == 1 && net.a_Scenario{1} == sc)
net.add_scenario(sc);                                % 同じものを再度: 何もしない
assert(numel(net.a_Scenario) == 1)
assert(DebugScript.helper.edit_flag(net) == "initialized", "シナリオは平衡点を古くしない")
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,2], sc));
assert(flag == 1)

% 同じタグの別のシナリオは追加できない
dup = Scenario("own");
assert(error_id(@() net.add_scenario(dup)) == "GUILDA:PowerNetwork:ScenarioTagInUse")
assert(isempty(dup.a_PowerNetwork) && numel(net.a_Scenario) == 1)
assert(error_id(@() net.add_scenario({Scenario("p"), Scenario("p")})) == "GUILDA:PowerNetwork:ScenarioTagInUse")
assert(numel(net.a_Scenario) == 1, "失敗したら何も追加しない")
assert(error_id(@() net.add_scenario(42)) == "GUILDA:PowerNetwork:NotScenario")

% 他の系統へ移動 (親は 1 つ)
net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
net2.add_scenario(sc);
assert(sc.a_PowerNetwork == net2 && isempty(net.a_Scenario) && numel(net2.a_Scenario) == 1)
assert(error_id(@() net.simulate([0,2], sc)) == "GUILDA:Scenario:OtherNetwork")

% 複製は親を持たず、元の系統はそのまま
cp = sc.copy();
assert(isempty(cp.a_PowerNetwork) && cp ~= sc && cp.s_tag == "own")
assert(isequaln(cp.tab_disturbance, sc.tab_disturbance))
assert(error_id(@() net.simulate([0,2], cp)) == "GUILDA:Scenario:OtherNetwork")
net.add_scenario(cp);
assert(sc.a_PowerNetwork == net2 && cp.a_PowerNetwork == net)
r1 = DebugScript.helper.quiet(@() net.simulate([0,2], cp));
r2 = DebugScript.helper.quiet(@() net2.simulate([0,2], sc));
assert(isequaln(r1.rm_variable, r2.rm_variable))

% 削除すると親の参照が消える
net2.remove_scenario("own");
assert(isempty(sc.a_PowerNetwork) && isempty(net2.a_Scenario))
assert(error_id(@() net2.remove_scenario("own")) == "GUILDA:PowerNetwork:ScenarioNotFound")
assert(error_id(@() net2.simulate([0,2], sc)) == "GUILDA:Scenario:OtherNetwork")


%% Unknown tags at add and at run time
net = new_ieee14();
% 系統に属するシナリオへの追加はその場で検査し、失敗したら追加しない
sc = Scenario("tags");
net.add_scenario(sc);
assert(error_id(@() sc.add_fault("B999", [1,2])) == "GUILDA:Scenario:UnknownFaultBus")
assert(error_id(@() sc.add_open_branch("EL999", [1,2])) == "GUILDA:Scenario:UnknownOpenBranch")
assert(error_id(@() sc.add_trip("B999SG1", [1,2])) == "GUILDA:Scenario:UnknownTripUnit")
assert(error_id(@() sc.add_offset("B001SG1", "nosuch", 0.1)) == "GUILDA:Scenario:UnknownOffsetState")
assert(error_id(@() sc.add_input("B002SG1", "nosuch", 0.1, [1,2])) == "GUILDA:Scenario:UnknownInputName")
assert(height(sc.tab_disturbance) == 0)

% 系統に属さないシナリオは系統へ追加するときに検査する
loose = Scenario("loose");
loose.add_fault("B999", [1,2]);
assert(error_id(@() net.add_scenario(loose)) == "GUILDA:Scenario:UnknownFaultBus")
assert(isempty(loose.a_PowerNetwork) && numel(net.a_Scenario) == 1)

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
a = Scenario("A");  a.add_fault("B008", [1,1.05], Tag="ev");
b = Scenario("B");  b.add_fault("B003", [2,2.05], Tag="ev");
net.add_scenario({a, b});
assert(error_id(@() net.simulate([0,3], a, b)) == "GUILDA:Scenario:DuplicateRunTag")
assert(error_id(@() net.simulate([0,3], [a, b])) == "GUILDA:Scenario:ScenarioArray")


%% CSV round trip with several scenarios in one file
net = new_ieee14();
s1 = Scenario("case1", Time=[0,20], Description="fault B008, EL003 and EL004 opened");
s1.add_fault("B008", [0.1,0.17]);
s1.add_open_branch(["EL003";"EL004"], [0.17,20]);
s2 = Scenario("case2");
s2.add_offset("B001SG1", ["delta";"omega"], [0.1; 1e-3], 0);
s2.add_input("B002SG1", ["Pmech";"Vfield"], {0.05; 0.1/3}, [1,1.5], Tag="in");
s2.add_disturbance("both", TimeSpan=[2,2.05], FaultBus=["B003";"B005"], TripUnit="B003SG1");
s3 = Scenario("empty", Description="no disturbance, a comma, and ""quotes""");
s_file = tempname + ".csv";
c_rm = onCleanup(@() delete(s_file));
Scenario.export_csv(s_file, {s1, s2, s3}, Overwrite=true);
assert(error_id(@() Scenario.export_csv(s_file, s1)) == "GUILDA:Scenario:CsvFileExists")

c_in = Scenario.import_csv(s_file);
assert(numel(c_in) == 3 && all(cellfun(@(s) isempty(s.a_PowerNetwork), c_in)))
c_ref = {s1, s2, s3};
for k = 1:3
    assert(c_in{k}.s_tag == c_ref{k}.s_tag && c_in{k}.Description == c_ref{k}.Description)
    assert(isequal(c_in{k}.Time, c_ref{k}.Time))
    assert(isequaln(normalize_values(c_in{k}.tab_disturbance), normalize_values(c_ref{k}.tab_disturbance)), c_ref{k}.s_tag)
end
% 書き出し直しても同じファイル
s_file2 = tempname + ".csv";
c_rm2 = onCleanup(@() delete(s_file2));
Scenario.export_csv(s_file2, c_in, Overwrite=true);
assert(isequal(readlines(s_file), readlines(s_file2)))

% Network を与えると系統へ追加し、タグを検査する
c_net = Scenario.import_csv(s_file, Network=net);
assert(all(cellfun(@(s) s.a_PowerNetwork == net, c_net)) && numel(net.a_Scenario) == 3)
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,1.8], c_net{2}));
assert(flag == 1)
assert(error_id(@() Scenario.import_csv(s_file, Network=net)) == "GUILDA:PowerNetwork:ScenarioTagInUse")

% 関数ハンドルは CSV に書けない
s4 = Scenario("fun");
s4.add_input("B002SG1", "Pmech", @(t) 0.01*t, [1,2]);
assert(error_id(@() Scenario.export_csv(s_file, s4, Overwrite=true)) == "GUILDA:Scenario:CsvFunctionHandle")
% 必要な列は Scenario だけ。未知の列は警告して無視する。空の Tag は event<n>
writelines(["Scenario,Tag,TimeStart,FaultBus,TimeEnd,Memo"; "m,,1,B008,1.05,note"; "m,f2,2,B003;B005,2.05,"], s_file);
lastwarn("");
c_memo = Scenario.import_csv(s_file);
assert(string(DebugScript.helper.msg_id()) == "GUILDA:Scenario:CsvUnknownColumn")
assert(isscalar(c_memo) && isequal(c_memo{1}.tab_disturbance.Tag.', ["event1","f2"]))
assert(isequal(c_memo{1}.tab_disturbance.FaultBus{2}, ["B003";"B005"]) && isequal(c_memo{1}.tab_disturbance.TimeSpan(1,:), [1,1.05]))
writelines(["Tag,TimeStart"; "f,1"], s_file);
assert(error_id(@() Scenario.import_csv(s_file)) == "GUILDA:Scenario:CsvMissingColumn")
writelines(["Scenario,Tag,TimeStart,TimeEnd,FaultBus"; "m,f,one,2,B008"], s_file);
assert(error_id(@() Scenario.import_csv(s_file)) == "GUILDA:Scenario:CsvInvalidValue")
writelines(["Scenario,ScenarioTimeEnd"; "m,10"; "m,20"], s_file);
assert(error_id(@() Scenario.import_csv(s_file)) == "GUILDA:Scenario:CsvConflict")


%% Default judge: stable and out-of-step on IEEE9bus
net = new_ieee14();
n9 = network.IEEE9bus;  
DebugScript.helper.quiet(@() n9.initialize);
short = Scenario("short", Time=[0,5]);
short.add_fault("B007", [1,1.05]);
long  = Scenario("long", Time=[0,5]);
long.add_fault("B007", [1,1.5]);
n9.add_scenario({short, long});
[r_short, f_short] = DebugScript.helper.quiet(@() n9.simulate(short));
v = short.judge(r_short);
assert(f_short == 1 && v.Verdict == "stable" && isnan(v.Time) && isempty(v.Units), v.Verdict)
assert(v.Reference == "B001SG1" && v.Threshold == 360 && v.MaxAngle < 360)

ws = warning("off", "all");  c_ws = onCleanup(@() warning(ws));
r_long = DebugScript.helper.quiet(@() n9.simulate(long));
clear c_ws
v = long.judge(r_long);
assert(v.Verdict == "out-of-step" && v.Time > 1 && ~isempty(v.Units) && v.MaxAngle > 360, v.Verdict)

% 基準: 重心 (COI) と機器のタグ
v = Scenario.out_of_step(r_short, Reference="COI");
assert(v.Verdict == "stable" && v.Reference == "COI")
v = Scenario.out_of_step(r_long, Reference="B002SG1");
assert(v.Verdict == "out-of-step" && v.Reference == "B002SG1")
assert(error_id(@() Scenario.out_of_step(r_short, Reference="B001")) == "GUILDA:Scenario:UnknownReference")
% しきい値を小さくすると短い地絡でも脱調と判定する
v = Scenario.out_of_step(r_short, Threshold=1);
assert(v.Verdict == "out-of-step")


%% Incomplete verdict and a custom judge
net = new_ieee14();
n9 = network.IEEE9bus;  
DebugScript.helper.quiet(@() n9.initialize);
sc = Scenario("limit", Time=[0,5]);
sc.add_fault("B007", [1,1.05]);
n9.add_scenario(sc);
ws = warning("off", "all");  c_ws = onCleanup(@() warning(ws));
[res, flag] = DebugScript.helper.quiet(@() n9.simulate(sc, TimeLimit=1e-3));
clear c_ws
assert(flag == 0)
v = sc.judge(res);
assert(v.Verdict == "incomplete" && isnan(v.Time), v.Verdict)
% 利用者の判定関数
sc.Judge = @(r) struct("Verdict", "custom", "tEnd", r.output.tEnd);
v = sc.judge(res);
assert(v.Verdict == "custom" && v.tEnd == res.output.tEnd)


%% Compatibility: ODEevent warns once and gives the same results
net = new_ieee14();
clear Deprecated
lastwarn("");
ev = DebugScript.helper.quiet(@() ODEevent("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008"));
assert(string(DebugScript.helper.msg_id()) == "GUILDA:Deprecated:ODEevent")
assert(isa(ev, "Scenario") && ev.a_PowerNetwork == net && ev.s_tag == "fault" && ev.tab_disturbance.Tag == "fault")
lastwarn("");
ev2 = DebugScript.helper.quiet(@() ODEevent("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B002SG1"));
assert(isempty(lastwarn()), "警告は 1 回だけ")
r_old = DebugScript.helper.quiet(@() net.simulate([0,2], ev, ev2));
sc = Scenario("new");
sc.add_fault("B008", [1,1.05], Tag="fault");
sc.add_trip("B002SG1", [1,1.2], Tag="trip");
net.add_scenario(sc);
r_new = DebugScript.helper.quiet(@() net.simulate([0,2], sc));
assert(isequaln(r_old.rm_variable, r_new.rm_variable) && isequal(r_old.output.phases, r_new.output.phases))
% 同じタグの ODEevent は前のものを置き換える (ループで増えない)
ev3 = DebugScript.helper.quiet(@() ODEevent("fault", net, "TimeSpan", [1,1.1], "FaultBus", "B008"));
assert(isempty(ev.a_PowerNetwork) && ev3.a_PowerNetwork == net)
assert(sum(cellfun(@(s) s.s_tag == "fault", net.a_Scenario)) == 1)
% Scenario として追加した同じタグのシナリオは置き換えない
assert(error_id(@() ODEevent("new", net, "TimeSpan", [1,1.1], "FaultBus", "B008")) == "GUILDA:PowerNetwork:ScenarioTagInUse")


%% Scenarios of another network are rejected
net = new_ieee14();
other = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() other.initialize);
sc_o = Scenario("o");
sc_o.add_fault("B008", [1,1.05]);
other.add_scenario(sc_o);
ok = Scenario("ok");
ok.add_fault("B008", [1,1.05]);
net.add_scenario(ok);
assert(error_id(@() net.simulate([0,2], sc_o)) == "GUILDA:Scenario:OtherNetwork")
assert(error_id(@() net.simulate([0,2], ok, sc_o)) == "GUILDA:Scenario:OtherNetwork")
assert(error_id(@() net.simulate([0,2], ok, sc_o.copy())) == "GUILDA:Scenario:OtherNetwork")


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

function tab = normalize_values(tab)
% 数値の cell の InputValue は CSV では数値の列になる
    for k = 1:height(tab)
        v = tab.InputValue{k};
        if iscell(v)
            tab.InputValue{k} = vertcat(zeros(0,1), v{:});
        end
    end
end

function net = new_ieee14()
    net = DebugScript.helper.build_ieee14();
    DebugScript.helper.quiet(@() net.initialize);
end
