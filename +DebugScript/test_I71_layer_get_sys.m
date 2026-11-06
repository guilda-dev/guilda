% I71 層別 get_sys と連続型潮流計算の編集の検査
%
% comp / bus / con / gc の get_sys と net.calculate_continuation_powerflow は、古いハンドルで結果を返さない。
%   - 系統に属する層は、平衡点を使うとき系統と自分 (と使う下の層) の sct_stale を確認し、古いもの
%     (平衡点・ハンドル・周波数) があれば net.initialize() を促す層ごとのエラーにする。何も作り直さない
%   - Point を指定した comp / bus の get_sys は平衡点を使わないので確認しない
%   - net に接続されていない層は確認を省略し、古いハンドルだけを作る
%
% 実行: runtests("DebugScript.test_I71_layer_get_sys")  または  DebugScript.run_all("Features","I71")

% 共通設定 (各テストの前に毎回実行される)
sr_load     = ["B009","B010","B011","B012","B013","B014"];


%% Layer get_sys before initialize asks for initialize
[net, ~] = build_with_controllers();
[gen, bus, avr, pss] = layers(net);
assert_stale_error(@() gen.get_sys(), "GUILDA:Component:Stale")
assert_stale_error(@() bus.get_sys(), "GUILDA:Bus:Stale")
assert_stale_error(@() avr.get_sys(), "GUILDA:LocalController:Stale")
assert_stale_error(@() pss.get_sys(), "GUILDA:LocalController:Stale")


%% Layer get_sys after a dynamics edit asks for initialize
[net, ~] = build_with_controllers();
DebugScript.helper.quiet(@() net.initialize);
[gen, bus, avr, pss] = layers(net);
gen.tab_parameter.dynamics.D = 3 * gen.tab_parameter.dynamics.D;
assert(DebugScript.helper.is_stale(net))
assert_stale_error(@() gen.get_sys(), "GUILDA:Component:Stale")
assert_stale_error(@() gen.get_sys("port", "I2V"), "GUILDA:Component:Stale")
assert_stale_error(@() bus.get_sys(), "GUILDA:Bus:Stale")
% 制御器の get_sys は系統と自分のタグだけを見るので、機器の編集では止まらない
avr.get_sys();
pss.get_sys();

% 位置引数で点を与えても制御器は平衡点で線形化するのでエラーのまま
x = gen.rv_Xequilibrium;  V = [real(gen.c_Vequilibrium); imag(gen.c_Vequilibrium)];
I = [real(gen.c_Iequilibrium); imag(gen.c_Iequilibrium)];  u = gen.rv_Uequilibrium;
assert_stale_error(@() gen.get_sys(x, V, I, u), "GUILDA:Component:Stale")

% 失敗した net.get_sys の後も下位層の答えは変わらない (エラーのまま)
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert_stale_error(@() gen.get_sys(), "GUILDA:Component:Stale")
assert_stale_error(@() bus.get_sys(), "GUILDA:Bus:Stale")


%% Layer get_sys after initialize uses the edited model
[net, ~] = build_with_controllers();
DebugScript.helper.quiet(@() net.initialize);
[gen, bus] = layers(net);
A0 = gen.get_sys().A;
gen.tab_parameter.dynamics.D = 3 * gen.tab_parameter.dynamics.D;
DebugScript.helper.quiet(@() net.initialize);
assert(~isequal(gen.get_sys().A, A0))
assert(size(bus.get_sys().A, 1) == size(gen.get_sys().A, 1))

% 同じ D で作った系統と一致する
[ref, ~] = build_with_controllers();
[gen_ref, ~] = layers(ref);
gen_ref.tab_parameter.dynamics.D = gen.tab_parameter.dynamics.D;
DebugScript.helper.quiet(@() ref.initialize);
assert(norm(gen.get_sys().A - gen_ref.get_sys().A) < 1e-9)


