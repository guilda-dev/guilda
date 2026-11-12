% F10 解析 API の基盤 (結果クラスの基底 / Name-Value オプションの解決 / v3 互換の仕組み)
%
%   tools.resolve_options : net.solver_* の既定値 + 呼び出し時の Name-Value 上書き
%   ResultBase        : 解析結果クラスの基底 (Plot / Export の契約)
%   legacy_output         : nargout が旧シグネチャと一致するとき旧形式の出力を返す
%   COMPAT(v3) フック     : 互換コードは _VersionSupport/ に集め、本体は1行のフックだけ
%
% 実行: runtests("DebugScript.test_F10_api_foundation")  または  DebugScript.run_all("Features","F10")

% 共通設定 (各テストの前に毎回実行される)
sct_mapPF = struct("MaxIteration", "MaxIterations", ...
                 "Verbose",      {{"Display", @(l) replace(string(l), ["true","false"], ["iter","none"])}}, ...
                 "TimeSpan",     "dynamic.t_span", ...
                 "WhenFailed",   "WhenFailed");
sct_holdPF = struct("MaxIterations", 50, "Display", "none", "WhenFailed", "NONE", ...
                    "dynamic", struct("Damper", 1, "t_span", 0:1/120:50));
sct_mapODE = struct("Tolerance", ["AbsoluteTolerance","RelativeTolerance"], ...
                  "TimeLimit", "TimeLimit", ...
                  "Progress",  "Progress");


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Resolve options returns stored defaults without overrides
% 既定値の持ち主は構造体でもよい (SolverPF は GUILDA.setting の値の構造体を渡す)
sct_hold = sct_holdPF;
sct_hold.MaxIterations = 42;
for nv = {{}, struct()}
    [opt, sv_given] = tools.resolve_options(sct_hold, sct_mapPF, nv{1});
    assert(opt.MaxIterations == 42 && opt.Display == sct_hold.Display && opt.WhenFailed == sct_hold.WhenFailed)
    assert(isequal(opt.dynamic, sct_hold.dynamic))
    assert(isempty(sv_given))
end
% 結果のフィールドは対応表が参照するフィールドだけ (入れ子は最上位のフィールド)
assert(isequal(sort(string(fieldnames(opt))), sort(["MaxIterations";"Display";"dynamic";"WhenFailed"])))


%% Resolve options applies overrides and leaves the stored solver unchanged
solver   = struct("MaxIterations", 500, "StepSize", 0.5);   % 既定値の入れ物 (構造体)
r_iter   = solver.MaxIterations;
r_step   = solver.StepSize;
[opt, sv_given] = tools.resolve_options(solver, struct("MaxIteration", "MaxIterations", "StepSize", "StepSize"), ...
                                        {"maxiteration", 7, "StepSize", 0.1});
assert(opt.MaxIterations == 7 && opt.StepSize == 0.1)   % 名前の大文字小文字は区別しない
assert(isequal(sv_given, ["MaxIteration","StepSize"]))
% 既定値の入れ物は変わらない
assert(solver.MaxIterations == r_iter && solver.StepSize == r_step)
% 変換関数 (Verbose -> Display) と入れ子のパス
[opt, sv_given] = tools.resolve_options(sct_holdPF, sct_mapPF, {"Verbose", true, "TimeSpan", 0:0.5:1});
assert(opt.Display == "iter")
assert(isequal(opt.dynamic.t_span, 0:0.5:1) && opt.dynamic.Damper == sct_holdPF.dynamic.Damper)
assert(isequal(sv_given, ["Verbose","TimeSpan"]))

% arguments ブロックの構造体でも渡せる。同じ名前が2回なら後が優先
opt = tools.resolve_options(sct_holdPF, sct_mapPF, struct("WhenFailed", "ERROR"));
assert(opt.WhenFailed == "ERROR" && sct_holdPF.WhenFailed ~= "ERROR")
opt = tools.resolve_options(sct_holdPF, sct_mapPF, {"MaxIteration", 3, "MaxIteration", 5});
assert(opt.MaxIterations == 5)


%% Resolve options sets several solver fields from one name
solver = struct("AbsoluteTolerance", 1e-6, "RelativeTolerance", 1e-4, "TimeLimit", Inf, "Progress", "dialog");
r_abs  = solver.AbsoluteTolerance;
r_rel  = solver.RelativeTolerance;
opt = tools.resolve_options(solver, sct_mapODE, {"Tolerance", 1e-8, "Progress", "none"});
assert(opt.AbsoluteTolerance == 1e-8 && opt.RelativeTolerance == 1e-8 && opt.Progress == "none")
assert(opt.TimeLimit == solver.TimeLimit)
assert(solver.AbsoluteTolerance == r_abs && solver.RelativeTolerance == r_rel)


