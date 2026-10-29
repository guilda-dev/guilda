% F6 時間応答シミュレーション (simulate / odeEventSet / odeSimulationResult)
%
% イベントの種類ごとに IEEE14 母線系統の応答を計算し、結果を確認する。
%   ev  = odeEventSet("名前", net, "TimeSpan", [t1,t2], <イベントの指定>);
%   [sol, flag, output] = net.simulate([t0,tend], ev1, ev2, ..., Name, Value);
%   r   = sol.odeResults;     % r.t, r.Bus(i).V / I / PQ, r.Bus(i).Component(j).X / U
%
%   FaultBus   : 母線の地絡 (電圧 0)
%   TripUnit   : 機器の解列
%   OffsetState: 状態の初期値のずらし
%   InputValue : 機器入力への加算 (数値 / 関数ハンドル)
%
%   flag: 1 = 終了時刻まで計算, 0 = TimeLimit で停止, -1 = ソルバーが途中で停止
%   Name-Value (odeSimulator.OptionMap): Solver, SolverOptions, Tolerance, AbsoluteTolerance,
%   SeparateComplexParts, TimeLimit, Progress, Verbose, Plot (+ Export)。その呼び出しだけ有効
%
% 実行: runtests("DebugScript.test_F6_simulation")  または  DebugScript.run_all("Features","F6")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();       % 進捗表示なし (Progress = "none")
DebugScript.helper.quiet(@() net.initialize);
inwin = @(t, t1, t2) t > t1 + 1e-3 & t < t2 - 1e-3;   % 区間の内側 (境界の重複点を除く)


%% Simulation result structure
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,3], ev);
assert(isa(sol, "odeSimulationResult"))

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


%% V4 call returns result flag and output
% [result, flag, output] を返す。結果クラスは AnalysisResult を継承し、flag / output / 使った設定を持つ
ev = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[sol, flag, output] = net.simulate([0,3], ev);
assert(isa(sol, "odeSimulationResult") && isa(sol, "AnalysisResult"))
assert(flag == 1 && sol.flag == 1 && sol.l_success)
assert(isequal(sol.output, output) && output.tEnd == 3 && output.nPhases == 3 && output.nPhasesDone == 3)
assert(isstring(output.message) && contains(output.message, "t = 3"))
assert(istable(output.phases) && height(output.phases) == 3)
assert(sol.str_solver == "odeSimulator" && sol.str_network == string(net.str_tag) && sol.r_elapsed > 0)
assert(sol.options.RelativeTolerance == net.solver_ODE.RelativeTolerance)
assert(sol.options.Progress == "none" && sol.options.TimeLimit == net.solver_ODE.TimeLimit)
assert(isequal(sol.sv_bus, string(net.a_Bus(:))) && numel(sol.c_component) == numel(net.a_Bus))
assert(sol.c_component{1}(1) == string(net.a_Bus{1}.a_Component{1}))
% モデルのデータは複製しない (未使用だった odeNetwork は廃止)
assert(~isprop(sol, "odeNetwork"))
% ソルバーは設定だけを持つ (系統・時間表・結果を保持しない)
assert(~isprop(net.solver_ODE, "odeNetwork") && ~isprop(net.solver_ODE, "odeTimeTable") && ~isprop(net.solver_ODE, "odeResult"))


%% Name-Value overrides leave solver_ODE unchanged
% Name-Value はその呼び出しだけ有効。net.solver_ODE の値は変わらない
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
s0  = net.solver_ODE;
c0  = {s0.RelativeTolerance, s0.AbsoluteTolerance, s0.TimeLimit, s0.Progress, s0.Verbose, s0.Plot, string(s0.Solver)};
sol = net.simulate([0,3], ev, Tolerance=1e-6, AbsoluteTolerance=1e-8, TimeLimit=Inf, Progress=false, Solver="ode23t");
assert(sol.options.RelativeTolerance == 1e-6 && sol.options.AbsoluteTolerance == 1e-8)
assert(isinf(sol.options.TimeLimit) && sol.options.Progress == "none" && string(sol.options.Solver) == "ode23t")
assert(sol.flag == 1 && sol.odeResults.t(end) == 3)
c1  = {s0.RelativeTolerance, s0.AbsoluteTolerance, s0.TimeLimit, s0.Progress, s0.Verbose, s0.Plot, string(s0.Solver)};
assert(isequal(c0, c1), "Name-Value で net.solver_ODE が変わった")
% 厳しい許容誤差では刻みが細かくなり、応答はほぼ同じ
ref = net.simulate([0,3], ev);
assert(numel(sol.odeResults.t) > numel(ref.odeResults.t))
w1  = sol.odeResults.Bus(1).Component(1).X.omega;
w0  = ref.odeResults.Bus(1).Component(1).X.omega;
assert(abs(w1(end) - w0(end)) < 1e-4)
% 保存された既定値の変更は次の呼び出しから使われる (net は他のテストと共有なので戻す)
net.solver_ODE.RelativeTolerance = 1e-5;
c_rel = onCleanup(@() set_property(net.solver_ODE, "RelativeTolerance", c0{1}));
sol = net.simulate([0,1], ev);
assert(sol.options.RelativeTolerance == 1e-5)
% Verbose: 区間の一覧と結果を表示する
str = evalc("net.simulate([0,3], ev, Verbose=true);");
assert(contains(str, "phase  1") && contains(str, "fault") && contains(str, "reached t = 3"))