%% A network Hz edit asks for initialize, which only rebuilds the handles
% Hz の編集は平衡点を変えないが、ハンドルは古いのでエラーになる。initialize はハンドルだけを作り直す
[net, ~] = build_with_controllers();
DebugScript.helper.quiet(@() net.initialize);
[gen, bus, avr, pss] = layers(net);
A_gen = gen.get_sys().A;  A_bus = bus.get_sys().A;
Hz0 = net.para_base.Hz;
net.para_base.Hz = 2 * Hz0;
assert(DebugScript.helper.is_stale(net) && isempty(net.sct_stale.powerflow) && DebugScript.helper.handle_Hz(gen) == Hz0)
assert_stale_error(@() gen.get_sys(), "GUILDA:Component:Stale")
assert_stale_error(@() bus.get_sys(), "GUILDA:Bus:Stale")
assert_stale_error(@() avr.get_sys(), "GUILDA:LocalController:Stale")
assert(DebugScript.helper.handle_Hz(gen) == Hz0)

res = DebugScript.helper.quiet(@() net.initialize);
assert(res.s_solver == "equilibrium")
A_gen2 = gen.get_sys().A;
assert(DebugScript.helper.handle_Hz(avr) == net.para_base.Hz && DebugScript.helper.handle_Hz(pss) == net.para_base.Hz)
assert(DebugScript.helper.handle_Hz(gen) == net.para_base.Hz && ~isequal(A_gen2, A_gen))
assert(~isequal(bus.get_sys().A, A_bus))

[ref, ~] = build_with_controllers();
ref.para_base.Hz = net.para_base.Hz;
DebugScript.helper.quiet(@() ref.initialize);
[gen_ref, bus_ref] = layers(ref);
assert(norm(A_gen2 - gen_ref.get_sys().A) < 1e-9)
assert(norm(bus.get_sys().A - bus_ref.get_sys().A) < 1e-9)


%% Point skips the check and keeps the handles until initialize
[net, ~] = build_with_controllers();
DebugScript.helper.quiet(@() net.initialize);
[gen, bus] = layers(net);
[~, c_idx] = bus.get_variable_map();
rv_point = SolverLIN.point_vector(bus, []);
A0 = gen.get_sys("Point", rv_point(c_idx{1})).A;
A0_bus = bus.get_sys("Point", rv_point).A;

gen.tab_parameter.dynamics.D = 3 * gen.tab_parameter.dynamics.D;
assert(DebugScript.helper.is_stale(net))
% Point を指定すると確認せず、initialize までは以前のハンドルのまま
assert(isequal(gen.get_sys("Point", rv_point(c_idx{1})).A, A0))
assert(isequal(bus.get_sys("Point", rv_point).A, A0_bus))
DebugScript.helper.quiet(@() net.initialize);
A1 = gen.get_sys("Point", rv_point(c_idx{1})).A;
assert(~isequal(A1, A0))
assert(~isequal(bus.get_sys("Point", rv_point).A, A0_bus))


%% Layers without a network skip the equilibrium check
avr = controller.avr.AVR_ST1("avr1");
assert(~isequal(error_id(@() avr.get_sys()), "GUILDA:LocalController:Stale"))


%% Global controller get_sys checks edits
[net, gc] = build_with_agc();
assert_stale_error(@() gc.get_sys(), "GUILDA:GlobalController:Stale")

DebugScript.helper.quiet(@() net.initialize);
sys0 = gc.get_sys();
h_dx = gc.f_dx;
gc.para_dynamics.kI = 2 * gc.para_dynamics.kI;
assert(isequal(h_dx, gc.f_dx) && DebugScript.helper.is_stale(net))
assert_stale_error(@() gc.get_sys(), "GUILDA:GlobalController:Stale")
assert_stale_error(@() gc.get_sys(gc.rv_Xequilibrium, zeros(2,1), zeros(2,1), gc.rv_Uequilibrium), "GUILDA:GlobalController:Stale")
assert(isequal(h_dx, gc.f_dx))       % 確認は作り直さない

% 失敗した net.get_sys の後もエラーのまま
assert_stale_error(@() net.get_sys(), "GUILDA:SolverLIN:Stale")
assert_stale_error(@() gc.get_sys(), "GUILDA:GlobalController:Stale")

