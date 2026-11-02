% F3 編集後の解析 (編集の扱い)
%
% パラメータや構成を編集しても値が変わるだけで、何かが古くなったことを記録する。
%   dynamics の編集 → 関数ハンドル f_* と平衡点が古くなる
%   base(baseMVA) の編集 → 平衡点が古くなる (f_* は baseMVA を持たない)
%   base(Hz) の編集 → その場で全層の f_* を作り直す (平衡点は定格周波数によらない)
%   powerflow の編集・構成の変更 (add_/remove_/replace_)・スラック母線の変更 → 平衡点が古くなる
%   operation / OPF / graph の編集 → 何も古くならない
% 解析の開始時 (initialize / simulate / get_sys) に古いハンドルだけを作り直す。
% 平衡点が古い (または未設定) とき simulate / get_sys は net.initialize() を促すエラーにする。
% 状態は s_edit.l_staleOdefcn (ハンドルを持つ機器・制御器) と s_edit.l_staleEquilibrium (PowerNetwork) で確認する。
%
% 実行: runtests("DebugScript.test_F3_edit_handling")  または  DebugScript.run_all("Features","F3")

% 共通設定 (各テストの前に毎回実行される)
str_staleID = "GUILDA:PowerNetwork:EquilibriumStale";


%% Simulate and get_sys before initialize ask for initialize
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)
assert_stale_error(@() net.get_sys(), str_staleID)


%% Solvers called directly check the equilibrium
% net.solver_ODE.solve / net.solver_LIN.solve も simulate / linearize と同じ確認をする
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
assert_stale_error(@() net.solver_ODE.solve(net, [0,1]), str_staleID)
assert_stale_error(@() net.solver_LIN.solve(net), str_staleID)

DebugScript.helper.quiet(@() net.initialize);
comp.tab_parameter.dynamics.D = 5;
assert_stale_error(@() net.solver_ODE.solve(net, [0,1]), str_staleID)
assert_stale_error(@() net.solver_LIN.solve(net), str_staleID)

DebugScript.helper.quiet(@() net.initialize);
sol = DebugScript.helper.quiet(@() net.solver_ODE.solve(net, [0,1]));
assert(sol.odeResults.t(end) == 1)
res = DebugScript.helper.quiet(@() net.solver_LIN.solve(net));
assert(isa(res, "LTIresult"))


%% Dynamics edit makes handles and equilibrium stale
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
assert(~comp.s_edit.l_staleOdefcn && ~net.s_edit.l_staleEquilibrium)

comp.tab_parameter.dynamics.D = 5;
assert(comp.s_edit.l_staleOdefcn && net.s_edit.l_staleEquilibrium)
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)
assert_stale_error(@() net.get_sys(), str_staleID)

% initialize でハンドルが作り直され、平衡点も最新になる
DebugScript.helper.quiet(@() net.initialize);
assert(~comp.s_edit.l_staleOdefcn && ~net.s_edit.l_staleEquilibrium)
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
net.get_sys();


%% Base Hz edit rebuilds the handles at once
% 周波数は PowerNetwork が持つ (net.tab_parameter.base.Hz)。変えるとその場で全機器のハンドルを作り直す。
% 平衡点は定格周波数によらないので initialize し直さなくてよい
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
x_eq = comp.rv_Xequilibrium;
net.tab_parameter.base.Hz = 50;
assert(DebugScript.helper.handle_Hz(comp) == 50 && ~comp.s_edit.l_staleOdefcn && ~net.s_edit.l_staleEquilibrium)
assert(comp.r_Hz == 50 && net.tab_editLog.log(end) == "edit Hz")

% initialize なしで simulate でき、平衡点に留まる
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(~comp.s_edit.l_staleOdefcn && sol.odeResults.t(end) == 1)
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)

