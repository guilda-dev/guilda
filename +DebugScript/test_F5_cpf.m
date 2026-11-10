% F5 連続潮流計算 (calculate_continuation_powerflow)
%
% 負荷を (1 + λ) 倍で増やしたときの潮流解を予測子・修正子法でたどり、PV 曲線 (ノーズカーブ) を求める。
%   [res, flag, output] = net.calculate_continuation_powerflow(LoadBus=負荷母線のタグ);
%   res.rv_lambda, res.cm_Vbus      % 経路上の λ と母線電圧
%   res.r_lambdaMax, res.tab_nose   % ノーズ点 (最大負荷点)
% 次も確認する。
%   - Name-Value による一時的な設定の上書き (net.solver_CPF は変わらない)
%   - 前提条件 (平衡点・負荷母線) の誤りと未知のオプションのエラー
%   - Limits による operation 制約 (Q: PV→PQ の切替、V・S: 最初に達した制約で停止)
%   - Plot / Export
%   - 旧入口 Continuation_Power_Flow(net, opt) と旧コンストラクタ SolverCPF(net, ...)
%
% 実行: runtests("DebugScript.test_F5_cpf")  または  DebugScript.run_all("Features","F5")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
sr_load = ["B009","B010","B011","B012","B013","B014"];     % 負荷を増やす母線
n_bus = numel(net.a_Bus);


%% CPF traces the nose curve
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));
lambda = res.rv_lambda;

% 結果クラスも flag と output を持つ
assert(isa(res, "ResultCPF") && isa(res, "ResultBase"))
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
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));
assert(isequal(res.sv_bus, string(net.a_Bus(:))))
assert(isequal(size(res.cm_Vbus), [n_bus, numel(res.rv_lambda)]))

% 出発点は initialize で求めた平衡点
assert(norm(res.cm_Vbus(:,1) - net.cv_Vequilibrium) < 1e-6)

% ノーズ点では負荷母線の電圧が下がっている
[~, idx] = ismember(sr_load, res.sv_bus);
V_abs = abs(res.cm_Vbus);
assert(all(V_abs(idx, res.r_noseStep) < V_abs(idx, 1)))
tab = res.tab_nose;
assert(isequal(string(tab.Properties.RowNames), res.sv_bus) && norm(tab.V - V_abs(:, res.r_noseStep)) < 1e-12)

% 全変数のベクトル (v3 の x_sol / x_prd): 母線ごとに [|V|; ∠V]、最終行が λ
assert(size(res.rm_x,1) == 2*n_bus + 1 && isequal(res.rm_x(end,:), res.rv_lambda))
assert(norm(res.rm_x(1:2:2*n_bus,:) - V_abs) < 1e-12)
assert(isequal(size(res.rm_xPredicted), size(res.rm_x)) && all(isnan(res.rm_xPredicted(:,1))))

% 設定と系統の参照
assert(res.s_solver == "SolverCPF" && res.a_PowerNetwork == net && res.r_elapsed >= 0)
assert(isequal(res.options.LoadBus, sr_load) && res.options.MaxIterations == net.solver_CPF.MaxIterations)


%% Name-Value options override solver defaults for one call only
% このセクションは net.solver_CPF を書き換えるので専用の系統を使う
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
solver = net.solver_CPF;
sct_before = solver.get_options();

% MaxIteration=3 ではノーズに届かない
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow( ...
    LoadBus=sr_load, MaxIteration=3, StepSize=0.4, ArcLength=2e-3, Tolerance=1e-6));
assert(~flag && ~res.l_success && numel(res.rv_lambda) == 4 && contains(output.message, "MaxIteration"))
assert(res.options.MaxIterations == 3 && res.options.StepSize == 0.4 && res.options.ArcLength == 2e-3 && res.options.Tolerance == 1e-6)
% 実効設定は get_options で確認できる (InitialLambda は出発点の λ)
sct_opt = solver.get_options({"InitialLambda", 0.1, "UseInternalState", true});
assert(sct_opt.InitialLambda == 0.1 && sct_opt.UseInternalState && sct_opt.MaxIterations == solver.MaxIterations)
% Verbose=true は各ステップの λ を表示する (名前の大文字小文字は区別しない)
s_log = evalc("net.calculate_continuation_powerflow(loadbus=sr_load, maxiteration=2, verbose=true);");
assert(count(s_log, "CPF step") == 2)

% 保存されている既定値は変わらない
assert(isequal(sct_before, solver.get_options()) && net.solver_CPF == solver && isempty(solver.LoadBus))

