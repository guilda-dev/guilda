% F4 最適潮流計算 (optimize_powerflow)
%
% 3 つの方式 "ELD" / "DC OPF" / "AC OPF" で最適潮流を計算し、物理的な妥当性を確認する。
%   - v4 の呼び出し形式 [result, flag, output] と結果クラス ResultOPF
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
%   - DC OPF の送電線は MATPOWER と同じ b = 1/(X*tap) (case14 で MATPOWER の DC 定式化と一致)
%   - 負荷の既定の費用は 0。上下限を与えた負荷は価格応答する負荷として配分される
%   - 利用者の費用・制約 (Cost, Constraint): 系統全体の変数をタグで参照、名前付き制約とその乗数、
%     DefaultCost=false、ReferenceBus ("auto" / タグ / "none")、net.solver_OPF に保存した既定値、
%     平衡点を古くしないこと
%   - 上下限を ±Inf (送電線は NaN も) にすると既定の制約が外れる
%   - build_opf_problem の問題を変更して Problem / InitialPoint で解く
%   - IEEJ_WEST10 (送電線のタグが制約名になる系統) の AC OPF が解ける
% 費用関数は機器の tab_parameter.OPF、制約は各クラスの tab_parameter.operation で設定する。
% 利用者の費用・制約は optimize_powerflow / build_opf_problem の Cost, Constraint で追加する。
%
% 実行: runtests("DebugScript.test_F4_opf")  または  DebugScript.run_all("Features","F4")
%
% [result, flag, output] = net.optimize_powerflow(Method=..., Name, Value)
%   result.tab_bus    : 母線ごとの解
%   result.tab_cub    : 母線への接続 (機器 "<機器名>"、送電線の端 "<送電線名>_<母線名>") ごとの、母線への注入
%   result.tab_branch : 送電線ごとの両端の潮流 (送電線へ流れ込む向き)
% 設定の既定値は net.solver_OPF (SolverOPF)。Name-Value はその呼び出しだけ上書きする。
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

% 送電線の端の P = 母線への流入 b*(θj-θi+φ) (MATPOWER と同じ b = 1/(X*tap))、両端の和 = 0 (損失なし)
for k = 1:numel(net.a_Branch)
    br  = net.a_Branch{k};
    str = string(br) + "_" + string(br.a_Bus);
    [b, phase] = dc_susceptance(br);
    th  = tab_bus{string(br.a_Bus),"Varg"};
    assert(abs(tab_cub{str(1),"P"} - b*(th(2)-th(1)+phase)) < tol)
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


%% AC OPF warm start starts from the last solution
% WarmStart=true は前回の AC OPF の解から、false (既定) はフラットスタート。同じ解に収束する
net = DebugScript.helper.build_ieee14();
[res0, flag0, out0] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", WarmStart=false));
[res1, flag1, out1] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", WarmStart=true));
assert(flag0 > 0 && flag1 > 0 && res1.options.WarmStart && ~res0.options.WarmStart)
assert(out1.iterations ~= out0.iterations)     % 初期値が違う (内点法なので反復回数は減るとは限らない)
assert(abs(res1.r_cost - res0.r_cost) < 1e-9*res0.r_cost && max(abs(res1.tab_bus.Vphasor - res0.tab_bus.Vphasor)) < 1e-4)
% build_opf_problem の初期値はフラットスタート (母線の位相 0、PV・スラックは設定値 V)
[~, x0] = DebugScript.helper.quiet(@() net.build_opf_problem(Method="AC OPF"));
s_bus = string(net.a_Bus{14});
assert(isequal(x0.(s_bus), [0; 1]))
assert(error_id(@() net.optimize_powerflow(WarmStart="on")) ~= "")
% 配布する既定値は false (ユーザー設定ファイルが既定を上書きしうるので JSON を直接読む)
sct_def = jsondecode(fileread(fullfile(GUILDA.pwd, "@GUILDA", "config", "DefaultOptimalPowerFlow.json")));
assert(sct_def.WarmStart.Value == false)


%% The OPF problem is kept until the network or the settings change
% net.solver_OPF は作った問題を保持し、ネットワーク・設定・初期点が同じなら再利用する。
% 再利用の判定: 問題の変数はハンドルなので、同じ問題なら一方の上下限の変更が他方に見える
net = DebugScript.helper.build_9bus();
s_var = "SG1B001";
shared = @(r1, r2) shares_variable(r1.OPFprob, r2.OPFprob, s_var);
res1 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
res2 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(shared(res1, res2))                                  % 再利用
res3 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD"));
assert(~shared(res2, res3))
res4 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(~shared(res2, res4))                                 % 設定が変われば作り直す (保持は 1 つ)
res5 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", Cost=@(v, p) 0*v.Component.SG1B001.P));
assert(~shared(res4, res5))                                 % Cost (関数ハンドル) が違う
res6 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(~shared(res5, res6))
% operation / OPF / powerflow / タグの編集で作り直し、結果は編集を反映する
g1 = net.a_Bus{1}.a_Component{1};
g1.tab_parameter.operation.Pmax = 0.5;
res7 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(~shared(res6, res7) && res7.tab_cub{"SG1B001","P"} <= 0.5 + 1e-6)
g1.tab_parameter.OPF.fP = g1.tab_parameter.OPF.fP + 1;
res8 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(~shared(res7, res8))
net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.1;
res9 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(~shared(res8, res9))
g1.s_tag = "G1";
res10 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(isfield(res10.OPFprob.Variables, "G1") && ~isfield(res10.OPFprob.Variables, "SG1B001"))
s_var = "G1";
shared = @(r1, r2) shares_variable(r1.OPFprob, r2.OPFprob, s_var);
% 結果の問題の上下限を変えると、次の計算は作り直す (変更は既定の問題に残らない)
res11 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(shared(res10, res11))
var = res11.OPFprob.Variables.G1;     % ハンドル (結果のプロパティ自体は読み取り専用)
var.UpperBound = 0.2;
res12 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(res12.OPFprob.Variables.G1.UpperBound == 0.5 && abs(res12.r_cost - res10.r_cost) < 1e-9*max(1, abs(res10.r_cost)))
% build_opf_problem は毎回新しい問題 (保持した問題を返さない)
prob = DebugScript.helper.quiet(@() net.build_opf_problem(Method="DC OPF"));
prob.Variables.G1.UpperBound = 0.3;
res13 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(shared(res12, res13) && res13.OPFprob.Variables.G1.UpperBound == 0.5)
% net.reset_solver() で捨てる
net.reset_solver();
res14 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(~shared(res13, res14))


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
sv_load = string(a_Com(l_load));
P_load = cellfun(@(c) c.tab_parameter.powerflow.P, a_Com(l_load));

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
assert(abs(sum(tab_bus.P)) < tol)
assert(max(abs(tab_cub{sv_load,"P"} - P_load)) < tol)
% 等増分費用: B001 (430.29 P^2 + 2000 P) と B002 (2500 P^2 + 2000 P) で負荷 2.59 を賄い、
% 限界費用 2*430.29*P1 + 2000 = 2*2500*P2 + 2000 = 3901.6 < 4000 なので他の 3 台は Pmin = 0
%   → P1 = 2.59*5000/(860.585+5000) = 2.2097, P2 = 0.3803 (rundcopf(case14) の 220.97, 38.03 MW)
sv_gen = string(cellfun(@(b) b.a_Component{1}, net.a_Bus([1 2 3 6 8]), "UniformOutput", false));
r_HP1 = 2*430.292599;
P1 = -sum(P_load)*5000/(r_HP1+5000);
assert(max(abs(tab_cub{sv_gen,"P"} - [P1; -sum(P_load)-P1; 0; 0; 0])) < 1e-4)

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF")); tab_DC = res.tab_bus; tab_cub_DC = res.tab_cub;
assert(flag > 0)
assert(abs(sum(tab_DC.P)) < tol)
assert(max(abs(tab_cub_DC{string(a_Com),"P"} - tab_cub{string(a_Com),"P"})) < 1e-4)


