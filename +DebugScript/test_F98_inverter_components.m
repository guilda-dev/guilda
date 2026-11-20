% F98 系統形成 (GFM) と系統追従 (GFL) のインバータ
%
%   component.GFMInverter.VSG_classical ("gfm-vsg-classical"): 古典モデルの発電機の電流を alpha
%   だけ回して母線へ流す VSG。動揺方程式の電力は回す前の電流の仮想電力
%   P~ = Re(V conj(e^{-j alpha} I)) = cos(alpha) P - sin(alpha) Q (Koizumi らの位相補償 VSG)。
%   入力は Pref, Vref で、ローカル制御器は付かない。alpha = 0 なら gen-classical (Static の AVR・調速機つき) と同じに動く。
%   component.GFLInverter.Static ("gfl-static"): load-power と同じ定電力の注入。入力は
%   Pref, Qref (母線へ注入する電力、発電が正)。
%   タグは母線タグ + "GFM" / "GFL" + 番号。潮流計算では GFM は PV、GFL は PQ。
%
% 実行: runtests("DebugScript.test_F98_inverter_components")  または  DebugScript.run_all("Features","F98")

c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)


%% Inverters have their tags, parameters and power-flow settings
bus = PowerNetwork().add_bus();
vsg = bus.add_component("gfm-vsg-classical", "P", 0.5);
gfl = bus.add_component("gfl-static", "P", 0.4, "Q", 0.1);
assert(vsg.s_tag == "B001GFM1" && gfl.s_tag == "B001GFL2", vsg.s_tag + " " + gfl.s_tag)
assert(isa(vsg, "component.GFMInverter.abstract") && ~isa(vsg, "component.generator.abstract"))
assert(isa(gfl, "component.GFLInverter.abstract") && ~isa(gfl, "component.load.abstract"))
assert(isequal(vsg.sv_u, ["Pref";"Vref"]) && isequal(vsg.sv_x, ["delta";"omega"]) && vsg.sv_y == "omega")
assert(isequal(gfl.sv_u, ["Pref";"Qref"]) && isempty(gfl.sv_x) && isempty(gfl.sv_para))
% 既定のパラメータは parameter.csv の 1 行目 (NGT2 の値、alpha = 0)
assert(isequal(vsg.tab_parameter.dynamics{1, ["M","D","Xd","Xq","alpha"]}, [100, 10, 1.7, 1.7, 0]))
% ローカル制御器は付かない
assert(isempty(vsg.a_LocalController) && isempty(gfl.a_LocalController))
% GFM は PV (Q = NaN)、GFL は PQ
assert(vsg.tab_parameter.powerflow.P == 0.5 && isnan(vsg.tab_parameter.powerflow.Q))
assert(isequal(gfl.tab_parameter.powerflow{1, ["P","Q"]}, [0.4, 0.1]))
% OPF の既定のコストは GFM が発電機と同じ 1、GFL が負荷と同じ 0
assert(vsg.tab_parameter.OPF.HP == 1 && vsg.tab_parameter.OPF.fP == 1)
assert(gfl.tab_parameter.OPF.HP == 0 && gfl.tab_parameter.OPF.fP == 0)


%% A VSG reads its parameters by name or table and ignores a Q setting
bus = PowerNetwork().add_bus();
v1 = bus.add_component("gfm-vsg-classical", "parameter", "NGT2");
assert(v1.tab_parameter.dynamics.Xd == 1.7 && v1.tab_parameter.dynamics.alpha == 0)
tab = table(50, 5, 0.3, 0.4, 0.2, VariableNames=["M","D","Xd","Xq","alpha"]);
v2 = bus.add_component("gfm-vsg-classical", "parameter", tab);
assert(isequal(v2.tab_parameter.dynamics{1,:}, tab{1,:}))
% ほかの名前、列の足りない表はエラー
assert(error_id(@() bus.add_component("gfm-vsg-classical", "parameter", "NGT6")) == "GUILDA:Component:UnknownParameter")
assert(error_id(@() bus.add_component("gfm-vsg-classical", "parameter", tab(:, 1:4))) == "GUILDA:Component:MissingParameter")
% Q は無視して警告する (PV)
lastwarn("");
sct_w = warning("off", "GUILDA:Component:GFMInverterQIgnored");
c_w = onCleanup(@() warning(sct_w));
v3 = bus.add_component("gfm-vsg-classical", "Q", 0.2);
[~, s_id] = lastwarn();
clear c_w
assert(s_id == "GUILDA:Component:GFMInverterQIgnored" && isnan(v3.tab_parameter.powerflow.Q), s_id)


