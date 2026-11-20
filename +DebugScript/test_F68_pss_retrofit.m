% F68 Retrofit 制御の PSS (controller.pss.Retrofit, キー pss-retrofit)
%
%   教科書 5.4 節の式 (5.42) を次の形に書き直したもの。x は発電機の全状態、x̂ は Retrofit の状態。
%     E x̂' = f(x, V, u*) − A_d (x − x̂)
%     Vpss = −K (x − x̂)          (K = lqr(E\A_d, E\B, Q, R)、V と u を平衡点に固定した発電機単体)
%   Static の AVR (Vfield = Vfd_ref + Vpss) の下にだけ付く。e = x − x̂ は E ė = (A_d − B K) e に
%   厳密に従うので、平衡点は動かず、線形化の固有値は分離し、V から入る外乱では Vpss = 0。
%
% 実行: runtests("DebugScript.test_F68_pss_retrofit")  または  DebugScript.run_all("Features","F68")

%% Retrofit goes under the Static AVR with the key, role, states and default weights
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
assert(gen.avr.key == "avr-static")
con = gen.add_local_controller("pss-retrofit");
assert(isa(con, "controller.pss.Retrofit") && gen.pss == con && con.a_Component == gen.avr)
assert(con.key == "pss-retrofit" && con.s_role == "pss" && startsWith(con.s_tag, gen.s_tag + "CP"))
assert(isequal(con.sv_x, "hat_" + gen.sv_x(:)) && isequal(con.sv_u, gen.sv_x(:)) && con.sv_y == "Vpss")
assert(isempty(con.sv_para) && isempty(con.Q) && isempty(con.R))
con2 = DebugScript.helper.quiet(@() gen.set_pss("pss-retrofit", parameter=struct(Q=[1 2 3], R=0.5)));
assert(isequal(con2.Q, diag([1 2 3])) && con2.R == 0.5)

%% The equilibrium does not move, Vpss is 0 there and K is the LQR of the generator alone
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
x0 = gen.rv_Xequilibrium;  u0 = gen.rv_Uequilibrium;
con = gen.add_local_controller("pss-retrofit");
assert(DebugScript.helper.is_stale(net))
DebugScript.helper.quiet(@() net.initialize);
assert(max(abs(gen.rv_Xequilibrium - x0)) < 1e-10 && max(abs(gen.rv_Uequilibrium - u0)) < 1e-10)
assert(isequal(con.rv_Xequilibrium, gen.rv_Xequilibrium) && isequal(con.rv_Uequilibrium, gen.rv_Xequilibrium))
assert(con.f_Y(0, con.rv_Xequilibrium, [0;0], con.rv_Uequilibrium) == 0)
assert(max(abs(con.f_dx(0, con.rv_Xequilibrium, V_of(gen), con.rv_Uequilibrium))) < 1e-10)
[A_d, B, E] = design_model(gen);
assert(max(abs(con.K - lqr(E\A_d, E\B, eye(3), 1)), [], "all") < 1e-10)
assert(isa(con.sys_design, "ss") && max(abs(con.sys_design.A - E\A_d), [], "all") < 1e-12)
% 重みの編集は平衡点と関数を古くし、initialize で K を設計し直す
K1 = con.K;
con.R = 0.01;
assert(DebugScript.helper.is_stale(net))
DebugScript.helper.quiet(@() net.initialize);
assert(norm(con.K - lqr(E\A_d, E\B, eye(3), 0.01)) < 1e-8 && norm(con.K - K1) > 1e-3)
% 系統の周波数を変えると、平衡点はそのままで、initialize が関数を作り直して K を設計し直す
K2 = con.K;
net.tab_parameter.base.Hz = 50;
DebugScript.helper.quiet(@() net.initialize);
[A_d, B, E] = design_model(gen);
assert(DebugScript.helper.handle_Hz(con) == 50 && norm(con.K - K2) > 1e-3)
assert(norm(con.K - lqr(E\A_d, E\B, eye(3), 0.01)) < 1e-8)

%% The eigenvalues are those without Retrofit and those of E\(A_d - B K)
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
res0 = DebugScript.helper.quiet(@() net.get_sys());
con = gen.add_local_controller("pss-retrofit", parameter=struct(R=0.1));
DebugScript.helper.quiet(@() net.initialize);
res1 = DebugScript.helper.quiet(@() net.get_sys());
[A_d, B, E] = design_model(gen);
e_sep = [DebugScript.helper.finite_eigs(res0); eig(E\(A_d - B*con.K))];
assert(DebugScript.helper.same_eigs(DebugScript.helper.finite_eigs(res1), e_sep, 1e-8))

%% An offset of its own state drives Vpss and returns faster; a distant fault leaves Vpss at 0
% IEEE9bus の B002 の発電機を Static の AVR にして比べる (ほかの発電機は AVR_ST1 と PSS1 のまま)
sol = cell(1,2);
for k = 1:2
    net = network.IEEE9bus();
    gen = net.a_Bus{2}.a_Component{1};
    DebugScript.helper.quiet(@() gen.remove_local_controller(gen.avr.s_tag, RemoveNested=true));
    gen.add_local_controller("avr-static");
    if k == 2
        con = gen.add_local_controller("pss-retrofit", parameter=struct(R=0.01));
    end
    DebugScript.helper.quiet(@() net.initialize);
    sc = net.add_scenario("kick", Time=[0 5]);
    sc.add_offset(gen.s_tag, "Eq", 0.1, 0);
    sol{k} = DebugScript.helper.quiet(@() net.simulate("kick"));
    assert(sol{k}.l_success)
