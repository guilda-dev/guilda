% Issue 55: 部分解の警告と、実行全体に対する TimeLimit (既定は Inf)
%
%   flag ~= 1 なら nargout によらず GUILDA:PowerNetwork:SimulationIncomplete を警告する
%   TimeLimit は区間ごとではなく、初期条件の計算も含めた実行全体の上限
%
% 実行: runtests("DebugScript.test_I55_time_limit")  または  DebugScript.run_all("Features","I55")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();       % 進捗表示なし (Progress = "none")
DebugScript.helper.quiet(@() net.initialize);
s_id = "GUILDA:PowerNetwork:SimulationIncomplete";
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
% 第 1 区間 [0,1] の代数変数を大きく解き直す入力
offset = @(n) DebugScript.helper.scenario("offset", n, "TimeSpan", 0, "OffsetUnit", "B002SG1", ...
                          "OffsetState", "delta", "OffsetValue", 1);


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Partial result warns with any number of outputs
lastwarn("");
sol = net.simulate(ev.s_tag, Time=[0,5], TimeLimit=1e-6);
[s_msg, s_got] = lastwarn(); s_got = DebugScript.helper.msg_id(s_msg, s_got);
assert(s_got == s_id)
assert(contains(s_msg, "TimeLimit") && contains(s_msg, "flag = 0"))
assert(sol.flag == 0)

lastwarn("");
[~, flag] = net.simulate(ev.s_tag, Time=[0,5], TimeLimit=1e-6);
s_got = DebugScript.helper.msg_id();
assert(s_got == s_id && flag == 0)

lastwarn("");
[~, flag, output] = net.simulate(ev.s_tag, Time=[0,5], TimeLimit=1e-6);
[s_msg, s_got] = lastwarn(); s_got = DebugScript.helper.msg_id(s_msg, s_got);
assert(s_got == s_id && flag == 0)
assert(contains(s_msg, output.message))


