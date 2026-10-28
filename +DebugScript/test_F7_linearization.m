% F7 近似線形化 (get_sys / odeLinearizer)
%
% 平衡点まわりの線形モデルを 3 つの方式で求める。
%   sys = net.get_sys("Algorithm", "Kron" | "Feedback" | "DAE", "NonUnit", 母線番号);
%   lin = odeLinearizer(net, NonUnit, "Algorithm", ...);  sys = lin.get_sys;
% sys は記述子形式の状態空間モデル (dss: E dx = A x + B u)。
% 3 方式の有限固有値が一致すること、IEEE14 の平衡点が安定であることを確認する。
%
% 実行: runtests("DebugScript.test_F7_linearization")  または  DebugScript.run_all("Features","F7")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
n_x = sum(cellfun(@(b) sum(cellfun(@(c) numel(c.sv_x), b.a_Component)), net.a_Bus));   % 機器の状態数
eig_finite = @DebugScript.helper.finite_eigs;    % 有限な一般化固有値
same_eigs  = @DebugScript.helper.same_eigs;      % 固有値の集合が一致するか


%% Get sys Kron
sys = net.get_sys("Algorithm", "Kron");
assert(isa(sys, "ss"))
assert(size(sys.A,1) == n_x)
assert(numel(sys.StateName) == size(sys.A,1))


%% Get sys Feedback
% 既定の方式は Feedback
sys = net.get_sys();
assert(isa(sys, "ss"))
assert(size(sys.A,1) >= n_x)


%% Get sys DAE
% DAE 方式は母線電圧・電流などの代数変数も状態に含む (E が特異)
sys = net.get_sys("Algorithm", "DAE");
assert(isa(sys, "ss"))
assert(size(sys.A,1) > n_x)
assert(rank(sys.E) < size(sys.E,1))


%% Three algorithms give same eigenvalues
e_kron = eig_finite(net.get_sys("Algorithm","Kron"));
e_fb   = eig_finite(net.get_sys("Algorithm","Feedback"));
e_dae  = eig_finite(net.get_sys("Algorithm","DAE"));
assert(same_eigs(e_kron, e_fb,  1e-6), "Kron と Feedback の固有値が一致しない")
assert(same_eigs(e_kron, e_dae, 1e-6), "Kron と DAE の固有値が一致しない")


%% IEEE14 equilibrium is stable
% 回転不変性による 0 固有値を除き、すべての固有値の実部が負
e = eig_finite(net.get_sys("Algorithm","Kron"));
assert(max(real(e)) < 1e-6, "不安定な固有値がある: " + max(real(e)))
assert(sum(abs(e) < 1e-6) <= 1)


%% Non unit bus
% B007 を機器のない母線として扱う (旧 Task9)
sys_all = net.get_sys("Algorithm","Kron");
sys_nu  = net.get_sys("Algorithm","Kron", "NonUnit", 7);
assert(isa(sys_nu, "ss"))
assert(size(sys_nu.A,1) <= size(sys_all.A,1))
assert(same_eigs(eig_finite(sys_nu), eig_finite(net.get_sys("Algorithm","Feedback","NonUnit",7)), 1e-6))


%% With local controllers
% AVR/PSS を付けると制御器の状態が加わる (旧 Task15)
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 3 + 3)
assert(max(real(eig_finite(sys))) < 1e-6)


%% With global controller
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 1)
assert(same_eigs(eig_finite(sys), eig_finite(net.get_sys("Algorithm","Feedback")), 1e-6))


%% odeLinearizer direct use
% odeLinearizer を直接使う場合 (旧 Task9 の lin.getLinearSystem は lin.get_sys に変更済み)
lin = odeLinearizer(net, [], "Algorithm", "Kron");
sys = lin.get_sys;
assert(isa(sys, "ss") && isequal(sys, lin.odeLinearSystem))
[A, B, C, D, E] = lin.get_sys;
assert(isequal(size(A), size(E)) && size(B,1) == size(A,1) && size(C,2) == size(A,1) && size(D,1) == size(C,1))