% initialize し直しても平衡点は変わらない
DebugScript.helper.quiet(@() net.initialize);
assert(norm(comp.rv_Xequilibrium - x_eq) < 1e-10)
x = comp.rv_Xequilibrium;  x(comp.sv_x == "omega") = 0.01;
V = comp.c_Vequilibrium;  I = comp.c_Iequilibrium;
para = comp.tab_parameter.dynamics{:, comp.sv_para};
dx_used = comp.f_dx(0, x, [real(V);imag(V)], [real(I);imag(I)], comp.rv_Uequilibrium);
dx_new  = comp.fcn_dx(0, x, [real(V);imag(V)], [real(I);imag(I)], comp.rv_Uequilibrium, para, 50);
assert(norm(dx_used - dx_new) < 1e-12, "f_dx が変更前の Hz を使っている")


%% Base baseMVA edit makes the equilibrium stale
% baseMVA を変えると単位法の値が変わるので、平衡点も古くなる
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
f_dx = comp.f_dx;
net.tab_parameter.base.baseMVA = 200;
assert(~comp.s_edit.l_staleOdefcn && net.s_edit.l_staleEquilibrium)
assert(isequal(comp.f_dx, f_dx))
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)
assert_stale_error(@() net.get_sys(), str_staleID)
DebugScript.helper.quiet(@() net.initialize);
assert(~comp.s_edit.l_staleOdefcn && ~net.s_edit.l_staleEquilibrium)


%% Powerflow edit makes only the equilibrium stale
[net, comp] = DebugScript.helper.build_3bus("load-power");
DebugScript.helper.quiet(@() net.initialize);
h_dx = comp.f_dx;

comp.tab_parameter.powerflow.P = -1.1;
assert(~comp.s_edit.l_staleOdefcn && net.s_edit.l_staleEquilibrium)
assert_stale_error(@() net.get_sys(), str_staleID)

% 潮流設定の母線パラメータも同じ
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{2}.tab_parameter.powerflow.V = 1.01;
assert(net.s_edit.l_staleEquilibrium)
DebugScript.helper.quiet(@() net.initialize);
assert(~net.s_edit.l_staleEquilibrium)
assert(isequal(h_dx, comp.f_dx))       % ハンドルは作り直されない


%% Bus and branch dynamics edits make the equilibrium stale
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
net.a_Branch{4}.tab_parameter.dynamics.X = 0.09;
assert(net.s_edit.l_staleEquilibrium)

DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{5}.tab_parameter.dynamics.Bshunt = 0.1;
assert(net.s_edit.l_staleEquilibrium)


%% Topology changes make the equilibrium stale
% 機器の追加
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.add_component("load-impedance", "P", -0.1, "Q", 0);
assert(net.s_edit.l_staleEquilibrium)
assert_stale_error(@() net.get_sys(), str_staleID)

% 機器の削除
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.remove_component(string(net.a_Bus{3}.a_Component{2}));
assert(net.s_edit.l_staleEquilibrium)

% 機器の置き換え (編集ログにも残る)
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.replace_component(string(net.a_Bus{3}.a_Component{1}), "load-impedance");
assert(net.s_edit.l_staleEquilibrium)
assert(any(contains(net.tab_editLog.log, "replace")) && all(net.tab_editLog.tag == "Topology"))
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)

% 送電線の追加・削除
DebugScript.helper.quiet(@() net.initialize);
net.add_branch("pi", [1,3], "R",0.02, "X",0.1);
assert(net.s_edit.l_staleEquilibrium)
DebugScript.helper.quiet(@() net.initialize);
net.remove_branch(string(net.a_Branch{3}));
assert(net.s_edit.l_staleEquilibrium && any(contains(net.tab_editLog.log, "remove")))

% 母線の追加
DebugScript.helper.quiet(@() net.initialize);
net.add_bus();
assert(net.s_edit.l_staleEquilibrium)


%% Local controller add and replace make the equilibrium stale
% AVR / PSS の追加・置き換えは構成の変更 (Topology) として記録される
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
assert(net.s_edit.l_staleEquilibrium)
assert(net.tab_editLog.tag(end) == "Topology" && contains(net.tab_editLog.log(end), "avr1"))
assert_stale_error(@() net.get_sys(), str_staleID)
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)

% PSS の追加
DebugScript.helper.quiet(@() net.initialize);
comp.add_local_controller(controller.pss.PSS1("pss1"));
assert(net.s_edit.l_staleEquilibrium && contains(net.tab_editLog.log(end), "pss1"))