%% IEEE14 AC OPF
% 潮流方程式・負荷・電圧制約を満たし、費用は潮流計算の解以下
net = DebugScript.helper.build_ieee14();
a_Com  = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
l_load = cellfun(is_load, a_Com);
sv_load = string(a_Com(l_load));
PQ_load = cell2mat(cellfun(@(c) c.tab_parameter.powerflow{1,["P","Q"]}, a_Com(l_load), "UniformOutput", false));

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
Y = net.get_admittance_matrix.Variables;
assert(norm(tab_bus.Vphasor .* conj(Y*tab_bus.Vphasor) - (tab_bus.P + 1j*tab_bus.Q)) < 1e-4)
S_loss = DebugScript.helper.branch_losses(net, tab_bus.Vphasor);
assert(abs(sum(tab_bus.P) - real(S_loss)) < 1e-4)
assert(max(abs(tab_cub{sv_load,["P","Q"]} - PQ_load), [], "all") < tol)
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
sv_bus  = string(net.a_Bus);
sv_gen  = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(1:2), "UniformOutput", false));
price = @(r) -cellfun(@(s) r.lambda.Constraints.("balancedP_"+s), cellstr(sv_bus));

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.75; 0.25])) < 1e-6)
assert(max(abs(price(res) - 2.5)) < 1e-6)

br13 = net.a_Branch{3};
assert(isequal(string(br13.a_Bus(:)).', ["B001","B003"]))
br13.tab_parameter.operation.Pmax = 0.5;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.5; 0.5])) < 1e-6)
assert(abs(res.tab_branch{string(br13),"Pfrom"} - 0.5) < 1e-6)
assert(max(abs(price(res) - [2; 3; 4])) < 1e-6)
assert(abs(res.r_cost - (0.5^2+0.5 + 0.5^2+2*0.5)) < 1e-6)
% 送電制約の乗数: 両端の変数の上下限の乗数の合計 = μ = 3
sv_end = string(br13) + "_" + string(br13.a_Bus);
mu = sum(cellfun(@(s) res.lambda.Variables.(s).Upper + res.lambda.Variables.(s).Lower, cellstr(sv_end)));
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
sv_end = string(br) + "_" + string(br.a_Bus);

r_Imax = 0.8*max(abs(res0.tab_branch{k,["Ifrom","Ito"]}));
br.tab_parameter.operation.Imax = r_Imax;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
assert(flag > 0)
r_I = max(abs(res.tab_branch{k,["Ifrom","Ito"]}));
assert(r_I <= r_Imax + 1e-6 && r_I >= r_Imax - 1e-4)
assert(res.r_cost > res0.r_cost)
assert(max(cellfun(@(s) res.lambda.Constraints.("Imax_"+s), cellstr(sv_end))) > 0)

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
    s_bus = string(a_Load{k}.a_Bus);
    for s_pq = ["P","Q"]
        lam = res.lambda.Constraints.("balanced"+s_pq+"_"+s_bus);
        fd  = fd_load(net, "AC OPF", a_Load{k}, s_pq, h, c_opt);
        assert(abs(fd + lam) < 1e-4*max(1, abs(lam)), s_bus + " " + s_pq + sprintf(": FD %.6f, -lambda %.6f", fd, -lam))
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
assert(error_id(@() tools.network_to_mpc(net2)) == "GUILDA:network_to_mpc:BranchLimit")


%% AC and DC OPF reproduce the MATPOWER case14 optimum
% network.IEEE14bus の線路定数・負荷・発電機の OPF 設定は MATPOWER の case14
% (DebugScript.helper.case14_data) と同じなので、MATPOWER の最適解と一致する
% (MATPOWER 不要。値は MATPOWER の runopf / rundcopf の結果)。
%   AC: 費用 8081.53 $/hr、Pg = [194.33, 36.72, 28.74, 0.00, 8.50] MW
%   DC: 費用 7642.59 $/hr、Pg = [220.97, 38.03, 0, 0, 0] MW
net = DebugScript.helper.build_ieee14();
mpc = DebugScript.helper.case14_data();
assert(norm(net.get_admittance_matrix.Variables - mpc_ybus(mpc)) < 1e-12)
sv_gen = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(mpc.gen(:,1)), "UniformOutput", false));
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", Tolerance=1e-10));
assert(flag > 0)
assert(abs(res.r_cost - 8081.53) < 0.01, sprintf("AC cost %.4f", res.r_cost))
assert(max(abs(100*res.tab_cub{sv_gen,"P"} - [194.33; 36.72; 28.74; 0; 8.50])) < 0.01)
assert(all(res.tab_bus.V >= 0.94 - 1e-6 & res.tab_bus.V <= 1.06 + 1e-6))

