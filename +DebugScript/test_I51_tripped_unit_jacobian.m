% I51 解列時のヤコビアンと、初期値を計算し直す経路 (フォールバック)
%
%   getODEJacobian     : 解列した機器の電流項は右辺と同じく母線の行に入らない
%   フォールバック     : NeedBetterY0 の後も同じ ode オブジェクトで解き、全設定が有効
%   CalculateInitialCondition : decic の失敗はエラー、微分状態の移動は警告で通知
%
% 実行: runtests("DebugScript.test_I51_tripped_unit_jacobian")  または  DebugScript.run_all("Features","I51")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
inwin = @(t,a,b) t > a & t < b;
% 第 1 区間 [0,1] からフォールバックに入る入力 (decic が微分状態を動かす)
offset = @(n) odeEventSet("offset", n, "TimeSpan", 0, "OffsetUnit", "SG1B002", ...
                          "OffsetState", "delta", "OffsetValue", 3);
c_warn = {warning("off", "GUILDA:odeSimulator:InitialConditionRelaxed")};
c_warn{2} = onCleanup(@() warning(c_warn{1}));


%% Jacobian matches the right-hand side while a generator is tripped
err = jacobian_errors(net, [0,2], {odeEventSet("trip", net, "TimeSpan", [1,1.2], "TripUnit", "SG1B003")});
assert(numel(err) == 3)
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side while a load is tripped
err = jacobian_errors(net, [0,2], {odeEventSet("trip", net, "TimeSpan", [1,1.2], "TripUnit", "LPQ2B003")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side during a fault
err = jacobian_errors(net, [0,2], {odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side with a tripped unit under a global controller
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002", kP=100, kI=500);
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);
err = jacobian_errors(net, [0,2], {odeEventSet("trip", net, "TimeSpan", [1,1.2], "TripUnit", "SG1B002")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side with local controllers on other units
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"));
DebugScript.helper.quiet(@() net.initialize);
err = jacobian_errors(net, [0,2], {odeEventSet("trip", net, "TimeSpan", [1,1.2], "TripUnit", "SG1B002")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Trip does not depend on the tolerance
ev = odeEventSet("trip", net, "TimeSpan", [1,1.2], "TripUnit", "SG1B003");
r1 = net.simulate([0,2], ev).odeResults;
r2 = net.simulate([0,2], ev, Tolerance=1e-8, AbsoluteTolerance=1e-8).odeResults;
X1 = r1.Bus(3).Component(1).X;
X2 = r2.Bus(3).Component(1).X;
assert(max(abs(X1{end,:} - X2{end,:})) < 1e-3)
d1 = X1.delta(find(r1.t > 1.2, 1));
d2 = X2.delta(find(r2.t > 1.2, 1));
assert(abs(d1 - d2) < 1e-3, "復帰時の delta: " + d1 + ", " + d2)


%% MaxStep applies in the trip phase
ev = odeEventSet("trip", net, "TimeSpan", [1,1.2], "TripUnit", "SG1B003");
opt = matlab.ode.options.ODE15s;
opt.MaxStep = 1e-3;
r = net.simulate([0,2], ev, SolverOptions=opt).odeResults;
assert(max(diff(r.t(inwin(r.t,1,1.2)))) < 1.1e-3)


%% Fallback honors MaxStep
opt = matlab.ode.options.ODE15s;
opt.MaxStep = 1e-3;
r = net.simulate([0,0.1], offset(net), SolverOptions=opt).odeResults;
assert(max(diff(r.t)) < 1.1e-3, "最大刻み " + max(diff(r.t)))


%% Fallback honors Solver
r15 = net.simulate([0,0.1], offset(net)).odeResults;
r23 = net.simulate([0,0.1], offset(net), Solver="ode23t", SolverOptions=matlab.ode.options.ODE23t).odeResults;
assert(numel(r15.t) ~= numel(r23.t) || any(r15.t ~= r23.t))


%% Fallback honors TimeLimit
opt = matlab.ode.options.ODE15s;
opt.MaxStep = 1e-4;
[~, flag, output] = net.simulate([0,10], offset(net), SolverOptions=opt, TimeLimit=0.2);
assert(flag == 0)
assert(output.tEnd < 10)


%% Fallback honors Progress
str = evalc('net.simulate([0,0.1], offset(net), Progress="disp");');
assert(strlength(str) > 0)


%% Fallback uses the analytic Jacobian
% 最初の solve (NeedBetterY0 で止まる) の呼び出し回数は時間幅によらない。
% 解き直しでも使っていれば、長い区間ほど回数が増える
assert(jacobian_calls(net, offset(net), 2) > jacobian_calls(net, offset(net), 0.01))


%% Phases after a fallback start without its initial slope
% 次の区間で状態の数が変わっても、前の区間の InitialSlope を持ち越さない
tr = odeEventSet("trip", net, "TimeSpan", [0.5,0.6], "TripUnit", "SG1B003");
[~, flag] = net.simulate([0,1], offset(net), tr);
assert(flag == 1)


%% Relaxed initial condition warns with the distance moved
warning("on", "GUILDA:odeSimulator:InitialConditionRelaxed");
lastwarn("");
[~, flag] = net.simulate([0,0.1], offset(net));
[str, id] = lastwarn();
assert(flag == 1)
assert(id == "GUILDA:odeSimulator:InitialConditionRelaxed", id)
assert(contains(str, "phase 1") && contains(str, "moved by up to"), str)
assert(~isempty(regexp(str, "up to [0-9.]+", "once")), str)


%% Relaxed warning is not reported as a warning of the solver
warning("on", "GUILDA:odeSimulator:InitialConditionRelaxed");
[~, flag, output] = net.simulate([0,0.1], offset(net));
assert(flag == 1)
assert(~contains(output.message, "moved by up to"), output.message)


%% Trip does not warn about the initial condition
warning("on", "GUILDA:odeSimulator:InitialConditionRelaxed");
lastwarn("");
net.simulate([0,2], odeEventSet("trip", net, "TimeSpan", [1,1.2], "TripUnit", "SG1B003"));
[~, id] = lastwarn();
assert(id ~= "GUILDA:odeSimulator:InitialConditionRelaxed")


%% Failed initial condition stops with flag -1 naming the phase
ev = odeEventSet("nan", net, "TimeSpan", [1,1.2], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", NaN);
w = warning("off", "GUILDA:PowerNetwork:SimulationIncomplete");
c_warn = onCleanup(@() warning(w));
[~, flag, output] = net.simulate([0,2], ev);
assert(flag == -1)
ME = output.exception;
assert(ME.identifier == "GUILDA:odeSimulator:InitialConditionFailed", ME.identifier + ": " + ME.message)
assert(contains(ME.message, "phase 2") && contains(ME.message, "t = [1, 1.2]"), ME.message)
assert(endsWith(string(ME.cause{1}.identifier), "NeedBetterY0"), ME.cause{1}.identifier)


function err = jacobian_errors(net, tspan, c_events)
% 全区間で、解析的なヤコビアンと右辺の中心差分の最大誤差
    box = containers.Map("KeyType", "double", "ValueType", "double");
    s_options = net.solver_ODE.get_options({"Progress", "none"});
    s_options.PhaseProbe = @(o) store(box, jacobian_error_ode(o));
    net.solver_ODE.solve(net, tspan, c_events, s_options);
    err = cell2mat(box.values);
end

function n = jacobian_calls(net, ev, t_end)
    profile("clear"); profile("on");
    c_prof = onCleanup(@() profile("off"));
    net.simulate([0,t_end], ev);
    profile("off");
    tab = profile("info").FunctionTable;
    n   = sum([tab(contains(string({tab.FunctionName}), "getODEJacobian")).NumCalls]);
end

function store(box, val)
    box(box.Count+1) = val;
end

function err = jacobian_error_ode(o)
    n  = numel(o.InitialValue);
    x  = o.InitialValue + 1e-3*sin(1:n)';       % 平衡点でだけ 0 になる項も確かめる
    J  = o.Jacobian.Jacobian(0, x);
    h  = 1e-6;
    Jn = zeros(n);
    for i = 1:n
        e = zeros(n,1);  e(i) = h;
        Jn(:,i) = (o.ODEFcn(0, x+e) - o.ODEFcn(0, x-e)) / (2*h);
    end
    err = max(abs(J - Jn), [], "all");
end
