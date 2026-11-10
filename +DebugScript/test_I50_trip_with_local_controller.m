% I50 局所制御器付きの発電機の解列
%
%   復帰時の制御器の微分状態は保持済みの平衡点から再開し (Q2)、平衡点は書き換えない
%   質量が 0 の代数状態は、解列区間の次の区間の初期値計算で母線電圧に合わせて決まる
%
% 実行: runtests("DebugScript.test_I50_trip_with_local_controller")  または  DebugScript.run_all("Features","I50")

% 共通設定 (各テストの前に毎回実行される)
trip = @(n, ts) DebugScript.helper.scenario("trip", n, "TimeSpan", ts, "TripUnit", "SG1B003");


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Default IEEE9 trip completes
net = ieee9();
[sol, eq] = run_trip(net, [0,2], trip(net, [1,1.2]));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
assert_restart(sol, net.a_Bus{3}.a_Component{1}, 1.2)


%% Default IEEE9 trip with a longer horizon completes
net = ieee9();
[sol, eq] = run_trip(net, [0,10], trip(net, [1,1.2]));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)


%% Default IEEE9 trip until the end completes
net = ieee9();
[sol, eq] = run_trip(net, [0,2], trip(net, [1,2]));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
X = sol.odeResults.Bus(3).Component(1).X.Variables;
assert(all(isnan(X(sol.odeResults.t > 1,:)), "all"))


%% Trip with AVR restarts from the stored equilibrium
net = ieee14(@(gen) gen.add_local_controller("avr-ST1"));
[sol, eq] = run_trip(net, [0,2], trip(net, [1,1.2]));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
assert_restart(sol, net.a_Bus{3}.a_Component{1}, 1.2)


%% Trip with AVR and PSS restarts from the stored equilibrium
net = ieee14(@(gen) add_avr_pss(gen));
[sol, eq] = run_trip(net, [0,2], trip(net, [1,1.2]));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)
assert_restart(sol, net.a_Bus{3}.a_Component{1}, 1.2)


%% Trip with LQR completes
net = ieee14(@(gen) gen.add_local_controller("local-LQR"));
[sol, eq] = run_trip(net, [0,2], trip(net, [1,1.2]));
assert(sol.flag == 1, sol.output.message)
assert_unchanged(net, eq)


%% A run after a trip stays at the equilibrium
net = ieee9();
run_trip(net, [0,2], trip(net, [1,1.2]));
r = net.simulate([0,2], Progress="none").odeResults;
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
    sol = net.simulate(tspan, ev, Progress="none", TimeLimit=120);
end


function assert_unchanged(net, eq)
    assert(isequal(net.rv_Xequilibrium, eq), "平衡点が書き換えられた")
end


function assert_restart(sol, gen, t2)
% 復帰時の制御器の微分状態が、保持済みの平衡点に一致する
    tab = gen.get_variable_map();
    val = sol.get_point(t2, tab, Side="after");
    a_LC = gen.a_LocalController;
    if ~isempty(a_LC)
        a_LC = [a_LC, a_LC{1}.a_LocalController];
    end
    for k = 1:numel(a_LC)
        lc = a_LC{k};
        rv = val(tab.Kind == "x" & tab.Owner == lc.s_tag);
        lv = diag(lc.f_Mass([],[],[],[])) ~= 0;
        assert(numel(rv) == numel(lv), lc.s_tag + " の状態が地図にない")
        assert(max(abs(rv(lv) - lc.rv_Xequilibrium(lv)), [], "all") < 1e-9, lc.s_tag + " が平衡点から再開していない")
    end
end
