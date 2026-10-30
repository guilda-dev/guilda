% F4 最適潮流計算 (optimize_powerflow)
%
% 3 つの方式 "ELD" / "DC OPF" / "AC OPF" で最適潮流を計算し、物理的な妥当性を確認する。
%   - v4 の呼び出し形式 [result, flag, output] と結果クラス OPFResult
%   - Name-Value による一時的な設定の上書き (net.solver_OPF は変わらない)
%   - v3 の呼び出し形式 (6 出力、"methods" オプション) の互換
%   - 解が得られる (flag > 0)
%   - 需給バランス (発電の合計 = 負荷 (+ 損失))、母線ごとの電力・電流のつり合い
%   - 負荷は潮流設定の値のまま、発電機出力・電圧は上下限の範囲内
%   - ELD は等増分費用、DC OPF (送電制約なし) は ELD と同じ配分
%   - AC OPF の費用は ELD 以上、潮流計算の解での費用以下
%   - 手計算できる小さな系統: DC の混雑価格 (3 母線ループ)、AC の閉じた形と KKT 条件 (2 母線)
%   - 送電線の Imax / Smax が効く AC OPF が解ける
%   - ラグランジュ乗数 (節点価格) = 最適費用の負荷に関する感度 (差分で確認)
%   - MATPOWER 形式への変換 (tools.network_to_mpc) と MATPOWER の case14 の最適解との一致
%   - MATPOWER との直接比較 (MATPOWER がパスに無いときは SKIP)
% 費用関数は機器の tab_parameter.OPF、制約は各クラスの tab_parameter.operation で設定する。
%
% 実行: runtests("DebugScript.test_F4_opf")  または  DebugScript.run_all("Features","F4")
%
% [result, flag, output] = net.optimize_powerflow(Method=..., Name, Value)
%   result.tab_bus    : 母線ごとの解
%   result.tab_cub    : 母線への接続 (機器 "<機器名>"、送電線の端 "<送電線名>_<母線名>") ごとの、母線への注入
%   result.tab_branch : 送電線ごとの両端の潮流 (送電線へ流れ込む向き)
% 設定の既定値は net.solver_OPF (OptimalPowerFlow)。Name-Value はその呼び出しだけ上書きする。
% v3 の形式 (6 出力、"methods" オプション) は警告付きで使える。

% 共通設定 (各テストの前に毎回実行される)
tol = 1e-5;
is_load = @(c) isa(c,"component.load.abstract");


%% Economic load dispatch
% 9 母線系統。送電線を無視して、負荷の合計を発電機で経済的に配分する
net = DebugScript.helper.build_9bus();
P_load = -(-1.0 - 0.8 - 1.2);

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
assert(istable(tab_bus) && height(tab_bus) == numel(net.a_Bus))

% 需給バランス: 母線注入の合計 = 0 (損失なし)
assert(abs(sum(tab_bus.P)) < tol)
assert(abs(sum(tab_bus{["B001","B002","B003"],"P"}) - P_load) < tol)

% 機器の行の合計 = 母線の P、負荷は指定値のまま、送電線の端は NaN
assert(abs(tab_cub{"LPQ1B005","P"} + 1.0) < tol)
assert(all(isnan(tab_cub{"EL004_B004","P"})))
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    if isempty(bus.a_Component); continue; end
    assert(abs(sum(tab_cub{string(bus.a_Component),"P"}) - tab_bus{string(bus),"P"}) < tol)
end

% 3 台とも費用 P^2 + P で同じなので、等分 (各 1.0) が最適
assert(all(abs(tab_bus{["B001","B002","B003"],"P"} - 1) < 1e-4))


%% ELD with a binding generator limit
% 上限に達した発電機以外は等増分費用 (2*HP*P + fP が等しい)
net = DebugScript.helper.build_9bus();
net.a_Bus{1}.a_Component{1}.tab_parameter.operation.Pmax = 0.5;
net.a_Bus{3}.a_Component{1}.tab_parameter.OPF.HP = 2;

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")); tab_bus = res.tab_bus;
assert(flag > 0)
assert(abs(sum(tab_bus.P)) < tol)
P = tab_bus{["B001","B002","B003"],"P"};
assert(P(1) <= 0.5 + tol && abs(P(1) - 0.5) < 1e-4)
% 残り 2.5 を 2*P2 + 1 = 4*P3 + 1 で配分 → P2 = 5/3, P3 = 5/6
assert(abs(2*P(2) + 1 - (4*P(3) + 1)) < 1e-4)
assert(abs(P(2) - 5/3) < 1e-4 && abs(P(3) - 5/6) < 1e-4)


%% DC optimal power flow
% DC 近似 (|V| = 1、損失なし) の最適潮流
net = DebugScript.helper.build_9bus();
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
assert(all(ismember(["Varg","V","P"], tab_bus.Properties.VariableNames)))
assert(abs(sum(tab_bus.P)) < tol)
assert(all(tab_bus.V == 1))

% 基準母線 (B001) の位相は 0
assert(abs(tab_bus{"B001","Varg"}) < tol)

% 送電線の端の P = 母線への流入 b_ij*(θj-θi)、両端の和 = 0 (損失なし)
for k = 1:numel(net.a_Branch)
    br  = net.a_Branch{k};
    str = string(br) + "_" + string(br.a_Bus);
    Y   = br.get_admittance_matrix();
    th  = tab_bus{string(br.a_Bus),"Varg"};
    assert(abs(tab_cub{str(1),"P"} - imag(Y(1,2))*(th(2)-th(1))) < tol)
    assert(abs(tab_cub{str(1),"P"} + tab_cub{str(2),"P"}) < tol)