% 既定値を変えると以後の呼び出しすべてに効く
net.solver_CPF.LoadBus = sr_load;
net.solver_CPF.MaxIterations = 2;
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow());
assert(isequal(res.options.LoadBus, sr_load) && numel(res.rv_lambda) == 3)


%% Failed preconditions and unknown options stop with an error
% 負荷母線の指定がない / 系統にない母線
assert(error_id(@() net.calculate_continuation_powerflow()) == "GUILDA:SolverCPF:EmptyLoadBus")
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus="B099")) == "GUILDA:SolverCPF:UnknownLoadBus")
% initialize 前は平衡点がない (9 母線系統は作成時に initialize しない)
net2 = DebugScript.helper.build_9bus();
assert(error_id(@() net2.calculate_continuation_powerflow(LoadBus="B005")) == "GUILDA:SolverCPF:NoEquilibrium")

% 未知のオプション (v3 の名前も受け付けない)
try
    DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, CPFMaxIter=10));
    error("DebugScript:noError", "未知のオプションでエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:resolve_options:UnknownName", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "CPFMaxIter") && contains(ME.message, "LoadBus, MaxIteration, Tolerance"))
end
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Method="x")) == "GUILDA:resolve_options:UnknownName")
% 値の検証
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=sr_load, StepSize=-1)) ~= "")
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=sr_load, MaxIteration=1.5)) ~= "")
assert(error_id(@() net.calculate_continuation_powerflow("LoadBus")) == "GUILDA:resolve_options:InvalidPairs")

% initialize 後に編集した系統は平衡点が古い (共通設定の系統は変えない)
net3 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net3.initialize);
evalc("net3.a_Bus{2}.l_isSlack = true;");
assert(DebugScript.helper.is_stale(net3))
assert(error_id(@() net3.calculate_continuation_powerflow(LoadBus=sr_load)) == "GUILDA:SolverCPF:Stale")


%% Limits "none" keeps the path of the continuation power flow
% 既定は GUILDA.setting の "none" (制約を課さない)
assert(GUILDA.config("ContinuationPowerFlow", "Limits") == "none" && net.solver_CPF.Limits == "none")
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=["B009","B014"]));
assert(numel(res.rv_lambda) == 362 && res.options.Limits == "none")
assert(height(res.tab_switch) == 0 && height(res.tab_stop) == 0)
assert(isequal(res.tab_switch.Properties.VariableNames, {'lambda','Step','Bus','Limit','Bound'}))
assert(isequal(res.tab_stop.Properties.VariableNames, {'lambda','Step','Class','Object','Limit','Bound'}))
% 明示した "none" と、Inf の制限だけの "S" (IEEE14 のブランチの Smax はすべて Inf) も同じ経路
% (時間の節約のため最初の 40 ステップで比較)
res2 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=["B009","B014"], Limits="none", MaxIteration=40));
assert(isequaln(res2.rm_x, res.rm_x(:,1:41)) && isequaln(res2.rm_xPredicted, res.rm_xPredicted(:,1:41)))
res3 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=["B009","B014"], Limits="S", MaxIteration=40));
assert(isequaln(res3.rm_x, res2.rm_x) && height(res3.tab_stop) == 0)


%% Limits "Q" switches PV buses to PQ at the Q limits of the generators
res0 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));
[res, flag] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits="Q"));
tab = res.tab_switch;
% 発電機の Q が上限に達した PV 母線から順に PQ になり、ノーズは手前に移る
assert(flag && height(tab) >= 2 && all(tab.Limit == "Qmax") && all(diff(tab.lambda) > 0))
assert(isequal(tab.Bus(1:2), ["B002";"B006"]) && height(res.tab_stop) == 0)
assert(all(abs(res.rv_lambda(tab.Step) - tab.lambda.') < 1e-12))
assert(res.r_lambdaMax < res0.r_lambdaMax && res.rv_lambda(end) < res.r_lambdaMax)
% 切替前の Q は上限以下、切替後は上限に固定され、電圧は設定値から離れる
% (母線 B002 の発電機の Q = 注入 Q - 負荷の Q。B002 は負荷を増やす母線ではない)
Y = net.get_admittance_matrix{res.sv_bus, res.sv_bus};
rv_Q = imag(res.cm_Vbus(2,:) .* conj(Y(2,:) * res.cm_Vbus));
com_load = net.a_Bus{2}.a_Component{cellfun(@(c) ~isnan(c.tab_parameter.powerflow.Q), net.a_Bus{2}.a_Component)};
rv_Qgen = rv_Q - imag(com_load.c_Vequilibrium * conj(com_load.c_Iequilibrium));
i_sw = tab.Step(1);
assert(all(rv_Qgen(1:i_sw-1) <= 0.5 + 1e-5) && max(abs(rv_Qgen(i_sw:end) - 0.5)) < 1e-5)   % 修正子の Tolerance 1e-5
V_abs = abs(res.cm_Vbus(2,:));
assert(max(abs(V_abs(1:i_sw) - 1.045)) < 1e-8 && V_abs(end) < 1.045 - 1e-2)
% 有効な制約の状態はモデルに書き戻さない
assert(net.a_Bus{2}.get_pf_condition().Type == "PV" && ~DebugScript.helper.is_stale(net))
res4 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, MaxIteration=30));
assert(isequaln(res4.rm_x, res0.rm_x(:,1:31)))
% 内部状態を使う計算では PV/PQ の切替はできない
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits="Q", UseInternalState=true)) == "GUILDA:SolverCPF:LimitsInternalState")


