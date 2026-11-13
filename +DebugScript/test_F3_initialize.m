% F3 平衡点の計算とセット (initialize)
%
% net.initialize は潮流計算の結果から各母線・機器・制御器の平衡点を設定する。
%   - 戻り値 [rm_pf, flag, output] (rm_pf: 書き込んだ運転点 n×4 の V, I, P, Q) と Method ("powerflow" / "OPF" / "equilibrium")
%   - 解析が失敗したらエラーにし、系統 (平衡点・古さ) を変えない
%   - 母線電圧・電流、機器ごとの P, Q の配分
%   - 平衡点で各機器の状態微分 ≈ 0、出力電流 = 潮流計算の電流
%   - 外乱なしのシミュレーションで平衡点に留まること (制御器付き・AGC 付きも)
% を確認する。機器の種類ごとのテストは 3 母線系統 (helper.build_3bus) を使う。
%
% 実行: runtests("DebugScript.test_F3_initialize")  または  DebugScript.run_all("Features","F3")

% 共通設定 (各テストの前に毎回実行される)
tol_dx    = 1e-8;      % 平衡点での状態微分の許容値
tol_drift = 1e-6;      % 外乱なしシミュレーションでの状態変化の許容値


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Initialize returns result flag output
% 9 母線系統 (旧 Task3)
net = DebugScript.helper.build_9bus();
[pf, flag, output] = DebugScript.helper.quiet(@() net.initialize());

% rm_pf: 書き込んだ運転点 (n×4 の複素数 V, I, P, Q)、flag: 収束フラグ、output: ソルバー出力 (構造体)
assert(isa(pf, "double") && ~isreal(pf) && isequal(size(pf), [numel(net.a_Bus) 4]))   % complex() なしでも複素数の配列
assert((isnumeric(flag) || islogical(flag)) && isscalar(flag), "flag が " + class(flag) + " で返っている")
assert(flag > 0 && isstruct(output) && isfield(output, "iterations"))
assert(norm(net.cv_Vequilibrium - pf(:,1)) < 1e-8 && norm(net.cv_Iequilibrium - pf(:,2)) < 1e-8)
cv_S = pf(:,1) .* conj(pf(:,2));
assert(norm(real(cv_S) - pf(:,3)) < 1e-12 && norm(imag(cv_S) - pf(:,4)) < 1e-12 && ~any(imag(pf(:,3:4)), "all"))
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(norm(res.tab_bus.Vphasor - pf(:,1)) < 1e-8)

% Method="powerflow" が既定。他の Name-Value は calculate_powerflow へそのまま渡る
[~, flag] = DebugScript.helper.quiet(@() net.initialize(Method="powerflow", Tolerance=1e-10));
assert(flag > 0)
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="powerflow", Tolerance=-1))) == "MATLAB:validators:mustBePositive")
assert(DebugScript.helper.edit_flag(net) == "initialized")


%% Initialize sets bus and component equilibria
net = DebugScript.helper.build_9bus();
tab = DebugScript.helper.quiet(@() net.calculate_powerflow().tab_bus);
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
sol = net.simulate(DebugScript.helper.noop_event(net,[0,5]).s_tag, Time=[0,5]);
assert(sol.odeResults.t(end) == 5)
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% No-event simulation with local controllers stays at equilibrium
% 旧 Task11 の AVR/PSS 構成
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{2}.a_Component{1}.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);

% 制御器の平衡点は有限値
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(all(isfinite([avr.rv_Xequilibrium; avr.rv_Uequilibrium])))

sol = net.simulate(DebugScript.helper.noop_event(net,[0,5]).s_tag, Time=[0,5]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% No-event simulation with global controller stays at equilibrium
% 旧 Task13 の AGC 構成
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);

% AGC の平衡点 (積分器 = 0、入力 = 0)
assert(isequal(agc.rv_Xequilibrium, 0) && isequal(agc.rv_Uequilibrium, [0;0]))