%% TimeLimit stops the simulation with flag 0
% 計算時間が TimeLimit を超えると、その時刻までの結果と flag = 0 を返す
ev = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[sol, flag, output] = net.simulate([0,5], ev, TimeLimit=1e-6);
assert(flag == 0 && sol.flag == 0 && ~sol.l_success)
assert(output.tEnd < 5 && sol.odeResults.t(end) == output.tEnd)
assert(output.nPhasesDone < output.nPhases)
assert(contains(output.message, "TimeLimit"))
% 結果は途中までの軌道として使える
assert(height(sol.odeResults.Bus(1).V) == numel(sol.odeResults.t))
% 既定値 (net.solver_ODE.TimeLimit) は変わらず、次の計算は最後まで進む
assert(net.solver_ODE.TimeLimit ~= 1e-6)
[~, flag] = net.simulate([0,5], ev);
assert(flag == 1)


%% Deprecated Reporter and option names still work
% COMPAT(v3): solver_ODE.Reporter は Progress、Name-Value の Reporter / RelativeTolerance は
% Progress / Tolerance に読み替え、警告を1回出す
clear Deprecated
lastwarn("");
evalc('net.solver_ODE.Reporter = "disp";');
[~, id] = lastwarn;
assert(id == "GUILDA:Deprecated:SimulatorReporter", id)
assert(net.solver_ODE.Progress == "disp" && net.solver_ODE.Reporter == "disp")
net.solver_ODE.Progress = "none";

lastwarn("");
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
evalc('sol = net.simulate([0,2], ev, Reporter="none", RelativeTolerance=1e-5);');
[~, id] = lastwarn;
assert(id == "GUILDA:Deprecated:SimulateOptionName", id)
assert(sol.options.Progress == "none" && sol.options.RelativeTolerance == 1e-5)
assert(net.solver_ODE.RelativeTolerance ~= 1e-5)


%% Unknown option or misplaced argument stops with an error
ev = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
try
    net.simulate([0,1], ev, Tolerence=1e-6);
    error("DebugScript:noError", "未知の名前でエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:resolve_options:UnknownName", ME.identifier)
    assert(contains(ME.message, "Tolerence") && contains(ME.message, "TimeLimit"))   % 使える名前を示す
end
% 不正な値
try
    net.simulate([0,1], ev, Progress="loud");
    error("DebugScript:noError", "不正な Progress でエラーにならない")
catch ME
    assert(ME.identifier ~= "DebugScript:noError", ME.message)
end
% イベントは Name-Value の前に置く
try
    net.simulate([0,1], "Verbose", false, ev);
    error("DebugScript:noError", "Name-Value の後のイベントでエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:PowerNetwork:SimulateArguments", ME.identifier)
end
try
    net.simulate([0,1], ev, 3);
    error("DebugScript:noError", "イベントでも名前でもない引数でエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:PowerNetwork:SimulateArguments", ME.identifier)
end


%% Plot and Export of the simulation result
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
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
    assert(ME.identifier == "GUILDA:odeSimulationResult:UnknownQuantity", ME.identifier)
end
try
    sol.Plot(Bus="B999");
    error("DebugScript:noError", "未知の母線でエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:odeSimulationResult:UnknownBus", ME.identifier)
end

