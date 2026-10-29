% F2 潮流計算 (calculate_powerflow)
%
% 9母線系統 (旧 Task1/Task2) と IEEE14 母線系統で潮流計算を行い、
%   - v4 の呼び出し形式 [result, flag, output] と結果クラス PowerFlowResult
%   - Name-Value による一時的な設定の上書き (net.solver_PF は変わらない)
%   - v3 の呼び出し形式 (位置引数 mode, export/filename) の互換
%   - 収束フラグ / 出力の形式
%   - スラック母線の自動選択と母線種別 (slack / PV / PQ)
%   - 指定値 (V, P, Q) が解で守られていること
%   - 電力の収支 (注入電力の合計 = 送電損失)
% を確認する。
%
% 実行: runtests("DebugScript.test_F2_powerflow")  または  DebugScript.run_all("Features","F2")

% 共通設定 (各テストの前に毎回実行される)
tol = 1e-6;


%% Algebraic power flow converges on 9-bus system
% Task2 と同じ潮流設定の 9 母線系統
net = DebugScript.helper.build_9bus();

% 潮流計算 (既定は "algebraic" = fsolve による代数方程式の求解)
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow);
tab = res.tab_bus;

% 収束フラグは正、出力は fsolve の output 構造体
assert(flag > 0, "潮流計算が収束していない: flag = " + flag)
assert(isstruct(output) && isfield(output,"message"))

% 結果クラスも flag と output を持つ
assert(isa(res, "PowerFlowResult") && isa(res, "AnalysisResult"))
assert(isequal(res.flag, flag) && isequal(res.output, output) && res.l_success)

% 結果は母線ごとの table (行名 = 母線タグ)
assert(istable(tab))
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)))
assert(all(ismember(["Varg","V","P","Q","Vphasor","Iphasor"], tab.Properties.VariableNames)))


%% Slack bus is selected automatically when none is set
net = DebugScript.helper.build_9bus();
assert(~any(cellfun(@(b) b.l_isSlack, net.a_Bus)), "初期状態ではスラック母線は未指定")

DebugScript.helper.quiet(@() net.calculate_powerflow);

% 先頭の母線がスラックになる
assert(net.a_Bus{1}.l_isSlack)
assert(sum(cellfun(@(b) b.l_isSlack, net.a_Bus)) == 1)


%% Slack bus can be chosen explicitly
net = DebugScript.helper.build_9bus();

% B002 をスラックに指定すると、他の母線のスラック指定は外れる
evalc("net.a_Bus{1}.l_isSlack = true;");     % evalc: 設定時の INFO 表示を抑制
evalc("net.a_Bus{2}.l_isSlack = true;");
assert(net.a_Bus{2}.l_isSlack && ~net.a_Bus{1}.l_isSlack)
assert(net.a_Bus{2}.str_bustype == "slack")

% スラック母線の電圧位相 (Varg) は指定値が使われる
% B001 は PV 母線になるので発電機出力 P を与える (Task2 では NaN)
net.a_Bus{2}.tab_parameter.powerflow.Varg = 0;
net.a_Bus{1}.a_Component{1}.tab_parameter.powerflow.P = 0.7;
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow); tab = res.tab_bus;
assert(flag > 0)
assert(abs(tab{"B002","Varg"}) < tol)
assert(abs(tab{"B002","V"} - 1.00) < tol)


%% Switching the slack bus leaves exactly one
% スラック母線は系統に高々1つ。母線は兄弟の母線を書き換えず、変更を系統に通知し、系統が他を外す
n_slack = @(net) sum(cellfun(@(b) b.l_isSlack, net.a_Bus));
net = DebugScript.helper.build_9bus();
net.a_Bus{1}.a_Component{1}.tab_parameter.powerflow.P = 0.7;    % B001 が PV 母線でも解けるように
net.a_Bus{2}.tab_parameter.powerflow.Varg = 0;                   % スラックにする母線の位相
net.a_Bus{3}.tab_parameter.powerflow.Varg = 0;

% initialize 前 (編集ログが記録されない状態) でも1つだけ
evalc("net.a_Bus{1}.l_isSlack = true;");
evalc("net.a_Bus{3}.l_isSlack = true;");
assert(n_slack(net) == 1 && net.a_Bus{3}.l_isSlack)