sol = net.simulate(DebugScript.helper.noop_event(net,[0,5]).s_tag, Time=[0,5]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen classical
[net, comp] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,3]).s_tag, Time=[0,3]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen 1axis
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,3]).s_tag, Time=[0,3]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen 2axis
[net, comp] = DebugScript.helper.build_3bus("gen-2axis");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,3]).s_tag, Time=[0,3]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen park
[net, comp] = DebugScript.helper.build_3bus("gen-park");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,3]).s_tag, Time=[0,3]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of gen droop
[net, comp] = DebugScript.helper.build_3bus("gen-droop");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,3]).s_tag, Time=[0,3]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of load impedance
[net, comp] = DebugScript.helper.build_3bus("load-impedance");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,3]).s_tag, Time=[0,3]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Equilibrium of load power
[net, comp] = DebugScript.helper.build_3bus("load-power");
DebugScript.helper.quiet(@() net.initialize);
[r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
assert(r_dx < tol_dx && r_I < tol_dx)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,3]).s_tag, Time=[0,3]);
assert(DebugScript.helper.max_state_drift(sol) < tol_drift)


%% Initialize with OPF
% OPF の解を平衡点にする (常に AC OPF。GUILDA.setting の OptimalPowerFlow の Method によらない)
net = DebugScript.helper.build_ieee14();
c_cfg = DebugScript.helper.user_config("OptimalPowerFlow", struct("Method", "DC OPF"));
[pf, flag] = DebugScript.helper.quiet(@() net.initialize(Method="OPF", Verbose=false));
assert(double(flag) > 0 && isequal(size(pf), [numel(net.a_Bus) 4]))
assert(norm(net.cv_Vequilibrium - pf(:,1)) < 1e-8)
% 運転点は AC OPF の解 (DC OPF なら電圧の大きさは 1)
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Verbose=false));
assert(res.l_success && GUILDA.config("OptimalPowerFlow", "Method") == "DC OPF")
assert(norm(res.tab_bus.Vphasor - pf(:,1)) < 1e-6 && any(abs(abs(pf(:,1)) - 1) > 1e-3))
clear c_cfg
assert(DebugScript.helper.edit_flag(net) == "initialized")


%% Initialize from Xequilibrium
% 一度 initialize した後、保持している平衡点から再設定する
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
V_before = net.cv_Vequilibrium;
[pf, flag, output] = DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
assert(~isfield(output, "iterations"))            % 解いていない
assert(isscalar(flag) && flag > 0)
assert(isequal(size(pf), [numel(net.a_Bus) 4]) && norm(pf(:,1) - V_before) < 1e-8)
assert(norm(net.cv_Vequilibrium - V_before) < 1e-8)


%% Initialize from Xequilibrium solves buses without components
% 9 母線系統の B004, B007, B009 は機器が無い (注入電流 0) → 電圧は Y*V = I から求める
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
V_before = net.cv_Vequilibrium;
I_before = net.cv_Iequilibrium;
X_before = cellfun(@(b) b.a_Component{1}.rv_Xequilibrium, net.a_Bus([1,2,3,5,6,8]), "UniformOutput", false);
[pf, flag, output] = DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
assert(isscalar(flag) && flag > 0, output.message)
assert(isequal(size(pf), [numel(net.a_Bus) 4]))
assert(norm(net.cv_Vequilibrium - V_before) < 1e-8)
assert(norm(net.cv_Iequilibrium - I_before) < 1e-8)
assert(norm(pf(:,1) - V_before) < 1e-8 && norm(pf(:,2) - I_before) < 1e-8)
% 機器の平衡点は変わらない
X_after = cellfun(@(b) b.a_Component{1}.rv_Xequilibrium, net.a_Bus([1,2,3,5,6,8]), "UniformOutput", false);
for k = 1:numel(X_after)
    assert(norm(X_after{k} - X_before{k}) < 1e-8)
