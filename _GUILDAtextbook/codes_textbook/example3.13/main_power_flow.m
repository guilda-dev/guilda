% 例3.13（プログラム3-16）の GUILDA v4 版: 母線と送電線のデータから潮流計算を解きます。
% 旧版の calculate_power_flow(a_bus, a_branch) にあたる処理は
% PowerNetwork の calculate_powerflow です。

y12 = 1.3652 - 11.6040j;
y23 = -10.5107j;

net = PowerNetwork();
net.add_bus(V=2, Varg=0);  % 母線1: スラック母線
net.add_bus();             % 母線2: 負荷母線
net.add_bus(V=2);          % 母線3: 発電機母線
net.add_branch("pi", [1,2], R=real(1/y12), X=imag(1/y12));
net.add_branch("pi", [2,3], R=real(1/y23), X=imag(1/y23));

net.a_Bus{1}.add_component("gen-1axis");
net.a_Bus{2}.add_component("load-impedance", "P", -3, "Q", 0);
net.a_Bus{3}.add_component("gen-1axis", "P", 0.5);
evalc("net.a_Bus{1}.l_isSlack = true;");

pf = net.calculate_powerflow(Format="powerflow(tab)");
V = pf.V;  I = pf.I;  P = pf.P;  Q = pf.Q;

display('Vabs:'), display(abs(V)')
display('Vangle:'), display(angle(V)')
display('P:'), display(P')
display('Q:'), display(Q')