% AVR の置き換え (警告が出る)
DebugScript.helper.quiet(@() net.initialize);
assert(warn_id(@() comp.add_local_controller(controller.avr.AVR_DC1("avr2"))) == "GUILDA:Component:ReplaceController")
assert(net.s_edit.l_staleEquilibrium && contains(net.tab_editLog.log(end), "replace"))
assert(all(net.tab_editLog.tag == "Topology"))

% 系統に属さない機器への追加は記録先がないだけでエラーにならない
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{1}.remove_component(string(comp));
evalc("net.a_Bus{2}.l_isSlack = true;");     % スラック母線に機器がないと平衡点にならない
DebugScript.helper.quiet(@() net.initialize);
comp.add_local_controller(controller.avr.AVR_ST1("avr3"));
assert(~net.s_edit.l_staleEquilibrium)


%% LQR add and weight edit make the equilibrium stale
% LQR の追加は構成の変更、重み Q / R の変更はゲインが変わるので動特性の変更として記録される
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
lqr = controller.local_LQR("lqr1");
comp.add_local_controller(lqr);
assert(net.s_edit.l_staleEquilibrium)
assert(net.tab_editLog.tag(end) == "Topology" && contains(net.tab_editLog.log(end), "lqr1"))

DebugScript.helper.quiet(@() net.initialize);
K1 = lqr.K;
lqr.Q = 10*ones(1, numel(comp.sv_x));
assert(net.s_edit.l_staleEquilibrium && net.tab_editLog.tag(end) == "Parameter(dynamics)")
assert_stale_error(@() net.get_sys(), str_staleID)

% initialize でゲインが計算し直される
DebugScript.helper.quiet(@() net.initialize);
assert(~net.s_edit.l_staleEquilibrium && norm(lqr.K - K1) > 1e-6)


%% Slack bus change makes the equilibrium stale
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
evalc("net.a_Bus{2}.l_isSlack = true;");     % 表示 (INFO) は抑制
assert(net.s_edit.l_staleEquilibrium)
assert(any(net.tab_editLog.tag == "Slack"))
assert_stale_error(@() net.get_sys(), str_staleID)


%% Operation OPF and graph edits keep the equilibrium
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
h_dx = comp.f_dx;

comp.tab_parameter.operation.Pmax = 2;
comp.tab_parameter.OPF.HP = 3;
comp.tab_parameter.graph.Marker = "s";
net.a_Bus{2}.tab_parameter.operation.Vmax = 1.2;
net.a_Bus{2}.tab_parameter.graph.Xaxis = 1;

% 編集は記録されるが、何も古くならない
assert(DebugScript.helper.edit_flag(net) == "editted" && height(net.tab_editLog) == 5)
assert(~comp.s_edit.l_staleOdefcn && ~net.s_edit.l_staleEquilibrium)

% initialize し直さなくても解析できる
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
net.get_sys();
assert(isequal(h_dx, comp.f_dx))


%% Analysis start rebuilds only the stale handles
net = DebugScript.helper.build_ieee14();
c1  = net.a_Bus{1}.a_Component{1};
c2  = net.a_Bus{2}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
h1 = c1.f_dx;  h2 = c2.f_dx;

c1.tab_parameter.dynamics.D = 50;
assert(c1.s_edit.l_staleOdefcn && ~c2.s_edit.l_staleOdefcn)
assert(isequal(h1, c1.f_dx))           % 編集しただけでは作り直さない

DebugScript.helper.quiet(@() net.initialize);
assert(~c1.s_edit.l_staleOdefcn)
assert(~isequal(h1, c1.f_dx))          % 編集した機器だけ作り直す
assert(isequal(h2, c2.f_dx))


%% Local controller dynamics edit is rebuilt at initialize
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
avr = comp.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);

avr.para_dynamics.kap = 2 * avr.para_dynamics.kap;
assert(avr.s_edit.l_staleOdefcn && ~comp.s_edit.l_staleOdefcn && net.s_edit.l_staleEquilibrium)
assert_stale_error(@() net.get_sys(), str_staleID)

