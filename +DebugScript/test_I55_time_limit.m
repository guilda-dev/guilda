% Issue 55: 部分解の警告と、実行全体に対する TimeLimit (既定は Inf)
%
%   flag ~= 1 なら nargout によらず GUILDA:PowerNetwork:SimulationIncomplete を警告する
%   TimeLimit は区間ごとではなく、フォールバックも含めた実行全体の上限
%
% 実行: runtests("DebugScript.test_I55_time_limit")  または  DebugScript.run_all("Features","I55")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();       % 進捗表示なし (Progress = "none")
DebugScript.helper.quiet(@() net.initialize);
str_id = "GUILDA:PowerNetwork:SimulationIncomplete";
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
% 第 1 区間 [0,1] からフォールバックに入る入力
offset = @(n) odeEventSet("offset", n, "TimeSpan", 0, "OffsetUnit", "SG1B002", ...
                          "OffsetState", "delta", "OffsetValue", 3);
c_warn = {warning("off", "GUILDA:odeSimulator:InitialConditionRelaxed")};
c_warn{2} = onCleanup(@() warning(c_warn{1}));


%% Partial result warns with any number of outputs
lastwarn("");
sol = net.simulate([0,5], ev, TimeLimit=1e-6);
[str_msg, str_got] = lastwarn();
assert(str_got == str_id)
assert(contains(str_msg, "TimeLimit") && contains(str_msg, "flag = 0"))
assert(sol.flag == 0)

lastwarn("");
[~, flag] = net.simulate([0,5], ev, TimeLimit=1e-6);
[~, str_got] = lastwarn();
assert(str_got == str_id && flag == 0)

lastwarn("");
[~, flag, output] = net.simulate([0,5], ev, TimeLimit=1e-6);
[str_msg, str_got] = lastwarn();
assert(str_got == str_id && flag == 0)
assert(contains(str_msg, output.message))


%% Stop by the solver warns too
% 入力が t = 2.5 で発散するとソルバーが止まる
ev_in = odeEventSet("in", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) 1/(1.5-t));
lastwarn("");
[~, flag, output] = net.simulate([0,4], ev_in);
[str_msg, str_got] = lastwarn();
assert(flag == -1)
assert(str_got == str_id && contains(str_msg, "flag = -1") && contains(str_msg, output.message))


%% Completed run does not warn
lastwarn("");
[~, flag] = net.simulate([0,2], ev);
[~, str_got] = lastwarn();
assert(flag == 1)
assert(str_got ~= str_id)


%% Default TimeLimit is Inf
mp = ?odeSimulator;
p  = mp.PropertyList(string({mp.PropertyList.Name}) == "TimeLimit");
assert(isinf(p.DefaultValue))
s_config = readstruct(fullfile(GUILDA.pwd, "@GUILDA", "config", "DefaultTimeSimulation.json"));
assert(isinf(s_config.TimeLimit.Value))


%% Limit keeps counting through the phases
prog = odeProgress("none", [0,2], 0.05);
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


%% Inf never stops
prog = odeProgress("none", [0,2], Inf);
fcn  = prog.OutputFcn;
fcn([0,1], zeros(1,1), 'init');
pause(0.01)
fcn(0.5, zeros(1,1), '');
assert(prog.ToBeContinue)


%% Phases that each fit in the limit stop when their sum does not
% 各区間の前で 0.3 s 待つ。区間ごとの上限なら 0.7 s を超える区間はなく最後まで進む
[flag, output] = run_with_delay(net, [0,5], faults(net), 0.3, 0.7);
assert(flag == 0, "flag " + flag)
assert(output.nPhasesDone >= 1 && output.nPhasesDone < output.nPhases, "phases " + output.nPhasesDone)
assert(output.tEnd < 5)


%% Limit includes the time before the fallback
% 第 1 区間の最初の solve は NeedBetterY0 で止まり、解き直す。解き直しで計時を始め直さない
c_ev = {offset(net), odeEventSet("trip", net, "TimeSpan", [0.5,0.6], "TripUnit", "SG1B003")};
assert(run_with_delay(net, [0,1], c_ev, 0, Inf) == 1)
[flag, output] = run_with_delay(net, [0,1], c_ev, 1, 0.9);
assert(flag == 0, "flag " + flag)
assert(output.tEnd < 1)


function c_ev = faults(net)
    c_ev = arrayfun(@(t) odeEventSet("fault" + t, net, "TimeSpan", [t,t+0.05], "FaultBus", "B008"), 1:4, "UniformOutput", false);
end

function [flag, output] = run_with_delay(net, tspan, c_events, t_delay, t_limit)
    s_options = net.solver_ODE.get_options({"Progress", "none", "TimeLimit", t_limit});
    s_options.PhaseProbe = @(o) pause(t_delay);
    [~, flag, output] = net.solver_ODE.solve(net, tspan, c_events, s_options);
end