%% Resolve options rejects an unknown name
solver = sct_holdPF;
try
    tools.resolve_options(solver, sct_mapPF, {"Tolerence", 1e-6});
    error("DebugScript:noError", "未知の名前でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:resolve_options:UnknownName", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "Tolerence") && contains(ME.message, "struct"))
    assert(contains(ME.message, "MaxIteration, Verbose, TimeSpan, WhenFailed"))   % 使える名前を示す
end
% 名前と値の組になっていない
assert(error_id(@() tools.resolve_options(solver, sct_mapPF, {"MaxIteration"})) == "GUILDA:resolve_options:InvalidPairs")
% 対応表の誤り (ソルバーにないフィールド) は開発者向けのエラー
assert(error_id(@() tools.resolve_options(solver, struct("Method", "Algorithm"))) == "GUILDA:resolve_options:UnknownField")
assert(error_id(@() tools.resolve_options(solver, struct("TimeSpan", "dynamic.tspan"))) == "GUILDA:resolve_options:UnknownField")


%% Solver properties are validated and the solver classes can be subclassed
% net.solver_* はクラスの検証付き。ソルバークラスはどれも Sealed ではない (系統のサブクラスで差し替え可能)
for s_cls = ["SolverPF","SolverOPF","SolverCPF","SolverODE","SolverLIN"]
    assert(~meta.class.fromName(s_cls).Sealed, s_cls)
end
mc = ?PowerNetwork;
for s_prop = ["solver_PF","solver_OPF","solver_CPF","solver_ODE","solver_LIN"]
    p = mc.PropertyList(strcmp({mc.PropertyList.Name}, s_prop));
    assert(p.Validation.Class.Name == "Solver" + extractAfter(s_prop, "solver_"), s_prop)
end


%% Analysis result base holds the shared parts
net = PowerNetwork("Grid");
solver = net.solver_PF;
opt = tools.resolve_options(sct_holdPF, sct_mapPF, {"MaxIteration", 9});
t0  = tic;
res = DebugScript.helper.DummyResult(net, solver, opt, 1, struct("iterations", 4), t0, 1:3);
assert(isa(res, "ResultBase") && isa(res, "auxiliary"))
assert(res.s_solver == "SolverPF" && res.options.MaxIterations == 9)
assert(res.flag == 1 && res.output.iterations == 4 && res.l_success)
assert(res.r_elapsed >= 0 && res.r_elapsed < 60)     % tic の値から経過時間
assert(res.s_network == "Grid")
assert(res.a_PowerNetwork == net)                    % 系統は参照 (コピーではない)

% 成否: 数値の flag は正なら成功、logical はそのまま
res = DebugScript.helper.DummyResult([], "SolverODE", struct(), -2, struct(), 0.5, []);
assert(~res.l_success && res.r_elapsed == 0.5 && res.s_solver == "SolverODE" && res.s_network == "")
res = DebugScript.helper.DummyResult([], "x", struct(), true, struct(), 0, []);
assert(res.l_success)

% 基底クラスは抽象クラス
assert(error_id(@() ResultBase()) ~= "")


%% Analysis result Plot and Export contract
res = DebugScript.helper.DummyResult([], "x", struct(), true, struct(), 0, [1 3 2]);
% 基底クラスに Plot はない (図は各結果クラスの plot_* メソッド)
assert(~ismethod(res, "Plot"))
% 結果クラスが自分の plot_* を持てる
h = res.plot_value();
assert(isa(h, "matlab.graphics.chart.primitive.Line") && isequal(h.YData, [1 3 2]))
close(ancestorfig(h))
% 実装していない export は明確なエラー
try
    res.export("result.csv");
    error("DebugScript:noError", "未対応の export でエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultBase:Unsupported", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "export") && contains(ME.message, "DebugScript.helper.DummyResult"))
end


%% Legacy output returns the old tuple only for the old output counts
c_new    = {"result", true, struct("a",1)};
f_legacy = @(r, f, o) {"old1", "old2", f, o, "old5", "old6"};
clear Deprecated
lastwarn("");
for n = 0:3
    assert(isequal(legacy_output(c_new, n, 4:6, f_legacy, "BusBaseMVA"), c_new))
