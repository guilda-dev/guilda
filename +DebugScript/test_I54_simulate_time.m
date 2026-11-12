% Issue 54: simulate の Time は有限で昇順の [t0,tend] のみ受理する
%
% 時間はシナリオの Time (既定 [0, 10])。呼び出しの Time=[t0,tend] がその呼び出しだけ上書きする。
% Time は arguments ブロックの (1,2) double と mustBeSimulationTime で検査する。
%
% 実行: runtests("DebugScript.test_I54_simulate_time")  または  DebugScript.run_all("Features","I54")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();       % 進捗表示なし (Progress = "none")
DebugScript.helper.quiet(@() net.initialize);
s_free = DebugScript.helper.no_disturbance(net);
s_id = "GUILDA:mustBeSimulationTime:InvalidTime";


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Invalid time stops with an error naming the cause
% {Time, 期待するエラー: mustBeSimulationTime の ID か、arguments ブロックのエラー ("")}
c_case = { ...
    5,                s_id; ...          % [5 5] に拡張される
    [0,NaN],          s_id; ...
    [NaN,1],          s_id; ...
    [0,Inf],          s_id; ...
    [-Inf,1],         s_id; ...
    [1,1],            s_id; ...
    [2,1],            s_id; ...
    [0,1i],           s_id; ...
    "abc",            s_id; ...          % double に変換すると NaN
    [0,1,2],          ""; ...
    [0,0.5,1,2,3],    ""; ...
    [0,1;2,3],        ""; ...
    'abc',            ""; ...
    {0,1},            ""; ...
    [],               ""};
for k = 1:height(c_case)
    s_case = string(evalc("disp(c_case{k,1})"));
    try
        net.simulate(s_free, Time=c_case{k,1});
        error("DebugScript:noError", "エラーにならない: %s", s_case)
    catch ME
        s_got = string(DebugScript.helper.msg_id(ME));
        assert(s_got ~= "DebugScript:noError", s_case)
        if c_case{k,2} ~= ""
            assert(s_got == c_case{k,2}, "%s: %s", s_case, s_got)
        end
        assert(contains(ME.message, "Time"), "%s: %s", s_case, ME.message)   % 引数の名前を示す
    end
end


%% The time of the scenario is used without Time
% net.simulate(tag) は sc.Time (既定 [0, 10]) を使う。外乱の時間区間は時間を変えない
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[sol, flag] = net.simulate(ev.s_tag);
assert(flag == 1 && sol.odeResults.t(1) == 0 && sol.odeResults.t(end) == 10)
ev.Time = [0,2];
[sol, flag] = net.simulate(ev.s_tag);
assert(flag == 1 && sol.odeResults.t(end) == 2)
% Time はその呼び出しだけ。sc.Time は変わらない
[sol, flag] = net.simulate(ev.s_tag, Time=[0,1.5]);
assert(flag == 1 && sol.odeResults.t(end) == 1.5 && isequal(ev.Time, [0,2]))
% 旧形式 (時間を先に渡す) は受けない
assert(error_of(@() net.simulate([0,2], ev.s_tag)) ~= "")


%% Valid time is accepted
[sol, flag] = net.simulate(s_free, Time=[0,1]);
assert(flag == 1 && sol.odeResults.t(1) == 0 && sol.odeResults.t(end) == 1)

[sol, flag] = net.simulate(s_free, Time=[-1,1]);
assert(flag == 1 && sol.odeResults.t(1) == -1 && sol.odeResults.t(end) == 1)

[sol, flag] = net.simulate(s_free, Time=[0;1]);
assert(flag == 1 && sol.odeResults.t(end) == 1)

[sol, flag] = net.simulate(s_free, Time=single([0,1]));
assert(flag == 1 && sol.odeResults.t(end) == 1)


function id = error_of(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
        if id == ""
            id = "(no id)";
        end
    end
end
