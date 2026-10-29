% F5 連続型潮流計算 (calculate_continuation_powerflow)
%
% 負荷を (1 + λ) 倍で増やしたときの潮流解を予測子・修正子法でたどり、PV 曲線 (ノーズカーブ) を求める。
%   [res, flag, output] = net.calculate_continuation_powerflow(LoadBus=負荷母線のタグ);
%   res.rv_lambda, res.cm_Vbus      % 経路上の λ と母線電圧
%   res.r_lambdaMax, res.tab_nose   % ノーズ点 (最大負荷点)
% 次も確認する。
%   - Name-Value による一時的な設定の上書き (net.solver_CPF は変わらない)
%   - 前提条件 (平衡点・負荷母線) の誤りと未知のオプションのエラー
%   - Plot / Export
%   - 旧入口 Continuation_Power_Flow(net, opt) と旧コンストラクタ ContinuationPowerFlow(net, ...)
%
% 実行: runtests("DebugScript.test_F5_cpf")  または  DebugScript.run_all("Features","F5")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
str_load = ["B009","B010","B011","B012","B013","B014"];     % 負荷を増やす母線
n_bus = numel(net.a_Bus);


%% CPF traces the nose curve
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=str_load));
lambda = res.rv_lambda;

% 結果クラスも flag と output を持つ
assert(isa(res, "CPFResult") && isa(res, "AnalysisResult"))
assert(islogical(flag) && flag && res.l_success && isequal(res.output, output))
assert(isfield(output, "message") && output.iterations == numel(lambda) - 1)
assert(numel(output.correctorIterations) == output.iterations)

% λ は 0 から増加し、ノーズ (最大負荷点) を越えると減少に転じる
assert(lambda(1) == 0)
[lam_max, i_max] = max(lambda);
assert(lam_max > 0 && res.r_lambdaMax == lam_max && res.r_noseStep == i_max)
assert(i_max > 1 && i_max < numel(lambda), "ノーズ点を越えていない")
assert(lambda(end) < lam_max)


%% CPF starts from the equilibrium and voltage drops toward the nose
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=str_load));
assert(isequal(res.sv_bus, string(net.a_Bus(:))))
assert(isequal(size(res.cm_Vbus), [n_bus, numel(res.rv_lambda)]))

% 出発点は initialize で求めた平衡点
assert(norm(res.cm_Vbus(:,1) - net.cv_Vequilibrium) < 1e-6)

% ノーズ点では負荷母線の電圧が下がっている
[~, idx] = ismember(str_load, res.sv_bus);
V_abs = abs(res.cm_Vbus);
assert(all(V_abs(idx, res.r_noseStep) < V_abs(idx, 1)))
tab = res.tab_nose;
assert(isequal(string(tab.Properties.RowNames), res.sv_bus) && norm(tab.V - V_abs(:, res.r_noseStep)) < 1e-12)

% 全変数のベクトル (v3 の x_sol / x_prd): 母線ごとに [|V|; ∠V]、最終行が λ
assert(size(res.rm_x,1) == 2*n_bus + 1 && isequal(res.rm_x(end,:), res.rv_lambda))
assert(norm(res.rm_x(1:2:2*n_bus,:) - V_abs) < 1e-12)
assert(isequal(size(res.rm_xPredicted), size(res.rm_x)) && all(isnan(res.rm_xPredicted(:,1))))

% 設定と系統の参照
assert(res.str_solver == "ContinuationPowerFlow" && res.a_PowerNetwork == net && res.r_elapsed >= 0)
assert(isequal(res.options.LoadBus, str_load) && res.options.MaxIterations == net.solver_CPF.MaxIterations)


%% Name-Value options override solver defaults for one call only
% このセクションは net.solver_CPF を書き換えるので専用の系統を使う
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
solver = net.solver_CPF;
s_before = solver.get_options();

% MaxIteration=3 ではノーズに届かない
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow( ...
    LoadBus=str_load, MaxIteration=3, StepSize=0.4, ArcLength=2e-3, Tolerance=1e-6));
assert(~flag && ~res.l_success && numel(res.rv_lambda) == 4 && contains(output.message, "MaxIteration"))
assert(res.options.MaxIterations == 3 && res.options.StepSize == 0.4 && res.options.ArcLength == 2e-3 && res.options.Tolerance == 1e-6)
% 実効設定は get_options で確認できる (InitialLambda は出発点の λ)
s_opt = solver.get_options({"InitialLambda", 0.1, "UseInternalState", true});
assert(s_opt.InitialLambda == 0.1 && s_opt.UseInternalState && s_opt.MaxIterations == solver.MaxIterations)
% Verbose=true は各ステップの λ を表示する (名前の大文字小文字は区別しない)
str_log = evalc("net.calculate_continuation_powerflow(loadbus=str_load, maxiteration=2, verbose=true);");
assert(count(str_log, "CPF step") == 2)

% 保存されている既定値は変わらない
assert(isequal(s_before, solver.get_options()) && net.solver_CPF == solver && isempty(solver.LoadBus))

% 既定値を変えると以後の呼び出しすべてに効く
net.solver_CPF.LoadBus = str_load;
net.solver_CPF.MaxIterations = 2;
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow());
assert(isequal(res.options.LoadBus, str_load) && numel(res.rv_lambda) == 3)