% initialize 後の切り替えも1つだけで、スラックの編集として記録され平衡点が古くなる
DebugScript.helper.quiet(@() net.initialize);
assert(n_slack(net) == 1 && net.a_Bus{3}.l_isSlack)
evalc("net.a_Bus{2}.l_isSlack = true;");
assert(n_slack(net) == 1 && net.a_Bus{2}.l_isSlack)
assert(net.l_staleEquilibrium && net.tab_editLog.tag(end) == "Slack")
assert(any(contains(net.tab_editLog.log, "slack bus -> B002")))

% 同じ値の再設定は何も記録しない
n_log = height(net.tab_editLog);
evalc("net.a_Bus{2}.l_isSlack = true;");
assert(height(net.tab_editLog) == n_log && n_slack(net) == 1)

% 切り替えた系統で潮流計算でき、指定した母線がスラックとして使われる
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(flag > 0 && n_slack(net) == 1 && net.a_Bus{2}.str_bustype == "slack")

% スラック指定を外すこともできる (外すとスラックは0、潮流計算で先頭の母線が選ばれる)
evalc("net.a_Bus{2}.l_isSlack = false;");
assert(n_slack(net) == 0)
DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(n_slack(net) == 1 && net.a_Bus{1}.l_isSlack)

% 別の系統の母線には影響しない
net2 = DebugScript.helper.build_9bus();
evalc("net2.a_Bus{2}.l_isSlack = true;");
assert(n_slack(net) == 1 && net.a_Bus{1}.l_isSlack && n_slack(net2) == 1)


%% Bus types follow powerflow settings
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.calculate_powerflow);

% 発電機母線: Q が NaN → PV、負荷母線: P,Q 指定 → PQ、機器なし母線: P=Q=0 の PQ
str_type = string(cellfun(@(b) b.str_bustype, net.a_Bus, "UniformOutput", false));
assert(isequal(str_type(:)', ["slack","PV","PV","PQ","PQ","PQ","PQ","PQ","PQ"]))

% get_pf_set は母線ごとの潮流条件を返す
tab_set = net.a_Bus{2}.get_pf_set;
assert(tab_set.Type == "PV" && tab_set.P == 1.0 && tab_set.V == 1.00)


%% Specified V P Q are honored by the solution
net = DebugScript.helper.build_9bus();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow); tab = res.tab_bus;
assert(flag > 0)

% slack: V, Varg
assert(abs(tab{"B001","V"}    - 1.05) < tol)
assert(abs(tab{"B001","Varg"} - 0.00) < tol)
% PV: V, P
assert(abs(tab{"B002","V"} - 1.00) < tol && abs(tab{"B002","P"} - 1.0) < tol)
assert(abs(tab{"B003","V"} - 1.02) < tol && abs(tab{"B003","P"} - 1.3) < tol)
% PQ (負荷): P, Q
assert(norm(tab{"B005",["P","Q"]} - [-1.0,-0.1]) < tol)
assert(norm(tab{"B006",["P","Q"]} - [-0.8,-0.2]) < tol)
assert(norm(tab{"B008",["P","Q"]} - [-1.2,-0.4]) < tol)
% 機器のない母線は P = Q = 0
assert(norm(tab{["B004","B007","B009"],["P","Q"]}) < tol)


%% Bus power balance equals branch losses
net = DebugScript.helper.build_9bus();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow); tab = res.tab_bus;
assert(flag > 0)

% 全母線の注入電力の合計 = 送電線 (とシャント) の損失
S_inject = sum(tab.P) + 1j*sum(tab.Q);
S_loss   = DebugScript.helper.branch_losses(net, tab.Vphasor);
assert(abs(S_inject - S_loss) < 1e-8)

% 抵抗のある系統なので有効電力損失は正
assert(real(S_loss) > 0)

% 電流は I = Y V、電力は S = V conj(I)
Y = net.get_admittance_matrix.Variables;
assert(norm(Y*tab.Vphasor - tab.Iphasor) < 1e-8)
assert(norm(tab.Vphasor.*conj(tab.Iphasor) - (tab.P + 1j*tab.Q)) < 1e-8)


%% Power flow on IEEE14 honors generator settings
net = DebugScript.helper.build_ieee14();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow); tab = res.tab_bus;
assert(flag > 0)

% 各母線の指定値が守られている
for i = 1:numel(net.a_Bus)
    s = net.a_Bus{i}.get_pf_set;
    switch s.Type
        case "slack"; assert(abs(tab.V(i)-s.V) < tol && abs(tab.Varg(i)-s.Varg) < tol)
        case "PV";    assert(abs(tab.V(i)-s.V) < tol && abs(tab.P(i)-s.P) < tol)
        case "PQ";    assert(abs(tab.P(i)-s.P) < tol && abs(tab.Q(i)-s.Q) < tol)
    end
