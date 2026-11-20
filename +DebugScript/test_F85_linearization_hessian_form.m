% F85 線形化結果の形式 (ResultLIN.Form: descriptor / absorbed / hessian)
%
%   res = net.get_sys(Form="hessian");     % エネルギー関数の形式 (機器の get_hessian から組み立てる)
%   res.Form = "absorbed";                 % A ... E を E^-1 を掛けた形へ切り替える
%   sct = res.get_ss("DAE", Form="hessian", Port="PQ", Format="struct");
%   res.rv_asymmetry                       % 母線のブロック H = Hvv + Hvv_net の norm(H - H.', "fro")/norm(H, "fro") (断面ごと)
%
% absorbed: 状態の行に E^-1 を掛け、E は状態で単位行列、母線で 0。固有値と伝達関数は descriptor と同じ。
% hessian:  [x; theta; V] (PI) で E_h dz/dt = H z、E_h = -blkdiag(inv(R), 0)、
%           H = [Hxx Hxv; Hvx Hvv + Hvv_net]。descriptor の DAE の行に E_h E^-1 を掛けたものと一致する。
% PQ は PI から dV = V drho, dQ = V d(Q/V) で導く。Tutorial10bus は制御器 (AVR, 調速機, LQR, AGC) と
% droop 機がエネルギー関数をもたないので、制御器を Static に替え、AGC を外し、droop 機を classical に替えた網で確かめる。
%
% 実行: runtests("DebugScript.test_F85_linearization_hessian_form")  または  DebugScript.run_all("Features","F85")

% 共通設定 (最初に 1 回だけ実行され、変数は全テストで共有される)
net = energy_network();
n_x = nnz(net.get_variable_map().Kind == "x");
resD = net.get_sys(Type="DAE", Port="PI");
resH = net.get_sys(Type="DAE", Port="PI", Form="hessian");
sD = resD.get_ss("DAE", Format="struct");
sH = resH.get_ss("DAE", Format="struct");
n_b = numel(net.a_Bus);
r_tol = 1e-10;   % 平衡点での相対誤差 (最大値で正規化)


%% absorbed has the eigenvalues and the transfer function of descriptor
net9 = network.IEEE9bus(LocalController=true);
DebugScript.helper.quiet(@() net9.initialize());
res9 = net9.get_sys();
for s_type = ["ODE", "DAE"]
    sD = res9.get_ss(s_type, Format="struct");
    sA = res9.get_ss(s_type, Form="absorbed", Format="struct");
    % E は時定数をもつ状態で単位行列、時定数 0 の状態 (AVR_ST1 など) と母線で 0
    lv_d = any(sD.E ~= 0, 2);
    assert(any(~lv_d(1:nnz(res9.tab_variable.Kind == "x"))) && isequal(sA.E, diag(double(lv_d))), s_type)
    eD = eig(sD.A, sD.E);  eA = eig(sA.A, sA.E);
    assert(DebugScript.helper.same_eigs(eA(isfinite(eA)), eD(isfinite(eD)), 1e-8), s_type)
    for s = [0.3, 2j, 1+5j]
        GD = sD.C*((s*sD.E - sD.A)\sD.B) + sD.D;
        GA = sA.C*((s*sA.E - sA.A)\sA.B) + sA.D;
        assert(norm(GA - GD) <= 1e-9*max(1, norm(GD)), s_type)
    end
end
% res.Form は A ... E を切り替え、Type と組み合わせられる
res9.Form = "absorbed";
assert(isequal(res9.E, diag(double(any(res9.E ~= 0, 2)))) && isequal(res9.A, res9.get_ss(res9.Type, Form="absorbed", Format="struct").A))
res9.Form = "descriptor";
assert(isequal(res9.A, res9.get_ss(res9.Type, Format="struct").A))
assert(all(isnan(res9.rv_asymmetry)))
% 機器の層の結果 (ポートモデル) も absorbed をもつ (時定数 0 の状態のない発電機)
comp = net.a_Bus{1}.a_Component{1};
sP = comp.get_sys(Format="struct");
sPA = comp.get_sys(Form="absorbed", Format="struct");
assert(isequal(sPA.E, eye(size(sP.E))) && norm(sPA.A - sP.E\sP.A) < 1e-12 && norm(sPA.B - sP.E\sP.B) < 1e-12)


%% hessian is the descriptor DAE Jacobian with the rows scaled at the equilibrium
assert(isequal(sH.StateName, sD.StateName) && isequal(sH.InputName, sD.InputName))
R = -(sH.E(1:n_x,1:n_x) \ eye(n_x));
assert(isequal(sH.E(n_x+1:end,:), zeros(size(sH.E) - [n_x 0])) && isequal(sH.E(:,n_x+1:end), zeros(size(sH.E) - [0 n_x])))
L = blkdiag(sH.E(1:n_x,1:n_x)/sD.E(1:n_x,1:n_x), eye(numel(sD.StateName) - n_x));   % E_h E^-1 on the state rows
J = L*sD.A;
assert(max(abs(sH.A - J), [], "all") < r_tol*max(abs(J), [], "all"), "A: %.1e", max(abs(sH.A - J), [], "all")/max(abs(J), [], "all"))
assert(norm(sH.B - L*sD.B) < 1e-12*max(1, norm(sD.B)) && isequal(sH.C, sD.C) && isequal(sH.D, sD.D))
% 状態の行は dx/dt = -R (Hxx x + Hxv v)、R は機器の R のブロック対角
J_x = sD.E(1:n_x,1:n_x) \ sD.A(1:n_x,:);
assert(max(abs(-R*sH.A(1:n_x,:) - J_x), [], "all") < r_tol*max(abs(J_x), [], "all"))
% 機器の Hxx は対称 (損失は母線の行と列だけ)
Hxx = sH.A(1:n_x,1:n_x);
assert(norm(Hxx - Hxx.', "fro") < 1e-12*norm(Hxx, "fro"))
% 固有値、伝達関数、ODE (母線の変数を消去) も descriptor と同じ。固有値 -0.0896 は条件数 2.5e5
% (condeig) で、行列の差 4e-11 (相対) が 1e-5 程度の差になる
eD = eig(sD.A, sD.E);  eH = eig(sH.A, sH.E);
assert(DebugScript.helper.same_eigs(eH(isfinite(eH)), eD(isfinite(eD)), 1e-4))
for s = [0.3, 2j]
    GD = sD.C*((s*sD.E - sD.A)\sD.B) + sD.D;
    GH = sH.C*((s*sH.E - sH.A)\sH.B) + sH.D;
    % s = 0.3 は条件数の大きい固有値 -0.0896 に近く、差は 1e-7 (相対) 程度になる
    assert(norm(GH - GD) <= 1e-6*max(1, norm(GD)), "%.1e", norm(GH - GD)/norm(GD))
end
oD = resD.get_ss("ODE", Format="struct");
oH = resH.get_ss("ODE", Format="struct");
assert(norm(oH.E + inv(R)) < 1e-12*norm(inv(R)) && norm(oH.E\oH.A - oD.E\oD.A) < 1e-8*norm(oD.E\oD.A))
% res.Form は既定で get_sys の Form、descriptor に戻せる (ヤコビアンも保持する)
assert(resH.Form == "hessian" && isequal(resH.A, sH.A))
resH.Form = "descriptor";
assert(isequal(resH.A, sD.A) && isequal(resH.E, sD.E))
resH.Form = "hessian";


%% PQ is PI with dV = V drho and dQ = V d(Q/V)
sQ  = resH.get_ss("DAE", Port="PQ", Format="struct");
sDQ = resD.get_ss("DAE", Port="PQ", Format="struct");
rv_V = abs(tools.vec2complex(resH.rv_point(resH.tab_variable.Kind == "Vre" | resH.tab_variable.Kind == "Vim")));
T = diag([ones(n_x + n_b, 1); rv_V]);
assert(norm(sQ.A - T*sH.A*T, "fro") < 1e-14*norm(sQ.A, "fro") && isequal(sQ.E, sH.E))
assert(all(startsWith(sQ.StateName(n_x+n_b+1:end), "rho")) && isequal(sQ.StateName, sDQ.StateName))
LQ = blkdiag(sQ.E(1:n_x,1:n_x)/sDQ.E(1:n_x,1:n_x), eye(2*n_b));
JQ = LQ*sDQ.A;
assert(max(abs(sQ.A - JQ), [], "all") < r_tol*max(abs(JQ), [], "all"))
% 対称性は合同変換で保たれる
assert(abs(norm(sQ.A - sQ.A.', "fro") - norm(T*(sH.A - sH.A.')*T, "fro")) < 1e-12*norm(sQ.A, "fro"))


%% Every section has the hessian form
ev = DebugScript.helper.scenario("offset", net, "TimeSpan", 0, "OffsetUnit", "B002SG1", "OffsetState", "delta", "OffsetValue", 0.3);
sim = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=[0, 1.5]));
rv_t = [0.3, 0.8, 1.2];
rSD = net.get_sys({sim, rv_t}, Type="DAE", Port="PQ");
rSH = net.get_sys({sim, rv_t}, Type="DAE", Port="PQ", Form="hessian");
assert(isequal(size(rSH.rv_asymmetry), [1 3]) && all(rSH.rv_asymmetry > 0))
for k = 1:3
    sDk = rSD.get_ss(Index=k, Format="struct");
    sHk = rSH.get_ss(Index=k, Format="struct");
    Lk = blkdiag(sHk.E(1:n_x,1:n_x)/sDk.E(1:n_x,1:n_x), eye(2*n_b));
    Jk = Lk*sDk.A;
    % 収支は積分の許容誤差までしか満たされないので、平衡点より緩い
    assert(max(abs(sHk.A - Jk), [], "all") < 1e-7*max(abs(Jk), [], "all"), "section %d", k)
    rSH.Index = k;
    assert(isequal(rSH.A, sHk.A))
