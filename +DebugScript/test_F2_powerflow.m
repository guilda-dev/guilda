% F2 潮流計算 (calculate_powerflow)
%
% 9母線系統 (旧 Task1/Task2) と IEEE14 母線系統で潮流計算を行い、
%   - v4 の呼び出し形式 [result, flag, output] と結果クラス ResultPF
%   - Name-Value による一時的な設定の上書き (GUILDA.setting は変わらない)
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
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow());
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


%% Power flow without a slack bus stops and names the remedy
% GUILDA はスラック母線を選ばない。未指定なら NoSlackBus で止まり、何も変えない
net = DebugScript.helper.build_9bus();
evalc("net.a_Bus{1}.l_isSlack = false;");
sv_log = DebugScript.helper.stale(net);
assert(error_id(@() net.calculate_powerflow()) == "GUILDA:PowerNetwork:NoSlackBus")
assert(~any(cellfun(@(b) b.l_isSlack, net.a_Bus)) && isequal(DebugScript.helper.stale(net), sv_log))


%% get_pf_condition returns the data of the power flow without changing the network
% Bus (Bus.get_pf_condition を積んだ表) と Y (get_admittance_matrix)
net = DebugScript.helper.build_9bus();
sv_log = DebugScript.helper.stale(net);
s_log = evalc("sct = net.get_pf_condition(Display=false);");
assert(isequal(fieldnames(sct), {'Bus';'Y'}) && strlength(s_log) == 0)
assert(isequal(string(sct.Bus.Properties.VariableNames), ["Type","Varg","V","P","Q"]) && isequal(string(sct.Bus.Properties.RowNames), string(net.a_Bus)))
assert(isequaln(sct.Y, net.get_admittance_matrix))
assert(isequal(sct.Bus.Type', ["slack","PV","PV","PQ","PQ","PQ","PQ","PQ","PQ"]))
assert(isequaln(sct.Bus, tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus)))
assert(isequal(DebugScript.helper.stale(net), sv_log))
% Display=true は Bus の表だけを表示し、出力なしでは何も返さない
s_log = evalc("net.get_pf_condition();");
assert(contains(s_log, "Bus") && contains(s_log, "slack"))
s_log = evalc("sct2 = net.get_pf_condition();");
assert(isequaln(sct2.Bus, sct.Bus) && contains(s_log, "Varg"))
% 母線がない、スラック母線がない
assert(error_id(@() PowerNetwork("NoBuses").get_pf_condition(Display=false)) == "GUILDA:PowerNetwork:NoBus")
net0 = PowerNetwork("NoSlack");
net0.add_bus();
assert(error_id(@() net0.get_pf_condition(Display=false)) == "GUILDA:PowerNetwork:NoSlackBus")


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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow()); tab = res.tab_bus;
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

% スラック指定を外すこともできる (外すとスラックは0、潮流計算は NoSlackBus で止まる)
evalc("net.a_Bus{2}.l_isSlack = false;");
assert(n_slack(net) == 0)
assert(error_id(@() net.calculate_powerflow) == "GUILDA:PowerNetwork:NoSlackBus" && n_slack(net) == 0)

% 別の系統の母線には影響しない
net2 = DebugScript.helper.build_9bus();
evalc("net2.a_Bus{2}.l_isSlack = true;");
assert(n_slack(net) == 0 && n_slack(net2) == 1)


%% Bus types follow powerflow settings
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow);

% スラック母線 (B001)、発電機母線: Q が NaN → PV、負荷母線: P,Q 指定 → PQ、機器なし母線: P=Q=0 の PQ
sv_type = string(cellfun(@(b) b.s_bustype, net.a_Bus, "UniformOutput", false));
assert(isequal(sv_type(:)', ["slack","PV","PV","PQ","PQ","PQ","PQ","PQ","PQ"]))
assert(isequal(res.tab_PFcondition.Type', sv_type(:)'))

% get_pf_condition は母線ごとの潮流条件を返す
tab_set = net.a_Bus{2}.get_pf_condition;
assert(tab_set.Type == "PV" && tab_set.P == 1.0 && tab_set.V == 1.00)


%% Specified V P Q are honored by the solution
net = DebugScript.helper.build_9bus();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow()); tab = res.tab_bus;
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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow()); tab = res.tab_bus;
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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow()); tab = res.tab_bus;
assert(flag > 0)

% 各母線の指定値が守られている
tab_cond = net.get_pf_condition(Display=false).Bus;
for i = 1:numel(net.a_Bus)
    s = tab_cond(i,:);
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
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow()); tab = res.tab_bus;
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
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="dynamic"));
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
tab_alg = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="newton")).tab_bus;
tab_dyn = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="dynamic")).tab_bus;

% PV 母線の電圧は指定値
lv_PV = string(cellfun(@(b) b.s_bustype, net.a_Bus, "UniformOutput", false)) == "PV";
V_set = cellfun(@(b) b.tab_parameter.powerflow.V, net.a_Bus);
assert(max(abs(tab_dyn.V(lv_PV) - V_set(lv_PV))) < 1e-4, "dynamic で PV 母線の電圧指定が守られていない")
assert(max(abs(tab_dyn.Vphasor - tab_alg.Vphasor)) < 1e-3)

% Tolerance を小さくすると代数解に近づく
tab_dyn = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="dynamic", Tolerance=1e-9)).tab_bus;
assert(max(abs(tab_dyn.Vphasor - tab_alg.Vphasor)) < 1e-6)


%% Result holds bus and branch values and the settings used
net = DebugScript.helper.build_9bus();
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag > 0)
assert(res.s_solver == "SolverPF" && isempty(res.a_PowerNetwork) && res.r_elapsed >= 0)
% 系統のハンドルは持たず、struct のスナップショット・アドミタンス行列・潮流条件を持つ
assert(res.s_network == string(net.s_tag) && isstruct(res.sct_network) && numel(res.sct_network.a_Bus) == numel(net.a_Bus))
tab_Y = net.get_admittance_matrix;
assert(isequal(res.cm_Y, tab_Y{string(net.a_Bus), string(net.a_Bus)}))
assert(isequaln(res.tab_PFcondition, DebugScript.helper.quiet(@() net.get_pf_condition(Display=false)).Bus))
assert(res.options.Solver == "newton" && res.options.Tolerance == 1e-8 && isnan(res.options.MaxIteration) && res.options.Verbose == false)
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