end

% 母線ごとのつり合い: 機器と送電線の端の注入の合計 = 0
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    l_bus = endsWith(tab_cub.Properties.RowNames, "_"+string(bus)) | ismember(tab_cub.Properties.RowNames, string(bus.a_Component));
    assert(abs(sum(tab_cub.P(l_bus))) < tol)
end

% 送電制約が無いので、配分は ELD と同じ
tab_ELD = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")).tab_bus;
assert(max(abs(tab_bus.P - tab_ELD.P)) < 1e-4)


%% AC optimal power flow
% 交流潮流方程式を制約にした最適潮流。電圧は 0.95-1.05 に制限する
net = DebugScript.helper.build_9bus();
for i = 1:numel(net.a_Bus)
    net.a_Bus{i}.tab_parameter.operation{1,["Vmin","Vmax"]} = [0.95, 1.05];
end
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
assert(all(ismember(["Varg","V","P","Q","Vphasor","Iphasor"], tab_bus.Properties.VariableNames)))

% 解は潮流方程式を満たし、注入の合計 = 送電損失 (> 0)
Y = net.get_admittance_matrix.Variables;
assert(norm(tab_bus.Vphasor .* conj(Y*tab_bus.Vphasor) - (tab_bus.P + 1j*tab_bus.Q)) < 1e-4)
S_loss = DebugScript.helper.branch_losses(net, tab_bus.Vphasor);
assert(abs(sum(tab_bus.P) - real(S_loss)) < 1e-4)
assert(real(S_loss) > 0)

% 負荷は指定値のまま、電圧は上下限 (Vmin, Vmax) の範囲内、基準母線の位相は 0
assert(abs(tab_bus{"B005","P"} + 1.0) < tol && abs(tab_bus{"B005","Q"} + 0.1) < tol)
assert(all(tab_bus.V >= 0.95 - tol & tab_bus.V <= 1.05 + tol))
assert(abs(tab_bus{"B001","Varg"}) < tol)

% 母線ごとの電流のつり合い (KCL): 機器と送電線の端の注入電流の合計 = 母線シャントの電流
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    l_bus = endsWith(tab_cub.Properties.RowNames, "_"+string(bus)) | ismember(tab_cub.Properties.RowNames, string(bus.a_Component));
    y_sh  = bus.tab_parameter.dynamics{1,["Gshunt","Bshunt"]} * [1;1j];
    assert(abs(sum(tab_cub.Iphasor(l_bus)) - y_sh*tab_bus{string(bus),"Vphasor"}) < 1e-4)
end

% 費用: ELD (損失なしの緩和問題) 以上、潮流計算の解 (実行可能解) 以下
J_AC = DebugScript.helper.opf_cost(net, tab_cub);
tab_cub_ELD = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")).tab_cub;
assert(J_AC >= DebugScript.helper.opf_cost(net, tab_cub_ELD) - 1e-6)
tab_PF = DebugScript.helper.quiet(@() net.calculate_powerflow().tab_bus);
assert(all(tab_PF.V >= 0.95 & tab_PF.V <= 1.05))   % 潮流解が OPF の制約を満たすことの確認
assert(J_AC <= DebugScript.helper.opf_cost(net, DebugScript.helper.pf_component_power(net, tab_PF)) + 1e-6)


%% AC OPF respects generator limits
% 発電機の出力上限・無効電力の範囲が守られ、上限に達する
net = DebugScript.helper.build_9bus();
gen = net.a_Bus{1}.a_Component{1};
gen.tab_parameter.operation{1,["Pmax","Qmin","Qmax"]} = [0.6, -0.3, 0.3];
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
P1 = tab_cub{string(gen),"P"};
Q1 = tab_cub{string(gen),"Q"};
assert(P1 <= 0.6 + tol && abs(P1 - 0.6) < 1e-4)
assert(Q1 >= -0.3 - tol && Q1 <= 0.3 + tol)
assert(abs(tab_bus{"B001","P"} - P1) < tol)


%% IEEE14 ELD and DC OPF
% IEEE 14 母線系統 (MATPOWER case14 の費用と出力制限)。負荷はそのまま、ELD と DC OPF
% (送電制約なし) の配分は一致する
net = DebugScript.helper.build_ieee14();
a_Com  = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
l_load = cellfun(is_load, a_Com);
str_load = string(a_Com(l_load));
P_load = cellfun(@(c) c.tab_parameter.powerflow.P, a_Com(l_load));

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
assert(abs(sum(tab_bus.P)) < tol)
assert(max(abs(tab_cub{str_load,"P"} - P_load)) < tol)
% 等増分費用: B001 (430.29 P^2 + 2000 P) と B002 (2500 P^2 + 2000 P) で負荷 2.59 を賄い、
% 限界費用 2*430.29*P1 + 2000 = 2*2500*P2 + 2000 = 3901.6 < 4000 なので他の 3 台は Pmin = 0
%   → P1 = 2.59*5000/(860.585+5000) = 2.2097, P2 = 0.3803 (rundcopf(case14) の 220.97, 38.03 MW)
str_gen = string(cellfun(@(b) b.a_Component{1}, net.a_Bus([1 2 3 6 8]), "UniformOutput", false));
r_HP1 = 2*430.292599;
P1 = -sum(P_load)*5000/(r_HP1+5000);
assert(max(abs(tab_cub{str_gen,"P"} - [P1; -sum(P_load)-P1; 0; 0; 0])) < 1e-4)

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF")); tab_DC = res.tab_bus; tab_cub_DC = res.tab_cub;
assert(flag > 0)
assert(abs(sum(tab_DC.P)) < tol)
assert(max(abs(tab_cub_DC{string(a_Com),"P"} - tab_cub{string(a_Com),"P"})) < 1e-4)