[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(abs(res.r_cost - 7642.59) < 0.01, sprintf("DC cost %.4f", res.r_cost))
assert(max(abs(100*res.tab_cub{sv_gen,"P"} - [220.97; 38.03; 0; 0; 0])) < 0.01)


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
sv_gen = string(mpc.gen_name);
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
assert(max(abs(res.tab_cub{sv_gen,"P"} - rmp.gen(:,2)/100)) < 1e-4)

mpc = rmfield(tools.network_to_mpc(net), ["bus_name","gen_name","branch_name"]);
rdc = rundcopf(mpc, mpopt);
assert(rdc.success)
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(abs(res.r_cost - rdc.f) < 1e-6*rdc.f, sprintf("DC cost: GUILDA %.6f, MATPOWER %.6f", res.r_cost, rdc.f))
assert(max(abs(res.tab_bus.Varg - rdc.bus(:,9)*pi/180)) < 1e-5)
assert(max(abs(res.tab_cub{sv_gen,"P"} - rdc.gen(:,2)/100)) < 1e-5)


%% Result class of all three methods
% 結果は ResultOPF。flag と output を持ち、費用・ラグランジュ乗数・最適化問題も保持する
net = DebugScript.helper.build_9bus();
sct_col = struct("ELD", ["P"], "DC_OPF", ["Varg","V","P"], "AC_OPF", ["Varg","V","P","Q","Vphasor","Iphasor"]);
for s_m = ["ELD","DC OPF","AC OPF"]
    [res, flag, output] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method=s_m));
    assert(isa(res, "ResultOPF") && isa(res, "ResultBase"))
    assert(isequal(res.flag, flag) && isequal(res.output, output) && res.l_success)
    assert(isstruct(output) && isfield(output, "message"))
    assert(res.options.Method == s_m && res.s_solver == "SolverOPF" && res.s_network == string(net.s_tag))
    assert(isequal(string(res.tab_bus.Properties.VariableNames), sct_col.(replace(s_m, " ", "_"))))
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
assert(net.solver_OPF.Method == "AC OPF" && isa(net.solver_OPF, "SolverOPF"))
res = DebugScript.helper.quiet(@() net.optimize_powerflow());
assert(res.options.Method == "AC OPF")


%% Name-Value options override solver defaults for one call only
net = DebugScript.helper.build_9bus();
solver   = net.solver_OPF;
sct_before = solver.get_options();

% MaxIteration=2 では AC OPF は解けない
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", MaxIteration=2));
assert(double(flag) <= 0 && ~res.l_success)
assert(res.options.MaxIteration == 2)
% Solver と Tolerance は solve へ渡される
[res, flag, output] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD", Solver="fmincon", Tolerance=1e-10));
assert(double(flag) > 0 && output.solver == "fmincon" && res.options.OptimalityTolerance == 1e-10)
assert(all(abs(res.tab_bus{["B001","B002","B003"],"P"} - 1) < 1e-4))
% Verbose=true はソルバーの表示 ("iter")、false は表示なし
s_on    = evalc("res = net.optimize_powerflow(Method=""DC OPF"", Verbose=true);");
assert(res.options.Display == "iter")
s_off = evalc("res = net.optimize_powerflow(method=""DC OPF"", verbose=false);");   % 名前の大文字小文字は区別しない
assert(res.options.Display == "none" && strlength(s_on) > strlength(s_off))

