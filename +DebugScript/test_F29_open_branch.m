% F29 ブランチの開放 (Scenario の OpenBranch)
%
%   sc = net.add_scenario("open");  sc.add_open_branch("EL003", [t1,t2]);
%   (テストでは DebugScript.helper.scenario("open", net, "TimeSpan", [t1,t2], "OpenBranch", "EL003"))
%
% OpenBranch のブランチは t1 から t2 まで網の Y から除かれ、t2 で再投入される。
% t2 が計算時間の終わり以降なら開放のまま (地絡の後に回線を切る使い方)。
% 区間ごとに ctx.Ymat を作り直し、右辺、ヤコビアン、結果の母線電流がその区間の Y を使う。
%
% 実行: runtests("DebugScript.test_F29_open_branch")  または  DebugScript.run_all("Features","F29")

% 共通設定 (各テストの前に毎回実行される)
net = build_avr_pss();
inwin = @(t, t1, t2) t > t1 + 1e-3 & t < t2 - 1e-3;   % 区間の内側 (境界の重複点を除く)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Open and reclose returns near the equilibrium
% EL003 (B002-B003) を 1.0〜1.2 秒に開放して再投入する
[sol, flag, output] = net.simulate(DebugScript.helper.scenario("open", net, "TimeSpan", [1,1.2], "OpenBranch", "EL003").s_tag, Time=[0,10]);
assert(flag == 1 && output.nPhases == 3, output.message)
r = sol.odeResults;
assert(r.t(end) == 10)

omega = r.Bus(1).Component(1).X.omega;
assert(max(abs(omega(r.t < 1))) < 1e-8, "開放前は平衡点")
assert(max(abs(omega)) > 1e-4, "開放で動く")
assert(abs(omega(end)) < 5e-4, "omega(end) = " + omega(end))
for i = 1:numel(net.a_Bus)
    V_end = r.Bus(i).V{end,:} * [1;1j];
    assert(abs(abs(V_end) - abs(net.a_Bus{i}.c_Vequilibrium)) < 1e-3, "B" + i)
end


%% Y of the open phase is the Y without the branch
c_Y = phase_admittance(net, [0,2], {DebugScript.helper.scenario("open", net, "TimeSpan", [1,1.2], "OpenBranch", "EL003")});
Y_full = full_admittance(net);
Y_open = admittance_without("EL003");
assert(numel(c_Y) == 3)
assert(isequal(c_Y{1}, Y_full) && isequal(c_Y{3}, Y_full), "閉じた区間は元の Y")
assert(issparse(c_Y{2}))
assert(norm(full(c_Y{2} - Y_open), 1) < 1e-12, "開放区間: " + norm(full(c_Y{2} - Y_open), 1))
assert(norm(full(c_Y{2} - Y_full), 1) > 1, "開放で Y が変わる")


%% Jacobian matches the right-hand side in the open phase
% 解析的なヤコビアンと右辺の中心差分 (I51 と同じ方法) が開放区間でも一致する
box = containers.Map("KeyType", "double", "ValueType", "double");
sct_options = DebugScript.helper.ode_options("Progress", "none");
sct_options.PhaseProbe = @(o) store(box, jacobian_error_ode(o));
net.solver_ODE.solve(net, [0,2], {DebugScript.helper.scenario("open", net, "TimeSpan", [1,1.2], "OpenBranch", "EL003")}, sct_options);
err = cell2mat(box.values);
assert(numel(err) == 3 && max(err) < 1e-5, "誤差 " + mat2str(err,3))


%% Bus currents follow the Y of each phase
% 結果の母線電流 I は各区間の Y と電圧から I = Y*V
ev  = DebugScript.helper.scenario("open", net, "TimeSpan", [1,1.2], "OpenBranch", "EL003");
r   = net.simulate(ev.s_tag, Time=[0,2]).odeResults;
[V, I] = bus_trajectories(r);
Y_full = full_admittance(net);
Y_open = admittance_without("EL003");

