% 例3.19（プログラム3-38）の GUILDA v4 版: 負荷のインピーダンスを時間とともに変える入力に対する時間応答を計算します。
% 旧版の load_impedance の入力 u = [u1; u2] は z = real(z)*(1+u1) + 1j*imag(z)*(1+u2)
% と働き, u1 = u2 = 0.05*t/50 です。v4 の load-impedance の入力は R と X そのものなので、
% R と X に 0.05*t/50 倍の値を加える直線の時系列（"foh"）を与えます。
% 旧版の発電機1の入力（Pmech に加える値）は 0 なので、v4 では入力を加えません。

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

sc = net.add_scenario("example3_19", Time=[0, 50]);
z0 = load2.rv_Uequilibrium;            % 平衡点の [R; X]
sc.add_input(load2.s_tag, ["R";"X"], [0, 0, 0; 50, 0.05*z0.'], [0, 50]);

c_opt = {"Solver","ode15s", "Tolerance",1e-6, "AbsoluteTolerance",1e-6, ...
         "MaxStep",NaN, "InitialStep",NaN, "SampleTime",NaN, "Progress","none"};
res = net.simulate("example3_19", c_opt{:});

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