str_dir = tempname;  mkdir(str_dir);
c_dir = onCleanup(@() rmdir(str_dir, "s"));
str_csv = sol.Export(fullfile(str_dir, "sim.csv"));
tab = readtable(str_csv, "VariableNamingRule", "preserve");
assert(height(tab) == numel(sol.odeResults.t))
sv  = string(tab.Properties.VariableNames);
assert(sv(1) == "t" && any(sv == "B001_Vreal") && any(sv == "SG1B001_omega") && any(sv == "B008_Q"))
assert(max(abs(tab.SG1B001_omega - sol.odeResults.Bus(1).Component(1).X.omega)) < 1e-10)
str_mat = sol.Export(fullfile(str_dir, "sim.mat"));
s = load(str_mat);
assert(isequal(s.odeResults.t, sol.odeResults.t) && s.flag == sol.flag)
try
    sol.Export(fullfile(str_dir, "sim.json"));
    error("DebugScript:noError", "未対応の拡張子でエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:odeSimulationResult:ExportFormat", ME.identifier)
end
% simulate(..., Plot=true, Export=file) は結果のメソッドを呼ぶ
n_fig = numel(findall(0, "Type", "figure"));
net.simulate([0,1], ev, Plot=true, Export=fullfile(str_dir, "sim2.csv"));
assert(numel(findall(0, "Type", "figure")) == n_fig + 1)
assert(isfile(fullfile(str_dir, "sim2.csv")))


%% Fault bus
% B008 で 1.00〜1.05 秒に地絡 (旧 Task7)
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
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
% 発電機 SG1B002 を 1.00〜1.05 秒に解列 (旧 Task8)
ev  = odeEventSet("trip", net, "TimeSpan", [1,1.05], "TripUnit", "SG1B002");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;
X   = r.Bus(2).Component(1).X.Variables;

% 解列中の状態は NaN、再並列後は有限値
assert(all(isnan(X(inwin(r.t,1,1.05),:)), "all"))
assert(all(isfinite(X(r.t > 1.1,:)), "all"))
assert(all(isfinite(X(r.t < 1,:)), "all"))


%% Trip load
% 負荷 LPQ2B003 を 1.00〜1.05 秒に解列 → 母線 B003 の消費電力が減る
ev  = odeEventSet("trip", net, "TimeSpan", [1,1.05], "TripUnit", "LPQ2B003");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

P3 = r.Bus(3).PQ.P;
lv = inwin(r.t, 1, 1.05);
assert(any(lv))
assert(min(P3(lv)) - P3(1) > 0.3, "負荷解列中も B003 の消費電力が減っていない")


