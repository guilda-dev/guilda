% F4 最適潮流計算 (calculate_optimal_powerflow)
%
% 3 つの方式 "ELD" / "DC OPF" / "AC OPF" で最適潮流を計算し、物理的な妥当性を確認する。
%   - v4 の呼び出し形式 [result, flag, output] と結果クラス ResultOPF
%   - Name-Value による一時的な設定の上書き (arguments ブロック。未知の名前・不正な値は MATLAB のエラー)
%   - 解が得られる (flag > 0)
%   - 需給バランス (発電の合計 = 負荷 (+ 損失))、母線ごとの電力・電流のつり合い
%   - 負荷は潮流設定の値のまま、発電機出力・電圧は上下限の範囲内
%   - ELD は等増分費用、DC OPF (送電制約なし) は ELD と同じ配分
%   - AC OPF の費用は ELD 以上、潮流計算の解での費用以下
%   - 手計算できる小さな系統: DC の混雑価格 (3 母線ループ)、AC の閉じた形と KKT 条件 (2 母線)
%   - 送電線の Imax / Smax が効く AC OPF が解ける
%   - 変数は母線の電圧と機器の電力だけ (ブランチ端の潮流は電圧の式)。上下限は名前付きの制約
%   - ラグランジュ乗数 (節点価格) = 最適費用の負荷に関する感度 (差分で確認)
%   - MATPOWER 形式への変換 (tools.network_to_mpc) と MATPOWER の case14 の最適解との一致
%   - MATPOWER との直接比較 (MATPOWER がパスに無いときは SKIP)
%   - DC OPF の送電線は MATPOWER と同じ b = 1/(X*tap) (case14 で MATPOWER の DC 定式化と一致)
%   - 負荷の既定の費用は 0。上下限を与えた負荷は価格応答する負荷として配分される
%   - 利用者の費用・制約 (Cost, Constraint): 系統全体の変数をタグで参照、名前付き制約とその乗数、
%     定数の費用 c (解は同じで費用だけ増える)、DefaultCost=false、ReferenceBus ("auto" / タグ / "none")、呼び出しだけのオプション、
%     平衡点を古くしないこと
%   - 上下限を ±Inf (送電線は NaN も) にすると既定の制約が外れる
%   - build_opf_problem の問題を変更して Problem / InitialPoint で解く
%   - IEEJ_WEST10 (送電線のタグが制約名になる系統) の AC OPF が解ける
%   - get_opf_condition (Bus / Branch / PowerNetwork): OPF が使う表、表示 (Display)
%   - 中身を見る表示と解析: disp_formulation、disp_summary、disp_binding、get_lmp (LMP と内訳)、
%     反復の記録 (sct_iteration) と plot_iteration
% 費用関数は機器の tab_parameter.OPF、制約は各クラスの tab_parameter.operation で設定する。
% 利用者の費用・制約は calculate_optimal_powerflow / build_opf_problem の Cost, Constraint で追加する。
%
% 実行: runtests("DebugScript.test_F4_opf")  または  DebugScript.run_all("Features","F4")
%
% [result, flag, output] = net.calculate_optimal_powerflow(Method=..., Name, Value)
%   result.tab_bus    : 母線ごとの解
%   result.tab_cub    : 母線への接続 (機器 "<機器名>"、送電線の端 "<送電線名>_<母線名>") ごとの、母線への注入
%   result.tab_branch : 送電線ごとの両端の潮流 (送電線へ流れ込む向き)
% 設定の既定値は GUILDA.setting の OptimalPowerFlow。Name-Value はその呼び出しだけ上書きする。
% Cost, Constraint, DefaultCost, ReferenceBus は呼び出しだけのオプション (既定 [], [], true, "auto")。

% 共通設定 (各テストの前に毎回実行される)
tol = 1e-5;
is_load = @(c) isa(c,"component.load.abstract");


%% Economic load dispatch
% 9 母線系統。送電線を無視して、負荷の合計を発電機で経済的に配分する
net = DebugScript.helper.build_9bus();
P_load = -(-1.0 - 0.8 - 1.2);

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
assert(flag > 0)
assert(istable(tab_bus) && height(tab_bus) == numel(net.a_Bus))

% 需給バランス: 母線注入の合計 = 0 (損失なし)
assert(abs(sum(tab_bus.P)) < tol)
assert(abs(sum(tab_bus{["B001","B002","B003"],"P"}) - P_load) < tol)

% 機器の行の合計 = 母線の P、負荷は指定値のまま、送電線の端は NaN
assert(abs(tab_cub{"B005LPQ1","P"} + 1.0) < tol)
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

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")); tab_bus = res.tab_bus;
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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
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
tab_ELD = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")).tab_bus;
assert(max(abs(tab_bus.P - tab_ELD.P)) < 1e-4)


%% AC optimal power flow
% 交流潮流方程式を制約にした最適潮流。電圧は 0.95-1.05 に制限する
net = DebugScript.helper.build_9bus();
for i = 1:numel(net.a_Bus)
    net.a_Bus{i}.tab_parameter.operation{1,["Vmin","Vmax"]} = [0.95, 1.05];
end
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
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
tab_cub_ELD = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")).tab_cub;
assert(J_AC >= DebugScript.helper.opf_cost(net, tab_cub_ELD) - 1e-6)
tab_PF = DebugScript.helper.quiet(@() net.calculate_powerflow().tab_bus);
assert(all(tab_PF.V >= 0.95 & tab_PF.V <= 1.05))   % 潮流解が OPF の制約を満たすことの確認
assert(J_AC <= DebugScript.helper.opf_cost(net, DebugScript.helper.pf_component_power(net, tab_PF)) + 1e-6)


%% AC OPF warm start starts from the last solution
% WarmStart=true は前回の AC OPF の解から、false (既定) はフラットスタート。同じ解に収束する
net = DebugScript.helper.build_ieee14();
[res0, flag0, out0] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", WarmStart=false));
[res1, flag1, out1] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", WarmStart=true));
assert(flag0 > 0 && flag1 > 0 && res1.options.WarmStart && ~res0.options.WarmStart)
assert(out1.iterations ~= out0.iterations)     % 初期値が違う (内点法なので反復回数は減るとは限らない)
assert(abs(res1.r_cost - res0.r_cost) < 1e-9*res0.r_cost && max(abs(res1.tab_bus.Vphasor - res0.tab_bus.Vphasor)) < 1e-4)
% build_opf_problem の初期値はフラットスタート (母線の位相 0、PV・スラックは設定値 V)
[~, x0] = DebugScript.helper.quiet(@() net.build_opf_problem(Method="AC OPF"));
s_bus = string(net.a_Bus{14});
assert(isequal(x0.(s_bus), [0; 1]))
assert(error_id(@() net.calculate_optimal_powerflow(WarmStart="on")) ~= "")
% 配布する既定値は false (ユーザー設定ファイルが既定を上書きしうるので JSON を直接読む)
sct_def = jsondecode(fileread(fullfile(GUILDA.pwd, "@GUILDA", "config", "DefaultOptimalPowerFlow.json")));
assert(sct_def.WarmStart.Value == false)


%% Every call builds the OPF problem from the current network
% 問題のキャッシュはない。呼び出しごとに tab_parameter から集めた表で問題を作るので、
% operation / OPF / powerflow / タグの編集はすぐ結果に反映される。
% 同じ問題かどうか: 問題の変数はハンドルなので、同じ問題なら一方の上下限の変更が他方に見える
net = DebugScript.helper.build_9bus();
s_var = "B001SG1";
shared = @(r1, r2) shares_variable(r1.OPFprob, r2.OPFprob, s_var);
res1 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
res2 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(~shared(res1, res2) && abs(res2.r_cost - res1.r_cost) < 1e-9*max(1, abs(res1.r_cost)))
g1 = net.a_Bus{1}.a_Component{1};
g1.tab_parameter.operation.Pmax = 0.5;
res3 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(res3.tab_cub{"B001SG1","P"} <= 0.5 + 1e-6 && res3.OPFprob.Variables.B001SG1.UpperBound == 0.5)
g1.tab_parameter.OPF.fP = g1.tab_parameter.OPF.fP + 1;
res4 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(res4.r_cost > res3.r_cost)
net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.1;
res5 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(abs(sum(res5.tab_cub{["B001SG1","B002SG1","B003SG1"],"P"}) - 3.1) < 1e-6)
g1.s_tag = "G1";
res6 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(isfield(res6.OPFprob.Variables, "G1") && ~isfield(res6.OPFprob.Variables, "B001SG1"))
% 結果の問題の上下限を変えても、次の計算には残らない
var = res6.OPFprob.Variables.G1;     % ハンドル (結果のプロパティ自体は読み取り専用)
var.UpperBound = 0.2;
res7 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(res7.OPFprob.Variables.G1.UpperBound == 0.5 && abs(res7.r_cost - res6.r_cost) < 1e-9*max(1, abs(res6.r_cost)))
% 結果は系統への参照を持たず、スナップショットのタグだけを持つ
assert(isempty(res7.a_PowerNetwork) && res7.s_network == string(net.s_tag))


%% AC OPF respects generator limits
% 発電機の出力上限・無効電力の範囲が守られ、上限に達する
net = DebugScript.helper.build_9bus();
gen = net.a_Bus{1}.a_Component{1};
gen.tab_parameter.operation{1,["Pmax","Qmin","Qmax"]} = [0.6, -0.3, 0.3];
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
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

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
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

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF")); tab_DC = res.tab_bus; tab_cub_DC = res.tab_cub;
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

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF")); tab_bus = res.tab_bus; tab_cub = res.tab_cub;
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
tab_cub_ELD = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")).tab_cub;
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

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.75; 0.25])) < 1e-6)
assert(max(abs(price(res) - 2.5)) < 1e-6)

br13 = net.a_Branch{3};
assert(isequal(string(br13.a_Bus(:)).', ["B001","B003"]))
br13.tab_parameter.operation.Pmax = 0.5;
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.5; 0.5])) < 1e-6)
assert(abs(res.tab_branch{string(br13),"Pfrom"} - 0.5) < 1e-6)
assert(max(abs(price(res) - [2; 3; 4])) < 1e-6)
assert(abs(res.r_cost - (0.5^2+0.5 + 0.5^2+2*0.5)) < 1e-6)
% 送電制約の乗数: 両端の制約 Pmax_<端> ([P; -P] <= Pmax) の乗数の合計 = μ = 3
sv_end = string(br13) + "_" + string(br13.a_Bus);
mu = sum(cellfun(@(s) sum(res.lambda.Constraints.("Pmax_"+s)), cellstr(sv_end)));
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

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Tolerance=1e-10));
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
res0 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
[~, k] = max(abs(res0.tab_branch.Ifrom));
br = net.a_Branch{k};
sv_end = string(br) + "_" + string(br.a_Bus);

r_Imax = 0.8*max(abs(res0.tab_branch{k,["Ifrom","Ito"]}));
br.tab_parameter.operation.Imax = r_Imax;
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
assert(flag > 0)
r_I = max(abs(res.tab_branch{k,["Ifrom","Ito"]}));
assert(r_I <= r_Imax + 1e-6 && r_I >= r_Imax - 1e-4)
assert(res.r_cost > res0.r_cost)
assert(max(cellfun(@(s) res.lambda.Constraints.("Imax_"+s), cellstr(sv_end))) > 0)

