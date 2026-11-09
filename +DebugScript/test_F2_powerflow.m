% F2 潮流計算 (calculate_powerflow)
%
% 9母線系統 (旧 Task1/Task2) と IEEE14 母線系統で潮流計算を行い、
%   - v4 の呼び出し形式 [result, flag, output] と結果クラス ResultPF
%   - Name-Value による一時的な設定の上書き (GUILDA.setting は変わらない)
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

% 潮流計算 (既定は "newton" = ニュートン・ラフソン法による電力方程式の求解)
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow);
tab = res.tab_bus;

% 収束フラグは正、出力は fsolve の output 構造体
assert(flag > 0, "潮流計算が収束していない: flag = " + flag)
assert(isstruct(output) && isfield(output,"message"))

% 結果クラスも flag と output を持つ
assert(isa(res, "ResultPF") && isa(res, "ResultBase"))
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
assert(net.a_Bus{2}.s_bustype == "slack")

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

% initialize 前 (未初期化の状態) でも1つだけ
evalc("net.a_Bus{1}.l_isSlack = true;");
evalc("net.a_Bus{3}.l_isSlack = true;");
assert(n_slack(net) == 1 && net.a_Bus{3}.l_isSlack)

% initialize 後の切り替えも1つだけで、スラックの編集として潮流が古くなる
DebugScript.helper.quiet(@() net.initialize);
assert(n_slack(net) == 1 && net.a_Bus{3}.l_isSlack)
evalc("net.a_Bus{2}.l_isSlack = true;");
assert(n_slack(net) == 1 && net.a_Bus{2}.l_isSlack)
assert(DebugScript.helper.is_stale(net) && any(contains(net.sct_stale.powerflow, "slack bus -> B002")))

% 同じ値の再設定は何も記録しない
sv_log = DebugScript.helper.stale(net);
evalc("net.a_Bus{2}.l_isSlack = true;");
assert(isequal(DebugScript.helper.stale(net), sv_log) && n_slack(net) == 1)

% 切り替えた系統で潮流計算でき、指定した母線がスラックとして使われる
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(flag > 0 && n_slack(net) == 1 && net.a_Bus{2}.s_bustype == "slack")

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
sv_type = string(cellfun(@(b) b.s_bustype, net.a_Bus, "UniformOutput", false));
assert(isequal(sv_type(:)', ["slack","PV","PV","PQ","PQ","PQ","PQ","PQ","PQ"]))

% get_pf_condition は母線ごとの潮流条件を返す
tab_set = net.a_Bus{2}.get_pf_condition;
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
    s = net.a_Bus{i}.get_pf_condition;
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
tab_alg = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="newton")).tab_bus;
tab_dyn = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="dynamic")).tab_bus;

% PV 母線の電圧は指定値
lv_PV = string(cellfun(@(b) b.s_bustype, net.a_Bus, "UniformOutput", false)) == "PV";
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
assert(res.s_solver == "SolverPF" && res.a_PowerNetwork == net && res.r_elapsed >= 0)
assert(res.options.Method == "newton" && res.options.Tolerance == 1e-8 && res.options.MaxIteration == 0)
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
sv_from  = string(cellfun(@(b) string(b.a_Bus{1}), net.a_Branch, "UniformOutput", false));
sv_to    = string(cellfun(@(b) string(b.a_Bus{2}), net.a_Branch, "UniformOutput", false));
for s_bus = string(net.a_Bus)'
    S_br = sum(tab_br.Pfrom(sv_from == s_bus) + 1j*tab_br.Qfrom(sv_from == s_bus)) ...
         + sum(tab_br.Pto(sv_to == s_bus)     + 1j*tab_br.Qto(sv_to == s_bus));
    assert(abs(S_br - res.tab_bus{s_bus,"P"} - 1j*res.tab_bus{s_bus,"Q"}) < 1e-8)
end