end


%% Initialize from Xequilibrium requires stored equilibria
% 潮流を一度も解いていない系統 (powerflow が初期メッセージのまま) はエラー
net = DebugScript.helper.build_9bus();
try
    DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
    error("DebugScript:noError", "エラーにならなかった")
catch ME
    assert(string(DebugScript.helper.msg_id(ME)) == "GUILDA:PowerNetwork:InitializeEquilibriumEdited", string(DebugScript.helper.msg_id(ME)))
    assert(contains(ME.message, net.s_notInitialized))
end
assert(DebugScript.helper.edit_flag(net) == "unset")


%% Failed OPF errors and leaves the network unchanged
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{1}.a_Component{1}.tab_parameter.operation.Pmax = 1;    % 平衡点を古くしない編集
[V0, I0, X0, log0, flag0] = snapshot(net);

% MaxIteration=2 では AC OPF は解けない
ME = error_of(@() net.initialize(Method="OPF", MaxIteration=2));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:InitializeOPFFailed", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "Relax the constraints") && contains(ME.message, 'Method="powerflow"'))
assert_unchanged(net, V0, I0, X0, log0, flag0)

% 発電機の出力上限で負荷をまかなえない (実行不能)
for i = [1,2,3]
    net.a_Bus{i}.a_Component{1}.tab_parameter.operation.Pmax = 0.01;
end
[V0, I0, X0, log0, flag0] = snapshot(net);
ME = error_of(@() net.initialize(Method="OPF"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:InitializeOPFFailed", DebugScript.helper.msg_id(ME))
assert_unchanged(net, V0, I0, X0, log0, flag0)


%% Failed powerflow errors and leaves the network unchanged
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
[V0, I0, X0, log0, flag0] = snapshot(net);
ME = error_of(@() net.initialize(Method="powerflow", MaxIteration=1, Tolerance=1e-14, WarmStart=false));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:InitializePowerflowFailed", DebugScript.helper.msg_id(ME))
assert_unchanged(net, V0, I0, X0, log0, flag0)


%% Initialize rejects unknown options
net = DebugScript.helper.build_9bus();
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="algebraic"))) == "GUILDA:PowerNetwork:InitializeMethod")
% v3 の値とオプション methods は受け付けない
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="calculate from Xequilibrium"))) == "GUILDA:PowerNetwork:InitializeMethod")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize("methods", "powerflow calculation"))) == "MATLAB:TooManyInputs")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="powerflow", Foo=1))) ~= "")     % arguments ブロックのエラー
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="OPF", Foo=1))) == "MATLAB:TooManyInputs")    % calculate_optimal_powerflow の arguments ブロック
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="equilibrium", Foo=1))) == "GUILDA:PowerNetwork:InitializeEquilibriumOption")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize("Method"))) == "GUILDA:PowerNetwork:InitializePairs")
% Format は initialize のオプションではない (どの Method でも、calculate_powerflow へ渡さない)
for s_method = ["powerflow","OPF","FixedInput","equilibrium"]
    assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method=s_method, Format="V"))) == "GUILDA:PowerNetwork:InitializeFormat")
end
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(format="GUILDAorigin"))) == "GUILDA:PowerNetwork:InitializeFormat")
assert(DebugScript.helper.edit_flag(net) == "unset")


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
Hz   = comp.get_Hz();
dx_used = comp.f_dx(0, x, [real(V);imag(V)], comp.rv_Uequilibrium);
dx_new  = comp.fcn_dx(0, x, [real(V);imag(V)], comp.rv_Uequilibrium, para, Hz);
assert(norm(dx_used - dx_new) < 1e-12, "f_dx が変更前の定数 D を使っている")


%% Equilibrium voltage and current have a single owner
% 母線が V を、機器が I を持つ。機器・制御器の V と母線の I は持ち主から読む (Dependent)
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
assert(findprop(net.a_Bus{1}, "c_Iequilibrium").Dependent && ~findprop(net.a_Bus{1}, "c_Vequilibrium").Dependent)
assert(findprop(net.a_Bus{1}.a_Component{1}, "c_Vequilibrium").Dependent)