br.tab_parameter.operation.Imax = inf;
S0 = abs(res0.tab_branch{k,["Pfrom","Pto"]} + 1j*res0.tab_branch{k,["Qfrom","Qto"]});
r_Smax = 0.8*max(S0);
br.tab_parameter.operation.Smax = r_Smax;
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
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
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
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
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow("Method", "AC OPF", c_opt{:}));
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
assert(mpc.bus(cellfun(@(b) b.l_isSlack, net.a_Bus), 2) == 3 && sum(mpc.bus(:,2) == 3) == 1)
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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Tolerance=1e-10));
assert(flag > 0)
assert(abs(res.r_cost - 8081.53) < 0.01, sprintf("AC cost %.4f", res.r_cost))
assert(max(abs(100*res.tab_cub{sv_gen,"P"} - [194.33; 36.72; 28.74; 0; 8.50])) < 0.01)
assert(all(res.tab_bus.V >= 0.94 - 1e-6 & res.tab_bus.V <= 1.06 + 1e-6))

[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Tolerance=1e-10));
assert(flag > 0)
assert(abs(res.r_cost - rmp.f) < 1e-5*rmp.f, sprintf("AC cost: GUILDA %.6f, MATPOWER %.6f", res.r_cost, rmp.f))
assert(max(abs(res.tab_bus.V - rmp.bus(:,8))) < 1e-4)
assert(max(abs(res.tab_bus.Varg - rmp.bus(:,9)*pi/180)) < 1e-4)
assert(max(abs(res.tab_cub{sv_gen,"P"} - rmp.gen(:,2)/100)) < 1e-4)
% LMP (費用/pu) = MATPOWER の lam_P ($/MWh) * baseMVA
tab = res.get_lmp();
assert(max(abs(tab.LMP/100 - rmp.bus(:,14))) < 1e-3*max(rmp.bus(:,14)))

mpc = rmfield(tools.network_to_mpc(net), ["bus_name","gen_name","branch_name"]);
rdc = rundcopf(mpc, mpopt);
assert(rdc.success)
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(flag > 0)
assert(abs(res.r_cost - rdc.f) < 1e-6*rdc.f, sprintf("DC cost: GUILDA %.6f, MATPOWER %.6f", res.r_cost, rdc.f))
assert(max(abs(res.tab_bus.Varg - rdc.bus(:,9)*pi/180)) < 1e-5)
assert(max(abs(res.tab_cub{sv_gen,"P"} - rdc.gen(:,2)/100)) < 1e-5)


%% Result class of all three methods
% 結果は ResultOPF。flag と output を持ち、費用・ラグランジュ乗数・最適化問題も保持する
net = DebugScript.helper.build_9bus();
sct_col = struct("ELD", ["P"], "DC_OPF", ["Varg","V","P"], "AC_OPF", ["Varg","V","P","Q","Vphasor","Iphasor"]);
for s_m = ["ELD","DC OPF","AC OPF"]
    [res, flag, output] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_m));
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
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD"));
assert(abs(abs(res.lambda.Constraints.balancedP) - 3) < 1e-4)
assert(all(isnan(res.tab_branch.Pfrom)))

% 送電線の潮流 = 母線への注入 (tab_cub の送電線の端) の符号を反転したもの
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
for k = 1:numel(net.a_Branch)
    br  = net.a_Branch{k};
    str = string(br) + "_" + string(br.a_Bus);
    assert(abs(res.tab_branch{string(br),"Pfrom"} + res.tab_cub{str(1),"P"}) < 1e-12)
    assert(abs(res.tab_branch{string(br),"Ito"}   + res.tab_cub{str(2),"Iphasor"}) < 1e-12)
end
assert(all(res.tab_branch.Ploss > -1e-6))
assert(abs(sum(res.tab_branch.Ploss) - sum(res.tab_bus.P)) < 1e-4)

% 既定の方式は GUILDA.setting の OptimalPowerFlow の Method ("AC OPF")。net.solver_OPF は設定を持たない
assert(GUILDA.config("OptimalPowerFlow", "Method") == "AC OPF" && isa(net.solver_OPF, "SolverOPF") && ~isprop(net.solver_OPF, "Method"))
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow());
assert(res.options.Method == "AC OPF")


%% Name-Value options override solver defaults for one call only
net = DebugScript.helper.build_9bus();
solver   = net.solver_OPF;

% MaxIteration=2 では AC OPF は解けない
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MaxIteration=2));
assert(double(flag) <= 0 && ~res.l_success)
assert(res.options.MaxIteration == 2)
% Solver と Tolerance は solve へ渡される
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD", Solver="fmincon", Tolerance=1e-10));
assert(double(flag) > 0 && output.solver == "fmincon" && res.options.Tolerance == 1e-10)
assert(all(abs(res.tab_bus{["B001","B002","B003"],"P"} - 1) < 1e-4))
% Verbose=true はソルバーの表示 ("iter")、false は表示なし
s_on    = evalc("res = net.calculate_optimal_powerflow(Method=""DC OPF"", Verbose=true);");
assert(res.options.Verbose == true && ~isfield(res.options, "Display"))
s_off = evalc("res = net.calculate_optimal_powerflow(method=""DC OPF"", verbose=false);");   % 名前の大文字小文字は区別しない
assert(res.options.Verbose == false && strlength(s_on) > strlength(s_off) && s_off == "")
% 既定 (GUILDA.setting の Verbose = false) は何も表示しない
assert(evalc("net.calculate_optimal_powerflow(Method=""AC OPF"");") == "")

% ソルバーは置き換わらず、設定を持たない (Cost などは呼び出しだけのオプション)
assert(net.solver_OPF == solver && ~any(isprop(solver, ["Cost","Constraint","DefaultCost","ReferenceBus"])))

% 既定値は GUILDA.setting の OptimalPowerFlow。変えると以後の呼び出しすべてに効く
c_cfg = DebugScript.helper.user_config("OptimalPowerFlow", struct("Method", "ELD", "Tolerance", 1e-9));
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow());
assert(res.options.Method == "ELD" && width(res.tab_bus) == 1 && res.options.Tolerance == 1e-9)
clear c_cfg
% 設定はプロパティではない (v4 の名前なので互換なし)
assert(error_id(@() set_property(net.solver_OPF, "Method", "ELD")) ~= "")


%% Unknown or invalid options stop with an error
% オプションは arguments ブロック: 未知の名前・組でない引数・不正な値は MATLAB のエラー
net = DebugScript.helper.build_9bus();
try
    DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Methd="ELD"));
    error("DebugScript:noError", "未知のオプションでエラーにならない")
catch ME
    assert(string(ME.identifier) == "MATLAB:TooManyInputs", ME.identifier)
    assert(contains(ME.message, "Methd") && contains(ME.message, "'Method'"))
end
% 共通名以外 (ソルバー固有の名前) も受け付けない
assert(error_id(@() net.calculate_optimal_powerflow("Display", "iter")) == "MATLAB:TooManyInputs")
% 値の検証
assert(error_id(@() net.calculate_optimal_powerflow(Method="OPF")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() net.calculate_optimal_powerflow(Solver="fminunc")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() net.calculate_optimal_powerflow(MaxIteration=0)) ~= "")
% Name-Value の組になっていない
assert(error_id(@() net.calculate_optimal_powerflow("Method")) == "MATLAB:TooManyInputs")
% 旧名 optimize_powerflow は残さない (別名なし)
assert(error_id(@() net.optimize_powerflow(Method="ELD")) == "MATLAB:noSuchMethodOrField")


%% Plot and Export of the result
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));

% Plot: 機器の P, Q と母線電圧の大きさ・位相の棒 (GraphChart。AC OPF は 3 パネル、ELD は 1 パネル)。
% 棒は機器・母線のタグの要素 (P と Q の棒は同じタグ)
G = res.plot_dispatch(Parent=figure("Visible","off"));
c_fig = onCleanup(@() close(ancestor(G.ax(1), "figure")));
n_com = numel(tools.vcellfun(@(b) b.a_Component, net.a_Bus));
assert(isa(G, "GraphChart") && numel(G.ax) == 3 && all(G.tab_element.Kind == "bar"))
assert(height(G.tab_element) == 2*n_com + 2*numel(net.a_Bus) && nnz(G.tab_element.Tag == string(net.a_Bus{1}.a_Component{1})) == 2)
assert(G.ax(2).YLabel.String == "|V| [pu]" && contains(G.ax(1).Parent.Title.String, "AC OPF"))
res_ELD = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD"));
G2 = res_ELD.plot_dispatch(Parent=figure("Visible","off"));
c_fig2 = onCleanup(@() close(ancestor(G2.ax(1), "figure")));
assert(isscalar(G2.ax) && height(G2.tab_element) == n_com && G2.ax.YLabel.String == "P [pu]")
% 計算後の図は result.plot_dispatch だけ。Plot オプションは廃止。PlotFcn は fmincon の表示 (別のテスト)
% Plot は PlotFcn の省略形として読まれ、その値として不正
assert(error_id(@() net.calculate_optimal_powerflow(Method="ELD", Plot=true)) == "GUILDA:check_plotfcn:InvalidValue")
assert(error_id(@() net.calculate_optimal_powerflow(Method="ELD", PlotFcn="cost")) == "GUILDA:check_plotfcn:UnknownKey")
res_none = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD", PlotFcn="none"));
assert(res_none.options.PlotFcn == "none")

