% I50 ローカル制御器付きの発電機の解列
%
%   解列は終わりまで続き (再接続はない)、解列した発電機の状態は NaN、平衡点は書き換えない
%   ローカル制御器の付いた発電機でも計算は最後まで進む
%
% 実行: runtests("DebugScript.test_I50_trip_with_local_controller")  または  DebugScript.run_all("Features","I50")

% 共通設定 (各テストの前に毎回実行される)
trip = @(n, ts) DebugScript.helper.scenario("trip", n, "TimeSpan", ts, "TripUnit", "B003SG1");


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Default IEEE9 trip completes
net = ieee9();
[sol, eq] = run_trip(net, [0,2], trip(net, 1));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
assert_tripped(sol, 1)


%% Default IEEE9 trip with a longer horizon completes
net = ieee9();
[sol, eq] = run_trip(net, [0,10], trip(net, 1));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)


%% Default IEEE9 trip until the end completes
net = ieee9();
[sol, eq] = run_trip(net, [0,2], trip(net, 1));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
X = sol.odeResults.Bus(3).Component(1).X.Variables;
assert(all(isnan(X(sol.odeResults.t > 1,:)), "all"))


%% Trip with AVR completes
net = ieee14(@(gen) gen.add_local_controller("avr-ST1"));
[sol, eq] = run_trip(net, [0,2], trip(net, 1));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
assert_tripped(sol, 1)


%% Trip with AVR and PSS completes
net = ieee14(@(gen) add_avr_pss(gen));
[sol, eq] = run_trip(net, [0,2], trip(net, 1));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
assert_tripped(sol, 1)


%% Trip with LQR completes
net = ieee14(@(gen) gen.add_local_controller("local-LQR"));
[sol, eq] = run_trip(net, [0,2], trip(net, 1));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)


%% A run after a trip stays at the equilibrium
net = ieee9();
run_trip(net, [0,2], trip(net, 1));
r = net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,2], Progress="none").odeResults;
for i = 1:3
    X = r.Bus(i).Component(1).X.Variables;
    assert(max(abs(X - X(1,:)), [], "all") < 1e-9, "母線 " + i + " の状態が動いた")
end


function net = ieee9()
    net = network.IEEE9bus();
    
    DebugScript.helper.quiet(@() net.initialize);
end


function add_avr_pss(gen)
    gen.add_local_controller("avr-ST1");
    gen.add_local_controller("pss-PSS1");
end


function net = ieee14(add)
    net = DebugScript.helper.build_ieee14();
    add(net.a_Bus{3}.a_Component{1});
    DebugScript.helper.quiet(@() net.initialize);
end


function [sol, eq] = run_trip(net, tspan, ev)
    eq  = net.rv_Xequilibrium;
    sol = net.simulate(ev.s_tag, Time=tspan, Progress="none", TimeLimit=120);
end


function assert_unchanged(net, eq)
    assert(isequal(net.rv_Xequilibrium, eq), "平衡点が書き換えられた")
end


function assert_tripped(sol, t1)
% 解列した発電機 (母線 3) の状態は解列の後、終わりまで NaN
    X = sol.odeResults.Bus(3).Component(1).X.Variables;
    assert(all(isnan(X(sol.odeResults.t > t1,:)), "all"), "解列の後の状態が NaN でない")
end