%% The analytic Jacobians of a rotated VSG match finite differences
[~, vsg] = build_net("gfm-vsg-classical", "gfl-static", 0.3);
p  = vsg.tab_parameter.dynamics{1, vsg.sv_para};
f0 = vsg.get_Hz();
sct_rng = rng;
c_rng = onCleanup(@() rng(sct_rng));   % 乱数の状態を元へ戻す
rng(3);
gen = PowerNetwork().add_bus().add_component("gen-classical");
for k = 1:5
    x = [2*rand - 1; 0.1*randn];
    V = [0.9 + 0.2*rand; 0.4*randn];
    u = [rand; 1 + rand];
    [Axx, Bxv, Bxu] = vsg.Jacobi_dx(0, x, V, u, p, f0);
    [Cix, Div, Diu] = vsg.Jacobi_I(0, x, V, u, p, f0);
    f_dx = @(x, V, u) vsg.fcn_dx(0, x, V, u, p, f0);
    f_I  = @(x, V, u) [1; 0]*real(vsg.fcn_I(0, x, V, u, p, f0)) + [0; 1]*imag(vsg.fcn_I(0, x, V, u, p, f0));
    assert(norm(Axx - fd(@(z) f_dx(z, V, u), x)) < 1e-6 && norm(Bxv - fd(@(z) f_dx(x, z, u), V)) < 1e-6 ...
        && norm(Bxu - fd(@(z) f_dx(x, V, z), u)) < 1e-6, "Jacobi_dx at point %d", k)
    assert(norm(Cix - fd(@(z) f_I(z, V, u), x)) < 1e-6 && norm(Div - fd(@(z) f_I(x, z, u), V)) < 1e-6 ...
        && norm(Diu - fd(@(z) f_I(x, V, z), u)) < 1e-6, "Jacobi_I at point %d", k)
    % 動揺方程式の電力は回す前の電流の仮想電力 P~ = Re(V conj(e^{-j alpha} I))
    c_V = [1, 1j]*V;
    c_I = vsg.fcn_I(0, x, V, u, p, f0);
    dx = f_dx(x, V, u);
    assert(abs(dx(2) - (-p(2)*x(2) - real(c_V*conj(exp(-1j*p(5))*c_I)) + u(1))) < 1e-12)
    % getCompPQ は母線へ注入する電力
    assert(norm(vsg.getCompPQ(x, [abs(c_V); angle(c_V)], u, p) - [real(c_V*conj(c_I)); imag(c_V*conj(c_I))]) < 1e-12)
    % 回転の前の電流は古典モデルの電流
    assert(abs(c_I - exp(1j*p(5))*gen.fcn_I(0, x, V, u, p(1:4), f0)) < 1e-12)
end


%% A rotated VSG and a GFL inverter are at the equilibrium after initialize
[net, vsg, gfl] = build_net("gfm-vsg-classical", "gfl-static", 0.3);
DebugScript.helper.quiet(@() net.initialize);
for comp = {vsg, gfl}
    [r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp{1});
    assert(r_dx < 1e-10 && r_I < 1e-10, "%s: dx %g, I %g", comp{1}.s_tag, r_dx, r_I)
    assert(isempty(DebugScript.helper.check_model_contract(comp{1})), "%s", ...
        join(DebugScript.helper.check_model_contract(comp{1}), newline))
    assert(DebugScript.helper.jacobian_error(comp{1}) < 1e-6, comp{1}.s_tag)
end
% Pref は平衡点の仮想電力 P~ = cos(alpha) P - sin(alpha) Q、omega = 0。母線の P は潮流計算の値
c_S = vsg.c_Vequilibrium*conj(vsg.c_Iequilibrium);
r_al = vsg.tab_parameter.dynamics.alpha;
assert(abs(vsg.rv_Uequilibrium(1) - (cos(r_al)*real(c_S) - sin(r_al)*imag(c_S))) < 1e-12 && vsg.rv_Xequilibrium(2) == 0)
assert(abs(real(c_S) - 0.5) < 1e-8 && abs(vsg.rv_Uequilibrium(1) - real(c_S)) > 1e-3)
% GFL の入力は潮流計算の P, Q (発電が正)
assert(norm(gfl.rv_Uequilibrium - [0.3; 0.05]) < 1e-10)
% 外乱がなければ平衡点にとどまり、事故も最後まで計算できる
sol = net.simulate(DebugScript.helper.no_disturbance(net), Time=[0, 2]);
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)
sc = net.add_scenario("fault");
sc.add_fault("B003", [0.5, 0.55]);
[~, flag] = net.simulate("fault", Time=[0, 2]);
assert(flag == 1)


