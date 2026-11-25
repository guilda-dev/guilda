function example_5_1(varargin)
% 例 5.1（図 5.2）: 消費電力の増加に対する角周波数偏差の時間応答
%
% 母線 2 の定電力負荷の消費電力を 0〜10 秒で 1% まで直線的に増やし（その後は一定）、
% 母線 1（青の実線）と母線 3（赤の破線）の発電機の周波数偏差を 100 秒まで描きます。
% (a) は自動発電制御（AGC）なし、(b) は母線 1・3 の発電機に AGC を付けた場合です。
% 引数は net.simulate にそのまま渡します（例: example_5_1(SampleTime=0.01)）。

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8}, varargin];
    sv_case = ["(a) 自動発電制御なし ", "(b) 自動発電制御あり "];

    figure();
    for j = 1:2
        net = network_example3bus(flow=2, comp2="L_power", lossless="br23");
        if j == 2
            % AGC（旧版 controller_broadcast_PI_AGC(net, [1,3], [1,3], -100, -500)）。
            % 入力の寄与係数 alpha = [1; 3]、観測の寄与係数 beta = [1; 3]
            g1 = net.a_Bus{1}.a_Component{1};
            g3 = net.a_Bus{3}.a_Component{1};
            net.add_global_controller("agc-PI", {g1, g3}, ...
                parameter=struct(alpha=[1; 3], beta=[1; 3], kP=100, kI=500));
            net.initialize(Solver="fsolve");
        end

        sc = net.add_scenario("load", Time=[0, 100]);
        add_load_increase(net, sc, 0.01);
        res = net.simulate("load", c_opt{:});

        sol = res.odeResults;
        subplot(2, 1, j)
        plot(sol.t, sol.Bus(1).Component(1).X.omega, "b", ...
             sol.t, sol.Bus(3).Component(1).X.omega, "--r")
        ylim([-0.002, 0.002])
        subtitle("図5.2 消費電力増加に対する角周波数偏差の時間応答 " + sv_case(j))
    end
end


function add_load_increase(net, sc, r_alpha)
% 母線 2 の定電力負荷の消費電力を、0〜10 秒で 1 倍から (1+r_alpha) 倍まで直線的に
% 増やし、その後は (1+r_alpha) 倍に保つ入力をシナリオ sc に加えます。
%
% 旧版の負荷の入力 u は電力の倍率 P = P0*(1+u) でした。v4 の load-power の入力は
% 電力 Pload そのものなので、ΔP = P0*u を加えます（u に比例するので直線補間で同じです）。
% 旧版は時刻 [0, 10, 100] の区間を別々に積分するので、v4 も 10 秒で入力を分けます。
    ld = net.a_Bus{2}.a_Component{1};
    P0 = ld.rv_Uequilibrium(ld.sv_u == "Pload");     % 平衡点の有効電力（消費は負）
    sc.add_input(ld.s_tag, "Pload", [0, 0; 10, r_alpha*P0], [0, 10], Method="foh");
    sc.add_input(ld.s_tag, "Pload", r_alpha*P0, [10, 100]);
end
