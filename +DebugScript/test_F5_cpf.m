% F5 連続型潮流計算 (ContinuationPowerFlow)
%
% 負荷を λ 倍で増やしたときの潮流解を予測子・修正子法でたどり、PV 曲線 (ノーズカーブ) を求める。
%   cpf = ContinuationPowerFlow(net, "CPFBus", 負荷母線のタグ);
%   [sol, sol_pred] = cpf.solve;     % sol の最終行が λ
%   cpf.CPF_Result.x_sol             % 母線ごとに [|V|; ∠V] を並べた解 + 最終行 λ
% 旧入口 Continuation_Power_Flow(net, opt) も確認する。
%
% 実行: runtests("DebugScript.test_F5_cpf")  または  DebugScript.run_all("Features","F5")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
str_load = ["B009","B010","B011","B012","B013","B014"];     % 負荷を増やす母線
n_bus = numel(net.a_Bus);


%% CPF traces the nose curve
cpf = DebugScript.helper.quiet(@() ContinuationPowerFlow(net, "CPFBus", str_load));
sol = DebugScript.helper.quiet(@() cpf.solve);
lambda = sol(end,:);

% λ は 0 から増加し、ノーズ (最大負荷点) を越えると減少に転じる
assert(lambda(1) == 0)
[lam_max, i_max] = max(lambda);
assert(lam_max > 0)
assert(i_max > 1 && i_max < numel(lambda), "ノーズ点を越えていない")
assert(lambda(end) < lam_max)


%% CPF starts from the equilibrium and voltage drops toward the nose
cpf = DebugScript.helper.quiet(@() ContinuationPowerFlow(net, "CPFBus", str_load));
DebugScript.helper.quiet(@() cpf.solve);
x_sol  = cpf.CPF_Result.x_sol;
assert(size(x_sol,1) == 2*n_bus + 1)

% 出発点は initialize で求めた平衡点
V_abs = x_sol(1:2:2*n_bus, :);
V_arg = x_sol(2:2:2*n_bus, :);
assert(norm(V_abs(:,1) - abs(net.cv_Vequilibrium)) < 1e-6)
assert(norm(V_arg(:,1) - angle(net.cv_Vequilibrium)) < 1e-6)

% ノーズ点では負荷母線の電圧が下がっている
[~, i_max] = max(x_sol(end,:));
[~, idx]   = ismember(str_load, string(net.a_Bus));
assert(all(V_abs(idx, i_max) < V_abs(idx, 1)))

% 予測子の結果も同じ大きさで保存される
assert(isequal(size(cpf.CPF_Result.x_prd), size(x_sol)))


%% Legacy entry Continuation_Power_Flow
% 旧バージョン互換の関数 Continuation_Power_Flow(net, opt)
opt = struct("CPFBus", str_load);
cpf = DebugScript.helper.quiet(@() Continuation_Power_Flow(net, opt));
assert(isa(cpf, "ContinuationPowerFlow"))
assert(isequal(cpf.CPFBus(:)', str_load))