%% A VSG with alpha 0 behaves as gen-classical
[r_v, net_v] = fault_run("gfm-vsg-classical", "load-power", 0);
[r_c, net_c] = fault_run("gen-classical", "load-power", 0);
t = [0.5, 1.02, 1.5, 2.5];
assert(max(abs(sample(r_v.Bus(2).Component(1).X, r_v.t, t) - sample(r_c.Bus(2).Component(1).X, r_c.t, t)), [], "all") < 1e-6)
for b = 1:3
    assert(max(abs(sample(r_v.Bus(b).V, r_v.t, t) - sample(r_c.Bus(b).V, r_c.t, t)), [], "all") < 1e-6, "B%d", b)
end
assert(max(abs(r_v.Bus(2).Component(1).X.omega)) > 1e-4)   % 事故で動いている
% 線形化の固有値も同じ
assert(DebugScript.helper.same_eigs(DebugScript.helper.finite_eigs(net_v.get_sys("Type", "ODE")), ...
                                    DebugScript.helper.finite_eigs(net_c.get_sys("Type", "ODE")), 1e-6))
% エネルギー関数の Hessian も同じ (対称)
H_v = net_v.a_Bus{2}.a_Component{1}.get_hessian();
H_c = net_c.a_Bus{2}.a_Component{1}.get_hessian();
for s = ["Hxx","Hxv","Hvx","Hvv","R"]
    assert(norm(H_v.(s) - H_c.(s)) < 1e-9, s)
