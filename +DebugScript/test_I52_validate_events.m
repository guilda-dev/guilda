% I52 イベントの検証 (Scenario)
%
% 打ち間違いが無外乱の flag=1 にならず、計算前に原因を示すエラーになることを確認する。
%
% 実行: runtests("DebugScript.test_I52_validate_events")  または  DebugScript.run_all("Features","I52")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Unknown fault target
expect_event_error(net, "UnknownFaultTarget", "B999", "TimeSpan", [1,1.05], "FaultBus", "B999");
% 正しいタグが混ざっていても、誤ったものだけを示す
expect_event_error(net, "UnknownFaultTarget", "B999", "TimeSpan", [1,1.05], "FaultBus", ["B008";"B999"]);


%% Unknown parallel target
expect_event_error(net, "UnknownParallelTarget", "NOPE", "TimeSpan", [1,2], "TripUnit", "NOPE");
expect_event_error(net, "UnknownParallelTarget", "EL999", "TimeSpan", [1,2], "OpenBranch", "EL999");


%% A trip accepts a local controller (simulated from step E2 on)
avr = net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
expect_event_error(net, "NotYetSupported", avr.s_tag, "TimeSpan", [1,1.2], "TripUnit", avr.s_tag);


%% TripUnit accepts components and global controllers
agc = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
[~, flag] = net.simulate(DebugScript.helper.scenario("ev", net, "TimeSpan", [1,1.2], "TripUnit", ["B003LPQ2";agc.s_tag]).s_tag, Time=[0,2]);
assert(flag == 1)


%% Unknown OffsetUnit
expect_event_error(net, "UnknownOffsetUnit", "NOPE", "TimeSpan", 0, "OffsetUnit", "NOPE", "OffsetState", "delta", "OffsetValue", 0.1);
% OffsetUnit を書き忘れた指定も無視しない
expect_event_error(net, "UnknownOffsetUnit", "OffsetUnit", "TimeSpan", 0, "OffsetState", "delta", "OffsetValue", 0.1);


%% Unknown OffsetState
expect_event_error(net, "UnknownOffsetState", ["delt", "delta"], "TimeSpan", 0, "OffsetUnit", "B001SG1", "OffsetState", "delt", "OffsetValue", 0.1);


%% OffsetValue count
expect_event_error(net, "ValueCountMismatch", "OffsetValue", "TimeSpan", 0, "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", [0.1;0.2]);
expect_event_error(net, "ValueCountMismatch", "OffsetValue", "TimeSpan", 0, "OffsetUnit", "B001SG1", "OffsetState", ["delta";"omega"]);
expect_event_error(net, "ValueCountMismatch", "OffsetState", "TimeSpan", 0, "OffsetUnit", "B001SG1");


%% Reversed or NaN TimeSpan
expect_event_error(net, "InvalidTimeSpan", "1.5 1", "TimeSpan", [1.5,1], "FaultBus", "B008");
expect_event_error(net, "InvalidTimeSpan", "NaN",   "TimeSpan", [NaN,1], "FaultBus", "B008");
expect_event_error(net, "InvalidTimeSpan", "NaN",   "TimeSpan", [1,NaN], "FaultBus", "B008");
expect_event_error(net, "InvalidTimeSpan", "NaN",   "TimeSpan", NaN,     "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.1);
% 外乱のないイベントでも同じ
expect_event_error(net, "InvalidTimeSpan", "1.5 1", "TimeSpan", [1.5,1]);


%% Extra or missing InputValue
base = {"TimeSpan", [1,2], "InputUnit", "B002SG1"};
expect_event_error(net, "ValueCountMismatch", "InputValue", base{:}, "InputName", "Pmech", "InputValue", [0.1;0.2]);
expect_event_error(net, "ValueCountMismatch", "InputValue", base{:}, "InputName", ["Pmech";"Vfield"], "InputValue", [0.1;0.2;0.3]);
expect_event_error(net, "ValueCountMismatch", "InputValue", base{:}, "InputName", "Pmech", "InputValue", [0.1, 0.2, 0.3]);
expect_event_error(net, "ValueCountMismatch", "InputValue", base{:}, "InputName", "Pmech");
% 名前なしの値も無視しない
expect_event_error(net, "ValueCountMismatch", "InputName", base{:}, "InputValue", 0.1);
expect_event_error(net, "UnknownInputUnit", "InputUnit", "TimeSpan", [1,2], "InputValue", 0.1);


%% Valid events still run
% 値が 1 つなら全ての名前に使い、イベントの種類ごとに正しい指定は計算できる
o = { ...
    DebugScript.helper.scenario("os", net, "TimeSpan", 0,        "OffsetUnit", "B001SG1", "OffsetState", ["delta";"omega"], "OffsetValue", 1e-3); ...
    DebugScript.helper.scenario("in", net, "TimeSpan", [1,1.5],  "InputUnit", "B002SG1", "InputName", ["Pmech";"Vfield"], "InputValue", 0.01); ...
    DebugScript.helper.scenario("fl", net, "TimeSpan", [2,2.02], "FaultBus", "B008"); ...
    DebugScript.helper.scenario("tr", net, "TimeSpan", [2.5,2.6], "TripUnit", "B003LPQ2"); ...
    DebugScript.helper.scenario("no", net, "TimeSpan", 1)};
[sol, flag] = net.simulate(DebugScript.helper.combine(net, o{:}).s_tag, Time=[0,3]);
assert(flag == 1 && sol.odeResults.t(end) == 3)


function expect_event_error(net, s_key, s_text, varargin)
    % エラーの ID と、メッセージが原因を示すこと (s_text を全て含む) を確認する
    % 系統に属するシナリオへの追加の時点で検査される
    s_id = "GUILDA:Scenario:" + s_key;
    try
        ev = DebugScript.helper.scenario("ev", net, varargin{:});
        net.simulate(ev.s_tag, Time=[0,3]);
    catch ME
        assert(DebugScript.helper.msg_id(ME) == s_id, DebugScript.helper.msg_id(ME) + ": " + ME.message)
        assert(all(contains(ME.message, s_text)), "原因が示されない: " + ME.message)
        assert(any(contains(ME.message, ["""ev""", """Fault001""", """Parallel001"""])), "外乱の名前が示されない: " + ME.message)
        return
    end
    error("DebugScript:noError", "エラーにならない (期待: " + s_id + ")")
end
