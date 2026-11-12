% F3 編集後の解析 (編集の扱い)
%
% 編集は値を変え、その編集で古くなるものを各層の sct_stale にメッセージとして記録する。
%   機器・制御器の dynamics の編集 → その機器・制御器の equilibrium と odefcn
%   ローカル制御器の追加・置き換え・削除 → 機器の equilibrium
%   base(baseMVA)、母線・送電線の編集、機器の powerflow、構成の変更 (母線・送電線・機器)、
%   スラック母線の変更 → 系統の powerflow
%   base(Hz) の編集 → 系統の odefcn (機器・制御器には届かず、initialize でハンドルを作った Hz と比べる)
%   operation / OPF / graph の編集、タグの変更 → 何も古くならない
% 最新にするのは net.initialize() だけ。潮流が古いときだけ潮流計算をし、古い関数ハンドル f_* と
% 平衡点だけを作り直す。simulate / get_sys / linearize は確認するだけで、古いものがあれば
% net.initialize() を促す解析ごとのエラー (GUILDA:SolverODE:Stale、SolverLIN:Stale、
% Component:Stale など) にする。
% ハンドルは f_dx (未作成は空、作り直したかは以前のハンドルとの isequal) で、古さは
% sct_stale と DebugScript.helper.stale / is_stale で確認する。
%
% 実行: runtests("DebugScript.test_F3_edit_handling")  または  DebugScript.run_all("Features","F3")

% 共通設定 (各テストの前に毎回実行される)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Simulate and get_sys before initialize ask for initialize
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), "GUILDA:SolverODE:Stale")
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert(DebugScript.helper.edit_flag(net) == "unset")


%% Solvers called directly check the equilibrium
% net.solver_ODE.solve / net.solver_LIN.solve も simulate / linearize と同じ確認をする
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
assert_stale_error(@() net.solver_ODE.solve(net, [0,1]), "GUILDA:SolverODE:Stale")
assert_stale_error(@() net.solver_LIN.solve(net), "GUILDA:SolverLIN:Stale")

DebugScript.helper.quiet(@() net.initialize);
comp.tab_parameter.dynamics.D = 5;
assert_stale_error(@() net.solver_ODE.solve(net, [0,1]), "GUILDA:SolverODE:Stale")
assert_stale_error(@() net.solver_LIN.solve(net), "GUILDA:SolverLIN:Stale")

DebugScript.helper.quiet(@() net.initialize);
sol = DebugScript.helper.quiet(@() net.solver_ODE.solve(net, [0,1]));
assert(sol.odeResults.t(end) == 1)
res = DebugScript.helper.quiet(@() net.solver_LIN.solve(net));
assert(isa(res, "ResultLIN"))


%% Dynamics edit makes handles and equilibrium stale
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
assert(~isempty(comp.f_dx) && ~DebugScript.helper.is_stale(net))
h_dx = comp.f_dx;
D0 = comp.tab_parameter.dynamics.D;

comp.tab_parameter.dynamics.D = 5;
s_msg = "dynamics/" + comp.s_tag + ": edit D: " + tools.value_text(D0) + " -> 5";
assert(isequal(comp.sct_stale.equilibrium, s_msg) && isequal(comp.sct_stale.odefcn, s_msg))
assert(isempty(net.sct_stale.powerflow))                 % 潮流は古くならない
assert(isequal(h_dx, comp.f_dx) && DebugScript.helper.is_stale(net))   % 編集しただけでは作り直さない
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), "GUILDA:SolverODE:Stale")
ME = error_of(@() net.get_sys());
assert(contains(ME.message, s_msg), "エラーが理由を示さない: " + ME.message)
assert(isequal(h_dx, comp.f_dx))                         % 解析は作り直さない

% initialize は潮流計算をせず、保持している V, I から平衡点とハンドルを作り直す
V0 = net.cv_Vequilibrium;
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver == "equilibrium" && isequal(net.cv_Vequilibrium, V0))
assert(~isequal(h_dx, comp.f_dx) && ~DebugScript.helper.is_stale(net))
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
net.get_sys();


