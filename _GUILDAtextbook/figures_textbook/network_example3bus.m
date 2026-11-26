function net = network_example3bus(opt)
% 教科書の 3 母線系統（例 2.1）を GUILDA v4 で作り、潮流計算まで済ませて返します。
%
% net = network_example3bus(flow=1, comp2="L_impedance", lossless="br23")
%
% 引数は旧版（GUILDA v1.1）の network_example3bus と同じです（README の対応表）。
% - flow     : 潮流設定。0 = 表 2.2 の定常値、1 = 表 3.1、2 = 表 3.2。
% - comp2    : 母線 2 の機器。"L_impedance"（定インピーダンス負荷）、
%              "L_power"（定電力負荷）、"Gen_1axis"（同期発電機の一軸モデル）。
% - lossless : 損失なしにする送電線。"br12"（母線 1-2）、"br23"（母線 2-3）。
%
% flow=0 は表 2.2 の発電機の定常値 δ*, E* から母線電圧を計算し、母線 1 を slack 母線
% （その |V|・偏角）、母線 2・3 を PV 母線（その P・|V|）にします。平衡点は表 2.2 の
% δ*, E* に一致します（表 2.2 は母線 2 が発電機の場合の値です）。
% 旧版は 3 母線とも PV 母線（|V|・P は表の丸め値）で slack 母線がなく、fsolve の解は
% 表 2.2 から偏角が約 0.25 rad 回転し、丸めた |V| のため E が最大 6e-3 ずれます。
    arguments
        opt.flow     (1,1) double {mustBeMember(opt.flow, [0, 1, 2])} = 1
        opt.comp2    (1,1) string {mustBeMember(opt.comp2, ["L_impedance", "L_power", "Gen_1axis"])} = "L_impedance"
        opt.lossless string {mustBeMember(opt.lossless, ["br12", "br23"])} = strings(0,1)
    end

    net = PowerNetwork();
    net.tab_parameter.base.Hz = 60;                 % 系統周波数 60 Hz（ω0 = 120π rad/s）

    %% 送電線（π 型回路、対地静電容量なし）のアドミタンス y
    y12 = 1.3652 - 11.6041j;
    y23 = 1.9422 - 10.5107j;
    if ismember("br12", opt.lossless), y12 = -11.6041j; end
    if ismember("br23", opt.lossless), y23 = -10.5107j; end

    %% 発電機の定数（一軸モデル。表 2.1）
    gen = table([100; 18; 12], [10; 10; 10], [1.569; 1.651; 1.220], ...
                [0.936; 0.911; 0.667], [0.936; 0.911; 0.667], [5.14; 5.90; 8.97], ...
                'VariableNames', ["M", "D", "Xd", "Xq", "Xd_p", "Td_p"]);

    %% 潮流設定（P・Q は機器に、|V|・偏角は母線に与えます。NaN は未指定）
    %          母線 1               母線 2              母線 3
    switch opt.flow
        case 0      % 母線 1: slack、母線 2: PV、母線 3: PV（表 2.2 の δ*, E* から計算）
            delta = [0.4656; 1.0903; 0.6067];      % 表 2.2 の δ*
            E     = [1.4363; 1.8095; 1.1030];      % 表 2.2 の E*
            % 発電機は Xq = X'd なので、平衡点では E∠δ の電圧源と jX'd の直列です。
            % 発電機電流 (E e^{jδ} - V)/(jX'd) = Y V から母線電圧 V を求めます。
            Y  = [y12, -y12, 0; -y12, y12 + y23, -y23; 0, -y23, y23];
            yd = 1 ./ (1j*gen.Xd_p);
            Vc = (diag(yd) + Y) \ (yd .* E .* exp(1j*delta));
            Pc = real(Vc .* conj(Y*Vc));
            V  = abs(Vc).';  Varg = [angle(Vc(1)), 0, 0];
            P  = [NaN,    Pc(2),  Pc(3)];
            Q  = [NaN,    NaN,    NaN];
            i_slack = 1;
        case 1      % 母線 1: PV、母線 2: PQ、母線 3: slack
            V  = [2,      1,      2];      Varg = [0, 0, 0];
            P  = [0.5,    -3,     NaN];
            Q  = [NaN,    0,      NaN];
            i_slack = 3;
        case 2      % 母線 1: slack、母線 2: PQ、母線 3: PV
            V  = [2,      1,      2];      Varg = [0, 0, 0];
            P  = [NaN,    -3,     0.5];
            Q  = [NaN,    0,      NaN];
            i_slack = 1;
    end
    for i = 1:3
        net.add_bus(V=V(i), Varg=Varg(i));
    end

    %% 送電線（R + jX = 1/y）
    net.add_branch("pi", [1, 2], "R", real(1/y12), "X", imag(1/y12), "C", 0);
    net.add_branch("pi", [2, 3], "R", real(1/y23), "X", imag(1/y23), "C", 0);

    %% 機器
    net.a_Bus{1}.add_component("gen-1axis", "P", P(1), "Q", Q(1), "parameter", gen(1,:));
    switch opt.comp2
        case "L_impedance"
            net.a_Bus{2}.add_component("load-impedance", "P", P(2), "Q", Q(2));
        case "L_power"
            net.a_Bus{2}.add_component("load-power", "P", P(2), "Q", Q(2));
        case "Gen_1axis"
            net.a_Bus{2}.add_component("gen-1axis", "P", P(2), "Q", Q(2), "parameter", gen(2,:));
    end
    net.a_Bus{3}.add_component("gen-1axis", "P", P(3), "Q", Q(3), "parameter", gen(3,:));
    net.a_Bus{i_slack}.l_isSlack = true;

    %% 潮流計算と平衡点の計算
    % 旧版と同じく fsolve で解きます（v4 の既定の Newton 法は、flow=1 で平坦な初期値
    % （母線 2 の |V| = 1）から発散します）。
    net.initialize(Solver="fsolve");
end
