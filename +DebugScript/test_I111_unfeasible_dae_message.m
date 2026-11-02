% Issue 111: 発電機母線の故障で初期条件が解けないときのメッセージ
%
%   定電力負荷へ電力を送れない故障では decic が収束しない。理由と変更点を伝え、
%   ode15s の tspan/y0 の文言や ans = 0 を出さない。定インピーダンス負荷なら解ける
%
% 実行: runtests("DebugScript.test_I111_unfeasible_dae_message")  または  DebugScript.run_all("Features","I111")

% 共通設定 (各テストの前に毎回実行される)
c_warn = {warning("off", "GUILDA:PowerNetwork:SimulationIncomplete")};
c_warn{2} = onCleanup(@() warning(c_warn{1}));


%% Fault on a generator bus explains the failure
for str_bus = ["B001","B002"]
    [net, ev] = build_case("load-power", str_bus);
    [sol, flag, output] = net.simulate([0,2], ev);
    assert(flag == -1 && sol.flag == -1)
    assert(DebugScript.helper.msg_id(output.exception) == "GUILDA:odeSimulator:InitialConditionFailed")
    assert(contains(output.message, "algebraic equations"))
    assert(contains(output.message, "load-impedance"))
    assert(~contains(output.message, "tspan") && ~contains(output.message, "y0"))
end


%% Failure prints nothing unexpected
[net, ev] = build_case("load-power", "B001");
str_out = evalc("net.simulate([0,2], ev);");
assert(~contains(str_out, "ans"))
assert(~contains(str_out, "tspan"))


%% The remedy of the message solves the same faults
for str_bus = ["B001","B002"]
    [net, ev] = build_case("load-impedance", str_bus);
    [~, flag] = net.simulate([0,2], ev);
    assert(flag == 1)
end


function [net, ev] = build_case(str_load, str_bus)
    net = PowerNetwork("Test3Bus");
    net.add_bus("V",1.00);
    net.add_bus("V",1.02);
    net.add_bus();
    net.add_branch("pi",[1,2], "R",0.010, "X",0.085);
    net.add_branch("pi",[2,3], "R",0.017, "X",0.092);
    net.a_Bus{1}.add_component("gen-park");
    net.a_Bus{2}.add_component("gen-classical", "P", 0.5, "Q", nan);
    net.a_Bus{3}.add_component(str_load, "P",-1.0, "Q",-0.2);
    net.solver_ODE.Progress = "none";
    DebugScript.helper.quiet(@() net.initialize);
    ev = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", str_bus);
end