%% Base Hz edit marks the handles and initialize rebuilds them
% 周波数は PowerNetwork が持つ (net.tab_parameter.base.Hz)。編集はどの層にも記録されず、
% 各機器はハンドルを作った Hz と比べて古いと判断する。initialize は潮流計算をせずハンドルだけ作り直す
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
x_eq = comp.rv_Xequilibrium;
Hz0  = net.tab_parameter.base.Hz;
net.tab_parameter.base.Hz = 50;
assert(isempty(net.sct_stale.powerflow) && isempty(comp.sct_stale.odefcn) && isempty(comp.sct_stale.equilibrium))
assert(net.sct_stale.odefcn == "base/" + net.s_tag + ": edit Hz: " + Hz0 + " -> 50", "Hz の編集は系統の odefcn に入る")
assert(DebugScript.helper.is_stale(net) && comp.get_Hz() == 50)
assert(DebugScript.helper.handle_Hz(comp) == Hz0, "編集しただけでは作り直さない")
ME = error_of(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:Stale" && contains(ME.message, "edit Hz"))

% initialize はハンドルだけを作り直し、平衡点は変わらない
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver == "equilibrium" && isequal(comp.rv_Xequilibrium, x_eq))
assert(DebugScript.helper.handle_Hz(comp) == 50 && ~DebugScript.helper.is_stale(net))
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)
x = comp.rv_Xequilibrium;  x(comp.sv_x == "omega") = 0.01;
V = comp.c_Vequilibrium;  I = comp.c_Iequilibrium;
para = comp.tab_parameter.dynamics{:, comp.sv_para};
dx_used = comp.f_dx(0, x, [real(V);imag(V)], comp.rv_Uequilibrium);
dx_new  = comp.fcn_dx(0, x, [real(V);imag(V)], comp.rv_Uequilibrium, para, 50);
assert(norm(dx_used - dx_new) < 1e-12, "f_dx が変更前の Hz を使っている")


%% Base baseMVA edit makes the power flow stale
% baseMVA を変えると単位法の値が変わるので、潮流が古くなる
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
f_dx = comp.f_dx;
net.tab_parameter.base.baseMVA = 200;
assert(isequal(net.sct_stale.powerflow, "base/" + net.s_tag + ": edit baseMVA: 100 -> 200"))
assert(isequal(comp.f_dx, f_dx))
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), "GUILDA:SolverODE:Stale")
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver ~= "equilibrium" && ~DebugScript.helper.is_stale(net))


%% Powerflow edit makes the power flow stale
[net, comp] = DebugScript.helper.build_3bus("load-power");
DebugScript.helper.quiet(@() net.initialize);

comp.tab_parameter.powerflow.P = -1.1;
assert(numel(net.sct_stale.powerflow) == 1 && contains(net.sct_stale.powerflow, "powerflow/" + comp.s_tag))
assert(isempty(comp.sct_stale.equilibrium))
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")

% 潮流設定の母線パラメータも同じ
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{2}.tab_parameter.powerflow.V = 1.01;
assert(contains(net.sct_stale.powerflow, "powerflow/B002: "))
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver ~= "equilibrium" && ~DebugScript.helper.is_stale(net))


%% Bus and branch dynamics edits make the power flow stale
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
net.a_Branch{4}.tab_parameter.dynamics.X = 0.09;
assert(contains(net.sct_stale.powerflow, "edit X: "))

DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{5}.tab_parameter.dynamics.Bshunt = 0.1;
assert(contains(net.sct_stale.powerflow, "edit Bshunt: "))


%% Topology changes make the power flow stale
% 機器の追加
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.add_component("load-impedance", "P", -0.1, "Q", 0);
assert(any(contains(net.sct_stale.powerflow, "<<-connect---")))
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")

% 機器の削除
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.remove_component(string(net.a_Bus{3}.a_Component{2}));
assert(any(contains(net.sct_stale.powerflow, "---remove->>")))