end
id = DebugScript.helper.msg_id();
assert(isempty(id), "新形式では警告しない")
c_out = legacy_output(c_new, 6, 4:6, f_legacy, "BusBaseMVA");
id = DebugScript.helper.msg_id();
assert(numel(c_out) == 6 && c_out{1} == "old1" && c_out{3} == true)
assert(string(id) == "GUILDA:Deprecated:BusBaseMVA")
% 警告は1セッションに1回、キーなしなら警告しない
lastwarn("");
legacy_output(c_new, 5, 4:6, f_legacy, "BusBaseMVA");
legacy_output(c_new, 5, 4:6, f_legacy);
id = DebugScript.helper.msg_id();
assert(isempty(id))


%% Legacy output as a varargout hook
% 段階2で解析メソッドに入れる形 (varargout + 1行のフック) をそのまま確認する
[r, f, o] = hooked_method();
assert(r == "result" && f && o.a == 1)
r = hooked_method();
assert(r == "result")
[a1, ~, ~, ~, ~, a6] = hooked_method();
assert(a1 == "old1" && a6 == "old6")


%% COMPAT hook helper for add_bus baseMVA
net = PowerNetwork();
opt = struct("V", 1, "Tag", "B");
assert(isequal(v3_bus_baseMVA(net, opt), opt))                 % baseMVA なし: そのまま
lastwarn("");
opt = v3_bus_baseMVA(net, struct("V", 1, "baseMVA", nan));     % 既定値 (指定なし): 警告なしで削除
id = DebugScript.helper.msg_id();
assert(~isfield(opt, "baseMVA") && isempty(id))


%% COMPAT hooks are single tagged lines and compat code stays in VersionSupport
s_root = string(fileparts(fileparts(which("DebugScript.run_all"))));
a_file = [dir(fullfile(s_root, "_GUILDAsystem", "**", "*.m")); ...
          dir(fullfile(s_root, "_GUILDAobject", "**", "*.m")); ...
          dir(fullfile(s_root, "@GUILDA", "**", "*.m"))];
sv_hook  = strings(0,1);
sv_bad   = strings(0,1);
for k = 1:numel(a_file)
    s_path = string(fullfile(a_file(k).folder, a_file(k).name));
    if contains(s_path, filesep + "_VersionSupport" + filesep)
        continue
    end
    sv_line = splitlines(string(fileread(s_path)));
    iv_hook = find(contains(sv_line, "COMPAT(v3)"));
    sv_hook = [sv_hook; erase(s_path, s_root + filesep) + ":" + iv_hook]; %#ok<AGROW>
    % 本体のコードから Deprecated を直接呼ばない (フック行の先の _VersionSupport/ で呼ぶ)
    iv_dep = find(contains(sv_line, ["Deprecated(", "GUILDA:Deprecated:"]) & ~startsWith(strtrim(sv_line), "%"));
    iv_dep = setdiff(iv_dep, iv_hook);
    sv_bad = [sv_bad; erase(s_path, s_root + filesep) + ":" + iv_dep]; %#ok<AGROW>
end
assert(isempty(sv_bad), "フック以外で Deprecated を使用: " + join(sv_bad, ", "))
% 現在のフック (追加・削除したらこの一覧と notes/v4-migration.md の4章を更新する)
sv_file = extractBefore(sv_hook, ":");
assert(sum(sv_file == fullfile("_GUILDAsystem", "@PowerNetwork", "add_bus.m")) == 2, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "@PowerNetwork", "calculate_powerflow.m")) == 0, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "@PowerNetwork", "calculate_optimal_powerflow.m")) == 0, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "@PowerNetwork", "build_opf_problem.m")) == 0, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "@PowerNetwork", "initialize.m")) == 1, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "_auxiliary", "@SolverCPF", "SolverCPF.m")) == 1, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "@PowerNetwork", "simulate.m")) == 0, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "_auxiliary", "@SolverLIN", "SolverLIN.m")) == 3, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "_auxiliary", "@SolverLIN", "get_options.m")) == 2, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "_auxiliary", "@SolverLIN", "solve.m")) == 1, join(sv_hook, ", "))
assert(sum(sv_file == fullfile("_GUILDAsystem", "_auxiliary", "@ResultLIN", "get_ss.m")) == 1, join(sv_hook, ", "))
assert(numel(sv_hook) == 11, join(sv_hook, ", "))


% ---- local functions ----
function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        fcn();
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
        if id == ""
            id = "(no id)";
        end
    end
end

function varargout = hooked_method()
% 段階2の解析メソッドの出力部分の見本
    result = "result"; flag = true; output = struct("a", 1);
    varargout = {result, flag, output};
    varargout = legacy_output(varargout, nargout, 4:6, @(r,f,o) {"old1","old2",f,o,"old5","old6"}, "BusBaseMVA"); % 段階2ではこの行に互換タグを付ける
end

function fig = ancestorfig(h)
    fig = ancestor(h, "figure");
end