% Export: 母線・接続・送電線の表を CSV に書く
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
f_bus = res.export(fullfile(s_dir, "bus.csv"));
tab = readtable(f_bus, "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)) && max(abs(tab.V - res.tab_bus.V)) < 1e-12)
res.export(fullfile(s_dir, "cub.csv"), Table="cub");
tab = readtable(fullfile(s_dir, "cub.csv"), "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(res.tab_cub.Properties.RowNames)))
res.export(fullfile(s_dir, "branch.csv"), Table="branch");
tab = readtable(fullfile(s_dir, "branch.csv"), "ReadRowNames", true);
assert(max(abs(tab.Ploss - res.tab_branch.Ploss)) < 1e-12)
% Export オプションはない (結果は result.export で書く)
assert(error_id(@() net.calculate_optimal_powerflow(Method="DC OPF", Export=fullfile(s_dir, "opt.csv"))) == "MATLAB:TooManyInputs")
assert(error_id(@() res.export(fullfile(s_dir, "x.json"))) == "GUILDA:ResultOPF:ExportFormat")


%% Build OPF problem with Method
% net.build_opf_problem も calculate_optimal_powerflow と同じオプション名 Method を使う。
% v3 の methods オプションは残さない
net = DebugScript.helper.build_9bus();
[prob, x0] = net.build_opf_problem(Method="DC OPF");
assert(isa(prob, "optim.problemdef.OptimizationProblem") && isstruct(x0))
assert(contains(prob.Description, "DC OPF"))
assert(error_id(@() net.build_opf_problem("methods", "ELD")) == "MATLAB:TooManyInputs")
assert(error_id(@() net.calculate_optimal_powerflow("methods", "ELD")) == "MATLAB:TooManyInputs")

%% OPF variables are the bus voltages and the component powers
% AC OPF の変数は母線の [Varg; V] と機器の [P; Q] だけ (DC OPF は Varg と P、ELD は P)。ブランチ端の
% 潮流は母線電圧の式で、変数も定義式 (defP_ など) も持たない。上下限は Pmax_ / Qmax_ / Imax_ /
% Smax_ (端ごと) と VargMax1_ / VargMax2_ (ブランチごと) の制約になる
net = DebugScript.helper.build_9bus();
sv_obj = [string(net.a_Bus(:)); string(net.get_opf_condition(Display=false).Component.Properties.RowNames)];
br = net.a_Branch{1};
br.tab_parameter.operation{1, ["Pmax","Qmax","Imax","Smax","Vargmax"]} = [2, 2, 2, 2, 1];
sv_end = string(br) + "_" + reshape(string(br.a_Bus), 1, []);
for s_m = ["AC OPF","DC OPF"]
    prob = net.build_opf_problem(Method=s_m);
    assert(isempty(setxor(string(fieldnames(prob.Variables)), sv_obj)))
    sv_con = string(fieldnames(prob.Constraints));
    assert(~any(startsWith(sv_con, ["defP_","defQ_","defIre_","defIim_"])))
    sv_lim = ["Pmax_" + sv_end, "VargMax1_" + string(br), "VargMax2_" + string(br)];
    if s_m == "AC OPF"
        sv_lim = [sv_lim, reshape(["Qmax_";"Imax_";"Smax_"] + sv_end, 1, [])];
    end
    assert(all(ismember(sv_lim(:), sv_con)), s_m)
end
prob = net.build_opf_problem(Method="ELD");
assert(isempty(setxor(string(fieldnames(prob.Variables)), sv_obj(numel(net.a_Bus)+1:end))))

%% DC OPF uses the MATPOWER susceptance 1/X
% DC OPF の送電線は MATPOWER (makeBdc) と同じ b = 1/(X*tap) (タップ比・移相は from 端)。
% case14_data からこのテストの中で MATPOWER の DC 定式化 P = Bbus*θ + Pbusinj を組み立て、
% GUILDA の DC OPF の発電量から求めた位相・潮流が GUILDA の解と一致することを確かめる。
% 抵抗のある送電線では Im(Y_ij) = X/(R^2+X^2) と 1/X が違うので、旧定義とは位相が変わる。
net = DebugScript.helper.build_ieee14();
mpc = DebugScript.helper.case14_data();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
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


%% DC OPF reads NaN tap and phase of pi lines as 1 and 0
% pi の線路は tap, phase が NaN。DC OPF は tap 1, phase 0 として扱い、1 と 0 を書いた系統と同じ解になる。
net = DebugScript.helper.build_ieee14();
lv_pi = cellfun(@(b) b.key == "pi", net.a_Branch);
assert(any(lv_pi) && all(cellfun(@(b) all(isnan(b.tab_parameter.dynamics{1,["tap","phase"]})), net.a_Branch(lv_pi))))
tab_br = net.get_opf_condition().Branch;
assert(all(tab_br.tap(lv_pi) == 1) && all(tab_br.phase(lv_pi) == 0))
[res_nan, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(flag > 0)
for br = net.a_Branch(lv_pi).'
    br{1}.tab_parameter.dynamics{1,["tap","phase"]} = [1, 0];
end
[res_one, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(flag > 0 && res_nan.r_cost == res_one.r_cost)
assert(isequal(res_nan.tab_bus.Varg, res_one.tab_bus.Varg) && isequal(res_nan.tab_cub.P, res_one.tab_cub.P))


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
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD"));
assert(abs(res.r_cost - 6) < 1e-6)


%% Price-responsive load: a load with P bounds and its own cost
% 上下限が有限の負荷は潮流設定に固定されず、上下限の範囲で配分される。
% B008 の負荷 (P = -1.2) を -3 <= P <= 0、費用 4*P (1 単位消費の便益 4。Cost で追加) にする。
% 発電機 3 台 (P^2+P) の限界費用 2*Pg+1 = 4 → Pg = 1.5、需要は 4.5 - 1.8 = 2.7 (範囲内)
net = DebugScript.helper.build_9bus();
ld8 = net.a_Bus{8}.a_Component{1};
ld8.tab_parameter.operation{1,["Pmin","Pmax"]} = [-3, 0];
s_ld8 = string(ld8);
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD", Cost=@(v, p) 4*v.Component.(s_ld8).P));
assert(abs(res.tab_cub{s_ld8,"P"} + 2.7) < 1e-5)
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - 1.5)) < 1e-5)
assert(abs(abs(res.lambda.Constraints.balancedP) - 4) < 1e-5)


%% Cost option adds a user cost to the objective
% 9 母線系統の発電機 3 台 (P^2+P) のうち B001SG1 に P^2 を加え 2*P^2 + P にする。
% 等増分費用 4*P1+1 = 2*P2+1 = 2*P3+1、P1+P2+P3 = 3 → P1 = 0.6, P2 = P3 = 1.2、
% 費用 = 2*0.36+0.6 + 2*(1.44+1.2) = 6.6。DC OPF (送電制約なし) も同じ配分
net = DebugScript.helper.build_9bus();
g1 = net.a_Bus{1}.a_Component{1};
s_g1 = string(g1);
f_cost = @(v, p) v.Component.(s_g1).P^2;
for s_m = ["ELD","DC OPF"]
    [res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_m, Cost=f_cost));
    assert(flag > 0)
    assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.6; 1.2; 1.2])) < 1e-5)
    assert(abs(res.r_cost - 6.6) < 1e-6)
    assert(isequal(res.options.Cost, f_cost))
end
% AC OPF では v.Component.(tag).Q も使える
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", ...
                  Cost=@(v, p) v.Component.(s_g1).P^2 + 0.1*v.Component.(s_g1).Q^2));
assert(flag > 0)
P1 = res.tab_cub{s_g1,"P"};  Q1 = res.tab_cub{s_g1,"Q"};
assert(P1 < res.tab_cub{string(net.a_Bus{2}.a_Component{1}),"P"})
assert(abs(res.r_cost - (P1^2 + 0.1*Q1^2 + DebugScript.helper.opf_cost(net, res.tab_cub))) < 1e-6)
% p には Method と base (系統の baseMVA, Hz) が入る
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD", ...
          Cost=@(v, p) (p.Method == "ELD")*p.base.baseMVA/100*v.Component.(s_g1).P^2));
assert(abs(res.r_cost - 6.6) < 1e-6)
% 保存されない (この呼び出しだけ)
assert(isempty(DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")).options.Cost))


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
    [res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_m, DefaultCost=false, Cost=f_cost));
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


%% The constant cost c adds to the cost without changing the solution
% 列 c (定数の費用、既定 0) は DefaultCost=true のとき GenCost に足される。最適解は同じで、
% r_cost (get_summary、disp_summary、AC OPF の sct_iteration.Fval) が sum(c) だけ増える。
% 負荷の c も入る。DefaultCost=false では入らない
net = DebugScript.helper.build_9bus();
a_com = tools.vcellfun(@(b) reshape(b.a_Component, [], 1), net.a_Bus);
assert(all(cellfun(@(c) c.tab_parameter.OPF.c, a_com) == 0))
c_res0 = cell(1, 3);
sv_m = ["ELD","DC OPF","AC OPF"];
for i = 1:3
    c_res0{i} = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=sv_m(i)));
end
rv_c = 10*(1:numel(a_com));
for k = 1:numel(a_com)
    a_com{k}.tab_parameter.OPF.c = rv_c(k);
end
assert(any(cellfun(is_load, a_com) & rv_c(:) ~= 0))
for i = 1:3
    [res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=sv_m(i)));
    assert(flag > 0)
    assert(max(abs(res.tab_cub.P - c_res0{i}.tab_cub.P)) < 1e-6, sv_m(i))
    assert(abs(res.r_cost - c_res0{i}.r_cost - sum(rv_c)) < 1e-6*max(1, abs(res.r_cost)), sv_m(i))
    assert(res.get_summary().r_cost == res.r_cost && contains(evalc("res.disp_summary()"), sprintf("%.6g", res.r_cost)))
    if sv_m(i) == "AC OPF"
        assert(abs(res.sct_iteration.Fval(end) - res.r_cost) < 1e-9*max(1, abs(res.r_cost)))
    end
end
assert(abs(DebugScript.helper.opf_cost(net, res.tab_cub) - res.r_cost) < 1e-6)    % AC OPF: the sum of the costs of the components with c
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", DefaultCost=false, Cost=@(v, p) 0*v.Component.(string(a_com{1})).P));
assert(abs(res.r_cost) < 1e-9)


%% Constraint option binds and its dual has the user's name
% Constraint の struct のフィールド名 <名前> が制約名と lambda.Constraints.<名前> になる
%   機器 : B001SG1 に P <= 0.4 → P2 = P3 = 1.3、乗数 = (2*1.3+1) - (2*0.4+1) = 1.8
%   送電線: ET001 (B001→B004、発電機 1 台だけの放射状) の Pfrom <= 0.1 → P1 = 0.1, P2 = P3 = 1.45、
%          乗数 = (2*1.45+1) - (2*0.1+1) = 2.7
%   母線 : AC OPF で B005 の電圧に V <= 1.0 (制約なしの解は 1.0 を超える) → 効いて乗数 > 0
net = DebugScript.helper.build_9bus();
for s_m = ["ELD","DC OPF"]
    [res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_m, ...
                      Constraint=@(v, p) struct("Cap", v.Component.B001SG1.P <= 0.4)));
    assert(flag > 0)
    assert(isfield(res.OPFprob.Constraints, "Cap"))
    assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.4; 1.3; 1.3])) < 1e-5)
    assert(abs(res.lambda.Constraints.Cap - 1.8) < 1e-5)
end

br1 = net.a_Branch{1};
assert(string(br1) == "ET001" && isequal(string(br1.a_Bus(:)).', ["B001","B004"]))
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", ...
                  Constraint=@(v, p) struct("Pfwd", v.Branch.ET001.Pfrom <= 0.1)));
assert(flag > 0)
assert(abs(res.tab_branch{"ET001","Pfrom"} - 0.1) < 1e-6)
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.1; 1.45; 1.45])) < 1e-5)
assert(abs(res.lambda.Constraints.Pfwd - 2.7) < 1e-5)

res0 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
assert(res0.tab_bus{"B005","V"} > 1.0 + 1e-3)
% (Tolerance: 既定の 1e-6 では上限の 1e-5 内側で止まることがある)
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Tolerance=1e-9, ...
                  Constraint=@(v, p) struct("Vhigh", v.Bus.B005.V <= 1.0, "Vlow", v.Bus.B005.V >= 0.98)));
assert(flag > 0)
assert(abs(res.tab_bus{"B005","V"} - 1.0) < 1e-5)
assert(res.lambda.Constraints.Vhigh > 1e-4 && abs(res.lambda.Constraints.Vlow) < 1e-4)
assert(res.r_cost > res0.r_cost)
% build_opf_problem も同じ名前で制約を加える
prob = net.build_opf_problem(Method="DC OPF", Constraint=@(v, p) struct("Cap", v.Component.B001SG1.P <= 0.4));
assert(isfield(prob.Constraints, "Cap") && isfield(prob.Constraints, "balancedP_B001"))


