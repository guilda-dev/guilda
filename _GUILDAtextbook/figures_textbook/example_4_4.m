function example_4_4()
% 例 4.4: サブシステム G と H の周波数応答の固有値の軌跡
%
% 発電機 3 台の 3 母線系統を、送電網の損失なし（青の o）とあり（赤の *）で、教科書の点
% （δ、E を数値で与えます）で GUILDA の線形化（get_sys）にかけます。その状態行列から
% 教科書の行列 L、C_E、B_E、A_E を取り出し、G(jω) と H(jω) の
% (G + G^*)/2 の固有値を周波数ごとに描きます。旧版は行列を式で組み立てていました。
    figure('position', [100, 100, 1000, 275])
    sv_lossless = {["br12", "br23"], {}};          % θ2 = 0（損失なし）、θ2 = 1（損失あり）
    sv_type     = ["bo", "r*"];
    for k = 1:2
        net = network_example3bus(flow=0, comp2="Gen_1axis", lossless=sv_lossless{k});

        % 発電機モデルの状態の点（教科書の値。損失ありでは flow=0 の平衡点、損失なしでは平衡点ではありません）
        delta = [0.4656; 1.0903; 0.6067];
        E     = [1.4363; 1.8095; 1.1030];
        lin   = linear_model_example3bus(net, delta, E);
        n = 3;
        Tinv = inv(lin.T);

        % サブシステム G: 入力 δ、出力 L δ + C_E E
        A_G = [zeros(n), zeros(n); Tinv*lin.BE, Tinv*lin.AE];
        B_G = [eye(n); zeros(n)];
        C_G = [lin.L, lin.CE];
        sysG = ss(A_G, B_G, C_G, []);

        n1 = -5;  n2 = 3;  num = 50;
        [w, G_eigloci] = eig_loci(n1, n2, num, sysG);
        subplot(1, 2, 1)
        semilogx(w, G_eigloci, sv_type(k), 'MarkerSize', 4, 'LineWidth', 1.5);
        ylim([-6, 8])
        grid on; hold on;

        % サブシステム H（j 倍した伝達関数）
        sysH1j = ss(Tinv*lin.AE, Tinv*lin.BE, 1j*lin.CE, 1j*lin.L);
        [w, H_eigloci] = eig_loci(n1, n2, num, sysH1j);
        subplot(1, 2, 2)
        semilogx(w, H_eigloci, sv_type(k), 'MarkerSize', 4, 'LineWidth', 1.5);
        ylim([-0.25, 0.05])
        grid on; hold on;
    end
end


function [w, eigloci] = eig_loci(n, m, num, sys)
% 周波数 w = logspace(n, m, num) での (G(jw) + G(jw)^*)/2 の固有値（大きい順、列ごとに 1 周波数）。
    w = logspace(n, m, num);
    n_sys = length(sys.A);
    eigloci = zeros(size(sys.C, 1), num);
    for i = 1:num
        G_jw = sys.C*inv(sqrt(-1)*w(i)*eye(n_sys) - sys.A)*sys.B + sys.D;   %#ok<MINV> 旧版と同じ計算
        eigloci(:, i) = 1/2*sort(real(eig(G_jw + G_jw')), 'descend');
    end
end