%% Format chooses the first output
% 既定 "GUILDAorigin" は ResultPF、"V" は母線電圧の列、"powerflow(mat)" は n×4 の複素行列、"powerflow(tab)" は V, I, P, Q の表
net = DebugScript.helper.build_9bus();
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
assert(isa(res, "ResultPF"))
[V, flag_v, out_v] = DebugScript.helper.quiet(@() net.calculate_powerflow(Format="V", WarmStart=false));
assert(isequal(size(V), [numel(net.a_Bus), 1]) && ~isreal(V) && flag_v == flag && isfield(out_v, "message"))
assert(max(abs(V - res.tab_bus.Vphasor)) < 1e-12)
mat = DebugScript.helper.quiet(@() net.calculate_powerflow(Format="powerflow(mat)", WarmStart=false));
assert(isequal(size(mat), [numel(net.a_Bus), 4]) && isa(mat, "double"))
assert(max(abs(mat - [res.tab_bus.Vphasor, res.tab_bus.Iphasor, res.tab_bus.P, res.tab_bus.Q]), [], "all") < 1e-12)
tab = DebugScript.helper.quiet(@() net.calculate_powerflow(Format="powerflow(tab)", WarmStart=false));
assert(isequal(string(tab.Properties.VariableNames), ["V","I","P","Q"]))
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)) && isreal(tab.P) && isreal(tab.Q))
assert(max(abs(tab{:,:} - mat), [], "all") < 1e-12)
assert(error_id(@() net.calculate_powerflow(Format="table")) == "MATLAB:validators:mustBeMember")
% initialize の最初の出力は常に set_equilibrium に書く n×4 の配列 ("powerflow(mat)" と同じ形)。Format は取らない
mat0 = DebugScript.helper.quiet(@() net.initialize(Method="powerflow"));
assert(isequal(size(mat0), [numel(net.a_Bus), 4]) && max(abs(mat0 - mat), [], "all") < 1e-8)
assert(max(abs(mat0(:,1) - net.cv_Vequilibrium)) < 1e-12 && max(abs(mat0(:,2) - net.cv_Iequilibrium)) < 1e-12)
mat_eq = DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
assert(isequal(size(mat_eq), [numel(net.a_Bus), 4]) && max(abs(mat_eq - mat), [], "all") < 1e-6)
mat_fi = DebugScript.helper.quiet(@() net.initialize(Method="FixedInput"));
assert(isequal(size(mat_fi), [numel(net.a_Bus), 4]) && max(abs(abs(mat_fi(:,1)) - abs(mat(:,1)))) < 1e-6)
assert(max(abs(mat_fi(:,1) - net.cv_Vequilibrium)) < 1e-12 && max(abs(mat_fi(:,2) - net.cv_Iequilibrium)) < 1e-12)
% Format を渡すと (どの値でも、どの Method でも) initialize の arguments ブロックのエラーで止まり、calculate_powerflow へは渡らない
mat_before = [net.cv_Vequilibrium, net.cv_Iequilibrium];
for s_format = ["V","powerflow(mat)","powerflow(tab)","GUILDAorigin","table"]
    assert(error_id(@() net.initialize(Format=s_format)) ~= "")
    assert(error_id(@() net.initialize(Method="powerflow", Format=s_format)) ~= "")
end
assert(error_id(@() net.initialize(Method="FixedInput", Format="V")) ~= "")
assert(error_id(@() net.initialize(Method="equilibrium", Format="V")) ~= "")
assert(isequal([net.cv_Vequilibrium, net.cv_Iequilibrium], mat_before))
% 書き出しは結果のメソッド (res.export) だけ。calculate_powerflow と initialize に Export オプションはない
assert(error_id(@() net.calculate_powerflow(Export="pf.csv")) ~= "")
assert(error_id(@() net.initialize(Method="powerflow", Export="pf.csv")) ~= "")


%% Viewing methods of the result read only the stored data
% disp_summary / disp_bus / disp_branch / disp_violation (出力 1 つで文字列) と plot_voltage
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
s = res.disp_summary();
assert(contains(s, "converged") && contains(s, "- Network: 9 buses (slack 1, PV 2, PQ 6), 9 branches") && contains(s, "- Violated operating limits: 0"), s)
assert(strlength(evalc("res.disp_summary();")) > 0)      % 出力なしでは表示する
% 収束しなかった結果: 収束の情報と母線・ブランチの数だけ。注入の合計、|V|、違反数は出さず、その旨の 1 行
net_x = network.IEEE9bus();
for k = 1:numel(net_x.a_Bus)
    for c = 1:numel(net_x.a_Bus{k}.a_Component)
        tab_c = net_x.a_Bus{k}.a_Component{c}.tab_parameter.powerflow;
        if ismember("P", tab_c.Properties.VariableNames) && tab_c.P < 0     % 負荷を 2.5 倍
            net_x.a_Bus{k}.a_Component{c}.tab_parameter.powerflow{:,["P","Q"]} = 2.5*[tab_c.P, tab_c.Q];
        end
    end
end
w = warning("off"); c_w = onCleanup(@() warning(w));
res_x = DebugScript.helper.quiet(@() net_x.calculate_powerflow());
clear c_w
s = res_x.disp_summary();
assert(~res_x.l_success && contains(s, "not converged, flag " + res_x.flag) && contains(s, " iterations") && contains(s, "- Network: 9 buses (slack 1, PV 2, PQ 6), 9 branches"), s)
assert(contains(s, "- Not converged: injection sums, |V| and violated limits are not shown"), s)
assert(~contains(s, "- Generation") && ~contains(s, "- |V|") && ~contains(s, "Violated operating limits:"), s)
assert(contains(evalc("res_x.disp_summary();"), "are not shown"))
% disp_bus: 全母線、Bus で絞り込み、Sort="V" は |V| の小さい順
s = res.disp_bus();
assert(all(contains(s, string(net.a_Bus))) && contains(s, "slack") && contains(s, "P=-1, Q=-0.1"), s)
s = res.disp_bus(Bus=["B005","B002"]);
assert(contains(s, "B005") && contains(s, "B002") && ~contains(s, "B001"))
s = res.disp_bus(Sort="V");
[~, i_min] = min(res.tab_bus.V); [~, i_max] = max(res.tab_bus.V);
assert(strfind(s, string(net.a_Bus{i_min})) < strfind(s, string(net.a_Bus{i_max})))
assert(error_id(@() res.disp_bus(Bus="B099")) == "GUILDA:ResultPF:UnknownTag")
% Unit="SI": |V| は母線の baseKV 倍、P・Q は系統の baseMVA 倍 (スナップショットの値を使う)
sct = res.sct_network;
sct.tab_parameter.base.baseMVA = 200;
sct.a_Bus{2}.tab_parameter.operation.baseKV = 100;       % B002 は PV (V = 1)
tab_pf = table(res.tab_bus.Vphasor, res.tab_bus.Iphasor, res.tab_bus.P, res.tab_bus.Q, ...
               'VariableNames', ["V","I","P","Q"], 'RowNames', res.tab_bus.Properties.RowNames);
sct_solver = struct("flag", 1, "options", res.options, "tab_PFcondition", res.tab_PFcondition);
res_si = ResultPF(tab_pf, res.cm_Y, sct, sct_solver);
s = res_si.disp_bus(Bus="B002", Unit="SI");
assert(contains(s, "(kV)") && contains(s, "(MW)") && contains(s, " 100 ") && contains(s, " 200 "), s)   % 1 pu * 100 kV, 1 pu * 200 MVA
s = res_si.disp_bus(Bus="B005", Unit="SI");
assert(contains(s, "-200") && contains(s, "-20 "), s)                                                    % P = -1, Q = -0.1 pu
assert(error_id(@() ResultPF(tab_pf, res.cm_Y, struct(), sct_solver).disp_bus(Unit="SI")) == "GUILDA:ResultPF:NoBase")
% disp_branch: From/To、Sort="loss" は損失の大きい順、Smax があれば負荷率で並べる
s = res.disp_branch();
assert(all(contains(s, string(net.a_Branch))) && contains(s, "From") && contains(s, "Loading"), s)
s = res.disp_branch(Branch="EL004");
assert(contains(s, "EL004") && contains(s, "B004") && contains(s, "B005") && ~contains(s, "EL005"))
s = res.disp_branch(Sort="loss");
[~, i_loss] = max(res.tab_branch.Ploss); [~, i_low] = min(res.tab_branch.Ploss);
assert(strfind(s, string(net.a_Branch{i_loss})) < strfind(s, string(net.a_Branch{i_low})))
sct_l = res.sct_network;
sct_l.a_Branch{9}.tab_parameter.operation.Smax = 2;
res_l = ResultPF(tab_pf, res.cm_Y, sct_l, sct_solver);
s = res_l.disp_branch(Sort="loading");
assert(strfind(s, string(net.a_Branch{9})) < strfind(s, string(net.a_Branch{1})), s)
s = res_si.disp_branch(Branch="ET001", Unit="SI");
assert(contains(s, "(MW)") && contains(s, sprintf("%.2f", 200*res.tab_branch{"ET001","Pfrom"})), s)
assert(error_id(@() res.disp_branch(Branch="EL099")) == "GUILDA:ResultPF:UnknownTag")
% disp_violation: 種類ごと。Class で絞り込み。違反がなければ 1 行
assert(contains(res.disp_violation(), "No violated operating limits"))
net.a_Bus{8}.tab_parameter.operation.Vmax = 0.95;
res_v = DebugScript.helper.quiet(@() net.calculate_powerflow());
s = res_v.disp_violation();
assert(contains(s, "Bus (1)") && contains(s, "B008") && contains(s, "Vmax"), s)
assert(contains(res_v.disp_violation(Class="Branch"), "No violated operating limits (Branch)"))


