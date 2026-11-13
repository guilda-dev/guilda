% I60 イベントと系統の対応 (Scenario)
%
% シナリオが生成時の系統の写しに依存せず、他の系統のシナリオとタグの問題が明示エラーになることを確認する。
% simulate はその系統のシナリオをタグで 1 つ選ぶ。
%
% 実行: runtests("DebugScript.test_I60_event_network")  または  DebugScript.run_all("Features","I60")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% An event created before a topology change gives the same result as a new one
args = {"TimeSpan", [1,1.05], "FaultBus", "B008"};
old = DebugScript.helper.scenario("fault", net, args{:});
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
r_old = DebugScript.helper.quiet(@() net.simulate(old.s_tag, Time=[0,2]));
r_new = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.scenario("fault", net, args{:}).s_tag, Time=[0,2]));
assert(isequaln(r_old.odeResults, r_new.odeResults))


%% An event created before adding a global controller still works
old = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
net.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
[~, flag] = DebugScript.helper.quiet(@() net.simulate(old.s_tag, Time=[0,2]));
assert(flag == 1)


%% An event of another network is rejected, even with the same structure
other = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() other.initialize);
ev = DebugScript.helper.scenario("fault", other, "TimeSpan", [1,1.05], "FaultBus", "B008");
ev.s_tag = "other_fault";
assert(error_id(@() net.simulate(ev.s_tag, Time=[0,2])) == "GUILDA:PowerNetwork:ScenarioNotFound")
assert(error_id(@() net.simulate(ev)) ~= "")


%% Duplicate tags
% 外乱のタグの重なりは、1 つのシナリオの中で追加の時点でエラー
ev1 = DebugScript.helper.scenario("same", net, "TimeSpan", [1,1.05], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0.01);
assert(error_id(@() ev1.add_offset("B001SG1", "delta", 0.01, 0, Tag="same")) == "GUILDA:Scenario:DuplicateTag")
% 故障と並列のタグは番号が振られ、重ならない
assert(ev1.add_fault("B008", [1,1.05]) == "Fault001" && ev1.add_fault("B003", [2,2.05]) == "Fault002")


%% Reserved tags
c_input = {"TimeSpan", [1,1.05], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0.01};
for tag = ["t1","t2","NoAction1","NoAction12","Properties","Row","Variables","","Fault001","Parallel12"]
    assert(error_id(@() DebugScript.helper.scenario(tag, net, c_input{:})) == "GUILDA:Scenario:ReservedTag")
end
% 予約名に似ているだけのタグは使える
ev = DebugScript.helper.scenario("NoAction", net, c_input{:});
ev.add_offset("B001SG1", "delta", 1e-3, 0, Tag="Fault");
ev.add_offset("B001SG1", "delta", 1e-3, 0, Tag="Parallel1x");
[~, flag] = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=[0,2]));
assert(flag == 1)


%% Several scenarios in one call are rejected
ev1 = DebugScript.helper.scenario("a", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
ev2 = DebugScript.helper.scenario("b", net, "TimeSpan", [2,2.05], "FaultBus", "B003");
assert(error_id(@() net.simulate([ev1.s_tag, ev2.s_tag])) ~= "")
assert(error_id(@() net.simulate(ev1.s_tag, ev2.s_tag)) ~= "")


function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
