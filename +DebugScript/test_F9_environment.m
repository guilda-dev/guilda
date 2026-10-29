% F9 GUILDA の環境 (起動 / パス / 設定 / クラス辞書)
%
% バッチで実行できるものだけを確認する。
% GUILDA.setting / GUILDA.tutorial / GUILDA.newclass など対話操作が必要なものは
% manual_F9_interactive.m で手動確認する。
%
% 実行: runtests("DebugScript.test_F9_environment")  または  DebugScript.run_all("Features","F9")

% 共通設定 (各テストの前に毎回実行される)
str_root = GUILDA.pwd;


%% GUILDA starts in batch mode
% 起動処理 (ロゴ表示・パス追加・Toolbox 確認・キーマップ更新・チュートリアル) がエラーなく終わる
evalc("GUILDA;");


%% GUILDA pwd is the installation folder
assert(isfolder(fullfile(str_root, "@GUILDA")))
assert(isfolder(fullfile(str_root, "_GUILDAsystem")) && isfolder(fullfile(str_root, "_GUILDAobject")))
assert(string(fileparts(which("PowerNetwork"))) == fullfile(str_root, "_GUILDAsystem", "@PowerNetwork"))


%% GUILDA addpath adds required folders
evalc("GUILDA.addpath");
str_list = string(strsplit(strtrim(fileread(fullfile(str_root, "@GUILDA", "config", "ListPath.txt")))));
str_path = string(strsplit(path, pathsep));
for p = str_list
    assert(ismember(fullfile(str_root, replace(p, "/", filesep)), str_path), p + " がパスに無い")
end


%% GUILDA config reads settings
assert(GUILDA.config("Model", "Hz") == 60)
cf = GUILDA.config("TimeSimulation");
assert(isstruct(cf) && isfield(cf, "Progress") && ~isfield(cf, "Reporter"))
% COMPAT(v3): 旧ユーザー設定のキー Reporter は Progress として読む
s_old = v3_user_config("TimeSimulation", struct("Reporter", "disp", "TimeLimit", 5));
assert(isequal(s_old, struct("TimeLimit", 5, "Progress", "disp")))
s_both = v3_user_config("TimeSimulation", struct("Reporter", "disp", "Progress", "none"));
assert(isequal(s_both, struct("Progress", "none")))
assert(isequal(v3_user_config("Model", struct("Reporter", 1)), struct("Reporter", 1)))


%% Component key map is generated at startup
% 起動時に add_component.m / replace_component.m が template から生成される
assert(isfile(fullfile(str_root, "_GUILDAsystem", "@Bus", "add_component.m")))
assert(isfile(fullfile(str_root, "_GUILDAsystem", "@Bus", "replace_component.m")))
txt = fileread(fullfile(str_root, "_GUILDAsystem", "@Bus", "add_component.m"));
for key = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-impedance","load-power"]
    assert(contains(txt, "'" + key + "'"), key)
end

% 内容が同じなら書き直さない (起動のたびに add_branch.m などを更新しない)
sv_file = fullfile(str_root, "_GUILDAsystem", ["@PowerNetwork","@Bus","@Bus"], ["add_branch.m","add_component.m","replace_component.m"]);
evalc("GUILDA;");
d0 = arrayfun(@(f) dir(f).datenum, sv_file);
pause(1.1)
evalc("GUILDA;");
d1 = arrayfun(@(f) dir(f).datenum, sv_file);
assert(isequal(d0, d1), "起動で生成ファイルが書き直された")


%% GUILDA dictionary lists classes
% dictionary は現在のフォルダによらず GUILDA のフォルダからクラスを探す
str_cwd = pwd;  cd(tempdir);  c = onCleanup(@() cd(str_cwd));
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


%% Symbolic Math Toolbox is not a required toolbox
% 必須は Control System / Optimization のみ。Symbolic Math は開発用スクリプト専用の任意 Toolbox
sv_req = strtrim(readlines(fullfile(str_root, "@GUILDA", "config", "ListToolbox.txt")));
sv_req = sv_req(sv_req ~= "");
assert(isequal(sort(sv_req), ["Control System Toolbox"; "Optimization Toolbox"]))


