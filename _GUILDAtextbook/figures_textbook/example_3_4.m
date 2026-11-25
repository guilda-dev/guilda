function example_3_4(varargin)
% 例 3.4（図 3.3、図 3.4）: 負荷の変化に対する角周波数偏差の時間応答
%
% 母線 2 の定インピーダンス負荷を 0〜10 秒で 1% 変化させ（その後は一定）、母線 1
% （青の実線）と母線 3（赤の破線）の発電機の周波数偏差を 100 秒まで描きます。
% 図 3.3 は表 3.1、図 3.4 は表 3.2 の潮流設定です。
% 引数は net.simulate にそのまま渡します（例: example_3_4(SampleTime=0.01)）。

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8}, varargin];
    sv_fig = ["図3.3", "図3.4"];
    for k = 1:2         % 図 3.3: 表 3.1 の潮流設定、図 3.4: 表 3.2 の潮流設定
        net  = network_example3bus(flow=k, comp2="L_impedance", lossless="br23");
        figure();

        % (a) 負荷のアドミタンスを 1% 増やす、(b) 1% 減らす
        sv_case = ["(a) 抵抗が1%増加した場合 ", "(b) 抵抗が1%減少した場合 "];
        r_alpha = [0.01, -0.01];
        sv_ylim = {[-0.001, 0], [0, 0.001]};
        for j = 1:2
            sc = net.add_scenario("load" + j, Time=[0, 100]);
            add_load_change(net, sc, r_alpha(j));
            res = net.simulate("load" + j, c_opt{:});

            sol = res.odeResults;
            subplot(2, 1, j)
            plot(sol.t, sol.Bus(1).Component(1).X.omega, "-b", ...
                 sol.t, sol.Bus(3).Component(1).X.omega, "--r")
            ylim(sv_ylim{j})
            subtitle(sv_fig(k) + " 負荷の変化に対する角周波数偏差の時間応答 " + sv_case(j))
        end
    end
end


function add_load_change(net, sc, r_alpha)
% 母線 2 の定インピーダンス負荷のアドミタンスを、0〜10 秒で 1 倍から (1+r_alpha) 倍
% まで直線的に変え、その後は (1+r_alpha) 倍に保つ入力をシナリオ sc に加えます。
%
% 旧版の負荷の入力 u はアドミタンスの倍率 Y = Y0*(1+u) でした。v4 の load-impedance の
% 入力はインピーダンス R、X そのものなので、Z = Z0/(1+u) との差
% ΔZ = -Z0*u/(1+u) を R と X に加えます。u は時刻に比例しますが ΔZ は比例しないので、
% 0.01 秒ごとの値を直線補間（"foh"）で与えます。
    ld  = net.a_Bus{2}.a_Component{1};
    Z0  = ld.rv_Uequilibrium;                  % 平衡点の [R; X]
    t   = (0:0.01:10).';
    u   = r_alpha * t/10;                      % 旧版の入力（0〜10 秒で 0 → r_alpha）
    dZ  = -u./(1+u) * Z0.';                    % [ΔR, ΔX]
    sc.add_input(ld.s_tag, ["R"; "X"], [t, dZ], [0, 100], Method="foh");
end
