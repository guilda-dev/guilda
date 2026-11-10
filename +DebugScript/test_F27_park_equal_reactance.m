% F27: gen-park の平衡点は Xq_p = Xq (q 軸の過渡回路なし) でも求まる
%
% get_equilibrium は 1/(Xq - Xq_p) を使っていたので、IEEJ の LGT=4 機 (Xq_p = Xq) で
% Inf/NaN になっていた。Eq, Ed の行に (Xd - Xd_p), (Xq - Xq_p) を掛けて解く。
%
% 実行: runtests("DebugScript.test_F27_park_equal_reactance")  または  DebugScript.run_all("Features","F27")

s_warn = "GUILDA:PowerNetwork:EquilibriumResidual";


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Xq_p equal to Xq gives a finite equilibrium with Ed = 0
[net, g2] = network_with("Xq_p", @(p) p.Xq);
assert(warning_of(@() net.initialize) ~= s_warn)

x = g2.rv_Xequilibrium;
assert(all(isfinite(x)) && all(isfinite(g2.rv_Uequilibrium)))
assert(abs(x(g2.sv_x == "Ed")) < 1e-14)

X = net.simulate([0,5]).odeResults.Bus(2).Component(1).X;
assert(max(abs(X{:,:} - x.'), [], "all") < 1e-9)

res = net.get_sys();
assert(all(isfinite(eig(res.A, res.E))))


%% Xq_p close to Xq approaches the case of equality
[net, g2] = network_with("Xq_p", @(p) p.Xq);
evalc("net.initialize;");
x_eq   = g2.rv_Xequilibrium;
res    = net.get_sys();
eig_eq = eig(res.A, res.E);

[net, g2] = network_with("Xq_p", @(p) p.Xq*(1-1e-6));
evalc("net.initialize;");
assert(norm(g2.rv_Xequilibrium - x_eq) < 1e-5)
% 等しいときの Ed は入力から届かないので get_sys が状態から除く (固有値 -1/Tq_p が 1 つ減る)
res      = net.get_sys();
eig_near = eig(res.A, res.E);
assert(any(numel(eig_near) - numel(eig_eq) == [0,1]))
for e = eig_eq.'
    assert(min(abs(eig_near - e)) < 1e-5*max(1, abs(e)), string(e))
end


%% Xd_p equal to Xd gives a finite equilibrium
[net, g2] = network_with("Xd_p", @(p) p.Xd);
assert(warning_of(@() net.initialize) ~= s_warn)
assert(all(isfinite(g2.rv_Xequilibrium)))
assert(abs(g2.rv_Xequilibrium(g2.sv_x == "Eq") - g2.rv_Uequilibrium(2)) < 1e-12)   % Eq = Vfield


%% Xq_p below Xq gives the same equilibrium as before
% 変更前の式 (1/(Xq - Xq_p) を使う) と比べる
net = network.IEEE14bus();
evalc("net.initialize;");
n = 0;
for k = 1:numel(net.a_Bus)
    for j = 1:numel(net.a_Bus{k}.a_Component)
        g = net.a_Bus{k}.a_Component{j};
        if ~isa(g, "component.generator.park"), continue, end
        x_old = old_equilibrium(g.tab_parameter.dynamics, g.c_Vequilibrium, g.c_Iequilibrium);
        assert(norm(g.rv_Xequilibrium - x_old) < 1e-12 * norm(x_old), g.s_tag)
        n = n + 1;
    end
end
assert(n > 0)

[~, g] = DebugScript.helper.build_3bus("gen-park");
for c_S = [0.5+0.2j, 1.2-0.3j, -0.4+0.1j]
    c_V = 1.03*exp(0.2j);
    c_I = conj(c_S/c_V);
    x_old = old_equilibrium(g.tab_parameter.dynamics, c_V, c_I);
    assert(norm(g.get_equilibrium(c_V, c_I) - x_old) < 1e-12 * norm(x_old))
end


% ---- local functions ----
function [net, g2] = network_with(s_para, fcn_value)
% B002 の gen-park のパラメータ s_para を fcn_value(既定のパラメータ) にした 3 母線系統
    [~, g] = DebugScript.helper.build_3bus("gen-park");
    p = g.tab_parameter.dynamics;
    p.(s_para) = fcn_value(p);
    [net, g2] = DebugScript.helper.build_3bus("gen-park", parameter=p);
end

function x = old_equilibrium(para, c_V, c_I)
% 変更前の get_equilibrium の式
    r_P = real(c_V*conj(c_I));
    r_Q = imag(c_V*conj(c_I));
    Vabs = abs(c_V);
    Xd = para.Xd;  Xq = para.Xq;  Xdp = para.Xd_p;  Xqp = para.Xq_p;
    Xdpp = para.Xd_pp;  Xqpp = para.Xq_pp;  Xls = para.X_ls;
    dst = angle(c_V) + atan(r_P/(r_Q+Vabs^2/Xq));
    Idq = exp(1j*dst) * conj(c_I);
    Iq  = real(Idq);
    Id  = imag(Idq);
    dXd  = 1/(Xd-Xdp);
    dXq  = 1/(Xq-Xqp);
    dXdp = (Xdp-Xdpp)/(Xdp-Xls)^2;
    dXqp = (Xqp-Xqpp)/(Xqp-Xls)^2;
    SE   = [dXd+dXdp, 0, 0, -dXdp; 0, dXq+dXqp, dXqp, 0; 0, dXqp, dXqp, 0; -dXdp, 0, 0, dXdp];
    Vfd  = Xd/Vabs * ( (r_Q+Vabs^2/Xq)*(r_Q+Vabs^2/Xd) + r_P^2 ) / sqrt( (r_Q+Vabs^2/Xq)^2 + r_P^2 );
    wst = [Xdpp-Xls, 0; 0, Xqpp-Xls; 0, -Xqp+Xqpp; Xdp-Xdpp, 0] * diag(1./[Xdp-Xls,Xqp-Xls]) * [-Id;Iq];
    ust = [dXd*Vfd; 0; 0; 0];
    x = [dst; 0; SE\(wst+ust)];
end

function s_id = warning_of(fcn)
% 関数を実行し、最後の警告の ID を返す (なければ "")
    lastwarn("", "");
    evalc("fcn();");
    [s_msg, s_id] = lastwarn();
    s_id = string(DebugScript.helper.msg_id(s_msg, s_id));
end
