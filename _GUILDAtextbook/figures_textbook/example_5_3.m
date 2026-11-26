function example_5_3(varargin)
% 例 5.3（図 5.5）: 損失のない電力系統の蓄積関数の時間応答
%
% 送電線の損失をなくした 3 母線系統で、母線 1・3 の発電機に AGC（寄与係数 [1; 1]）を
% 付け、機械入力の定常値を 0 にして（機械入力は AGC がすべて与えます）5 秒間計算し、
% 蓄積関数 W = WF + WG + Wxi とその内訳を描きます。左は表 5.2 の左の潮流設定
% （母線 3 の P = 0.5）、右は右の潮流設定（母線 1 の偏角 -0.0488、母線 3 の P = 2.5）です。
% 引数は net.simulate にそのまま渡します（例: example_5_3(SampleTime=0.01)）。

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8, "Format", "struct"}, varargin];

    figure('position', [100, 100, 950, 300]);

    net = network_example3bus(flow=2, comp2="L_power", lossless=["br12", "br23"]);
    g   = {net.a_Bus{1}.a_Component{1}, net.a_Bus{3}.a_Component{1}};
    kI  = 500;
    agc = net.add_global_controller("agc-PI", g, ...
              parameter=struct(alpha=[1; 1], beta=[1; 1], kP=100, kI=kI));

    % 表 5.2 の潮流設定: 母線 1 の偏角と母線 3 の P
    r_Varg = [0, -0.0488];
    r_P3   = [0.5, 2.5];
    for k = 1:2
        net.a_Bus{1}.tab_parameter.powerflow.Varg = r_Varg(k);
        g{2}.tab_parameter.powerflow.P = r_P3(k);
        net.initialize(Solver="fsolve");

        % AGC の積分器 xi の初期値: 2 台の発電機で母線 2 の負荷を半分ずつ受け持つ値
        % （旧版 x0 = P2/(2*Ki)、Ki = -500）。平衡点からのずれとして add_offset で与えます。
        P2  = net.a_Bus{2}.a_Component{1}.tab_parameter.powerflow.P;
        xi0 = P2 / (2 * -kI);
        sc  = net.add_scenario("flow" + k, Time=[0, 5]);
        sc.add_offset(agc.s_tag, "xi", xi0 - agc.rv_Xequilibrium, 0);
        for i = 1:2
            Pm0 = g{i}.rv_Uequilibrium(g{i}.sv_u == "Pmech");   % 定常値を 0 に（旧版 governor.P = 0）
            sc.add_input(g{i}.s_tag, "Pmech", -Pm0, [0, 5]);
        end
        sol = net.simulate("flow" + k, c_opt{:});

        subplot(1, 2, k)
        storage_func(sol, net, kI);
    end
end