%% IEEE14 AC OPF
% 潮流方程式・負荷・電圧制約を満たし、費用は潮流計算の解以下
net = DebugScript.helper.build_ieee14();
a_Com  = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
l_load = cellfun(is_load, a_Com);
str_load = string(a_Com(l_load));
PQ_load = cell2mat(cellfun(@(c) c.tab_parameter.powerflow{1,["P","Q"]}, a_Com(l_load), "UniformOutput", false));

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
Y = net.get_admittance_matrix.Variables;
assert(norm(tab_bus.Vphasor .* conj(Y*tab_bus.Vphasor) - (tab_bus.P + 1j*tab_bus.Q)) < 1e-4)
S_loss = DebugScript.helper.branch_losses(net, tab_bus.Vphasor);
assert(abs(sum(tab_bus.P) - real(S_loss)) < 1e-4)
assert(max(abs(tab_cub{str_load,["P","Q"]} - PQ_load), [], "all") < tol)
Vmin = cellfun(@(b) b.tab_parameter.operation.Vmin, net.a_Bus);
Vmax = cellfun(@(b) b.tab_parameter.operation.Vmax, net.a_Bus);
assert(all(tab_bus.V >= Vmin - tol & tab_bus.V <= Vmax + tol))

J_AC  = DebugScript.helper.opf_cost(net, tab_cub);
tab_cub_ELD = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")).tab_cub;
assert(J_AC >= DebugScript.helper.opf_cost(net, tab_cub_ELD) - 1e-6)
tab_PF = DebugScript.helper.quiet(@() net.calculate_powerflow().tab_bus);
assert(J_AC <= DebugScript.helper.opf_cost(net, DebugScript.helper.pf_component_power(net, tab_PF)) + 1e-6)


%% DC OPF congestion prices on a 3-bus loop
% 3 母線ループ (リアクタンスはすべて 0.1、損失なし)。B001 の発電機 (費用 P^2+P) と B002 の
% 発電機 (P^2+2P) で B003 の負荷 1.0 を賄う。
%   送電制約なし: 等増分費用 2*P1+1 = 2*P2+2 → P1 = 0.75, P2 = 0.25、全母線の価格 2.5
%   B001-B003 の容量 0.5: 潮流 = 2/3*P1 + 1/3*P2 (PTDF) と P1 + P2 = 1 から P1 <= 0.5
%     → P1 = P2 = 0.5、限界費用 2, 3。節点価格は π1 = π3 - 2/3*μ, π2 = π3 - 1/3*μ
%     → 送電制約の乗数 μ = 3、負荷母線の価格 π3 = 4 (どちらの発電機の限界費用よりも高い)
% 節点価格 (負荷 1 単位あたりの費用増) = -lambda.Constraints.balancedP_<母線>
net = build_loop3();
str_bus = string(net.a_Bus);
str_gen = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(1:2), "UniformOutput", false));
price = @(r) -cellfun(@(s) r.lambda.Constraints.("balancedP_"+s), cellstr(str_bus));

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(max(abs(res.tab_cub{str_gen,"P"} - [0.75; 0.25])) < 1e-6)
assert(max(abs(price(res) - 2.5)) < 1e-6)

br13 = net.a_Branch{3};
assert(isequal(string(br13.a_Bus(:)).', ["B001","B003"]))
br13.tab_parameter.operation.Pmax = 0.5;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(max(abs(res.tab_cub{str_gen,"P"} - [0.5; 0.5])) < 1e-6)
assert(abs(res.tab_branch{string(br13),"Pfrom"} - 0.5) < 1e-6)
assert(max(abs(price(res) - [2; 3; 4])) < 1e-6)
assert(abs(res.r_cost - (0.5^2+0.5 + 0.5^2+2*0.5)) < 1e-6)
% 送電制約の乗数: 両端の変数の上下限の乗数の合計 = μ = 3
str_end = string(br13) + "_" + string(br13.a_Bus);
mu = sum(cellfun(@(s) res.lambda.Variables.(s).Upper + res.lambda.Variables.(s).Lower, cellstr(str_end)));
assert(abs(mu - 3) < 1e-6)


%% AC OPF on a 2-bus system matches the closed form
% B001 の発電機 (費用 = P) から送電線 R+jX を通して B002 の負荷 PL+jQL へ送る。
% 負荷は固定なので、費用最小 = 損失最小 = B001 の電圧を上限 Vmax にする。
% V1 を与えると受電端電圧は閉じた形で求まる:
%   V2^2 = (a + sqrt(a^2 - 4(R^2+X^2)(PL^2+QL^2)))/2,  a = V1^2 - 2(R*PL + X*QL)
%   P1 = PL + R(PL^2+QL^2)/V2^2,  Q1 = QL + X(PL^2+QL^2)/V2^2
% KKT 条件: V1 の上限の乗数 = 費用の V1 に関する感度 -dP1/dV1 (V1 以外に自由度はない)
[R, X, PL, QL, Vmax] = deal(0.02, 0.1, 0.8, 0.3, 1.05);
net = PowerNetwork("OPF2Bus");
net.add_bus("Vmin",0.95, "Vmax",Vmax);
net.add_bus("Vmin",0.90, "Vmax",1.10);
net.add_branch("pi", [1,2], "R",R, "X",X);
gen = net.a_Bus{1}.add_component("gen-park");
ld  = net.a_Bus{2}.add_component("load-power", "P",-PL, "Q",-QL);
gen.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]} = [0, 1, 0, 0];
ld.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]}  = [0, 0, 0, 0];

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", Tolerance=1e-10));
assert(flag > 0)
V2  = @(V1) sqrt(((V1^2-2*(R*PL+X*QL)) + sqrt((V1^2-2*(R*PL+X*QL))^2 - 4*(R^2+X^2)*(PL^2+QL^2)))/2);
P1  = @(V1) PL + R*(PL^2+QL^2)/V2(V1)^2;
Q1  = @(V1) QL + X*(PL^2+QL^2)/V2(V1)^2;
assert(abs(res.tab_bus{"B001","V"} - Vmax) < 1e-6)
assert(abs(res.tab_bus{"B002","V"} - V2(Vmax)) < 1e-6)
assert(abs(res.tab_cub{string(gen),"P"} - P1(Vmax)) < 1e-6)
assert(abs(res.tab_cub{string(gen),"Q"} - Q1(Vmax)) < 1e-6)
assert(abs(res.r_cost - P1(Vmax)) < 1e-6)
assert(res.tab_bus{"B002","Varg"} < 0)
h  = 1e-6;
dJ = (P1(Vmax+h) - P1(Vmax-h))/(2*h);
mu = res.lambda.Variables.B001.Upper;                 % [Varg; V]
assert(dJ < 0 && abs(mu(2) + dJ) < 1e-5 && abs(mu(1)) < 1e-8)