% 保存されている既定値は変わらない
assert(isequaln(sct_before, solver.get_options()) && net.solver_OPF == solver)   % NaN = ソルバーの既定値

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
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:resolve_options:UnknownName", DebugScript.helper.msg_id(ME))
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
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
f_bus = res.Export(fullfile(s_dir, "bus.csv"));
tab = readtable(f_bus, "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)) && max(abs(tab.V - res.tab_bus.V)) < 1e-12)
res.Export(fullfile(s_dir, "cub.csv"), Table="cub");
tab = readtable(fullfile(s_dir, "cub.csv"), "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(res.tab_cub.Properties.RowNames)))
res.Export(fullfile(s_dir, "branch.csv"), Table="branch");
tab = readtable(fullfile(s_dir, "branch.csv"), "ReadRowNames", true);
assert(max(abs(tab.Ploss - res.tab_branch.Ploss)) < 1e-12)
% Export=filename は計算後に result.Export を呼ぶ
f_opt = fullfile(s_dir, "opt.csv");
DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", Export=f_opt));
assert(isfile(f_opt))
assert(error_id(@() res.Export(fullfile(s_dir, "x.json"))) == "GUILDA:ResultOPF:ExportFormat")


%% Legacy six-output form
% v3 の [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob] は 6 出力のときだけ返る (警告付き)
net = DebugScript.helper.build_9bus();
clear Deprecated
lastwarn("");
w = warning("off", "GUILDA:Deprecated:OptimizePowerflowTuple"); c = onCleanup(@() warning(w));
[tab_bus, tab_cub, flag, output, lambda, OPFprob] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
id = DebugScript.helper.msg_id();
assert(string(id) == "GUILDA:Deprecated:OptimizePowerflowTuple")
[res, flag4, output4] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(isequal(tab_bus, res.tab_bus) && isequal(tab_cub, res.tab_cub) && isequal(flag, flag4))
assert(isstruct(output) && isfield(output, "message") && isequal(output.solver, output4.solver))
assert(isstruct(lambda) && isa(OPFprob, "optim.problemdef.OptimizationProblem"))
% 1-3 出力は v4 の形式
assert(isa(DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD")), "ResultOPF"))


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
id = DebugScript.helper.msg_id();
assert(string(id) == "GUILDA:Deprecated:BuildOpfProblemMethods")
assert(contains(prob.Description, "ELD"))


%% Deprecated methods option
% v3 のオプション名 "methods" は Method と同じ (警告付き)
net = DebugScript.helper.build_9bus();
clear Deprecated
lastwarn("");
w = warning("off", "GUILDA:Deprecated:OptimizePowerflowMethods"); c = onCleanup(@() warning(w));
res = DebugScript.helper.quiet(@() net.optimize_powerflow("methods", "ELD"));
id = DebugScript.helper.msg_id();
assert(string(id) == "GUILDA:Deprecated:OptimizePowerflowMethods")
assert(res.options.Method == "ELD" && width(res.tab_bus) == 1)
% v3 の呼び出しをそのまま実行できる
w2 = warning("off", "GUILDA:Deprecated:OptimizePowerflowTuple"); c2 = onCleanup(@() warning(w2));
[tab_bus, ~, ~, ~, ~, ~] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods", "AC OPF"));
assert(istable(tab_bus) && width(tab_bus) == 6)
[out1, ~, out3] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods", "AC OPF"));
assert(isa(out1, "ResultOPF") && isstruct(out3))          % 3 出力は v4 の形式 [result, flag, output]
assert(net.solver_OPF.Method == "AC OPF")

%% DC OPF uses the MATPOWER susceptance 1/X
% DC OPF の送電線は MATPOWER (makeBdc) と同じ b = 1/(X*tap) (タップ比・移相は from 端)。
% case14_data からこのテストの中で MATPOWER の DC 定式化 P = Bbus*θ + Pbusinj を組み立て、
% GUILDA の DC OPF の発電量から求めた位相・潮流が GUILDA の解と一致することを確かめる。
% 抵抗のある送電線では Im(Y_ij) = X/(R^2+X^2) と 1/X が違うので、旧定義とは位相が変わる。
net = DebugScript.helper.build_ieee14();
mpc = DebugScript.helper.case14_data();
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(flag > 0)
sv_gen = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(mpc.gen(:,1)), "UniformOutput", false));
assert(abs(res.r_cost - 7642.59) < 0.01, sprintf("DC cost %.4f", res.r_cost))
assert(max(abs(100*res.tab_cub{sv_gen,"P"} - [220.97; 38.03; 0; 0; 0])) < 0.01)

nb  = size(mpc.bus,1);
br  = mpc.branch;
tap = br(:,9);  tap(tap == 0) = 1;
b   = 1./(br(:,4).*tap);
shift = br(:,10)*pi/180;
nl  = size(br,1);
Cft = sparse([1:nl, 1:nl], [br(:,1); br(:,2)], [ones(nl,1); -ones(nl,1)], nl, nb);
Bbus    = full(Cft.'*diag(b)*Cft);
Pbusinj = Cft.'*(-b.*shift);
Pg = zeros(nb,1);
Pg(mpc.gen(:,1)) = res.tab_cub{sv_gen,"P"};
Pinj = Pg - mpc.bus(:,3)/mpc.baseMVA - mpc.bus(:,5)/mpc.baseMVA;
th = zeros(nb,1);
th(2:end) = Bbus(2:end,2:end) \ (Pinj(2:end) - Pbusinj(2:end));
assert(max(abs(res.tab_bus.Varg - th)) < 1e-8)
sv_bus = string(net.a_Bus);
for k = 1:numel(net.a_Branch)
    brk = net.a_Branch{k};
    [~, iv] = ismember(string(brk.a_Bus), sv_bus);
    j = find(br(:,1) == iv(1) & br(:,2) == iv(2), 1);
    assert(abs(res.tab_branch{string(brk),"Pfrom"} - b(j)*(th(iv(1)) - th(iv(2)) - shift(j))) < 1e-8)
end
% 旧定義 b = Im(Y_ij) の位相とは 1e-3 rad 以上違う (このテストは定義の違いを見分けられる)
b_old = zeros(nl,1);
for k = 1:numel(net.a_Branch)
    brk = net.a_Branch{k};
    [~, iv] = ismember(string(brk.a_Bus), sv_bus);
    j = find(br(:,1) == iv(1) & br(:,2) == iv(2), 1);
    Y = brk.get_admittance_matrix();
    b_old(j) = -imag(Y(1,2));
end
B_old  = Cft.'*diag(b_old)*Cft;
th_old = [0; B_old(2:end,2:end) \ Pinj(2:end)];
assert(max(abs(th_old - th)) > 1e-3)


%% Default OPF cost of a load is 0
% add_component の既定の費用は発電機などが HP = fP = 1、負荷は 0 (固定の負荷は費用に効かない)。
% 明示した値 (同梱の系統の opf.csv など) はそのまま
net = PowerNetwork("CostDefault");
bus = net.add_bus();
ld  = bus.add_component("load-power");
gen = bus.add_component("gen-park");
ld2 = bus.add_component("load-power", "OPFcost_HP", 2, "OPFcost_fP", 5);
assert(isequal(ld.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]}, [0 0 0 0]))
assert(isequal(gen.tab_parameter.OPF{1,["HP","fP","HQ","fQ"]}, [1 1 0 0]))
assert(isequal(ld2.tab_parameter.OPF{1,["HP","fP"]}, [2 5]))
% 9 母線系統: 最適費用は発電機の費用だけ (3 台とも P = 1 で 3*(1+1) = 6)
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD"));
assert(abs(res.r_cost - 6) < 1e-6)


%% Price-responsive load: a load with P bounds and its own cost
% 上下限が有限の負荷は潮流設定に固定されず、上下限の範囲で配分される。
% B008 の負荷 (P = -1.2) を -3 <= P <= 0、費用 4*P (1 単位消費の便益 4。Cost で追加) にする。
% 発電機 3 台 (P^2+P) の限界費用 2*Pg+1 = 4 → Pg = 1.5、需要は 4.5 - 1.8 = 2.7 (範囲内)
net = DebugScript.helper.build_9bus();
ld8 = net.a_Bus{8}.a_Component{1};
ld8.tab_parameter.operation{1,["Pmin","Pmax"]} = [-3, 0];
s_ld8 = string(ld8);
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD", Cost=@(v, p) 4*v.Component.(s_ld8).P));
assert(abs(res.tab_cub{s_ld8,"P"} + 2.7) < 1e-5)
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - 1.5)) < 1e-5)
assert(abs(abs(res.lambda.Constraints.balancedP) - 4) < 1e-5)