% 機器の置き換え
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.replace_component(string(net.a_Bus{3}.a_Component{1}), "load-impedance");
assert(any(contains(net.sct_stale.powerflow, "replace")))
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), "GUILDA:SolverODE:Stale")

% 送電線の追加・削除
DebugScript.helper.quiet(@() net.initialize);
net.add_branch("pi", [1,3], "R",0.02, "X",0.1);
assert(DebugScript.helper.is_stale(net) && ~isempty(net.sct_stale.powerflow))
DebugScript.helper.quiet(@() net.initialize);
net.remove_branch(string(net.a_Branch{3}));
assert(any(contains(net.sct_stale.powerflow, "remove")))

% 母線の追加
DebugScript.helper.quiet(@() net.initialize);
net.add_bus();
assert(~isempty(net.sct_stale.powerflow))


%% Local controller add and replace make the equilibrium stale
% AVR / PSS の追加・置き換えは機器の構成の変更 (Topology) で、機器の equilibrium だけが古くなる
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
avr1 = comp.add_local_controller("avr-ST1");
assert(any(contains(comp.sct_stale.equilibrium, avr1.s_tag)) && isempty(net.sct_stale.powerflow))
assert(avr1.sct_stale.odefcn(1) == avr1.s_notInitialized)   % 新しい制御器は未初期化
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), "GUILDA:SolverODE:Stale")
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver == "equilibrium" && ~DebugScript.helper.is_stale(net))   % 潮流計算はしない
assert(~isempty(avr1.f_dx) && ~isempty(avr1.rv_Xequilibrium))

% PSS の追加
pss1 = comp.add_local_controller("pss-PSS1");
assert(any(contains(comp.sct_stale.equilibrium, pss1.s_tag)))

% AVR の置き換え (警告が出る)
DebugScript.helper.quiet(@() net.initialize);
assert(warn_id(@() comp.add_local_controller("avr-DC1")) == "GUILDA:Component:ReplaceController")
assert(any(contains(comp.sct_stale.equilibrium, "replace")))
DebugScript.helper.quiet(@() net.initialize);
assert(~DebugScript.helper.is_stale(net))

% 系統に属さない機器への追加は系統を古くしない
net.a_Bus{1}.remove_component(string(comp));
evalc("net.a_Bus{2}.l_isSlack = true;");     % スラック母線に機器がないと平衡点にならない
DebugScript.helper.quiet(@() net.initialize);
comp.add_local_controller("avr-ST1");
assert(~DebugScript.helper.is_stale(net))


%% LQR add and weight edit make the equilibrium stale
% LQR の追加は機器の構成の変更、重み Q / R の変更は LQR の equilibrium と odefcn を古くする
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
lqr = comp.add_local_controller("local-LQR");
assert(any(contains(comp.sct_stale.equilibrium, lqr.s_tag)))

DebugScript.helper.quiet(@() net.initialize);
K1 = lqr.K;
lqr.Q = 10*ones(1, numel(comp.sv_x));
assert(numel(lqr.sct_stale.equilibrium) == 1 && contains(lqr.sct_stale.equilibrium, "edit Q: "))
assert(isequal(lqr.sct_stale.odefcn, lqr.sct_stale.equilibrium) && isempty(comp.sct_stale.equilibrium))
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")

% initialize でゲインが計算し直される (潮流計算はしない)
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver == "equilibrium")
assert(~DebugScript.helper.is_stale(net) && norm(lqr.K - K1) > 1e-6)


%% Slack bus change makes the power flow stale
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
evalc("net.a_Bus{2}.l_isSlack = true;");     % 表示 (INFO) は抑制
assert(any(contains(net.sct_stale.powerflow, "slack bus")))
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")


%% Operation OPF and graph edits keep the equilibrium
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);

comp.tab_parameter.operation.Pmax = 2;
comp.tab_parameter.OPF.HP = 3;
comp.tab_parameter.graph.Marker = "s";
net.a_Bus{2}.tab_parameter.operation.Vmax = 1.2;
net.a_Bus{2}.tab_parameter.graph.Xaxis = 1;

