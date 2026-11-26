function lin = linear_model_example3bus(net, delta, E)
% 発電機 3 台の 3 母線系統を、指定した δ、E の点で GUILDA v4 の線形化（get_sys）にかけ、
% 教科書 4 章の近似線形化モデルの行列を返します（例 4.3、4.4、4.6 で使います）。
%
% lin = linear_model_example3bus(net, delta, E)
%
% - net   : network_example3bus(flow=0, comp2="Gen_1axis", ...)（送電線の R、X は書き換えてよい）
% - delta : 回転子偏角 δ [rad]（3 x N。列ごとに 1 点）
% - E     : 内部電圧 E（3 x N）
% 点は平衡点でなくてもかまいません（Δω = 0）。母線電圧 V は、その δ、E で代数方程式
% （送電網 Y V = I と発電機の I = (E e^{jδ} - V)/(j Xd')、Xd' = Xq）を満たす値にします。
%
% 返す lin のフィールド（行列は 3 x 3 x N、点ごとに 3 枚目の添字）:
% - Psi              : 状態 [δ; Δω; E]（種類ごとに母線 1〜3 の順）の状態行列（9 x 9 x N）
% - L, CE, BE, AE    : 教科書の (4.x) の行列。Psi = blkdiag(I, M^-1, T^-1) *
%                      [0, ω0 I, 0; -L, -D, -CE; BE, 0, AE]
% - M, D, T, Xd, Xq  : 発電機の定数（対角行列）、omega0 : 2π × 系統周波数
% - result           : get_sys の結果（ResultLIN）
    arguments
        net  (1,1) PowerNetwork
        delta (3,:) double
        E     (3,:) double {mustBeEqualSize(delta, E)}
    end
    n = 3;
    N = size(delta, 2);
    a_gen = cellfun(@(b) b.a_Component{1}, net.a_Bus(:), "UniformOutput", false);
    tab_dyn = cellfun(@(g) g.tab_parameter.dynamics, a_gen, "UniformOutput", false);
    tab_dyn = vertcat(tab_dyn{:});
    if any(abs(tab_dyn.Xq - tab_dyn.Xd_p) > 0)
        error("linear_model_example3bus: 教科書の近似線形化モデルは Xq = Xd' の場合です。");
    end
    lin.M  = diag(tab_dyn.M);
    lin.D  = diag(tab_dyn.D);
    lin.T  = diag(tab_dyn.Td_p);
    lin.Xd = diag(tab_dyn.Xd);
    lin.Xq = diag(tab_dyn.Xq);
    lin.omega0 = 2*pi*net.tab_parameter.base.Hz;

    % 線形化する点（net.get_variable_map() の x, Vre, Vim, u, uc の順）。
    % 入力 u, uc は平衡点の値のまま（状態行列には現れません）。
    tab  = net.get_variable_map();
    tags = cellfun(@(g) g.s_tag, a_gen);
    p0   = tab.Equilibrium(ismember(tab.Kind, ["x", "Vre", "Vim", "u", "uc"]));
    Y    = net.get_admittance_matrix();
    Y    = Y{:, :};
    Yg   = diag(1 ./ (1j*diag(lin.Xq)));                % 発電機の内部アドミタンス 1/(j Xd')
    P    = repmat(p0, 1, N);
    for k = 1:N
        V = (Y + Yg) \ (Yg * (E(:, k) .* exp(1j*delta(:, k))));
        for i = 1:n
            P(tab.Label == "delta_" + tags(i), k) = delta(i, k);
            P(tab.Label == "omega_" + tags(i), k) = 0;
            P(tab.Label == "Eq_"    + tags(i), k) = E(i, k);
            P(tab.Label == "Vre_"   + net.a_Bus{i}.s_tag, k) = real(V(i));
            P(tab.Label == "Vim_"   + net.a_Bus{i}.s_tag, k) = imag(V(i));
        end
    end

    % v4 の線形化: 母線電圧を消去した ODE（Type="ODE"）、時定数を掛けた形（Form="absorbed"）
    [res, flag, output] = net.get_sys(P, Type="ODE", Form="absorbed");
    if ~flag
        error("linear_model_example3bus: 線形化に失敗しました（%s）。", output.message);
    end
    sv_name = ["delta_" + tags; "omega_" + tags; "Eq_" + tags];
    [~, perm] = ismember(sv_name, res.StateName);
    lin.Psi = zeros(3*n, 3*n, N);
    [lin.L, lin.CE, lin.BE, lin.AE] = deal(zeros(n, n, N));
    id = 1:n;  iw = n + (1:n);  iE = 2*n + (1:n);
    for k = 1:N
        res.Index = k;
        Psi = res.A(perm, perm);
        lin.Psi(:, :, k) = Psi;
        lin.L(:, :, k)  = -lin.M * Psi(iw, id);
        lin.CE(:, :, k) = -lin.M * Psi(iw, iE);
        lin.BE(:, :, k) =  lin.T * Psi(iE, id);
        lin.AE(:, :, k) =  lin.T * Psi(iE, iE);
    end
    res.Index = 1;
    lin.result = res;
end


function mustBeEqualSize(a, b)
    if ~isequal(size(a), size(b))
        error("delta と E は同じ大きさにしてください。");
    end
end
