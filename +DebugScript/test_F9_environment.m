% F9 GUILDA の環境 (起動 / パス / 設定 / クラス辞書)
%
% バッチで実行できるものだけを確認する。
% GUILDA.setting / GUILDA.tutorial / GUILDA.newclass など対話操作が必要なものは
% manual_F9_interactive.m で手動確認する。
%
% 実行: runtests("DebugScript.test_F9_environment")  または  DebugScript.run_all("Features","F9")

% 共通設定 (各テストの前に毎回実行される)
s_root = GUILDA.pwd;


%% GUILDA starts in batch mode
% 起動処理 (ロゴ表示・パス追加・Toolbox 確認・キーマップ更新・チュートリアル) がエラーなく終わる
evalc("GUILDA;");


%% GUILDA pwd is the installation folder
assert(isfolder(fullfile(s_root, "@GUILDA")))
assert(isfolder(fullfile(s_root, "_GUILDAsystem")) && isfolder(fullfile(s_root, "_GUILDAobject")))
assert(string(fileparts(which("PowerNetwork"))) == fullfile(s_root, "_GUILDAsystem", "@PowerNetwork"))


%% GUILDA addpath adds required folders
evalc("GUILDA.addpath");
sr_list  = string(strsplit(strtrim(fileread(fullfile(s_root, "@GUILDA", "config", "ListPath.txt")))));
sr_path  = string(strsplit(path, pathsep));
for p = sr_list
    assert(ismember(fullfile(s_root, replace(p, "/", filesep)), sr_path), p + " がパスに無い")
end


%% GUILDA config reads settings
assert(GUILDA.config("Model", "Hz") == 60)
cf = GUILDA.config("TimeSimulation");
assert(isstruct(cf) && isfield(cf, "Progress") && ~isfield(cf, "Reporter"))
% COMPAT(v3): 旧ユーザー設定のキー Reporter は Progress として読む
sct_old = v3_user_config("TimeSimulation", struct("Reporter", "disp", "TimeLimit", 5));
assert(isequal(sct_old, struct("TimeLimit", 5, "Progress", "disp")))
sct_both = v3_user_config("TimeSimulation", struct("Reporter", "disp", "Progress", "none"));
assert(isequal(sct_both, struct("Progress", "none")))
assert(isequal(v3_user_config("Model", struct("Reporter", 1)), struct("Reporter", 1)))


%% Component key map is generated at startup
% 起動時に add_component.m / replace_component.m が template/ の .template から生成される
assert(isfile(fullfile(s_root, "_GUILDAsystem", "@Bus", "add_component.m")))
assert(isfile(fullfile(s_root, "_GUILDAsystem", "@Bus", "replace_component.m")))
txt = fileread(fullfile(s_root, "_GUILDAsystem", "@Bus", "add_component.m"));
for key = DebugScript.helper.model_classes("Component").Key'
    assert(contains(txt, "'" + key + "'"), key)
end

% 制御器の追加メソッドも template/ から生成される
txt = fileread(fullfile(s_root, "_GUILDAsystem", "@Component", "add_local_controller.m"));
for key = DebugScript.helper.model_classes("LocalController").Key'
    assert(contains(txt, "'" + key + "'"), key)
end
txt = fileread(fullfile(s_root, "_GUILDAsystem", "@PowerNetwork", "add_global_controller.m"));
assert(contains(txt, "'agc-PI'"))

% 内容が同じなら書き直さない (起動のたびに add_branch.m などを更新しない)
sv_file = fullfile(s_root, "_GUILDAsystem", ["@PowerNetwork","@Bus","@Bus","@Component","@PowerNetwork"], ...
                   ["add_branch.m","add_component.m","replace_component.m","add_local_controller.m","add_global_controller.m"]);
evalc("GUILDA;");
d0 = arrayfun(@(f) dir(f).datenum, sv_file);
pause(1.1)
evalc("GUILDA;");
d1 = arrayfun(@(f) dir(f).datenum, sv_file);
assert(isequal(d0, d1), "起動で生成ファイルが書き直された")