%% Name-Value options override the settings for one call only
net = DebugScript.helper.build_9bus();
sct_before = GUILDA.config("PowerFlowCalculation");

% MaxIteration=1 では収束しない (flag = 0)
w = warning("off"); c = onCleanup(@() warning(w));
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow(MaxIteration=1, Tolerance=1e-10, WarmStart=false));
assert(flag == 0 && ~res.l_success)
assert(res.options.MaxIteration == 1 && res.options.Tolerance == 1e-10)
% Verbose=true は反復ごとの表示 ("iter")
s_log = evalc("res = net.calculate_powerflow(Verbose=true, WarmStart=false);");
assert(res.options.Display == "iter" && strlength(s_log) > strlength(evalc("net.calculate_powerflow(WarmStart=false);")))
res = DebugScript.helper.quiet(@() net.calculate_powerflow(verbose=false, method="dynamic"));   % 名前の大文字小文字は区別しない
assert(res.options.Display == "none" && res.options.Method == "dynamic")

% GUILDA.setting は変わらない。ソルバーは数値の設定を持たない
assert(isequal(GUILDA.config("PowerFlowCalculation"), sct_before))
assert(~isprop(net.solver_PF, "Method") && ~isprop(net.solver_PF, "Tolerance") && ~isprop(net.solver_PF, "WhenFailed"))

% GUILDA.setting を変えると以後の呼び出しすべてに効く
c_cfg = DebugScript.helper.user_config("PowerFlowCalculation", struct("Method", "dynamic", "Tolerance", 1e-6));
res = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(res.options.Method == "dynamic" && res.options.Tolerance == 1e-6 && res.l_success)
clear c_cfg
assert(GUILDA.config("PowerFlowCalculation", "Method") == "newton")


%% Warm start starts from the last converged solution
% WarmStart=true は前回の収束解から (反復 0 回)、false はフラットスタート
net = DebugScript.helper.build_ieee14();
[res0, ~, out0] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
[res1, ~, out1] = DebugScript.helper.quiet(@() net.calculate_powerflow());          % 既定 WarmStart=true
assert(out0.iterations > 0 && out1.iterations == 0 && res1.options.WarmStart)
assert(max(abs(res1.tab_bus.Vphasor - res0.tab_bus.Vphasor)) < 1e-8)
[~, ~, out2] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
assert(out2.iterations == out0.iterations)
% フラットスタート: 位相 0、大きさ 1 (PV・スラックは設定値 V、スラックの位相は設定値)
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false, MaxIteration=1, Method="newton"));
cv_V0 = res.cm_Vhistory(:,1);
tab_set = tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus);
lv_PQ = tab_set.Type == "PQ";
assert(all(abs(cv_V0(lv_PQ) - 1) < 1e-15) && max(abs(abs(cv_V0(~lv_PQ)) - tab_set.V(~lv_PQ))) < 1e-15)
% パラメータの編集ではウォームスタートを保持し、方程式は作り直す (解は新しく作った系統と一致)
net.a_Bus{14}.a_Component{1}.tab_parameter.powerflow.P = -0.2;
net.a_Branch{3}.tab_parameter.dynamics.X = 0.21;
net.a_Bus{9}.tab_parameter.dynamics.Bshunt = 0.25;
[res_w, flag, out_w] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1 && out_w.iterations > 0 && out_w.iterations <= out0.iterations)
net2 = DebugScript.helper.build_ieee14();
net2.a_Bus{14}.a_Component{1}.tab_parameter.powerflow.P = -0.2;
net2.a_Branch{3}.tab_parameter.dynamics.X = 0.21;
net2.a_Bus{9}.tab_parameter.dynamics.Bshunt = 0.25;
res_ref = DebugScript.helper.quiet(@() net2.calculate_powerflow(WarmStart=false));
assert(max(abs(res_w.tab_bus.Vphasor - res_ref.tab_bus.Vphasor)) < 1e-8)
% タグの変更ではキャッシュもウォームスタートも保持し、結果の行名は新しいタグ
net.a_Bus{14}.s_tag = "Bnew";
[res_t, ~, out_t] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(out_t.iterations == 0 && string(res_t.tab_bus.Properties.RowNames(14)) == string(net.a_Bus{14}))
% スラック母線の変更でも方程式は作り直す
evalc("net.a_Bus{2}.l_isSlack = true;");
net.a_Bus{1}.a_Component{1}.tab_parameter.powerflow.P = 2.3;
[res_s, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1 && abs(res_s.tab_bus.Varg(2) - net.a_Bus{2}.tab_parameter.powerflow.Varg) < 1e-12)
% トポロジーの編集でウォームスタートを捨てる (フラットスタートと同じ反復回数)
net.remove_branch(string(net.a_Branch{1}));
[res_f, ~, out_f] = DebugScript.helper.quiet(@() net.calculate_powerflow());
[~, ~, out_g] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
assert(out_f.iterations == out_g.iterations && out_f.iterations > 0 && res_f.l_success)
% 収束しなかった解は保存しない。reset_solver で捨てる
w = warning("off"); c = onCleanup(@() warning(w));
DebugScript.helper.quiet(@() net.calculate_powerflow(MaxIteration=1, WarmStart=false));
[~, ~, out_h] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(out_h.iterations == 0)
clear c
net.reset_solver();
[~, ~, out_r] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(out_r.iterations == out_g.iterations)
% 別の系統で同じソルバーを使っても母線はオブジェクトで対応付ける (他の系統の解を使わない)
net3 = DebugScript.helper.build_ieee14();
[~, ~, out3] = DebugScript.helper.quiet(@() net.solver_PF.solve(net3, net.solver_PF.get_options()));
assert(out3.iterations == out0.iterations)