%% plot_voltage draws the limits that are finite
% plot_voltage: 既定は 2 つのパネルと有限の Vmin・Vmax の線。Limit=false や無限の制約では線なし
% 戻り値は GraphChart。棒は母線のタグ (|V| と角度で同じタグ)、制約の線は "Vmin"・"Vmax"
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
tab_pf = table(res.tab_bus.Vphasor, res.tab_bus.Iphasor, res.tab_bus.P, res.tab_bus.Q, ...
               'VariableNames', ["V","I","P","Q"], 'RowNames', res.tab_bus.Properties.RowNames);
sct_solver = struct("flag", 1, "options", res.options, "tab_PFcondition", res.tab_PFcondition);
sv_bus = string(res.tab_bus.Properties.RowNames);
f = figure("Visible", "off"); c_f = onCleanup(@() close(f));
G = res.plot_voltage(Parent=f);
tab_e = G.tab_element;
assert(isa(G, "GraphChart") && numel(G.ax) == 2)
assert(isequal(tab_e.Tag, [sv_bus; "Vmin"; "Vmax"; sv_bus]) && isequal(tab_e.Kind, [repmat("bar", 9, 1); "line"; "line"; repmat("bar", 9, 1)]))
h = G.ax(1).Children(arrayfun(@(o) isa(o, "matlab.graphics.chart.primitive.Bar"), G.ax(1).Children));
assert(max(abs(h.YData(:) - res.tab_bus.V)) < 1e-12 && isequal(string(G.ax(1).XTickLabel(:)), sv_bus))
G.set_style("B002", Color=[1 0 0]);                   % 2 つのパネルの棒
assert(isequal(G.SeriesColor(tab_e.Tag == "B002", :), [1 0 0; 1 0 0]))
G.set_style("Vmax", LineStyle="-");
assert(G.SeriesLineStyle(tab_e.Tag == "Vmax") == "-")
clf(f); G = res.plot_voltage(Parent=f, Quantity="magnitude", Limit=false);
assert(numel(G.ax) == 1 && ~any(G.tab_element.Tag == "Vmin"))
clf(f); G = res.plot_voltage(Parent=f, Quantity="angle");
assert(numel(G.ax) == 1 && isequal(G.tab_element.Tag, sv_bus))
sct_i = res.sct_network;
for k = 1:numel(sct_i.a_Bus)
    sct_i.a_Bus{k}.tab_parameter.operation.Vmin = -Inf;
    sct_i.a_Bus{k}.tab_parameter.operation.Vmax = Inf;
end
clf(f); G = ResultPF(tab_pf, res.cm_Y, sct_i, sct_solver).plot_voltage(Parent=f);
assert(~any(ismember(G.tab_element.Tag, ["Vmin", "Vmax"])))
% 母線が多い (IEEE68) と横軸の母線名は 20 個以下に間引いて縦書き。棒とタグは全母線のまま
res68 = DebugScript.helper.quiet(@() network.IEEE68bus().calculate_powerflow());
sv_68 = string(res68.tab_bus.Properties.RowNames);
clf(f); G = res68.plot_voltage(Parent=f, Quantity="magnitude");
h = findobj(G.ax, "Type", "bar");
assert(numel(G.ax.XTick) <= 20 && numel(G.ax.XTick) >= 10 && G.ax.XTickLabelRotation == 90)
assert(isequal(string(G.ax.XTickLabel(:)), sv_68(G.ax.XTick)))
assert(max(abs(h.YData(:) - res68.tab_bus.V)) < 1e-12 && isequal(G.tab_element.Tag(G.tab_element.Kind == "bar"), sv_68))
clear c_f


%% plot_branch draws one bar per branch
% 棒の高さは tab_branch の値 (P: Pfrom, Q: Qfrom, S: 両端の大きいほうの |S|, loss: Ploss)。loading は |S|/Smax と 1 の線
% 戻り値は GraphChart。棒の要素のタグはブランチのタグ
net = DebugScript.helper.build_9bus();
net.a_Branch{4}.tab_parameter.operation.Smax = 0.8;
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
tab = res.tab_branch;
sv_br = string(tab.Properties.RowNames);
rv_S = max(abs([tab.Pfrom + 1j*tab.Qfrom, tab.Pto + 1j*tab.Qto]), [], 2);
f = figure("Visible", "off"); c_f = onCleanup(@() close(f));
bar_of = @(G) findobj(G.ax, "Type", "bar");
G = res.plot_branch(Parent=f);
b = bar_of(G);
assert(isa(G, "GraphChart") && numel(G.ax) == 1 && numel(b) == 1 && max(abs(b.YData(:) - tab.Pfrom)) < 1e-12)
assert(isequal(G.tab_element.Tag, sv_br) && all(G.tab_element.Kind == "bar") && isequal(string(G.ax.XTickLabel(:)), sv_br))
G.set_style(sv_br(2), Color=[0 0 1], Visible=false);
assert(isequal(b.CData(2, :), [0 0 1]) && isnan(b.YData(2)) && ~G.SeriesVisible(2))
for c = {"Q", tab.Qfrom; "S", rv_S; "loss", tab.Ploss}'
    clf(f); b = bar_of(res.plot_branch(Parent=f, Quantity=c{1}));
    assert(max(abs(b.YData(:) - c{2})) < 1e-12, c{1})
end
clf(f); G = res.plot_branch(Parent=f, Quantity="loading");
b = bar_of(G);
rv_Smax = cellfun(@(br) br.tab_parameter.operation.Smax, net.a_Branch(:));   % 無限なら棒なし (NaN)
rv_load = rv_S ./ rv_Smax; rv_load(isinf(rv_Smax)) = NaN;
assert(abs(b.YData(4) - rv_S(4)/0.8) < 1e-12 && isequaln(isnan(b.YData(:)), isnan(rv_load)) && max(abs(b.YData(:) - rv_load), [], "omitnan") < 1e-12)
h = findall(G.ax, "Tag", "RefLine");
assert(isscalar(h) && h.Value == 1)
assert(error_id(@() res.plot_branch(Parent=f, Quantity="I")) == "MATLAB:validators:mustBeMember")
clear c_f


