function example_4_2(varargin)
% 例 4.2（図 4.2）: 3 母線系統（発電機 3 台）の初期値応答を平衡点からの偏差で描きます
%
% 母線 1 の発電機の初期値に摂動を加えたときの Δω、δ、E、P の平衡点からの偏差を描きます。
% 旧版は net.simulate(..., 'linear', false) で、近似線形モデルではなく非線形モデル
% （例 2.3 の図 2.10 と同じ計算）を解いています。v4 版も同じく非線形モデルで計算します。
% 引数は net.simulate にそのまま渡します（例: example_4_2(SampleTime=0.01)）。

    % ネットワークの定義（設定の詳細は README を参照）
    net  = network_example3bus(flow=0, comp2="Gen_1axis", lossless={});
    gen1 = net.a_Bus{1}.a_Component{1}.s_tag;      % 母線 1 の発電機のタグ（"B001SG1"）

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8}, varargin];

    % 母線 1 の発電機の回転子偏角 δ を平衡点 + π/6、内部電圧 E を平衡点 + 0.1 にする
    sc = net.add_scenario("fig4_2", Time=[0, 30]);
    sc.add_offset(gen1, ["delta"; "Eq"], [pi/6; 0.1], 0);
    res = net.simulate("fig4_2", c_opt{:});

    sol   = res.odeResults;
    t     = sol.t;
    color = ["b", "k", "r"];

    figure();
    sgtitle('図4.2');

    % (a)〜(c) 発電機の状態 Δω、δ、E の平衡点からの偏差
    sv_state = ["omega", "delta", "Eq"];
    sv_sub   = ["(a) $\Delta\omega^{\rm{lin}}$", "(b) $\delta^{lin}$", "(c) $E^{lin}$"];
    rm_ylim  = [-0.005, 0.005; -pi, pi; -1, 1];
    i_state  = [2, 1, 3];                         % 状態の並び [delta; omega; Eq] での位置
    for k = 1:3
        subplot(2, 2, k)
        hold on
        for i = 1:3
            x_eq = net.a_Bus{i}.a_Component{1}.rv_Xequilibrium(i_state(k));
            plot(t, sol.Bus(i).Component(1).X.(sv_state(k)) - x_eq, color(i))
        end
        ylim(rm_ylim(k, :))
        subtitle(sv_sub(k), 'Interpreter', 'latex')
    end

    % (d) 母線から送電網へ送る有効電力 P の平衡点からの偏差
    subplot(2, 2, 4)
    hold on
    for i = 1:3
        V  = sol.Bus(i).V{:, 1} + 1j*sol.Bus(i).V{:, 2};
        I  = sol.Bus(i).I{:, 1} + 1j*sol.Bus(i).I{:, 2};
        bus = net.a_Bus{i};
        P_eq = real(bus.c_Vequilibrium .* conj(bus.c_Iequilibrium));
        plot(t, real(V .* conj(I)) - P_eq, color(i))
    end
    ylim([-1.5, 1.5])
    subtitle('(d) $P^{lin}$', 'Interpreter', 'latex')

    % 図 4.3 は example_4_6 と同じです（旧版と同じく表示だけ）
    disp('"example_4_6.m" と同様')
end
