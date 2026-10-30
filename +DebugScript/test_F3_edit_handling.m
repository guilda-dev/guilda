% F3 編集後の解析 (編集の扱い)
%
% パラメータや構成を編集しても値が変わるだけで、何かが古くなったことを記録する。
%   dynamics / base(baseMVA) の編集 → 関数ハンドル f_* と平衡点が古くなる
%   base(Hz) の編集 → 関数ハンドル f_* だけが古くなる (平衡点は定格周波数によらない)
%   powerflow の編集・構成の変更 (add_/remove_/replace_)・スラック母線の変更 → 平衡点が古くなる
%   operation / OPF / graph の編集 → 何も古くならない
% 解析の開始時 (initialize / simulate / get_sys) に古いハンドルだけを作り直す。
% 平衡点が古い (または未設定) とき simulate / get_sys は net.initialize() を促すエラーにする。
% 状態は l_staleOdefcn (ハンドルを持つ機器・制御器) と l_staleEquilibrium (PowerNetwork) で確認する。
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
assert(isa(res, "LinearizationResult"))


%% Dynamics edit makes handles and equilibrium stale
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
assert(~comp.l_staleOdefcn && ~net.l_staleEquilibrium)

comp.tab_parameter.dynamics.D = 5;
assert(comp.l_staleOdefcn && net.l_staleEquilibrium)
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)
assert_stale_error(@() net.get_sys(), str_staleID)

% initialize でハンドルが作り直され、平衡点も最新になる
DebugScript.helper.quiet(@() net.initialize);
assert(~comp.l_staleOdefcn && ~net.l_staleEquilibrium)
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
net.get_sys();


%% Base Hz edit makes only the handles stale
% 周波数は PowerNetwork が持つ (net.tab_parameter.base.Hz)。変えると全機器のハンドルが古くなるが、
% 平衡点は定格周波数によらないので initialize し直さなくてよい
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
x_eq = comp.rv_Xequilibrium;
net.tab_parameter.base.Hz = 50;
assert(comp.l_staleOdefcn && ~net.l_staleEquilibrium)
assert(comp.r_Hz == 50 && net.tab_editLog.log(end) == "edit Hz")

% simulate がハンドルを作り直し、平衡点に留まる
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(~comp.l_staleOdefcn && sol.odeResults.t(end) == 1)
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


%% Base baseMVA edit makes handles and equilibrium stale
% baseMVA を変えると単位法の値が変わるので、平衡点も古くなる
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.tab_parameter.base.baseMVA = 200;
assert(comp.l_staleOdefcn && net.l_staleEquilibrium)
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)
assert_stale_error(@() net.get_sys(), str_staleID)
DebugScript.helper.quiet(@() net.initialize);
assert(~comp.l_staleOdefcn && ~net.l_staleEquilibrium)


%% Powerflow edit makes only the equilibrium stale
[net, comp] = DebugScript.helper.build_3bus("load-power");
DebugScript.helper.quiet(@() net.initialize);
h_dx = comp.f_dx;

comp.tab_parameter.powerflow.P = -1.1;
assert(~comp.l_staleOdefcn && net.l_staleEquilibrium)
assert_stale_error(@() net.get_sys(), str_staleID)

% 潮流設定の母線パラメータも同じ
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{2}.tab_parameter.powerflow.V = 1.01;
assert(net.l_staleEquilibrium)
DebugScript.helper.quiet(@() net.initialize);
assert(~net.l_staleEquilibrium)
assert(isequal(h_dx, comp.f_dx))       % ハンドルは作り直されない


%% Bus and branch dynamics edits make the equilibrium stale
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
net.a_Branch{4}.tab_parameter.dynamics.X = 0.09;
assert(net.l_staleEquilibrium)

DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{5}.tab_parameter.dynamics.Bshunt = 0.1;
assert(net.l_staleEquilibrium)


%% Topology changes make the equilibrium stale
% 機器の追加
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.add_component("load-impedance", "P", -0.1, "Q", 0);
assert(net.l_staleEquilibrium)
assert_stale_error(@() net.get_sys(), str_staleID)

% 機器の削除
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.remove_component(string(net.a_Bus{3}.a_Component{2}));
assert(net.l_staleEquilibrium)

% 機器の置き換え (編集ログにも残る)
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.replace_component(string(net.a_Bus{3}.a_Component{1}), "load-impedance");
assert(net.l_staleEquilibrium)
assert(any(contains(net.tab_editLog.log, "replace")) && all(net.tab_editLog.tag == "Topology"))
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)

% 送電線の追加・削除
DebugScript.helper.quiet(@() net.initialize);
net.add_branch("pi", [1,3], "R",0.02, "X",0.1);
assert(net.l_staleEquilibrium)
DebugScript.helper.quiet(@() net.initialize);
net.remove_branch(string(net.a_Branch{3}));
assert(net.l_staleEquilibrium && any(contains(net.tab_editLog.log, "remove")))

% 母線の追加
DebugScript.helper.quiet(@() net.initialize);
net.add_bus();
assert(net.l_staleEquilibrium)


