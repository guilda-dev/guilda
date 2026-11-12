% I53 長さのない TimeSpan (Scenario)
%
% fault, trip, input のスカラーや [t,t] は、無関係なイベントで継続時間が変わらないようエラーにする。
% offset と効果のないイベントは、これまでどおり 1 つの時刻で指定できることを確認する。
%
% 実行: runtests("DebugScript.test_I53_scalar_timespan")  または  DebugScript.run_all("Features","I53")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
c_fault = {"FaultBus", "B008"};
c_trip  = {"TripUnit", "B003LPQ2"};
c_input = {"InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0.01};
c_os    = {"OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 1e-3};


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Fault, trip and input need a duration
for c_kind = {c_fault, c_trip, c_input}
    expect_zero_length(net, "1", "TimeSpan", 1, c_kind{1}{:});
    expect_zero_length(net, "[1 1]", "TimeSpan", [1,1], c_kind{1}{:});
end


%% Unrelated event does not decide the duration (Issue の再現手順)
% 長さのない地絡は、他の外乱があってもなくても追加の時点でエラー
ev_other = DebugScript.helper.scenario("other", net, "TimeSpan", [1.5,2], c_trip{:});
assert(event_error(@() DebugScript.helper.scenario("fault", net, "TimeSpan", 1, c_fault{:})) == "GUILDA:Scenario:ZeroLengthTimeSpan")
sc = net.add_scenario("both");
sc.add_trip("B003LPQ2", [1.5,2]);
assert(event_error(@() sc.add_disturbance("fault", "TimeSpan", 1, c_fault{:})) == "GUILDA:Scenario:ZeroLengthTimeSpan")
assert(height(sc.tab_disturbance) == 1)
[~, flag] = net.simulate([0,3], ev_other);
assert(flag == 1)


%% An offset with a fault in one event still needs a duration
expect_zero_length(net, "1", "TimeSpan", 1, c_os{:}, c_fault{:});


%% A scenario checks the duration when the disturbance is added
sc = net.add_scenario("loose");
assert(event_error(@() sc.add_disturbance("ev", "TimeSpan", 1, c_fault{:})) == "GUILDA:Scenario:ZeroLengthTimeSpan")
assert(event_error(@() sc.add_fault("B008", [1,1])) == "GUILDA:Scenario:ZeroLengthTimeSpan")
assert(height(sc.tab_disturbance) == 0)


%% Offset and an event without effect keep a single time
for ts = {0, 1, [1,1], [1,2]}
    [sol, flag] = net.simulate([0,3], DebugScript.helper.scenario("os", net, "TimeSpan", ts{1}, c_os{:}));
    assert(flag == 1 && sol.odeResults.t(end) == 3)
end
for ts = {1, [1,1]}
    [sol, flag] = net.simulate([0,3], DebugScript.helper.scenario("none", net, "TimeSpan", ts{1}));
    assert(flag == 1 && sol.odeResults.t(end) == 3)
end


%% Events with a duration still run
for c_kind = {c_fault, c_trip, c_input}
    [sol, flag] = net.simulate([0,2], DebugScript.helper.scenario("ev", net, "TimeSpan", [1,1.05], c_kind{1}{:}));
    assert(flag == 1 && sol.odeResults.t(end) == 2)
end


function expect_zero_length(net, s_ts, varargin)
    % エラーの ID と、メッセージが原因と対処を示すことを確認する
    [s_id, s_msg] = event_error(@() net.simulate([0,3], DebugScript.helper.scenario("ev", net, varargin{:})));
    assert(s_id == "GUILDA:Scenario:ZeroLengthTimeSpan", s_id + ": " + s_msg)
    assert(all(contains(s_msg, ['"ev"', s_ts, "[t_start, t_end]"])), "原因が示されない: " + s_msg)
end

function [s_id, s_msg] = event_error(f)
    s_id    = "";
    s_msg   = "";
    try
        f();
    catch ME
        s_id    = string(DebugScript.helper.msg_id(ME));
        s_msg   = string(ME.message);
    end
end
