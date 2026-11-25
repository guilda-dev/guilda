function example_4_6()
% 例 4.6: 偏角の広がり θ1 と送電網の損失の大きさ θ2 に対する安定性
%
% 発電機 3 台の 3 母線系統で、送電線のアドミタンスを y = θ2 Re(y0) + j Im(y0)
% （(c)、(d) は y0 を 1/100 倍）とし、δ = linspace(-θ1 π/2, θ1 π/2, 3) の点
% （E は教科書の値）を GUILDA の線形化（get_sys）にかけます。その状態行列 Ψ と、
% Ψ から取り出した教科書の行列 L、C_E、B_E、A_E の固有値で、各 (θ1, θ2) を分類して描きます。
% (a)、(c) は D = 10、(b)、(d) は D = 0.1 です。旧版は行列を式で組み立てていました。
%
% 青の点: Ψ が安定、赤の o: L - C_E A_E^-1 B_E が正定でない、マゼンタの o: その固有値が複素数、
% シアンの x: A_E の 2 番目の固有値の実部が 0 以上。
    figure;
    sv_sub = ["a", "b", "c", "d"];
    for i_sub = 1:4
        subplot(2, 2, i_sub)
        s_sub = sv_sub(i_sub);
        n = 3;
        net = network_example3bus(flow=0, comp2="Gen_1axis", lossless={});

        % 送電線のアドミタンス y0（(c)、(d) は 1/100 倍）
        y0 = [1.3652 - 1j*11.6041; 1.9422 - 1j*10.5107];
        if ismember(s_sub, ["c", "d"])
            y0 = y0 / 100;
        end
        % 制動係数（(b)、(d) は 1/100 倍）
        if ismember(s_sub, ["b", "d"])
            for i = 1:n
                gen = net.a_Bus{i}.a_Component{1};
                gen.tab_parameter.dynamics.D = 0.01*gen.tab_parameter.dynamics.D;
            end
            net.initialize(Solver="fsolve");       % 機器の定数を変えたら線形化の前に必要です
        end
        E = [1.4363; 1.8095; 1.1030];

        rv_theta1 = 0:0.01:1;
        rv_theta2 = 0:0.05:5;
        delta = cell2mat(arrayfun(@(th) linspace(-th*pi/2, th*pi/2, n)', rv_theta1, "UniformOutput", false));
        [thar1s, thar2s, thar1u, thar2u, thar1uc, thar2uc, thar1ucs, thar2ucs, thar1uci, thar2uci] = deal([]);

        % θ1 と θ2 の各値におけるシステムの安定性を評価
        % （θ2 ごとに送電線を書き換え、θ1 の 101 点をまとめて線形化します）
        lin = cell(numel(rv_theta2), 1);
        for j = 1:numel(rv_theta2)
            y = rv_theta2(j)*real(y0) + 1j*imag(y0);
            for b = 1:2
                net.a_Branch{b}.tab_parameter.dynamics.R = real(1/y(b));
                net.a_Branch{b}.tab_parameter.dynamics.X = imag(1/y(b));
            end
            lin{j} = linear_model_example3bus(net, delta, repmat(E, 1, numel(rv_theta1)));
        end
        for i1 = 1:numel(rv_theta1)
            theta_1 = rv_theta1(i1);
            for j = 1:numel(rv_theta2)
                theta_2 = rv_theta2(j);
                L   = lin{j}.L(:, :, i1);
                CE  = lin{j}.CE(:, :, i1);
                BE  = lin{j}.BE(:, :, i1);
                AE  = lin{j}.AE(:, :, i1);
                Psi = lin{j}.Psi(:, :, i1);

                reeigPsi = sort(real(eig(Psi)), 'descend');
                reeigA = sort(real(eig(AE)), 'descend');
                eigK = eig(L - CE*inv(AE)*BE);                      %#ok<MINV> 旧版と同じ計算
                reeigK = sort(real(eigK));

                if reeigPsi(1) < 1e-7 && reeigPsi(2) ~= 0
                    thar1s = [thar1s theta_1];                       %#ok<AGROW>
                    thar2s = [thar2s theta_2];                       %#ok<AGROW>
                else
                    thar1u = [thar1u theta_1];                       %#ok<AGROW>
                    thar2u = [thar2u theta_2];                       %#ok<AGROW>
                end
                if min(reeigK) < -1e-7 || sum(reeigK) == 0
                    thar1uc = [thar1uc theta_1];                     %#ok<AGROW>
                    thar2uc = [thar2uc theta_2];                     %#ok<AGROW>
                end
                if sum(abs(imag(eigK))) > 1e-7
                    thar1uci = [thar1uci theta_1];                   %#ok<AGROW>
                    thar2uci = [thar2uci theta_2];                   %#ok<AGROW>
                end
                if reeigA(2) >= 0
                    thar1ucs = [thar1ucs theta_1];                   %#ok<AGROW>
                    thar2ucs = [thar2ucs theta_2];                   %#ok<AGROW>
                end
            end
        end

        % 解析結果をプロット
        plot(thar1s, thar2s, 'ob', 'MarkerFaceColor', 'b', 'MarkerSize', 6);
        hold on;
        grid on;
        plot(thar1uc, thar2uc, 'or', 'MarkerSize', 6);
        plot(thar1uci, thar2uci, 'om', 'MarkerSize', 9);
        plot(thar1ucs, thar2ucs, 'xc', 'MarkerSize', 9);
        xlabel('\theta_1')
        ylabel('\theta_2')
    end
end