DebugScript.helper.quiet(@() net.initialize);
assert(~avr.s_edit.l_staleOdefcn)
x = avr.rv_Xequilibrium + 0.01;  u = avr.rv_Uequilibrium;
V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];
para = avr.tab_parameter.dynamics{:, avr.sv_para}.';
assert(norm(avr.f_dx(0,x,V,[0;0],u) - avr.fcn_dx(0,x,V,[0;0],u,para,60)) < 1e-12, ...
       "AVR の f_dx が変更前の定数を使っている")


%% Global controller dynamics edit is rebuilt and logged
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);

agc.para_dynamics.kP = [200; 200];
assert(agc.s_edit.l_staleOdefcn && net.s_edit.l_staleEquilibrium)
assert(any(net.tab_editLog.log == "edit kP"))

DebugScript.helper.quiet(@() net.initialize);
assert(~agc.s_edit.l_staleOdefcn)
para = agc.tab_parameter.dynamics{:, agc.sv_para};
x = 0.1;  u = [0.01; 0.02];
assert(norm(agc.f_dx(0,x,[],[],u) - agc.fcn_dx(0,x,[],[],u,para,60)) < 1e-12, ...
       "AGC の f_dx が変更前の定数を使っている")


%% Network Hz edit rebuilds every handle
% 周波数は PowerNetwork だけが持つ。変えると機器・制御器 (AVR, PSS, AGC) のハンドルがすべて古くなる
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
c{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);
avr = c{1}.a_LocalController{1};
pss = avr.a_LocalController{1};
ld  = net.a_Bus{5}.a_Component{1};
a_model = {c{1}, c{2}, ld, avr, pss, agc};
assert(~any(cellfun(@(m) m.s_edit.l_staleOdefcn, a_model)))
assert(isa(c{1}.tab_parameter.base, "ComponentBaseView"))   % 機器は Hz を持たない (旧形式の互換ビューだけ)

net.tab_parameter.base.Hz = 50;
assert(all(cellfun(@DebugScript.helper.handle_Hz, a_model) == 50) && ~net.s_edit.l_staleEquilibrium)
assert(all(cellfun(@(m) m.r_Hz, a_model) == 50))
assert(~any(cellfun(@(m) m.s_edit.l_staleOdefcn, a_model)))

% 編集の時点でハンドルは新しい Hz になっている (initialize は不要)
x = avr.rv_Xequilibrium + 0.01;  u = avr.rv_Uequilibrium;
V = [real(c{1}.c_Vequilibrium); imag(c{1}.c_Vequilibrium)];
para = avr.tab_parameter.dynamics{:, avr.sv_para}.';
assert(norm(avr.f_dx(0,x,V,[0;0],u) - avr.fcn_dx(0,x,V,[0;0],u,para,50)) < 1e-12)


%% Network Hz edit redesigns the LQR gain
% K は線形モデルの Hz に依存する。保持している平衡点で作り直し、再初期化と同じ値になる
for str_call = ["get_sys", "simulate"]
    [net, gen] = DebugScript.helper.build_3bus("gen-1axis");
    lqr = controller.local_LQR("lqr1");
    gen.add_local_controller(lqr);
    DebugScript.helper.quiet(@() net.initialize);
    K60 = lqr.K;
    net.tab_parameter.base.Hz = 50;
    K50 = lqr.K;
    assert(norm(K50 - K60) > 1e-3 && ~net.s_edit.l_staleEquilibrium, "編集の時点で K を作り直す")
    if str_call == "get_sys"
        net.get_sys();
    else
        net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
    end
    assert(isequal(lqr.K, K50), "解析では作り直さない")
    assert(~net.s_edit.l_staleEquilibrium && ~lqr.s_edit.l_staleOdefcn)
    u = ones(numel(gen.sv_x), 1);
    y_expected = lqr.fcn_y(0, [], [], [], u, struct("K",K50, "x0",gen.rv_Xequilibrium, "u0",gen.rv_Uequilibrium), 50);
    assert(norm(lqr.f_Y(0, [], [], [], u) - y_expected) < 1e-12, "f_Y が古い K を使っている")
    DebugScript.helper.quiet(@() net.initialize);
    assert(norm(lqr.K - K50) < 1e-6 * norm(K50), "再初期化の値と一致しない")