end
sHt = rSH.get_ss(Time=0.79, Format="struct");
assert(isequal(sHt.A, rSH.get_ss(Index=2, Format="struct").A))
assert(contains(rSH.disp_summary(Index="all"), "Form hessian") && contains(rSH.disp_summary(), "asymmetry"))


%% Unsupported devices and Port I stop with an error
% 元の Tutorial10bus は AVR_DC1 などをもつ
n10 = DebugScript.helper.quiet(@() network.Tutorial10bus());
DebugScript.helper.quiet(@() n10.initialize());
c_case = {@() n10.get_sys(Form="hessian"),                         "GUILDA:LocalController:HessianNotSupported"
          @() net.get_sys(Form="hessian", Port="I"),               "GUILDA:PowerSystemModel:HessianPort"
          @() resH.get_ss("DAE", Port="I"),                        "GUILDA:ResultLIN:HessianPort"
          @() resD.get_ss("DAE", Form="hessian"),                  "GUILDA:ResultLIN:NoHessianForm"
          @() set_form(resD, "hessian"),                           "GUILDA:ResultLIN:NoHessianForm"
          @() net.a_Bus{1}.a_Component{1}.get_sys(Form="hessian"), "GUILDA:PowerSystemModel:HessianNetworkOnly"};
% droop 機 (Component) と AGC (GlobalController) も止まる
n10b = energy_network();
n10b.a_Bus{5}.replace_component("B005SG1", "gen-droop");
DebugScript.helper.quiet(@() n10b.initialize());
c_case(end+1,:) = {@() n10b.get_sys(Form="hessian"), "GUILDA:Component:HessianNotSupported"};
n10c = energy_network();
n10c.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
DebugScript.helper.quiet(@() n10c.initialize());
c_case(end+1,:) = {@() n10c.get_sys(Form="hessian"), "GUILDA:GlobalController:HessianNotSupported"};
for k = 1:height(c_case)
    try
        c_case{k,1}();
        error("DebugScript:NoError", "case %d (%s) がエラーにならない", k, c_case{k,2})
    catch ME
        assert(DebugScript.helper.msg_id(ME) == c_case{k,2}, "case %d: %s", k, DebugScript.helper.msg_id(ME))
    end
