% F6 時間応答シミュレーション (simulate / Scenario / ResultODE)
%
% イベントの種類ごとに IEEE14 母線系統の応答を計算し、結果を確認する。
%   sc  = Scenario("名前");  sc.add_disturbance("名前", "TimeSpan", [t1,t2], <外乱の指定>);  net.add_scenario(sc);
%   (テストでは ev = DebugScript.helper.scenario("名前", net, "TimeSpan", [t1,t2], <外乱の指定>))
%   [sol, flag, output] = net.simulate([t0,tend], ev1, ev2, ..., Name, Value);
%   r   = sol.odeResults;     % r.t, r.Bus(i).V / I / PQ, r.Bus(i).Component(j).X / U
%
%   FaultBus   : 母線の地絡 (電圧 0)
%   TripUnit   : 機器の解列
%   OffsetState: 状態の初期値のずらし
%   InputValue : 機器入力への加算 (数値 / 関数ハンドル)
%
%   flag: 1 = 終了時刻まで計算, 0 = TimeLimit で停止, -1 = ソルバーが途中で停止
%   Name-Value (SolverODE.OptionMap): Solver, SolverOptions, Tolerance, AbsoluteTolerance,
%   SeparateComplexParts, TimeLimit, Progress, Verbose, Plot (+ Export)。その呼び出しだけ有効
%
% 実行: runtests("DebugScript.test_F6_simulation")  または  DebugScript.run_all("Features","F6")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();       % 進捗表示なし (Progress = "none")
DebugScript.helper.quiet(@() net.initialize);
inwin = @(t, t1, t2) t > t1 + 1e-3 & t < t2 - 1e-3;   % 区間の内側 (境界の重複点を除く)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Simulation result structure
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,3], ev);
assert(isa(sol, "ResultODE"))

r = sol.odeResults;
nt = numel(r.t);
assert(r.t(1) == 0 && r.t(end) == 3 && all(diff(r.t) >= 0))

% 母線: V (Vreal, Vimag), I (Ireal, Iimag), PQ (P, Q)
assert(numel(r.Bus) == numel(net.a_Bus))
assert(isequal(string(r.Bus(1).V.Properties.VariableNames),  ["Vreal","Vimag"]))
assert(isequal(string(r.Bus(1).I.Properties.VariableNames),  ["Ireal","Iimag"]))
assert(isequal(string(r.Bus(1).PQ.Properties.VariableNames), ["P","Q"]))
assert(height(r.Bus(1).V) == nt)