end
assert(abs(sum(tab.P)+1j*sum(tab.Q) - DebugScript.helper.branch_losses(net, tab.Vphasor)) < 1e-8)


%% Power flow on IEEE14 matches MATPOWER case14
% network.IEEE14bus は MATPOWER の case14 と同じアドミタンス行列・負荷・発電機設定。
% 潮流解は runpf(case14) と一致する: 発電機の Q = [-16.55, 43.56, 25.08, 12.73, 17.62] MVAr、
% B001 の P = 232.39 MW。case14 の母線データの Vm, Va (IEEE の元データの解、小数 3 桁 / 0.01 度)
% とは 0.002 pu, 0.02 度以内で一致する。
net = DebugScript.helper.build_ieee14();
mpc = DebugScript.helper.case14_data();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow); tab = res.tab_bus;
assert(flag > 0)
assert(max(abs(tab.V - mpc.bus(:,8))) < 2e-3)
assert(max(abs(tab.Varg*180/pi - mpc.bus(:,9))) < 2e-2)
i_gen = mpc.gen(:,1);
Qg = 100*tab.Q(i_gen) + mpc.bus(i_gen,4);
assert(max(abs(Qg - [-16.55; 43.56; 25.08; 12.73; 17.62])) < 0.01, mat2str(Qg.', 6))
assert(abs(100*tab.P(1) + mpc.bus(1,3) - 232.39) < 0.01)


%% Infeasible case reports non-convergence
% Task1 の送電線既定値 (X = 1 pu) では負荷 3 pu を送れず、潮流解が存在しない
net = DebugScript.helper.build_9bus("Feasible", false);
w = warning("off"); c = onCleanup(@() warning(w));
[~, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow);

% 収束しなかったことがフラグで分かる
assert(flag <= 0, "解のない系統で収束フラグが立っている")
assert(isfield(output,"message"))


%% Dynamic method converges
% "dynamic" は母線電圧を仮想的なダイナミクスで動かして潮流解へ収束させる方式
net = DebugScript.helper.build_ieee14();
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="dynamic"));
assert(logical(flag), "dynamic が収束していない: " + output.message)
assert(istable(res.tab_bus) && height(res.tab_bus) == numel(net.a_Bus))
% 経過は時刻ごとの母線電圧として結果に残る (ソルバーには書き戻さない)
assert(size(res.cm_Vhistory,1) == numel(net.a_Bus) && size(res.cm_Vhistory,2) == numel(res.rv_step))
assert(res.rv_step(1) == 0 && all(diff(res.rv_step) > 0))
assert(norm(res.cm_Vhistory(:,end) - res.tab_bus.Vphasor) < 1e-12)
assert(~isprop(net.solver_PF, "rm_response"))


%% Dynamic method reaches the algebraic solution
% dynamic でも代数方程式の解 (指定電圧を含む) と同じ解になるべき
net = DebugScript.helper.build_ieee14();
tab_alg = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="algebraic")).tab_bus;
tab_dyn = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="dynamic")).tab_bus;

% PV 母線の電圧は指定値
lv_PV = string(cellfun(@(b) b.str_bustype, net.a_Bus, "UniformOutput", false)) == "PV";
V_set = cellfun(@(b) b.tab_parameter.powerflow.V, net.a_Bus);
assert(max(abs(tab_dyn.V(lv_PV) - V_set(lv_PV))) < 1e-4, "dynamic で PV 母線の電圧指定が守られていない")
assert(max(abs(tab_dyn.Vphasor - tab_alg.Vphasor)) < 1e-3)

% Tolerance を小さくすると代数解に近づく
tab_dyn = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="dynamic", Tolerance=1e-9)).tab_bus;
assert(max(abs(tab_dyn.Vphasor - tab_alg.Vphasor)) < 1e-6)


%% Result holds bus and branch values and the settings used
net = DebugScript.helper.build_9bus();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(flag > 0)
assert(res.str_solver == "PowerFlowCalculation" && res.a_PowerNetwork == net && res.r_elapsed >= 0)
assert(res.options.Method == "algebraic" && isequal(res.options.dynamic, net.solver_PF.dynamic))
% 反復ごとの母線電圧 (最後が解)
assert(size(res.cm_Vhistory,1) == numel(net.a_Bus) && isequal(res.rv_step, 0:size(res.cm_Vhistory,2)-1))
assert(norm(res.cm_Vhistory(:,end) - res.tab_bus.Vphasor) < 1e-12)