%% Infinite operation limits remove the default limits
%   機器 : Pmax = 0.5 → 0.5 で頭打ち。Pmax = Inf で上限が外れ、等分 (各 1.0) に戻る
%   母線 : Vmin/Vmax = -Inf/Inf で電圧の上下限が外れる (変数の上下限が ±Inf)
%   送電線: 3 母線ループの B001-B003 の容量 0.5 → Inf (NaN も同じ) で送電制約なしの配分 (0.75, 0.25) に戻る
% 物理的な式 (母線の電力収支、送電線の潮流の式) は残る
net = DebugScript.helper.build_9bus();
g1 = net.a_Bus{1}.a_Component{1};
g1.tab_parameter.operation.Pmax = 0.5;
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD"));
assert(abs(res.tab_bus{"B001","P"} - 0.5) < 1e-5)
g1.tab_parameter.operation{1,["Pmin","Pmax"]} = [-Inf, Inf];
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD"));
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - 1)) < 1e-5)
assert(isfield(res.OPFprob.Constraints, "balancedP"))
% 負荷の規則は変わらない: 上下限が無限の負荷は潮流設定の P に固定
assert(abs(res.tab_cub{"B005LPQ1","P"} + 1.0) < 1e-6)

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
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.5; 0.5])) < 1e-6)
for r_none = [Inf, NaN]
    br13.tab_parameter.operation.Pmax = r_none;
    res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
    assert(max(abs(res.tab_cub{sv_gen,"P"} - [0.75; 0.25])) < 1e-6)
    assert(~isfield(res.OPFprob.Constraints, "Pmax_EL003_B001") && isfield(res.OPFprob.Constraints, "balancedP_B001"))
end


%% ReferenceBus selects the bus with a fixed angle
%   "auto": tools.slack_bus_index の母線 (9 母線系統では B001) の位相を潮流設定の Varg (NaN なら 0) に固定
%   タグ : その母線の位相を固定。DC OPF の配分と位相差は変わらない
%   "none": 位相を固定しない (VargRef なし)
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(abs(res.tab_bus{"B001","Varg"}) < 1e-9 && isfield(res.OPFprob.Constraints, "VargRef"))
res4 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", ReferenceBus="B004"));
assert(abs(res4.tab_bus{"B004","Varg"}) < 1e-9)
assert(max(abs(res4.tab_bus.P - res.tab_bus.P)) < 1e-6)
dth = res.tab_bus.Varg - res.tab_bus{"B004","Varg"};
assert(max(abs(res4.tab_bus.Varg - dth)) < 1e-6)
% 固定する値は潮流設定の Varg
net.a_Bus{4}.tab_parameter.powerflow.Varg = 0.1;
res4 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", ReferenceBus="B004"));
assert(abs(res4.tab_bus{"B004","Varg"} - 0.1) < 1e-9)
prob = net.build_opf_problem(Method="AC OPF", ReferenceBus="none");
assert(~isfield(prob.Constraints, "VargRef") && isfield(prob.Constraints, "balancedP_B001"))
% 呼び出しだけのオプション: 既定は "auto"
prob = net.build_opf_problem(Method="DC OPF");
assert(isfield(prob.Constraints, "VargRef"))
% ELD には位相がないので無視
prob = net.build_opf_problem(Method="ELD", ReferenceBus="B004");
assert(~isfield(prob.Constraints, "VargRef"))
assert(error_id(@() net.build_opf_problem(Method="DC OPF", ReferenceBus="B099")) == "GUILDA:SolverOPF:UnknownReferenceBus")


%% Cost and Constraint are options of the call only
% Cost / Constraint / DefaultCost / ReferenceBus は呼び出しだけのオプション。net.solver_OPF に
% 保存する場所はなく、次の呼び出しは既定値 ([], [], true, "auto") に戻る
net = DebugScript.helper.build_9bus();
res0 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", Constraint=@(v, p) struct("Cap", v.Component.B001SG1.P <= 0.4)));
assert(abs(res.tab_bus{"B001","P"} - 0.4) < 1e-5 && isfield(res.lambda.Constraints, "Cap"))
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
assert(~isfield(res.OPFprob.Constraints, "Cap") && abs(res.r_cost - res0.r_cost) < 1e-9)
assert(isempty(res.options.Cost) && isempty(res.options.Constraint) && res.options.DefaultCost)
assert(~any(isprop(net.solver_OPF, ["Cost","Constraint","DefaultCost","ReferenceBus"])))
assert(error_id(@() set_property(net.solver_OPF, "Cost", @(v, p) 0)) ~= "")


%% Network-level reserve constraint and cost
% Cost / Constraint の変数は v.Component.(タグ) / v.Bus.(タグ) / v.Branch.(タグ) で参照する。
%   予備力: B001SG1, B002SG1 の余力 (2 - P) の合計 >= 2.5 → P1 + P2 <= 1.5
%     → P1 = P2 = 0.75, P3 = 1.5、乗数 = (2*1.5+1) - (2*0.75+1) = 1.5 (名前は "Reserve")
%   費用: B003SG1 に P3 を追加 → 2*P1+1 = 2*P2+1 = 2*P3+2、合計 3 → P3 = 2/3, P1 = P2 = 7/6
net = DebugScript.helper.build_9bus();
sv_g = string(cellfun(@(b) b.a_Component{1}, net.a_Bus(1:3), "UniformOutput", false));
f_con = @(v, p) struct("Reserve", (2 - v.Component.(sv_g(1)).P) + (2 - v.Component.(sv_g(2)).P) >= 2.5);
for s_m = ["ELD","DC OPF","AC OPF"]
    [res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_m, Constraint=f_con));
    assert(flag > 0)
    P = res.tab_cub{sv_g,"P"};
    assert(P(1) + P(2) <= 1.5 + 1e-6)
    assert(res.lambda.Constraints.Reserve > 1e-3)
    if s_m ~= "AC OPF"
        assert(max(abs(P - [0.75; 0.75; 1.5])) < 1e-5)
        assert(abs(res.lambda.Constraints.Reserve - 1.5) < 1e-5)
    end
end
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD", Cost=@(v, p) v.Component.(sv_g(3)).P));
assert(max(abs(res.tab_cub{sv_g,"P"} - [7/6; 7/6; 2/3])) < 1e-5)
assert(abs(res.r_cost - (DebugScript.helper.opf_cost(net, res.tab_cub) + 2/3)) < 1e-6)
% 母線・送電線の変数も参照できる: B004 と B007 の位相差を 0 にする (DC OPF)
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", ...
          Constraint=@(v, p) struct("SameAngle", v.Bus.B004.Varg == v.Bus.B007.Varg, ...
                                    "Flow", v.Branch.ET001.Pfrom >= 0)));
assert(abs(res.tab_bus{"B004","Varg"} - res.tab_bus{"B007","Varg"}) < 1e-6)


%% Problem and InitialPoint solve a user-modified problem
% build_opf_problem の問題に制約を加えて calculate_optimal_powerflow(Problem=...) で解く。
% 結果の表・乗数のラベルは通常どおり (B001SG1 の P <= 0.4 → 乗数 1.8)
net = DebugScript.helper.build_9bus();
[prob, x0] = net.build_opf_problem(Method="DC OPF");
prob.Constraints.Cap = prob.Variables.B001SG1 <= 0.4;
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", Problem=prob, InitialPoint=x0));
assert(flag > 0)
assert(max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [0.4; 1.3; 1.3])) < 1e-5)
assert(abs(res.lambda.Constraints.Cap - 1.8) < 1e-5 && isfield(res.OPFprob.Constraints, "Cap"))
% InitialPoint を省くと build_opf_problem の x0 から解く (AC OPF)
[prob, x0] = net.build_opf_problem(Method="AC OPF");
prob.Constraints.Vhigh = prob.Variables.B005("V") <= 1.0;
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Problem=prob));
assert(flag > 0 && abs(res.tab_bus{"B005","V"} - 1.0) < 1e-5 && res.lambda.Constraints.Vhigh > 1e-4)
[res2, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Problem=prob, InitialPoint=x0));
assert(flag > 0 && abs(res2.r_cost - res.r_cost) < 1e-9)
% 変数を加えた問題: 上限 0.4 の超過 s >= 0 に費用 1*s (InitialPoint に s の初期値を加える)。
% 目的関数は GenCost の 1 つだけ (フィールドを増やすと多目的問題になる)
%   P1 <= 0.4 + s → 2*P1+1+1 = 2*P2+1 = 2*P3+1、合計 3 → P1 = 2/3, P2 = P3 = 7/6, s = 2/3 - 0.4
[prob, x0] = net.build_opf_problem(Method="DC OPF");
s = optimvar("Over", 1, "LowerBound", 0);
prob.Constraints.Cap = prob.Variables.B001SG1 <= 0.4 + s;
prob.Objective.GenCost = prob.Objective.GenCost + s;
x0.Over = 0;
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", Problem=prob, InitialPoint=x0));
assert(flag > 0 && max(abs(res.tab_bus{["B001","B002","B003"],"P"} - [2/3; 7/6; 7/6])) < 1e-5)
assert(abs(res.r_cost - (DebugScript.helper.opf_cost(net, res.tab_cub) + 2/3 - 0.4)) < 1e-6)
% 別の Method の問題や問題でないものは止まる
prob_ELD = net.build_opf_problem(Method="ELD");
assert(error_id(@() net.calculate_optimal_powerflow(Method="DC OPF", Problem=prob_ELD)) == "GUILDA:SolverOPF:ProblemMismatch")
assert(error_id(@() net.calculate_optimal_powerflow(Method="DC OPF", Problem=1)) ~= "")


%% OPF options do not make the equilibrium stale
% OPF のオプションは呼び出しだけのもので、平衡点に影響しない
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize());
assert(~DebugScript.helper.is_stale(net))
DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", ...
    Cost=@(v, p) v.Component.B001SG1.P^2, Constraint=@(v, p) struct("Reserve", v.Component.B001SG1.P <= 3), ...
    DefaultCost=false, ReferenceBus="B004"));
assert(~DebugScript.helper.is_stale(net) && isempty(DebugScript.helper.stale(net)))
% 比較: 潮流設定の編集は平衡点を古くする
net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.1;
assert(DebugScript.helper.is_stale(net))


%% Invalid Cost and Constraint stop with an error
net = DebugScript.helper.build_9bus();
assert(error_id(@() net.calculate_optimal_powerflow(Method="ELD", Cost=3)) == "GUILDA:PowerNetwork:InvalidOpfHandle")
assert(error_id(@() net.build_opf_problem(Method="ELD", Constraint="x")) == "GUILDA:PowerNetwork:InvalidOpfHandle")
assert(error_id(@() net.calculate_optimal_powerflow(Method="ELD", Cost=@(v, p) [v.Component.B001SG1.P, v.Component.B001SG1.P])) == "GUILDA:SolverOPF:InvalidCost")
% v.Component.(タグ).Q は AC OPF だけ
assert(error_id(@() net.calculate_optimal_powerflow(Method="DC OPF", Cost=@(v, p) v.Component.B001SG1.Q)) == "GUILDA:SolverOPF:HandleError")
assert(error_id(@() net.calculate_optimal_powerflow(Method="ELD", Constraint=@(v, p) v.Component.B001SG1.P <= 1)) == "GUILDA:SolverOPF:InvalidConstraint")
assert(error_id(@() net.calculate_optimal_powerflow(Method="ELD", Constraint=@(v, p) struct("Cap", v.Component.B001SG1.P))) == "GUILDA:SolverOPF:InvalidConstraintField")
assert(error_id(@() net.calculate_optimal_powerflow(Method="DC OPF", Constraint=@(v, p) struct("balancedP_B001", v.Component.B001SG1.P <= 1))) == "GUILDA:SolverOPF:DuplicateName")
% build_opf_problem は問題の設定だけを受け付ける (Tolerance などソルバーの設定は不可)
assert(error_id(@() net.build_opf_problem(Tolerance=1e-6)) == "MATLAB:TooManyInputs")
% 問題を表せない Solver は使える Solver 名を示して止まる (2 次の費用に linprog)
assert(error_id(@() net.calculate_optimal_powerflow(Method="DC OPF", Solver="linprog")) == "GUILDA:SolverOPF:UnsupportedSolver")


