% F3 平衡点の計算とセット (initialize)
%
% net.initialize は潮流計算の結果から各母線・機器・制御器の平衡点を設定する。
%   - 戻り値 [flag, tab, output] と "methods" オプション
%   - 母線電圧・電流、機器ごとの P, Q の配分
%   - 平衡点で各機器の状態微分 ≈ 0、出力電流 = 潮流計算の電流
%   - 外乱なしのシミュレーションで平衡点に留まること (制御器付き・AGC 付きも)
% を確認する。機器の種類ごとのテストは 3 母線系統 (helper.build_3bus) を使う。
%
% 実行: runtests("DebugScript.test_F3_initialize")  または  DebugScript.run_all("Features","F3")

% 共通設定 (各テストの前に毎回実行される)
tol_dx    = 1e-8;      % 平衡点での状態微分の許容値
tol_drift = 1e-6;      % 外乱なしシミュレーションでの状態変化の許容値


%% Initialize returns flag table output
% 9 母線系統 (旧 Task3)
net = DebugScript.helper.build_9bus();
[flag, tab, output] = DebugScript.helper.quiet(@() net.initialize);

% flag: 収束フラグ (数値/論理のスカラー)、tab: 潮流計算結果、output: ソルバー出力 (構造体)
assert((isnumeric(flag) || islogical(flag)) && isscalar(flag), "flag が " + class(flag) + " で返っている")
assert(flag > 0)
assert(istable(tab) && height(tab) == numel(net.a_Bus))
assert(isstruct(output))


%% Initialize sets bus and component equilibria
net = DebugScript.helper.build_9bus();
tab = DebugScript.helper.quiet(@() net.calculate_powerflow);
DebugScript.helper.quiet(@() net.initialize);

% 母線の平衡点 = 潮流計算の解
assert(norm(net.cv_Vequilibrium - tab.Vphasor) < 1e-8)
assert(norm(net.cv_Iequilibrium - tab.Iphasor) < 1e-8)

% 各母線で、接続機器の電流の合計 = 母線の注入電流
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    I_comp = 0;
    for j = 1:numel(bus.a_Component)
        I_comp = I_comp + bus.a_Component{j}.c_Iequilibrium;
    end
    assert(abs(I_comp - bus.c_Iequilibrium) < 1e-8, string(bus))
end

% PV/PQ の機器は指定した P (負荷は Q も) で運転する
comp_P = @(c) real(c.c_Vequilibrium * conj(c.c_Iequilibrium));
comp_Q = @(c) imag(c.c_Vequilibrium * conj(c.c_Iequilibrium));
assert(abs(comp_P(net.a_Bus{2}.a_Component{1}) - 1.0) < 1e-8)
assert(abs(comp_P(net.a_Bus{5}.a_Component{1}) + 1.0) < 1e-8 && abs(comp_Q(net.a_Bus{5}.a_Component{1}) + 0.1) < 1e-8)

% スラック母線の発電機が残りの電力 (負荷 + 損失 - 他の発電) を受け持つ
assert(abs(comp_P(net.a_Bus{1}.a_Component{1}) - tab{"B001","P"}) < 1e-8)

% 状態・入力の平衡点のサイズは sv_x, sv_u と一致
for i = 1:numel(net.a_Bus)
    for j = 1:numel(net.a_Bus{i}.a_Component)
        c = net.a_Bus{i}.a_Component{j};
        assert(numel(c.rv_Xequilibrium) == numel(c.sv_x) && numel(c.rv_Uequilibrium) == numel(c.sv_u), string(c))
    end
end


%% Equilibrium of IEEE14 components
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);

% すべての機器で、平衡点の状態微分 ≈ 0、出力電流 = 潮流計算の電流
for i = 1:numel(net.a_Bus)
    for j = 1:numel(net.a_Bus{i}.a_Component)
        comp = net.a_Bus{i}.a_Component{j};
        [r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
        assert(r_dx < tol_dx, string(comp) + ": |dx| = " + r_dx)
        assert(r_I  < tol_dx, string(comp) + ": |I - I*| = " + r_I)
    end
end


%% No-event simulation stays at equilibrium
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);