%% Cost option adds a user cost to the objective
% 9 母線系統の発電機 3 台 (P^2+P) のうち SG1B001 に P^2 を加え 2*P^2 + P にする。
% 等増分費用 4*P1+1 = 2*P2+1 = 2*P3+1、P1+P2+P3 = 3 → P1 = 0.6, P2 = P3 = 1.2、
% 費用 = 2*0.36+0.6 + 2*(1.44+1.2) = 6.6。DC OPF (送電制約なし) も同じ配分
net = DebugScript.helper.build_9bus();
g1 = net.a_Bus{1}.a_Component{1};
s_g1 = string(g1);
f_cost = @(v, p) v.Component.(s_g1).P^2;
for s_m = ["ELD","DC OPF"]
    [res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method=s_m, Cost=f_cost));
    assert(flag > 0)
    assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.6; 1.2; 1.2])) < 1e-5)
    assert(abs(res.r_cost - 6.6) < 1e-6)
    assert(isequal(res.options.Cost, f_cost))
end
% AC OPF では v.Component.(tag).Q も使える
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", ...
                  Cost=@(v, p) v.Component.(s_g1).P^2 + 0.1*v.Component.(s_g1).Q^2));
assert(flag > 0)
P1 = res.tab_cub{s_g1,"P"};  Q1 = res.tab_cub{s_g1,"Q"};
assert(P1 < res.tab_cub{string(net.a_Bus{2}.a_Component{1}),"P"})
assert(abs(res.r_cost - (P1^2 + 0.1*Q1^2 + DebugScript.helper.opf_cost(net, res.tab_cub))) < 1e-6)
% p には Method と base (系統の baseMVA, Hz) が入る
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD", ...
          Cost=@(v, p) (p.Method == "ELD")*p.base.baseMVA/100*v.Component.(s_g1).P^2));
assert(abs(res.r_cost - 6.6) < 1e-6)
% 保存されない (この呼び出しだけ)
assert(isempty(net.solver_OPF.Cost))


%% DefaultCost=false leaves out the costs of tab_parameter.OPF
% DefaultCost=false では tab_parameter.OPF の費用が入らず、Cost だけが目的関数になる。
% Cost = 2*P1^2 + P1 + P2^2 + P2 + P3^2 + P3 → 上と同じ P = [0.6; 1.2; 1.2]、費用 6.6
% (既定の費用が残っていれば 3*P1^2 + 2*P1 + ... となり配分が変わる)
net = DebugScript.helper.build_9bus();
sv_g = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(1:3), "UniformOutput", false));
f_cost = @(v, p) 2*v.Component.(sv_g(1)).P^2 + v.Component.(sv_g(1)).P ...
                 + v.Component.(sv_g(2)).P^2 + v.Component.(sv_g(2)).P ...
                 + v.Component.(sv_g(3)).P^2 + v.Component.(sv_g(3)).P;
for s_m = ["ELD","DC OPF"]
    [res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method=s_m, DefaultCost=false, Cost=f_cost));
    assert(flag > 0)
    assert(max(abs(res.tab_cub{sv_g,"P"} - [0.6; 1.2; 1.2])) < 1e-5)
    assert(abs(res.r_cost - 6.6) < 1e-6)
end
% Cost もなければ目的関数は定数 0 (発電機の P = 1 で評価)
[prob, x0] = net.build_opf_problem(Method="DC OPF", DefaultCost=false);
for s_g = sv_g.'
    x0.(s_g) = 1;
end
assert(evaluate(prob.Objective.GenCost, x0) == 0)
prob = net.build_opf_problem(Method="DC OPF");
assert(abs(evaluate(prob.Objective.GenCost, x0) - 6) < 1e-12)


%% Constraint option binds and its dual has the user's name
% Constraint の struct のフィールド名 <名前> が制約名と lambda.Constraints.<名前> になる
%   機器 : SG1B001 に P <= 0.4 → P2 = P3 = 1.3、乗数 = (2*1.3+1) - (2*0.4+1) = 1.8
%   送電線: ET001 (B001→B004、発電機 1 台だけの放射状) の Pfrom <= 0.1 → P1 = 0.1, P2 = P3 = 1.45、
%          乗数 = (2*1.45+1) - (2*0.1+1) = 2.7
%   母線 : AC OPF で B005 の電圧に V <= 1.0 (制約なしの解は 1.0 を超える) → 効いて乗数 > 0
net = DebugScript.helper.build_9bus();
for s_m = ["ELD","DC OPF"]
    [res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method=s_m, ...
                      Constraint=@(v, p) struct("Cap", v.Component.SG1B001.P <= 0.4)));
    assert(flag > 0)
    assert(isfield(res.OPFprob.Constraints, "Cap"))
    assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.4; 1.3; 1.3])) < 1e-5)
    assert(abs(res.lambda.Constraints.Cap - 1.8) < 1e-5)
end

br1 = net.a_Branch{1};
assert(string(br1) == "ET001" && isequal(string(br1.a_Bus(:)).', ["B001","B004"]))
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", ...
                  Constraint=@(v, p) struct("Pfwd", v.Branch.ET001.Pfrom <= 0.1)));
assert(flag > 0)
assert(abs(res.tab_branch{"ET001","Pfrom"} - 0.1) < 1e-6)
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.1; 1.45; 1.45])) < 1e-5)
assert(abs(res.lambda.Constraints.Pfwd - 2.7) < 1e-5)

res0 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
assert(res0.tab_bus{"B005","V"} > 1.0 + 1e-3)
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", ...
                  Constraint=@(v, p) struct("Vhigh", v.Bus.B005.V <= 1.0, "Vlow", v.Bus.B005.V >= 0.98)));
assert(flag > 0)
assert(abs(res.tab_bus{"B005","V"} - 1.0) < 1e-5)
assert(res.lambda.Constraints.Vhigh > 1e-4 && abs(res.lambda.Constraints.Vlow) < 1e-4)
assert(res.r_cost > res0.r_cost)
% build_opf_problem も同じ名前で制約を加える
prob = net.build_opf_problem(Method="DC OPF", Constraint=@(v, p) struct("Cap", v.Component.SG1B001.P <= 0.4));
assert(isfield(prob.Constraints, "Cap") && isfield(prob.Constraints, "balancedP_B001"))