end

% 動特性の編集で平衡点が古いときは Hz を編集しても設計せず、K は initialize まで変えない
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr);
DebugScript.helper.quiet(@() net.initialize);
K60 = lqr.K;
gen.tab_parameter.dynamics.D = 5;
net.tab_parameter.base.Hz = 50;
assert(isequal(lqr.K, K60))
assert_stale_error(@() net.get_sys(), str_staleID)
assert(isequal(lqr.K, K60))
DebugScript.helper.quiet(@() net.initialize);
assert(norm(lqr.K - K60) > 1e-3)

% 未初期化なら設計しない
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr);
net.tab_parameter.base.Hz = 50;
assert_stale_error(@() net.get_sys(), str_staleID)
assert(isempty(lqr.K))

% 同じ Hz に戻したときは設計し直さず、K はそのまま
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr);
DebugScript.helper.quiet(@() net.initialize);
K60 = lqr.K;
net.tab_parameter.base.Hz = 50;
net.tab_parameter.base.Hz = 60;
net.get_sys();
assert(norm(lqr.K - K60) < 1e-9 * norm(K60))

% Hz を変えると設計できないときは警告し、他の層は新しい Hz にして、initialize を促す
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
last = net.a_Bus{end}.a_Component{1};
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr);
DebugScript.helper.quiet(@() net.initialize);
K60 = lqr.K;
lastwarn("");
evalc("net.tab_parameter.base.Hz = 0;");
[~, id] = lastwarn();
assert(string(id) == "GUILDA:local_LQR:RedesignFailed" && isequal(lqr.K, K60))
assert(DebugScript.helper.handle_Hz(last) == 0 && net.s_edit.l_staleEquilibrium)
assert(net.tab_editLog.log(1) == "edit Hz" && contains(net.tab_editLog.log(end), "redesign failed"))
assert_stale_error(@() net.get_sys(), str_staleID)

% 設計済みの制御器を外して Hz の違う系統へ付け替える: initialize で新しい Hz の K になる
[net50, gen50] = DebugScript.helper.build_3bus("gen-1axis");
net50.tab_parameter.base.Hz = 50;
lqr = controller.local_LQR("lqr1");
gen50.add_local_controller(lqr);
DebugScript.helper.quiet(@() net50.initialize);
gen50.remove_local_controller(lqr.str_tag);
assert(lqr.r_Hz == GUILDA.config("Model","Hz"))
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gen.add_local_controller(lqr);          % 未初期化の系統: 設計しない
assert(lqr.r_Hz == net.r_Hz && lqr.s_edit.l_staleOdefcn == false)
DebugScript.helper.quiet(@() net.initialize);
K = lqr.K;
net.tab_parameter.base.Hz = 50;
assert(norm(lqr.K - K) > 1e-3)


%% Network Hz edit redesigns the LQR gain through the layers
% 機器・母線の get_sys でも net.get_sys と同じように K を作り直し、モデルは新しい Hz で作った系統と一致する
build_lqr = @() DebugScript.helper.build_3bus("gen-1axis");
[ref, gen_ref] = build_lqr();
lqr_ref = controller.local_LQR("lqr1");
gen_ref.add_local_controller(lqr_ref);
ref.tab_parameter.base.Hz = 50;
DebugScript.helper.quiet(@() ref.initialize);
for str_layer = ["component", "bus", "network"]
    [net, gen] = build_lqr();
    lqr = controller.local_LQR("lqr1");
    gen.add_local_controller(lqr);
    DebugScript.helper.quiet(@() net.initialize);
    net.tab_parameter.base.Hz = 50;
    switch str_layer
        case "component", gen.get_sys();
        case "bus",       gen.a_Bus.get_sys();
        case "network",   net.get_sys();
    end
    assert(norm(lqr.K - lqr_ref.K) < 1e-6 * norm(lqr_ref.K), str_layer + ": K")
    assert(~lqr.s_edit.l_staleOdefcn && ~net.s_edit.l_staleEquilibrium, str_layer)
    s = gen.get_sys();  s_ref = gen_ref.get_sys();
    assert(norm(s.A - s_ref.A, 1) < 1e-6 * norm(s_ref.A, 1) && norm(s.B - s_ref.B, 1) < 1e-6 * norm(s_ref.B, 1), str_layer + ": 機器のモデル")
    assert(isequal(s.StateName, s_ref.StateName) && isequal(s.InputName, s_ref.InputName), str_layer + ": 名前")
    for alg = ["Kron", "Feedback", "DAE"]
        s = net.get_sys("Algorithm", alg);  s_ref = ref.get_sys("Algorithm", alg);
        assert(isequal(size(s.A), size(s_ref.A)) && norm(s.A - s_ref.A, 1) < 1e-6 * norm(s_ref.A, 1), str_layer + " " + alg)
    end