% 機器: X (状態), U (入力) の列名は sv_x, sv_u
gen = net.a_Bus{1}.a_Component{1};
assert(isequal(string(r.Bus(1).Component(1).X.Properties.VariableNames), gen.sv_x(:)'))
assert(isequal(string(r.Bus(1).Component(1).U.Properties.VariableNames), gen.sv_u(:)'))
assert(height(r.Bus(1).Component(1).X) == nt)

% 初期値は平衡点
assert(norm(r.Bus(1).Component(1).X{1,:}' - gen.rv_Xequilibrium) < 1e-8)
V1 = r.Bus(1).V{1,:} * [1;1j];
assert(abs(V1 - net.a_Bus{1}.c_Vequilibrium) < 1e-8)


%% Trajectory follows the variable map
% 結果は軌道を変数の表 (net.get_variable_map) の順に 1 回だけ持つ: rm_variable の列 = tab_variable の行。
% 局所・大域制御器の状態も入り、odeResults はその見え方 (同じ値)
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,2], ev);
[tab, c_idxBus, c_idxGC] = net.get_variable_map();
n_lin = sum(ismember(tab.Kind, ["x","Vre","Vim","u"]));   % 結果の変数は表の先頭の x, Vre, Vim, u
tab = tab(1:n_lin,:);
c_idxBus = cellfun(@(iv) iv(iv <= n_lin), c_idxBus, 'UniformOutput', false);
c_idxGC  = cellfun(@(iv) iv(iv <= n_lin), c_idxGC, 'UniformOutput', false);
nt  = numel(sol.rv_t);
assert(isequal(sol.tab_variable, tab))
assert(isequal(size(sol.rm_variable), [nt, height(tab)]))
assert(isequal(size(sol.rm_I), [nt, 2*numel(net.a_Bus)]))
r = sol.odeResults;
assert(isequal(r.t, sol.rv_t) && height(r.Bus(1).V) == nt)
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(all(ismember([avr.s_tag, avr.a_LocalController{1}.s_tag, net.a_GlobalController{1}.s_tag], tab.Owner)))
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    assert(isequaln(r.Bus(i).V.Variables, sol.rm_variable(:, tab.Bus == bus.s_tag & (tab.Kind == "Vre" | tab.Kind == "Vim"))))
    assert(isequaln(r.Bus(i).I.Variables, sol.rm_I(:, 2*i-1:2*i)))
    for j = 1:numel(bus.a_Component)
        c = bus.a_Component{j};
        assert(isequaln(r.Bus(i).Component(j).X.Variables, sol.rm_variable(:, tab.Owner == c.s_tag & tab.Kind == "x")))
        assert(isequaln(r.Bus(i).Component(j).U.Variables, sol.rm_variable(:, tab.Owner == c.s_tag & tab.Kind == "u")))
    end
end
% 制御器の状態は地絡で動く
X_avr = sol.rm_variable(:, tab.Owner == avr.s_tag);
assert(norm(X_avr(1,:)' - avr.rv_Xequilibrium) < 1e-8 && max(abs(X_avr - X_avr(1,:)), [], "all") > 1e-4)
assert(max(abs(sol.rm_variable(:, c_idxGC{1})), [], "all") > 1e-6)
% get_point: 変数の表の順の列ベクトル。母線・機器の表を与えるとその行だけ
x = sol.get_point(1.5);
assert(isequal(size(x), [height(tab), 1]))
lin = @(T) T(ismember(T.Kind, ["x","Vre","Vim","u"]), :);
assert(isequal(sol.get_point(1.5, lin(net.a_Bus{1}.get_variable_map())), x(c_idxBus{1})))
assert(isequal(sol.get_point(1.5, lin(net.a_Bus{1}.a_Component{1}.get_variable_map())), ...
               x(c_idxBus{1}(1:height(lin(net.a_Bus{1}.a_Component{1}.get_variable_map()))))))
% 制御器の入力 uc は結果に無い
tab_c1 = net.a_Bus{1}.a_Component{1}.get_variable_map();
expect_error(@() sol.get_point(1.5, tab_c1(tab_c1.Kind == "uc", :)), "GUILDA:ResultODE:UnknownVariable")
% 範囲外の時刻、結果にない変数はエラー
expect_error(@() sol.get_point(3), "GUILDA:ResultODE:PointTime")
tab_bad = tab(1,:);  tab_bad.Owner = "nobody";
expect_error(@() sol.get_point(1.5, tab_bad), "GUILDA:ResultODE:UnknownVariable")
% 空の結果
sol0 = ResultODE();
assert(isequal(sol0.odeResults, struct()) && isempty(sol0.rm_variable) && isempty(sol0.rv_t))


%% Point at a phase boundary
% 区間の境界の時刻は 2 回出力される (前の区間の終わり, 次の区間の始まり)。
% get_point は既定でイベントの後 (Side="after")、Side="before" でイベントの前の値を返す
gen = net.a_Bus{1}.a_Component{1};
ev  = DebugScript.helper.scenario("offset", net, "TimeSpan", 1, "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.1);
sol = net.simulate([0,2], ev);
tab = sol.tab_variable;
iv_d = find(tab.Owner == gen.s_tag & tab.Name == "delta");
assert(nnz(sol.rv_t == 1) == 2, "境界の時刻が 2 回出力されていない")
x_after  = sol.get_point(1);
x_before = sol.get_point(1, Side="before");
assert(isequal(x_after, sol.get_point(1, Side="after")))
assert(abs(x_before(iv_d) - gen.rv_Xequilibrium(1)) < 1e-8)
assert(abs(x_after(iv_d) - (gen.rv_Xequilibrium(1) + 0.1)) < 1e-8)
% 境界でない出力時刻では Side は関係なく、その間は線形補間
k = find(sol.rv_t > 1.2, 1);
assert(isequal(sol.get_point(sol.rv_t(k), Side="before"), sol.get_point(sol.rv_t(k)), sol.rm_variable(k,:)'))
tm = (sol.rv_t(k) + sol.rv_t(k+1)) / 2;
assert(norm(sol.get_point(tm) - (sol.rm_variable(k,:) + sol.rm_variable(k+1,:))'/2) < 1e-12)
% 線形化の Point={sim, t, Side} も同じ規則
assert(isequal(net.linearize("Point", {sol, 1}).rv_point, x_after))
assert(isequal(net.linearize("Point", {sol, 1, "before"}).rv_point, x_before))


%% V4 call returns result flag and output
% [result, flag, output] を返す。結果クラスは ResultBase を継承し、flag / output / 使った設定を持つ
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[sol, flag, output] = net.simulate([0,3], ev);
assert(isa(sol, "ResultODE") && isa(sol, "ResultBase"))
assert(flag == 1 && sol.flag == 1 && sol.l_success)
assert(isequal(sol.output, output) && output.tEnd == 3 && output.nPhases == 3 && output.nPhasesDone == 3)
assert(isstring(output.message) && contains(output.message, "t = 3"))
assert(istable(output.phases) && height(output.phases) == 3)
assert(sol.s_solver == "SolverODE" && sol.s_network == string(net.s_tag) && sol.r_elapsed > 0)
assert(sol.options.Tolerance == GUILDA.config("TimeSimulation", "Tolerance"))
assert(sol.options.Progress == "none" && sol.options.TimeLimit == GUILDA.config("TimeSimulation", "TimeLimit"))
assert(isequal(sol.sv_bus, string(net.a_Bus(:))) && numel(sol.c_component) == numel(net.a_Bus))
assert(sol.c_component{1}(1) == string(net.a_Bus{1}.a_Component{1}))
% モデルのデータは複製しない (未使用だった odeNetwork は廃止)
assert(~isprop(sol, "odeNetwork"))
% ソルバーは設定も系統・時間表・結果も保持しない (設定は GUILDA.setting の TimeSimulation)
assert(~isprop(net.solver_ODE, "odeNetwork") && ~isprop(net.solver_ODE, "odeTimeTable") && ~isprop(net.solver_ODE, "odeResult"))
assert(~isprop(net.solver_ODE, "RelativeTolerance") && ~isprop(net.solver_ODE, "Progress") && ~isprop(net.solver_ODE, "Reporter"))


%% Name-Value overrides leave GUILDA.setting unchanged
% Name-Value はその呼び出しだけ有効。GUILDA.setting の TimeSimulation は変わらない
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sct0 = GUILDA.config("TimeSimulation");
sol = net.simulate([0,3], ev, Tolerance=1e-6, AbsoluteTolerance=1e-8, TimeLimit=Inf, Progress=false, Solver="ode23t");
assert(sol.options.Tolerance == 1e-6 && sol.options.AbsoluteTolerance == 1e-8)
assert(isinf(sol.options.TimeLimit) && sol.options.Progress == "none" && string(sol.options.Solver) == "ode23t")
assert(sol.flag == 1 && sol.odeResults.t(end) == 3)
assert(isequaln(sct0, GUILDA.config("TimeSimulation")), "Name-Value で GUILDA.setting が変わった")
% 厳しい許容誤差では刻みが細かくなり、応答はほぼ同じ
ref = net.simulate([0,3], ev);
assert(numel(sol.odeResults.t) > numel(ref.odeResults.t))
w1  = sol.odeResults.Bus(1).Component(1).X.omega;
w0  = ref.odeResults.Bus(1).Component(1).X.omega;
assert(abs(w1(end) - w0(end)) < 1e-4)
% GUILDA.setting の既定値は次の呼び出しから使われる (Solver も設定のキー)
c_cfg = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none", "Tolerance", 1e-5, "Solver", "ode23t"));
sol = net.simulate([0,1], ev);
assert(sol.options.Tolerance == 1e-5 && string(sol.options.Solver) == "ode23t")
clear c_cfg
% SolverOptions は呼び出し (またはシナリオの Options) だけ。既定は Solver の既定の options
assert(isempty(net.solver_ODE.get_options().SolverOptions))
sol = net.simulate([0,1], ev, SolverOptions=matlab.ode.options.ODE15s(MaxStep=0.01));
assert(max(diff(sol.odeResults.t)) <= 0.01 + 1e-12)
% 設定はプロパティではない (v3 の名前も互換なし)
assert(error_id(@() set_property(net.solver_ODE, "RelativeTolerance", 1e-5)) ~= "")
assert(error_id(@() set_property(net.solver_ODE, "Reporter", "none")) ~= "")
% Plot オプションは廃止 (図は result.Plot)、PlotFcn は "none" のみ
assert(error_id(@() net.simulate([0,1], ev, Plot=true)) == "GUILDA:resolve_options:UnknownName")
assert(error_id(@() net.simulate([0,1], ev, PlotFcn="omega")) == "GUILDA:check_plotfcn:InDevelopment")
% SeparateComplexParts は他の on/off の設定と同じ logical (ode には "on" / "off" で渡す)
assert(GUILDA.config("TimeSimulation", "SeparateComplexParts") == false)
sct_ode = net.solver_ODE.get_options({"SeparateComplexParts", true});
assert(islogical(sct_ode.SeparateComplexParts) && sct_ode.SeparateComplexParts)
assert(error_id(@() net.solver_ODE.get_options({"SeparateComplexParts", "maybe"})) ~= "")
sol = net.simulate([0,1], ev, SeparateComplexParts=true);
assert(sol.l_success && sol.options.SeparateComplexParts == true)
% Verbose: 区間の一覧と結果を表示する
str = evalc("net.simulate([0,3], ev, Verbose=true);");
assert(contains(str, "phase  1") && contains(str, "fault") && contains(str, "reached t = 3"))


%% TimeLimit stops the simulation with flag 0
% 計算時間が TimeLimit を超えると、その時刻までの結果と flag = 0 を返す
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[sol, flag, output] = net.simulate([0,5], ev, TimeLimit=1e-6);
assert(flag == 0 && sol.flag == 0 && ~sol.l_success)
assert(output.tEnd < 5 && sol.odeResults.t(end) == output.tEnd)
assert(output.nPhasesDone < output.nPhases)
assert(contains(output.message, "TimeLimit"))
% 結果は途中までの軌道として使える
assert(height(sol.odeResults.Bus(1).V) == numel(sol.odeResults.t))
% 既定値 (GUILDA.setting の TimeLimit) は変わらず、次の計算は最後まで進む
assert(GUILDA.config("TimeSimulation", "TimeLimit") ~= 1e-6)
[~, flag] = net.simulate([0,5], ev);
assert(flag == 1)


%% Deprecated option names still work
% COMPAT(v3): Name-Value の Reporter / RelativeTolerance は Progress / Tolerance に読み替え、警告を1回出す
clear Deprecated
lastwarn("");
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
evalc('sol = net.simulate([0,2], ev, Reporter="none", RelativeTolerance=1e-5);');
id = DebugScript.helper.msg_id();
assert(id == "GUILDA:Deprecated:SimulateOptionName", id)
assert(sol.options.Progress == "none" && sol.options.Tolerance == 1e-5)
assert(GUILDA.config("TimeSimulation", "Tolerance") ~= 1e-5)


%% Unknown option or misplaced argument stops with an error
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
try
    net.simulate([0,1], ev, Tolerence=1e-6);
    error("DebugScript:noError", "未知の名前でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:resolve_options:UnknownName", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "Tolerence") && contains(ME.message, "TimeLimit"))   % 使える名前を示す
end
% 不正な値
try
    net.simulate([0,1], ev, Progress="loud");
    error("DebugScript:noError", "不正な Progress でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) ~= "DebugScript:noError", ME.message)
end
% イベントは Name-Value の前に置く
try
    net.simulate([0,1], "Verbose", false, ev);
    error("DebugScript:noError", "Name-Value の後のイベントでエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:SimulateArguments", DebugScript.helper.msg_id(ME))
end
try
    net.simulate([0,1], ev, 3);
    error("DebugScript:noError", "イベントでも名前でもない引数でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:SimulateArguments", DebugScript.helper.msg_id(ME))
end


%% Plot and Export of the simulation result
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,2], ev);
c_fig = onCleanup(@() close(findall(0, "Type", "figure")));
ax = sol.Plot();
assert(isa(ax, "matlab.graphics.axis.Axes") && numel(ax.Children) == numel(net.a_Bus))
ax = sol.Plot(Quantity="omega", Bus=["B001","B002"]);
assert(numel(ax.Children) == 2)
ax = sol.Plot(Quantity="P", Bus="B008");
assert(numel(ax.Children) == 1)
try
    sol.Plot(Quantity="nosuchstate");
    error("DebugScript:noError", "未知の量でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultODE:UnknownQuantity", DebugScript.helper.msg_id(ME))
end
try
    sol.Plot(Bus="B999");
    error("DebugScript:noError", "未知の母線でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultODE:UnknownBus", DebugScript.helper.msg_id(ME))
end

s_dir = tempname;  mkdir(s_dir);
c_dir = onCleanup(@() rmdir(s_dir, "s"));
s_csv = sol.Export(fullfile(s_dir, "sim.csv"));
tab = readtable(s_csv, "VariableNamingRule", "preserve");
assert(height(tab) == numel(sol.odeResults.t))
sv  = string(tab.Properties.VariableNames);
assert(sv(1) == "t" && any(sv == "B001_Vreal") && any(sv == "B001SG1_omega") && any(sv == "B008_Q"))
assert(max(abs(tab.B001SG1_omega - sol.odeResults.Bus(1).Component(1).X.omega)) < 1e-10)
s_mat = sol.Export(fullfile(s_dir, "sim.mat"));
s = load(s_mat);
assert(isequal(s.odeResults.t, sol.odeResults.t) && s.flag == sol.flag)
try
    sol.Export(fullfile(s_dir, "sim.json"));
    error("DebugScript:noError", "未対応の拡張子でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultODE:ExportFormat", DebugScript.helper.msg_id(ME))
end
% simulate(..., Export=file) は result.Export を呼ぶ。図は描かない (図は result.Plot)
n_fig = numel(findall(0, "Type", "figure"));
net.simulate([0,1], ev, Export=fullfile(s_dir, "sim2.csv"));
assert(numel(findall(0, "Type", "figure")) == n_fig)
assert(isfile(fullfile(s_dir, "sim2.csv")))


%% Fault bus
% B008 で 1.00〜1.05 秒に地絡 (旧 Task7)
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

% 地絡中は故障母線の電圧が 0
lv = inwin(r.t, 1, 1.05);
assert(any(lv) && max(abs(r.Bus(8).V{lv,:}), [], "all") < 1e-8)

% 地絡前は平衡点、地絡で発電機の周波数が動き、除去後は電圧が戻る
assert(max(abs(r.Bus(1).Component(1).X.omega(r.t < 1))) < 1e-8)
assert(max(abs(r.Bus(1).Component(1).X.omega)) > 1e-4)
V8_end = r.Bus(8).V{end,:} * [1;1j];
assert(abs(abs(V8_end) - abs(net.a_Bus{8}.c_Vequilibrium)) < 0.05)


%% Trip generator
% 発電機 B002SG1 を 1.00〜1.05 秒に解列 (旧 Task8)
ev  = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.05], "TripUnit", "B002SG1");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;
X   = r.Bus(2).Component(1).X.Variables;

% 解列中の状態は NaN、再並列後は有限値
assert(all(isnan(X(inwin(r.t,1,1.05),:)), "all"))
assert(all(isfinite(X(r.t > 1.1,:)), "all"))
assert(all(isfinite(X(r.t < 1,:)), "all"))


%% Trip generator in a network with local controllers
% 局所制御器 (AVR) が付いた系統でも、解列した機器だけの状態が NaN になる
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.05], "TripUnit", "B002SG1");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;
lv  = inwin(r.t, 1, 1.05);
X2 = r.Bus(2).Component(1).X.Variables;
assert(all(isnan(X2(lv,:)), "all"))
for i = [1, 3, 6]
    Xi = r.Bus(i).Component(1).X.Variables;
    assert(all(isfinite(Xi), "all"), "解列していない機器 (母線 " + i + ") の状態が NaN")
end


%% Trip load
% 負荷 B003LPQ2 を 1.00〜1.05 秒に解列 → 母線 B003 の消費電力が減る
ev  = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.05], "TripUnit", "B003LPQ2");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

P3 = r.Bus(3).PQ.P;
lv = inwin(r.t, 1, 1.05);
assert(any(lv))
assert(min(P3(lv)) - P3(1) > 0.3, "負荷解列中も B003 の消費電力が減っていない")


%% Offset state at time zero
% 計算開始時に B001SG1 の内部位相 delta を 0.1 rad ずらす (旧 Task16)
gen = net.a_Bus{1}.a_Component{1};
ev  = DebugScript.helper.scenario("offset", net, "TimeSpan", 0, "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

delta = r.Bus(1).Component(1).X.delta;
assert(abs(delta(1) - (gen.rv_Xequilibrium(1) + 0.1)) < 1e-8)
assert(max(abs(r.Bus(1).Component(1).X.omega)) > 1e-5)


%% Offset state after time zero
% t = 1 秒で delta を 0.1 rad ずらす (旧 Task10 の ev1)
gen = net.a_Bus{1}.a_Component{1};
ev  = DebugScript.helper.scenario("offset", net, "TimeSpan", 1, "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

delta = r.Bus(1).Component(1).X.delta;
assert(max(abs(delta(r.t < 1) - gen.rv_Xequilibrium(1))) < 1e-8)
i1 = find(r.t > 1, 1);                         % 1 秒の直後の点
assert(abs(delta(i1) - (gen.rv_Xequilibrium(1) + 0.1)) < 1e-2, "t = 1 のオフセットが反映されていない")


%% Offset state during a trip
% 他の機器の解列中 (区間の初期値の再計算が必要な場合) にもオフセットが残る
os = DebugScript.helper.scenario("offset", net, "TimeSpan", 1.5, "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.1);
tr = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,2], "TripUnit", "B002SG1");
r  = net.simulate([0,3], os, tr).odeResults;
d  = r.Bus(1).Component(1).X.delta;
k  = find(abs(r.t - 1.5) < 1e-9);              % 1.5 秒の前後の区間の境界点 (2 点)
assert(numel(k) == 2 && abs(d(k(2)) - d(k(1)) - 0.1) < 1e-8, "解列中の t = 1.5 のオフセットが反映されていない")


%% Offset state is applied only once
% オフセットの期間が他のイベントで分割されても、オフセットは開始時刻に 1 回だけ加わる
% (分割用のイベントは入力 0 で、応答には影響しない)
os  = DebugScript.helper.scenario("offset", net, "TimeSpan", [1,3], "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.1);
cut = DebugScript.helper.scenario("cut", net, "TimeSpan", [2,2.5], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0);
r1  = net.simulate([0,4], os).odeResults;
r2  = net.simulate([0,4], os, cut).odeResults;
d1  = r1.Bus(1).Component(1).X.delta;
d2  = r2.Bus(1).Component(1).X.delta;
assert(abs(d2(end) - d1(end)) < 1e-3, "オフセットが分割された区間ごとに重ねて加わっている")


%% Input value numeric
% B002SG1 の機械入力 Pmech に 1〜3 秒の間 0.1 を加える
gen = net.a_Bus{2}.a_Component{1};
ev  = DebugScript.helper.scenario("input", net, "TimeSpan", [1,3], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

Pm  = r.Bus(2).Component(1).U.Pmech;
Pm0 = gen.rv_Uequilibrium(gen.sv_u == "Pmech");
assert(max(abs(Pm(inwin(r.t,1,3)) - (Pm0 + 0.1))) < 1e-8)
assert(max(abs(Pm(r.t > 3.01) - Pm0)) < 1e-8)
assert(max(abs(r.Bus(2).Component(1).X.omega)) > 1e-5)


%% Input value function handle
% 負荷 B002LPQ2 の Pload に時間関数を加える (旧 Task10 の ev3)
% 関数の引数 t はイベント開始からの経過時間
load2 = net.a_Bus{2}.a_Component{2};
ev  = DebugScript.helper.scenario("input", net, "TimeSpan", [1,3], "InputUnit", "B002LPQ2", ...
                  "InputName", ["Pload";"Qload"], "InputValue", {@(t) 0.1*t; @(t) 0});
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

U   = r.Bus(2).Component(2).U;
P0  = load2.rv_Uequilibrium(load2.sv_u == "Pload");
lv  = inwin(r.t, 1, 3);
assert(max(abs(U.Pload(lv) - (P0 + 0.1*(r.t(lv) - 1)))) < 1e-8)
assert(max(abs(U.Pload(r.t > 3.01) - P0)) < 1e-8)


%% Offset and input names in any order
% OffsetState / InputName は sv_x / sv_u と違う順に並べても名前で対応する
gen = net.a_Bus{1}.a_Component{1};
g2  = net.a_Bus{2}.a_Component{1};
os  = DebugScript.helper.scenario("offset", net, "TimeSpan", 0, "OffsetUnit", "B001SG1", "OffsetState", ["omega";"delta"], "OffsetValue", [0.01;0.1]);
in  = DebugScript.helper.scenario("input", net, "TimeSpan", [1,2], "InputUnit", "B002SG1", "InputName", ["Vfield";"Pmech"], "InputValue", [0.02;0.1]);
r   = net.simulate([0,2], os, in).odeResults;

X = r.Bus(1).Component(1).X;
assert(abs(X.delta(1) - (gen.rv_Xequilibrium(gen.sv_x == "delta") + 0.1)) < 1e-8)
assert(abs(X.omega(1) - (gen.rv_Xequilibrium(gen.sv_x == "omega") + 0.01)) < 1e-8)
U  = r.Bus(2).Component(1).U;
lv = inwin(r.t, 1, 2);
assert(max(abs(U.Pmech(lv)  - (g2.rv_Uequilibrium(g2.sv_u == "Pmech")  + 0.1)))  < 1e-8)
assert(max(abs(U.Vfield(lv) - (g2.rv_Uequilibrium(g2.sv_u == "Vfield") + 0.02))) < 1e-8)


%% Several events on the same unit
% 同じ機器への複数のオフセット・入力は足し合わされる
gen = net.a_Bus{1}.a_Component{1};
g2  = net.a_Bus{2}.a_Component{1};
o = cell(4,1);
o{1} = DebugScript.helper.scenario("os1", net, "TimeSpan", 0,     "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.05);
o{2} = DebugScript.helper.scenario("os2", net, "TimeSpan", 0,     "OffsetUnit", "B001SG1", "OffsetState", "delta", "OffsetValue", 0.05);
o{3} = DebugScript.helper.scenario("in1", net, "TimeSpan", [1,3], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0.1);
o{4} = DebugScript.helper.scenario("in2", net, "TimeSpan", [2,3], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", @(t) 0.05);
r = net.simulate([0,4], o{:}).odeResults;

assert(abs(r.Bus(1).Component(1).X.delta(1) - (gen.rv_Xequilibrium(gen.sv_x == "delta") + 0.1)) < 1e-8)
Pm  = r.Bus(2).Component(1).U.Pmech;
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
assert(max(abs(Pm(inwin(r.t,1,2)) - (Pm0 + 0.1)))  < 1e-8)
assert(max(abs(Pm(inwin(r.t,2,3)) - (Pm0 + 0.15))) < 1e-8)
assert(max(abs(Pm(r.t > 3.01) - Pm0)) < 1e-8)


%% Events beyond the simulation time
% 計算時間の外にはみ出すイベントで計算時間は変わらない。関数の引数はイベント開始からの経過時間のまま
g2  = net.a_Bus{2}.a_Component{1};
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
ev  = DebugScript.helper.scenario("input", net, "TimeSpan", [1,5], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", @(t) 0.1*t);

r = net.simulate([0,2], ev).odeResults;
assert(r.t(1) == 0 && r.t(end) == 2)

r = net.simulate([2,4], ev).odeResults;
assert(r.t(1) == 2 && r.t(end) == 4)
Pm = r.Bus(2).Component(1).U.Pmech;
assert(max(abs(Pm - (Pm0 + 0.1*(r.t - 1)))) < 1e-8)


%% Multiple events in one simulation
% 複数のイベントをまとめて渡す (旧 Task10 の構成を短縮)
o = cell(4,1);
o{1} = DebugScript.helper.scenario("ev1", net, "TimeSpan", 0,        "OffsetState", "delta", "OffsetUnit", "B001SG1", "OffsetValue", pi/36);
o{2} = DebugScript.helper.scenario("ev2", net, "TimeSpan", [1,1.5],  "InputUnit", "B002SG1", "InputName", ["Pmech";"Vfield"], "InputValue", {0.05; @(t) 0.01*t});
o{3} = DebugScript.helper.scenario("ev4", net, "TimeSpan", [2,2.02], "FaultBus", "B008");
o{4} = DebugScript.helper.scenario("ev5", net, "TimeSpan", [3,3.5],  "TripUnit", "B003LPQ2");
sol = net.simulate([0,5], o{:});
r   = sol.odeResults;

assert(r.t(end) == 5)
assert(max(abs(r.Bus(8).V{inwin(r.t,2,2.02),:}), [], "all") < 1e-8)
assert(all(isfinite(r.Bus(1).Component(1).X.Variables), "all"))


%% Simulate without events
% イベントを渡さなければ外乱なしの応答になるべき
sol = net.simulate([0,3]);
assert(sol.odeResults.t(end) == 3)
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)


%% Repeated simulation gives the same result
% 同じ net で続けて計算しても結果は変わらない (状態が残らない)
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
s1 = net.simulate([0,3], ev);
s2 = net.simulate([0,3], ev);
o1 = s1.odeResults.Bus(1).Component(1).X.omega;
o2 = s2.odeResults.Bus(1).Component(1).X.omega;
assert(isequal(size(o1), size(o2)) && max(abs(o1 - o2)) < 1e-10)


%% Shorter simulation after a longer one
% 区間数の少ない計算を後から行っても、前の計算の区間が結果に残らない
o1 = DebugScript.helper.scenario("f1", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
o2 = DebugScript.helper.scenario("f2", net, "TimeSpan", [2,2.05], "FaultBus", "B008");
net.simulate([0,3], o1, o2);
r = net.simulate([0,2], o1).odeResults;
assert(r.t(end) == 2 && all(diff(r.t) >= 0))


%% Fault with local controllers
% AVR + PSS を付けた系統での地絡応答 (旧 Task11 + Task12)
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{2}.a_Component{1}.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);

ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;
assert(r.t(end) == 5)

% AVR が動作して界磁電圧 Vfield (発電機の入力) が変化する
Vfd = r.Bus(1).Component(1).U.Vfield;
assert(max(Vfd) - min(Vfd) > 1e-3)
assert(all(isfinite(Vfd)))


%% AVR and PSS response is unchanged by name wiring
% 制御器の入出力を名前で接続するようにした (local_LQR の移植) 前と同じ応答になる。
% 値は変更前のコードで同じ条件のシミュレーションを実行して記録したもの (密行列の 189 点)。
% 疎行列では丸めの差で刻みが変わる (184 点) ので、点数は 2 割、値は 1e-3 の幅で比べる。
% 1e-3 は既定の許容誤差 (相対 1e-4) での誤差に対応する: 疎と記録値の差は最大 2.3e-4、
% Tolerance=1e-10 の解に対する誤差は記録値で最大 2.5e-4、疎で最大 4.8e-4
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{2}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{3}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sol = net.simulate([0,3], DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008"));
r   = sol.odeResults;
assert(abs(numel(r.t) - 189) <= 0.2*189, "steps: " + numel(r.t))
x_ref = [1.21546465440074; 0.000417344321429537; 0.894219545365634; 0.244739185785292; -0.982794522565431; 0.381301677046273];
u_ref = [2.31453097771137; 1.17969105725771];
V_ref = [1.06196892490977; -0.233592359118239];
assert(norm(r.Bus(1).Component(1).X{end,:}' - x_ref) < 1e-3)
assert(norm(r.Bus(1).Component(1).U{end,:}' - u_ref) < 1e-3)
assert(norm(r.Bus(8).V{end,:}' - V_ref) < 1e-3)


%% Fault with LQR
% 状態フィードバックの LQR を付けた系統の地絡応答: 平衡点は保たれ、事故後の動揺は LQR 無しより小さい
net = DebugScript.helper.build_ieee14();
lqr1 = net.a_Bus{1}.a_Component{1}.add_local_controller("local-LQR");
net.a_Bus{6}.a_Component{1}.add_local_controller("local-LQR", parameter=struct(Input="Vfield"));
DebugScript.helper.quiet(@() net.initialize);

sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)

ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
r   = net.simulate([0,10], ev).odeResults;
assert(r.t(end) == 10)
w   = r.Bus(1).Component(1).X.omega;

% LQR の出力が発電機の入力 (Pmech, Vfield) になる
U   = r.Bus(1).Component(1).U;
x   = r.Bus(1).Component(1).X{:,:}';
gen = net.a_Bus{1}.a_Component{1};
u   = gen.rv_Uequilibrium - lqr1.K * (x - gen.rv_Xequilibrium);
assert(max(abs(U{:,:}' - u), [], "all") < 1e-6)

net0 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net0.initialize);
r0  = net0.simulate([0,10], DebugScript.helper.scenario("fault", net0, "TimeSpan", [1,1.05], "FaultBus", "B008")).odeResults;
w0  = r0.Bus(1).Component(1).X.omega;
assert(max(abs(w(r.t > 8))) < max(abs(w0(r0.t > 8))))


%% Load step with global controller
% AGC 付き系統で負荷を増やす (旧 Task13 + Task14)
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);

ev  = DebugScript.helper.scenario("step", net, "TimeSpan", [1,20], "InputUnit", "B005LPQ1", "InputName", "Pload", "InputValue", -0.1);
sol = net.simulate([0,20], ev);
r   = sol.odeResults;

% AGC が発電機の機械入力を増やし、周波数偏差を 0 に戻す
omega = r.Bus(1).Component(1).X.omega;
Pm    = r.Bus(1).Component(1).U.Pmech;
assert(max(abs(omega)) > 1e-4)
assert(abs(omega(end)) < 1e-4)
assert(Pm(end) > Pm(1))

% 比較: AGC なしでは周波数偏差が残る
net0 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net0.initialize);
ev0  = DebugScript.helper.scenario("step", net0, "TimeSpan", [1,20], "InputUnit", "B005LPQ1", "InputName", "Pload", "InputValue", -0.1);
r0   = net0.simulate([0,20], ev0).odeResults;
assert(abs(r0.Bus(1).Component(1).X.omega(end)) > 10*abs(omega(end)))


%% Tripped global controller gives no output
% 大域制御器を解列すると、解列中の出力は 0 (機器の入力は定常値のまま)
net = DebugScript.helper.build_ieee14();
agc = net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"], parameter=struct(kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);

ev1 = DebugScript.helper.scenario("step", net, "TimeSpan", [1,20], "InputUnit", "B005LPQ1", "InputName", "Pload", "InputValue", -0.1);
ev2 = DebugScript.helper.scenario("trip", net, "TimeSpan", [5,10], "TripUnit", agc.s_tag);
sol = net.simulate([0,20], ev1, ev2);
r   = sol.odeResults;
Pm  = r.Bus(1).Component(1).U.Pmech;
lv  = inwin(r.t, 5, 10);
assert(any(lv))
assert(max(abs(Pm(lv) - Pm(1))) < 1e-8, "解列した AGC の出力 (比例項) が機器の入力に加わっている")
assert(max(abs(Pm(inwin(r.t, 1, 5)) - Pm(1))) > 1e-3)    % 解列前は AGC が働く
assert(~isprop(agc, "l_isConnect"), "解列の状態はモデルに書かない (SolverODE の ctx)")


%% Two global controllers act together
% 大域制御器は何台でも扱える。同じ発電機を alpha を半分ずつにした 2 台の AGC で制御すると、
% 出力の和が 1 台の AGC と等しいので、同じ応答になる
net1 = DebugScript.helper.build_ieee14();
net1.add_global_controller("agc-PI", ["B001SG1", "B002SG1"], parameter=struct(alpha=[1;1], kP=100, kI=500));
net2 = DebugScript.helper.build_ieee14();
net2.add_global_controller("agc-PI", ["B001SG1", "B002SG1"], parameter=struct(alpha=[0.5;0.5], kP=100, kI=500));
net2.add_global_controller("agc-PI", ["B001SG1", "B002SG1"], parameter=struct(alpha=[0.5;0.5], kP=100, kI=500));
DebugScript.helper.quiet(@() net1.initialize);
DebugScript.helper.quiet(@() net2.initialize);

% 外乱なしでは平衡点に留まる
sol = net2.simulate([0,2], DebugScript.helper.noop_event(net2,[0,2]));
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)

% 負荷を増やしたときの応答が 1 台の場合と一致し、周波数偏差が 0 に戻る
r1 = net1.simulate([0,20], DebugScript.helper.scenario("step", net1, "TimeSpan", [1,20], "InputUnit", "B005LPQ1", "InputName", "Pload", "InputValue", -0.1)).odeResults;
r2 = net2.simulate([0,20], DebugScript.helper.scenario("step", net2, "TimeSpan", [1,20], "InputUnit", "B005LPQ1", "InputName", "Pload", "InputValue", -0.1)).odeResults;
t  = linspace(0, 20, 401)';
[t1, i1] = unique(r1.t);
[t2, i2] = unique(r2.t);
for name = ["omega", "Pmech"]
    if name == "omega"
        y1 = r1.Bus(1).Component(1).X.omega;  y2 = r2.Bus(1).Component(1).X.omega;
    else
        y1 = r1.Bus(1).Component(1).U.Pmech;  y2 = r2.Bus(1).Component(1).U.Pmech;
    end
    y1 = interp1(t1, y1(i1), t);
    y2 = interp1(t2, y2(i2), t);
    assert(max(abs(y1 - y2)) < 1e-2 * max(abs(y1 - y1(1))), name + ": 2 台の AGC の応答が 1 台の場合と一致しない")
end
assert(abs(r2.Bus(1).Component(1).X.omega(end)) < 1e-4)


%% Network Hz sets the rotor angle dynamics
% 系統の周波数 (net.tab_parameter.base.Hz) が発電機の d(delta)/dt = 2*pi*Hz*omega に使われる。
% omega をずらして始めると、短時間の delta の変化は Hz に比例する (50 Hz / 60 Hz)
ddelta = zeros(1,2);
sv_Hz  = [50, 60];
for k = 1:2
    [net, gen] = DebugScript.helper.build_3bus("gen-classical");
    net.tab_parameter.base.Hz = sv_Hz(k);
    DebugScript.helper.quiet(@() net.initialize);
    i_bus = find(cellfun(@(b) b == gen.a_Bus, net.a_Bus));
    ev  = DebugScript.helper.scenario("offset", net, "TimeSpan", 0, "OffsetUnit", string(gen), "OffsetState", "omega", "OffsetValue", 1e-3);
    r   = net.simulate([0,0.02], ev).odeResults;
    X   = r.Bus(i_bus).Component(1).X;
    ddelta(k) = interp1(r.t, X.delta, 0.01) - X.delta(1);
end
assert(all(ddelta > 0))
assert(abs(ddelta(1)/ddelta(2) - 50/60) < 1e-2, "delta の変化の比 " + ddelta(1)/ddelta(2) + " が 50/60 にならない")
% 1e-3 の omega で 0.01 秒 → 2*pi*60*1e-3*0.01 ≈ 3.8e-3 rad
assert(abs(ddelta(2) - 2*pi*60*1e-3*0.01) < 0.1 * 2*pi*60*1e-3*0.01)


%% Event input names are checked
% 存在しない InputUnit / InputName、引数の数が違う関数ハンドルは計算前にエラー
expect_error(@() DebugScript.helper.scenario("in", net, "TimeSpan", [1,2], "InputUnit", "B002LPQ2", "InputName", ["P";"Q"], "InputValue", 0.1), "GUILDA:Scenario:UnknownInputName")
expect_error(@() DebugScript.helper.scenario("in", net, "TimeSpan", [1,2], "InputUnit", "NoSuchUnit", "InputName", "Pload", "InputValue", 0.1), "GUILDA:Scenario:UnknownInputUnit")
expect_error(@() DebugScript.helper.scenario("in", net, "TimeSpan", [1,2], "InputUnit", "B002LPQ2", "InputName", "Pload", "InputValue", @(t,x) 0.1), "GUILDA:Scenario:InvalidNargin")


%% Phase that starts at rest in a large network
% 平衡点から始まる区間で、ode15s のニュートン修正量が丸め誤差だけになると発散と誤判定され、
% IEEE68bus (AVR/PSS なし) は t = 0 で止まっていた ([0,1] の区間で起きる)。
% 何もしないイベントで区間を分けても最後まで進み、平衡点に留まる
net = DebugScript.helper.quiet(@() network.IEEE68bus(LocalController=false));
DebugScript.helper.quiet(@() net.initialize);

[sol, flag, output] = net.simulate([0,5], DebugScript.helper.scenario("none", net, "TimeSpan", 1));
assert(flag == 1, output.message)
assert(output.nPhases == 2)
assert(DebugScript.helper.max_state_drift(sol) < 1e-8)
% 地絡の後の区間も計算できる
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B030");
[~, flag, output] = net.simulate([0,2], ev, TimeLimit=Inf);
assert(flag == 1, output.message)


%% Solver stop reports the phase and the solver message
% 入力が t = 2.5 (イベント開始から 1.5 s) で発散するとソルバーが止まる (flag = -1)。
% output.message は止まった区間・時刻とソルバーの警告文を示す
ev = DebugScript.helper.scenario("in", net, "TimeSpan", [1,3], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", @(t) 1/(1.5-t));
lastwarn("");
[~, flag, output] = net.solver_ODE.solve(net, [0,4], {ev}, net.solver_ODE.get_options({}));   % net.simulate の警告で lastwarn が変わらない
s_warn = lastwarn();
assert(flag == -1)
assert(output.tEnd > 1 && output.tEnd < 2.5)
assert(contains(output.message, "phase 2") && contains(output.message, "t = [1, 3]"), output.message)
assert(strlength(s_warn) > 0 && contains(output.message, s_warn), output.message)

% 計算中のエラーは区間を示す GUILDA のエラーになり、元のエラーは cause に残る
ev = DebugScript.helper.scenario("in", net, "TimeSpan", [1,3], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", @(t) boom(t));
try
    net.simulate([0,4], ev);
    error("DebugScript:noError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:PhaseFailed", DebugScript.helper.msg_id(ME) + ": " + ME.message)
    assert(contains(ME.message, "phase 2") && contains(ME.message, "t = [1, 3]") && contains(ME.message, "boom"), ME.message)
    assert(DebugScript.helper.msg_id(ME.cause{1}) == "DebugScript:boom")
end


%% Differential states are continuous at the phase boundaries
% 区間の境界で微分状態 (質量行列が掛かる状態) は直前の値のまま、代数変数 (母線電圧、
% 代数状態、入力) だけを新しい区間の網で解き直す。地絡の始まりと終わり、負荷の解列を確かめる
ev1 = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
ev2 = DebugScript.helper.scenario("trip",  net, "TimeSpan", [1.5,1.7], "TripUnit", "B003LPQ2");
[sol, flag, output] = net.simulate([0,2], ev1, ev2);
assert(flag == 1, output.message)
[d_x, d_v] = boundary_jumps(net, sol);
assert(numel(d_x) == 4 && all(d_x == 0), "微分状態の跳び " + mat2str(d_x))
assert(d_v(1) > 1e-2, "地絡の始まりで電圧が解き直されていない")


%% Fault in IEEJ WEST10 keeps the rotor angles
% IEEJ WEST10 (AVR の質量行列が対角でない) の B003 の地絡は、Tolerance 1e-6 では初期条件の
% 計算が微分状態を固定できず、G1 の delta が地絡の直前に 1.5156 から 1.8073 へ跳んでいた
% (当時は警告 InitialConditionRelaxed を出すだけで結果は誤り。その警告は bf7512b で削除)。
% どの Tolerance でも跳ばず、警告も出ない
net = DebugScript.helper.quiet(@() network.IEEJ_WEST10(Section="peak"));
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.1,0.17], "FaultBus", "B003");
for tol = [1e-4, 1e-6]
    lastwarn("");
    [sol, flag, output] = net.simulate([0,1], ev, Progress="none", Tolerance=tol, AbsoluteTolerance=1e-8);
    assert(flag == 1, output.message)
    assert(isempty(lastwarn()), lastwarn())
    [d_x, d_v] = boundary_jumps(net, sol);
    assert(numel(d_x) == 2 && all(d_x == 0), "微分状態の跳び " + mat2str(d_x))
    assert(all(d_v > 1e-2), "代数変数が解き直されていない " + mat2str(d_v))
end


%% IEEJ WEST10 starts from its equilibrium for any time span
% 以前は ode15s 自身の初期条件の計算 (疎で対角でない質量行列の daeic3) が区間の長さに
% よって失敗し、[0,5] や [0,10] が既定の許容誤差で t = 0 で止まった
net = DebugScript.helper.quiet(@() network.IEEJ_WEST10(Section="peak"));
for t_end = [1, 10]
    for atol = [1e-4, 1e-6, 1e-8]
        [sol, flag, output] = net.simulate([0,t_end], Progress="none", AbsoluteTolerance=atol);
        assert(flag == 1, output.message)
        assert(sol.rv_t(end) == t_end)
    end
end


%% Event outside the simulation time warns
ev = DebugScript.helper.scenario("late", net, "TimeSpan", [5,6], "FaultBus", "B008");
lastwarn("");
[~, flag] = net.simulate([0,1], ev);
id = DebugScript.helper.msg_id();
assert(id == "GUILDA:Scenario:OutsideTimeSpan")
assert(flag == 1)


% ---- local functions ----
function u = boom(t)
    if t > 0.5
        error("DebugScript:boom", "boom at t = %g", t)
    end
    u = 0;
end

function [d_x, d_v] = boundary_jumps(net, sol)
% 区間の各境界 (時刻が 2 回現れる行) での、微分状態と母線電圧の最大の変化
% 解列中の機器 (NaN) の状態は除く。微分状態は機器・制御器の質量行列の非零の列
    lv_dif = false(height(sol.tab_variable), 1);
    c_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);
    c_model = {};
    for i = 1:numel(c_comp)
        for j = 1:numel(c_comp{i})
            m = c_comp{i}{j};
            while true
                c_model{end+1} = m; %#ok<AGROW>
                if isempty(m.a_LocalController); break; end
                m = m.a_LocalController{1};
            end
        end
    end
    c_model = [c_model, reshape(net.a_GlobalController, 1, [])];
    for k = 1:numel(c_model)
        m = c_model{k};
        if isempty(m.sv_x); continue; end
        sv_dif = m.sv_x(any(tools.read_mass(m) ~= 0, 1));
        lv_dif = lv_dif | (sol.tab_variable.Kind == "x" & sol.tab_variable.Owner == string(m) ...
                           & ismember(sol.tab_variable.Name, sv_dif));
    end
    lv_v = ismember(sol.tab_variable.Kind, ["Vre","Vim"]);
    iv_b = find(diff(sol.rv_t) == 0);
    d_x = zeros(1, numel(iv_b));
    d_v = zeros(1, numel(iv_b));
    for k = 1:numel(iv_b)
        X = sol.rm_variable(iv_b(k) + [0,1], :);
        d_x(k) = max([0, abs(diff(X(:, lv_dif)))], [], "omitnan");
        d_v(k) = max([0, abs(diff(X(:, lv_v)))], [], "omitnan");
    end
end

function set_property(obj, s_name, val)
    obj.(s_name) = val;
end

function expect_error(f, s_id)
    try
        f();
        error("DebugScript:noError", "エラーにならない (期待: " + s_id + ")")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == s_id, DebugScript.helper.msg_id(ME) + ": " + ME.message)
    end
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