%% Infinite operation limits remove the default limits
%   機器 : Pmax = 0.5 → 0.5 で頭打ち。Pmax = Inf で上限が外れ、等分 (各 1.0) に戻る
%   母線 : Vmin/Vmax = -Inf/Inf で電圧の上下限が外れる (変数の上下限が ±Inf)
%   送電線: 3 母線ループの B001-B003 の容量 0.5 → Inf (NaN も同じ) で送電制約なしの配分 (0.75, 0.25) に戻る
% 物理的な式 (母線の電力収支、送電線の潮流の式) は残る
net = DebugScript.helper.build_9bus();
g1 = net.a_Bus{1}.a_Component{1};
g1.tab_parameter.operation.Pmax = 0.5;
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD"));
assert(abs(res.tab_bus{"B001","P"} - 0.5) < 1e-5)
g1.tab_parameter.operation{1,["Pmin","Pmax"]} = [-Inf, Inf];
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD"));
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - 1)) < 1e-5)
assert(isfield(res.OPFprob.Constraints, "balancedP"))
% 負荷の規則は変わらない: 上下限が無限の負荷は潮流設定の P に固定
assert(abs(res.tab_cub{"LPQ1B005","P"} + 1.0) < 1e-6)

b5 = net.a_Bus{5};
b5.tab_parameter.operation{1,["Vmin","Vmax"]} = [0.95, 1.05];
prob = DebugScript.helper.quiet(@() net.build_opf_problem(Method="AC OPF"));
assert(prob.Variables.B005.UpperBound(2) == 1.05 && prob.Variables.B005.LowerBound(2) == 0.95)
b5.tab_parameter.operation{1,["Vmin","Vmax"]} = [-Inf, Inf];
prob = DebugScript.helper.quiet(@() net.build_opf_problem(Method="AC OPF"));
assert(isinf(prob.Variables.B005.UpperBound(2)) && isinf(prob.Variables.B005.LowerBound(2)))
assert(isfield(prob.Constraints, "balancedP_B005") && isfield(prob.Constraints, "VargRef"))

net = build_loop3();
br13 = net.a_Branch{3};
br13.tab_parameter.operation.Pmax = 0.5;
sv_gen = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(1:2), "UniformOutput", false));
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.5; 0.5])) < 1e-6)
for r_none = [Inf, NaN]
    br13.tab_parameter.operation.Pmax = r_none;
    res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
    assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.75; 0.25])) < 1e-6)
    assert(isfield(res.OPFprob.Constraints, "defP_EL003_B001"))
end


%% ReferenceBus selects the bus with a fixed angle
%   "auto": tools.slack_bus_index の母線 (9 母線系統では B001) の位相を潮流設定の Varg (NaN なら 0) に固定
%   タグ : その母線の位相を固定。DC OPF の配分と位相差は変わらない
%   "none": 位相を固定しない (VargRef なし)
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(abs(res.tab_bus{"B001","Varg"}) < 1e-9 && isfield(res.OPFprob.Constraints, "VargRef"))
res4 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", ReferenceBus="B004"));
assert(abs(res4.tab_bus{"B004","Varg"}) < 1e-9)
assert(max(abs(res4.tab_bus.P - res.tab_bus.P)) < 1e-6)
dth = res.tab_bus.Varg - res.tab_bus{"B004","Varg"};
assert(max(abs(res4.tab_bus.Varg - dth)) < 1e-6)
% 固定する値は潮流設定の Varg
net.a_Bus{4}.tab_parameter.powerflow.Varg = 0.1;
res4 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", ReferenceBus="B004"));
assert(abs(res4.tab_bus{"B004","Varg"} - 0.1) < 1e-9)
prob = net.build_opf_problem(Method="AC OPF", ReferenceBus="none");
assert(~isfield(prob.Constraints, "VargRef") && isfield(prob.Constraints, "balancedP_B001"))
% 保存された既定値として使える
net.solver_OPF.ReferenceBus = "none";
prob = net.build_opf_problem(Method="DC OPF");
assert(~isfield(prob.Constraints, "VargRef"))
prob = net.build_opf_problem(Method="DC OPF", ReferenceBus="auto");
assert(isfield(prob.Constraints, "VargRef"))
% ELD には位相がないので無視
prob = net.build_opf_problem(Method="ELD", ReferenceBus="B004");
assert(~isfield(prob.Constraints, "VargRef"))
assert(error_id(@() net.build_opf_problem(Method="DC OPF", ReferenceBus="B099")) == "GUILDA:SolverOPF:UnknownReferenceBus")


%% Stored Cost and Constraint in net.solver_OPF
% net.solver_OPF の Cost / Constraint / DefaultCost は以後の呼び出しすべてに効く。
% Name-Value で一時的に上書きでき、reset_solver で既定値に戻る
net = DebugScript.helper.build_9bus();
res0 = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
net.solver_OPF.Constraint = @(v, p) struct("Cap", v.Component.SG1B001.P <= 0.4);
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(abs(res.tab_bus{"B001","P"} - 0.4) < 1e-5 && isfield(res.lambda.Constraints, "Cap"))
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", Constraint=[]));
assert(~isfield(res.OPFprob.Constraints, "Cap") && abs(res.r_cost - res0.r_cost) < 1e-9)
assert(~isempty(net.solver_OPF.Constraint))
net.reset_solver();
assert(isempty(net.solver_OPF.Cost) && isempty(net.solver_OPF.Constraint) ...
       && net.solver_OPF.DefaultCost && net.solver_OPF.ReferenceBus == "auto")
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(abs(res.r_cost - res0.r_cost) < 1e-9)
assert(max(abs(res.tab_bus.P - res0.tab_bus.P)) < 1e-9)


