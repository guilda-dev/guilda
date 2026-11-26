function example_5_2(varargin)
% 例 5.2（図 5.3）: AGC の寄与係数の変化に対する有効電力の時間応答
%
% 母線 1・3 の発電機に AGC を付け、機械入力の定常値を 0 にして（機械入力は AGC が
% すべて与えます）、寄与係数 [alpha1; alpha3] = [beta1; beta3] を 0〜20 秒は [1; 1]、
% 20〜40 秒は [1; 3]、40〜60 秒は [3; 1] にします。区間ごとに計算し、前の区間の最後の
% 状態（AGC の状態を含む）から次の区間を始めます。
% (a) 母線 1（青の実線）と母線 3（赤の破線）の有効電力、(b) 送電損失 P1+P2+P3 を描きます。
% 引数は net.simulate にそのまま渡します（例: example_5_2(SampleTime=0.01)）。

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8, "Format", "struct"}, varargin];

    net = network_example3bus(flow=2, comp2="L_power", lossless="br23");
    ib  = [1, 3];                    % 発電機の母線
    g   = {net.a_Bus{1}.a_Component{1}, net.a_Bus{3}.a_Component{1}};
    agc = net.add_global_controller("agc-PI", g, parameter=struct(kP=100, kI=500));

    % AGC の積分器 xi の初期値: 1 区間目は 2 台の発電機で母線 2 の負荷 P2 を半分ずつ受け持つ値
    % （旧版 x0 = P2/(2*Ki)、Ki = -500）、2 区間目からは前の区間の最後の値です。
    % 初期値は、平衡点からのずれとして add_offset で AGC の状態 xi に与えます。
    P2  = net.a_Bus{2}.a_Component{1}.tab_parameter.powerflow.P;
    xi0 = P2 / (2 * -500);

    K = [1, 1; 1, 3; 3, 1];          % 区間ごとの寄与係数（alpha = beta）
    c_sol = cell(3, 1);
    for k = 1:3
        T = 20*[k-1, k];
        agc.tab_parameter.dynamics.alpha = K(k, :).';
        agc.tab_parameter.dynamics.beta  = K(k, :).';
        net.initialize(Solver="fsolve");          % 寄与係数の変更を反映（平衡点は変わりません）
        if k > 1
            xi0 = c_sol{k-1}.a_GlobalController{1}.x.xi(end);
        end

        sc = net.add_scenario("term" + k, Time=T);
        sc.add_offset(agc.s_tag, "xi", xi0 - agc.rv_Xequilibrium, T(1));
        for i = 1:2
            % 機械入力: 定常値を 0 にします（旧版 governor.P = 0。機械入力は AGC がすべて与えます）
            Pm0 = g{i}.rv_Uequilibrium(g{i}.sv_u == "Pmech");
            sc.add_input(g{i}.s_tag, "Pmech", -Pm0, T);
            % 発電機の状態の初期値: 1 区間目は平衡点、2 区間目からは前の区間の最後の状態
            if k > 1
                x_end = c_sol{k-1}.a_Bus{ib(i)}.a_Component{1}.x{end, :}.';
                sc.add_offset(g{i}.s_tag, g{i}.sv_x, x_end - g{i}.rv_Xequilibrium, T(1));
            end
        end
        c_sol{k} = net.simulate("term" + k, c_opt{:});
    end

    % 3 区間をつないで、母線の有効電力 P = Re(V conj(I)) を求めます
    t = []; P = [];
    for k = 1:3
        sol = c_sol{k};
        Pk  = zeros(numel(sol.t), 3);
        for i = 1:3
            V = sol.a_Bus{i}.V{:, 1} + 1j*sol.a_Bus{i}.V{:, 2};
            I = sol.a_Bus{i}.I{:, 1} + 1j*sol.a_Bus{i}.I{:, 2};
            Pk(:, i) = real(V .* conj(I));
        end
        t = [t; sol.t(:)]; %#ok<AGROW>
        P = [P; Pk];       %#ok<AGROW>
    end

    figure()
    subplot(1, 2, 1)
    plot(t, P(:, 1), "b", t, P(:, 3), "--r")
    ylim([-1, 4])
    subtitle("(a) 青実線:P1, 赤波線:P3 ")

    subplot(1, 2, 2)
    plot(t, P(:, 1) + P(:, 2) + P(:, 3), "b")
    ylim([0, 0.03])
    subtitle("(b) 送電損失 P1+P2+P3")
end