%% Violated operating limits are recorded and not applied
% 潮流計算は operation の制約を課さず、違反を tab_violation に記録するだけ (警告もエラーもなし)
net = DebugScript.helper.build_ieee14();
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
% IEEE14 のデータ自体が違反を含む: B006, B007, B008 の V > Vmax = 1.06、スラックの発電機の Q < Qmin = 0
tab0 = res.tab_violation;
assert(isequal(sort(tab0.Object + ":" + tab0.Limit), sort(["B006:Vmax";"B007:Vmax";"B008:Vmax";"SG1B001:Qmin"])))
assert(isequal(string(res.tab_violation.Properties.VariableNames), ["Class","Object","Limit","Value","Bound","Excess"]))
tab_ref = res.tab_bus;
s_bus = string(net.a_Bus{14});  s_br = string(net.a_Branch{1});  com = net.a_Bus{2}.a_Component{1};
net.a_Bus{14}.tab_parameter.operation.Vmin = 1.05;            % V(B014) は約 1.036
net.a_Branch{1}.tab_parameter.operation.Smax = 1;             % 枝 1 の |S| は 1.5 以上
net.a_Branch{1}.tab_parameter.operation.Vargmax = 0.01;
com.tab_parameter.operation.Qmax = 0.1;                       % 発電機 B002 の Q は約 0.42
lastwarn("");
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1 && isempty(lastwarn()) && max(abs(res.tab_bus.Vphasor - tab_ref.Vphasor)) < 1e-10)
tab = res.tab_violation;
assert(height(tab) == height(tab0) + 4, string(height(tab)))
r = tab(tab.Object == s_bus, :);
assert(r.Class == "Bus" && r.Limit == "Vmin" && abs(r.Value - res.tab_bus{s_bus,"V"}) < 1e-12 && r.Bound == 1.05 && abs(r.Excess - (1.05 - r.Value)) < 1e-12)
r = tab(tab.Object == s_br & tab.Limit == "Smax", :);
S = [res.tab_branch{s_br,"Pfrom"} + 1j*res.tab_branch{s_br,"Qfrom"}, res.tab_branch{s_br,"Pto"} + 1j*res.tab_branch{s_br,"Qto"}];
assert(r.Class == "Branch" && abs(r.Value - max(abs(S))) < 1e-12 && r.Bound == 1)
assert(any(tab.Object == s_br & tab.Limit == "Vargmax"))
r = tab(tab.Object == string(com), :);
Q_other = sum(cellfun(@(c) c.tab_parameter.powerflow.Q, net.a_Bus{2}.a_Component(2:end)));   % 負荷
assert(r.Class == "Component" && r.Limit == "Qmax" && abs(r.Value - (res.tab_bus{string(net.a_Bus{2}),"Q"} - Q_other)) < 1e-12)
% initialize が機器に与える Q と同じ
DebugScript.helper.quiet(@() net.initialize());
c_S = com.a_Bus.c_Vequilibrium * conj(com.c_Iequilibrium);
assert(abs(imag(c_S) - r.Value) < 1e-8)
% 収束しなければ 0 行
w = warning("off"); c = onCleanup(@() warning(w));
res = DebugScript.helper.quiet(@() net.calculate_powerflow(MaxIteration=1, WarmStart=false, Tolerance=1e-14));
assert(~res.l_success && height(res.tab_violation) == 0)