%% AC OPF with active branch current and power limits
% 9 母線系統で最大電流の送電線の Imax (または Smax) を制約なしの解の 80% にする。
% 二乗の形 (|I|^2 <= Imax^2, P^2+Q^2 <= Smax^2) なので、電流 0 の初期点でも解ける。
net = DebugScript.helper.build_9bus();
res0 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
[~, k] = max(abs(res0.tab_branch.Ifrom));
br = net.a_Branch{k};
str_end = string(br) + "_" + string(br.a_Bus);

r_Imax = 0.8*max(abs(res0.tab_branch{k,["Ifrom","Ito"]}));
br.tab_parameter.operation.Imax = r_Imax;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
assert(flag > 0)
r_I = max(abs(res.tab_branch{k,["Ifrom","Ito"]}));
assert(r_I <= r_Imax + 1e-6 && r_I >= r_Imax - 1e-4)
assert(res.r_cost > res0.r_cost)
assert(max(cellfun(@(s) res.lambda.Constraints.("Imax_"+s), cellstr(str_end))) > 0)

br.tab_parameter.operation.Imax = inf;
S0 = abs(res0.tab_branch{k,["Pfrom","Pto"]} + 1j*res0.tab_branch{k,["Qfrom","Qto"]});
r_Smax = 0.8*max(S0);
br.tab_parameter.operation.Smax = r_Smax;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
assert(flag > 0)
r_S = max(abs(res.tab_branch{k,["Pfrom","Pto"]} + 1j*res.tab_branch{k,["Qfrom","Qto"]}));
assert(r_S <= r_Smax + 1e-6 && r_S >= r_Smax - 1e-4)
assert(res.r_cost > res0.r_cost)


%% Duals match finite-difference sensitivities of the optimal cost
% 節点価格 -lambda (balancedP_<母線>, balancedQ_<母線>) = 最適費用の負荷に関する感度。
% 負荷の費用は 0 にする (負荷は固定なので、その費用は定数として費用に加わるだけ)。
% DC: 送電制約が効いた 3 母線ループ、全母線に負荷を置いて中心差分で確認
net = build_loop3();
net.a_Branch{3}.tab_parameter.operation.Pmax = 0.5;
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
h = 1e-3;
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    ld  = bus.a_Component{end};
    fd  = fd_load(net, "DC OPF", ld, "P", h, {});
    assert(abs(fd + res.lambda.Constraints.("balancedP_"+string(bus))) < 1e-6, string(bus))
end
% AC: 9 母線系統の 3 つの負荷の P と Q
net = DebugScript.helper.build_9bus();
a_Com  = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
a_Load = a_Com(cellfun(is_load, a_Com));
for k = 1:numel(a_Load)
    a_Load{k}.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]} = [0, 0, 0, 0];
end
c_opt = {"Tolerance", 1e-10};
res = DebugScript.helper.quiet(@() net.optimize_powerflow("Method", "AC OPF", c_opt{:}));
assert(res.l_success)
for k = 1:numel(a_Load)
    str_bus = string(a_Load{k}.a_Bus);
    for str_pq = ["P","Q"]
        lam = res.lambda.Constraints.("balanced"+str_pq+"_"+str_bus);
        fd  = fd_load(net, "AC OPF", a_Load{k}, str_pq, h, c_opt);
        assert(abs(fd + lam) < 1e-4*max(1, abs(lam)), str_bus + " " + str_pq + sprintf(": FD %.6f, -lambda %.6f", fd, -lam))
    end
end


%% Conversion to a MATPOWER case
% tools.network_to_mpc は MATPOWER なしで動く。mpc から組み立てた Ybus (MATPOWER の
% 送電線モデル) が GUILDA のアドミタンス行列と一致し、負荷・発電機・費用が対応することを確認する。
net  = DebugScript.helper.build_ieee14();
mpc  = tools.network_to_mpc(net);
Y    = net.get_admittance_matrix.Variables;
assert(norm(mpc_ybus(mpc) - Y) < 1e-10)
assert(isequal(size(mpc.bus), [14 13]) && size(mpc.gen,1) == 5 && size(mpc.gencost,1) == 5)
assert(isequal(mpc.bus_name(:).', cellstr(string(net.a_Bus)).'))
assert(mpc.bus(cellfun(@(b) b.l_isSlack, net.a_Bus), 2) == 3)
ld = net.a_Bus{3}.a_Component{end};
assert(isa(ld, "component.load.abstract"))
assert(max(abs(mpc.bus(3,3:4) + 100*ld.tab_parameter.powerflow{1,["P","Q"]})) < 1e-12)
gen = net.a_Bus{1}.a_Component{1};
assert(max(abs(mpc.gencost(1,5:6) - [gen.tab_parameter.OPF.HP/1e4, gen.tab_parameter.OPF.fP/100])) < 1e-15)