%% plot_convergence draws the largest residual at each iterate
% 残差は SolverPF の方程式と同じ: 収束した最後の点は Tolerance 以下、反復ごとに MethodNewtonRaphson の残差と一致
% 戻り値は GraphChart。残差の線は "Residual"、Bus の |V| の線は母線のタグ
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false, Solver="newton"));
f = figure("Visible", "off"); c_f = onCleanup(@() close(f));
G = res.plot_convergence(Parent=f);
assert(isa(G, "GraphChart") && numel(G.ax) == 1 && isequal(G.tab_element.Tag, "Residual"))
assert(isscalar(findall(G.ax, "Tag", "RefLine")) && findall(G.ax, "Tag", "RefLine").Value == res.options.Tolerance)
h = findobj(G.ax, "Type", "line");
assert(isequal(h.XData(:), res.rv_step(:)) && h.YData(end) <= res.options.Tolerance && h.YData(1) > 1e-3)
assert(abs(h.YData(end) - res.output.residual) <= 1e-12 + 1e-6*res.output.residual)
assert(strcmp(G.ax.YScale, "log"))
assert(~isempty(G.ax.XTick) && all(G.ax.XTick == round(G.ax.XTick)))   % 反復回数は整数の目盛り
G.set_style("Residual", Color=[0 0 0], LineWidth=2);
assert(isequal(h.Color, [0 0 0]) && h.LineWidth == 2)
clf(f); G = res.plot_convergence(Parent=f, Bus=["B008","B001"]);
assert(numel(G.ax) == 2 && isequal(G.tab_element.Tag, ["Residual"; "B001"; "B008"]) && isequal(G.tab_element.Kind, ["line"; "line"; "line"]))
h = G.sct_plt.Element(G.tab_element.Tag == "B008");
assert(numel(findobj(G.ax(2), "Type", "line")) == 2 && max(abs(h.YData(:) - abs(res.cm_Vhistory(8,:)).')) < 1e-12)
assert(isgraphics(G.ax(2).Legend) && isequal(string(G.ax(2).Legend.String), ["B001", "B008"]))
assert(all(arrayfun(@(ax) all(ax.XTick == round(ax.XTick)), G.ax)))
assert(error_id(@() res.plot_convergence(Parent=f, Bus="B099")) == "GUILDA:ResultPF:UnknownTag")
assert(error_id(@() ResultPF().plot_convergence(Parent=f)) == "GUILDA:ResultPF:NoHistory")
% dynamic: 横軸は仮想時間で、パネルは時刻のパネル
res_d = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false, Solver="dynamic"));
clf(f); G = res_d.plot_convergence(Parent=f);
h = findobj(G.ax, "Type", "line");
assert(isequal(h.XData(:), res_d.rv_step(:)) && contains(G.ax.XLabel.String, "virtual time"))
G.set_time(res_d.rv_step(end));
assert(findall(G.ax, "Tag", "TimeCursor").Value == res_d.rv_step(end))
clear c_f


%% plot_network colors the buses and draws the flows as arrows
% 色は |V| (または位相)、矢印は P (Q) が枝に入る端から、線幅は |P| の最小〜最大を BranchWidthRange
% (既定 [1 4] pt) に写す。母線の大きさは 6。座標がないと force レイアウト
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
tab = res.tab_branch;
f = figure("Visible", "off"); c_f = onCleanup(@() close(f));
G = res.plot_network(Parent=f); h = G.sct_plt.Graph;
assert(isa(G, "GraphNetMap") && isa(h, "matlab.graphics.chart.primitive.GraphPlot") && numel(h.XData) == numel(net.a_Bus) && numel(h.LineWidth) == height(tab))
assert(max(abs(h.NodeCData(:) - res.tab_bus.V)) < 1e-12 && numel(findobj(f, "Type", "colorbar")) == 1 && h.ShowArrows)
% 一番太い矢印は |P| が最大の枝、細い順も |P| の順
rv_P = max(abs([tab.Pfrom, tab.Pto]), [], 2);
[~, iv_e] = ismember(h.UserData, string(tab.Properties.RowNames));
assert(isequal(sort(iv_e(:))', 1:height(tab)))
[~, i_e] = max(h.LineWidth);
[~, i_b] = max(rv_P);
rv_r = G.BranchWidthRange;
assert(iv_e(i_e) == i_b && max(abs(h.LineWidth(:) - (rv_r(1) + diff(rv_r)*(rv_P(iv_e) - min(rv_P))/(max(rv_P) - min(rv_P))))) < 1e-12)
[~, iv_w] = sort(h.LineWidth(:));
assert(issorted(rv_P(iv_e(iv_w))), "細い順も |P| の順")
assert(all(h.MarkerSize == 6), "母線の大きさは 6")
% 座標: スナップショットの X, Y を使う。NaN があれば全母線を force レイアウトで置く
sct = res.sct_network;
for k = 1:numel(sct.a_Bus)
    sct.a_Bus{k}.tab_parameter.graph.X = k;
    sct.a_Bus{k}.tab_parameter.graph.Y = -k;
end
tab_pf = table(res.tab_bus.Vphasor, res.tab_bus.Iphasor, res.tab_bus.P, res.tab_bus.Q, ...
               'VariableNames', ["V","I","P","Q"], 'RowNames', res.tab_bus.Properties.RowNames);
res_xy = ResultPF(tab_pf, res.cm_Y, sct, struct("flag", 1, "options", res.options));
clf(f); h = res_xy.plot_network(Parent=f).sct_plt.Graph;
assert(isequal(h.XData(:)', 1:9) && isequal(h.YData(:)', -(1:9)))
sct.a_Bus{3}.tab_parameter.graph.X = NaN;
clf(f); h = ResultPF(tab_pf, res.cm_Y, sct, struct("flag", 1)).plot_network(Parent=f).sct_plt.Graph;
assert(all(isfinite(h.XData)) && ~isequal(h.XData(:)', 1:9))
% Color="angle" は位相 [deg]、Arrow="none" は矢印なし
clf(f); h = res.plot_network(Parent=f, Color="angle", Arrow="none").sct_plt.Graph;
assert(max(abs(h.NodeCData(:) - rad2deg(res.tab_bus.Varg))) < 1e-12 && ~h.ShowArrows && all(h.LineWidth == mean(rv_r)), "矢印なしは範囲の中央")
clf(f); h = res.plot_network(Parent=f, Arrow="Q").sct_plt.Graph;
rv_Q = max(abs([tab.Qfrom, tab.Qto]), [], 2);
[~, iv_e] = ismember(h.UserData, string(tab.Properties.RowNames));
assert(max(abs(h.LineWidth(:) - (rv_r(1) + diff(rv_r)*(rv_Q(iv_e) - min(rv_Q))/(max(rv_Q) - min(rv_Q))))) < 1e-12)
assert(error_id(@() res.plot_network(Parent=f, Color="P")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() ResultPF().plot_network(Parent=f)) == "GUILDA:ResultPF:NoNetworkSnapshot")
clear c_f


%% Branch flows of the result use the admittance matrix in the snapshot
% Branch.struct はスナップショットに枝のアドミタンス行列 cm_Y を加え、ResultPF はそれで枝潮流を求める
net = PowerNetwork();
for i = 1:4
    net.add_bus();
end
net.add_branch("pi",             [1,2], "R",0.01, "X",0.1, "C",0.02);
net.add_branch("pi_transformer", [2,3], "R",0.002, "X",0.05, "C",0.01, "Tap",1.02, "Phase",0.1);
net.add_branch("T",              [3,4], "R",0.01, "X",0.08, "C",0.03);
net.add_branch("two_winding_transformer", [1,4], "R",0.003, "X",0.06, "C",0.01, "Tap",0.97, "Phase",-0.05);
sv_bus = string(net.a_Bus);
cv_V = [1.02; 0.99*exp(-0.1j); 1.01*exp(0.05j); 0.98*exp(-0.2j)];
tab_Y = net.get_admittance_matrix;
cm_Y = tab_Y{sv_bus, sv_bus};
cv_I = cm_Y*cv_V;
tab_pf = table(cv_V, cv_I, real(cv_V.*conj(cv_I)), imag(cv_V.*conj(cv_I)), 'VariableNames', ["V","I","P","Q"], 'RowNames', sv_bus);
res = ResultPF(tab_pf, cm_Y, struct(net, false), struct("flag", 1));
for k = 1:numel(net.a_Branch)
    br = net.a_Branch{k};
    [~, iv] = ismember(string(br.a_Bus), sv_bus);
    I_ft = br.get_admittance_matrix() * cv_V(iv);
    assert(norm([res.tab_branch{k,"Ifrom"}; res.tab_branch{k,"Ito"}] - I_ft) < 1e-12, string(class(br)))
end
% スナップショットの cm_Y は get_admittance_matrix と同じ (2 度目に出会う枝はパスのまま)
sct = struct(net, false);
for k = 1:numel(net.a_Branch)
    assert(isequal(sct.a_Branch{k}.cm_Y, net.a_Branch{k}.get_admittance_matrix()))
end
assert(isequal(struct(net.a_Branch{1}).cm_Y, net.a_Branch{1}.get_admittance_matrix()))
[s_path, ~] = net.a_Branch{1}.struct(false, "x", struct("a_obj", {{net.a_Branch{1}}}, "sv_path", "net.a_Branch{1}"));
assert(s_path == "net.a_Branch{1}")
% 利用者の枝クラス: ResultPF はクラス名ではなく cm_Y を使う (クラス名を変えても同じ潮流、cm_Y を変えれば潮流も変わる)
sct_user = sct;
sct_user.a_Branch{1}.class = "user.MyBranch";
res_user = ResultPF(tab_pf, cm_Y, sct_user, struct("flag", 1));
assert(isequal(res_user.tab_branch, res.tab_branch))
sct_user.a_Branch{1}.cm_Y = 2*sct_user.a_Branch{1}.cm_Y;
res_user = ResultPF(tab_pf, cm_Y, sct_user, struct("flag", 1));
assert(abs(res_user.tab_branch{1,"Ifrom"} - 2*res.tab_branch{1,"Ifrom"}) < 1e-12)
% cm_Y のない struct (Branch.struct を通らないもの) では NaN
sct_user.a_Branch{1} = rmfield(sct_user.a_Branch{1}, "cm_Y");
res_user = ResultPF(tab_pf, cm_Y, sct_user, struct("flag", 1));
assert(isnan(res_user.tab_branch{1,"Pfrom"}) && ~any(isnan(res_user.tab_branch{2,"Pfrom"})))
% 結果は系統の後の編集で変わらない
net.a_Branch{1}.tab_parameter.dynamics.X = 0.5;
assert(res.sct_network.a_Branch{1}.tab_parameter.dynamics.X == 0.1)


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
assert(res.options.Verbose && strlength(s_log) > strlength(evalc("net.calculate_powerflow(WarmStart=false);")))
res = DebugScript.helper.quiet(@() net.calculate_powerflow(verbose=false, solver="dynamic"));   % 名前の大文字小文字は区別しない
assert(~res.options.Verbose && res.options.Solver == "dynamic")
% Verbose は GUILDA.setting のキーでもある (他の解析と同じ)。MaxIteration の自動は NaN
c_cfg = DebugScript.helper.user_config("PowerFlowCalculation", struct("Verbose", true));
s_log = evalc("res = net.calculate_powerflow(WarmStart=false, MaxIteration=NaN);");
assert(res.options.Verbose && contains(s_log, "iter") && res.flag == 1)
clear c_cfg
assert(error_id(@() net.calculate_powerflow(MaxIteration=-1)) ~= "")

% GUILDA.setting は変わらない。ソルバーは数値の設定を持たない
assert(isequaln(GUILDA.config("PowerFlowCalculation"), sct_before))   % NaN = automatic
assert(~isprop(net.solver_PF, "Method") && ~isprop(net.solver_PF, "Tolerance") && ~isprop(net.solver_PF, "WhenFailed"))

% GUILDA.setting を変えると以後の呼び出しすべてに効く
c_cfg = DebugScript.helper.user_config("PowerFlowCalculation", struct("Solver", "dynamic", "Tolerance", 1e-6));
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(res.options.Solver == "dynamic" && res.options.Tolerance == 1e-6 && res.l_success)
clear c_cfg
assert(GUILDA.config("PowerFlowCalculation", "Solver") == "newton")


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
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false, MaxIteration=1, Solver="newton"));
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
% ウォームスタートは同じ母線タグの解だけを使う。タグを変えるとフラットスタートで、結果の行名は新しいタグ
net.a_Bus{14}.s_tag = "Bnew";
[res_t, ~, out_t] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(out_t.iterations > 0 && string(res_t.tab_bus.Properties.RowNames(14)) == string(net.a_Bus{14}))
% スラック母線の変更でも方程式は作り直す
evalc("net.a_Bus{2}.l_isSlack = true;");
net.a_Bus{1}.a_Component{1}.tab_parameter.powerflow.P = 2.3;
[res_s, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1 && abs(res_s.tab_bus.Varg(2) - net.a_Bus{2}.tab_parameter.powerflow.Varg) < 1e-12)
% 枝の削除では母線タグが同じなのでウォームスタートを使う (初期値だけの違いで、解は同じ)
net.remove_branch(string(net.a_Branch{1}));
[res_f, ~, out_f] = DebugScript.helper.quiet(@() net.calculate_powerflow());
[res_g, ~, out_g] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
assert(out_f.iterations > 0 && out_g.iterations > 0 && res_f.l_success)
assert(max(abs(res_f.tab_bus.Vphasor - res_g.tab_bus.Vphasor)) < 1e-8)
% 収束しなかった解は保存しない。reset_solver で捨てる
w = warning("off"); c = onCleanup(@() warning(w));
DebugScript.helper.quiet(@() net.calculate_powerflow(MaxIteration=1, WarmStart=false));
[~, ~, out_h] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(out_h.iterations == 0)
clear c
net.reset_solver();
[~, ~, out_r] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(out_r.iterations == out_g.iterations)
% ソルバーは系統を読まない: Y と潮流条件の表だけで解く。母線タグが違えば保存した解を使わない
net3 = DebugScript.helper.build_ieee14();
evalc("net3.a_Bus{1}.l_isSlack = true;");
tab3 = tools.vcellfun(@(b) b.get_pf_condition, net3.a_Bus);
tab3.Properties.RowNames = string(net3.a_Bus);
tab_Y3 = net3.get_admittance_matrix;
[cv_V3, flag3, out3] = DebugScript.helper.quiet(@() net.solver_PF.solve(tab_Y3{:,:}, tab3, pf_options()));
assert(flag3 == 1 && isequal(size(cv_V3), [14 1]))
assert(out3.iterations == out0.iterations)


%% Initial voltage columns V0 and Varg0 of the conditions start the solver
% 潮流条件の列 V0 [pu]・Varg0 [rad] は初期電圧で、WarmStart とフラットスタートより優先する
net = DebugScript.helper.build_ieee14();
tab = tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus);
tab.Properties.RowNames = string(net.a_Bus);
tab_Y = net.get_admittance_matrix;
sct = pf_options();  sct.WarmStart = false;  sct.Solver = "newton";
[cv_Vref, flag, out_ref] = DebugScript.helper.quiet(@() net.solver_PF.solve(tab_Y{:,:}, tab, sct));
assert(flag == 1 && out_ref.iterations > 2)
% 列なし: 従来どおり (フラットスタートの反復回数は同じ、WarmStart=true は保存した解から反復 0 回)
[cv_V, flag, out] = DebugScript.helper.quiet(@() net.solver_PF.solve(tab_Y{:,:}, tab, sct));
assert(flag == 1 && out.iterations == out_ref.iterations && max(abs(cv_V - cv_Vref)) < 1e-12)
sct_w = sct;  sct_w.WarmStart = true;
[~, ~, out] = DebugScript.helper.quiet(@() net.solver_PF.solve(tab_Y{:,:}, tab, sct_w));
assert(out.iterations == 0)
% 既知の解から始めると 2 回以内で収束し、解は通常の解と一致する
tab_0 = tab;  tab_0.V0 = abs(cv_Vref);  tab_0.Varg0 = angle(cv_Vref);
[cv_V, flag, out, cm_hist] = DebugScript.helper.quiet(@() net.solver_PF.solve(tab_Y{:,:}, tab_0, sct));
assert(flag == 1 && out.iterations <= 2 && max(abs(cv_V - cv_Vref)) < 1e-8)
assert(max(abs(cm_hist(:,1) - cv_Vref)) < 1e-12)
% 列は WarmStart より優先する: 保存した解と違う初期値 (平坦な 1.05 pu) から反復する
tab_1 = tab;  tab_1.V0 = 1.05*ones(height(tab), 1);  tab_1.Varg0 = zeros(height(tab), 1);
[cv_V, flag, out, cm_hist] = DebugScript.helper.quiet(@() net.solver_PF.solve(tab_Y{:,:}, tab_1, sct_w));
assert(flag == 1 && out.iterations > 0 && max(abs(cv_V - cv_Vref)) < 1e-8)
assert(max(abs(cm_hist(:,1) - 1.05)) < 1e-12)
% "dynamic" も列の初期値から同じ解に収束する
sct_d = sct;  sct_d.Solver = "dynamic";
[cv_V, flag] = DebugScript.helper.quiet(@() net.solver_PF.solve(tab_Y{:,:}, tab_0, sct_d));
assert(flag == 1 && max(abs(cv_V - cv_Vref)) < 1e-6)
% 片方の列だけ、または有限でない値はエラー
tab_e = tab;  tab_e.V0 = abs(cv_Vref);
assert(error_id(@() net.solver_PF.solve(tab_Y{:,:}, tab_e, sct)) == "GUILDA:SolverPF:InvalidInitialVoltage")
tab_e = tab;  tab_e.Varg0 = angle(cv_Vref);
assert(error_id(@() net.solver_PF.solve(tab_Y{:,:}, tab_e, sct)) == "GUILDA:SolverPF:InvalidInitialVoltage")
tab_e = tab_0;  tab_e.V0(3) = NaN;
assert(error_id(@() net.solver_PF.solve(tab_Y{:,:}, tab_e, sct)) == "GUILDA:SolverPF:InvalidInitialVoltage")


%% Violated operating limits are recorded and not applied
% 潮流計算は operation の制約を課さず、違反を tab_violation に記録するだけ (警告もエラーもなし)
net = DebugScript.helper.build_ieee14();
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
% IEEE14 のデータ自体が違反を含む: B006, B007, B008 の V > Vmax = 1.06、スラックの発電機の Q < Qmin = 0
tab0 = res.tab_violation;
assert(isequal(sort(tab0.Object + ":" + tab0.Limit), sort(["B006:Vmax";"B007:Vmax";"B008:Vmax";"B001SG1:Qmin"])))
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


%% Components share the bus P and Q as initialize gives them
% tools.distribute_power は Bus.set_equilibrium (initialize) と tab_violation の両方が使う配分。
% PV 母線 B002 に Q = NaN の発電機をもう 1 台つなぎ、残りの Q を 2 台で分ける
net = DebugScript.helper.build_9bus();
bus = net.a_Bus{2};
g1 = bus.a_Component{1};
g2 = bus.add_component("gen-park", P=0.3, Q=NaN);
g1.tab_parameter.operation{1,["baseMVA","Qmin","Qmax"]} = [100, -0.5, 1.5];
g2.tab_parameter.operation{1,["baseMVA","Qmin","Qmax"]} = [300, -0.2, 0.2];
r_P = 2.0;  r_Q = 0.4;
rm_PQ = tools.distribute_power(bus, r_P, r_Q);                          % 既定 "baseMVA"
assert(isequal(rm_PQ(:,1), [g1.tab_parameter.powerflow.P; 0.3]))       % PV 母線の P は設定値のまま
assert(max(abs(rm_PQ(:,2) - r_Q*[100; 300]/400)) < 1e-15)
rm_PQ = tools.distribute_power(bus, r_P, r_Q, "Qmax");                  % Qmin から幅 Qmax - Qmin に比例
assert(max(abs(rm_PQ(:,2) - ([-0.5; -0.2] + [2.0; 0.4]/2.4*(r_Q + 0.7)))) < 1e-15)
g2.tab_parameter.operation.Qmax = Inf;                                  % 無限の幅があれば "baseMVA"
assert(isequal(tools.distribute_power(bus, r_P, r_Q, "Qmax"), tools.distribute_power(bus, r_P, r_Q)))
assert(isequal(size(tools.distribute_power(PowerNetwork().add_bus(), 1, 1)), [0 2]))
% initialize の機器の P、Q と tab_violation の値は同じ配分
pf  = DebugScript.helper.quiet(@() net.initialize());
c_V = bus.c_Vequilibrium;
rm_init = cell2mat(cellfun(@(c) [real(c_V*conj(c.c_Iequilibrium)), imag(c_V*conj(c.c_Iequilibrium))], ...
                           bus.a_Component(:), "UniformOutput", false));
rm_dist = tools.distribute_power(bus, real(pf(2,3)), real(pf(2,4)));
assert(max(abs(rm_init - rm_dist), [], "all") < 1e-12)
g2.tab_parameter.operation.Qmax = rm_dist(2,2) - 0.01;                  % 違反させる
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
row = res.tab_violation(res.tab_violation.Object == string(g2) & res.tab_violation.Limit == "Qmax", :);
assert(height(row) == 1)
assert(abs(row.Value - rm_dist(2,2)) < 1e-8)


%% Unknown or invalid options stop with an error
net = DebugScript.helper.build_9bus();
% 未知の名前は arguments ブロックのエラー
assert(error_id(@() net.calculate_powerflow(Tolerence=1e-8)) ~= "")
% 共通名以外 (ソルバー固有の名前) も受け付けない
assert(error_id(@() net.calculate_powerflow("MaxIterations", 5)) ~= "")
% 値の検証
assert(error_id(@() net.calculate_powerflow(Solver="algebraic")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() net.calculate_powerflow(MaxIteration=-1)) ~= "")
assert(error_id(@() net.calculate_powerflow(MaxIteration=1.5)) ~= "")
assert(error_id(@() net.calculate_powerflow(Plot="yes")) ~= "")
assert(error_id(@() net.calculate_powerflow(WarmStart="yes")) ~= "")
assert(error_id(@() net.calculate_powerflow(PlotFcn="bars")) == "GUILDA:check_plotfcn:UnknownKey")
assert(error_id(@() net.calculate_powerflow(Tolerance=0)) == "MATLAB:validators:mustBePositive")
% v3 の位置引数 mode と export/filename は受け付けない
assert(error_id(@() net.calculate_powerflow("dynamic")) ~= "")
assert(error_id(@() net.calculate_powerflow("dynamic", "export", false)) ~= "")
assert(error_id(@() net.calculate_powerflow(filename="a.json")) ~= "")
% Name-Value の組になっていない
assert(error_id(@() net.calculate_powerflow("Solver")) ~= "")


%% fsolve reaches a small Tolerance
% fsolve には Tolerance^2 を FunctionTolerance と OptimalityTolerance として渡す。
% OptimalityTolerance が既定 (1e-6) のままだと、これらの系統は不平衡 1e-10〜1e-9 で止まり flag -2 だった
for c = {{"EAST30", "peak"}, {"WEST30", "night"}}
    net = DebugScript.helper.quiet(@() network.("IEEJ_" + c{1}{1})(Section=c{1}{2}));
    [res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="fsolve", Tolerance=1e-10, WarmStart=false));
    assert(flag == 1 && output.residual <= 1e-10, c{1}{1} + " " + c{1}{2} + ": " + output.message)
    tab_NR = DebugScript.helper.quiet(@() net.calculate_powerflow(Tolerance=1e-12, WarmStart=false)).tab_bus;
    assert(max(abs(res.tab_bus.Vphasor - tab_NR.Vphasor)) < 1e-10)
end


%% Every method reaches the same solution
% newton / gradient / levenberg-marquardt は fsolve と同じ解に収束し、同じ形の出力を返す
net = DebugScript.helper.build_ieee14();
tab_ref = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="fsolve")).tab_bus;
for s_method = ["newton", "gradient", "levenberg-marquardt"]
    [res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_method, WarmStart=false));
    assert(flag == 1 && res.l_success, s_method + ": " + output.message)
    assert(max(abs(res.tab_bus.Vphasor - tab_ref.Vphasor)) < 1e-6, s_method)
    assert(output.algorithm == s_method && output.residual <= 1e-8 && contains(output.message, "converged"))
    assert(size(res.cm_Vhistory,1) == numel(net.a_Bus) && size(res.cm_Vhistory,2) == numel(res.rv_step))
    assert(res.rv_step(1) == 0 && res.rv_step(end) == output.iterations && all(diff(res.rv_step) > 0))
    assert(norm(res.cm_Vhistory(:,end) - res.tab_bus.Vphasor) < 1e-12)
    % 反復回数の上限に達すると flag = 0
    w = warning("off"); c = onCleanup(@() warning(w));
    [res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_method, MaxIteration=1, WarmStart=false));
    assert(flag == 0 && ~res.l_success && output.iterations == 1 && contains(output.message, "MaxIterations"), s_method)
    clear c
    % Verbose=true は反復ごとに 1 行
    s_log = evalc("net.calculate_powerflow(Solver=s_method, Verbose=true, WarmStart=false);");
    assert(count(s_log, "iter ") >= 2 && contains(s_log, "converged"), s_method)