% 枝の潮流: 行 = 枝, from = a_Bus{1}, to = a_Bus{2}
tab_br = res.tab_branch;
assert(isequal(string(tab_br.Properties.RowNames), string(cellfun(@string, net.a_Branch, "UniformOutput", false))))
assert(all(ismember(["Pfrom","Qfrom","Pto","Qto","Ifrom","Ito","Ploss","Qloss"], tab_br.Properties.VariableNames)))
br = net.a_Branch{4};
V_ft = res.tab_bus{string(br.a_Bus), "Vphasor"};
I_ft = br.get_admittance_matrix() * V_ft;
assert(norm([tab_br{4,"Ifrom"}; tab_br{4,"Ito"}] - I_ft) < 1e-12)
assert(abs(tab_br{4,"Pfrom"} - real(V_ft(1)*conj(I_ft(1)))) < 1e-12)
% 枝の損失の合計 = 全母線の注入電力の合計 (この系統に母線シャントはない)
S_inject = sum(res.tab_bus.P) + 1j*sum(res.tab_bus.Q);
assert(abs(sum(tab_br.Ploss) + 1j*sum(tab_br.Qloss) - S_inject) < 1e-8)
% 各母線: 注入 = 接続する枝へ流れ込む電力の合計
str_from = string(cellfun(@(b) string(b.a_Bus{1}), net.a_Branch, "UniformOutput", false));
str_to   = string(cellfun(@(b) string(b.a_Bus{2}), net.a_Branch, "UniformOutput", false));
for str_bus = string(net.a_Bus)'
    S_br = sum(tab_br.Pfrom(str_from == str_bus) + 1j*tab_br.Qfrom(str_from == str_bus)) ...
         + sum(tab_br.Pto(str_to == str_bus)     + 1j*tab_br.Qto(str_to == str_bus));
    assert(abs(S_br - res.tab_bus{str_bus,"P"} - 1j*res.tab_bus{str_bus,"Q"}) < 1e-8)
end


%% Name-Value options override solver defaults for one call only
net = DebugScript.helper.build_9bus();
solver = net.solver_PF;
s_before = struct("Method", solver.Method, "MaxIterations", solver.MaxIterations, ...
                  "Display", solver.Display, "Tolerance", solver.Tolerance);

% MaxIteration=1 では収束しない (fsolve の exitflag = 0)
w = warning("off"); c = onCleanup(@() warning(w));
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow(MaxIteration=1, Tolerance=1e-10));
assert(flag == 0 && ~res.l_success)
assert(res.options.MaxIterations == 1 && res.options.Tolerance == 1e-10)
% Verbose=true は fsolve の表示 ("iter")
str_log = evalc("res = net.calculate_powerflow(Verbose=true);");
assert(res.options.Display == "iter" && strlength(str_log) > strlength(evalc("net.calculate_powerflow();")))
res = DebugScript.helper.quiet(@() net.calculate_powerflow(verbose=false, method="dynamic"));   % 名前の大文字小文字は区別しない
assert(res.options.Display == "none" && res.options.Method == "dynamic")

% 保存されている既定値は変わらない
s_after = struct("Method", solver.Method, "MaxIterations", solver.MaxIterations, ...
                 "Display", solver.Display, "Tolerance", solver.Tolerance);
assert(isequal(s_before, s_after) && net.solver_PF == solver)

% 既定値を変えると以後の呼び出しすべてに効く
net.solver_PF.Method = "dynamic";
res = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(res.options.Method == "dynamic" && islogical(res.flag))


%% Unknown or invalid options stop with an error
net = DebugScript.helper.build_9bus();
try
    DebugScript.helper.quiet(@() net.calculate_powerflow(Tolerence=1e-8));
    error("DebugScript:noError", "未知のオプションでエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:resolve_options:UnknownName", ME.identifier)
    assert(contains(ME.message, "Tolerence") && contains(ME.message, "Method, Tolerance, MaxIteration, Verbose"))
end
% 共通名以外 (ソルバー固有の名前) も受け付けない
assert(error_id(@() net.calculate_powerflow("MaxIterations", 5)) == "GUILDA:resolve_options:UnknownName")
% 値の検証
assert(error_id(@() net.calculate_powerflow(Method="newton")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() net.calculate_powerflow(MaxIteration=-1)) ~= "")
assert(error_id(@() net.calculate_powerflow(Plot="yes")) ~= "")
% Name-Value の組になっていない
assert(error_id(@() net.calculate_powerflow("Method")) == "GUILDA:resolve_options:InvalidPairs")