% 同梱の IEEE14 を変換すると、MATPOWER の case14 と同じ負荷・シャント・電圧上下限・線路・発電機・費用になる
mpc14 = DebugScript.helper.case14_data();
assert(max(abs(mpc.bus(:,[3:6 12 13]) - mpc14.bus(:,[3:6 12 13])), [], "all") < 1e-12)
assert(max(abs(mpc.bus(:,3:6) - mpc14.bus(:,3:6)), [], "all") < 1e-12)
assert(max(abs(sortrows(mpc.branch(:,[1:5 9 10])) - sortrows(mpc14.branch(:,[1:5 9 10]))), [], "all") < 1e-12)
assert(max(abs(mpc.gen(:,[1 4 5 9 10]) - mpc14.gen(:,[1 4 5 9 10])), [], "all") < 1e-12)
assert(max(abs(mpc.gencost(:,4:7) - mpc14.gencost(:,4:7)), [], "all") < 1e-12)

% 両端のシャントが非対称な変圧器 (two_winding_transformer の C) は母線のシャントへ移す
net2 = PowerNetwork("Mpc2Bus");
net2.add_bus();  net2.add_bus("Bshunt", 0.1);
net2.add_branch("two_winding_transformer", [1,2], "R",0.01, "X",0.2, "C",0.05, "Tap",0.95);
net2.a_Bus{1}.add_component("gen-park");
net2.a_Bus{2}.add_component("load-power", "P",-0.5, "Q",-0.1);
mpc2 = tools.network_to_mpc(net2);
assert(norm(mpc_ybus(mpc2) - net2.get_admittance_matrix.Variables) < 1e-12)
assert(abs(mpc2.bus(1,6) - 5) < 1e-12 && abs(mpc2.bus(2,6) - 10) < 1e-12 && mpc2.branch(1,9) == 0.95)
% MATPOWER で表せない設定はエラー
net2.a_Branch{1}.tab_parameter.operation.Imax = 1;
assert(error_id(@() tools.network_to_mpc(net2)) == "GUILDA:network_to_mpc:Unsupported")


%% AC and DC OPF reproduce the MATPOWER case14 optimum
% network.IEEE14bus の線路定数・負荷・発電機の OPF 設定は MATPOWER の case14
% (DebugScript.helper.case14_data) と同じなので、MATPOWER の最適解と一致する
% (MATPOWER 不要。値は MATPOWER の runopf / rundcopf の結果)。
%   AC: 費用 8081.53 $/hr、Pg = [194.33, 36.72, 28.74, 0.00, 8.50] MW
%   DC: 費用 7642.59 $/hr、Pg = [220.97, 38.03, 0, 0, 0] MW
% DC は MATPOWER と同じ b = 1/X になるよう R = 0 にする (GUILDA の DC は b = Im(Y_ij) を使う)。
net = DebugScript.helper.build_ieee14();
mpc = DebugScript.helper.case14_data();
assert(norm(net.get_admittance_matrix.Variables - mpc_ybus(mpc)) < 1e-12)
str_gen = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(mpc.gen(:,1)), "UniformOutput", false));
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", Tolerance=1e-10));
assert(flag > 0)
assert(abs(res.r_cost - 8081.53) < 0.01, sprintf("AC cost %.4f", res.r_cost))
assert(max(abs(100*res.tab_cub{str_gen,"P"} - [194.33; 36.72; 28.74; 0; 8.50])) < 0.01)
assert(all(res.tab_bus.V >= 0.94 - 1e-6 & res.tab_bus.V <= 1.06 + 1e-6))

for k = 1:numel(net.a_Branch)
    net.a_Branch{k}.tab_parameter.dynamics.R = 0;
end
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(abs(res.r_cost - 7642.59) < 0.01, sprintf("DC cost %.4f", res.r_cost))
assert(max(abs(100*res.tab_cub{str_gen,"P"} - [220.97; 38.03; 0; 0; 0])) < 0.01)


%% AC and DC OPF agree with MATPOWER on IEEE 14-bus
% MATPOWER (runopf) がパスに無いときは SKIP。
% case14 に合わせた network.IEEE14bus を tools.network_to_mpc で変換し、MATPOWER で解いた
% 結果と費用・電圧・出力を比べる。変換した mpc は MATPOWER の case14 と同じ問題になる。
if ~exist("runopf", "file")
    error("DebugScript:Skip", "MATPOWER (runopf) がパスに無い")