end
% gradient の刻み幅は GUILDA.setting の GradientStepSize で変えられる (大きすぎると発散)
c_cfg = DebugScript.helper.user_config("PowerFlowCalculation", struct("GradientStepSize", 1));
w = warning("off"); c = onCleanup(@() warning(w));
[~, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="gradient", WarmStart=false));
assert(flag == -2 && output.StepSize == 1 && contains(output.message, "diverged"))
clear c_cfg


%% Infeasible case is reported by every method
net = DebugScript.helper.build_9bus("Feasible", false);
w = warning("off"); c = onCleanup(@() warning(w));
for s_method = ["newton", "levenberg-marquardt", "gradient"]
    [~, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_method, MaxIteration=2000));
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
    net.calculate_powerflow(Solver="fsolve");
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:require_toolbox:Unavailable", ME.message)
    assert(contains(ME.message, "Optimization Toolbox") && contains(ME.message, 'Solver="fsolve"'), ME.message)
end
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1)
assert(error_id(@() tools.require_toolbox("optim", "X")) == "GUILDA:require_toolbox:Unavailable")
assert(error_id(@() tools.require_toolbox("optimization", "X")) == "MATLAB:validators:mustBeMember")


%% Plot and Export of the result
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow());

% Plot: 電圧の大きさと位相の棒グラフ
G = res.plot_voltage(Parent=figure("Visible","off"));
c_fig = onCleanup(@() close(ancestor(G.ax(1), "figure")));
assert(isa(G, "GraphChart") && numel(G.ax) == 2)
% 計算後の図は result.plot_voltage だけ。Plot オプションは廃止、PlotFcn (計算中の表示) は "none" では図を作らない
a_before = findall(groot, "Type", "figure");
res = DebugScript.helper.quiet(@() net.calculate_powerflow(PlotFcn="none"));
assert(res.options.PlotFcn == "none" && isempty(setdiff(findall(groot, "Type", "figure"), a_before)))
assert(error_id(@() net.calculate_powerflow(Plot=true)) ~= "")     % 未知の名前 (arguments ブロックのエラー)
assert(error_id(@() net.calculate_powerflow(PlotFcn="voltage")) == "GUILDA:check_plotfcn:UnknownKey")
assert(error_id(@() net.calculate_powerflow(PlotFcn=["none","residual"])) == "GUILDA:check_plotfcn:InvalidValue")
assert(error_id(@() net.calculate_powerflow(PlotFcn=1)) == "GUILDA:check_plotfcn:InvalidValue")