%% Limits "V" and "S" stop the path at the first limit reached
% operation を編集するので専用の系統を使う (operation の編集は平衡点を古くしない)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
for i = 1:n_bus
    net.a_Bus{i}.tab_parameter.operation.Vmax = 1.1;   % IEEE14 の B006-B008 は初期点で 1.06 を超える
end
for i = 9:14
    net.a_Bus{i}.tab_parameter.operation.Vmin = 0.95;
end
res0 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));

% "V": 母線電圧が最初に Vmin に達した点 (内挿) で止まる
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits="V"));
tab = res.tab_stop;
assert(flag && height(tab) == 1 && tab.Class == "Bus" && tab.Object == "B014" && tab.Limit == "Vmin" && tab.Bound == 0.95)
assert(tab.Step == numel(res.rv_lambda) && tab.lambda == res.rv_lambda(end) && res.r_lambdaMax == tab.lambda)
assert(abs(abs(res.cm_Vbus(14,end)) - 0.95) < 1e-4 && all(abs(res.cm_Vbus(9:14,1:end-1)) > 0.95, "all"))
assert(tab.lambda < res0.r_lambdaMax && contains(output.message, "Vmin") && height(res.tab_switch) == 0)
% 止まるまでの経路は制約なしと同じ
n = numel(res.rv_lambda) - 1;
assert(max(abs(res.rm_x(:,1:n) - res0.rm_x(:,1:n)), [], "all") < 1e-12)

% "S": ブランチの両端の大きい方の |S| が Smax に達した点で止まる
br = net.a_Branch{1};
[~, iv_end] = ismember(string(br.a_Bus), res0.sv_bus);
f_S = @(r, k) max(abs(r.cm_Vbus(iv_end,k) .* conj(br.get_admittance_matrix() * r.cm_Vbus(iv_end,k))));
r_Smax = f_S(res0, 1) + 0.3;
br.tab_parameter.operation.Smax = r_Smax;
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits="S"));
tab = res.tab_stop;
assert(res.l_success && tab.Class == "Branch" && tab.Object == string(br) && tab.Limit == "Smax" && tab.Bound == r_Smax)
assert(abs(f_S(res, numel(res.rv_lambda)) - r_Smax) < 1e-4 && f_S(res, numel(res.rv_lambda) - 1) < r_Smax)

% "all": Q の切替のあと、最初に達した V または S の制約で止まる
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits="all"));
assert(height(res.tab_switch) >= 1 && height(res.tab_stop) == 1 && all(res.tab_switch.lambda < res.tab_stop.lambda))
res2 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits=["S","V","Q"]));
assert(isequaln(res2.rm_x, res.rm_x))

% 初期点で制約を超えている (IEEE14 の元のデータ: B006 の設定電圧 1.07 > Vmax 1.06) と初期点で止まる
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
[res, flag] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits="V"));
assert(~flag && numel(res.rv_lambda) == 1 && res.tab_stop.Step == 1 && res.tab_stop.Limit == "Vmax")