%% OPF stops without Optimization Toolbox
% Toolbox が無い環境を license の代わりで再現する。calculate_optimal_powerflow と initialize(Method="OPF") は
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
    net.calculate_optimal_powerflow(Method="DC OPF");
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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
assert(flag > 0)
assert(abs(sum(res.tab_bus.P) - real(DebugScript.helper.branch_losses(net, res.tab_bus.Vphasor))) < 1e-4)


%% disp_formulation shows the formulation and the counts of a built problem
% SolverOPF.disp_formulation は Method ごとの一般形 (目的関数と制約) を表示する。Problem を
% 渡すと、式ごとに問題の中の制約の件数を並べる (上下限は有限の上下限を持つ変数の数)
net = DebugScript.helper.build_ieee14();
s = net.solver_OPF.disp_formulation(Method="AC OPF");
assert(contains(s, "balancedP_<bus>") && contains(s, "balancedQ_<bus>") && contains(s, "Smax_<branch>_<bus>") ...
    && contains(s, "VargRef") && contains(s, "GenCost"))
assert(contains(s, "fQ_g*Q_g + c_g (+ Cost)"))
s = net.solver_OPF.disp_formulation(Method="ELD");
assert(contains(s, "balancedP") && ~contains(s, "balancedQ") && ~contains(s, "Smax") && contains(s, "fP_g*P_g + c_g (+ Cost)"))
assert(strlength(evalc("net.solver_OPF.disp_formulation(Method=""DC OPF"");")) > 0)
net.a_Branch{1}.tab_parameter.operation.Smax = 1;
prob = net.build_opf_problem(Method="AC OPF", Constraint=@(v, p) struct("Cap", v.Component.B001SG1.P <= 2));
sv = splitlines(net.solver_OPF.disp_formulation(Method="AC OPF", Problem=prob));
count = @(s_key) str2double(regexp(sv(contains(sv, s_key)), "(\d+)\s*$", "tokens", "once"));
assert(count("balancedP_<bus>") == 14 && count("Smax_<branch>_<bus>") == 2 && count("Imax_<branch>_<bus>") == 0)
assert(count("bounds of <bus>") == 14 && count("VargRef") == 1)
assert(count("other constraints") == 1 && any(contains(sv, "Cap")))


%% disp_summary and disp_binding show the binding constraints
% 効いている制約 (値が制限値の 1e-4*max(1,|制限値|) 以内) の一覧。値・制限値は物理量
% (ブランチ端の |S| など)、乗数は lambda の値。disp_summary は費用・発電・損失・件数・LMP の範囲
net = DebugScript.helper.build_ieee14();
net.a_Branch{1}.tab_parameter.operation.Smax = 1;
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
s = res.disp_binding(Kind="Branch");
assert(contains(s, "Smax_EL001_B001") && ~contains(s, "Vmax"))
s = res.disp_binding();
assert(contains(s, "Smax_EL001_B001") && contains(s, "Vmax") && ~contains(s, "balancedP"))
assert(contains(evalc("res.disp_binding(Kind=""Bound"");"), "Vmax"))
s = res.disp_summary();
assert(contains(s, "AC OPF") && contains(s, "- Binding constraints") && contains(s, "(branch limits 1)") && contains(s, "- LMP"))
% DC の 3 母線ループ: B001-B003 の容量 0.5 が効く (両端の Pmax_ の要素がそれぞれ 1 つ)
net = build_loop3();
net.a_Branch{3}.tab_parameter.operation.Pmax = 0.5;
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
sv = splitlines(res.disp_binding(Kind="Branch"));
assert(sum(contains(sv, "Pmax_")) == 2 && all(contains(sv(contains(sv, "Pmax_")), "0.5")))
% 効いている制約のない結果
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD"));
assert(contains(res.disp_binding(Kind="Branch"), "No binding constraints"))


%% get_lmp returns the nodal prices and their components
% LMP = -lambda.Constraints.balancedP_<母線> (費用/pu) = Energy + Congestion + Loss。
%   ELD: 全母線で同じ。DC OPF: 損失分 0、混雑がなければ全母線で同じ (発電機 1 の限界費用)。
%   3 母線ループで容量が効くと [2; 3; 4] (エネルギー分 = 基準母線 B001 の 2、混雑分 [0; 1; 2])。
%   AC OPF: 内訳の和 = LMP、基準母線の損失分・混雑分は 0、出力が上下限の内側の発電機の母線では
%   LMP = 限界費用 2*HP*P + fP。基準母線を変えると内訳は変わるが LMP は変わらない
net = DebugScript.helper.build_ieee14();
g1  = net.a_Bus{1}.a_Component{1};
mc  = @(res) 2*g1.tab_parameter.OPF.HP*res.tab_cub{string(g1),"P"} + g1.tab_parameter.OPF.fP;
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD"));
tab = res.get_lmp();
assert(isequal(string(tab.Properties.VariableNames), ["LMP","Energy","Congestion","Loss"]) && height(tab) == 14)
assert(all(tab.LMP == tab.LMP(1)) && all(tab.Energy == tab.LMP) && all(tab.Congestion == 0 & tab.Loss == 0))
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF"));
tab = res.get_lmp();
assert(max(abs(tab.LMP - tab.LMP(1))) < 1e-6*tab.LMP(1) && all(tab.Loss == 0) && abs(tab.LMP(1) - mc(res)) < 1e-6*tab.LMP(1))
net3 = build_loop3();
net3.a_Branch{3}.tab_parameter.operation.Pmax = 0.5;
tab = DebugScript.helper.quiet(@() net3.calculate_optimal_powerflow(Method="DC OPF")).get_lmp();
assert(max(abs(tab.LMP - [2; 3; 4])) < 1e-6 && max(abs(tab.Energy - 2)) < 1e-6 && max(abs(tab.Congestion - [0; 1; 2])) < 1e-6)
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Tolerance=1e-10));
tab = res.get_lmp();
assert(max(abs(tab.LMP - (tab.Energy + tab.Congestion + tab.Loss))) < 1e-9*max(tab.LMP))
assert(tab{"B001","Loss"} == 0 && abs(tab{"B001","Congestion"}) < 1e-9 && abs(tab{"B001","LMP"} - mc(res)) < 1e-4*mc(res))
assert(all(tab.Loss(2:end) > 0))        % 負荷へ送る向きの母線では、1 単位多く注入すると損失が減る
tab2 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Tolerance=1e-10, ReferenceBus="B002")).get_lmp();
assert(max(abs(tab2.LMP - tab.LMP)) < 1e-4*max(tab.LMP) && abs(tab2{"B002","Energy"} - tab2{"B002","LMP"}) < 1e-9*max(tab.LMP))
assert(abs(tab2{"B001","Energy"} - tab{"B001","Energy"}) > 1)


%% plot_lmp colors the buses by their LMP and selects the binding branches
% 3 母線ループで容量 (Pmax) が効く DC OPF: 母線の色の値 = LMP [2; 3; 4]、効いているブランチが選択される。
% ELD (全母線で同じ価格) と AC OPF でも図を表示せずに作れる
a_before = findall(groot, "Type", "figure");
c_fig = onCleanup(@() close(setdiff(findall(groot, "Type", "figure"), a_before)));
net3 = build_loop3();
net3.a_Branch{3}.tab_parameter.operation.Pmax = 0.5;
res = DebugScript.helper.quiet(@() net3.calculate_optimal_powerflow(Method="DC OPF"));
G = res.plot_lmp(Parent=figure("Visible", "off"));
assert(isa(G, "GraphNetDiagram") && G.ColorMode == "user" && max(abs(G.BusColorData - [2; 3; 4])) < 1e-6)
assert(isequal(G.Selection, string(net3.a_Branch{3}.s_tag)) && G.ColorLimits(1) <= 2 && G.ColorLimits(2) >= 4)
assert(contains(G.ax.Title.String, "DC OPF") && G.ColorbarLabel == "LMP [cost/pu]" && G.ax.Colorbar.Label.String == "LMP [cost/pu]")
for s_m = ["ELD","AC OPF"]
    res = DebugScript.helper.quiet(@() net3.calculate_optimal_powerflow(Method=s_m));
    G = res.plot_lmp(Parent=figure("Visible", "off"), LabelMode="none");
    tab = res.get_lmp();
    assert(max(abs(G.BusColorData - tab.LMP)) < 1e-9 && G.LabelMode == "none" && diff(G.ColorLimits) > 0)
end