% Export: 拡張子で形式が決まる。CSV は母線または枝の表
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
f_bus = res.export(fullfile(s_dir, "bus.csv"));
tab = readtable(f_bus, "ReadRowNames", true);
assert(isequal(string(tab.Properties.RowNames), string(net.a_Bus)) && max(abs(tab.V - res.tab_bus.V)) < 1e-12)
res.export(fullfile(s_dir, "branch.csv"), Table="branch");
tab = readtable(fullfile(s_dir, "branch.csv"), "ReadRowNames", true);
assert(height(tab) == numel(net.a_Branch) && max(abs(tab.Ploss - res.tab_branch.Ploss)) < 1e-12)
% 未対応の拡張子
assert(error_id(@() res.export(fullfile(s_dir, "bus.mat"))) == "GUILDA:ResultPF:ExportFormat")


%% Dynamic method exports convergence history as JSON
% .json は計算過程 (GridSpring で可視化できる形式)
net = DebugScript.helper.build_ieee14();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="dynamic"));
filepath = fullfile(tempdir, "DebugScript_test_F2_" + string(feature("getpid")) + ".json");
c = onCleanup(@() delete(filepath));
DebugScript.helper.quiet(@() res.export(filepath));

assert(isfile(filepath))
data = jsondecode(fileread(filepath));
assert(numel(data.nodes) == numel(net.a_Bus))
assert(numel(data.nodes(2).Vabs) == numel(res.rv_step))
% 結果だけ (系統なし) では JSON を書けない
res_empty = ResultPF();
assert(error_id(@() res_empty.export(filepath)) == "GUILDA:ResultPF:NoNetwork")