%% Unknown or invalid options stop with an error
net = DebugScript.helper.build_9bus();
try
    DebugScript.helper.quiet(@() net.calculate_powerflow(Tolerence=1e-8));
    error("DebugScript:noError", "未知のオプションでエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:resolve_options:UnknownName", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "Tolerence") && contains(ME.message, "Method, Tolerance, MaxIteration, Verbose, WarmStart"))
end
% 共通名以外 (ソルバー固有の名前) も受け付けない
assert(error_id(@() net.calculate_powerflow("MaxIterations", 5)) == "GUILDA:resolve_options:UnknownName")
% 値の検証
assert(error_id(@() net.calculate_powerflow(Method="algebraic")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() net.calculate_powerflow(MaxIteration=-1)) ~= "")
assert(error_id(@() net.calculate_powerflow(Plot="yes")) ~= "")
assert(error_id(@() net.calculate_powerflow(WarmStart="yes")) ~= "")
assert(error_id(@() net.calculate_powerflow(Tolerance=0)) == "MATLAB:validators:mustBePositive")
% Name-Value の組になっていない
assert(error_id(@() net.calculate_powerflow("Method")) == "GUILDA:resolve_options:InvalidPairs")


%% Every method reaches the same solution
% newton / gradient / levenberg-marquardt は fsolve と同じ解に収束し、同じ形の出力を返す
net = DebugScript.helper.build_ieee14();
tab_ref = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="fsolve")).tab_bus;
for s_method = ["newton", "gradient", "levenberg-marquardt"]
    [res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Method=s_method, WarmStart=false));
    assert(flag == 1 && res.l_success, s_method + ": " + output.message)
    assert(max(abs(res.tab_bus.Vphasor - tab_ref.Vphasor)) < 1e-6, s_method)
    assert(output.algorithm == s_method && output.residual <= 1e-8 && contains(output.message, "converged"))
    assert(size(res.cm_Vhistory,1) == numel(net.a_Bus) && size(res.cm_Vhistory,2) == numel(res.rv_step))
    assert(res.rv_step(1) == 0 && res.rv_step(end) == output.iterations && all(diff(res.rv_step) > 0))
    assert(norm(res.cm_Vhistory(:,end) - res.tab_bus.Vphasor) < 1e-12)
    % 反復回数の上限に達すると flag = 0
    w = warning("off"); c = onCleanup(@() warning(w));
    [res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Method=s_method, MaxIteration=1, WarmStart=false));
    assert(flag == 0 && ~res.l_success && output.iterations == 1 && contains(output.message, "MaxIterations"), s_method)
    clear c
    % Verbose=true は反復ごとに 1 行
    s_log = evalc("net.calculate_powerflow(Method=s_method, Verbose=true, WarmStart=false);");
    assert(count(s_log, "iter ") >= 2 && contains(s_log, "converged"), s_method)
