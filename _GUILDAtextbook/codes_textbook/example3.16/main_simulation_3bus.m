% 例3.16（プログラム3-27）の GUILDA v4 版: 機器のクラスを使って 3 母線系統の時間応答を計算します。
% 旧版の generator（1 軸モデル）は gen-1axis, load_impedance は load-impedance,
% simulate_power_system は PowerNetwork の simulate にあたります。
% ソルバーの設定は旧版の simulate_power_system と同じです（ode15s, RelTol = 1e-6,
% AbsTol は odeset の既定値 1e-6）。

y12 = 1.3652 - 11.6040j;
y23 = -10.5107j;

net = PowerNetwork();
net.tab_parameter.base.Hz = 60;   % omega0 = 60*2*pi
net.add_bus(V=2, Varg=0);         % 母線1: スラック母線（|V| = 2, ∠V = 0）
net.add_bus();                    % 母線2: 負荷母線（P = -3, Q = 0）
net.add_bus(V=2);                 % 母線3: 発電機母線（P = 0.5, |V| = 2）
net.add_branch("pi", [1,2], R=real(1/y12), X=imag(1/y12));
net.add_branch("pi", [2,3], R=real(1/y23), X=imag(1/y23));

% 旧版 generator(omega0, M, D, tau, X, X_prime, ...) の X は Xd, tau は Td_p,
% X_prime は Xd_p と Xq（非突極機: 両軸の過渡リアクタンスが等しい）にあたります。
sv_para = ["M","D","Xd","Xq","Xd_p","Td_p"];
para1 = array2table([100, 10, 1.569, 0.936, 0.936, 5.14], VariableNames=sv_para);
para3 = array2table([ 12, 10, 1.220, 0.667, 0.667, 8.97], VariableNames=sv_para);
gen1  = net.a_Bus{1}.add_component("gen-1axis", "parameter", para1);
load2 = net.a_Bus{2}.add_component("load-impedance", "P", -3, "Q", 0);
gen3  = net.a_Bus{3}.add_component("gen-1axis", "P", 0.5, "parameter", para3);
evalc("net.a_Bus{1}.l_isSlack = true;");
net.initialize();                 % 潮流計算と平衡点の計算

sc = net.add_scenario("example3_16", Time=[0, 50]);
% 旧版は Pmech, Vfield, 負荷インピーダンス z2 を数値で与えます。v4 の機器の入力は
% 平衡点の値（潮流計算から決まる値）に保たれるため、旧版の値との差を一定の入力として
% シミュレーションの全区間 [0, 50] に加えます。
sc.add_input(gen1.s_tag,  ["Pmech";"Vfield"], [2.5158; 2.7038] - gen1.rv_Uequilibrium,  [0, 50]);
sc.add_input(load2.s_tag, ["R";"X"],          [1.3224; 0]      - load2.rv_Uequilibrium, [0, 50]);
sc.add_input(gen3.s_tag,  ["Pmech";"Vfield"], [0.5000; 2.1250] - gen3.rv_Uequilibrium,  [0, 50]);

% 初期値も旧版の値です。平衡点との差を時刻 0 の状態のオフセットとして与えます。
% 母線の電圧と電流（代数変数）の初期値は v4 が微分変数から求めます。
x0 = [0.5357 + pi/6; 0; 2.3069 + 0.1; 0.0390; 0; 2.0654];
sc.add_offset(gen1.s_tag, ["delta";"omega";"Eq"], x0(1:3) - gen1.rv_Xequilibrium, 0);
sc.add_offset(gen3.s_tag, ["delta";"omega";"Eq"], x0(4:6) - gen3.rv_Xequilibrium, 0);

c_opt = {"Solver","ode15s", "Tolerance",1e-6, "AbsoluteTolerance",1e-6, ...
         "MaxStep",NaN, "InitialStep",NaN, "SampleTime",NaN, "Progress","none"};
res = net.simulate("example3_16", c_opt{:});

% 旧版の出力と同じ形にそろえます: x{k} は機器 k の状態, V(:,k) は母線 k の電圧,
% I(:,k) は機器 k が母線 k に流し込む電流（複素数）です。
sol = res.odeResults;
t = sol.t;
x = cell(3, 1);
V = zeros(numel(t), 3);
I = zeros(numel(t), 3);
for k = 1:3
    x{k}    = sol.Bus(k).Component(1).X{:,:};
    V(:, k) = sol.Bus(k).V{:,1} + 1j*sol.Bus(k).V{:,2};
    I(:, k) = sol.Bus(k).Component(1).I{:,1} + 1j*sol.Bus(k).Component(1).I{:,2};
end

plot(t, [x{1}(:, 2), x{3}(:, 2)])
