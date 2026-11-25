% 例3.11（プログラム3-11）の GUILDA v4 版: 母線の種類ごとの条件で潮流計算を解きます。
% 旧版は母線クラス bus_slack, bus_load, bus_generator の制約式を fsolve で解きます。
% v4 では母線と機器の潮流設定（スラック母線, P・Q 指定, P・|V| 指定）を与え、
% calculate_powerflow で解きます。アドミタンス行列は旧版の Y と同じ送電線から作ります。

y12 = 1.3652 - 11.6040j;   % 母線1-2間の送電線のアドミタンス
y23 = -10.5107j;           % 母線2-3間の送電線のアドミタンス

net = PowerNetwork();
net.add_bus(V=2, Varg=0);  % 母線1: スラック母線（|V| = 2, ∠V = 0）
net.add_bus();             % 母線2: 負荷母線（P, Q を指定）
net.add_bus(V=2);          % 母線3: 発電機母線（P, |V| = 2 を指定）
net.add_branch("pi", [1,2], R=real(1/y12), X=imag(1/y12));
net.add_branch("pi", [2,3], R=real(1/y23), X=imag(1/y23));

net.a_Bus{1}.add_component("gen-1axis");                       % P, Q は潮流計算で決まる
net.a_Bus{2}.add_component("load-impedance", "P", -3, "Q", 0); % P = -3, Q = 0
net.a_Bus{3}.add_component("gen-1axis", "P", 0.5);             % P = 0.5
evalc("net.a_Bus{1}.l_isSlack = true;");                       % 母線1をスラック母線にする

pf = net.calculate_powerflow(Format="powerflow(tab)");
V = pf.V;  I = pf.I;  P = pf.P;  Q = pf.Q;
Vabs = abs(V);
Vangle = angle(V);
display('Vabs:'), display(Vabs')
display('Vangle:'), display(Vangle')
display('P:'), display(P')
display('Q:'), display(Q')