lv = inwin(r.t, 1, 1.2);
assert(any(lv))
assert(max(abs(I(lv,:) - V(lv,:)*Y_open.'), [], "all") < 1e-10)
assert(max(abs(I(lv,:) - V(lv,:)*Y_full.'), [], "all") > 1e-3, "開放区間は元の Y と一致しない")
lv = r.t < 1 - 1e-3 | inwin(r.t, 1.2, 2);
assert(max(abs(I(lv,:) - V(lv,:)*Y_full.'), [], "all") < 1e-10)


%% Permanent opening after a fault
% B003 の地絡を 70 ms で除去し、同時に EL003 (B002-B003) を計算の終わりまで開放する。
% 計算時間の外へはみ出す t_end で警告は出ない
ev_fault = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.07], "FaultBus", "B003");
ev_open  = DebugScript.helper.scenario("open",  net, "TimeSpan", [1.07,20], "OpenBranch", "EL003");
lastwarn("");
[sol, flag, output] = net.simulate(DebugScript.helper.combine(net, ev_fault, ev_open).s_tag, Time=[0,10]);
assert(isempty(lastwarn()), "警告: " + lastwarn())
assert(flag == 1 && output.nPhases == 3, output.message)
assert(isequal(output.phases{:, ["t1","t2"]}, [0,1; 1,1.07; 1.07,10]))
r = sol.odeResults;
assert(r.t(end) == 10)

[V, I] = bus_trajectories(r);
lv = inwin(r.t, 1.07, 10);
assert(max(abs(I(lv,:) - V(lv,:)*admittance_without("EL003").'), [], "all") < 1e-10)
% 調速機がないので、損失の増えた分だけ全発電機が同じ周波数偏差 (約 -0.01) へ向かう
% (EL003 を除いて初期化した網はこの偏差なしで安定)。発電機どうしの差は減衰する
omega = cell2mat(arrayfun(@(g) r.Bus(g).Component(1).X.omega, [1,2,3,6,8], "UniformOutput", false));
assert(all(isfinite(omega), "all") && max(abs(omega), [], "all") < 0.05)
spread = @(lv) max(max(omega(lv,:), [], 2) - min(omega(lv,:), [], 2));
assert(spread(r.t > 9) < 0.5*spread(inwin(r.t, 1.07, 3)), "発電機の周波数の差が減衰しない")


%% Overlapping openings use the union of the open branches
ev1 = DebugScript.helper.scenario("open1", net, "TimeSpan", [1,2], "OpenBranch", "EL003");
ev2 = DebugScript.helper.scenario("open2", net, "TimeSpan", [1.5,2.5], "OpenBranch", ["EL005"; "EL003"]);
c_Y = phase_admittance(net, [0,3], {ev1, ev2});
assert(numel(c_Y) == 5)
c_ref = {full_admittance(net), admittance_without("EL003"), admittance_without(["EL003","EL005"]), ...
         admittance_without(["EL003","EL005"]), full_admittance(net)};
for tp = 1:5
    assert(norm(full(c_Y{tp} - c_ref{tp}), 1) < 1e-12, "区間 " + tp)
end


%% Without OpenBranch the admittance is unchanged
% 開放のない区間の Y は従来と同じ式 sparse(complex2matrix(Y)) で、結果も変わらない
c_Y = phase_admittance(net, [0,2], {DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008")});
Y_ref = sparse(tools.complex2matrix(net.get_admittance_matrix.Variables));
assert(numel(c_Y) == 3 && all(cellfun(@(Y) isequal(Y, Y_ref), c_Y)))


%% One event can fault a bus and open a branch
ev = DebugScript.helper.scenario("both", net, "TimeSpan", [1,1.05], "FaultBus", "B008", "OpenBranch", "EL003");
[~, flag, output] = net.simulate(ev.s_tag, Time=[0,2]);
assert(flag == 1, output.message)


%% Unknown branch tag stops with an error
[s_id, s_msg] = call_error(@() DebugScript.helper.scenario("open", net, "TimeSpan", [1,2], "OpenBranch", ["EL003"; "EL999"]));
assert(s_id == "GUILDA:Scenario:UnknownOpenBranch", s_id + ": " + s_msg)
assert(contains(s_msg, '"open"') && contains(s_msg, "EL999") && ~contains(s_msg, "EL003,"), s_msg)


%% Opening needs a duration
for ts = {1, [1,1]}
    [s_id, s_msg] = call_error(@() DebugScript.helper.scenario("open", net, "TimeSpan", ts{1}, "OpenBranch", "EL003"));
    assert(s_id == "GUILDA:Scenario:ZeroLengthTimeSpan", s_id + ": " + s_msg)
end


%% A part of the network without components is an error
% B004 は機器がなく、EL003 だけで B003 につながる。開放すると電圧が決まらない (DAE が特異)
net3 = DebugScript.helper.build_3bus("load-impedance");
net3.add_bus();
net3.add_branch("pi", [3,4], "R", 0.01, "X", 0.1, "C", 0.01);
DebugScript.helper.quiet(@() net3.initialize);
ev = DebugScript.helper.scenario("open", net3, "TimeSpan", [1,1.5], "OpenBranch", "EL003");
[s_id, s_msg] = event_error(net3, ev);
assert(s_id == "GUILDA:SolverODE:OpenBranchIsland", s_id + ": " + s_msg)
assert(all(contains(s_msg, ["EL003", "B004", "Phase 2"])), s_msg)


%% A part with components is simulated as an island
% ET020 は B008 (発電機のみ) を網につなぐ唯一のブランチ
[~, flag, output] = net.simulate(DebugScript.helper.scenario("open", net, "TimeSpan", [1,1.2], "OpenBranch", "ET020").s_tag, Time=[0,2]);
assert(flag == 1, output.message)


%% Open branch after the fallback to dense matrices
% 大きな系統で密行列へ切り替わった後も、開放区間の Y は密で、回線を除いた Y になる
net_r = ring(136);
c_Y = phase_admittance(net_r, [0,0.1], {DebugScript.helper.scenario("open", net_r, "TimeSpan", [0.05,0.08], "OpenBranch", "EL001")});
Y_open = full_admittance(net_r);
br = net_r.a_Branch{1};
Y_open(1:4,1:4) = Y_open(1:4,1:4) - tools.complex2matrix(br.get_admittance_matrix());   % B001, B002
assert(numel(c_Y) == 3 && ~issparse(c_Y{2}) && ~issparse(c_Y{3}))
assert(norm(c_Y{2} - Y_open, 1) < 1e-12)
assert(isequal(full(c_Y{3}), full(full_admittance(net_r))))


% ---- local functions ----
function net = build_avr_pss()
    % IEEE14 の 2 台の発電機に AVR + PSS (F6 "Fault with local controllers" と同じ)
    net = DebugScript.helper.build_ieee14();
    for i = 1:2
        net.a_Bus{i}.a_Component{1}.add_local_controller("avr-ST1");
        net.a_Bus{i}.a_Component{1}.add_local_controller("pss-PSS1");
    end
    DebugScript.helper.quiet(@() net.initialize);
end

function Y = full_admittance(net)
    Y = sparse(tools.complex2matrix(net.get_admittance_matrix.Variables));
end

function Y = admittance_without(sv_branch)
    % 同じ IEEE14 からブランチを除いた網の Y (remove_branch で直接作る)
    net = DebugScript.helper.build_ieee14();
    net.remove_branch(sv_branch);
    Y = sparse(tools.complex2matrix(net.get_admittance_matrix.Variables));
end

function c_Y = phase_admittance(net, time, c_events)
    % 各区間の右辺が使う ctx.Ymat (PhaseProbe で ode の右辺から取り出す)
    box = containers.Map("KeyType", "double", "ValueType", "any");
    sct_options = DebugScript.helper.ode_options("Progress", "none");
    sct_options.PhaseProbe = @(o) store(box, ode_ymat(o));
    [~, flag, output] = net.solver_ODE.solve(net, time, c_events, sct_options);
    assert(flag == 1, output.message)
    % PhaseProbe は区間ごとに 1 回 (密行列で解き直す区間は、切り替え前の疎行列を記録)
    assert(box.Count == output.nPhases)
    c_Y = box.values(num2cell(1:box.Count));
end

function v = ode_ymat(o)
    s = functions(o.ODEFcn);
    v = s.workspace{1}.ctx.Ymat;
end

function store(box, val)
    box(box.Count+1) = val;
end

function err = jacobian_error_ode(o)
    % 平衡点から少しずらした点で、ヤコビアンと右辺の中心差分の最大誤差 (I51 と同じ)
    n  = numel(o.InitialValue);
    x  = o.InitialValue + 1e-3*sin(1:n)';
    J  = o.Jacobian.Jacobian(0, x);
    h  = 1e-6;
    Jn = zeros(n);
    for i = 1:n
        e = zeros(n,1);  e(i) = h;
        Jn(:,i) = (o.ODEFcn(0, x+e) - o.ODEFcn(0, x-e)) / (2*h);
    end
    err = max(abs(J - Jn), [], "all");
end

function [V, I] = bus_trajectories(r)
    % 各母線の [Vreal, Vimag] と [Ireal, Iimag] を並べた行列 (tools.complex2matrix の並び)
    V = cell2mat(arrayfun(@(b) b.V{:,:}, r.Bus(:).', "UniformOutput", false));
    I = cell2mat(arrayfun(@(b) b.I{:,:}, r.Bus(:).', "UniformOutput", false));
end

function [s_id, s_msg] = event_error(net, varargin)
    [s_id, s_msg] = call_error(@() net.simulate(varargin{1}.s_tag, Time=[0,3]));
end

function [s_id, s_msg] = call_error(f)
    s_id    = "";
    s_msg   = "";
    try
        f();
    catch ME
        s_id    = string(DebugScript.helper.msg_id(ME));
        s_msg   = string(ME.message);
    end
end

function net = ring(N)
    % 発電機 (AVR+PSS) とインピーダンス負荷を交互に並べた人工系統 (I64 と同じ)
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