function [W, WF, WG, Wxi] = storage_func(sol, net, kI)
% 機械サブシステムの蓄積関数 WF、電気サブシステムの蓄積関数 WG、AGC の蓄積関数 Wxi と
% その和 W を、計算の最後の値（平衡点）を基準にして求め、描きます。

    % ネットワークのパラメータ
    Y = net.get_admittance_matrix().Variables;     % 表（母線のタグの行・列）から行列に
    B = imag(Y);
    omega0 = 2*pi*60;

    % 発電機の母線と負荷の母線
    n_bus   = numel(net.a_Bus);
    gen_idx  = cellfun(@(b) startsWith(b.a_Component{1}.key, "gen-"), net.a_Bus);
    load_idx = cellfun(@(b) startsWith(b.a_Component{1}.key, "load-"), net.a_Bus);

    % 母線電圧と有効電力・無効電力（計算の最後の値を平衡点とします）
    V  = zeros(numel(sol.t), n_bus);
    I  = zeros(numel(sol.t), n_bus);
    for i = 1:n_bus
        V(:, i) = sol.a_Bus{i}.V{:, 1} + 1j*sol.a_Bus{i}.V{:, 2};
        I(:, i) = sol.a_Bus{i}.I{:, 1} + 1j*sol.a_Bus{i}.I{:, 2};
    end
    V_st  = V(end, :).';
    PQ_st = V_st .* conj(I(end, :).');
    P_st  = real(PQ_st);
    Q_st  = imag(PQ_st);

    % 発電機の状態とパラメータ（発電機のない母線は NaN）
    [delta, omega, E] = deal(nan(numel(sol.t), n_bus));
    [M, X, X_prime]   = deal(nan(n_bus, 1));
    for i = find(gen_idx(:)).'
        x = sol.a_Bus{i}.a_Component{1}.x;
        delta(:, i) = x.delta;
        omega(:, i) = x.omega;
        E(:, i)     = x.Eq;
        p = net.a_Bus{i}.a_Component{1}.tab_parameter.dynamics;
        M(i) = p.M;  X(i) = p.Xd;  X_prime(i) = p.Xd_p;
    end
    xi = sol.a_GlobalController{1}.x.xi;           % AGC の状態

    % 電気サブシステムのポテンシャルエネルギー関数 UG
    ig = find(gen_idx(:));
    il = find(load_idx(:));
    UG = @(d, e, Va, Vg) ...
          sum(X(ig).*e(ig).^2./(2*X_prime(ig).*(X(ig)-X_prime(ig))) ...
              - e(ig).*Va(ig)./X_prime(ig).*cos(d(ig)-Vg(ig)) + Va(ig).^2./(2*X_prime(ig))) ...
        - sum(P_st(il).*Vg(il) + Q_st(il).*log(Va(il))) ...
        - sum((diag(Va)*B/2*diag(Va)) .* cos(Vg - Vg.'), "all");
    % UG の δ と E による偏微分
    dUGdd = @(d, e, Va, Vg) e(ig).*Va(ig)./X_prime(ig).*sin(d(ig)-Vg(ig));
    dUGdE = @(d, e, Va, Vg) -1./(X(ig)-X_prime(ig)).*(-X(ig)./X_prime(ig).*e(ig) ...
                             + (X(ig)./X_prime(ig)-1).*Va(ig).*cos(d(ig)-Vg(ig)));

    d_st = delta(end, :).';  w_st = omega(end, :).';  E_st = E(end, :).';
    Va_st = abs(V_st);  Vg_st = angle(V_st);
    UG_st = UG(d_st, E_st, Va_st, Vg_st);
    gd_st = dUGdd(d_st, E_st, Va_st, Vg_st);
    gE_st = dUGdE(d_st, E_st, Va_st, Vg_st);

    n  = numel(sol.t);
    [WF, WG, Wxi] = deal(zeros(n, 1));
    for t = 1:n
        d = delta(t, :).';  w = omega(t, :).';  e = E(t, :).';
        Va = abs(V(t, :)).';  Vg = angle(V(t, :)).';
        WF(t)  = omega0/2 * (w(ig)-w_st(ig)).' * diag(M(ig)) * (w(ig)-w_st(ig));
        WG(t)  = UG(d, e, Va, Vg) - UG_st - gd_st.'*(d(ig)-d_st(ig)) - gE_st.'*(e(ig)-E_st(ig));
        Wxi(t) = 1/2 * omega0 * kI * (xi(t)-xi(end))^2;
    end
    W = WF + WG + Wxi;

    Wplot = @(Wdata, lintype, color) plot(sol.t, Wdata, lintype, 'LineWidth', 2, 'Color', color);
    hold on
    Wplot(W,   '.', 'k')
    Wplot(WF,  '-', '#0072BD')
    Wplot(WG,  '-', '#D95319')
    Wplot(Wxi, '-', '#77AC30')
    xlabel('Time(s)', 'FontSize', 15)
    legend({'W', 'WF', 'WG', 'Wxi'})
    ylim([0, 4])
    xlim([0, 5])
    grid on
    hold off
end