%% Network-level reserve constraint and cost
% Cost / Constraint の変数は v.Component.(タグ) / v.Bus.(タグ) / v.Branch.(タグ) で参照する。
%   予備力: SG1B001, SG1B002 の余力 (2 - P) の合計 >= 2.5 → P1 + P2 <= 1.5
%     → P1 = P2 = 0.75, P3 = 1.5、乗数 = (2*1.5+1) - (2*0.75+1) = 1.5 (名前は "Reserve")
%   費用: SG1B003 に P3 を追加 → 2*P1+1 = 2*P2+1 = 2*P3+2、合計 3 → P3 = 2/3, P1 = P2 = 7/6
net = DebugScript.helper.build_9bus();
sv_g = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(1:3), "UniformOutput", false));
f_con = @(v, p) struct("Reserve", (2 - v.Component.(sv_g(1)).P) + (2 - v.Component.(sv_g(2)).P) >= 2.5);
for s_m = ["ELD","DC OPF","AC OPF"]
    [res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method=s_m, Constraint=f_con));
    assert(flag > 0)
    P = res.tab_cub{sv_g,"P"};
    assert(P(1) + P(2) <= 1.5 + 1e-6)
    assert(res.lambda.Constraints.Reserve > 1e-3)
    if s_m ~= "AC OPF"
        assert(max(abs(P - [0.75; 0.75; 1.5])) < 1e-5)
        assert(abs(res.lambda.Constraints.Reserve - 1.5) < 1e-5)
    end
end
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="ELD", Cost=@(v, p) v.Component.(sv_g(3)).P));
assert(max(abs(res.tab_cub{sv_g,"P"} - [7/6; 7/6; 2/3])) < 1e-5)
assert(abs(res.r_cost - (DebugScript.helper.opf_cost(net, res.tab_cub) + 2/3)) < 1e-6)
% 母線・送電線の変数も参照できる: B004 と B007 の位相差を 0 にする (DC OPF)
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", ...
          Constraint=@(v, p) struct("SameAngle", v.Bus.B004.Varg == v.Bus.B007.Varg, ...
                                    "Flow", v.Branch.ET001.Pfrom >= 0)));
assert(abs(res.tab_bus{"B004","Varg"} - res.tab_bus{"B007","Varg"}) < 1e-6)


%% Problem and InitialPoint solve a user-modified problem
% build_opf_problem の問題に制約を加えて optimize_powerflow(Problem=...) で解く。
% 結果の表・乗数のラベルは通常どおり (SG1B001 の P <= 0.4 → 乗数 1.8)
net = DebugScript.helper.build_9bus();
[prob, x0] = net.build_opf_problem(Method="DC OPF");
prob.Constraints.Cap = prob.Variables.SG1B001 <= 0.4;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", Problem=prob, InitialPoint=x0));
assert(flag > 0)
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.4; 1.3; 1.3])) < 1e-5)
assert(abs(res.lambda.Constraints.Cap - 1.8) < 1e-5 && isfield(res.OPFprob.Constraints, "Cap"))
% InitialPoint を省くと build_opf_problem の x0 から解く (AC OPF)
[prob, x0] = net.build_opf_problem(Method="AC OPF");
prob.Constraints.Vhigh = prob.Variables.B005("V") <= 1.0;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", Problem=prob));
assert(flag > 0 && abs(res.tab_bus{"B005","V"} - 1.0) < 1e-5 && res.lambda.Constraints.Vhigh > 1e-4)
[res2, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", Problem=prob, InitialPoint=x0));
assert(flag > 0 && abs(res2.r_cost - res.r_cost) < 1e-9)
% 変数を加えた問題: 上限 0.4 の超過 s >= 0 に費用 1*s (InitialPoint に s の初期値を加える)。
% 目的関数は GenCost の 1 つだけ (フィールドを増やすと多目的問題になる)
%   P1 <= 0.4 + s → 2*P1+1+1 = 2*P2+1 = 2*P3+1、合計 3 → P1 = 2/3, P2 = P3 = 7/6, s = 2/3 - 0.4
[prob, x0] = net.build_opf_problem(Method="DC OPF");
s = optimvar("Over", 1, "LowerBound", 0);
prob.Constraints.Cap = prob.Variables.SG1B001 <= 0.4 + s;
prob.Objective.GenCost = prob.Objective.GenCost + s;
x0.Over = 0;
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF", Problem=prob, InitialPoint=x0));
assert(flag > 0 && max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [2/3; 7/6; 7/6])) < 1e-5)
assert(abs(res.r_cost - (DebugScript.helper.opf_cost(net, res.tab_cub) + 2/3 - 0.4)) < 1e-6)
% 別の Method の問題や問題でないものは止まる。設定 (net.solver_OPF) は変わらない
prob_ELD = net.build_opf_problem(Method="ELD");
assert(error_id(@() net.optimize_powerflow(Method="DC OPF", Problem=prob_ELD)) == "GUILDA:SolverOPF:ProblemMismatch")
assert(error_id(@() net.optimize_powerflow(Method="DC OPF", Problem=1)) ~= "")
assert(isequaln(net.solver_OPF.get_options(), SolverOPF().get_options()))


%% OPF options do not make the equilibrium stale
% OPF の設定は net.solver_OPF にあり、平衡点に影響しない
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize());
assert(~DebugScript.helper.is_stale(net))
net.solver_OPF.Cost         = @(v, p) v.Component.SG1B001.P^2;
net.solver_OPF.Constraint   = @(v, p) struct("Reserve", v.Component.SG1B001.P <= 3);
net.solver_OPF.DefaultCost  = false;
net.solver_OPF.ReferenceBus = "B004";
DebugScript.helper.quiet(@() net.optimize_powerflow(Method="DC OPF"));
assert(~DebugScript.helper.is_stale(net) && isempty(DebugScript.helper.stale(net)))
% 比較: 潮流設定の編集は平衡点を古くする
net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.1;
assert(DebugScript.helper.is_stale(net))