end
net = DebugScript.helper.build_ieee14();
mpc14 = loadcase("case14");
assert(DebugScript.helper.quiet(@() set_case14(net, mpc14)) < 1e-12)
mpc = tools.network_to_mpc(net);
str_gen = string(mpc.gen_name);
mpc = rmfield(mpc, ["bus_name","gen_name","branch_name"]);
mpopt = mpoption("verbose", 0, "out.all", 0, "opf.ac.solver", "MIPS", "mips.gradtol", 1e-10, "mips.comptol", 1e-10, "mips.costtol", 1e-10);
r14 = runopf(mpc14, mpopt);
rmp = runopf(mpc, mpopt);
assert(r14.success && rmp.success)
assert(abs(rmp.f - r14.f) < 1e-6*r14.f)
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", Tolerance=1e-10));
assert(flag > 0)
assert(abs(res.r_cost - rmp.f) < 1e-5*rmp.f, sprintf("AC cost: GUILDA %.6f, MATPOWER %.6f", res.r_cost, rmp.f))
assert(max(abs(res.tab_bus.V - rmp.bus(:,8))) < 1e-4)
assert(max(abs(res.tab_bus.Varg - rmp.bus(:,9)*pi/180)) < 1e-4)
assert(max(abs(res.tab_cub{str_gen,"P"} - rmp.gen(:,2)/100)) < 1e-4)

for k = 1:numel(net.a_Branch)
    net.a_Branch{k}.tab_parameter.dynamics.R = 0;
end
mpc = rmfield(tools.network_to_mpc(net), ["bus_name","gen_name","branch_name"]);
rdc = rundcopf(mpc, mpopt);
assert(rdc.success)
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(abs(res.r_cost - rdc.f) < 1e-6*rdc.f, sprintf("DC cost: GUILDA %.6f, MATPOWER %.6f", res.r_cost, rdc.f))
assert(max(abs(res.tab_bus.Varg - rdc.bus(:,9)*pi/180)) < 1e-5)
assert(max(abs(res.tab_cub{str_gen,"P"} - rdc.gen(:,2)/100)) < 1e-5)


%% Result class of all three methods
% 結果は OPFResult。flag と output を持ち、費用・ラグランジュ乗数・最適化問題も保持する
net = DebugScript.helper.build_9bus();
s_col = struct("ELD", ["P"], "DC_OPF", ["Varg","V","P"], "AC_OPF", ["Varg","V","P","Q","Vphasor","Iphasor"]);
for str_m = ["ELD","DC OPF","AC OPF"]
    [res, flag, output] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method=str_m));
    assert(isa(res, "OPFResult") && isa(res, "AnalysisResult"))
    assert(isequal(res.flag, flag) && isequal(res.output, output) && res.l_success)
    assert(isstruct(output) && isfield(output, "message"))
    assert(res.options.Method == str_m && res.str_solver == "OptimalPowerFlow" && res.str_network == string(net.str_tag))
    assert(isequal(string(res.tab_bus.Properties.VariableNames), s_col.(replace(str_m, " ", "_"))))
    assert(isequal(string(res.tab_bus.Properties.RowNames), string(net.a_Bus)))
    assert(isequal(string(res.tab_branch.Properties.RowNames), string(net.a_Branch)))
    % 費用 = 機器の費用関数の合計
    assert(abs(res.r_cost - DebugScript.helper.opf_cost(net, res.tab_cub)) < 1e-6)
    assert(isstruct(res.lambda) && isa(res.OPFprob, "optim.problemdef.OptimizationProblem"))
end
% ELD は母線ごとの電力収支の制約 (balancedP) が 1 つ、乗数 = 等増分費用 2*HP*P + fP = 3
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD"));
assert(abs(abs(res.lambda.Constraints.balancedP) - 3) < 1e-4)
assert(all(isnan(res.tab_branch.Pfrom)))

% 送電線の潮流 = 母線への注入 (tab_cub の送電線の端) の符号を反転したもの
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
for k = 1:numel(net.a_Branch)
    br  = net.a_Branch{k};
    str = string(br) + "_" + string(br.a_Bus);
    assert(abs(res.tab_branch{string(br),"Pfrom"} + res.tab_cub{str(1),"P"}) < 1e-12)
    assert(abs(res.tab_branch{string(br),"Ito"}   + res.tab_cub{str(2),"Iphasor"}) < 1e-12)
end
assert(all(res.tab_branch.Ploss > -1e-6))
assert(abs(sum(res.tab_branch.Ploss) - sum(res.tab_bus.P)) < 1e-4)

% 既定の方式は net.solver_OPF.Method ("AC OPF")
assert(net.solver_OPF.Method == "AC OPF" && isa(net.solver_OPF, "OptimalPowerFlow"))
res = DebugScript.helper.quiet(@() net.optimize_powerflow());
assert(res.options.Method == "AC OPF")


%% Name-Value options override solver defaults for one call only
net = DebugScript.helper.build_9bus();
solver   = net.solver_OPF;
s_before = solver.get_options();

% MaxIteration=2 では AC OPF は解けない
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", MaxIteration=2));
assert(double(flag) <= 0 && ~res.l_success)
assert(res.options.MaxIteration == 2)
% Solver と Tolerance は solve へ渡される
[res, flag, output] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD", Solver="fmincon", Tolerance=1e-10));
assert(double(flag) > 0 && output.solver == "fmincon" && res.options.OptimalityTolerance == 1e-10)
assert(all(abs(res.tab_bus{["B001","B002","B003"],"P"} - 1) < 1e-4))
% Verbose=true はソルバーの表示 ("iter")、false は表示なし
str_on  = evalc("res = net.optimize_powerflow(Method=""DC OPF"", Verbose=true);");
assert(res.options.Display == "iter")
str_off = evalc("res = net.optimize_powerflow(method=""DC OPF"", verbose=false);");   % 名前の大文字小文字は区別しない
assert(res.options.Display == "none" && strlength(str_on) > strlength(str_off))

% 保存されている既定値は変わらない
assert(isequaln(s_before, solver.get_options()) && net.solver_OPF == solver)   % NaN = ソルバーの既定値

% 既定値を変えると以後の呼び出しすべてに効く
net.solver_OPF.Method = "ELD";
res = DebugScript.helper.quiet(@() net.optimize_powerflow());
assert(res.options.Method == "ELD" && width(res.tab_bus) == 1)