%% GUILDA dictionary lists classes
% dictionary は現在のフォルダによらず GUILDA のフォルダからクラスを探す
s_cwd = pwd;  cd(tempdir);  c = onCleanup(@() cd(s_cwd));
tab = GUILDA.dictionary("Component", "disp", false);
assert(istable(tab))
assert(all(ismember(["component.generator.park","component.load.power"], tab.filename)))

tab = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", ["Component","Branch"]);
assert(iscell(tab) && numel(tab) == 2)
assert(ismember("branch.pi", tab{2}.filename))

% 表示あり (クラスツリー) もエラーにならない
txt = evalc("GUILDA.dictionary(""LocalController"");");
assert(contains(txt, "LocalController"))
% 旧クラスの保管フォルダ (+component/+load/history) は探さない
txt = evalc("GUILDA.dictionary(""Component"");");
assert(~contains(txt, "same name"), txt)


%% GUILDA dictionary skips archive folders
% archive フォルダ (保管用の旧ファイル) はどこにあっても探さない。
% 現行クラスと同名のファイルを一時的に archive に置いても、重複として検出されない
s_dir = fullfile(s_root, "_GUILDAobject", "+component", "+load", "archive");
assert(~isfolder(s_dir), s_dir + " が既にある")
mkdir(s_dir);
c_dir = onCleanup(@() rmdir(s_dir, "s"));
writelines(["classdef power < handle", "end"], fullfile(s_dir, "power.m"));

txt = evalc("tab = GUILDA.dictionary(""Component"");");
assert(~contains(txt, "same name"), txt)
assert(ismember("component.load.power", tab.filename))
assert(string(which("component.load.power")) ~= fullfile(s_dir, "power.m"))


%% GUILDA dictionary warns about a class that cannot be loaded
% 定義エラーのクラスは元の理由つきの警告を出し、キー一覧には入らない
s_file = fullfile(s_root, "_GUILDAobject", "+component", "+generator", "broken_f9.m");
assert(~isfile(s_file), s_file + " が既にある")
writelines(["classdef broken_f9 < component.generator.no_such_parent_f9", "end"], s_file);
c_file = onCleanup(@() delete_and_rehash(s_file));
rehash path

lastwarn("");
txt = evalc("tab = GUILDA.dictionary(""Component"", ""disp"", false);");
[s_msg, s_id] = lastwarn(); s_id = DebugScript.helper.msg_id(s_msg, s_id);
assert(string(s_id) == "GUILDA:dictionary:ClassNotLoaded", txt)
assert(contains(s_msg, "component.generator.broken_f9") && contains(s_msg, "no_such_parent_f9"), s_msg)
assert(~ismember("component.generator.broken_f9", tab.filename))
assert(ismember("component.generator.park", tab.filename))

% 起動しても止まらず、壊れたクラスはキー一覧に出ない
txt = evalc("GUILDA;");
assert(contains(txt, "broken_f9"), txt)
assert(~contains(fileread(fullfile(s_root, "_GUILDAsystem", "@Bus", "add_component.m")), "broken_f9"))


%% GUILDA startup gives no class warning and lists no test stubs
lastwarn("");
txt = evalc("GUILDA;");
s_id = DebugScript.helper.msg_id();
assert(string(s_id) ~= "GUILDA:dictionary:ClassNotLoaded", txt)
assert(~contains(txt, "could not be loaded"), txt)

% +DebugScript のスタブはモデルのキーとして出さない
tab = GUILDA.dictionary("Component", "disp", false);
assert(~any(startsWith(tab.filename, "DebugScript.")))
txt = fileread(fullfile(s_root, "_GUILDAsystem", "@Bus", "add_component.m"));
assert(~contains(txt, "test-hessian-stub"))


%% Every listed toolbox is optional and has a warning
% ListToolbox.json の Toolbox はすべて任意。キーは tools.require_toolbox の短縮名と同じ
sct_tb = jsondecode(fileread(fullfile(s_root, "@GUILDA", "config", "ListToolbox.json")));
assert(isequal(string(fieldnames(sct_tb)), ["optim"; "control"; "symbolic"]))
for s_key = ["optim", "control", "symbolic"]
    assert(isequal(string(fieldnames(sct_tb.(s_key))), ["Name"; "License"; "Warning"]))
    assert(strlength(string(sct_tb.(s_key).Warning)) > 0)