%% Stop by the solver warns too
% 入力が t = 1 から 1 s で 1e3 まで増えるとソルバーが止まる
ev_in = DebugScript.helper.scenario("in", net, "TimeSpan", [1,3], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", [0, 0; 1, 1e3]);
lastwarn("");
[~, flag, output] = net.simulate(ev_in.s_tag, Time=[0,4]);
[s_msg, s_got] = lastwarn(); s_got = DebugScript.helper.msg_id(s_msg, s_got);
assert(flag == -1)
assert(s_got == s_id && contains(s_msg, "flag = -1") && contains(s_msg, output.message))


%% Completed run does not warn
lastwarn("");
[~, flag] = net.simulate(ev.s_tag, Time=[0,2]);
s_got = DebugScript.helper.msg_id();
assert(flag == 1)
assert(s_got ~= s_id)


%% Default TimeLimit is Inf
% 既定は GUILDA.setting の TimeSimulation (net.solver_ODE は設定を持たない)
assert(~isprop(SolverODE(), "TimeLimit") && isinf(net.simulate(ev.s_tag, Time=[0,0.1]).options.TimeLimit))
sct_config = readstruct(fullfile(GUILDA.pwd, "@GUILDA", "config", "DefaultTimeSimulation.json"));
assert(isinf(sct_config.TimeLimit.Value))


%% Limit keeps counting through the phases
prog = ProgressGUILDA("none", "Time simulation", [0,2], 0.05);
fcn  = prog.OutputFcn;
fcn([0,1], zeros(1,1), 'init');
fcn(0.5, zeros(1,1), '');
assert(prog.ToBeContinue)
pause(0.1)
fcn([0,1], zeros(1,1), 'init');        % 次の区間でも計時を始め直さない
assert(prog.ToBeContinue)              % 停止の検出は次の刻みで行う
fcn(0.5, zeros(1,1), '');
assert(~prog.ToBeContinue)
assert(contains(prog.message, "timeout"))


%% Events stops the phase without OutputFcn
% SampleTime では SolverODE.solve が solutionFcn を使い、OutputFcn は呼ばれない。
% 時間の上限はイベント関数 Events(t) が調べる (t は区間の開始からの時刻)
prog = ProgressGUILDA("none", "Time simulation", [0,2], 0.05);
prog.timeoffset = 1;
assert(prog.Events(0.25) && prog.ToBeContinue)
pause(0.1)
assert(prog.Events(0) && prog.ToBeContinue)        % 区間の開始 (t = 0) は調べない
assert(prog.Events(0.5) && ~prog.ToBeContinue)     % 超えた時の値はまだ true (次の呼び出しで止まる)
assert(prog.message == "|(timeout: t=1.5)", prog.message)
[value, isterminal] = prog.Events(0.75);
assert(~value && isterminal == 1 && prog.message == "|(timeout: t=1.5)")   % 最初の停止の時刻を残す
% SampleTime の計算も TimeLimit で止まる (flag = 0)
ws = warning("off", s_id);  c_ws = onCleanup(@() warning(ws));
[~, flag, output] = net.simulate(ev.s_tag, Time=[0,5], SampleTime=0.01, TimeLimit=1e-6);
clear c_ws
assert(flag == 0 && output.tEnd < 5 && contains(output.message, "TimeLimit"), "flag %d", flag)


%% Dialog takes several times per call and a start time other than 0
% SampleTime では OutputFcn が 1 回に複数の時刻を受け取る。旧 ProgressODE は waitbar(t/tspan) に
% ベクトルを渡して "first argument must be between 0 and 1" で止まった。dialogFcn が update に
% 渡す表示と割合を確かめる (-batch では "dialog" は "none" になるので dialogFcn を直接呼ぶ)
prog = ProgressGUILDA("dialog", "Time simulation", [2,4], Inf);
c_prog = onCleanup(@() delete(prog));
prog.timeoffset = 2;                                 % solve sets it before the phase
prog.dialogFcn([0,2], zeros(2,1), 'init');
prog.dialogFcn([0.5, 0.75, 1.0], zeros(2,3), '');   % 3 つの時刻 (t = 2.5, 2.75, 3)
assert(isscalar(prog.r_fraction) && abs(prog.r_fraction - 0.5) < 1e-12)
assert(contains(prog.s_text, "3.00(s) / 4.00(s)"))
prog.dialogFcn([2.5; 3], zeros(2,2), '');            % 終わりの時刻を超えても止まらない
assert(prog.r_fraction > 1)                          % update が描画のときに [0,1] に丸める
prog.dialogFcn([], [], 'done');
delete(c_prog);


%% Text bar takes several times per call
% SampleTime では OutputFcn が 1 回に複数の時刻を受け取る。dispFcn が (t - tlast)/tspan を
% ベクトルのまま repmat に渡して止まっていた (相 1 で「複製係数は整数」)
prog = ProgressGUILDA("disp", "Time simulation", [2,4], Inf);
s_out = evalc("prog.timeoffset = 2; prog.OutputFcn([0,2], zeros(2,1), 'init'); " + ...   % solve sets timeoffset first
              "prog.OutputFcn([0.5, 0.75, 1.0], zeros(2,3), ''); prog.OutputFcn([], [], 'done');");
assert(count(s_out, ">") == 50, "bar " + count(s_out, ">"))   % t = 3 of [2, 4]: 50 %
delete(prog);


%% Delete ends the display and leaves no timer
% arguments ブロックのある delete はデストラクターにならず、isvalid が true のまま残った
prog = ProgressGUILDA("disp", "Power flow");
delete(prog);
assert(~isvalid(prog))
assert(isempty(timerfindall("Tag", "GUILDA:ProgressGUILDA")))


%% Inf never stops
prog = ProgressGUILDA("none", "Time simulation", [0,2], Inf);
fcn  = prog.OutputFcn;
fcn([0,1], zeros(1,1), 'init');
pause(0.01)
fcn(0.5, zeros(1,1), '');
assert(prog.ToBeContinue)


%% Phases that each fit in the limit stop when their sum does not
% 各区間の前で 0.6 s 待つ。区間ごとの上限なら 1.5 s を超える区間はなく最後まで進む。
% 全体では第 3 区間の待ちで 1.8 s > 1.5 s になり必ず止まる。第 1 区間は 0.9 s 以内に計算できれば
% 終わる (先に同じ計算を 1 回して、初回の読み込みの時間を除く)
c_ev = faults(net);
assert(run_with_delay(net, [0,5], c_ev, 0, Inf) == 1)
[flag, output] = run_with_delay(net, [0,5], c_ev, 0.6, 1.5);
assert(flag == 0, "flag " + flag)
assert(output.nPhasesDone >= 1 && output.nPhasesDone < output.nPhases, "phases " + output.nPhasesDone)
assert(output.tEnd < 5)


%% Limit includes the time of the initial condition
% 区間ごとに初期条件を計算してから solve する。その後で計時を始め直さない
c_ev = {offset(net), DebugScript.helper.scenario("trip", net, "TimeSpan", 0.5, "TripUnit", "B003SG1")};
assert(run_with_delay(net, [0,1], c_ev, 0, Inf) == 1)
[flag, output] = run_with_delay(net, [0,1], c_ev, 1, 0.9);
assert(flag == 0, "flag " + flag)
assert(output.tEnd < 1)


function c_ev = faults(net)
    c_ev = arrayfun(@(t) DebugScript.helper.scenario("fault" + t, net, "TimeSpan", [t,t+0.05], "FaultBus", "B008"), 1:4, "UniformOutput", false);
end

function [flag, output] = run_with_delay(net, tspan, c_events, t_delay, t_limit)
    sct_options = DebugScript.helper.ode_options("Progress", "none", "TimeLimit", t_limit);
    sct_options.PhaseProbe = @(o) pause(t_delay);
    [~, flag, output] = DebugScript.helper.solve_direct(net, one_scenario(net, c_events), tspan, sct_options);
end


function s_tag = one_scenario(net, c_events)
% シナリオのセルを 1 つのシナリオのタグにする (2 つ以上は DebugScript.helper.combine でまとめる)
    sc = c_events{1};
    if numel(c_events) > 1
        sc = DebugScript.helper.combine(net, c_events{:});
    end
    s_tag = sc.s_tag;
end