% ---- local functions ----
%% PlotFcn residual shows the residual of each equation for every Solver
% "residual": 方程式ごとの |残差| の棒 (母線あたり 2 本)。図 (Tag) を使い回し、反復ごとに更新
net = DebugScript.helper.build_ieee14();
n_bus = numel(net.a_Bus);
s_tag = "GUILDA:PlotFcn:residual";
fig = figure("Visible", "off", "Tag", s_tag);      % 同じ Tag の図があればそれを使う
c_fig = onCleanup(@() close(findall(groot, "Type", "figure", "Tag", s_tag)));
for s_solver = ["newton","levenberg-marquardt","gradient","fsolve","dynamic"]
    res0 = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_solver, WarmStart=false));
    res1 = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_solver, WarmStart=false, PlotFcn="residual"));
    % 結果は "none" と同じ
    assert(res1.flag == 1 && isequal(res1.tab_bus{:, 1:4}, res0.tab_bus{:, 1:4}) ...
           && isequal(res1.output.iterations, res0.output.iterations), s_solver)
    assert(isequal(res1.options.PlotFcn, "residual"))
    a_fig = findall(groot, "Type", "figure", "Tag", s_tag);
    a_bar = findobj(fig, "Type", "bar");
    assert(isscalar(a_fig) && a_fig == fig && numel(a_bar) == 2, s_solver)
    % 最後の反復の残差 (0 は棒なし = NaN)、題に Solver
    rm_F = [a_bar(2).YData(:), a_bar(1).YData(:)];
    r_tol = res1.options.Tolerance;
    assert(numel(rm_F) == 2*n_bus && max(rm_F(:), [], "omitnan") <= 1.01*r_tol && all(rm_F(:) > 0 | isnan(rm_F(:))), s_solver)
    % 縦軸は最小の残差と Tolerance の 1/10 以下から最大の 10 倍以上 (棒と Tolerance の線が見える)
    ax = findobj(fig, "Type", "axes");
    assert(ax.YLim(1) <= min([rm_F(:); r_tol], [], "omitnan")/10 && ax.YLim(2) >= 10*r_tol && a_bar(1).BaseValue == ax.YLim(1), s_solver)
    s_title = string(ax.Title.String);
    assert(contains(s_title, "(" + s_solver + ")"), s_title)