% 何も古くならない
assert(DebugScript.helper.edit_flag(net) == "initialized" && isempty(DebugScript.helper.stale(net)))

% initialize し直さなくても解析できる
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
net.get_sys();


%% Initialize rebuilds only the stale handles
net = DebugScript.helper.build_ieee14();
c1  = net.a_Bus{1}.a_Component{1};
c2  = net.a_Bus{2}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
h1 = c1.f_dx;  h2 = c2.f_dx;
x2 = c2.rv_Xequilibrium;

c1.tab_parameter.dynamics.D = 50;
assert(isequal(h1, c1.f_dx))           % 編集しただけでは作り直さない

DebugScript.helper.quiet(@() net.initialize);
assert(~isequal(h1, c1.f_dx))          % 編集した機器だけ作り直す
assert(isequal(h2, c2.f_dx) && isequal(x2, c2.rv_Xequilibrium))
para = c1.tab_parameter.dynamics{:, c1.sv_para};
assert(para(c1.sv_para == "D") == 50 && isequal(handle_para(c1), para))

% 何も古くないときの initialize は何も変えない
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(h2, c2.f_dx))
h1 = c1.f_dx;
net.get_sys();  net.linearize();
assert(isequal(h1, c1.f_dx))           % 解析は作り直さない


%% Local controller dynamics edit is rebuilt at initialize
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller("avr-ST1");
avr = comp.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);
h_dx = avr.f_dx;

avr.tab_parameter.dynamics.kap = 2 * avr.tab_parameter.dynamics.kap;
assert(isequal(h_dx, avr.f_dx) && DebugScript.helper.is_stale(net))
assert(contains(avr.sct_stale.odefcn, "edit kap: ") && isempty(comp.sct_stale.equilibrium))
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")

DebugScript.helper.quiet(@() net.initialize);
assert(~isequal(h_dx, avr.f_dx))
x = avr.rv_Xequilibrium + 0.01;  u = avr.rv_Uequilibrium;
V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];
para = avr.tab_parameter.dynamics{:, avr.sv_para}.';
assert(norm(avr.f_dx(0,x,V,u) - avr.fcn_dx(0,x,V,u,para,60)) < 1e-12, ...
       "AVR の f_dx が変更前の定数を使っている")


%% Global controller dynamics edit is rebuilt and marked
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);
h_dx = agc.f_dx;

agc.tab_parameter.dynamics.kP = [200; 200];
assert(isequal(h_dx, agc.f_dx) && DebugScript.helper.is_stale(net))
assert(contains(agc.sct_stale.equilibrium, "edit kP: ") && isequal(agc.sct_stale.odefcn, agc.sct_stale.equilibrium))

DebugScript.helper.quiet(@() net.initialize);
assert(~isequal(h_dx, agc.f_dx))
para = agc.tab_parameter.dynamics{:, agc.sv_para};
x = 0.1;  u = [0.01; 0.02];
assert(norm(agc.f_dx(0,x,[],u) - agc.fcn_dx(0,x,[],u,para,60)) < 1e-12, ...
       "AGC の f_dx が変更前の定数を使っている")


%% Global controller add marks only the controller and remove marks nothing
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
agc = net.add_global_controller("agc-PI", "B001SG1");
assert(isempty(net.sct_stale.powerflow) && DebugScript.helper.is_stale(net))
assert(agc.sct_stale.equilibrium(1) == agc.s_notInitialized)   % 新しい制御器は未初期化のまま
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver == "equilibrium" && ~DebugScript.helper.is_stale(net))
net.remove_global_controller(agc.s_tag);
assert(~DebugScript.helper.is_stale(net))
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)