%% Unknown or invalid options stop with an error
net = DebugScript.helper.build_9bus();
try
    DebugScript.helper.quiet(@() net.optimize_powerflow(Methd="ELD"));
    error("DebugScript:noError", "未知のオプションでエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:resolve_options:UnknownName", ME.identifier)
    assert(contains(ME.message, "Methd") && contains(ME.message, "Method, Solver, Tolerance, MaxIteration, Verbose"))
end
% 共通名以外 (ソルバー固有の名前) も受け付けない
assert(error_id(@() net.optimize_powerflow("Display", "iter")) == "GUILDA:resolve_options:UnknownName")
% 値の検証
assert(error_id(@() net.optimize_powerflow(Method="OPF")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() net.optimize_powerflow(Solver="fminunc")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() net.optimize_powerflow(MaxIteration=0)) ~= "")
% Name-Value の組になっていない
assert(error_id(@() net.optimize_powerflow("Method")) == "GUILDA:resolve_options:InvalidPairs")


%% Plot and Export of the result
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));

% Plot: 機器の P, Q と母線電圧の大きさ・位相 (AC OPF は 3 段、ELD は 1 段)
t = res.Plot(Parent=figure("Visible","off"));
c_fig = onCleanup(@() close(ancestor(t, "figure")));
assert(isa(t, "matlab.graphics.layout.TiledChartLayout") && numel(findobj(t.Children, "Type", "axes")) == 3)
res_ELD = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD"));
t2 = res_ELD.Plot(Parent=figure("Visible","off"));
c_fig2 = onCleanup(@() close(ancestor(t2, "figure")));
ax = findobj(t2.Children, "Type", "axes");
assert(numel(ax) == 1 && numel(ax.Children.XData) == numel(tools.vcellfun(@(b) b.a_Component, net.a_Bus)))
% Plot=true は計算後に result.Plot を呼ぶ
a_before = findall(groot, "Type", "figure");
DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD", Plot=true));
a_after = findall(groot, "Type", "figure");
a_new   = a_after(~ismember(a_after, a_before));
assert(numel(a_new) == 1)
close(a_new)