%% AC OPF records its iterations and plot_iteration plays them
% AC OPF (fmincon) は OutputFcn で反復ごとに x、目的関数値、制約違反量を sct_iteration に記録する。
% plot_iteration は図を表示せずに作れ、4 パネルの GraphChart と系統図の GraphNetDiagram
% (axes の Tag "Network") を返す。2 つは link で連動し、再生バーは G_chart の 1 本だけ (系統図は
% axes に描くのでバーがない) で、そのスライダーと再生 (animate) で両方が反復を切り替える。
% 自前の uicontrol (Tag "Iteration"・"Play") はない。グラフは 2x2 の格子 (対数軸の目盛りの数字も出る)。
% set_time を直接呼んでも (どちらの G でも)、題・スライダー・系統図がその反復になる
% (G_chart の TimeChangedFcn)。コールバックは弱い参照で G をたどるので、savefig しても警告が出ず、
% 保存のあとも動く。出力を受け取らなくても、受け取った G を clear しても、スライダーは効く
% (図が G を持ち続ける)。Parent は uipanel や uigridlayout でもよい。
% linprog・quadprog (ELD、DC OPF) は記録がなく、GUILDA:ResultOPF:NoIteration で止まる
net = DebugScript.helper.build_9bus();
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
sct = res.sct_iteration;
assert(flag > 0 && isequal(string(fieldnames(sct)).', ["Iteration","Fval","ConstrViolation","X"]))
n_it = numel(sct.Iteration);
assert(sct.Iteration(end) == output.iterations && numel(sct.Fval) == n_it && numel(sct.ConstrViolation) == n_it)
assert(abs(sct.Fval(end) - res.r_cost) < 1e-9*max(1, abs(res.r_cost)))
assert(isequal(size(sct.X.B001), [2, n_it]) && max(abs(sct.X.B001(:,end) - res.tab_bus{"B001",["Varg","V"]}.')) < 1e-12)
assert(isequal(sort(string(fieldnames(sct.X))), sort(string(fieldnames(res.OPFprob.Variables)))))
assert(res.sct_network.s_tag == net.s_tag && numel(res.sct_network.a_Bus) == numel(net.a_Bus))
a_before = findall(groot, "Type", "figure");
c_fig = onCleanup(@() close(setdiff(findall(groot, "Type", "figure"), a_before)));
f = figure("Visible", "off");
[G_chart, G_net] = res.plot_iteration(Parent=f);
assert(isa(G_chart, "GraphChart") && isa(G_net, "GraphNetDiagram") && numel(G_chart.ax) == 4 && G_net.ax.Tag == "Network")
assert(isequal(G_chart.rv_t, sct.Iteration) && isequal(G_net.rv_t, sct.Iteration) && G_chart.ax(2).YScale == "log")
assert(isequal(G_chart.ax(1).Parent.GridSize, [2 2]) && numel(G_chart.ax(2).YTick) >= 3 && ~isempty(G_chart.ax(2).YTickLabel))
assert(all(ismember(["Fval","ConstrViolation","B001"], G_chart.tab_element.Tag)) && all(G_chart.tab_element.Kind == "line"))
f_color = @() get(findall(G_net.ax, "Type", "line"), {"Color", "MarkerFaceColor", "MarkerSize", "LineWidth"});   % 2D の系統図の線と記号
c_last  = f_color();
h_now = findall(f, "Tag", "TimeCursor");                   % GraphChart の時刻のカーソル (4 パネル)
assert(numel(h_now) == 4 && all([h_now.Value] == sct.Iteration(end)) && G_net.i_time == n_it)
assert(isempty(findall(f, "Tag", "Iteration")) && isempty(findall(f, "Tag", "Play")))   % 自前の部品はない
h_bar = findall(f, "Tag", "GUILDA:GraphBase:PlaybackBar");  % 再生バーは G_chart の 1 本だけ
assert(isscalar(h_bar) && isempty(findall(G_net.ax.Parent, "Tag", "GUILDA:GraphBase:PlaybackBar")))
assert(isa(G_net.ax.Parent, "matlab.ui.container.Panel") && isequal(G_net.ax.Parent.Position, [0.64 0 0.36 1]))
sl = findall(h_bar, "Tag", "GUILDA:GraphBase:TimeSlider");
assert(sl.Value == n_it)
sl.Value = 2;
sl.ValueChangedFcn(sl, []);
assert(all([h_now.Value] == sct.Iteration(2)) && contains(G_chart.ax(1).Parent.Title.String, "2 of") && G_net.i_time == 2)
assert(~isequal(f_color(), c_last) && startsWith(G_net.ax.Title.String, "violations"))   % 系統図も 2 番目の反復
G_chart.animate(Speed=Inf);                                % 2 番目から最後まで再生 (バーの Play と同じ順)
assert(all([h_now.Value] == sct.Iteration(end)) && sl.Value == n_it && G_net.i_time == n_it)
c_last = f_color();
G_net.set_time(sct.Iteration(3));                          % link: 系統図の時刻でグラフのカーソル、題、系統図も動く
assert(all([h_now.Value] == sct.Iteration(3)) && contains(G_chart.ax(1).Parent.Title.String, "3 of") && sl.Value == 3)
assert(~isequal(f_color(), c_last) && startsWith(G_net.ax.Title.String, "violations"))
G_chart.set_time(sct.Iteration(end));
assert(sl.Value == n_it && contains(G_chart.ax(1).Parent.Title.String, n_it + " of"))
s_fig = [tempname '.fig'];                                 % 保存: コールバックは弱い参照なので警告が出ない
c_file = onCleanup(@() delete(s_fig));
lastwarn("");
savefig(f, s_fig);
[s_warn, s_warnId] = lastwarn();
assert(isempty(s_warn), "savefig warned: %s (%s)", s_warn, s_warnId)
c_last = f_color();
sl.Value = 2;                                              % 保存のあとも、スライダーと set_time で表示が変わる
sl.ValueChangedFcn(sl, []);
assert(all([h_now.Value] == sct.Iteration(2)) && contains(G_chart.ax(1).Parent.Title.String, "2 of") && ~isequal(f_color(), c_last))
G_chart.set_time(sct.Iteration(end));
assert(sl.Value == n_it && G_net.i_time == n_it && isequal(f_color(), c_last))
clear c_file
close(f)
for l_clear = [false, true]                                % 出力を受け取らない、受け取って clear しても動く
    f = figure("Visible", "off");
    if l_clear
        [G_chart, G_net] = res.plot_iteration(Parent=f);
        clear G_chart G_net
    else
        res.plot_iteration(Parent=f);
    end
    h_now = findall(f, "Tag", "TimeCursor");
    ax_net = findobj(f, "Tag", "Network");
    c_last = get(findall(ax_net, "Type", "line"), {"Color", "MarkerFaceColor", "MarkerSize", "LineWidth"});
    sl = findall(f, "Tag", "GUILDA:GraphBase:TimeSlider");
    sl.Value = 2;
    sl.ValueChangedFcn(sl, []);
    assert(all([h_now.Value] == sct.Iteration(2)) && contains(h_now(1).Parent.Parent.Title.String, "2 of"))
    assert(~isequal(get(findall(ax_net, "Type", "line"), {"Color", "MarkerFaceColor", "MarkerSize", "LineWidth"}), c_last))
    close(f)
end
f = figure("Visible", "off");
[G_chart, G_net] = res.plot_iteration(Parent=uipanel(f));            % コンテナ: uipanel
assert(isscalar(findall(f, "Tag", "GUILDA:GraphBase:TimeSlider")) && G_net.i_time == n_it && isequal(G_chart.ax(1).Parent.GridSize, [2 2]))
close(f)
f = uifigure("Visible", "off");
[~, G_net] = res.plot_iteration(Parent=uigridlayout(f, [1 1]));       % uigridlayout
assert(G_net.i_time == n_it && isscalar(findall(f, "Tag", "GUILDA:GraphBase:PlaybackBar")))
close(f)
for s_m = ["ELD","DC OPF"]
    res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_m));
    assert(isempty(fieldnames(res.sct_iteration)))
    assert(error_id(@() res.plot_iteration(Parent=figure("Visible","off"))) == "GUILDA:ResultOPF:NoIteration")
end

% ---- local functions ----
%% Settings of one solver go only to that solver
% キーは <Solver 名><MATLAB のオプション名>。共通の MaxIteration・Tolerance は全ソルバー
net = DebugScript.helper.build_9bus();
sct_cfg = GUILDA.config("OptimalPowerFlow");
sv_key = string(fieldnames(sct_cfg)).';
assert(all(ismember(["LinprogAlgorithm","QuadprogAlgorithm","FminconAlgorithm","QuadprogStepTolerance", ...
    "FminconStepTolerance","FminconMaxFunctionEvaluations","FminconUseParallel"], sv_key)))
assert(~any(ismember(["Algorithm_linprog","StepTolerance","MaxFunctionEvaluations","UseParallel","Display"], sv_key)))
c_cfg = DebugScript.helper.user_config("OptimalPowerFlow", struct("FminconStepTolerance", 1e-12, ...
    "FminconMaxFunctionEvaluations", 30, "QuadprogStepTolerance", 1e-13, "FminconAlgorithm", "sqp"));
% fmincon の設定は linprog・quadprog (ELD、DC OPF) には渡らない (渡ると optimoptions のエラー)
sct_opt = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD")).options;   % 実効設定
[s_solver, c_nv] = net.solver_OPF.optimoption(net.build_opf_problem(Method="ELD"), sct_opt);
o_opt = c_nv{find(cellfun(@(c) isequal(c, "Options"), c_nv)) + 1};
assert(s_solver ~= "fmincon" && class(o_opt) == "optim.options." + upper(extractBefore(s_solver, 2)) + extractAfter(s_solver, 1))
assert(~isprop(o_opt, "StepTolerance") || o_opt.StepTolerance == 1e-13)    % quadprog: its own QuadprogStepTolerance
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="DC OPF", Solver="quadprog"));
assert(res.l_success && res.output.solver == "quadprog")
% AC OPF の fmincon には渡る: 関数評価 30 回で止まる
sct_opt.Method = "AC OPF";
[s_solver, c_nv] = net.solver_OPF.optimoption(net.build_opf_problem(Method="AC OPF"), sct_opt);
o_opt = c_nv{find(cellfun(@(c) isequal(c, "Options"), c_nv)) + 1};
assert(s_solver == "fmincon" && o_opt.MaxFunctionEvaluations == 30 && o_opt.StepTolerance == 1e-12 && o_opt.Algorithm == "sqp")
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
assert(double(flag) == 0 && ~res.l_success)      % exitflag 0: MaxFunctionEvaluations reached
clear c_cfg
% Name-Value の MaxIteration・Tolerance の NaN はソルバーの既定
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD", MaxIteration=NaN, Tolerance=NaN));
assert(res.l_success && isnan(res.options.MaxIteration))


%% PlotFcn draws the plot functions of fmincon in AC OPF
% キー k は fmincon の optimplot<k>。"none" と結果は同じ
net = DebugScript.helper.build_9bus();
a_before = findall(groot, "Type", "figure");
c_fig = onCleanup(@() close(setdiff(findall(groot, "Type", "figure"), a_before)));
res0 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
sv_key = ["fval","constrviolation","fvalconstr","firstorderopt","stepsize","funccount","x"];
res1 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", PlotFcn=sv_key));
assert(res1.l_success && res1.r_cost == res0.r_cost && isequal(res1.tab_bus, res0.tab_bus))
assert(isequal(res1.options.PlotFcn, sv_key))
% 反復の記録 (OutputFcn) は PlotFcn と両立し、PlotFcn がなくても同じ記録になる
assert(isequal(res1.sct_iteration, res0.sct_iteration) && numel(res0.sct_iteration.Iteration) >= 2)
a_new = setdiff(findall(groot, "Type", "figure"), a_before);
assert(isscalar(a_new) && numel(findobj(a_new, "Type", "axes")) == numel(sv_key))
% 図は使い回す (fmincon の動作): 2 回目も図は 1 枚、キーごとの軸に反復の点
DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", PlotFcn="fval"));
a_new = setdiff(findall(groot, "Type", "figure"), a_before);
ax = findobj(a_new, "Type", "axes");
assert(isscalar(a_new) && isscalar(ax) && numel(ax.Children(1).XData) >= 2)     % optimplotfval: a scatter of the iterates
% 関数ハンドルは fmincon にそのまま渡す (stop = f(x, optimValues, state))
m_log = containers.Map({'state'}, {strings(1,0)});
res2 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", PlotFcn=@(x, o, s) opf_log(m_log, o, s)));
sv_state = m_log("state");
assert(res2.l_success && sv_state(1) == "init" && sv_state(end) == "done" && any(sv_state == "iter"))
% stop = true で fmincon が止まる (exitflag -1)
[res3, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", PlotFcn=@(x, o, s) o.iteration >= 1));
assert(~res3.l_success && double(flag) == -1)
% linprog・quadprog (ELD、DC OPF) は PlotFcn を持たない: Solver 名を挙げたエラー
for s_method = ["ELD","DC OPF"]
    try
        DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_method, PlotFcn="fval"));
        error("DebugScript:noError", "linprog / quadprog の PlotFcn でエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverOPF:PlotFcnUnsupported", DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, ["linprog","quadprog"]) && contains(ME.message, s_method))
    end
    assert(error_id(@() net.calculate_optimal_powerflow(Method=s_method, PlotFcn=@(x, o, s) false)) == "GUILDA:SolverOPF:PlotFcnUnsupported")
