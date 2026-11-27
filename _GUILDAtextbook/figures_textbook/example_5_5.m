function varargout = example_5_5(varargin)
% 例 5.5（図 5.12）: 系統安定化装置（PSS）を付けた電力系統の角周波数偏差の初期値応答
%
% 3 母線系統（母線 2 は定インピーダンス負荷、母線 2-3 は損失なし）の母線 1・3 の発電機に、
% IEEE ST1 型の AVR（表 5.5 の例 1）と IEEE PSS1 型の PSS（表 5.7 の例 2）を付けます。
% 平衡点は例 5.4 で選ばれた点（内部電圧 E* は表 3.3、回転子偏角の差 δ3* − δ1* = −π/6）で、
% 表 3.1 の潮流（flow=1）の平衡点（δ3* − δ1* = 0.32）とは違う点です。この点の母線電圧を求め、
% 母線 1・3 の P と |V|、母線 2 の P と Q を潮流設定にして平衡点を計算します
% （負荷のインピーダンスは flow=1 の値のままです）。
% 初期値は E(0) = E*、Δω(0) = 0、δ1(0) = 0、δ3(0) = −1（左）と −π/2（右）、AVR と PSS の
% 状態は平衡点の値で、50 秒間計算します。
% 引数は net.simulate にそのまま渡します（例: example_5_5(SampleTime=0.01)）。
% 出力を受け取ると、平衡点を計算したネットワークを返します（net = example_5_5(...)）。

    % 旧版と同じ数値解法の設定（ode15s、相対・絶対許容誤差 1e-8）
    c_opt = [{"Solver", "ode15s", "Tolerance", 1e-8, "AbsoluteTolerance", 1e-8, "Format", "struct"}, varargin];

    net = network_example3bus(flow=1, comp2="L_impedance", lossless="br23");
    g   = {net.a_Bus{1}.a_Component{1}, net.a_Bus{3}.a_Component{1}};
    for i = 1:2
        % AVR: 表 5.5 の例 1。式 (5.32) の増幅器は遅れのない比例 Vap = kap(Vref + Vpss − Vtr) なので tap = 0
        g{i}.set_avr("avr-ST1", parameter=struct(ttr=0.015, kap=200, tap=0, k0=0.04, ...
                     gamma_max=7, gamma_min=-6.4, Limiter=true));
        % PSS: 表 5.7 の例 2（出力の上下限なし）
        g{i}.set_pss("pss-PSS1", parameter=struct(kpss=20, tWS=10, td1=0.02, tn1=0.05, ...
                     td2=5.40, tn2=3.00, Vpss_max=Inf, Vpss_min=-Inf));
    end
    net.initialize(Solver="fsolve");

    % 平衡点の母線電圧: 内部電圧 E*（表 3.3 = flow=1 の平衡点の E）、δ* = [π/6; 0]。
    % 発電機は Xq = X'd なので、平衡点では E∠δ の電圧源と jX'd の直列です。負荷はインピーダンス
    % Z（flow=1 の値）で、発電機電流 (E e^{jδ} − V)/(jX'd) と負荷電流 −V/Z が Y V に等しい式を解きます。
    E     = [g{1}.rv_Xequilibrium(g{1}.sv_x == "Eq"); g{2}.rv_Xequilibrium(g{2}.sv_x == "Eq")];
    delta = [pi/6; 0];
    r_Z   = net.a_Bus{2}.a_Component{1}.rv_Uequilibrium;          % [R; X]
    Y     = net.get_admittance_matrix().Variables;
    Xp    = [g{1}.tab_parameter.dynamics.Xd_p; g{2}.tab_parameter.dynamics.Xd_p];
    y_sh  = [1/(1j*Xp(1)); 1/(r_Z(1) + 1j*r_Z(2)); 1/(1j*Xp(2))];
    Vc    = (diag(y_sh) + Y) \ ([1; 0; 1] .* y_sh .* [E(1)*exp(1j*delta(1)); 0; E(2)*exp(1j*delta(2))]);
    Sc    = Vc .* conj(Y*Vc);

    % 潮流設定: 母線 1 は PV（P、|V|）、母線 2 は PQ（P、Q）、母線 3 は slack（|V|、偏角）
    net.a_Bus{1}.tab_parameter.powerflow.V = abs(Vc(1));
    g{1}.tab_parameter.powerflow.P = real(Sc(1));
    net.a_Bus{2}.a_Component{1}.tab_parameter.powerflow.P = real(Sc(2));
    net.a_Bus{2}.a_Component{1}.tab_parameter.powerflow.Q = imag(Sc(2));
    net.a_Bus{3}.tab_parameter.powerflow.V    = abs(Vc(3));
    net.a_Bus{3}.tab_parameter.powerflow.Varg = angle(Vc(3));
    net.initialize(Solver="fsolve");

    r_d3 = [-1, -pi/2];
    sv_label = ["(a) δ3(0)-δ1(0) = -1", "(b) δ3(0)-δ1(0) = -1.57"];
    figure('Position', [100, 150, 850, 250])
    for k = 1:2
        sc = net.add_scenario("d" + k, Time=[0, 50]);
        sc.add_offset(g{1}.s_tag, "delta", 0 - g{1}.rv_Xequilibrium(g{1}.sv_x == "delta"), 0);
        sc.add_offset(g{2}.s_tag, "delta", r_d3(k) - g{2}.rv_Xequilibrium(g{2}.sv_x == "delta"), 0);
        sol = net.simulate("d" + k, c_opt{:});

        subplot(1, 2, k)
        plot(sol.t, sol.a_Bus{3}.a_Component{1}.x.omega, '--r', ...
             sol.t, sol.a_Bus{1}.a_Component{1}.x.omega, '-b', 'LineWidth', 1.5);
        xlim([0, 50])
        ylim([-0.03, 0.03])
        grid on
        xlabel(sv_label(k))
    end
    sgtitle('図5.12 角周波数偏差の初期値応答（系統安定化装置あり）')
    if nargout > 0, varargout{1} = net; end
end