% Export: 母線・接続・送電線の表を CSV に書く
str_dir = tempname; mkdir(str_dir); c_dir = onCleanup(@() rmdir(str_dir, "s"));
f_bus = res.Export(fullfile(str_dir, "bus.csv"));
tab = readtable(f_bus, "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)) && max(abs(tab.V - res.tab_bus.V)) < 1e-12)
res.Export(fullfile(str_dir, "cub.csv"), Table="cub");
tab = readtable(fullfile(str_dir, "cub.csv"), "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(res.tab_cub.Properties.RowNames)))
res.Export(fullfile(str_dir, "branch.csv"), Table="branch");
tab = readtable(fullfile(str_dir, "branch.csv"), "ReadRowNames", true);
assert(max(abs(tab.Ploss - res.tab_branch.Ploss)) < 1e-12)
% Export=filename は計算後に result.Export を呼ぶ
f_opt = fullfile(str_dir, "opt.csv");
DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", Export=f_opt));
assert(isfile(f_opt))
assert(error_id(@() res.Export(fullfile(str_dir, "x.json"))) == "GUILDA:OPFResult:ExportFormat")


%% Legacy six-output form
% v3 の [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob] は 6 出力のときだけ返る (警告付き)
net = DebugScript.helper.build_9bus();
clear Deprecated
lastwarn("");
w = warning("off", "GUILDA:Deprecated:OptimizePowerflowTuple"); c = onCleanup(@() warning(w));
[tab_bus, tab_cub, flag, output, lambda, OPFprob] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:OptimizePowerflowTuple")
[res, flag4, output4] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(isequal(tab_bus, res.tab_bus) && isequal(tab_cub, res.tab_cub) && isequal(flag, flag4))
assert(isstruct(output) && isfield(output, "message") && isequal(output.solver, output4.solver))
assert(isstruct(lambda) && isa(OPFprob, "optim.problemdef.OptimizationProblem"))
% 1-3 出力は v4 の形式
assert(isa(DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")), "OPFResult"))


%% Build OPF problem with Method and deprecated methods option
% net.build_opf_problem も optimize_powerflow と同じオプション名 Method を使う。v3 の methods は警告付きで同じ
net = DebugScript.helper.build_9bus();
[prob, x0] = net.build_opf_problem(Method="DC OPF");
assert(isa(prob, "optim.problemdef.OptimizationProblem") && isstruct(x0))
assert(contains(prob.Description, "DC OPF"))
clear Deprecated
lastwarn("");
w = warning("off", "GUILDA:Deprecated:BuildOpfProblemMethods"); c = onCleanup(@() warning(w));
prob = net.build_opf_problem("methods", "ELD");
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:BuildOpfProblemMethods")
assert(contains(prob.Description, "ELD"))


%% Deprecated methods option
% v3 のオプション名 "methods" は Method と同じ (警告付き)
net = DebugScript.helper.build_9bus();
clear Deprecated
lastwarn("");
w = warning("off", "GUILDA:Deprecated:OptimizePowerflowMethods"); c = onCleanup(@() warning(w));
res = DebugScript.helper.quiet(@() net.optimize_powerflow("methods", "ELD"));
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:OptimizePowerflowMethods")
assert(res.options.Method == "ELD" && width(res.tab_bus) == 1)
% v3 の呼び出しをそのまま実行できる
w2 = warning("off", "GUILDA:Deprecated:OptimizePowerflowTuple"); c2 = onCleanup(@() warning(w2));
[tab_bus, ~, ~, ~, ~, ~] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods", "AC OPF"));
assert(istable(tab_bus) && width(tab_bus) == 6)
[out1, ~, out3] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods", "AC OPF"));
assert(isa(out1, "OPFResult") && isstruct(out3))          % 3 出力は v4 の形式 [result, flag, output]
assert(net.solver_OPF.Method == "AC OPF")


% ---- local functions ----
function net = build_loop3()
% 3 母線ループ: 送電線 B001-B002, B002-B003, B001-B003 (R = 0, X = 0.1)。
% B001: 発電機 (P^2+P)、B002: 発電機 (P^2+2P)、B003: 負荷 1.0。全母線に負荷 (B001, B002 は 0) を置く。
    net = PowerNetwork("OPFLoop3");
    for i = 1:3
        net.add_bus();
    end
    net.add_branch("pi", [1,2], "X",0.1);
    net.add_branch("pi", [2,3], "X",0.1);
    net.add_branch("pi", [1,3], "X",0.1);
    g1 = net.a_Bus{1}.add_component("gen-park");
    g2 = net.a_Bus{2}.add_component("gen-park");
    g1.tab_parameter.OPF{1,["HP","fP"]} = [1, 1];
    g2.tab_parameter.OPF{1,["HP","fP"]} = [1, 2];
    rv_P = [0, 0, -1];
    for i = 1:3
        ld = net.a_Bus{i}.add_component("load-power", "P",rv_P(i), "Q",0);
        ld.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]} = [0, 0, 0, 0];
    end
end

function fd = fd_load(net, str_method, ld, str_pq, h, c_opt)
% 負荷 ld の P または Q (注入) を ±h 変えたときの最適費用の中心差分 (負荷 1 単位の増加あたり)
    v0 = ld.tab_parameter.powerflow.(str_pq);
    c_restore = onCleanup(@() set_pf(ld, str_pq, v0));
    set_pf(ld, str_pq, v0 - h);
    J_more = DebugScript.helper.quiet(@() net.optimize_powerflow("Method", str_method, c_opt{:})).r_cost;
    set_pf(ld, str_pq, v0 + h);
    J_less = DebugScript.helper.quiet(@() net.optimize_powerflow("Method", str_method, c_opt{:})).r_cost;
    fd = (J_more - J_less)/(2*h);
end

function set_pf(ld, str_pq, v)
    ld.tab_parameter.powerflow.(str_pq) = v;
end

function Y = mpc_ybus(mpc)
% MATPOWER の送電線モデル (makeYbus と同じ式) で mpc から母線アドミタンス行列を組み立てる
    n  = size(mpc.bus,1);
    br = mpc.branch;
    ys = 1./(br(:,3) + 1j*br(:,4));
    t  = br(:,9);  t(t == 0) = 1;
    t  = t .* exp(1j*br(:,10)*pi/180);
    Ytt = ys + 1j*br(:,5)/2;
    Yff = Ytt ./ (t.*conj(t));
    Yft = -ys ./ conj(t);
    Ytf = -ys ./ t;
    f  = br(:,1);  tt = br(:,2);
    Y  = sparse([f; f; tt; tt], [f; tt; f; tt], [Yff; Yft; Ytf; Ytt], n, n) ...
       + sparse(1:n, 1:n, (mpc.bus(:,5) + 1j*mpc.bus(:,6))/mpc.baseMVA, n, n);
    Y  = full(Y);
end

function err = set_case14(net, mpc)
% network.IEEE14bus の線路定数 (タップを含む)・負荷・電圧上下限・発電機の制約と費用を
% MATPOWER の case14 に合わせる。
% 戻り値は合わせた後の Ybus と case14 の Ybus の差 (確認用)。
    base = mpc.baseMVA;
    for i = 1:numel(net.a_Bus)
        bus = net.a_Bus{i};
        bus.tab_parameter.operation{1,["Vmin","Vmax"]} = mpc.bus(i,[13 12]);
        bus.tab_parameter.dynamics{1,["Gshunt","Bshunt"]} = mpc.bus(i,[5 6])/base;
        for k = 1:numel(bus.a_Component)
            c = bus.a_Component{k};
            if isa(c, "component.load.abstract")
                c.tab_parameter.powerflow{1,["P","Q"]} = -mpc.bus(i,[3 4])/base;
                c.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]} = [0, 0, 0, 0];
            else
                g = find(mpc.gen(:,1) == i, 1);
                c.tab_parameter.operation{1,["Pmin","Pmax","Qmin","Qmax"]} = mpc.gen(g,[10 9 5 4])/base;
                c.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]} = [mpc.gencost(g,5)*base^2, mpc.gencost(g,6)*base, 0, 0];
            end
        end
    end
    str_bus = string(net.a_Bus);
    for k = 1:numel(net.a_Branch)
        br = net.a_Branch{k};
        [~, iv] = ismember(string(br.a_Bus), str_bus);
        j = find(mpc.branch(:,1) == iv(1) & mpc.branch(:,2) == iv(2), 1);
        r_tap = mpc.branch(j,9);
        if r_tap == 0; r_tap = 1; end
        br.tab_parameter.dynamics{1,["R","X","C","tap","phase"]} = [mpc.branch(j,3:4), mpc.branch(j,5)/2, r_tap, mpc.branch(j,10)*pi/180];
    end
    err = norm(net.get_admittance_matrix.Variables - mpc_ybus(mpc));
end

function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        DebugScript.helper.quiet(fcn);
    catch ME
        id = string(ME.identifier);
        if id == ""
            id = "(no id)";
        end
    end
end