end
% fmincon を選べば ELD でも表示できる
res4 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="ELD", Solver="fmincon", PlotFcn="fval"));
assert(res4.l_success)
% GUILDA.setting の PlotFcn (select) にキーがある
assert(isequal(string(GUILDA.config("OptimalPowerFlow").PlotFcn.options(:)).', ["none", sv_key]))
assert(GUILDA.config("OptimalPowerFlow", "Verbose") == false && ~isfield(GUILDA.config("OptimalPowerFlow"), "Display"))


%% Stability-constrained OPF raises the smallest damping ratio of IEEE14 and leaves the network as it was
% MinDampingRatio = 0.048 (制約なしの OPF の点で 0.0447): 外側の反復で線形化した減衰比の制約を
% 加え、最後の点で ζ_min >= 0.048、費用は制約なしより大きく、反復ごとに増える。結果の表 (sct_stability)、
% flag、message、disp_summary の 1 行。系統 (スナップショット、solver_PF のウォームスタート) は変わらない。
% 定数の費用 c (全機器 1000) を足しても、スラックの重みは c を除いた費用で決まるので結果は同じ
net = DebugScript.helper.build_ieee14();
r0  = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF"));
assert(isempty(fieldnames(r0.sct_stability)))                % 既定 (NaN) では安定度の計算をしない
sct_net = struct(net, false);
w = warning("off", "MATLAB:structOnObject");
sct_pf = struct(net.solver_PF);                             % ウォームスタート (private) を含む
warning(w);
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.048));
tab = res.sct_stability.tab_iteration;
assert(flag > 0 && res.l_success && contains(output.message, "stability limits hold"))
assert(isequal(string(tab.Properties.VariableNames), ["Iteration","Cost","MinDampingRatio","MaxRealPart","CriticalMode","Step","Flag"]))
assert(tab.MinDampingRatio(1) < 0.048 && tab.MinDampingRatio(end) >= 0.048 && res.r_cost > r0.r_cost)
assert(abs(tab.Cost(1) - r0.r_cost) < 1e-6*r0.r_cost && all(diff(tab.Cost) > 0) && abs(tab.Cost(end) - res.r_cost) < 1e-9*res.r_cost)
tab_m = res.sct_stability.tab_mode;
assert(abs(min(tab_m.DampingRatio) - tab.MinDampingRatio(end)) < 1e-12 && all(ismember(tab_m.Owner, net.get_variable_map().Owner)))
assert(isfield(res.lambda.Constraints, "StabilityDamping") && isequal(res.options.StabilityStep, [0.1 0.02]))
assert(contains(res.disp_summary(), "- Stability: minimum damping ratio"))
w = warning("off", "MATLAB:structOnObject");
assert(isequaln(struct(net, false), sct_net) && isequaln(struct(net.solver_PF), sct_pf))
warning(w);
% 定数の費用 c はスラックの重みに入らない: 全機器 c = 1000 でも同じ反復と解、費用は Σc だけ大きい
a_com = tools.vcellfun(@(b) reshape(b.a_Component, [], 1), net.a_Bus);
for k = 1:numel(a_com)
    a_com{k}.tab_parameter.OPF.c = 1000;
end
[res_c, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.048));
tab_c = res_c.sct_stability.tab_iteration;
assert(flag > 0 && height(tab_c) == height(tab) && abs(tab_c.MinDampingRatio(end) - tab.MinDampingRatio(end)) < 1e-6)
assert(abs(res_c.r_cost - 1000*numel(a_com) - res.r_cost) < 1e-6*res.r_cost && max(abs(res_c.tab_cub.P - res.tab_cub.P)) < 1e-5)


%% Stability-constrained OPF on a poorly damped network and with MaxRealPart
% IEEE14 の発電機の制動係数 D を 1/10 にすると ζ_min は 0.031 になり、MinDampingRatio = 0.033 を
% 満たす点へ動く。IEEE39 (AVR なし) の OPF の点の最大実部 -0.0122 (B039SG1 の実固有値) は
% MaxRealPart = -0.0124 で -0.0124 以下になる
net = DebugScript.helper.build_ieee14();
for i = 1:numel(net.a_Bus)
    for c = net.a_Bus{i}.a_Component
        if isa(c{1}, "component.generator.abstract")
            c{1}.tab_parameter.dynamics.D = c{1}.tab_parameter.dynamics.D/10;
        end
    end
end
DebugScript.helper.quiet(@() net.initialize());
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.033));
tab = res.sct_stability.tab_iteration;
assert(flag > 0 && tab.MinDampingRatio(1) < 0.032 && tab.MinDampingRatio(end) >= 0.033 && height(tab) > 1)
net = network.IEEE39Bus();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MaxRealPart=-0.0124));
tab = res.sct_stability.tab_iteration;
assert(flag > 0 && tab.MaxRealPart(1) > -0.0124 && tab.MaxRealPart(end) <= -0.0124 && isnan(res.options.MinDampingRatio))


%% Stability-constrained OPF uses the equilibria of the controllers and reports a limit it cannot meet
% 制御器 (AVR、PSS) のある IEEE9: 制約なしの解の点のモードは、initialize(Method="OPF") のあとの
% get_sys のモードと同じ。満たせない基準 (MinDampingRatio = 0.9) では StabilityMaxIteration 回で
% flag 0、l_success false、message に未達の値。系統は変わらない
net = network.IEEE9bus();
sct_net = struct(net, false);
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MaxRealPart=100, StabilityMaxIteration=1));
net2 = network.IEEE9bus();
DebugScript.helper.quiet(@() net2.initialize(Method="OPF"));
sys = net2.get_sys(Type="ODE", Format="struct");
lam = eig(sys.A, sys.E);
lam = lam(isfinite(lam) & abs(imag(lam)) > 1e-6);
assert(abs(min(-real(lam)./abs(lam)) - res.sct_stability.tab_iteration.MinDampingRatio) < 1e-6)
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.9, StabilityMaxIteration=2));
assert(flag == 0 && ~res.l_success && height(res.sct_stability.tab_iteration) == 2 && contains(output.message, "not met after 2 outer iterations"))
assert(isequaln(struct(net, false), sct_net))


%% Stability-constrained OPF returns the last solution, not the iterate of an OPF that stopped
% 2 回目の外側の反復の OPF を PlotFcn で止める (fmincon の exitflag -1)。その最後の点は解ではない
% (潮流の釣り合いを満たさず、費用が最適値より小さく見えることがある) ので返さない: 結果は 1 回目の
% 解、flag 0、l_success false、tab_iteration の最後に止まった OPF の行 (Cost と制限の値 NaN、
% Flag -1)、警告 GUILDA:PowerNetwork:StabilityOPFFailed、message に 1 回目の値
net = network.IEEE9bus();
r0 = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", Progress="none"));
map_n = containers.Map("n", 0);
lastwarn("");
w = warning("off", "GUILDA:PowerNetwork:StabilityOPFFailed");
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", ...
    MinDampingRatio=0.9, StabilityMaxIteration=3, PlotFcn=@(x, v, s) stop_second_solve(map_n, v, s)));
[~, s_id] = lastwarn();
warning(w);
close all force
tab = res.sct_stability.tab_iteration;
assert(s_id == "GUILDA:PowerNetwork:StabilityOPFFailed", s_id)
assert(flag == 0 && ~res.l_success && height(tab) == 2 && isequaln(tab{2, ["Cost","MinDampingRatio","MaxRealPart"]}, [NaN NaN NaN]) && tab.Flag(2) == -1)
assert(abs(res.r_cost - tab.Cost(1)) < 1e-9*abs(tab.Cost(1)) && abs(res.r_cost - r0.r_cost) < 1e-6*abs(r0.r_cost))
assert(max(abs(res.tab_bus.V - r0.tab_bus.V)) < 1e-6)
assert(contains(output.message, "outer iteration 2") && contains(output.message, "the solution of outer iteration 1"))


%% CriticalMode lists the modes by the limit they are near
% MinDampingRatio: 減衰比の小さい順。MaxRealPart (StabilityBand を広げて実部 -100 より大きいモード): 実部の大きい順。
% 両方: 減衰比の制限に近いモードを先に、そのあと実部の制限だけに近いモード。1 回の反復の
% tab_mode (その解のモード) から同じ並びを作って比べる
net = network.IEEE9bus();
f_list = @(tab_m, iv) strjoin(tab_m.Owner(iv) + compose(" %.3g Hz", tab_m.Frequency(iv)), ", ");
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.9, StabilityMaxIteration=1, Progress="none"));
tab_m = res.sct_stability.tab_mode;
iv = find(~isnan(tab_m.DampingRatio));
[~, o] = sort(tab_m.DampingRatio(iv));
assert(res.sct_stability.tab_iteration.CriticalMode == f_list(tab_m, iv(o)))
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MaxRealPart=0, StabilityBand=[0.02 100], StabilityMaxIteration=1, Progress="none"));
tab_m = res.sct_stability.tab_mode;
iv = find(real(tab_m.Eigenvalue) > -100);                                  % within the band of MaxRealPart = 0
[~, o] = sort(real(tab_m.Eigenvalue(iv)), "descend");
assert(res.sct_stability.tab_iteration.CriticalMode == f_list(tab_m, iv(o)))
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.1, MaxRealPart=0, StabilityBand=[0.02 100], StabilityMaxIteration=1, Progress="none"));
tab_m = res.sct_stability.tab_mode;
iv_z = find(tab_m.DampingRatio < 0.12);
[~, o] = sort(tab_m.DampingRatio(iv_z));
iv_r = setdiff(find(real(tab_m.Eigenvalue) > -100), iv_z);
[~, o_r] = sort(real(tab_m.Eigenvalue(iv_r)), "descend");
assert(~isempty(iv_z) && ~isempty(iv_r))
assert(res.sct_stability.tab_iteration.CriticalMode == f_list(tab_m, [iv_z(o); iv_r(o_r)]))


%% Stability-constrained OPF gives the controllers that observe the states the state at its point
% IEEE9 の B002 の発電機に pss-retrofit (Static AVR の下)、B003 の発電機に local-LQR を付ける。
% OPF の解の点の hat_x と uc は、保存された平衡点ではなく、その点の発電機の状態になる。
% 制約なしの解の点のモードは、initialize(Method="OPF") の平衡点で、同じ系統 (設計は
% initialize のまま) を線形化したモードと同じ
c_net = cell(1, 2);
for m = 1:2
    c_net{m} = network.IEEE9bus();
    gen = c_net{m}.a_Bus{2}.a_Component{1};
    gen.remove_local_controller(gen.avr.s_tag, RemoveNested=true);
    DebugScript.helper.quiet(@() gen.add_local_controller("avr-static"));
    gen.add_local_controller("pss-retrofit", parameter=struct(R=0.01));
    gen = c_net{m}.a_Bus{3}.a_Component{1};
    gen.remove_local_controller(gen.avr.s_tag, RemoveNested=true);
    DebugScript.helper.quiet(@() gen.add_local_controller("local-LQR"));
end
[net, net2] = c_net{:};
DebugScript.helper.quiet(@() net.initialize);
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MaxRealPart=100, StabilityMaxIteration=1));
DebugScript.helper.quiet(@() net2.initialize(Method="OPF"));
tab2 = net2.get_variable_map();
tab2 = tab2(ismember(tab2.Kind, ["x","Vre","Vim","u","uc"]), :);
gen = net2.a_Bus{2}.a_Component{1};
assert(max(abs(gen.rv_Xequilibrium - net.a_Bus{2}.a_Component{1}.rv_Xequilibrium)) > 1e-3)   % the OPF point is away from the equilibrium
sys = net.get_sys(tab2.Equilibrium, Type="ODE", Format="struct");
sct = tools.linear_modes(sys.A, sys.E, tab2.Owner(tab2.Kind == "x"));
lv  = ~sct.l_zero;
tab_it = res.sct_stability.tab_iteration;
assert(abs(min(sct.zeta(lv & sct.l_osc)) - tab_it.MinDampingRatio(1)) < 1e-6)
assert(abs(max(real(sct.lambda(lv))) - tab_it.MaxRealPart(1)) < 1e-6)