end
% gradient の刻み幅は GUILDA.setting の GradientStepSize で変えられる (大きすぎると発散)
c_cfg = DebugScript.helper.user_config("PowerFlowCalculation", struct("GradientStepSize", 1));
w = warning("off"); c = onCleanup(@() warning(w));
[~, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Method="gradient", WarmStart=false));
assert(flag == -2 && output.StepSize == 1 && contains(output.message, "diverged"))
clear c_cfg


%% Infeasible case is reported by every method
net = DebugScript.helper.build_9bus("Feasible", false);
w = warning("off"); c = onCleanup(@() warning(w));
for s_method = ["newton", "levenberg-marquardt", "gradient"]
    [~, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Method=s_method, MaxIteration=2000));
    assert(flag <= 0 && startsWith(output.message, "✘"), s_method)
end


%% Newton-Raphson solver reports convergence without a warning
% 収束フラグを受け取る呼び出しは MaxIter の警告を出さず、共通の出力と反復の履歴を返す
nrm = MethodNewtonRaphson(Fcn=@(x) x.^2 - 4, Jac=@(x) 2*x, InitVal=1, MaxIter=2);
lastwarn("");
[x, flag, output, rm_hist, rv_step] = nrm.solve();
assert(flag == 0 && output.iterations == 2 && isequal(size(rm_hist), [1 3]) && rm_hist(1) == 1 && rm_hist(end) == x)
assert(isequal(rv_step, 0:2) && output.algorithm == "newton" && contains(output.message, "MaxIterations"))
assert(isempty(lastwarn()))
nrm.MaxIter = 50;
[x, flag, output] = nrm.solve();
assert(flag == 1 && abs(x - 2) < 1e-6 && output.residual <= nrm.ConvTol)
% 出力が 1 つなら従来どおり警告する
nrm.MaxIter = 2;
w = warning("off", "all"); c = onCleanup(@() warning(w));
lastwarn("");
x = nrm.solve(); %#ok<NASGU>
assert(DebugScript.helper.msg_id() == "GUILDA:MethodNewtonRaphson:MaxIteration")
clear c
% Jac が無ければ Increment の中心差分。解のない方程式は flag -2
[x, flag] = MethodNewtonRaphson(Fcn=@(x) [x(1)^2 + x(2) - 2; x(2)^3 - 1], InitVal=[0.5; 0.5]).solve();
assert(flag == 1 && norm(x - [1; 1]) < 1e-5)
[~, flag, output] = MethodNewtonRaphson(Fcn=@(x) x.^2 + 1, InitVal=0, MaxIter=200).solve();
assert(flag <= 0 && startsWith(output.message, "✘"))


%% Method classes solve a generic equation
% MethodLevenbergMarquardt / MethodFsolve / MethodGradient は潮流計算以外の方程式も解ける
f_F = @(x) [x(1)^2 - 4; x(1) + x(2) - 3];
f_J = @(x) [2*x(1), 0; 1, 1];
[x, flag, output, rm_hist, rv_step] = MethodLevenbergMarquardt(Fcn=f_F, Jac=f_J, InitVal=[1; 1]).solve();
assert(flag == 1 && norm(x - [2; 1]) < 1e-8 && isequal(rm_hist(:,end), x) && rv_step(end) == output.iterations)
[x, flag, output] = MethodFsolve(Fcn=f_F, Jac=f_J, InitVal=[1; 1], Display="none").solve();
assert(flag == 1 && norm(x - [2; 1]) < 1e-6 && output.exitflag > 0 && output.algorithm == "fsolve")
[x, flag] = MethodFsolve(Fcn=f_F, InitVal=[1; 1], Display="none").solve();     % Jacobian なし (差分)
assert(flag == 1 && norm(x - [2; 1]) < 1e-6)
[~, flag, output] = MethodFsolve(Fcn=@(x) x.^2 + 1, InitVal=1, Display="none").solve();   % 解なし
assert(flag == -2 && output.exitflag <= 0 && startsWith(output.message, "✘"))
[x, flag] = MethodLevenbergMarquardt(Fcn=f_F, InitVal=[1; 1]).solve();        % Jacobian なし (差分)
assert(flag == 1 && norm(x - [2; 1]) < 1e-8)
[x, flag, output] = MethodGradient(Fcn=@(x) [1; 2] - x, InitVal=[0; 0], StepSize=0.5).solve();
assert(flag == 1 && norm(x - [1; 2]) < 1e-8 && output.iterations > 10)
[~, flag] = MethodGradient(Fcn=@(x) x, InitVal=1, StepSize=1).solve();           % x が増え続けて発散
assert(flag == -2)


