% F2 潮流計算 (calculate_powerflow)
%
% 9母線系統 (旧 Task1/Task2) と IEEE14 母線系統で潮流計算を行い、
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
[tab, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow);

% 収束フラグは正、出力は fsolve の output 構造体
assert(flag > 0, "潮流計算が収束していない: flag = " + flag)
assert(isstruct(output) && isfield(output,"message"))

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
[tab, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
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
[tab, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
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
[tab, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
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
[tab, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
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


%% Infeasible case reports non-convergence
% Task1 の送電線既定値 (X = 1 pu) では負荷 3 pu を送れず、潮流解が存在しない
net = DebugScript.helper.build_9bus("Feasible", false);
w = warning("off"); c = onCleanup(@() warning(w));
[~, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow);

% 収束しなかったことがフラグで分かる
assert(flag <= 0, "解のない系統で収束フラグが立っている")
assert(isfield(output,"message"))


%% Dynamic mode converges
% "dynamic" は母線電圧を仮想的なダイナミクスで動かして潮流解へ収束させる方式
net = DebugScript.helper.build_ieee14();
[tab, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow("dynamic", "export", false));
assert(logical(flag), "dynamic モードが収束していない: " + output.message)
assert(istable(tab) && height(tab) == numel(net.a_Bus))


%% Dynamic mode reaches the algebraic solution
% dynamic モードでも代数方程式の解 (指定電圧を含む) と同じ解になるべき
net = DebugScript.helper.build_ieee14();
tab_alg = DebugScript.helper.quiet(@() net.calculate_powerflow("algebraic"));
tab_dyn = DebugScript.helper.quiet(@() net.calculate_powerflow("dynamic", "export", false));

% PV 母線の電圧は指定値
lv_PV = string(cellfun(@(b) b.str_bustype, net.a_Bus, "UniformOutput", false)) == "PV";
V_set = cellfun(@(b) b.tab_parameter.powerflow.V, net.a_Bus);
assert(max(abs(tab_dyn.V(lv_PV) - V_set(lv_PV))) < 1e-4, "dynamic モードで PV 母線の電圧指定が守られていない")
assert(max(abs(tab_dyn.Vphasor - tab_alg.Vphasor)) < 1e-3)


%% Dynamic mode exports convergence history as JSON
% export=true のとき GUILDA.pwd に JSON (計算過程) を書き出す
net = DebugScript.helper.build_ieee14();
filename = "DebugScript_test_F2_" + string(feature("getpid")) + ".json";
filepath = fullfile(GUILDA.pwd, filename);
c = onCleanup(@() delete(filepath));
DebugScript.helper.quiet(@() net.calculate_powerflow("dynamic", "export", true, "filename", filename));

assert(isfile(filepath))
data = jsondecode(fileread(filepath));
assert(numel(data.nodes) == numel(net.a_Bus))
