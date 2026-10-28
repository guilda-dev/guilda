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
assert(isstruct(cf) && isfield(cf, "Reporter"))


%% Component key map is generated at startup
% 起動時に add_component.m / replace_component.m が template から生成される
assert(isfile(fullfile(str_root, "_GUILDAsystem", "@Bus", "add_component.m")))
assert(isfile(fullfile(str_root, "_GUILDAsystem", "@Bus", "replace_component.m")))
txt = fileread(fullfile(str_root, "_GUILDAsystem", "@Bus", "add_component.m"));
for key = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-impedance","load-power"]
    assert(contains(txt, "'" + key + "'"), key)
end


%% GUILDA dictionary lists classes
% dictionary は現在のフォルダからクラスを探すので GUILDA のフォルダで実行する
str_cwd = pwd;  cd(str_root);  c = onCleanup(@() cd(str_cwd));
tab = GUILDA.dictionary("Component", "disp", false);
assert(istable(tab))
assert(all(ismember(["component.generator.park","component.load.power"], tab.filename)))

tab = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", ["Component","Branch"]);
assert(iscell(tab) && numel(tab) == 2)
assert(ismember("branch.pi", tab{2}.filename))

% 表示あり (クラスツリー) もエラーにならない
txt = evalc("GUILDA.dictionary(""LocalController"");");
assert(contains(txt, "LocalController"))