end
dev = cellfun(@(s) deviation(s, gen), sol);       % 回転速度と内部電圧のずれの大きさ (t = 1 s 以降の最大)
assert(dev(2) < 0.5*dev(1), "Retrofit で戻りが速くならない: %g vs %g", dev(2), dev(1))
Vpss = output_of(sol{2}, con, "Vpss");
assert(max(abs(Vpss)) > 1e-3)
% 誤差 e = x - x̂ は線形の式 E ė = (A_d - B K) e に従う
[A_d, B, E] = design_model(gen);
e = state_of(sol{2}, gen) - state_of(sol{2}, con);
t = sol{2}.rv_t;
e_lin = cell2mat(arrayfun(@(s) (expm((E\(A_d - B*con.K))*s)*e(1,:).').', t, 'UniformOutput', false));
assert(max(abs(e - e_lin), [], "all") < 1e-3)
% 遠くの母線の地絡は V から入るので、Vpss はソルバーの許容誤差の程度
sc = net.add_scenario("fault", Time=[0 3]);
sc.add_fault("B005", [0.5 0.55]);
solf = DebugScript.helper.quiet(@() net.simulate("fault"));
assert(solf.l_success && max(abs(output_of(solf, con, "Vpss"))) < 1e-8)

%% Under ST1 or DC1 it is rejected and the generator keeps its old PSS
for s_avr = ["avr-ST1", "avr-DC1"]
    [~, gen] = DebugScript.helper.build_3bus("gen-1axis");
    avr = gen.add_local_controller(s_avr);
    pss = gen.add_local_controller("pss-PSS1");
    ME = caught(@() gen.add_local_controller("pss-retrofit"));
    assert(ME.identifier == "GUILDA:Retrofit:ParentNotStatic", ME.identifier)
    assert(isvalid(avr) && isvalid(pss) && gen.avr == avr && gen.pss == pss && pss.a_Component == avr)
    assert(numel(gen.a_LocalController) == 2 && isscalar(avr.a_LocalController))
end

%% set_avr on a generator with Retrofit is rejected and leaves it as it was
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
con = gen.add_local_controller("pss-retrofit");
avr = gen.avr;
DebugScript.helper.quiet(@() net.initialize);
ME = caught(@() gen.set_avr("avr-ST1"));
assert(ME.identifier == "GUILDA:Retrofit:ParentNotStatic", ME.identifier)
assert(isvalid(avr) && isvalid(con) && gen.avr == avr && gen.pss == con && con.a_Component == avr)
assert(~DebugScript.helper.is_stale(net))
% local の制御器 (local-LQR) への置き換えは PSS を消すので、エラーにならず Retrofit も消える
[~, gen2] = DebugScript.helper.build_3bus("gen-1axis");
con2 = gen2.add_local_controller("pss-retrofit");
lqr2 = DebugScript.helper.quiet(@() gen2.add_local_controller("local-LQR", parameter=struct(Input="Vfield")));
assert(~isvalid(con2) && isempty(gen2.pss) && gen2.a_LocalController{1} == lqr2)
% 先に Retrofit を外せば AVR を替えられる
gen.remove_local_controller(con.s_tag);
gen.set_avr("avr-ST1");
assert(gen.avr.key == "avr-ST1" && isempty(gen.pss))

%% The base driven_inputs gives sv_y for PSS1, under any AVR
% add_local_controller が事前に呼ぶ driven_inputs は、PSS1 では今までの sv_y と同じ (振る舞いは変わらない)
for s_avr = ["avr-static", "avr-ST1", "avr-DC1"]
    [~, gen] = DebugScript.helper.build_3bus("gen-1axis");
    if s_avr ~= "avr-static"
        gen.add_local_controller(s_avr);
    end
    pss = gen.add_local_controller("pss-PSS1");
    assert(isequal(pss.driven_inputs(gen.avr), pss.sv_y) && pss.sv_y == "Vpss")
end

%% The Jacobians agree with finite differences
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
con = gen.add_local_controller("pss-retrofit");
DebugScript.helper.quiet(@() net.initialize);
err = DebugScript.helper.jacobian_error(con);
assert(err < 1e-6, "Jacobian の誤差 %g", err)


function [A_d, B, E] = design_model(gen)
% 発電機単体の線形モデル (V と u を平衡点に固定)
    lin = gen.get_linear_matrix(gen.rv_Xequilibrium, V_of(gen), gen.rv_Uequilibrium);
    A_d = lin.A;  E = lin.E;
    B = lin.B(:, 2 + find(gen.sv_u == "Vfield"));
end

function V = V_of(gen)
    V = [real(gen.c_Vequilibrium); imag(gen.c_Vequilibrium)];
end

function X = state_of(sol, obj)
% obj の状態の軌道 (列は sv_x の順)
    tab = sol.tab_variable;
    X = sol.rm_variable(:, tab.Owner == obj.s_tag & tab.Kind == "x");
end

function y = output_of(sol, obj, s_name)
    tab = sol.tab_output;
    y = sol.rm_output(:, tab.Owner == obj.s_tag & tab.Name == s_name);
end

function d = deviation(sol, gen)
% 回転速度と内部電圧の平衡点からのずれの大きさの、t >= 1 s での最大
    X = state_of(sol, gen) - gen.rv_Xequilibrium.';
    d = max(vecnorm(X(sol.rv_t >= 1, 2:3), 2, 2));
end

function ME = caught(fcn)
% fcn を実行してエラーを返す (エラーにならなければ失敗)
    ME = [];
    try
        fcn();
    catch ME
    end
    assert(~isempty(ME), "No error was raised.")
    ME = struct("identifier", string(DebugScript.helper.msg_id(ME)), "message", string(ME.message));
end