% 平衡点を計算し直して母線の V が変わると、機器・制御器もその値を返す
bus  = net.a_Bus{1};
comp = bus.a_Component{1};
avr  = comp.a_LocalController{1};
pss  = avr.a_LocalController{1};
V_before = bus.c_Vequilibrium;
bus.tab_parameter.powerflow.V = 1.03;
DebugScript.helper.quiet(@() net.initialize);
assert(abs(abs(bus.c_Vequilibrium) - 1.03) < 1e-8 && abs(bus.c_Vequilibrium - V_before) > 1e-3)
assert(comp.c_Vequilibrium == bus.c_Vequilibrium)
assert(avr.c_Vequilibrium == bus.c_Vequilibrium && pss.c_Vequilibrium == bus.c_Vequilibrium)
assert(avr.c_Iequilibrium == comp.c_Iequilibrium)

% 母線の電流 = 接続機器の電流の和 (機器が無い母線は 0)
for i = 1:numel(net.a_Bus)
    b = net.a_Bus{i};
    I_comp = sum(cellfun(@(c) c.c_Iequilibrium, b.a_Component));
    assert(b.c_Iequilibrium == I_comp, string(b))
end
net9 = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net9.initialize);
assert(isempty(net9.a_Bus{4}.a_Component) && net9.a_Bus{4}.c_Iequilibrium == 0)


%% FixedInput with the held inputs keeps the equilibrium
% 入力を変えなければ同じ平衡点 (スラック母線の位相 0) を反復 0 回で返す
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
V0 = net.cv_Vequilibrium;
c_X0 = component_values(net, "rv_Xequilibrium");
[pf, flag, output] = DebugScript.helper.quiet(@() net.initialize(Method="FixedInput"));
assert(flag == 1 && output.iterations == 0 && output.residual < 1e-8, output.message)
assert(isequal(size(pf), [numel(net.a_Bus) 4]) && max(abs(pf(:,1) - V0)) < 1e-10)
assert(abs(angle(V0(1))) < 1e-12 && max(abs(net.cv_Vequilibrium - V0)) < 1e-10)
assert(max(abs(vertcat(c_X0{:}) - cell2mat(component_values(net, "rv_Xequilibrium")))) < 1e-10)
assert(isempty(net.sct_stale.powerflow) && isempty(net.sct_stale.input))


%% set_input makes the inputs stale until FixedInput
% 入力の編集は記録され、解析と Method なしの initialize は FixedInput を促して止まる
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
ld = net.a_Bus{5}.a_Component{1};
u0 = ld.rv_Uequilibrium;
ld.set_input(u0);                                   % 同じ値は記録しない
assert(isempty(net.sct_stale.input) && isempty(ld.sct_stale.equilibrium))
ld.set_input(u0/0.95);
assert(numel(net.sct_stale.input) == 1 && contains(net.sct_stale.input, "rv_Uequilibrium"))
assert(numel(ld.sct_stale.equilibrium) == 1 && isempty(ld.sct_stale.odefcn))
assert(isempty(net.sct_stale.powerflow) && isequal(ld.rv_Uequilibrium, u0/0.95))
assert(DebugScript.helper.msg_id(error_of(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0 1]))) == "GUILDA:PowerNetwork:SimulateInputEdited")
assert(DebugScript.helper.msg_id(error_of(@() net.get_sys())) == "GUILDA:PowerSystemModel:InputEdited")
assert(DebugScript.helper.msg_id(error_of(@() ld.get_sys())) == "GUILDA:PowerSystemModel:InputEdited")
assert(DebugScript.helper.msg_id(error_of(@() net.a_Bus{5}.get_sys())) == "GUILDA:PowerSystemModel:InputEdited")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize())) == "GUILDA:PowerNetwork:InputEdited")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="equilibrium"))) == "GUILDA:PowerNetwork:InputEdited")
assert(isequal(ld.rv_Uequilibrium, u0/0.95))
% 値の検査: 要素数、実数・有限
assert(DebugScript.helper.msg_id(error_of(@() ld.set_input([1; 2; 3]))) == "GUILDA:Component:InputSize")
assert(DebugScript.helper.msg_id(error_of(@() ld.set_input([NaN; 1]))) == "MATLAB:validators:mustBeFinite")
assert(DebugScript.helper.msg_id(error_of(@() ld.set_input([1i; 1]))) == "MATLAB:validators:mustBeReal")
assert(numel(net.sct_stale.input) == 1)


