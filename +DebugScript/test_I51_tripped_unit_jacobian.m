% I51 解列時のヤコビアンと、初期値を計算し直す経路 (フォールバック)
%
%   getODEJacobian     : 解列した機器の電流項は右辺と同じく母線の行に入らない
%   初期条件           : 微分状態を固定して代数変数を解き直した後も、全設定が有効
%   CalculateInitialCondition : 代数変数を解けなければエラーで、微分状態は動かさない
%
% 実行: runtests("DebugScript.test_I51_tripped_unit_jacobian")  または  DebugScript.run_all("Features","I51")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
inwin = @(t,a,b) t > a & t < b;
% 第 1 区間 [0,1] の代数変数を大きく解き直す入力
offset = @(n, val) DebugScript.helper.scenario("offset", n, "TimeSpan", 0, "OffsetUnit", "B002SG1", ...
                               "OffsetState", "delta", "OffsetValue", val);


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Jacobian matches the right-hand side while a generator is tripped
err = jacobian_errors(net, [0,2], {DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B003SG1")});
assert(numel(err) == 3)
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side while a load is tripped
err = jacobian_errors(net, [0,2], {DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B003LPQ2")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side during a fault
err = jacobian_errors(net, [0,2], {DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side with a tripped unit under a global controller
agc = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"], parameter=struct(kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);
err = jacobian_errors(net, [0,2], {DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B002SG1")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Jacobian matches the right-hand side with local controllers on other units
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
err = jacobian_errors(net, [0,2], {DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B002SG1")});
assert(max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Trip does not depend on the tolerance
ev = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B003SG1");
r1 = net.simulate([0,2], ev).odeResults;
r2 = net.simulate([0,2], ev, Tolerance=1e-8, AbsoluteTolerance=1e-8).odeResults;
X1 = r1.Bus(3).Component(1).X;
X2 = r2.Bus(3).Component(1).X;
assert(max(abs(X1{end,:} - X2{end,:})) < 1e-3)
d1 = X1.delta(find(r1.t > 1.2, 1));
d2 = X2.delta(find(r2.t > 1.2, 1));
assert(abs(d1 - d2) < 1e-3, "復帰時の delta: " + d1 + ", " + d2)


%% MaxStep applies in the trip phase
ev = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B003SG1");
opt = matlab.ode.options.ODE15s;
opt.MaxStep = 1e-3;
r = net.simulate([0,2], ev, SolverOptions=opt).odeResults;
assert(max(diff(r.t(inwin(r.t,1,1.2)))) < 1.1e-3)


%% Phase with a recomputed initial condition honors MaxStep
opt = matlab.ode.options.ODE15s;
opt.MaxStep = 1e-3;
r = net.simulate([0,0.1], offset(net,1), SolverOptions=opt).odeResults;
assert(max(diff(r.t)) < 1.1e-3, "最大刻み " + max(diff(r.t)))


%% Phase with a recomputed initial condition honors Solver
r15 = net.simulate([0,0.1], offset(net,1)).odeResults;
r23 = net.simulate([0,0.1], offset(net,1), Solver="ode23t", SolverOptions=matlab.ode.options.ODE23t).odeResults;
assert(numel(r15.t) ~= numel(r23.t) || any(r15.t ~= r23.t))


%% Phase with a recomputed initial condition honors TimeLimit
opt = matlab.ode.options.ODE15s;
opt.MaxStep = 1e-4;
[~, flag, output] = net.simulate([0,10], offset(net,1), SolverOptions=opt, TimeLimit=0.2);
assert(flag == 0)
assert(output.tEnd < 10)


%% Phase with a recomputed initial condition honors Progress
str = evalc('net.simulate([0,0.1], offset(net,1), Progress="disp");');
assert(strlength(str) > 0)


%% Phases after an offset start without its initial slope
% 次の区間で状態の数が変わっても、前の区間の InitialSlope を持ち越さない
tr = DebugScript.helper.scenario("trip", net, "TimeSpan", [0.5,0.6], "TripUnit", "B003SG1");
[~, flag] = net.simulate([0,1], offset(net,1), tr);
assert(flag == 1)


%% Offset keeps the differential states and solves the algebraic ones
% ずらした delta はそのまま始まり (以前は decic が微分状態ごと動かし、警告だけだった)、
% 母線電圧は新しい delta で解き直される
[sol, flag] = net.simulate([0,0.1], offset(net,1));
assert(flag == 1)
r = sol.odeResults;
X = r.Bus(2).Component(1).X;
assert(X.delta(1) == net.a_Bus{2}.a_Component{1}.rv_Xequilibrium(1) + 1, "delta(0) " + X.delta(1))
assert(abs(r.Bus(2).V.Vreal(1) - real(net.a_Bus{2}.c_Vequilibrium)) > 1e-2)


%% Offset without consistent algebraic variables stops instead of moving the states
% delta を 3 ずらすと、微分状態を固定した代数方程式に解が無い (定電力負荷)
w = warning("off", "GUILDA:PowerNetwork:SimulationIncomplete");
c_w = onCleanup(@() warning(w));
[~, flag, output] = net.simulate([0,0.1], offset(net,3));
assert(flag == -1)
ME = output.exception;
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:InitialConditionFailed", DebugScript.helper.msg_id(ME) + ": " + ME.message)
assert(contains(ME.message, "phase 1") && contains(ME.message, "differential states kept"), ME.message)


%% Trip does not warn about the initial condition
lastwarn("");
net.simulate([0,2], DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", "B003SG1"));
assert(isempty(lastwarn()), lastwarn())


%% Failed initial condition stops with flag -1 naming the phase
ev = DebugScript.helper.scenario("nan", net, "TimeSpan", [1,1.2], "InputUnit", "B005LPQ1", "InputName", "Pload", "InputValue", NaN);
w = warning("off", "GUILDA:PowerNetwork:SimulationIncomplete");
c_warn = onCleanup(@() warning(w));
[~, flag, output] = net.simulate([0,2], ev);
assert(flag == -1)
ME = output.exception;
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:InitialConditionFailed", DebugScript.helper.msg_id(ME) + ": " + ME.message)
assert(contains(ME.message, "phase 2") && contains(ME.message, "t = [1, 1.2]"), ME.message)
assert(DebugScript.helper.msg_id(ME.cause{1}) == "GUILDA:SolverODE:AlgebraicNotSolved", DebugScript.helper.msg_id(ME.cause{1}))


function err = jacobian_errors(net, tspan, c_events)
% 全区間で、解析的なヤコビアンと右辺の中心差分の最大誤差
    box = containers.Map("KeyType", "double", "ValueType", "double");
    sct_options = net.solver_ODE.get_options({"Progress", "none"});
    sct_options.PhaseProbe = @(o) store(box, jacobian_error_ode(o));
    net.solver_ODE.solve(net, tspan, c_events, sct_options);
    err = cell2mat(box.values);
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
