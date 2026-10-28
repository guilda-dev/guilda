% F7 近似線形化 (get_sys / odeLinearizer)
%
% 平衡点まわりの線形モデルを 3 つの方式で求める。
%   sys = net.get_sys("Algorithm", "Kron" | "Feedback" | "DAE", "NonUnit", 母線番号);
%   lin = odeLinearizer(net, NonUnit, "Algorithm", ...);  sys = lin.get_sys;
% sys は記述子形式の状態空間モデル (dss: E dx = A x + B u)。
% 3 方式の有限固有値が一致すること、IEEE14 の平衡点が安定であることを確認する。
%
% 実行: runtests("DebugScript.test_F7_linearization")  または  DebugScript.run_all("Features","F7")

% 共通設定 (最初に 1 回だけ実行され、変数は全テストで共有される)
% net はハンドルなので、制御器の追加など net を変更するテストは new_net() で自分用の系統を作ること。
new_net = @() DebugScript.helper.build_ieee14();
net = new_net();
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
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 3 + 3)
assert(max(real(eig_finite(sys))) < 1e-6)


%% With global controller
net = new_net();
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


%% Analytic jacobians match numerical differentiation
% get_sys と odeSimulator が使う f_Jacobi* (Jacobi_dx / Jacobi_I / Jacobi_Y) が f_dx, f_I, f_Y の微分と一致する
for key = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-impedance","load-power"]
    [net3, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net3.initialize);
    err = DebugScript.helper.jacobian_error(comp);
    assert(err < 1e-6, key + ": Jacobian error " + err)
end
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
gen.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr2", kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
con = {gen.a_LocalController{1}, gen.a_LocalController{1}.a_LocalController{1}, ...
       net.a_Bus{2}.a_Component{1}.a_LocalController{1}, net.a_GlobalController{1}};
for k = 1:numel(con)
    err = DebugScript.helper.jacobian_error(con{k});
    assert(err < 1e-6, class(con{k}) + ": Jacobian error " + err)
end


%% Each component type gives same eigenvalues in three algorithms
% 3 母線系統で機器の種類ごとに get_sys を求める (B001: gen-park, B002 または B003: 指定した機器)
for key = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-impedance","load-power"]
    [net3, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net3.initialize);
    sys = net3.get_sys("Algorithm","Kron");
    n_x3 = sum(cellfun(@(b) sum(cellfun(@(cc) numel(cc.sv_x), b.a_Component)), net3.a_Bus));
    assert(size(sys.A,1) == n_x3, key)
    e = eig_finite(sys);
    assert(same_eigs(e, eig_finite(net3.get_sys("Algorithm","Feedback")), 1e-6), key + ": Kron と Feedback の固有値が一致しない")
    assert(same_eigs(e, eig_finite(net3.get_sys("Algorithm","DAE")),      1e-6), key + ": Kron と DAE の固有値が一致しない")
end


%% Local and global controllers in three algorithms
% AVR (ST1, DC1)・PSS・AGC を付けたときも 3 方式の固有値が一致し、IEEE14 は安定
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr2", kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 3 + 3 + 4 + 1)
e = eig_finite(sys);
assert(max(real(e)) < 1e-6)
assert(same_eigs(e, eig_finite(net.get_sys("Algorithm","Feedback")), 1e-6))
assert(same_eigs(e, eig_finite(net.get_sys("Algorithm","DAE")),      1e-6))
sys = net.get_sys("Algorithm","DAE");
assert(numel(sys.StateName) == size(sys.A,1))


%% Non unit choice does not remain on the bus
% NonUnit を指定した後に指定なしで呼ぶと、元の結果に戻る
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
sys1 = net.get_sys("Algorithm","Feedback");
net.get_sys("Algorithm","Feedback","NonUnit",[7,9]);
sys2 = net.get_sys("Algorithm","Feedback");
assert(isequal(size(sys1.A), size(sys2.A)))
assert(same_eigs(eig_finite(sys1), eig_finite(sys2), 1e-9))
