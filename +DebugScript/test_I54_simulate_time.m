% Issue 54: simulate の time は有限で昇順の [t0,tend] か [] のみ受理する
%
% 実行: runtests("DebugScript.test_I54_simulate_time")  または  DebugScript.run_all("Features","I54")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();       % 進捗表示なし (Progress = "none")
DebugScript.helper.quiet(@() net.initialize);
s_id = "GUILDA:PowerNetwork:SimulateTime";


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Invalid time stops with an error naming the cause
% {time, メッセージに含まれるべき原因}
c_case = { ...
    5,                "size 1x1"; ...
    [0,1,2],          "size 1x3"; ...
    [0,0.5,1,2,3],    "size 1x5"; ...
    [0,1;2,3],        "size 2x2"; ...
    [0,NaN],          "not finite"; ...
    [NaN,1],          "not finite"; ...
    [0,Inf],          "not finite"; ...
    [-Inf,1],         "not finite"; ...
    [1,1],            "not smaller"; ...
    [2,1],            "not smaller"; ...
    [0,1i],           "class double"; ...
    "abc",            "class string"; ...
    'ab',             "class char"; ...
    [false,true],     "class logical"; ...
    {0,1},            "class cell"};
for k = 1:height(c_case)
    s_case = string(evalc("disp(c_case{k,1})"));
    try
        net.simulate(c_case{k,1});
        error("DebugScript:noError", "エラーにならない: %s", s_case)
    catch ME
        assert(DebugScript.helper.msg_id(ME) == s_id, "%s: %s", s_case, DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, c_case{k,2}), "%s: %s", s_case, ME.message)
    end
end


%% A scenario as the first argument runs without time
% net.simulate(sc) は sc.Time、それがなければ外乱の時間区間を使う
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[sol, flag] = net.simulate(ev);
assert(flag == 1 && sol.odeResults.t(end) >= 1.05)
ev.Time = [0,2];
[sol, flag] = net.simulate(ev);
assert(flag == 1 && sol.odeResults.t(end) == 2)
% time 以外の値は従来どおり time のエラー
try
    net.simulate("fault");
    error("DebugScript:noError", "文字列を time に渡してもエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == s_id, DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "class string"), ME.message)
end


%% Several time points no longer drop a later event silently
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
try
    net.simulate([0,0.5,1,2,3], ev);
    error("DebugScript:noError", "3 要素以上の time でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == s_id, DebugScript.helper.msg_id(ME))
end


%% Valid time is accepted
[sol, flag] = net.simulate([0,1]);
assert(flag == 1 && sol.odeResults.t(1) == 0 && sol.odeResults.t(end) == 1)

[sol, flag] = net.simulate([-1,1]);
assert(flag == 1 && sol.odeResults.t(1) == -1 && sol.odeResults.t(end) == 1)

[sol, flag] = net.simulate([0;1]);
assert(flag == 1 && sol.odeResults.t(end) == 1)

[sol, flag] = net.simulate(single([0,1]));
assert(flag == 1 && sol.odeResults.t(end) == 1)


%% Empty time takes the time span of the events
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[sol, flag] = net.simulate([], ev);
assert(flag == 1 && sol.odeResults.t(end) >= 1.05)

[~, flag] = net.simulate();
assert(flag == 1)

[~, flag] = net.simulate([]);
assert(flag == 1)