%% FixedInput solves the equilibrium with the edited inputs
% 負荷を 5 % 減らし (Z / 0.95)、発電機の入力を保ったまま平衡点を解く。スラック母線の Pm だけが変わる
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
c_U0 = component_values(net, "rv_Uequilibrium");
for i_bus = [5 6 8]
    ld = net.a_Bus{i_bus}.a_Component{1};
    ld.set_input(ld.rv_Uequilibrium/0.95);
end
c_Uset = component_values(net, "rv_Uequilibrium");
[pf, flag, output] = DebugScript.helper.quiet(@() net.initialize(Method="FixedInput"));
assert(flag == 1 && output.iterations > 0 && output.iterations <= 10, string(output.iterations))
c_U = component_values(net, "rv_Uequilibrium");
gen1 = net.a_Bus{1}.a_Component{1};
assert(isequal(c_U(2:end), c_Uset(2:end)) && c_U{1}(2) == c_Uset{1}(2))      % スラック発電機の Vfield も固定
assert(c_U{1}(1) < c_U0{1}(1) - 0.1)                                          % 負荷が減って Pm が下がる
assert(abs(angle(net.a_Bus{1}.c_Vequilibrium)) < 1e-12)
assert(max(abs(pf(:,1) - net.cv_Vequilibrium)) < 1e-12 && max(abs(pf(:,2) - net.cv_Iequilibrium)) < 1e-12)
assert(isempty(net.sct_stale.input) && isempty(net.sct_stale.powerflow) && isempty(gen1.sct_stale.equilibrium))
assert(DebugScript.helper.max_state_drift(DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0 5]))) < 1e-6)


%% FixedInput gives the same point with every solver
% 他の Solver とフラットスタートの初期値も同じ点
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
for i_bus = [5 6 8]
    ld = net.a_Bus{i_bus}.a_Component{1};
    ld.set_input(ld.rv_Uequilibrium/0.95);
end
DebugScript.helper.quiet(@() net.initialize(Method="FixedInput"));
V1 = net.cv_Vequilibrium;
% fsolve は Tolerance^2 を FunctionTolerance と OptimalityTolerance に使うので、既定の 1e-8 や 1e-10 でも止まらない
for c = {{"Solver", "levenberg-marquardt"}, {"Solver", "fsolve"}, {"Solver", "fsolve", "Tolerance", 1e-10}, {"WarmStart", false}}
    net2 = network.IEEE9bus();
    DebugScript.helper.quiet(@() net2.initialize);
    for i_bus = [5 6 8]
        ld = net2.a_Bus{i_bus}.a_Component{1};
        ld.set_input(ld.rv_Uequilibrium/0.95);
    end
    [~, flag2] = DebugScript.helper.quiet(@() net2.initialize("Method", "FixedInput", c{1}{:}));
    assert(flag2 == 1 && max(abs(net2.cv_Vequilibrium - V1)) < 1e-5, c{1}{1})
end