%% Network Hz edit marks every handle
% 周波数は PowerNetwork だけが持つ。initialize で機器・制御器 (AVR, PSS, AGC) のハンドルがすべて新しい Hz になる
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
c{1}.add_local_controller("avr-ST1");
c{1}.add_local_controller("pss-PSS1");
agc  = net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);
avr = c{1}.a_LocalController{1};
pss = avr.a_LocalController{1};
ld  = net.a_Bus{5}.a_Component{1};
a_model = {c{1}, c{2}, ld, avr, pss, agc};
assert(~any(cellfun(@(m) isempty(m.f_dx), a_model)))
assert(~ismember("base", c{1}.tab_parameter.Properties.VariableNames))   % 機器は Hz を持たない
Hz0 = net.tab_parameter.base.Hz;

net.tab_parameter.base.Hz = 50;
assert(DebugScript.helper.is_stale(net) && isempty(net.sct_stale.powerflow))
assert(all(cellfun(@(m) m.get_Hz(), a_model) == 50))
assert(all(cellfun(@DebugScript.helper.handle_Hz, a_model) == Hz0), "編集しただけでは作り直さない")
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert(all(cellfun(@DebugScript.helper.handle_Hz, a_model) == Hz0), "解析は作り直さない")

% initialize でハンドルは新しい Hz になる
DebugScript.helper.quiet(@() net.initialize);
assert(all(cellfun(@DebugScript.helper.handle_Hz, a_model) == 50))
x = avr.rv_Xequilibrium + 0.01;  u = avr.rv_Uequilibrium;
V = [real(c{1}.c_Vequilibrium); imag(c{1}.c_Vequilibrium)];
para = avr.tab_parameter.dynamics{:, avr.sv_para}.';
assert(norm(avr.f_dx(0,x,V,u) - avr.fcn_dx(0,x,V,u,para,50)) < 1e-12)


%% Network Hz edit redesigns the LQR gain
% K は線形モデルの Hz に依存する。Hz 編集後の initialize で、保持している平衡点で作り直し、潮流から解き直した値と同じになる
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = gen.add_local_controller("local-LQR");
DebugScript.helper.quiet(@() net.initialize);
K60 = lqr.K;
net.tab_parameter.base.Hz = 50;
assert(isequal(lqr.K, K60) && DebugScript.helper.handle_Hz(lqr) == 60, "編集の時点では作り直さない")
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert(isequal(lqr.K, K60), "解析では作り直さない")
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
K50 = lqr.K;
assert(res.s_solver == "equilibrium")
assert(norm(K50 - K60) > 1e-3, "initialize で K を作り直す")
assert(~DebugScript.helper.is_stale(net) && DebugScript.helper.handle_Hz(lqr) == 50)
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(lqr.K, K50), "設計した Hz と同じなら設計し直さない")
u = ones(numel(gen.sv_x), 1);
y_expected = lqr.fcn_y(0, [], [], u, struct("K",K50, "x0",gen.rv_Xequilibrium, "u0",gen.rv_Uequilibrium), 50);
assert(norm(lqr.f_Y(0, [], [], u) - y_expected) < 1e-12, "f_Y が古い K を使っている")
DebugScript.helper.quiet(@() net.initialize(Method="powerflow"));
assert(norm(lqr.K - K50) < 1e-6 * norm(K50), "潮流から解き直した値と一致しない")

% 動特性の編集で平衡点が古いときは、平衡点と一緒に新しい Hz で設計する
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = gen.add_local_controller("local-LQR");
DebugScript.helper.quiet(@() net.initialize);
K60 = lqr.K;
gen.tab_parameter.dynamics.D = 5;
net.tab_parameter.base.Hz = 50;
assert(isequal(lqr.K, K60))
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert(isequal(lqr.K, K60))
DebugScript.helper.quiet(@() net.initialize);
assert(norm(lqr.K - K60) > 1e-3 && DebugScript.helper.handle_Hz(lqr) == 50)

% 未初期化なら設計しない
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = gen.add_local_controller("local-LQR");
net.tab_parameter.base.Hz = 50;
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert(isempty(lqr.K))