%% Plot and Export of the result
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow);

% Plot: 電圧の大きさと位相の棒グラフ
t = res.Plot(Parent=figure("Visible","off"));
c_fig = onCleanup(@() close(ancestor(t, "figure")));
assert(isa(t, "matlab.graphics.layout.TiledChartLayout") && numel(t.Children) == 2)
% Plot=true は計算後に result.Plot を呼ぶ
a_before = findall(groot, "Type", "figure");
DebugScript.helper.quiet(@() net.calculate_powerflow(Plot=true));
a_after = findall(groot, "Type", "figure");
a_new   = a_after(~ismember(a_after, a_before));
assert(numel(a_new) == 1)
close(a_new)

% Export: 拡張子で形式が決まる。CSV は母線または枝の表
str_dir = tempname; mkdir(str_dir); c_dir = onCleanup(@() rmdir(str_dir, "s"));
f_bus = res.Export(fullfile(str_dir, "bus.csv"));
tab = readtable(f_bus, "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)) && max(abs(tab.V - res.tab_bus.V)) < 1e-12)
res.Export(fullfile(str_dir, "branch.csv"), Table="branch");
tab = readtable(fullfile(str_dir, "branch.csv"), "ReadRowNames", true);
assert(height(tab) == numel(net.a_Branch) && max(abs(tab.Ploss - res.tab_branch.Ploss)) < 1e-12)
% Export=filename は計算後に result.Export を呼ぶ
DebugScript.helper.quiet(@() net.calculate_powerflow(Export=fullfile(str_dir, "nv.csv")));
assert(isfile(fullfile(str_dir, "nv.csv")))
% 未対応の拡張子
assert(error_id(@() res.Export(fullfile(str_dir, "bus.mat"))) == "GUILDA:PowerFlowResult:ExportFormat")


%% Dynamic method exports convergence history as JSON
% .json は計算過程 (GridSpring で可視化できる形式)
net = DebugScript.helper.build_ieee14();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="dynamic"));
filepath = fullfile(tempdir, "DebugScript_test_F2_" + string(feature("getpid")) + ".json");
c = onCleanup(@() delete(filepath));
DebugScript.helper.quiet(@() res.Export(filepath));

assert(isfile(filepath))
data = jsondecode(fileread(filepath));
assert(numel(data.nodes) == numel(net.a_Bus))
assert(numel(data.nodes(2).Vabs) == numel(res.rv_step))
% 結果だけ (系統なし) では JSON を書けない
res_empty = PowerFlowResult();
assert(error_id(@() res_empty.Export(filepath)) == "GUILDA:PowerFlowResult:NoNetwork")


%% COMPAT v3 positional mode and export options
% 旧形式 calculate_powerflow(mode, "export", l, "filename", f) は警告して v4 に読み替える
net = DebugScript.helper.build_ieee14();
clear Deprecated
lastwarn("");
w = warning("off", "GUILDA:Deprecated:CalculatePowerflowMode"); c = onCleanup(@() warning(w));
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow("dynamic", "export", false));
assert(isa(res, "PowerFlowResult") && logical(flag) && res.options.Method == "dynamic")
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:CalculatePowerflowExport")
assert(net.solver_PF.Method == "algebraic")       % 既定値は変わらない
warning(w);

% 位置引数の mode だけ
clear Deprecated
lastwarn("");
res = DebugScript.helper.quiet(@() net.calculate_powerflow("algebraic"));
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:CalculatePowerflowMode" && res.options.Method == "algebraic")

% export=true の JSON は v3 と同じく GUILDA.pwd に書く
filename = "DebugScript_test_F2_" + string(feature("getpid")) + ".json";
filepath = fullfile(GUILDA.pwd, filename);
c = onCleanup(@() delete(filepath));
w = warning("off", "GUILDA:Deprecated:CalculatePowerflowMode");
warning("off", "GUILDA:Deprecated:CalculatePowerflowExport");
DebugScript.helper.quiet(@() net.calculate_powerflow("dynamic", "export", true, "filename", filename));
warning(w);
assert(isfile(filepath))
data = jsondecode(fileread(filepath));
assert(numel(data.nodes) == numel(net.a_Bus))

% v4 の呼び出しは互換フックを素通りする
assert(isequal(v3_powerflow_args({"Method", "dynamic", "Export", true}), {"Method", "dynamic", "Export", true}))
assert(isequal(v3_powerflow_args({}), {}))


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