% 外乱なしで 5 秒間シミュレーション → 状態は平衡点から動かない
sol = net.simulate([0,5], DebugScript.helper.noop_event(net,[0,5]));
assert(sol.odeResults.t(end) == 5)
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% No-event simulation with local controllers stays at equilibrium
% 旧 Task11 の AVR/PSS 構成
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr2"), controller.pss.PSS1("pss2"));
DebugScript.helper.quiet(@() net.initialize);

% 制御器の平衡点は有限値
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(all(isfinite([avr.rv_Xequilibrium; avr.rv_Uequilibrium])))

sol = net.simulate([0,5], DebugScript.helper.noop_event(net,[0,5]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% No-event simulation with global controller stays at equilibrium
% 旧 Task13 の AGC 構成
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);

% AGC の平衡点 (積分器 = 0、入力 = 0)
assert(isequal(agc.rv_Xequilibrium, 0) && isequal(agc.rv_Uequilibrium, [0;0]))

sol = net.simulate([0,5], DebugScript.helper.noop_event(net,[0,5]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen classical
[net, comp] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate([0,3], DebugScript.helper.noop_event(net,[0,3]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen 1axis
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate([0,3], DebugScript.helper.noop_event(net,[0,3]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen 2axis
[net, comp] = DebugScript.helper.build_3bus("gen-2axis");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate([0,3], DebugScript.helper.noop_event(net,[0,3]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen park
[net, comp] = DebugScript.helper.build_3bus("gen-park");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate([0,3], DebugScript.helper.noop_event(net,[0,3]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen droop
[net, comp] = DebugScript.helper.build_3bus("gen-droop");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate([0,3], DebugScript.helper.noop_event(net,[0,3]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of load impedance
[net, comp] = DebugScript.helper.build_3bus("load-impedance");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate([0,3], DebugScript.helper.noop_event(net,[0,3]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of load power
[net, comp] = DebugScript.helper.build_3bus("load-power");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate([0,3], DebugScript.helper.noop_event(net,[0,3]));
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Initialize with optimal powerflow
% OPF の解を平衡点にする (F4 の AC OPF を使う)
net = DebugScript.helper.build_ieee14();
[flag, tab] = DebugScript.helper.quiet(@() net.initialize("methods","optimal powerflow"));
assert(isscalar(flag) && flag > 0)
assert(istable(tab) && height(tab) == numel(net.a_Bus))


%% Initialize from Xequilibrium
% 一度 initialize した後、保持している平衡点から再設定する
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
V_before = net.cv_Vequilibrium;
[flag, tab] = DebugScript.helper.quiet(@() net.initialize("methods","calculate from Xequilibrium"));
assert(isscalar(flag) && flag > 0)
assert(istable(tab))
assert(norm(net.cv_Vequilibrium - V_before) < 1e-8)


%% Dynamics parameter edit is used after initialize
% tab_parameter で発電機定数を変えたら、シミュレーションの式 (f_dx) にも反映されるべき
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.tab_parameter.dynamics.D = 50;
DebugScript.helper.quiet(@() net.initialize);

% omega をずらした点で、保持している f_dx と新しい定数で計算した式を比べる
V = comp.c_Vequilibrium;  I = comp.c_Iequilibrium;
x = comp.rv_Xequilibrium;  x(comp.sv_x == "omega") = 0.01;
para = comp.tab_parameter.dynamics{:, comp.sv_para};
Hz   = comp.tab_parameter.base.Hz;
dx_used = comp.f_dx(0, x, [real(V);imag(V)], [real(I);imag(I)], comp.rv_Uequilibrium);
dx_new  = comp.fcn_dx(0, x, [real(V);imag(V)], [real(I);imag(I)], comp.rv_Uequilibrium, para, Hz);
assert(norm(dx_used - dx_new) < 1e-12, "f_dx が変更前の定数 D を使っている")