%% FixedInput keeps the inputs under local controllers
% 制御器は方程式に入らず、平衡点の後で参照値を合わせる (外乱なしで動かない)
net = network.IEEE9bus();
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
gen2 = net.a_Bus{2}.a_Component{1};
u = gen2.rv_Uequilibrium;
gen2.set_input([u(1) - 0.05; u(2)]);
[~, flag] = DebugScript.helper.quiet(@() net.initialize(Method="FixedInput"));
assert(flag == 1 && isequal(gen2.rv_Uequilibrium, [u(1) - 0.05; u(2)]))
assert(DebugScript.helper.max_state_drift(DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0 5]))) < 1e-6)


%% Powerflow replaces the edited inputs
% 明示の Method="powerflow" は編集した入力を潮流解の値で上書きし、INFO で知らせる
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
ld = net.a_Bus{5}.a_Component{1};
u0 = ld.rv_Uequilibrium;
ld.set_input(u0/0.95);
s_log = evalc("net.initialize(Method=""powerflow"");");
assert(contains(s_log, "replaced the inputs edited with set_input"), s_log)
assert(max(abs(ld.rv_Uequilibrium - u0)) < 1e-8 && isempty(net.sct_stale.input))


%% FixedInput errors leave the network unchanged
% 収束しない (AVR なしで負荷 +5 %)、Solver の誤り、スラック母線に発電機がない、入力のない機器
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
for i_bus = [5 6 8]
    ld = net.a_Bus{i_bus}.a_Component{1};
    ld.set_input(ld.rv_Uequilibrium/1.05);
end
[V0, I0, X0, log0, flag0] = snapshot(net);
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="FixedInput"))) == "GUILDA:PowerNetwork:InitializeFixedInputFailed")
assert_unchanged(net, V0, I0, X0, log0, flag0)
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="FixedInput", Solver="gradient"))) == "GUILDA:PowerNetwork:InitializeFixedInputSolver")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="FixedInput", Solver="foo"))) == "MATLAB:validators:mustBeMember")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="FixedInput", Foo=1))) == "GUILDA:resolve_options:UnknownName")
assert_unchanged(net, V0, I0, X0, log0, flag0)

net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
DebugScript.helper.quiet(@() set_slack(net.a_Bus{5}));                         % 負荷だけの母線
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="FixedInput"))) == "GUILDA:PowerNetwork:InitializeNoSlackGenerator")

net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
DebugScript.helper.quiet(@() net.a_Bus{4}.add_component("load-impedance", P=-0.1, Q=0));
assert(DebugScript.helper.msg_id(error_of(@() net.initialize(Method="FixedInput"))) == "GUILDA:PowerNetwork:InitializeInputNotSet")


% ---- local functions ----
function c = component_values(net, s_prop)
% s_prop of every component, bus by bus
    c = {};
    for i = 1:numel(net.a_Bus)
        for k = 1:numel(net.a_Bus{i}.a_Component)
            c{end+1,1} = net.a_Bus{i}.a_Component{k}.(s_prop); %#ok<AGROW>
        end
    end
end

function set_slack(bus)
    bus.l_isSlack = true;
end

function [V, I, X, tab_log, s_flag] = snapshot(net)
% 平衡点 (母線の V, I と機器の状態) と古さ
    V = net.cv_Vequilibrium;
    I = net.cv_Iequilibrium;
    X = cellfun(@(b) cellfun(@(c) c.rv_Xequilibrium, b.a_Component, "UniformOutput", false), ...
                net.a_Bus, "UniformOutput", false);
    tab_log  = DebugScript.helper.stale(net);
    s_flag   = DebugScript.helper.edit_flag(net);
end

function assert_unchanged(net, V0, I0, X0, log0, flag0)
    [V, I, X, tab_log, s_flag] = snapshot(net);
    assert(isequal(V, V0) && isequal(I, I0) && isequal(X, X0), "平衡点が変わった")
    assert(isequal(tab_log, log0) && s_flag == flag0, "古さが変わった")
end

function ME = error_of(fcn)
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
    assert(~isempty(ME), "エラーにならなかった")
end
