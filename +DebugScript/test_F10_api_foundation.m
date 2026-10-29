% F10 解析 API の基盤 (結果クラスの基底 / Name-Value オプションの解決 / v3 互換の仕組み)
%
%   tools.resolve_options : net.solver_* の既定値 + 呼び出し時の Name-Value 上書き
%   AnalysisResult        : 解析結果クラスの基底 (Plot / Export の契約)
%   legacy_output         : nargout が旧シグネチャと一致するとき旧形式の出力を返す
%   COMPAT(v3) フック     : 互換コードは _VersionSupport/ に集め、本体は1行のフックだけ
%
% 実行: runtests("DebugScript.test_F10_api_foundation")  または  DebugScript.run_all("Features","F10")

% 共通設定 (各テストの前に毎回実行される)
s_mapPF = struct("MaxIteration", "MaxIterations", ...
                 "Verbose",      {{"Display", @(l) replace(string(l), ["true","false"], ["iter","none"])}}, ...
                 "TimeSpan",     "dynamic.t_span", ...
                 "WhenFailed",   "WhenFailed");
s_mapODE = struct("Tolerance", ["AbsoluteTolerance","RelativeTolerance"], ...
                  "TimeLimit", "TimeLimit", ...
                  "Progress",  "Reporter");


%% Resolve options returns stored defaults without overrides
solver = PowerFlowCalculation();
solver.MaxIterations = 42;
for nv = {{}, struct()}
    [opt, sv_given] = tools.resolve_options(solver, s_mapPF, nv{1});
    assert(opt.MaxIterations == 42 && opt.Display == solver.Display && opt.WhenFailed == solver.WhenFailed)
    assert(isequal(opt.dynamic, solver.dynamic))
    assert(isempty(sv_given))
end
% 結果のフィールドは対応表が参照するソルバーのフィールドだけ (入れ子は最上位のプロパティ)
assert(isequal(sort(string(fieldnames(opt))), sort(["MaxIterations";"Display";"dynamic";"WhenFailed"])))


%% Resolve options applies overrides and leaves the stored solver unchanged
net = PowerNetwork();
solver   = net.solver_PF;
r_iter   = solver.MaxIterations;
str_disp = solver.Display;
s_dyn    = solver.dynamic;
[opt, sv_given] = tools.resolve_options(solver, s_mapPF, {"maxiteration", 7, "Verbose", true, "TimeSpan", 0:0.5:1});
assert(opt.MaxIterations == 7)                       % 名前の大文字小文字は区別しない
assert(opt.Display == "iter")                        % 変換関数 (Verbose -> Display)
assert(isequal(opt.dynamic.t_span, 0:0.5:1) && opt.dynamic.Damper == s_dyn.Damper)  % 入れ子のパス
assert(isequal(sv_given, ["MaxIteration","Verbose","TimeSpan"]))
% 保存されているソルバーは変わらない
assert(net.solver_PF.MaxIterations == r_iter && net.solver_PF.Display == str_disp)
assert(isequal(net.solver_PF.dynamic, s_dyn))

% arguments ブロックの構造体でも渡せる。同じ名前が2回なら後が優先
opt = tools.resolve_options(solver, s_mapPF, struct("WhenFailed", "ERROR"));
assert(opt.WhenFailed == "ERROR" && solver.WhenFailed ~= "ERROR")
opt = tools.resolve_options(solver, s_mapPF, {"MaxIteration", 3, "MaxIteration", 5});
assert(opt.MaxIterations == 5)


%% Resolve options sets several solver fields from one name
solver = odeSimulator();
r_abs  = solver.AbsoluteTolerance;
r_rel  = solver.RelativeTolerance;
opt = tools.resolve_options(solver, s_mapODE, {"Tolerance", 1e-8, "Progress", "none"});
assert(opt.AbsoluteTolerance == 1e-8 && opt.RelativeTolerance == 1e-8 && opt.Reporter == "none")
assert(opt.TimeLimit == solver.TimeLimit)
assert(solver.AbsoluteTolerance == r_abs && solver.RelativeTolerance == r_rel)


%% Resolve options rejects an unknown name
solver = PowerFlowCalculation();
try
    tools.resolve_options(solver, s_mapPF, {"Tolerence", 1e-6});
    error("DebugScript:noError", "未知の名前でエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:resolve_options:UnknownName", ME.identifier)
    assert(contains(ME.message, "Tolerence") && contains(ME.message, "PowerFlowCalculation"))
    assert(contains(ME.message, "MaxIteration, Verbose, TimeSpan, WhenFailed"))   % 使える名前を示す
end
% 名前と値の組になっていない
assert(error_id(@() tools.resolve_options(solver, s_mapPF, {"MaxIteration"})) == "GUILDA:resolve_options:InvalidPairs")
% 対応表の誤り (ソルバーにないフィールド) は開発者向けのエラー
assert(error_id(@() tools.resolve_options(solver, struct("Method", "Algorithm"))) == "GUILDA:resolve_options:UnknownField")
assert(error_id(@() tools.resolve_options(solver, struct("TimeSpan", "dynamic.tspan"))) == "GUILDA:resolve_options:UnknownField")