% initialize の後は編集後のモデルで、同じ kI で作った系統と一致する
DebugScript.helper.quiet(@() net.initialize);
sys1 = gc.get_sys();
assert(~isequal(ssdata_all(sys1), ssdata_all(sys0)))
[ref, gc_ref] = build_with_agc();
gc_ref.para_dynamics.kI = gc.para_dynamics.kI;
DebugScript.helper.quiet(@() ref.initialize);
assert(norm(ssdata_all(sys1) - ssdata_all(gc_ref.get_sys())) < 1e-9)


%% Global controller handles follow a network Hz edit
[net, gc] = build_with_agc();
DebugScript.helper.quiet(@() net.initialize);
Hz0 = net.para_base.Hz;
net.para_base.Hz = 2 * Hz0;
assert(DebugScript.helper.handle_Hz(gc) == Hz0 && DebugScript.helper.is_stale(net))
assert_stale_error(@() gc.get_sys(), "GUILDA:GlobalController:Stale")
DebugScript.helper.quiet(@() net.initialize);
assert(DebugScript.helper.handle_Hz(gc) == net.para_base.Hz)
gc.get_sys();


%% Initialize of a controller that designs with get_sys still passes
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");     % B002 (1.02 pu): V0 = 1 と異なる母線
gen.add_local_controller(controller.avr.AVR_ST1("avr1"));
gen.add_local_controller(controller.local_LQR("lqr1"));
DebugScript.helper.quiet(@() net.initialize);
assert(size(gen.get_sys().A, 1) >= numel(gen.sv_x))


%% CPF after a dynamics edit asks for initialize
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
gen = net.a_Bus{1}.a_Component{1};
h_dx = gen.f_dx;
gen.tab_parameter.dynamics.D = 3 * gen.tab_parameter.dynamics.D;
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=sr_load)) == "GUILDA:SolverCPF:Stale")
assert(isequal(h_dx, gen.f_dx))      % 確認は作り直さない


%% CPF after a network Hz edit and initialize keeps the path
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
gen = net.a_Bus{1}.a_Component{1};
res0 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));
Hz0 = net.para_base.Hz;
net.para_base.Hz = 2 * Hz0;
assert(DebugScript.helper.handle_Hz(gen) == Hz0 && DebugScript.helper.is_stale(net))
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=sr_load)) == "GUILDA:SolverCPF:Stale")
DebugScript.helper.quiet(@() net.initialize);
res1 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));
assert(DebugScript.helper.handle_Hz(gen) == net.para_base.Hz)
assert(isequal(res1.rv_lambda, res0.rv_lambda) && isequal(res1.cm_Vbus, res0.cm_Vbus))


% ローカル関数
function [net, gen] = build_with_controllers()
% B001 の発電機に AVR と、その下に PSS を付けた 3 母線系統
    [net, ~] = DebugScript.helper.build_3bus("gen-1axis");
    gen = net.a_Bus{1}.a_Component{1};
    gen.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
end

function [net, gc] = build_with_agc()
% B001 の発電機を制御する AGC を付けた 3 母線系統
    [net, ~] = DebugScript.helper.build_3bus("gen-1axis");
    net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", string(net.a_Bus{1}.a_Component{1}), alpha=1, beta=1));
    gc = net.a_GlobalController{1};
end

function v = ssdata_all(sys)
% 状態方程式の行列をまとめた列ベクトル
    [A, B, C, D, E] = dssdata(sys);
    v = [A(:); B(:); C(:); D(:); E(:)];
end

function [gen, bus, avr, pss] = layers(net)
    bus = net.a_Bus{1};
    gen = bus.a_Component{1};
    avr = gen.a_LocalController{1};
    pss = avr.a_LocalController{1};
end

function assert_stale_error(fcn, s_id)
% fcn が平衡点の古さを知らせるエラー (net.initialize() を促す) になることを確認する
    try
        DebugScript.helper.quiet(fcn);
    catch ME
        assert(DebugScript.helper.msg_id(ME) == s_id, "想定外のエラー: " + DebugScript.helper.msg_id(ME) + " " + ME.message)
        assert(contains(ME.message, "net.initialize()"))
        return
    end
    error("DebugScript:noError", "平衡点が古いのにエラーにならない")
end

function id = error_id(fcn)
    id = "";
    try
        DebugScript.helper.quiet(fcn);
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
    end
end