%% Stability-constrained OPF tells about extra zero eigenvalues and modes it cannot follow
% 発電機の D = 0 (速度の制御もない) の 9 母線では周波数のモードもゼロ固有値になり、島 1 つに対して
% ゼロ固有値 2 つ: INFO GUILDA:PowerNetwork:StabilityZeroEigenvalues。同じ発電機 3 台が負荷母線を
% 囲む系統では電気機械モードが重なり、差分の点で固有ベクトルが回るので追跡できない:
% INFO GUILDA:PowerNetwork:StabilityModeNotTracked (モードの所有者と固有値を含む)。
% そのモードには切断面を作らずに続ける。ShowInfo=false では表示しない
net = DebugScript.helper.build_9bus();
for i = 1:3
    net.a_Bus{i}.a_Component{1}.tab_parameter.dynamics.D = 0;
end
DebugScript.helper.quiet(@() net.initialize());
s_out = evalc('net.calculate_optimal_powerflow(Method="AC OPF", MaxRealPart=100, StabilityMaxIteration=1);');
assert(contains(s_out, "INFO: The stability-constrained OPF left out 2 zero eigenvalues") && contains(s_out, "has 1 islands"))
net = PowerNetwork("Sym3");
for i = 1:4
    net.add_bus();
end
for i = 1:3
    net.add_branch("pi", [i,4], "X", 0.2);
    g = net.a_Bus{i}.add_component("gen-park");
    g.tab_parameter.powerflow{:,["P","Q"]} = [0.5, nan];
    net.a_Bus{i}.tab_parameter.powerflow{:,"V"} = 1;
end
net.a_Bus{4}.add_component("load-power", "P", -1.5, "Q", -0.3);
evalc("net.a_Bus{1}.l_isSlack = true;");
DebugScript.helper.quiet(@() net.initialize());
s_out = evalc('[res, flag] = net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.5, StabilityMaxIteration=2);');
assert(contains(s_out, "INFO: The stability-constrained OPF could not follow the modes B001SG1 0.347 Hz") && flag == 0)
assert(height(res.sct_stability.tab_iteration) == 2 && ~isfield(res.lambda.Constraints, "StabilityDamping"))
c_set = DebugScript.helper.user_config("Message", struct("ShowInfo", false)); %#ok<NASGU>
s_out = evalc('net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.5, StabilityMaxIteration=2);');
assert(~contains(s_out, "INFO"))


%% Stability options need AC OPF and valid values
% DC OPF・ELD での MinDampingRatio・MaxRealPart は GUILDA:PowerNetwork:StabilityNeedsACOPF。
% 2 要素の設定 (StabilityStep など) は GUILDA.config から 1x2 で読める
net = DebugScript.helper.build_9bus();
assert(error_id(@() net.calculate_optimal_powerflow(Method="DC OPF", MinDampingRatio=0.05)) == "GUILDA:PowerNetwork:StabilityNeedsACOPF")
assert(error_id(@() net.calculate_optimal_powerflow(Method="ELD", MaxRealPart=0)) == "GUILDA:PowerNetwork:StabilityNeedsACOPF")
assert(isequal(GUILDA.config("OptimalPowerFlow", "StabilityStep"), [0.1 0.02]) && isequal(size(GUILDA.config("OptimalPowerFlow", "StabilityBand")), [1 2]))
assert(startsWith(error_id(@() net.calculate_optimal_powerflow(StabilityStep=[0.1 -1])), "MATLAB:validators:"))
assert(startsWith(error_id(@() net.calculate_optimal_powerflow(MinDampingRatio=1.5)), "MATLAB:validators:"))


%% get_opf_condition shows the data the OPF runs with
% IEEE14bus: Bus / Branch の get_opf_condition を積み重ねた表が、OPF が使うデータ
% (tab_parameter の operation, dynamics, powerflow, OPF) と行・列・値まで一致する
net = DebugScript.helper.quiet(@() DebugScript.helper.build_ieee14());
a_load = net.a_Bus{3}.a_Component(cellfun(is_load, net.a_Bus{3}.a_Component));
ld = a_load{1};
set_pf(ld, "P", -0.9);
ld.tab_parameter.operation.Qmin = -0.5;      % Q は上下限があるので固定しない (Qmax は Inf のまま)
sct = net.get_opf_condition(Display=false);
assert(isequal(fieldnames(sct), {'Bus';'Component';'Branch'}))
assert(isequal(string(sct.Bus.Properties.VariableNames), ["Vmin","Vmax","Gshunt","Bshunt","Type","V","Varg"]))
assert(isequal(string(sct.Component.Properties.VariableNames), ["Bus","HP","fP","HQ","fQ","c","P0","Q0","Pmin","Pmax","Qmin","Qmax"]))
assert(isequal(string(sct.Branch.Properties.VariableNames), ["From","To","Y","X","tap","phase","Pmax","Qmax","Vargmax","Imax","Smax"]))
assert(isequal(string(sct.Bus.Properties.RowNames), string(net.a_Bus)))
assert(isequal(string(sct.Branch.Properties.RowNames), string(net.a_Branch)))
a_com = tools.vcellfun(@(b) reshape(b.a_Component, [], 1), net.a_Bus);
assert(isequal(string(sct.Component.Properties.RowNames), string(a_com)))
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    row = sct.Bus(string(bus), :);
    assert(isequaln([row.Vmin, row.Vmax], [bus.tab_parameter.operation.Vmin, bus.tab_parameter.operation.Vmax]))
    assert(isequaln([row.Gshunt, row.Bshunt], [bus.tab_parameter.dynamics.Gshunt, bus.tab_parameter.dynamics.Bshunt]))
    assert(isequaln([row.V, row.Varg], [bus.tab_parameter.powerflow.V, bus.tab_parameter.powerflow.Varg]))
    assert(row.Type == bus.get_pf_condition().Type)
    [tb, tc] = bus.get_opf_condition(Display=false);
    assert(isequaln(tb, row) && isequaln(tc, sct.Component(string(bus.a_Component), :)))
    assert(all(tc.Bus == string(bus)))
end
for k = 1:numel(a_com)
    com = a_com{k};
    row = sct.Component(string(com), :);
    assert(isequaln([row.HP, row.fP, row.HQ, row.fQ, row.c], [com.tab_parameter.OPF.HP, com.tab_parameter.OPF.fP, com.tab_parameter.OPF.HQ, com.tab_parameter.OPF.fQ, com.tab_parameter.OPF.c]))
    if ~is_load(com)
        assert(isequaln([row.P0, row.Q0, row.Pmin, row.Pmax, row.Qmin, row.Qmax], ...
            [com.tab_parameter.OPF.P0, com.tab_parameter.OPF.Q0, com.tab_parameter.operation.Pmin, ...
             com.tab_parameter.operation.Pmax, com.tab_parameter.operation.Qmin, com.tab_parameter.operation.Qmax]))
    end
end
% 上下限が両方 Inf の負荷は潮流設定の P, Q に固定 (上下限と初期値)、上下限のある側はそのまま
row = sct.Component(string(ld), :);
assert(row.Pmin == -0.9 && row.Pmax == -0.9 && row.P0 == -0.9)
assert(row.Qmin == -0.5 && row.Qmax == Inf && row.Q0 == ld.tab_parameter.OPF.Q0)
for k = 1:numel(net.a_Branch)
    br  = net.a_Branch{k};
    row = sct.Branch(string(br), :);
    assert(row.From == string(br.a_Bus{1}) && row.To == string(br.a_Bus{2}))
    assert(isequal(squeeze(row.Y), br.get_admittance_matrix))
    [b, phase] = dc_susceptance(br);
    assert(abs(1/(row.X*row.tap) - b) < 1e-12 && row.phase == phase)
    ope = br.tab_parameter.operation;
    assert(isequaln([row.Pmax, row.Qmax, row.Vargmax, row.Imax, row.Smax], [ope.Pmax, ope.Qmax, ope.Vargmax, ope.Imax, ope.Smax]))
    assert(isequaln(br.get_opf_condition(Display=false), row))
end
% OPF はこの表から作る: 問題の説明 (SolverOPF) が同じ表を示し、解は表を変えない
prob = net.build_opf_problem(Method="DC OPF");
assert(contains(prob.Description, formattedDisplayText(sct.Component)))
% Display=true (既定): 見出し Bus, Component, Branch の下に表を表示し、Y の列は表示しない
s_text = evalc("net.get_opf_condition();");
assert(all(contains(s_text, ["Bus","Component","Branch"])))
assert(~contains(s_text, regexpPattern("\<Y\>")))
assert(contains(s_text, formattedDisplayText(sct.Bus)) && contains(s_text, formattedDisplayText(removevars(sct.Branch, "Y"))))
s_text = evalc("net.a_Bus{3}.get_opf_condition();");
assert(contains(s_text, "Bus") && contains(s_text, "Component") && ~contains(s_text, "Branch"))
s_text = evalc("net.a_Branch{1}.get_opf_condition();");
assert(contains(s_text, "Branch") && ~contains(s_text, regexpPattern("\<Y\>")))
% Display=true でも出力を受け取れば表を返す。Display=false は何も表示しない
s_text = evalc("sct2 = net.get_opf_condition();");
assert(strlength(s_text) > 0 && isequaln(sct2, sct))
assert(evalc("net.get_opf_condition(Display=false);") == "")
assert(evalc("net.a_Bus{3}.get_opf_condition(Display=false);") == "")
assert(evalc("net.a_Branch{1}.get_opf_condition(Display=false);") == "")
% calculate_optimal_powerflow は表を表示しない
assert(evalc("net.calculate_optimal_powerflow(Method=""DC OPF"");") == "")
% 母線・送電線の無い系統は列だけの表
sct0 = PowerNetwork("Empty").get_opf_condition(Display=false);
assert(height(sct0.Bus) == 0 && height(sct0.Component) == 0 && height(sct0.Branch) == 0)
assert(isequal(sct0.Branch.Properties.VariableNames, sct.Branch.Properties.VariableNames))


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
    J_more = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow("Method", s_method, c_opt{:})).r_cost;
    set_pf(ld, s_pq, v0 + h);
    J_less = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow("Method", s_method, c_opt{:})).r_cost;
    fd = (J_more - J_less)/(2*h);
end

function set_pf(ld, s_pq, v)
    ld.tab_parameter.powerflow.(s_pq) = v;
end

function [b, phase] = dc_susceptance(br)
% DC OPF の送電線のサセプタンス (MATPOWER と同じ b = 1/(X*tap)、移相 phase [rad])
    d = br.tab_parameter.dynamics;
    tap = 1;  phase = 0;
    if ismember("tap", d.Properties.VariableNames) && ~isnan(d.tap) && d.tap ~= 0
        tap = d.tap;
    end
    if ismember("phase", d.Properties.VariableNames) && ~isnan(d.phase)
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
        br.tab_parameter.dynamics{1,["R","X","C"]} = [mpc.branch(j,3:4), mpc.branch(j,5)/2];
        if br.key ~= "pi"   % 線路の tap, phase は NaN のまま
            br.tab_parameter.dynamics{1,["tap","phase"]} = [r_tap, mpc.branch(j,10)*pi/180];
        end
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


function stop = opf_log(m_log, sct, s_state)
% PlotFcn の関数ハンドル (fmincon): 呼ばれた state を m_log に足す
    assert(isstruct(sct) && isfield(sct, "iteration"))
    m_log("state") = [m_log("state"), string(s_state)];
    stop = false;
end


function stop = stop_second_solve(map_n, v, s_state)
    % PlotFcn of fmincon that stops the second solve after its first iteration (counts in map_n)
    if s_state == "init"
        map_n("n") = map_n("n") + 1;
    end
    stop = map_n("n") >= 2 && v.iteration >= 1;
end