end


%% Components and controllers use the network Hz when attached
% 系統の外で作った制御器は GUILDA.config の Hz、系統に付けると系統の Hz になる
net = PowerNetwork();
net.tab_parameter.base.Hz = 50;
net.add_bus("V",1.0);
gen = net.a_Bus{1}.add_component("gen-1axis");
assert(gen.r_Hz == 50)
avr = controller.avr.AVR_ST1("avr1");
assert(avr.r_Hz == GUILDA.config("Model","Hz"))
gen.add_local_controller(avr);
assert(avr.r_Hz == 50 && ~avr.s_edit.l_staleOdefcn)
x = zeros(numel(gen.sv_x),1);  x(gen.sv_x == "omega") = 0.01;
para = gen.tab_parameter.dynamics{:, gen.sv_para};
V = [1;0];  I = [0.5;0];  u = zeros(numel(gen.sv_u),1);
assert(norm(gen.f_dx(0,x,V,I,u) - gen.fcn_dx(0,x,V,I,u,para,50)) < 1e-12)


%% Deprecated component Hz forms still work and warn once
% 旧形式 comp.tab_parameter.base.Hz / comp.para_base.Hz は系統の Hz を返し、警告を1回だけ出す
str_id = "GUILDA:Deprecated:ComponentBaseHz";
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
net.tab_parameter.base.Hz = 50;
clear Deprecated
assert(warn_id(@() comp.tab_parameter.base.Hz) == str_id)
assert(comp.tab_parameter.base.Hz == 50 && comp.para_base.Hz == 50)
assert(comp.para_base.tab_parameter.Hz == 50)
assert(warn_id(@() comp.para_base.Hz) == "", "警告は1セッションに1回")
clear Deprecated
assert(warn_id(@() comp.para_base.Hz) == str_id)
% 他の列の編集は今まで通り (base は無視される)
comp.tab_parameter.dynamics.D = 3;
assert(comp.para_dynamics.D == 3 && net.para_base.Hz == 50)


%% Deprecated component Hz write sets the network Hz
% 旧形式で Hz を書くと系統全体の Hz を変え (警告)、全機器のハンドルが古くなる
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
other = net.a_Bus{1}.a_Component{1};
clear Deprecated
lastwarn("");
evalc("comp.tab_parameter.base.Hz = 50;");
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:ComponentBaseHzSet")
assert(net.tab_parameter.base.Hz == 50 && other.r_Hz == 50)
assert(DebugScript.helper.handle_Hz(comp) == 50 && DebugScript.helper.handle_Hz(other) == 50 && ~net.s_edit.l_staleEquilibrium)
evalc("comp.para_base.Hz = 55;");
assert(net.tab_parameter.base.Hz == 55 && DebugScript.helper.handle_Hz(comp) == 55)


% ---- local functions ----
function assert_stale_error(fcn, str_id)
% fcn が平衡点の古さを知らせるエラー (net.initialize() を促す) になることを確認する
    try
        DebugScript.helper.quiet(fcn);
    catch ME
        assert(ME.identifier == str_id, "想定外のエラー: " + ME.identifier + " " + ME.message)
        assert(contains(ME.message, "net.initialize()"))
        return
    end
    error("DebugScript:noError", "平衡点が古いのにエラーにならない")
end


function id = warn_id(fcn)
% fcn を実行し、出た警告の ID を返す (警告なしは "")
    lastwarn("");
    evalc("fcn();");
    [~, id] = lastwarn();
    id = string(id);
end