end
H = [H_v.Hxx, H_v.Hxv; H_v.Hvx, H_v.Hvv];
assert(norm(H - H.') < 1e-9)


%% The blocks of get_hessian of a rotated VSG are the Jacobians of the model
[net, vsg] = build_net("gfm-vsg-classical", "gfl-static", 0.3);
DebugScript.helper.quiet(@() net.initialize);
x = vsg.rv_Xequilibrium + [0.05; 0.01];
u = vsg.rv_Uequilibrium;
p = vsg.tab_parameter.dynamics{1, vsg.sv_para};
f0 = vsg.get_Hz();
c_V0 = vsg.c_Vequilibrium * 0.98;
H = vsg.get_hessian(x, [real(c_V0); imag(c_V0)], u);
% z = [x; theta; |V|] の関数としての状態方程式と w_dev = -[P; Q/|V|]
rect = @(z) [z(end)*cos(z(end-1)); z(end)*sin(z(end-1))];
f_x = @(z) vsg.fcn_Mass(0, z(1:2), rect(z), u, p, f0) \ vsg.fcn_dx(0, z(1:2), rect(z), u, p, f0);
S   = @(z) ([1, 1j]*rect(z)) * conj(vsg.fcn_I(0, z(1:2), rect(z), u, p, f0));
f_w = @(z) -[real(S(z)); imag(S(z))/z(end)];
z0 = [x; angle(c_V0); abs(c_V0)];
assert(norm(-H.R*[H.Hxx, H.Hxv] - fd(f_x, z0)) < 1e-6)
assert(norm([H.Hvx, H.Hvv] - fd(f_w, z0)) < 1e-6)
assert(norm(H.Hxv - H.Hvx.') > 1e-3)   % alpha ≠ 0 では対称でない
% 状態の行は古典モデルの発電機と同じ (動揺方程式は回す前の電流の仮想電力): Hxx は対称
gen = PowerNetwork().add_bus().add_component("gen-classical");
gen.tab_parameter.dynamics{1, gen.sv_para} = p(1:4);
f_g = @(z) gen.fcn_Mass(0, z(1:2), rect(z), u, p(1:4), f0) \ gen.fcn_dx(0, z(1:2), rect(z), u, p(1:4), f0);
assert(norm(fd(f_x, z0) - fd(f_g, z0)) < 1e-6 && norm(H.Hxx - H.Hxx.') < 1e-12)


%% The Hessian form of lossy VSG networks gives the eigenvalues of get_sys
% 線路に抵抗がある網 (build_net) で、alpha = 0 と alpha = 0.3 (位相補償) の VSG と、すべての線路の
% インピーダンス角を alpha にそろえた網。エネルギー関数の形式 E_h dz/dt = H z の固有値と、
% それによる安定の判定 (最大実部の符号) が記述子形式の get_sys と一致すること (0 の固有値は数値誤差 1e-7 程度)
for r_al = [0, 0.3]
    for l_uniform = [false, true]
        net = build_net("gfm-vsg-classical", "gfl-static", r_al);
        if l_uniform
            for k = 1:numel(net.a_Branch)
                tp = net.a_Branch{k}.tab_parameter.dynamics;
                r_z = abs(tp.R + 1j*tp.X);
                net.a_Branch{k}.tab_parameter.dynamics.R = r_z*sin(max(r_al, 0.1));
                net.a_Branch{k}.tab_parameter.dynamics.X = r_z*cos(max(r_al, 0.1));
            end
        end
        DebugScript.helper.quiet(@() net.initialize);
        resD = net.get_sys(Type="DAE", Port="PI");
        resH = net.get_sys(Type="DAE", Port="PI", Form="hessian");
        assert(resH.rv_asymmetry > 1e-3, "線路の損失で非対称")
        sD = resD.get_ss("DAE", Format="struct");
        sH = resH.get_ss("DAE", Form="hessian", Format="struct");
        eD = DebugScript.helper.finite_eigs(sD);
        eH = DebugScript.helper.finite_eigs(sH);
        assert(DebugScript.helper.same_eigs(eH, eD, 1e-6), "alpha %g, uniform %d", r_al, l_uniform)
        eS = DebugScript.helper.finite_eigs(net.get_sys(Type="ODE"));
        assert(DebugScript.helper.same_eigs(eS, eD, 1e-6), "alpha %g, uniform %d (ODE)", r_al, l_uniform)
        % 0 の固有値 (位相の回転) を除く最大実部で判定する
        [~, k0] = min(abs(eD));  eD(k0) = [];
        [~, k0] = min(abs(eH));  eH(k0) = [];
        assert((max(real(eH)) < 0) == (max(real(eD)) < 0) && max(real(eD)) < 0, "alpha %g, uniform %d", r_al, l_uniform)
    end
end


%% A GFL inverter behaves as load-power with the same injection
[r_g, net_g] = fault_run("gfm-vsg-classical", "gfl-static", 0);
[r_l, net_l] = fault_run("gfm-vsg-classical", "load-power", 0);
t = [0.5, 1.02, 1.5, 2.5];
for b = 1:3
    assert(max(abs(sample(r_g.Bus(b).V, r_g.t, t) - sample(r_l.Bus(b).V, r_l.t, t)), [], "all") < 1e-6, "B%d", b)
end
gfl = net_g.a_Bus{3}.a_Component{2};
ld  = net_l.a_Bus{3}.a_Component{2};
assert(norm(gfl.rv_Uequilibrium - ld.rv_Uequilibrium) < 1e-12)
H_g = gfl.get_hessian();
H_l = ld.get_hessian();
assert(norm(H_g.Hvv - H_l.Hvv) < 1e-12)
% 入力 Pref の段階変化は Pload の段階変化と同じ (どちらも母線へ注入する電力)
r = cell(1, 2);
for k = 1:2
    net = {net_g, net_l};
    net = net{k};
    comp = net.a_Bus{3}.a_Component{2};
    sc = net.add_scenario("in");
    sc.add_input(comp.s_tag, comp.sv_u(1), 0.05, [0.5, 1.5]);
    r{k} = net.simulate("in", Time=[0, 2]).odeResults;
end
X = cellfun(@(o) sample(o.Bus(2).Component(1).X, o.t, [0.4, 1.0, 1.8]), r, "UniformOutput", false);
assert(max(abs(X{1} - X{2}), [], "all") < 1e-6 && max(abs(X{1}(2,:) - X{1}(1,:))) > 1e-4)


function [net, comp2, comp3] = build_net(key2, key3, alpha)
    % B001: gen-park (slack) -- B002: key2 (P = 0.5, PV) -- B003: load-power と key3 (P = 0.3, Q = 0.05)
    [net, comp2] = DebugScript.helper.build_3bus("gen-classical");
    net.a_Bus{2}.remove_component(comp2.s_tag);
    comp2 = net.a_Bus{2}.add_component(key2, "P", 0.5, "Q", nan);
    if ismember("alpha", comp2.sv_para)
        comp2.tab_parameter.dynamics.alpha = alpha;
    end
    comp3 = net.a_Bus{3}.add_component(key3, "P", 0.3, "Q", 0.05);
end

function [r, net] = fault_run(key2, key3, alpha)
    % build_net の系統で B003 に 1 s から 0.05 s の地絡
    net = build_net(key2, key3, alpha);
    DebugScript.helper.quiet(@() net.initialize);
    sc = net.add_scenario("fault");
    sc.add_fault("B003", [1, 1.05]);
    r = net.simulate("fault", Time=[0, 3]).odeResults;
end

function X = sample(tab, rv_t, t)
    % 表 tab の値を時刻 t で補間する (2 つの区間の境の時刻は後の値)
    [t_u, iv] = unique(rv_t, "last");
    X = interp1(t_u, tab{iv, :}, t(:));
end

function J = fd(f, z)
    % 中心差分のヤコビアン
    h = 1e-6;
    f0 = f(z);
    J = zeros(numel(f0), numel(z));
    for i = 1:numel(z)
        e = zeros(size(z));
        e(i) = h;
        J(:, i) = (f(z + e) - f(z - e)) / (2*h);
    end
end

function s_id = error_id(fcn)
    % fcn のエラーの ID ("" ならエラーなし)
    s_id = "";
    try
        fcn();
    catch ME
        s_id = string(DebugScript.helper.msg_id(ME));
    end
end