end
assert(~isfile(fullfile(s_root, "@GUILDA", "config", "ListToolbox.txt")))


%% Runtime code makes no symbolic calls
% 実行時のコードは Symbolic Math Toolbox を使わない。使ってよいのは次のファイルだけ:
%   MethodNewtonRaphson.m (sym 入力のときだけ。Toolbox が無ければエラーで代替手段を示す)
%   validate.m (開発用スクリプト), 未+GFM (未完成モデル, パス外)
sv_allowed = [fullfile("_GUILDAsystem", "_auxiliary", "@MethodNewtonRaphson", "MethodNewtonRaphson.m")
              fullfile("_GUILDAobject", "+component", "+load", "validate.m")
              fullfile("_GUILDAobject", "+controller", "validate.m")];
s_pat = "(\<(sym|syms|symvar|jacobian|hessian|matlabFunction|vpa|subs|simplify)\s*\()|(^\s*syms\s)|(isa\s*\(.*'sym')";
% パターンが実際に検出できることの確認 (許可されたファイルには呼び出しがある)
sv_dev = readlines(fullfile(s_root, sv_allowed(3)));
assert(any(contains(regexprep(sv_dev, "^\s*%.*", ""), regexpPattern(s_pat))))
sv_hit = strings(0, 1);
for s_dir = ["@GUILDA", "_GUILDAsystem", "_GUILDAobject"]
    sct_files = dir(fullfile(s_root, s_dir, "**", "*.m"));
    for k = 1:numel(sct_files)
        s_rel = string(erase(fullfile(sct_files(k).folder, sct_files(k).name), string(s_root) + filesep));
        if ismember(s_rel, sv_allowed) || contains(s_rel, ["archive", "未+GFM"])
            continue
        end
        sv_line = readlines(fullfile(sct_files(k).folder, sct_files(k).name));
        sv_code = regexprep(sv_line, "^\s*%.*", "");          % コメント行は除く
        l_hit   = contains(sv_code, regexpPattern(s_pat));
        sv_hit  = [sv_hit; s_rel + ":" + string(find(l_hit))]; %#ok<AGROW>
    end
end
assert(isempty(sv_hit), "Symbolic Math の呼び出しがある: " + strjoin(sv_hit, ", "))


%% MethodNewtonRaphson rejects symbolic input without Symbolic Math Toolbox
% Toolbox が無い環境を、偽の sym クラスと license の代わりで再現する
s_tmp = tempname;  mkdir(s_tmp);
writelines(["classdef sym", "methods", "function obj = sym(varargin), end", "end", "end"], ...
    fullfile(s_tmp, "sym.m"));
writelines(["function varargout = license(varargin)", ...
    "if nargin >= 2 && strcmpi(varargin{1}, 'test') && strcmpi(varargin{2}, 'Symbolic_Toolbox')", ...
    "    varargout = {false};  return", "end", ...
    "[varargout{1:max(nargout,1)}] = builtin('license', varargin{:});", "end"], ...
    fullfile(s_tmp, "license.m"));
w = warning("off", "MATLAB:dispatcher:nameConflict");
addpath(s_tmp);
c_tmp = onCleanup(@() cellfun(@feval, {@() rmpath(s_tmp), @() rmdir(s_tmp, "s"), ...
    @() clear("sym", "license"), @() warning(w)}));
assert(isa(sym(), "sym") && ~license("test", "Symbolic_Toolbox"))
try
    MethodNewtonRaphson(NRMFcn=sym(), InitVal=1);
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:MethodNewtonRaphson:SymbolicUnavailable", ME.message)
    assert(contains(ME.message, "function handle") && contains(ME.message, "NRMJac"))
end
clear c_tmp

% 数値の関数ハンドルなら Toolbox 無しで解ける
nrm = MethodNewtonRaphson(NRMFcn=@(x) x.^2 - 4, InitVal=1);
assert(abs(nrm.solve() - 2) < 1e-6)


function delete_and_rehash(s_file)
    delete(s_file)
    rehash path
end
