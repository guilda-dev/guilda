function example_4_3()
% 例 4.3: 近似線形化モデルの初期値応答と蓄積関数 W_F、W_G
%
% 発電機 3 台の 3 母線系統（送電網の損失なし (左)・あり (右)）を、教科書の点
% （δ、E を数値で与えます）で GUILDA の線形化（get_sys）にかけ、その状態行列 Ψ の
% 初期値応答から、サブシステム F の蓄積関数 W_F（青）、G の蓄積関数 W_G（赤）と
% その和（黒）を描きます。旧版は Ψ を式で組み立てていました。
    figure
    sv_lossless = {["br12", "br23"], {}};          % θ2 = 0（損失なし）、θ2 = 1（損失あり）
    for k = 1:2
        subplot(1, 2, k)
        net = network_example3bus(flow=0, comp2="Gen_1axis", lossless=sv_lossless{k});

        % 発電機モデルの状態の点（教科書の値。平衡点ではありません）
        delta = [0.4656; 1.0903; 0.6067];
        E     = [1.4363; 1.8095; 1.1030];
        lin   = linear_model_example3bus(net, delta, E);
        n = 3;

        % 近似線形モデルの初期値応答（δ1 に π/6、E1 に 0.1 の初期値）
        sys = ss(lin.Psi, [], [], []);
        x0  = [pi/6; 0; 0; 0; 0; 0; 0.1; 0; 0];
        [~, t, x] = initial(sys, x0);
        deltax = x(:, 1:n);
        omegax = x(:, n+1:2*n);
        Ex     = x(:, 2*n+1:3*n);

        % 蓄積関数の行列
        Ahat = (lin.Xd - lin.Xq) \ lin.AE;
        Bhat = (lin.Xd - lin.Xq) \ lin.BE;
        PF = 1/2*lin.omega0*lin.M;
        PG = 1/2*[lin.L, -Bhat'; -Bhat, -Ahat];
        PG = (PG + PG')/2;

        WF = diag(omegax*PF*omegax');              % サブシステム F の蓄積関数
        xG = [deltax, Ex];
        WG = diag(xG*PG*xG');                      % サブシステム G の蓄積関数

        plot(t, WF, '-b', 'LineWidth', 1.5);
        grid on;
        hold on;
        plot(t, WG, '-r', 'LineWidth', 1.5);
        plot(t, WF + WG, '-k', 'LineWidth', 1.5);
        xlim([0, 30])
        ylim([0, 0.18])
    end
end