%% Invalid Cost and Constraint stop with an error
net = DebugScript.helper.build_9bus();
assert(error_id(@() net.optimize_powerflow(Method="ELD", Cost=3)) == "GUILDA:SolverOPF:InvalidHandle")
assert(error_id(@() net.build_opf_problem(Method="ELD", Constraint="x")) == "GUILDA:SolverOPF:InvalidHandle")
assert(error_id(@() set_property(net.solver_OPF, "Cost", 3)) == "GUILDA:SolverOPF:InvalidHandle")
assert(error_id(@() net.optimize_powerflow(Method="ELD", Cost=@(v, p) [v.Component.SG1B001.P, v.Component.SG1B001.P])) == "GUILDA:SolverOPF:InvalidCost")
% v.Component.(タグ).Q は AC OPF だけ
assert(error_id(@() net.optimize_powerflow(Method="DC OPF", Cost=@(v, p) v.Component.SG1B001.Q)) == "GUILDA:SolverOPF:HandleError")
assert(error_id(@() net.optimize_powerflow(Method="ELD", Constraint=@(v, p) v.Component.SG1B001.P <= 1)) == "GUILDA:SolverOPF:InvalidConstraint")
assert(error_id(@() net.optimize_powerflow(Method="ELD", Constraint=@(v, p) struct("Cap", v.Component.SG1B001.P))) == "GUILDA:SolverOPF:InvalidConstraintField")
assert(error_id(@() net.optimize_powerflow(Method="DC OPF", Constraint=@(v, p) struct("balancedP_B001", v.Component.SG1B001.P <= 1))) == "GUILDA:SolverOPF:DuplicateName")
% build_opf_problem は問題の設定だけを受け付ける (Tolerance などソルバーの設定は不可)
assert(error_id(@() net.build_opf_problem(Tolerance=1e-6)) == "GUILDA:resolve_options:UnknownName")
% 問題を表せない Solver は使える Solver 名を示して止まる (2 次の費用に linprog)
assert(error_id(@() net.optimize_powerflow(Method="DC OPF", Solver="linprog")) == "GUILDA:SolverOPF:UnsupportedSolver")


%% OPF stops without Optimization Toolbox
% Toolbox が無い環境を license の代わりで再現する。optimize_powerflow と initialize(Method="OPF") は
% 解析の開始時に GUILDA のメッセージで止まり、潮流計算 (既定の newton) はそのまま動く
net = DebugScript.helper.build_9bus();
s_tmp = tempname;  mkdir(s_tmp);
writelines(["function varargout = license(varargin)", ...
    "if nargin >= 2 && strcmpi(varargin{1}, 'test') && strcmpi(varargin{2}, 'Optimization_Toolbox')", ...
    "    varargout = {false};  return", "end", ...
    "[varargout{1:max(nargout,1)}] = builtin('license', varargin{:});", "end"], ...
    fullfile(s_tmp, "license.m"));
w = warning("off", "MATLAB:dispatcher:nameConflict");
addpath(s_tmp);
c_tmp = onCleanup(@() cellfun(@feval, {@() rmpath(s_tmp), @() rmdir(s_tmp, "s"), ...
    @() clear("license"), @() warning(w)}));
assert(~license("test", "Optimization_Toolbox"))
try
    net.optimize_powerflow(Method="DC OPF");
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:require_toolbox:Unavailable", ME.message)
    assert(contains(ME.message, "OPF") && contains(ME.message, "Optimization Toolbox"), ME.message)
end
assert(error_id(@() net.initialize(Method="OPF")) == "GUILDA:require_toolbox:Unavailable")
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1)


%% IEEJ_WEST10 AC OPF names its branch constraints after the tags
% 制約名は送電線などのタグから作られる。IEEJ_WEST10 の LINE20_1 や G1_TR (定義ファイルは
% 変数名として有効なタグ) で AC OPF が解ける (昼間断面。夜間断面も解けるが時間がかかる)
net = DebugScript.helper.quiet(@() network.IEEJ_WEST10());
sv_bra = string(net.a_Branch);
assert(all(arrayfun(@(s) isvarname(char(s)), sv_bra)) && ismember("LINE20_1", sv_bra) && ismember("G1_TR", sv_bra))
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
assert(flag > 0)
assert(abs(sum(res.tab_bus.P) - real(DebugScript.helper.branch_losses(net, res.tab_bus.Vphasor))) < 1e-4)

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

function fd = fd_load(net, s_method, ld, s_pq, h, c_opt)
% 負荷 ld の P または Q (注入) を ±h 変えたときの最適費用の中心差分 (負荷 1 単位の増加あたり)
    v0 = ld.tab_parameter.powerflow.(s_pq);
    c_restore = onCleanup(@() set_pf(ld, s_pq, v0));
    set_pf(ld, s_pq, v0 - h);
    J_more = DebugScript.helper.quiet(@() net.optimize_powerflow("Method", s_method, c_opt{:})).r_cost;
    set_pf(ld, s_pq, v0 + h);
    J_less = DebugScript.helper.quiet(@() net.optimize_powerflow("Method", s_method, c_opt{:})).r_cost;
    fd = (J_more - J_less)/(2*h);
end

function set_pf(ld, s_pq, v)
    ld.tab_parameter.powerflow.(s_pq) = v;
end

function [b, phase] = dc_susceptance(br)
% DC OPF の送電線のサセプタンス (MATPOWER と同じ b = 1/(X*tap)、移相 phase [rad])
    d = br.tab_parameter.dynamics;
    tap = 1;  phase = 0;
    if ismember("tap", d.Properties.VariableNames) && d.tap ~= 0
        tap = d.tap;
    end
    if ismember("phase", d.Properties.VariableNames)
        phase = d.phase;
    end
    b = 1/(d.X*tap);
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
    sv_bus = string(net.a_Bus);
    for k = 1:numel(net.a_Branch)
        br = net.a_Branch{k};
        [~, iv] = ismember(string(br.a_Bus), sv_bus);
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
        id = string(DebugScript.helper.msg_id(ME));
        if id == ""
            id = "(no id)";
        end
    end
end

function set_property(obj, s_name, val)
% obj.(s_name) = val (プロパティの検証を関数ハンドルの中で確かめる)
    obj.(s_name) = val;
end


function l = shares_variable(prob1, prob2, s_var)
% prob1 と prob2 が同じ変数 s_var (ハンドル) を持つか: 一方の上下限を変えて他方を見る
    if ~isfield(prob1.Variables, s_var) || ~isfield(prob2.Variables, s_var)
        l = false;
        return
    end
    v1 = prob1.Variables.(s_var);
    v2 = prob2.Variables.(s_var);
    r_old = v1.UpperBound;
    v1.UpperBound = 123.25;      % 一意な有限値 (上限は Inf のこともある)
    l = isequal(v2.UpperBound, 123.25);
    v1.UpperBound = r_old;
end