end
assert(resD.Form == "descriptor")


%% The lossless case is symmetric and the lossy one is not
n14 = network.IEEE14bus_lossless();
DebugScript.helper.quiet(@() n14.initialize());
r14 = n14.get_sys(Type="DAE", Port="PI", Form="hessian");
s14 = r14.get_ss(Format="struct");
assert(r14.rv_asymmetry < 1e-14 && norm(s14.A - s14.A.', "fro") < 1e-14*norm(s14.A, "fro"), "%.1e", r14.rv_asymmetry)
n14x = nnz(r14.tab_variable.Kind == "x");
Hvv = s14.A(n14x+1:end, n14x+1:end);
assert(norm(Hvv - Hvv.', "fro") < 1e-14*norm(Hvv, "fro"))
% Tutorial10bus (損失のある送電線とインピーダンス負荷) は対称でない
% rv_asymmetry は母線のブロック Hvv + Hvv_net の非対称 (Hxx は対称、Hvx = Hxv.')
Hb = sH.A(n_x+1:end, n_x+1:end);
assert(abs(resH.rv_asymmetry - norm(Hb - Hb.', "fro")/norm(Hb, "fro")) < 1e-15 && resH.rv_asymmetry > 0.1, "%.3g", resH.rv_asymmetry)
assert(isequal(sH.A(1:n_x, n_x+1:end), sH.A(n_x+1:end, 1:n_x).'))


function net = energy_network()
% Tutorial10bus の制御器を Static に替え、AGC を外し、droop 機を classical に替えた網
    net = DebugScript.helper.quiet(@() network.Tutorial10bus());
    for k = numel(net.a_GlobalController):-1:1
        net.remove_global_controller(net.a_GlobalController{k}.s_tag);
    end
    for b = 1:4
        g = net.a_Bus{b}.a_Component{1};
        for s_tag = reshape(string(cellfun(@(c) c.s_tag, g.a_LocalController, "UniformOutput", false)), 1, [])
            DebugScript.helper.quiet(@() g.remove_local_controller(s_tag, RemoveNested=true));
        end
        DebugScript.helper.quiet(@() g.set_avr("avr-static"));
        DebugScript.helper.quiet(@() g.set_governor("gov-static"));
    end
    DebugScript.helper.quiet(@() net.a_Bus{5}.replace_component("B005SG1", "gen-classical"));
    DebugScript.helper.quiet(@() net.initialize());
end

function set_form(res, s_form)
    res.Form = s_form;
end