%% Runtime code makes no symbolic calls
% 実行時のコードは Symbolic Math Toolbox を使わない。使ってよいのは次のファイルだけ:
%   NewtonRaphsonMethod.m (sym 入力のときだけ。Toolbox が無ければエラーで代替手段を示す)
%   validate.m (開発用スクリプト), 未+GFM (未完成モデル, パス外)
sv_allowed = [fullfile("_GUILDAsystem", "_auxiliary", "@NewtonRaphsonMethod", "NewtonRaphsonMethod.m")
              fullfile("_GUILDAobject", "+component", "+load", "validate.m")
              fullfile("_GUILDAobject", "+controller", "validate.m")];
str_pat = "(\<(sym|syms|symvar|jacobian|hessian|matlabFunction|vpa|subs|simplify)\s*\()|(^\s*syms\s)|(isa\s*\(.*'sym')";
% パターンが実際に検出できることの確認 (許可されたファイルには呼び出しがある)
sv_dev = readlines(fullfile(str_root, sv_allowed(3)));
assert(any(contains(regexprep(sv_dev, "^\s*%.*", ""), regexpPattern(str_pat))))
sv_hit = strings(0, 1);
for str_dir = ["@GUILDA", "_GUILDAsystem", "_GUILDAobject"]
    s_files = dir(fullfile(str_root, str_dir, "**", "*.m"));
    for k = 1:numel(s_files)
        str_rel = string(erase(fullfile(s_files(k).folder, s_files(k).name), string(str_root) + filesep));
        if ismember(str_rel, sv_allowed) || contains(str_rel, ["archive", "未+GFM"])
            continue
        end
        sv_line = readlines(fullfile(s_files(k).folder, s_files(k).name));
        sv_code = regexprep(sv_line, "^\s*%.*", "");          % コメント行は除く
        l_hit   = contains(sv_code, regexpPattern(str_pat));
        sv_hit  = [sv_hit; str_rel + ":" + string(find(l_hit))]; %#ok<AGROW>
    end
end
assert(isempty(sv_hit), "Symbolic Math の呼び出しがある: " + strjoin(sv_hit, ", "))


%% NewtonRaphsonMethod rejects symbolic input without Symbolic Math Toolbox
% Toolbox が無い環境を、偽の sym クラスと license の代わりで再現する
str_tmp = tempname;  mkdir(str_tmp);
writelines(["classdef sym", "methods", "function obj = sym(varargin), end", "end", "end"], ...
    fullfile(str_tmp, "sym.m"));
writelines(["function varargout = license(varargin)", ...
    "if nargin >= 2 && strcmpi(varargin{1}, 'test') && strcmpi(varargin{2}, 'Symbolic_Toolbox')", ...
    "    varargout = {false};  return", "end", ...
    "[varargout{1:max(nargout,1)}] = builtin('license', varargin{:});", "end"], ...
    fullfile(str_tmp, "license.m"));
w = warning("off", "MATLAB:dispatcher:nameConflict");
addpath(str_tmp);
c_tmp = onCleanup(@() cellfun(@feval, {@() rmpath(str_tmp), @() rmdir(str_tmp, "s"), ...
    @() clear("sym", "license"), @() warning(w)}));
assert(isa(sym(), "sym") && ~license("test", "Symbolic_Toolbox"))
try
    NewtonRaphsonMethod(NRMFcn=sym(), InitVal=1);
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:NewtonRaphsonMethod:SymbolicUnavailable", ME.message)
    assert(contains(ME.message, "function handle") && contains(ME.message, "NRMJac"))
end
clear c_tmp

% 数値の関数ハンドルなら Toolbox 無しで解ける
nrm = NewtonRaphsonMethod(NRMFcn=@(x) x.^2 - 4, InitVal=1);
assert(abs(nrm.solve() - 2) < 1e-6)