%% fsolve stops without Optimization Toolbox
% Toolbox が無い環境を license の代わりで再現する。既定の newton はそのまま動く
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
    net.calculate_powerflow(Method="fsolve");
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:require_toolbox:Unavailable", ME.message)
    assert(contains(ME.message, "Optimization Toolbox") && contains(ME.message, 'Method="fsolve"'), ME.message)
end
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1)
assert(error_id(@() tools.require_toolbox("optim", "X")) == "GUILDA:require_toolbox:Unavailable")
assert(error_id(@() tools.require_toolbox("optimization", "X")) == "MATLAB:validators:mustBeMember")


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
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
f_bus = res.Export(fullfile(s_dir, "bus.csv"));
tab = readtable(f_bus, "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)) && max(abs(tab.V - res.tab_bus.V)) < 1e-12)
res.Export(fullfile(s_dir, "branch.csv"), Table="branch");
tab = readtable(fullfile(s_dir, "branch.csv"), "ReadRowNames", true);
assert(height(tab) == numel(net.a_Branch) && max(abs(tab.Ploss - res.tab_branch.Ploss)) < 1e-12)
% Export=filename は計算後に result.Export を呼ぶ
DebugScript.helper.quiet(@() net.calculate_powerflow(Export=fullfile(s_dir, "nv.csv")));
assert(isfile(fullfile(s_dir, "nv.csv")))
% 未対応の拡張子
assert(error_id(@() res.Export(fullfile(s_dir, "bus.mat"))) == "GUILDA:ResultPF:ExportFormat")


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
res_empty = ResultPF();
assert(error_id(@() res_empty.Export(filepath)) == "GUILDA:ResultPF:NoNetwork")


%% COMPAT v3 positional mode and export options
% 旧形式 calculate_powerflow(mode, "export", l, "filename", f) は警告して v4 に読み替える
net = DebugScript.helper.build_ieee14();
clear Deprecated
lastwarn("");
w = warning("off", "GUILDA:Deprecated:CalculatePowerflowMode"); c = onCleanup(@() warning(w));
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow("dynamic", "export", false));
assert(isa(res, "ResultPF") && logical(flag) && res.options.Method == "dynamic")
id = DebugScript.helper.msg_id();
assert(string(id) == "GUILDA:Deprecated:CalculatePowerflowExport")
assert(GUILDA.config("PowerFlowCalculation", "Method") == "newton")          % 既定値は変わらない
warning(w);

% 位置引数の mode だけ (v3 の "algebraic" は fsolve)
clear Deprecated
lastwarn("");
res = DebugScript.helper.quiet(@() net.calculate_powerflow("algebraic"));
[s_msg, id] = lastwarn(); id = DebugScript.helper.msg_id(s_msg, id);
assert(string(id) == "GUILDA:Deprecated:CalculatePowerflowMode" && res.options.Method == "fsolve")
assert(contains(s_msg, 'Method="fsolve"'), s_msg)

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
        id = string(DebugScript.helper.msg_id(ME));
        if id == ""
            id = "(no id)";
        end
    end
end