end
% 反復の途中で更新される (MaxIteration=1 の newton は残差が許容誤差より大きい棒のまま終わる)
DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false, MaxIteration=1, PlotFcn="residual", Verbose=false));
a_bar = findobj(fig, "Type", "bar");
assert(max([a_bar.YData]) > 1e-6 && contains(string(findobj(fig, "Type", "axes").Title.String), "iteration 1"))
% 図を閉じても計算は続く (表示だけ止まる): 図を閉じる関数ハンドルで "init" の後に閉じる
close(fig)
res = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver="gradient", WarmStart=false, PlotFcn="residual", MaxIteration=50));
assert(isscalar(findall(groot, "Type", "figure", "Tag", s_tag)))


%% disp_powerflow shows the bus injection S = V*conj(I)
% IEEE9bus を initialize し、表の P, Q が平衡点の V.*conj(I) と一致すること
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
evalc("tab = net.disp_powerflow();");
cv_S = net.cv_Vequilibrium .* conj(net.cv_Iequilibrium);
assert(max(abs(tab.("P(pu)") - real(cv_S))) < tol && max(abs(tab.("Q(pu)") - imag(cv_S))) < tol)
% B005 の負荷: P = -1.25
assert(abs(tab{"B005","P(pu)"} - (-1.25)) < tol, "B005 P = " + tab{"B005","P(pu)"})


%% PlotFcn handle receives the voltages and can stop the power flow
% 関数ハンドル: stop = f(x, optimValues, state)。x は母線の複素電圧
net = DebugScript.helper.build_ieee14();
n_bus = numel(net.a_Bus);
for s_solver = ["newton","levenberg-marquardt","gradient","fsolve","dynamic"]
    m_log = containers.Map(["state","iteration","residual"], {strings(1,0), [], []});
    res = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_solver, WarmStart=false, ...
                                       PlotFcn=@(x, o, s) log_call(m_log, n_bus, x, o, s)));
    assert(res.flag == 1, s_solver)
    sv_state = m_log("state");
    assert(sv_state(1) == "init" && sv_state(end) == "done" && all(sv_state(2:end-1) == "iter") && numel(sv_state) >= 3, s_solver)
    rv_res = m_log("residual");
    assert(rv_res(end) <= 1.01*res.options.Tolerance, s_solver)     % dynamic: the event at the crossing of Tolerance
    rv_iter = m_log("iteration");
    if s_solver ~= "dynamic"
        assert(rv_iter(end) == res.output.iterations, s_solver)
    end
end
% stop = true で止める: flag -1 とメッセージ
c_w = DebugScript.helper.user_config("PowerFlowCalculation", struct("WhenFailed", "NONE"));
for s_solver = ["newton","levenberg-marquardt","gradient","fsolve","dynamic"]
    [res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_solver, WarmStart=false, PlotFcn=@(x, o, s) o.iteration >= 1));
    assert(flag == -1 && contains(res.output.message, "stopped by PlotFcn") && ~res.l_success, s_solver)
end
clear c_w

%% Warm start that fails is solved once more from the flat start
% ノーズ点 (2.374 倍) 近くの収束解から負荷を戻すとニュートン法は発散する。保持解から始めた計算が
% flag 0 / -2 なら、フラットスタートで 1 回だけ解き直す (output と履歴は再試行のもの、警告なし)
s_retry = "solved again from the flat start";
net = network.IEEE9bus();
[res_flat, ~, out_flat] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
c_w = DebugScript.helper.user_config("PowerFlowCalculation", struct("WhenFailed", "NONE"));
set_load(net, 2.37);
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1)
set_load(net, 1);
lastwarn("");
[res, flag, out] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1 && contains(out.message, s_retry) && out.iterations == out_flat.iterations, out.message)
assert(max(abs(res.tab_bus.Vphasor - res_flat.tab_bus.Vphasor)) < 1e-8 && size(res.cm_Vhistory, 2) == out.iterations + 1)
assert(lastwarn == "")
% Verbose=true は 1 行表示する
set_load(net, 2.37);
DebugScript.helper.quiet(@() net.calculate_powerflow());
set_load(net, 1);
s_log = evalc("[~, flag] = net.calculate_powerflow(Verbose=true);");
assert(flag == 1 && contains(s_log, "solving again from the flat start"))
% 収束すれば再試行しない。WarmStart=false も再試行しない
[~, ~, out] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(out.iterations == 0 && ~contains(out.message, s_retry))
set_load(net, 2.38);
[~, flag, out] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
assert(flag ~= 1 && ~contains(out.message, s_retry))
% PlotFcn で止めた計算 (flag -1) は再試行しない
set_load(net, 2.37);
DebugScript.helper.quiet(@() net.calculate_powerflow());
set_load(net, 1);
[~, flag, out] = DebugScript.helper.quiet(@() net.calculate_powerflow(PlotFcn=@(x, o, s) o.iteration >= 1));
assert(flag == -1 && ~contains(out.message, s_retry), out.message)
% 再試行も失敗したら、保持解はそのまま (2.37 の解から反復 0 回)
set_load(net, 2.38);
[~, flag, out] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(any(flag == [0 -2]) && contains(out.message, s_retry), out.message)
set_load(net, 2.37);
[~, flag, out] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag == 1 && out.iterations == 0)
% 全 Solver で再試行する (MaxIteration=1 は保持解からもフラットスタートからも収束しない)
for s_solver = ["newton","levenberg-marquardt","gradient","fsolve"]
    set_load(net, 1);
    DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_solver, WarmStart=false));
    set_load(net, 1.5);
    [~, flag, out] = DebugScript.helper.quiet(@() net.calculate_powerflow(Solver=s_solver, MaxIteration=1));
    assert(flag ~= 1 && contains(out.message, s_retry), s_solver)
end
clear c_w


function set_load(net, r_scale)
% IEEE9bus の母線 5・6・8 の負荷 (P, Q) を元の r_scale 倍にする
    rm_PQ = [-1.25 -0.5; -0.9 -0.3; -1 -0.35];
    iv_bus = [5 6 8];
    for k = 1:3
        net.a_Bus{iv_bus(k)}.a_Component{1}.tab_parameter.powerflow.P = r_scale*rm_PQ(k,1);
        net.a_Bus{iv_bus(k)}.a_Component{1}.tab_parameter.powerflow.Q = r_scale*rm_PQ(k,2);
    end
end


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


function stop = log_call(m_log, n_bus, x, sct, s_state)
% PlotFcn の関数ハンドル: 呼ばれた state・iteration・residual を m_log に足す
    assert(isequal(size(x), [n_bus, 1]) && isnumeric(x) && numel(sct.fval) == 2*n_bus && ischar(s_state))
    m_log("state")     = [m_log("state"), string(s_state)];
    m_log("iteration") = [m_log("iteration"), sct.iteration];
    m_log("residual")  = [m_log("residual"), sct.residual];
    stop = false;
end


function sct = pf_options()
% calculate_powerflow がソルバーに渡す設定 (PowerFlowCalculation の値と Display)
    sct_cfg = GUILDA.config("PowerFlowCalculation");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    sct.Display = "none";
end