%% Failed preconditions and unknown options stop with an error
% 負荷母線の指定がない / 系統にない母線
assert(error_id(@() net.calculate_continuation_powerflow()) == "GUILDA:ContinuationPowerFlow:EmptyLoadBus")
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus="B099")) == "GUILDA:ContinuationPowerFlow:UnknownLoadBus")
% initialize 前は平衡点がない (9 母線系統は作成時に initialize しない)
net2 = DebugScript.helper.build_9bus();
assert(error_id(@() net2.calculate_continuation_powerflow(LoadBus="B005")) == "GUILDA:ContinuationPowerFlow:NoEquilibrium")

% 未知のオプション (v3 の名前も受け付けない)
try
    DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=str_load, CPFMaxIter=10));
    error("DebugScript:noError", "未知のオプションでエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:resolve_options:UnknownName", ME.identifier)
    assert(contains(ME.message, "CPFMaxIter") && contains(ME.message, "LoadBus, MaxIteration, Tolerance"))
end
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=str_load, Method="x")) == "GUILDA:resolve_options:UnknownName")
% 値の検証
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=str_load, StepSize=-1)) ~= "")
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=str_load, MaxIteration=1.5)) ~= "")
assert(error_id(@() net.calculate_continuation_powerflow("LoadBus")) == "GUILDA:resolve_options:InvalidPairs")

% initialize 後に編集した系統は平衡点が古い (共通設定の系統は変えない)
net3 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net3.initialize);
evalc("net3.a_Bus{2}.l_isSlack = true;");
assert(net3.l_staleEquilibrium)
assert(error_id(@() net3.calculate_continuation_powerflow(LoadBus=str_load)) == "GUILDA:ContinuationPowerFlow:StaleEquilibrium")


%% Plot and Export of the result
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=str_load));

% Plot: 既定は負荷母線の PV 曲線
ax = res.Plot(Parent=figure("Visible","off"));
c_fig = onCleanup(@() close(ancestor(ax, "figure")));
assert(isa(ax, "matlab.graphics.axis.Axes") && numel(findobj(ax, "Type", "line")) == numel(str_load))
ax2 = res.Plot(Bus="all", Parent=figure("Visible","off"));
c_fig2 = onCleanup(@() close(ancestor(ax2, "figure")));
assert(numel(findobj(ax2, "Type", "line")) == n_bus)
assert(error_id(@() res.Plot(Bus="B099", Parent=figure("Visible","off"))) == "GUILDA:CPFResult:UnknownBus")
close(findall(groot, "Type", "figure", "Visible", "off"))
% Plot=true は計算後に result.Plot を呼ぶ
a_before = findall(groot, "Type", "figure");
DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=str_load, MaxIteration=2, Plot=true));
a_after = findall(groot, "Type", "figure");
a_new   = a_after(~ismember(a_after, a_before));
assert(numel(a_new) == 1)
close(a_new)

% Export: 経路の表 (lambda, V_<bus>, Varg_<bus>)
str_dir = tempname; mkdir(str_dir); c_dir = onCleanup(@() rmdir(str_dir, "s"));
f_csv = res.Export(fullfile(str_dir, "cpf.csv"));
tab = readtable(f_csv, "VariableNamingRule", "preserve");
assert(height(tab) == numel(res.rv_lambda) && width(tab) == 1 + 2*n_bus)
assert(max(abs(tab.lambda - res.rv_lambda(:))) < 1e-12 && max(abs(tab.V_B009 - abs(res.cm_Vbus(9,:)).')) < 1e-12)
% Export=filename は計算後に result.Export を呼ぶ
DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=str_load, MaxIteration=2, Export=fullfile(str_dir, "nv.csv")));
assert(isfile(fullfile(str_dir, "nv.csv")))
assert(error_id(@() res.Export(fullfile(str_dir, "cpf.mat"))) == "GUILDA:CPFResult:ExportFormat")


%% COMPAT v3 Continuation_Power_Flow and ContinuationPowerFlow constructor
% 旧入口 Continuation_Power_Flow(net, opt) は警告して v3 の使い方を保つ
clear Deprecated
lastwarn("");
opt = struct("CPFBus", str_load, "CPFMaxIter", 500);
cpf = DebugScript.helper.quiet(@() Continuation_Power_Flow(net, opt));
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:ContinuationPowerFlowFunction")
assert(isa(cpf, "ContinuationPowerFlowV3") && isequal(cpf.CPFBus(:)', str_load))
[sol, sol_pred] = DebugScript.helper.quiet(@() cpf.solve);
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=str_load));
assert(isequal(sol, cpf.CPF_Result.x_sol) && isequaln(sol_pred, cpf.CPF_Result.x_prd))
assert(norm(sol - res.rm_x) < 1e-12 && isa(cpf.CPF_Result.result, "CPFResult"))
assert(isempty(net.solver_CPF.LoadBus))      % 既定値は変わらない

% 旧コンストラクタ ContinuationPowerFlow(net, ...) は v4 の呼び方を示すエラー
assert(error_id(@() ContinuationPowerFlow(net, "CPFBus", str_load)) == "GUILDA:Deprecated:ContinuationPowerFlowConstructor")
assert(isa(ContinuationPowerFlow(), "ContinuationPowerFlow"))


% ---- local functions ----
function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        evalc("fcn();");
    catch ME
        id = string(ME.identifier);
        if id == ""
            id = "(no id)";
        end
    end
end