%% Offset state at time zero
% 計算開始時に SG1B001 の内部位相 delta を 0.1 rad ずらす (旧 Task16)
gen = net.a_Bus{1}.a_Component{1};
ev  = odeEventSet("offset", net, "TimeSpan", 0, "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

delta = r.Bus(1).Component(1).X.delta;
assert(abs(delta(1) - (gen.rv_Xequilibrium(1) + 0.1)) < 1e-8)
assert(max(abs(r.Bus(1).Component(1).X.omega)) > 1e-5)


%% Offset state after time zero
% t = 1 秒で delta を 0.1 rad ずらす (旧 Task10 の ev1)
gen = net.a_Bus{1}.a_Component{1};
ev  = odeEventSet("offset", net, "TimeSpan", 1, "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

delta = r.Bus(1).Component(1).X.delta;
assert(max(abs(delta(r.t < 1) - gen.rv_Xequilibrium(1))) < 1e-8)
i1 = find(r.t > 1, 1);                         % 1 秒の直後の点
assert(abs(delta(i1) - (gen.rv_Xequilibrium(1) + 0.1)) < 1e-2, "t = 1 のオフセットが反映されていない")


%% Offset state during a trip
% 他の機器の解列中 (区間の初期値の再計算が必要な場合) にもオフセットが残る
os = odeEventSet("offset", net, "TimeSpan", 1.5, "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
tr = odeEventSet("trip", net, "TimeSpan", [1,2], "TripUnit", "SG1B002");
r  = net.simulate([0,3], os, tr).odeResults;
d  = r.Bus(1).Component(1).X.delta;
k  = find(abs(r.t - 1.5) < 1e-9);              % 1.5 秒の前後の区間の境界点 (2 点)
assert(numel(k) == 2 && abs(d(k(2)) - d(k(1)) - 0.1) < 1e-8, "解列中の t = 1.5 のオフセットが反映されていない")


%% Offset state is applied only once
% オフセットの期間が他のイベントで分割されても、オフセットは開始時刻に 1 回だけ加わる
% (分割用のイベントは入力 0 で、応答には影響しない)
os  = odeEventSet("offset", net, "TimeSpan", [1,3], "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
cut = odeEventSet("cut", net, "TimeSpan", [2,2.5], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0);
r1  = net.simulate([0,4], os).odeResults;
r2  = net.simulate([0,4], os, cut).odeResults;
d1  = r1.Bus(1).Component(1).X.delta;
d2  = r2.Bus(1).Component(1).X.delta;
assert(abs(d2(end) - d1(end)) < 1e-3, "オフセットが分割された区間ごとに重ねて加わっている")


%% Input value numeric
% SG1B002 の機械入力 Pmech に 1〜3 秒の間 0.1 を加える
gen = net.a_Bus{2}.a_Component{1};
ev  = odeEventSet("input", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

Pm  = r.Bus(2).Component(1).U.Pmech;
Pm0 = gen.rv_Uequilibrium(gen.sv_u == "Pmech");
assert(max(abs(Pm(inwin(r.t,1,3)) - (Pm0 + 0.1))) < 1e-8)
assert(max(abs(Pm(r.t > 3.01) - Pm0)) < 1e-8)
assert(max(abs(r.Bus(2).Component(1).X.omega)) > 1e-5)


%% Input value function handle
% 負荷 LPQ2B002 の Pload に時間関数を加える (旧 Task10 の ev3)
% 関数の引数 t はイベント開始からの経過時間
load2 = net.a_Bus{2}.a_Component{2};
ev  = odeEventSet("input", net, "TimeSpan", [1,3], "InputUnit", "LPQ2B002", ...
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
os  = odeEventSet("offset", net, "TimeSpan", 0, "OffsetUnit", "SG1B001", "OffsetState", ["omega";"delta"], "OffsetValue", [0.01;0.1]);
in  = odeEventSet("input", net, "TimeSpan", [1,2], "InputUnit", "SG1B002", "InputName", ["Vfield";"Pmech"], "InputValue", [0.02;0.1]);
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
o{1} = odeEventSet("os1", net, "TimeSpan", 0,     "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.05);
o{2} = odeEventSet("os2", net, "TimeSpan", 0,     "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.05);
o{3} = odeEventSet("in1", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.1);
o{4} = odeEventSet("in2", net, "TimeSpan", [2,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) 0.05);
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
ev  = odeEventSet("input", net, "TimeSpan", [1,5], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) 0.1*t);

r = net.simulate([0,2], ev).odeResults;
assert(r.t(1) == 0 && r.t(end) == 2)

r = net.simulate([2,4], ev).odeResults;
assert(r.t(1) == 2 && r.t(end) == 4)
Pm = r.Bus(2).Component(1).U.Pmech;
assert(max(abs(Pm - (Pm0 + 0.1*(r.t - 1)))) < 1e-8)


%% Multiple events in one simulation
% 複数のイベントをまとめて渡す (旧 Task10 の構成を短縮)
o = cell(4,1);
o{1} = odeEventSet("ev1", net, "TimeSpan", 0,        "OffsetState", "delta", "OffsetUnit", "SG1B001", "OffsetValue", pi/36);
o{2} = odeEventSet("ev2", net, "TimeSpan", [1,1.5],  "InputUnit", "SG1B002", "InputName", ["Pmech";"Vfield"], "InputValue", {0.05; @(t) 0.01*t});
o{3} = odeEventSet("ev4", net, "TimeSpan", [2,2.02], "FaultBus", "B008");
o{4} = odeEventSet("ev5", net, "TimeSpan", [3,3.5],  "TripUnit", "LPQ2B003");
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
ev = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
s1 = net.simulate([0,3], ev);
s2 = net.simulate([0,3], ev);
o1 = s1.odeResults.Bus(1).Component(1).X.omega;
o2 = s2.odeResults.Bus(1).Component(1).X.omega;
assert(isequal(size(o1), size(o2)) && max(abs(o1 - o2)) < 1e-10)


%% Shorter simulation after a longer one
% 区間数の少ない計算を後から行っても、前の計算の区間が結果に残らない
o1 = odeEventSet("f1", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
o2 = odeEventSet("f2", net, "TimeSpan", [2,2.05], "FaultBus", "B008");
net.simulate([0,3], o1, o2);
r = net.simulate([0,2], o1).odeResults;
assert(r.t(end) == 2 && all(diff(r.t) >= 0))


%% Fault with local controllers
% AVR + PSS を付けた系統での地絡応答 (旧 Task11 + Task12)
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr2"), controller.pss.PSS1("pss2"));
DebugScript.helper.quiet(@() net.initialize);

ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;
assert(r.t(end) == 5)

% AVR が動作して界磁電圧 Vfield (発電機の入力) が変化する
Vfd = r.Bus(1).Component(1).U.Vfield;
assert(max(Vfd) - min(Vfd) > 1e-3)
assert(all(isfinite(Vfd)))


%% Load step with global controller
% AGC 付き系統で負荷を増やす (旧 Task13 + Task14)
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);

ev  = odeEventSet("step", net, "TimeSpan", [1,20], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", -0.1);
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
ev0  = odeEventSet("step", net0, "TimeSpan", [1,20], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", -0.1);
r0   = net0.simulate([0,20], ev0).odeResults;
assert(abs(r0.Bus(1).Component(1).X.omega(end)) > 10*abs(omega(end)))


%% Two global controllers act together
% 大域制御器は何台でも扱える。同じ発電機を alpha を半分ずつにした 2 台の AGC で制御すると、
% 出力の和が 1 台の AGC と等しいので、同じ応答になる
net1 = DebugScript.helper.build_ieee14();
net1.add_global_controller(controller.agc.broadcast_PI_AGC(net1, "agc", "SG1B001", "SG1B002", alpha=[1;1], kP=100, kI=500));
net2 = DebugScript.helper.build_ieee14();
agcA = controller.agc.broadcast_PI_AGC(net2, "agcA", "SG1B001", "SG1B002", alpha=[0.5;0.5], kP=100, kI=500);
agcB = controller.agc.broadcast_PI_AGC(net2, "agcB", "SG1B001", "SG1B002", alpha=[0.5;0.5], kP=100, kI=500);
net2.add_global_controller(agcA);
net2.add_global_controller(agcB);
DebugScript.helper.quiet(@() net1.initialize);
DebugScript.helper.quiet(@() net2.initialize);

% 外乱なしでは平衡点に留まる
sol = net2.simulate([0,2], DebugScript.helper.noop_event(net2,[0,2]));
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)

% 負荷を増やしたときの応答が 1 台の場合と一致し、周波数偏差が 0 に戻る
r1 = net1.simulate([0,20], odeEventSet("step", net1, "TimeSpan", [1,20], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", -0.1)).odeResults;
r2 = net2.simulate([0,20], odeEventSet("step", net2, "TimeSpan", [1,20], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", -0.1)).odeResults;
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
    ev  = odeEventSet("offset", net, "TimeSpan", 0, "OffsetUnit", string(gen), "OffsetState", "omega", "OffsetValue", 1e-3);
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
ev = odeEventSet("in", net, "TimeSpan", [1,2], "InputUnit", "LPQ2B002", "InputName", ["P";"Q"], "InputValue", 0.1);
expect_error(@() net.simulate([0,3], ev), "GUILDA:odeEventSet:UnknownInputName")
ev = odeEventSet("in", net, "TimeSpan", [1,2], "InputUnit", "NoSuchUnit", "InputName", "Pload", "InputValue", 0.1);
expect_error(@() net.simulate([0,3], ev), "GUILDA:odeEventSet:UnknownInputUnit")
ev = odeEventSet("in", net, "TimeSpan", [1,2], "InputUnit", "LPQ2B002", "InputName", "Pload", "InputValue", @(t,x) 0.1);
expect_error(@() net.simulate([0,3], ev), "GUILDA:odeEventSet:InvalidNargin")


%% Event outside the simulation time warns
ev = odeEventSet("late", net, "TimeSpan", [5,6], "FaultBus", "B008");
lastwarn("");
[~, flag] = net.simulate([0,1], ev);
[~, id] = lastwarn();
assert(id == "GUILDA:odeEventSet:OutsideTimeSpan")
assert(flag == 1)


% ---- local functions ----
function set_property(obj, str_name, val)
    obj.(str_name) = val;
end

function expect_error(f, str_id)
    try
        f();
        error("DebugScript:noError", "エラーにならない (期待: " + str_id + ")")
    catch ME
        assert(ME.identifier == str_id, ME.identifier + ": " + ME.message)
    end
end
