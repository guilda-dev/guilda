function example_3_3(varargin)
% 例 3.3（図 3.2）: 初期値の変動に対する角周波数偏差の時間応答
%
% 潮流設定（表 3.1、表 3.2）ごとに、母線 1 の発電機の初期値に摂動を加えたときの
% 母線 1（青の実線）と母線 3（赤の破線）の発電機の周波数偏差を描きます。
% 引数は net.simulate にそのまま渡します（例: example_3_3(SampleTime=0.01)）。

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8}, varargin];
    s_sub = ["図3.2(a) 初期値変動に対する角周波数偏差の時間応答", ...
             "図3.2(b) 初期値変動に対する角周波数偏差の時間応答"];
    figure();
    for k = 1:2         % (a) 表 3.1 の潮流設定、(b) 表 3.2 の潮流設定
        net  = network_example3bus(flow=k, comp2="L_impedance", lossless="br23");
        gen1 = net.a_Bus{1}.a_Component{1}.s_tag;

        % 母線 1 の発電機の回転子偏角 δ を平衡点 + π/6、内部電圧 E を平衡点 + 0.1 にする
        sc = net.add_scenario("perturb", Time=[0, 50]);
        sc.add_offset(gen1, ["delta"; "Eq"], [pi/6; 0.1], 0);
        res = net.simulate("perturb", c_opt{:});

        sol = res.odeResults;
        subplot(2, 1, k)
        plot(sol.t, sol.Bus(1).Component(1).X.omega, "-b", ...
             sol.t, sol.Bus(3).Component(1).X.omega, "--r")
        ylim([-0.015, 0.015])
        subtitle(s_sub(k))
    end
end