%% Analysis result base holds the shared parts
net = PowerNetwork("Grid");
solver = net.solver_PF;
opt = tools.resolve_options(solver, s_mapPF, {"MaxIteration", 9});
t0  = tic;
res = DebugScript.helper.DummyResult(net, solver, opt, 1, struct("iterations", 4), t0, 1:3);
assert(isa(res, "AnalysisResult") && isa(res, "auxiliary"))
assert(res.str_solver == "PowerFlowCalculation" && res.options.MaxIterations == 9)
assert(res.flag == 1 && res.output.iterations == 4 && res.l_success)
assert(res.r_elapsed >= 0 && res.r_elapsed < 60)     % tic の値から経過時間
assert(res.str_network == "Grid")
assert(res.a_PowerNetwork == net)                    % 系統は参照 (コピーではない)

% 成否: 数値の flag は正なら成功、logical はそのまま
res = DebugScript.helper.DummyResult([], "odeSimulator", struct(), -2, struct(), 0.5, []);
assert(~res.l_success && res.r_elapsed == 0.5 && res.str_solver == "odeSimulator" && res.str_network == "")
res = DebugScript.helper.DummyResult([], "x", struct(), true, struct(), 0, []);
assert(res.l_success)

% 基底クラスは抽象クラス
assert(error_id(@() AnalysisResult()) ~= "")


%% Analysis result Plot and Export contract
res = DebugScript.helper.DummyResult([], "x", struct(), true, struct(), 0, [1 3 2]);
% Plot を実装した結果クラス
h = res.Plot();
assert(isa(h, "matlab.graphics.chart.primitive.Line") && isequal(h.YData, [1 3 2]))
close(ancestorfig(h))
% 実装していない Export は明確なエラー
try
    res.Export("result.csv");
    error("DebugScript:noError", "未対応の Export でエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:AnalysisResult:Unsupported", ME.identifier)
    assert(contains(ME.message, "Export") && contains(ME.message, "DebugScript.helper.DummyResult"))
end


%% Legacy output returns the old tuple only for the old output counts
c_new    = {"result", true, struct("a",1)};
f_legacy = @(r, f, o) {"old1", "old2", f, o, "old5", "old6"};
clear Deprecated
lastwarn("");
for n = 0:3
    assert(isequal(legacy_output(c_new, n, 4:6, f_legacy, "BusBaseMVA"), c_new))
end
[~, id] = lastwarn();
assert(isempty(id), "新形式では警告しない")
c_out = legacy_output(c_new, 6, 4:6, f_legacy, "BusBaseMVA");
[~, id] = lastwarn();
assert(numel(c_out) == 6 && c_out{1} == "old1" && c_out{3} == true)
assert(string(id) == "GUILDA:Deprecated:BusBaseMVA")
% 警告は1セッションに1回、キーなしなら警告しない
lastwarn("");
legacy_output(c_new, 5, 4:6, f_legacy, "BusBaseMVA");
legacy_output(c_new, 5, 4:6, f_legacy);
[~, id] = lastwarn();
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
[~, id] = lastwarn();
assert(~isfield(opt, "baseMVA") && isempty(id))


%% COMPAT hooks are single tagged lines and compat code stays in VersionSupport
str_root = string(fileparts(fileparts(which("DebugScript.run_all"))));
a_file = [dir(fullfile(str_root, "_GUILDAsystem", "**", "*.m")); ...
          dir(fullfile(str_root, "_GUILDAobject", "**", "*.m")); ...
          dir(fullfile(str_root, "@GUILDA", "**", "*.m"))];
str_hook = strings(0,1);
str_bad  = strings(0,1);
for k = 1:numel(a_file)
    str_path = string(fullfile(a_file(k).folder, a_file(k).name));
    if contains(str_path, filesep + "_VersionSupport" + filesep)
        continue
    end
    sv_line = splitlines(string(fileread(str_path)));
    iv_hook = find(contains(sv_line, "COMPAT(v3)"));
    str_hook = [str_hook; erase(str_path, str_root + filesep) + ":" + iv_hook]; %#ok<AGROW>
    % 本体のコードから Deprecated を直接呼ばない (フック行の先の _VersionSupport/ で呼ぶ)
    iv_dep = find(contains(sv_line, ["Deprecated(", "GUILDA:Deprecated:"]) & ~startsWith(strtrim(sv_line), "%"));
    iv_dep = setdiff(iv_dep, iv_hook);
    str_bad = [str_bad; erase(str_path, str_root + filesep) + ":" + iv_dep]; %#ok<AGROW>
end
assert(isempty(str_bad), "フック以外で Deprecated を使用: " + join(str_bad, ", "))
% 現在のフック (追加・削除したらこの一覧と notes/v4-migration.md の4章を更新する)
str_file = extractBefore(str_hook, ":");
assert(sum(str_file == fullfile("_GUILDAsystem", "@Component", "Component.m")) == 5, join(str_hook, ", "))
assert(sum(str_file == fullfile("_GUILDAsystem", "@PowerNetwork", "add_bus.m")) == 2, join(str_hook, ", "))
assert(numel(str_hook) == 7, join(str_hook, ", "))


% ---- local functions ----
function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        fcn();
    catch ME
        id = string(ME.identifier);
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