% 同じ Hz に戻しても系統の odefcn は古いまま。initialize は K を設計し直さない
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = gen.add_local_controller("local-LQR");
DebugScript.helper.quiet(@() net.initialize);
K60 = lqr.K;
net.tab_parameter.base.Hz = 50;
net.tab_parameter.base.Hz = 60;
assert(numel(net.sct_stale.odefcn) == 2 && DebugScript.helper.is_stale(net))
res = DebugScript.helper.quiet(@() net.initialize(Format="GUILDAorigin"));
assert(res.s_solver == "equilibrium" && ~DebugScript.helper.is_stale(net))
net.get_sys();
assert(isequal(lqr.K, K60))

% Hz を変えると設計できないときは、initialize が警告し、他の層は新しい Hz にして、LQR の平衡点を古いままにする
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
last = net.a_Bus{end}.a_Component{1};
lqr = gen.add_local_controller("local-LQR");
DebugScript.helper.quiet(@() net.initialize);
K60 = lqr.K;
net.tab_parameter.base.Hz = 0;
assert(isequal(lqr.K, K60), "編集の時点では設計しない")
s_out = evalc("net.initialize();");
assert(contains(s_out, "K was not redesigned"), s_out)
assert(isequal(lqr.K, K60) && DebugScript.helper.handle_Hz(last) == 0)
assert(any(contains(lqr.sct_stale.equilibrium, "redesign failed")))
ME = error_of(@() net.get_sys());
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:Stale" && contains(ME.message, "redesign failed"))


%% Network Hz edit redesigns the LQR gain through the layers
% Hz 編集の後は機器・母線・系統の get_sys がどれも initialize を促し、initialize の後のモデルは新しい Hz で作った系統と一致する
build_lqr = @() DebugScript.helper.build_3bus("gen-1axis");
[ref, gen_ref] = build_lqr();
lqr_ref = gen_ref.add_local_controller("local-LQR");
ref.tab_parameter.base.Hz = 50;
DebugScript.helper.quiet(@() ref.initialize);
for s_layer = ["component", "bus", "network"]
    [net, gen] = build_lqr();
    lqr = gen.add_local_controller("local-LQR");
    DebugScript.helper.quiet(@() net.initialize);
    net.tab_parameter.base.Hz = 50;
    switch s_layer
        case "component", assert_stale_error(@() gen.get_sys(), "GUILDA:Component:Stale")
        case "bus",       assert_stale_error(@() gen.a_Bus.get_sys(), "GUILDA:Bus:Stale")
        case "network",   assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
    end
    DebugScript.helper.quiet(@() net.initialize);
    assert(norm(lqr.K - lqr_ref.K) < 1e-6 * norm(lqr_ref.K), s_layer + ": K")
    assert(DebugScript.helper.handle_Hz(lqr) == 50 && ~DebugScript.helper.is_stale(net), s_layer)
    s = gen.get_sys();  sys_ref = gen_ref.get_sys();
    assert(norm(s.A - sys_ref.A, 1) < 1e-6 * norm(sys_ref.A, 1) && norm(s.B - sys_ref.B, 1) < 1e-6 * norm(sys_ref.B, 1), s_layer + ": 機器のモデル")
    assert(isequal(s.StateName, sys_ref.StateName) && isequal(s.InputName, sys_ref.InputName), s_layer + ": 名前")
    for alg = ["Kron", "Feedback", "DAE"]
        s = net.get_sys("Method", alg);  sys_ref = ref.get_sys("Method", alg);
        assert(isequal(size(s.A), size(sys_ref.A)) && norm(s.A - sys_ref.A, 1) < 1e-6 * norm(sys_ref.A, 1), s_layer + " " + alg)
    end
end


