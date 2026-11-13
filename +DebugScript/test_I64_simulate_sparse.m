% I64 net.simulate の疎行列と、密行列での解き直し
%
%   既定 : 質量行列とヤコビアンは疎で、output.isSparse が true
%   誤検知: 大きな系統で ode15s の指数の検査が誤検知したら (IndexGTOne)、同じ区間を密で解き直す
%
% 実行: runtests("DebugScript.test_I64_simulate_sparse")  または  DebugScript.run_all("Features","I64")


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Mass matrix and Jacobian are sparse by default
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
box = containers.Map("KeyType", "double", "ValueType", "logical");
sct_options = DebugScript.helper.ode_options("Progress", "none");
sct_options.PhaseProbe = @(o) store(box, issparse(o.MassMatrix.MassMatrix) && ...
                                       issparse(o.Jacobian.Jacobian(0, o.InitialValue)));
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5,0.6], "FaultBus", "B008");
[~, flag, output] = DebugScript.helper.solve_direct(net, ev.s_tag, [0,1], sct_options);
assert(flag == 1 && output.isSparse)
assert(all(cell2mat(box.values)))


%% Sparse run agrees with the tight solution within the tolerance
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate(ev.s_tag, Time=[0,3]);
ref = net.simulate(ev.s_tag, Time=[0,3], Tolerance=1e-10, AbsoluteTolerance=1e-10);
assert(max(abs(sol.rm_variable(end,:) - ref.rm_variable(end,:))) < 1e-2)


%% False index error falls back to dense matrices
net = ring(136);
[~, flag, output] = net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,0.1], Progress="none");
assert(flag == 1 && ~output.isSparse)


%% Phases after the fallback stay dense and the fault is solved
net = ring(136);
box = containers.Map("KeyType", "double", "ValueType", "logical");
sct_options = DebugScript.helper.ode_options("Progress", "none");
sct_options.PhaseProbe = @(o) store(box, issparse(o.MassMatrix.MassMatrix));
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.05,0.06], "FaultBus", string(net.a_Bus{1}));
[res, flag, output] = DebugScript.helper.solve_direct(net, ev.s_tag, [0,0.1], sct_options);
assert(flag == 1 && ~output.isSparse)
assert(all(~cell2mat(box.values(num2cell(2:box.Count)))), "2 番目以降の区間は密")
assert(all(isfinite(res.rm_variable(end,:))))


%% TimeLimit includes the time of the fallback
net = ring(136);
[sol, flag, output] = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,1], Progress="none", TimeLimit=1e-3));
assert(flag == 0, "flag " + flag)
assert(~output.isSparse)
assert(sol.rv_t(end) < 1)


%% Input event on a phase after phases without one
% 入力イベントのない区間は入力の関数が無く、イベントのある区間だけ入力が効く
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("input", net, "TimeSpan", [0.5,1], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0.05);
sol = net.simulate(ev.s_tag, Time=[0,1.5], Progress="none");
ref = net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,1.5], Progress="none");
assert(max(abs(sol.rm_variable(end,:) - ref.rm_variable(end,:))) > 1e-4)


function net = ring(N)
    % 発電機 (AVR+PSS) とインピーダンス負荷を交互に並べた人工系統
    net = PowerNetwork("Ring" + N);
    for i = 1:N
        if mod(i,2) == 1
            net.add_bus("V", 1.0);
        else
            net.add_bus();
        end
    end
    for i = 1:N
        net.add_branch("pi", [i, mod(i,N)+1], "R", 0.01, "X", 0.1);
    end
    for i = 1:N
        if i == 1
            net.a_Bus{i}.add_component("gen-park");
        elseif mod(i,2) == 1
            net.a_Bus{i}.add_component("gen-park", "P", 0.5, "Q", nan);
        else
            net.a_Bus{i}.add_component("load-impedance", "P", -0.5, "Q", -0.1);
        end
    end
    for i = 1:2:N
        net.a_Bus{i}.a_Component{1}.add_local_controller("avr-ST1");
        net.a_Bus{i}.a_Component{1}.add_local_controller("pss-PSS1");
    end
    
    DebugScript.helper.quiet(@() net.initialize);
end

function store(box, val)
    box(box.Count+1) = val;
end