%% Limits option values are checked
solver = net.solver_CPF;
% string 配列・char・cellstr を受け付け、string の行ベクトルとして保持
assert(isequal(solver.get_options({"Limits", 'Q'}).Limits, "Q"))
assert(isequal(solver.get_options({"Limits", {'V','S'}}).Limits, ["V","S"]))
assert(isequal(solver.get_options({"Limits", "all"}).Limits, "all") && solver.Limits == "none")
% 不正な値: 未知の種類、重複、"all"/"none" と他の組み合わせ、空
c_bad = {["Q","X"], "q", ["Q","Q"], ["all","Q"], ["none","V"], strings(1,0), 1};
for k = 1:numel(c_bad)
    try
        solver.get_options({"Limits", c_bad{k}});
        error("DebugScript:noError", "不正な Limits でエラーにならない")
    catch ME
        assert(contains(ME.message, "Limits of the continuation power flow"), ME.message)
    end
end
% 直接設定した保存値も実行時に検証する
net.solver_CPF.Limits = "bad";
assert(error_id(@() net.calculate_continuation_powerflow(LoadBus=sr_load)) ~= "")
net.solver_CPF.Limits = ["Q","V"];
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));
assert(isequal(res.options.Limits, ["Q","V"]) && height(res.tab_stop) == 1)


%% Plot and Export of the result
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));

% Plot: 既定は負荷母線の PV 曲線
ax = res.Plot(Parent=figure("Visible","off"));
c_fig = onCleanup(@() close(ancestor(ax, "figure")));
assert(isa(ax, "matlab.graphics.axis.Axes") && numel(findobj(ax, "Type", "line")) == numel(sr_load))
ax2 = res.Plot(Bus="all", Parent=figure("Visible","off"));
c_fig2 = onCleanup(@() close(ancestor(ax2, "figure")));
assert(numel(findobj(ax2, "Type", "line")) == n_bus)
assert(error_id(@() res.Plot(Bus="B099", Parent=figure("Visible","off"))) == "GUILDA:ResultCPF:UnknownBus")
close(findall(groot, "Type", "figure", "Visible", "off"))
% Plot=true は計算後に result.Plot を呼ぶ
a_before = findall(groot, "Type", "figure");
DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, MaxIteration=2, Plot=true));
a_after = findall(groot, "Type", "figure");
a_new   = a_after(~ismember(a_after, a_before));
assert(numel(a_new) == 1)
close(a_new)

% Export: 経路の表 (lambda, V_<bus>, Varg_<bus>)
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
f_csv = res.Export(fullfile(s_dir, "cpf.csv"));
tab = readtable(f_csv, "VariableNamingRule", "preserve");
assert(height(tab) == numel(res.rv_lambda) && width(tab) == 1 + 2*n_bus)
assert(max(abs(tab.lambda - res.rv_lambda(:))) < 1e-12 && max(abs(tab.V_B009 - abs(res.cm_Vbus(9,:)).')) < 1e-12)
% Export=filename は計算後に result.Export を呼ぶ
DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, MaxIteration=2, Export=fullfile(s_dir, "nv.csv")));
assert(isfile(fullfile(s_dir, "nv.csv")))
assert(error_id(@() res.Export(fullfile(s_dir, "cpf.mat"))) == "GUILDA:ResultCPF:ExportFormat")


%% COMPAT v3 Continuation_Power_Flow and SolverCPF constructor
% 旧入口 Continuation_Power_Flow(net, opt) は警告して v3 の使い方を保つ
clear Deprecated
lastwarn("");
opt = struct("CPFBus", sr_load, "CPFMaxIter", 500);
cpf = DebugScript.helper.quiet(@() Continuation_Power_Flow(net, opt));
id = DebugScript.helper.msg_id();
assert(string(id) == "GUILDA:Deprecated:ContinuationPowerFlowFunction")
assert(isa(cpf, "ContinuationPowerFlowV3") && isequal(cpf.CPFBus(:)', sr_load))
[sol, sol_pred] = DebugScript.helper.quiet(@() cpf.solve);
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load));
assert(isequal(sol, cpf.CPF_Result.x_sol) && isequaln(sol_pred, cpf.CPF_Result.x_prd))
assert(norm(sol - res.rm_x) < 1e-12 && isa(cpf.CPF_Result.result, "ResultCPF"))
assert(isempty(net.solver_CPF.LoadBus))      % 既定値は変わらない

% 旧コンストラクタ SolverCPF(net, ...) は v4 の呼び方を示すエラー
assert(error_id(@() SolverCPF(net, "CPFBus", sr_load)) == "GUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor")
assert(isa(SolverCPF(), "SolverCPF"))


% ---- local functions ----
function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        evalc("fcn();");
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
        if id == ""
            id = "(no id)";
        end
    end
end
