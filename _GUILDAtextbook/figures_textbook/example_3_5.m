function example_3_5(varargin)
% 例 3.5（図 3.5、図 3.6）: 地絡に対する角周波数偏差の時間応答
%
% 母線 1 を 0 秒から 50 ms または 100 ms の間地絡させ、母線 1（青の実線）と母線 3
% （赤の破線）の発電機の周波数偏差を 50 秒まで描きます。
% 図 3.5 は表 3.1、図 3.6 は表 3.2 の潮流設定です。
% 引数は net.simulate にそのまま渡します（例: example_3_5(SampleTime=0.01)）。

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8}, varargin];
    sv_fig = ["図3.5", "図3.6"];
    for k = 1:2         % 図 3.5: 表 3.1 の潮流設定、図 3.6: 表 3.2 の潮流設定
        net = network_example3bus(flow=k, comp2="L_impedance", lossless="br23");
        figure();

        % (a) 50 ms の地絡、(b) 100 ms の地絡（初期値は平衡点のまま）
        r_tf    = [0.05, 0.1];
        sv_case = ["(a) 50 [ms] の地絡", "(b) 100 [ms] の地絡"];
        for j = 1:2
            sc = net.add_scenario("fault" + j, Time=[0, 50]);
            sc.add_fault("B001", [0, r_tf(j)]);
            res = net.simulate("fault" + j, c_opt{:});

            sol = res.odeResults;
            subplot(2, 1, j)
            plot(sol.t, sol.Bus(1).Component(1).X.omega, "-b", ...
                 sol.t, sol.Bus(3).Component(1).X.omega, "--r")
            ylim([-0.02, 0.02])
            subtitle(sv_fig(k) + " 地絡に対する角周波数偏差の時間応答 " + sv_case(j))
        end
    end
end