%% Components and controllers use the network Hz when attached
% 系統の外で作った制御器は GUILDA.config の Hz、系統に付けると系統の Hz になる。
% ハンドルは作った直後には無く (f_dx が空)、initialize で系統の Hz で作る
net = PowerNetwork();
net.tab_parameter.base.Hz = 50;
net.add_bus("V",1.0);
gen = net.a_Bus{1}.add_component("gen-1axis");
assert(gen.get_Hz() == 50 && isempty(gen.f_dx))
avr = controller.avr.AVR_ST1("avr1");
assert(avr.get_Hz() == GUILDA.config("Model","Hz") && isempty(avr.f_dx))
avr = gen.add_local_controller("avr-ST1");
assert(avr.get_Hz() == 50 && isempty(avr.f_dx))
assert_stale_error(@() gen.get_sys(), "GUILDA:Component:Stale")    % 解析はハンドルを作らない
assert(isempty(gen.f_dx) && isempty(avr.f_dx))
DebugScript.helper.quiet(@() net.initialize);
assert(~isempty(gen.f_dx) && ~isempty(avr.f_dx))
assert(DebugScript.helper.handle_Hz(avr) == 50)
x = zeros(numel(gen.sv_x),1);  x(gen.sv_x == "omega") = 0.01;
para = gen.tab_parameter.dynamics{:, gen.sv_para};
V = [1;0];  u = zeros(numel(gen.sv_u),1);
assert(norm(gen.f_dx(0,x,V,u) - gen.fcn_dx(0,x,V,u,para,50)) < 1e-12)


%% Handles are built at initialize
% 作った直後は f_dx が空で、initialize で作る
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
avr  = comp.add_local_controller("avr-ST1");
pss  = comp.add_local_controller("pss-PSS1");
a_model = {comp, avr, pss};
assert(isempty(avr.f_dx) && isempty(pss.f_dx))
DebugScript.helper.quiet(@() net.initialize);
assert(~any(cellfun(@(m) isempty(m.f_dx), a_model)))

% 系統に属さない機器を直接使う: get_sys と validate がハンドルを作る
stub = DebugScript.helper.HessianStub();
assert(isempty(stub.f_dx))
sys = stub.get_sys([1;2], [1;0], 0);
assert(~isempty(stub.f_dx) && isequal(size(sys.A), [2 2]))
assert(DebugScript.helper.handle_Hz(stub) == GUILDA.config("Model","Hz"))
stub = DebugScript.helper.HessianStub();
flag = stub.validate(false);
assert(isstruct(flag) && isfield(flag, "contract"))


%% A component has no base column
% 周波数は系統だけが持つ。機器の tab_parameter に base 列は無く、base 列を書くとエラーで何も変わらない
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
assert(~ismember("base", comp.tab_parameter.Properties.VariableNames))
assert(~isprop(comp, "para_base"))
tp = comp.tab_parameter;
tp.dynamics.D = 3;
tp.base = table(50, 'VariableNames', "Hz");
try
    comp.tab_parameter = tp;
    error("DebugScript:noError", "base 列を書いてもエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerSystemModel:UnknownParameterGroup", DebugScript.helper.msg_id(ME))
end
assert(comp.tab_parameter.dynamics.D ~= 3 && net.tab_parameter.base.Hz ~= 50 && ~DebugScript.helper.is_stale(net))


% ---- local functions ----
function para = handle_para(obj)
% 機器の関数ハンドル f_dx に埋め込まれたパラメータを読む
    s    = functions(obj.f_dx);
    para = s.workspace{1}.array;
end


function assert_stale_error(fcn, s_id)
% fcn が古さを知らせるエラー (net.initialize() を促す) になることを確認する
    try
        DebugScript.helper.quiet(fcn);
    catch ME
        assert(DebugScript.helper.msg_id(ME) == s_id, "想定外のエラー: " + DebugScript.helper.msg_id(ME) + " " + ME.message)
        assert(contains(ME.message, "net.initialize()"))
        return
    end
    error("DebugScript:noError", "古いのにエラーにならない")
end


function ME = error_of(fcn)
% fcn を実行し、出たエラーを返す (エラーなしは [])
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
end


function id = warn_id(fcn)
% fcn を実行し、出た警告の ID を返す (警告なしは "")
    lastwarn("");
    evalc("fcn();");
    id = DebugScript.helper.msg_id();
    id = string(id);
end
