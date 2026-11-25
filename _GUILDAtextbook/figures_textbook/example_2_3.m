function example_2_3(varargin)
% 例 2.3（図 2.10〜2.12）: 3 母線系統（発電機 3 台）の時間応答
%
% 母線 1 の発電機の初期値に摂動を加えたときの応答（図 2.10）と、さらに入力を
% 加えたときの応答（図 2.11、図 2.12）を描きます。
% 引数は net.simulate にそのまま渡します（例: example_2_3(SampleTime=0.01)）。

    % ネットワークの定義（設定の詳細は README を参照）
    net  = network_example3bus(flow=0, comp2="Gen_1axis", lossless={});
    gen1 = net.a_Bus{1}.a_Component{1}.s_tag;      % 母線 1 の発電機のタグ（"B001SG1"）

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8}, varargin];

    %% 図 2.10: 初期値に摂動を加えた場合
    % 母線 1 の発電機の回転子偏角 δ を平衡点 + π/6、内部電圧 E を平衡点 + 0.1 にする
    sc = net.add_scenario("fig2_10", Time=[0, 30]);
    sc.add_offset(gen1, ["delta"; "Eq"], [pi/6; 0.1], 0);
    res = net.simulate("fig2_10", c_opt{:});
    plot_response(res, "図2.10(%s) 初期値に摂動を加えた場合の時間応答");

    %% 図 2.11: 初期値の摂動に加えて、入力に摂動を加えた場合
    % 0〜30 秒の間、母線 1 の発電機の界磁電圧 Vfield と機械入力 Pmech に 0.05 を加える
    sc = net.add_scenario("fig2_11", Time=[0, 30]);
    sc.add_offset(gen1, ["delta"; "Eq"], [pi/6; 0.1], 0);
    sc.add_input(gen1, ["Vfield"; "Pmech"], [0.05; 0.05], [0, 30]);
    res = net.simulate("fig2_11", c_opt{:});
    plot_response(res, "図2.11(%s) 機械入力に摂動を加えた場合の時間応答");

    %% 図 2.12: 初期値の摂動に加えて、入力を与える場合
    % 旧版のコード u = [0, 0; 0.05, 0.05] は「行 = 時刻（0 秒、30 秒）」と解釈され、
    % 0〜30 秒の入力は 0 でした。旧版と同じ条件にするため、ここでも入力は加えません
    % （結果は図 2.10 と同じになります）。
    sc = net.add_scenario("fig2_12", Time=[0, 30]);
    sc.add_offset(gen1, ["delta"; "Eq"], [pi/6; 0.1], 0);
    res = net.simulate("fig2_12", c_opt{:});
    plot_response(res, "図2.12(%s) 界磁電圧に摂動を加えた場合の時間応答");
end


function plot_response(res, s_title)
% 4 つの図（(a) 周波数偏差、(b) 偏角、(c) 電圧の大きさ、(d) 電力）を描きます。
% 色は 青 = 母線 1、黒 = 母線 2、赤 = 母線 3 です。
    sol   = res.odeResults;
    t     = sol.t;
    color = ["b", "k", "r"];
    V = zeros(numel(t), 3);  I = zeros(numel(t), 3);
    for i = 1:3
        V(:, i) = sol.Bus(i).V{:, 1} + 1j*sol.Bus(i).V{:, 2};    % 母線電圧 [pu]
        I(:, i) = sol.Bus(i).I{:, 1} + 1j*sol.Bus(i).I{:, 2};    % 母線から送電網へ流れる電流 [pu]
    end
    PQ = V .* conj(I);                                           % 母線から送電網へ送る電力
    figure();

    % (a) 周波数偏差 Δω
    subplot(2, 2, 1)
    hold on
    for i = 1:3
        plot(t, sol.Bus(i).Component(1).X.omega, color(i))
    end
    subtitle(sprintf(s_title, "a"))

    % (b) 実線: 回転子偏角 δ、破線: 母線電圧の偏角 ∠V（0〜2π に折り返し）
    subplot(2, 2, 2)
    hold on
    for i = 1:3
        plot(t, mod(sol.Bus(i).Component(1).X.delta, 2*pi), color(i))
        plot(t, mod(angle(V(:, i)), 2*pi), "--" + color(i))
    end
    ylim([0, 6])
    subtitle(sprintf(s_title, "b"))

    % (c) 実線: 内部電圧 E、破線: 母線電圧の大きさ |V|
    subplot(2, 2, 3)
    hold on
    for i = 1:3
        plot(t, sol.Bus(i).Component(1).X.Eq, color(i))
        plot(t, abs(V(:, i)), "--" + color(i))
    end
    ylim([0, 2])
    subtitle(sprintf(s_title, "c"))

    % (d) 実線: 有効電力 P、破線: 無効電力 Q
    subplot(2, 2, 4)
    hold on
    for i = 1:3
        plot(t, real(PQ(:, i)), color(i))
        plot(t, imag(PQ(:, i)), "--" + color(i))
    end
    ylim([-1.5, 1.5])
    subtitle(sprintf(s_title, "d"))
end