%% Local controller add and replace make the equilibrium stale
% AVR / PSS の追加・置き換えは構成の変更 (Topology) として記録される
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
assert(net.l_staleEquilibrium)
assert(net.tab_editLog.tag(end) == "Topology" && contains(net.tab_editLog.log(end), "avr1"))
assert_stale_error(@() net.get_sys(), str_staleID)
assert_stale_error(@() net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1])), str_staleID)

% PSS の追加
DebugScript.helper.quiet(@() net.initialize);
comp.add_local_controller(controller.pss.PSS1("pss1"));
assert(net.l_staleEquilibrium && contains(net.tab_editLog.log(end), "pss1"))

% AVR の置き換え (警告が出る)
DebugScript.helper.quiet(@() net.initialize);
assert(warn_id(@() comp.add_local_controller(controller.avr.AVR_DC1("avr2"))) == "GUILDA:Component:ReplaceController")
assert(net.l_staleEquilibrium && contains(net.tab_editLog.log(end), "replace"))
assert(all(net.tab_editLog.tag == "Topology"))

% 系統に属さない機器への追加は記録先がないだけでエラーにならない
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{1}.remove_component(string(comp));
DebugScript.helper.quiet(@() net.initialize);
comp.add_local_controller(controller.avr.AVR_ST1("avr3"));
assert(~net.l_staleEquilibrium)


%% LQR add and weight edit make the equilibrium stale
% LQR の追加は構成の変更、重み Q / R の変更はゲインが変わるので動特性の変更として記録される
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
DebugScript.helper.quiet(@() net.initialize);
lqr = controller.local_LQR("lqr1");
comp.add_local_controller(lqr);
assert(net.l_staleEquilibrium)
assert(net.tab_editLog.tag(end) == "Topology" && contains(net.tab_editLog.log(end), "lqr1"))

DebugScript.helper.quiet(@() net.initialize);
K1 = lqr.K;
lqr.Q = 10*ones(1, numel(comp.sv_x));
assert(net.l_staleEquilibrium && net.tab_editLog.tag(end) == "Parameter(dynamics)")
assert_stale_error(@() net.get_sys(), str_staleID)

% initialize でゲインが計算し直される
DebugScript.helper.quiet(@() net.initialize);
assert(~net.l_staleEquilibrium && norm(lqr.K - K1) > 1e-6)


%% Slack bus change makes the equilibrium stale
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
evalc("net.a_Bus{2}.l_isSlack = true;");     % 表示 (INFO) は抑制
assert(net.l_staleEquilibrium)
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
assert(~comp.l_staleOdefcn && ~net.l_staleEquilibrium)

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
assert(c1.l_staleOdefcn && ~c2.l_staleOdefcn)
assert(isequal(h1, c1.f_dx))           % 編集しただけでは作り直さない

DebugScript.helper.quiet(@() net.initialize);
assert(~c1.l_staleOdefcn)
assert(~isequal(h1, c1.f_dx))          % 編集した機器だけ作り直す
assert(isequal(h2, c2.f_dx))


%% Local controller dynamics edit is rebuilt at initialize
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
avr = comp.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);

avr.para_dynamics.kap = 2 * avr.para_dynamics.kap;
assert(avr.l_staleOdefcn && ~comp.l_staleOdefcn && net.l_staleEquilibrium)
assert_stale_error(@() net.get_sys(), str_staleID)

DebugScript.helper.quiet(@() net.initialize);
assert(~avr.l_staleOdefcn)
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
assert(agc.l_staleOdefcn && net.l_staleEquilibrium)
assert(any(net.tab_editLog.log == "edit kP"))

DebugScript.helper.quiet(@() net.initialize);
assert(~agc.l_staleOdefcn)
para = agc.tab_parameter.dynamics{:, agc.sv_para};
x = 0.1;  u = [0.01; 0.02];
assert(norm(agc.f_dx(0,x,[],[],u) - agc.fcn_dx(0,x,[],[],u,para,60)) < 1e-12, ...
       "AGC の f_dx が変更前の定数を使っている")


%% Network Hz edit makes every handle stale
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
assert(~any(cellfun(@(m) m.l_staleOdefcn, a_model)))
assert(isa(c{1}.tab_parameter.base, "ComponentBaseView"))   % 機器は Hz を持たない (旧形式の互換ビューだけ)

net.tab_parameter.base.Hz = 50;
assert(all(cellfun(@(m) m.l_staleOdefcn, a_model)) && ~net.l_staleEquilibrium)
assert(all(cellfun(@(m) m.r_Hz, a_model) == 50))

% get_sys がハンドルを作り直す (initialize は不要)
net.get_sys();
assert(~any(cellfun(@(m) m.l_staleOdefcn, a_model)))
x = avr.rv_Xequilibrium + 0.01;  u = avr.rv_Uequilibrium;
V = [real(c{1}.c_Vequilibrium); imag(c{1}.c_Vequilibrium)];
para = avr.tab_parameter.dynamics{:, avr.sv_para}.';
assert(norm(avr.f_dx(0,x,V,[0;0],u) - avr.fcn_dx(0,x,V,[0;0],u,para,50)) < 1e-12)


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
assert(avr.r_Hz == 50 && ~avr.l_staleOdefcn)
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
assert(comp.l_staleOdefcn && other.l_staleOdefcn && ~net.l_staleEquilibrium)
evalc("comp.para_base.Hz = 55;");
assert(net.tab_parameter.base.Hz == 55)


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
