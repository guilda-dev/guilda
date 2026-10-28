% F3 編集後の解析 (編集の扱い)
%
% パラメータや構成を編集しても値が変わるだけで、何かが古くなったことを記録する。
%   dynamics / base(Hz) の編集 → 関数ハンドル f_* と平衡点が古くなる
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


%% Base Hz edit makes handles and equilibrium stale
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
comp.tab_parameter.base.Hz = 50;
assert(comp.l_staleOdefcn && net.l_staleEquilibrium)

DebugScript.helper.quiet(@() net.initialize);
x = comp.rv_Xequilibrium;  x(comp.sv_x == "omega") = 0.01;
V = comp.c_Vequilibrium;  I = comp.c_Iequilibrium;
para = comp.tab_parameter.dynamics{:, comp.sv_para};
dx_used = comp.f_dx(0, x, [real(V);imag(V)], [real(I);imag(I)], comp.rv_Uequilibrium);
dx_new  = comp.fcn_dx(0, x, [real(V);imag(V)], [real(I);imag(I)], comp.rv_Uequilibrium, para, 50);
assert(norm(dx_used - dx_new) < 1e-12, "f_dx が変更前の Hz を使っている")


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
