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
% @GUILDA があるルートも入り、別のフォルダからでも GUILDA のメソッドを呼べる
assert(ismember(s_root, sr_path), "ルートがパスに無い")
s_cwd = cd(tempdir);
cleanup_cwd = onCleanup(@() cd(s_cwd));
assert(GUILDA.config("PowerSystemModel", "Hz") == 60)
clear cleanup_cwd


%% GUILDA config reads settings
assert(GUILDA.config("PowerSystemModel", "Hz") == 60)
cf = GUILDA.config("TimeSimulation");
assert(isstruct(cf) && isfield(cf, "Progress") && ~isfield(cf, "Reporter"))
% 潮流計算の設定: MethodNewtonRaphson のセクションはなく、連続潮流計算の修正子はそのセクション
cf = GUILDA.config();
assert(~isfield(cf, "MethodNewtonRaphson"))
assert(isequal(sort(string(fieldnames(cf.PowerFlowCalculation))), sort(["Solver";"Tolerance";"MaxIteration"; ...
    "NewtonStepSize";"GradientStepSize";"FsolveUseParallel";"FsolveMaxFunctionEvaluations";"WhenFailed";"Verbose";"Progress";"WarmStart";"PlotFcn"])))
% 進捗表示は 3 つの解析とも既定でダイアログ (true/false は "dialog"/"none")
for s_sec = ["PowerFlowCalculation","ContinuationPowerFlow","OptimalPowerFlow"]
    assert(cf.(s_sec).Progress.Value == "dialog" && isequal(string(cf.(s_sec).Progress.FromLogical), ["none","dialog"]))
end
% 自動・ソルバーの既定は NaN (全解析で共通)、Verbose は他の解析と同じ logical
assert(cf.PowerFlowCalculation.Tolerance.Value == 1e-8 && isnan(cf.PowerFlowCalculation.MaxIteration.Value) ...
    && isnan(cf.PowerFlowCalculation.GradientStepSize.Value) && isnan(cf.PowerFlowCalculation.FsolveMaxFunctionEvaluations.Value) ...
    && cf.PowerFlowCalculation.Verbose.Value == false)
assert(cf.ContinuationPowerFlow.CorrectorMaxIteration.Value == 1000 && cf.ContinuationPowerFlow.CorrectorStepSize.Value == 1 ...
    && cf.ContinuationPowerFlow.Increment.Value == 1e-4)


%% GUILDA config sections come in the order of the settings window
% 起動・メッセージ・モデル・各解析の順。Git pull の設定とメソッドはない
cf = GUILDA.config();
sv_sec = string(fieldnames(cf))';
assert(isequal(sv_sec(1:8), ["Startup","Message","PowerSystemModel","PowerFlowCalculation", ...
    "OptimalPowerFlow","ContinuationPowerFlow","TimeSimulation","ApproximateLinearization"]), strjoin(sv_sec, ", "))
assert(~any(ismember(["EnvStartup","Model","Linearization"], sv_sec)))
assert(~isfield(cf.Startup, "gitpull") && ~ismember("gitpull", methods("GUILDA")))
assert(cf.Startup.UpdateKeyMap.Value == "disp" && isequal(string(cf.Startup.UpdateKeyMap.options(:))', ["none","silent","disp"]))


%% Startup UpdateKeyMap updates the key map with or without the list
% "disp" は一覧を表示、"silent" は表示せずに作り直し、"none" は作り直さない。true/false は "disp"/"none"
c_user = backup_user_config(); %#ok<NASGU>
s_head = "=== Update Key List ===";
GUILDA.setting("Startup", UpdateKeyMap="disp");
assert(contains(string(evalc("GUILDA;")), s_head))
GUILDA.setting("Startup", UpdateKeyMap="silent");
s_out = string(evalc("GUILDA;"));
assert(~contains(s_out, s_head) && ~contains(s_out, "addkey"), s_out)
assert(isKey(GUILDA.keymap("Component"), "gen-park"))
GUILDA.setting("Startup", UpdateKeyMap="none");
assert(~contains(string(evalc("GUILDA;")), s_head))
GUILDA.setting("Startup", UpdateKeyMap=true);
assert(GUILDA.config("Startup", "UpdateKeyMap") == "disp")
GUILDA.setting("Startup", UpdateKeyMap=false);
assert(GUILDA.config("Startup", "UpdateKeyMap") == "none")
try
    GUILDA.setting("Startup", UpdateKeyMap="verbose");
    error("DebugScript:NoError", "no error")
catch ME
    assert(contains(ME.message, """silent"""), ME.message)
end


%% User files of the former section names are ignored
% 旧名 (EnvStartup, Model, Linearization) のファイルは読まない。起動は止まらず既定値を使う
c_user = backup_user_config(); %#ok<NASGU>
s_dir = fullfile(s_root, "@GUILDA", "user");
writelines(jsonencode(struct("version", 1, "gitpull", true, "UpdateKeyMap", false)), fullfile(s_dir, "DefaultEnvStartup.json"));
writelines(jsonencode(struct("version", 1, "Hz", 50)), fullfile(s_dir, "DefaultModel.json"));
writelines(jsonencode(struct("version", 1, "Type", "DAE")), fullfile(s_dir, "DefaultLinearization.json"));
s_out = string(evalc("GUILDA;"));
assert(contains(s_out, "=== Update Key List ==="), s_out)
assert(GUILDA.config("PowerSystemModel", "Hz") == 60 && GUILDA.config("ApproximateLinearization", "Type") == "ODE")
assert(~any(isfield(GUILDA.config(), ["EnvStartup","Model","Linearization"])))


%% GUILDA setting changes settings by command
% カテゴリと Name-Value で値だけを変える。@GUILDA/user に保存し、キャッシュも書き直す
c_user = backup_user_config(); %#ok<NASGU>
GUILDA.config([], [], "reset", true);
GUILDA.setting("PowerFlowCalculation", Tolerance=1e-10, WhenFailed="ERROR");
assert(GUILDA.config("PowerFlowCalculation", "Tolerance") == 1e-10)
assert(GUILDA.config("PowerFlowCalculation", "WhenFailed") == "ERROR")
assert(GUILDA.config("PowerFlowCalculation", "Solver") == "newton")   % ほかの値はそのまま
sct = jsondecode(fileread(fullfile(s_root, "@GUILDA", "user", "DefaultPowerFlowCalculation.json")));
assert(sct.Tolerance == 1e-10 && string(sct.WhenFailed) == "ERROR")
GUILDA.config([], [], "reset", true);                                 % ファイルから読み直しても残る
assert(GUILDA.config("PowerFlowCalculation", "Tolerance") == 1e-10)
% 型の変換: 数値の 0/1 は logical、char は string
GUILDA.setting("Message", ShowInfo=1);
assert(GUILDA.config("Message", "ShowInfo") == true && islogical(GUILDA.config("Message", "ShowInfo")))
GUILDA.setting("TimeSimulation", Progress='none');
assert(GUILDA.config("TimeSimulation", "Progress") == "none")
% 直後の解析が新しい値を使う
GUILDA.setting("PowerFlowCalculation", MaxIteration=7, WhenFailed="NONE");
res = DebugScript.helper.quiet(@() DebugScript.helper.build_9bus().calculate_powerflow());
assert(res.options.Tolerance == 1e-10 && res.options.MaxIteration == 7)


%% GUILDA setting rejects invalid input and changes nothing
c_user = backup_user_config(); %#ok<NASGU>
GUILDA.setting("PowerFlowCalculation", Tolerance=1e-9);
s_dir = fullfile(s_root, "@GUILDA", "user");
s_before = user_texts(s_dir);
c_case = {
    {"NoSuchCategory", "Tolerance", 1},                                "GUILDA:GUILDA:UnknownSettingCategory"
    {"PowerFlowCalculation", "NoSuchName", 1},                         "GUILDA:GUILDA:UnknownSettingName"
    {"PowerFlowCalculation", "Tolerance"},                             "GUILDA:GUILDA:SettingNameValue"
    {"PowerFlowCalculation"},                                          "GUILDA:GUILDA:SettingNameValue"
    {"PowerFlowCalculation", "Tolerance", 1e-6, "WhenFailed", "FAIL"}, "GUILDA:GUILDA:InvalidSettingValue"
    {"PowerFlowCalculation", "Tolerance", "small"},                    "GUILDA:GUILDA:InvalidSettingValue"
    {"PowerFlowCalculation", "Tolerance", [1 2]},                      "GUILDA:GUILDA:InvalidSettingValue"
    {"PowerFlowCalculation", "WarmStart", "yes"},                      "GUILDA:GUILDA:InvalidSettingValue"
    {"PowerFlowCalculation", "WarmStart", 2},                          "GUILDA:GUILDA:InvalidSettingValue"
    {"ContinuationPowerFlow", "Limits", 3},                            "GUILDA:GUILDA:InvalidSettingValue"
    };
for k = 1:size(c_case, 1)
    try
        GUILDA.setting(c_case{k,1}{:});
        error("DebugScript:NoError", "エラーにならない: case " + k)
    catch ME
        assert(string(DebugScript.helper.msg_id(ME)) == c_case{k,2}, "case " + k + ": " + ME.message)
    end
end
assert(isequal(user_texts(s_dir), s_before), "エラーのあとに設定ファイルが変わった")
assert(GUILDA.config("PowerFlowCalculation", "Tolerance") == 1e-9)   % 先に正しい値があっても変えない
% エラー文に候補を示す
try
    GUILDA.setting("PowerFlowCalculation", WhenFailed="FAIL");
catch ME
    assert(contains(ME.message, "WhenFailed") && contains(ME.message, """ERROR"""), ME.message)
end


%% A double setting with Size takes an array of its size
% check_setting は @GUILDA/private にあるので、その場所で呼ぶ
s_old = cd(fullfile(s_root, "@GUILDA", "private"));
c_cd = onCleanup(@() cd(s_old)); %#ok<NASGU>
sct_vec = struct("Value", [0.1 0.02], "Type", "double", "Description", "", "Size", [1 2], "Valid", "all(v > 0)");
[val, l_ok] = check_setting(sct_vec, [0.2; Inf]);    % 列でも受け付け、Size の形にする
assert(l_ok && isequal(val, [0.2 Inf]), "Size の配列")
for c_bad = {0.2, [0.2 0.1 0.3], [0.2 -1], "0.2 0.1", [1+1i 1]}
    [~, l_ok, s_expect] = check_setting(sct_vec, c_bad{1});
    assert(~l_ok && contains(s_expect, "2 elements"), "受け付けてはいけない値")
end
sct_sc = rmfield(sct_vec, ["Size","Valid"]);           % Size のない設定は今までどおりスカラーだけ
[val, l_ok] = check_setting(sct_sc, missing);
assert(l_ok && isnan(val))
[~, l_ok] = check_setting(sct_sc, [0.1 0.2]);
assert(~l_ok)
clear c_cd


%% User settings of another version are reset to the defaults with INFO
% 利用者の JSON の version が既定ファイルと違うと、そのカテゴリを既定値で上書きして INFO で知らせる
c_user = backup_user_config(); %#ok<NASGU>
s_file = fullfile(s_root, "@GUILDA", "user", "DefaultPowerSystemModel.json");
writelines(jsonencode(struct("version", 999, "Hz", 50)), s_file);
s_out = string(evalc("GUILDA.config([], [], ""reset"", true);"));
assert(contains(s_out, "INFO: ") && contains(s_out, "PowerSystemModel") && contains(s_out, "reset"), s_out)
assert(GUILDA.config("PowerSystemModel", "Hz") == 60)
sct = jsondecode(fileread(s_file));
sct_def = jsondecode(fileread(fullfile(s_root, "@GUILDA", "config", "DefaultPowerSystemModel.json")));
assert(sct.Hz == 60)
assert(isfield(sct, "version") && isequal(sct.version, sct_def.version))
% 書き直したファイルは次から同じ version: もう知らせない
s_out = string(evalc("GUILDA.config([], [], ""reset"", true);"));
assert(~contains(s_out, "INFO"), s_out)
% 起動時にも知らせる
writelines(jsonencode(struct("version", 999, "Hz", 50)), s_file);
s_out = string(evalc("GUILDA;"));
assert(contains(s_out, "INFO: ") && contains(s_out, "PowerSystemModel"), s_out)
assert(GUILDA.config("PowerSystemModel", "Hz") == 60)


%% GUILDA setting window has an editor for every setting
% 設定ウィンドウは左にセクションの一覧、右にスクロールする設定の表 (名前・入力欄・説明)。
% ウィンドウの大きさは固定で、セクションを切り替えても変わらない。Type "string" (Limits) も入力欄を持つ
c_user = backup_user_config(); %#ok<NASGU>
GUILDA.setting;
f = findall(groot, "Type", "figure", "Name", "GUILDA Settings");
c_fig = onCleanup(@() delete(f));
assert(isscalar(f) && f.Resize == "off")
r_pos = f.Position;
lb = findobj(f, "Tag", "sections");
g  = findobj(f, "Tag", "settings");
assert(isa(g, "matlab.ui.container.GridLayout") && g.Scrollable == "on")
assert(isequal(string(lb.ItemsData), string(fieldnames(GUILDA.config()))'))
for s_cat = string(lb.ItemsData)
    lb.Value = s_cat;  lb.ValueChangedFcn(lb, []);
    assert(isequal(f.Position, r_pos), s_cat)
    assert(string(findobj(f, "Tag", "heading").Text) == s_cat)
    sv_name  = string(fieldnames(GUILDA.config(s_cat)));
    sv_label = string({findobj(g, "-depth", 1, "Tag", "name").Text});
    assert(isempty(setxor(sv_label, sv_name)), s_cat)
    assert(numel(findobj(g, "Tag", "value")) == numel(sv_name), s_cat)
    assert(numel(findobj(g, "-depth", 1, "Tag", "description")) == numel(sv_name), s_cat)
    assert(numel(g.RowHeight) == 2*numel(sv_name), s_cat)
end
% 3 択の UpdateKeyMap は選択式
lb.Value = "Startup";  lb.ValueChangedFcn(lb, []);
dd = findobj(g, "Type", "uidropdown", "Tag", "value");
assert(isscalar(dd) && isequal(string(dd.Items), ["none","silent","disp"]) && string(dd.Value) == "disp")
assert(isempty(findobj(f, "-regexp", "Text", "gitpull")))
% 長いセクションは表がウィンドウより高くなり、スクロールする
lb.Value = "OptimalPowerFlow";  lb.ValueChangedFcn(lb, []);
assert(sum([g.RowHeight{:}]) > r_pos(4), "OptimalPowerFlow の表がウィンドウに収まっている")
assert(isequal(f.Position, r_pos))
% Limits はカンマ区切りの入力欄
lb.Value = "ContinuationPowerFlow";  lb.ValueChangedFcn(lb, []);
ef = findobj(g, "Type", "uieditfield", "Value", 'none');
assert(isscalar(ef) && string(ef.Value) == strjoin(string(GUILDA.config("ContinuationPowerFlow", "Limits")), ", "))
% 入力は GUILDA.setting と同じ検査: 数値でない文字は元に戻し、正しい値は Apply で保存する
ef = findobj(g, "Type", "uieditfield", "Value", '0.5');   % StepSize
btn = findobj(f, "Tag", "apply");
ef.Value = 'abc';  ef.ValueChangedFcn(ef, []);
assert(string(ef.Value) == "0.5" && btn.Enable == "off")
assert(startsWith(string(findobj(f, "Tag", "state").Text), "Invalid value: StepSize"))
ef.Value = '0.25';  ef.ValueChangedFcn(ef, []);
assert(btn.Enable == "on" && contains(string(findobj(f, "Tag", "state").Text), "ContinuationPowerFlow"))
assert(any(endsWith(string(lb.Items), "*")))
btn.ButtonPushedFcn(btn, []);
assert(GUILDA.config("ContinuationPowerFlow", "StepSize") == 0.25 && btn.Enable == "off")
clear c_fig


%% Every default settings file has a version
% 既定ファイルはすべて最上位に version (数値) を持つ。設定の構造体には出ない
for f = dir(fullfile(s_root, "@GUILDA", "config", "Default*.json"))'
    sct_def = jsondecode(fileread(fullfile(f.folder, f.name)));
    assert(isfield(sct_def, "version") && isnumeric(sct_def.version) && isscalar(sct_def.version), f.name)
    s_cat = erase(string(f.name), ["Default", ".json"]);
    assert(~isfield(GUILDA.config(s_cat), "version"), f.name)
end


%% User settings without a version are reset to the defaults
% これまでの (version のない) 利用者の JSON は既定値で上書きし、INFO で知らせる
c_user = backup_user_config(); %#ok<NASGU>
s_file = fullfile(s_root, "@GUILDA", "user", "DefaultPowerSystemModel.json");
writelines(jsonencode(struct("Hz", 50)), s_file);
s_out = string(evalc("GUILDA.config([], [], ""reset"", true);"));
assert(contains(s_out, "INFO: ") && contains(s_out, "PowerSystemModel"), s_out)
assert(GUILDA.config("PowerSystemModel", "Hz") == 60)
sct_def = jsondecode(fileread(fullfile(s_root, "@GUILDA", "config", "DefaultPowerSystemModel.json")));
sct = jsondecode(fileread(s_file));
assert(sct.Hz == 60 && isfield(sct, "version") && isequal(sct.version, sct_def.version))
% 旧形式の潮流計算の設定 (MaxIteration 0 は旧「自動」、新しい既定は NaN) も既定値に戻り、潮流計算が収束する
s_file = fullfile(s_root, "@GUILDA", "user", "DefaultPowerFlowCalculation.json");
writelines(jsonencode(struct("Solver", "newton", "Tolerance", 1e-8, "MaxIteration", 0, "WhenFailed", "WARN")), s_file);
s_out = string(evalc("GUILDA.config([], [], ""reset"", true);"));
assert(contains(s_out, "INFO: ") && contains(s_out, "PowerFlowCalculation"), s_out)
assert(isnan(GUILDA.config("PowerFlowCalculation", "MaxIteration")))
[res, flag] = DebugScript.helper.quiet(@() DebugScript.helper.build_9bus().calculate_powerflow());
assert(flag == 1 && res.l_success, "flag = " + flag)
% 同じ version なら利用者の値を残す (helper.user_config は既定ファイルの version を付ける)
c_set = DebugScript.helper.user_config("PowerSystemModel", struct("Hz", 50)); %#ok<NASGU>
assert(GUILDA.config("PowerSystemModel", "Hz") == 50)
sct = jsondecode(fileread(fullfile(s_root, "@GUILDA", "user", "DefaultPowerSystemModel.json")));
assert(sct.version == 1)


%% Model key map lists the keys of the classes
% GUILDA.keymap はクラスの Constant key からキーとコンストラクターの対応を作る
for s_cat = ["Component", "LocalController", "GlobalController", "Branch"]
    dic = GUILDA.keymap(s_cat);
    assert(isa(dic, "dictionary"))
    if s_cat ~= "Branch"
        sv_key = DebugScript.helper.model_classes(s_cat).Key;
        assert(isempty(setxor(keys(dic), sv_key)), s_cat)
    end
end
dic = GUILDA.keymap("Component");
assert(dic("gen-park") == "component.generator.park")
assert(all(ismember(["pi","pi_transformer"], keys(GUILDA.keymap("Branch")))))

% 未知のキーは検証関数がキーの一覧付きで止める
try
    tools.mustBeKeyOf("gen-unknown", "Component");
    error("DebugScript:NoError", "no error")
catch err
    assert(string(DebugScript.helper.msg_id(err)) == "GUILDA:mustBeKeyOf:UnknownKey", err.message)
    assert(contains(err.message, "gen-park") && contains(err.message, "load-power"), err.message)
end
net = network.IEEE9bus;
try
    net.a_Bus{4}.add_component("gen-unknown");
    error("DebugScript:NoError", "no error")
catch err
    % the arguments block puts its own text before the message of the validator
    assert(contains(err.message, "Component model key") && contains(err.message, "load-power"), err.message)
end

% 起動はメソッドのファイルも functionSignatures.json も書き直さない
sv_file = [fullfile(s_root, "_GUILDAsystem", ["@PowerNetwork","@Bus","@Bus","@Component","@PowerNetwork"], ...
                   ["add_branch.m","add_component.m","replace_component.m","add_local_controller.m","add_global_controller.m"]), ...
           fullfile(s_root, "_GUILDAsystem", "resources", "functionSignatures.json")];
evalc("GUILDA;");
d0 = arrayfun(@(f) dir(f).datenum, sv_file);
pause(1.1)
evalc("GUILDA;");
d1 = arrayfun(@(f) dir(f).datenum, sv_file);
assert(isequal(d0, d1), "起動でファイルが書き直された")


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


%% GUILDA config reads the Message settings from the cache
assert(GUILDA.config("Message", "ShowWarning") == true && GUILDA.config("Message", "ShowInfo") == true)
c_set = set_message(false, false, false);   % 書き込むだけ: キャッシュは古い値のまま
assert(GUILDA.config("Message", "ShowWarning") == true && GUILDA.config("Message", "ShowInfo") == true)
GUILDA.config([], [], "reset", true);       % 保存時 (set_config) と同じ再読込
assert(GUILDA.config("Message", "ShowWarning") == false && GUILDA.config("Message", "ShowInfo") == false)
clear c_set
assert(GUILDA.config("Message", "ShowWarning") == true && GUILDA.config("Message", "ShowInfo") == true)


%% A GUILDA warning carries its message ID
bus = PowerNetwork().add_bus();
lastwarn("", "");
gen = bus.add_component("gen-park", P=0.5, Q=0.3);
[s_warn, s_id] = lastwarn();
assert(string(s_id) == "GUILDA:Component:GeneratorQIgnored", s_id)
assert(contains(s_warn, gen.s_tag) && contains(s_warn, "0.3"), s_warn)


%% ShowWarning=false hides the GUILDA warnings
c_set = set_message(false, true); %#ok<NASGU>
bus = PowerNetwork().add_bus();
lastwarn("", "");
s_out = string(evalc('bus.add_component("gen-park", P=0.5, Q=0.3);'));
[s_warn, s_id] = lastwarn();
assert(s_warn == "" && s_id == "" && ~contains(s_out, "Warning"), s_out)
% MATLAB の警告やエラーは設定に関係しない
assert(isnan(bus.a_Component{1}.tab_parameter.powerflow.Q))
try
    bus.add_component("gen-park", parameter="NGT9");
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:UnknownParameter", ME.message)
end


%% ShowInfo=false hides the INFO messages
net = PowerNetwork();
bus = net.add_bus();
bus.add_component("gen-park", P=0.5);
s_out = string(evalc("bus.l_isSlack = true;"));
assert(startsWith(strtrim(s_out), "INFO: ") && contains(s_out, "set as slack bus"), s_out)
evalc("bus.l_isSlack = false;");
c_set = set_message(true, false); %#ok<NASGU>
s_out = string(evalc("bus.l_isSlack = true;"));
assert(s_out == "", s_out)


%% msg accepts a subclass of the class in the ID and rejects other callers
% component.generator.abstract (+component の外) が Component.xml の ID を使える
bus = PowerNetwork().add_bus();
try
    bus.add_component("gen-park", parameter="NGT9");
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(contains(ME.message, "NGT9") && ~contains(ME.message, "ID specification"), ME.message)
end
% サブクラスでない呼び出し元 (このテスト) は Component の ID を使えない
for c_call = {@() msg("GUILDA:Component:GeneratorQIgnored", "a", "b"), ...
              @() show_msg("warning", "GUILDA:Component:GeneratorQIgnored", "a", "b")}
    try
        c_call{1}();
        error("DebugScript:NoError", "エラーにならない")
    catch ME
        assert(contains(ME.message, "ID specification"), ME.message)
    end
end


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
    MethodNewtonRaphson(Fcn=sym(), InitVal=1);
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:MethodNewtonRaphson:SymbolicUnavailable", ME.message)
    assert(contains(ME.message, "function handle") && contains(ME.message, "Jac"))
end
clear c_tmp

% 数値の関数ハンドルなら Toolbox 無しで解ける
nrm = MethodNewtonRaphson(Fcn=@(x) x.^2 - 4, InitVal=1);
assert(abs(nrm.solve() - 2) < 1e-6)


function delete_and_rehash(s_file)
    delete(s_file)
    rehash path
end


function c_restore = set_message(l_warning, l_info, l_reset)
% Message の設定をユーザー設定ファイルへ書き、終了時 (c_restore の削除) に元へ戻す
    arguments (Input)
        l_warning (1,1) logical         % ShowWarning
        l_info    (1,1) logical         % ShowInfo
        l_reset   (1,1) logical = true  % 書いたあとに設定を読み直す
    end
    arguments (Output)
        c_restore  % onCleanup: 元のファイルに戻して設定を読み直す
    end
    s_file = fullfile(GUILDA.pwd, "@GUILDA", "user", "DefaultMessage.json");
    if isfile(s_file)
        s_old = fileread(s_file);
    else
        s_old = string(missing);
    end
    c_restore = onCleanup(@() restore_message(s_file, s_old));
    sct = struct("ShowWarning", l_warning, "ShowInfo", l_info);
    sct_def = jsondecode(fileread(fullfile(GUILDA.pwd, "@GUILDA", "config", "DefaultMessage.json")));
    if isfield(sct_def, "version")
        sct.version = sct_def.version;   % 違う version は既定値で上書きされる
    end
    writelines(jsonencode(sct), s_file);
    if l_reset
        GUILDA.config([], [], "reset", true);
    end
end


function restore_message(s_file, s_old)
    if ismissing(s_old)
        delete(s_file)
    else
        fid = fopen(s_file, "w");  fwrite(fid, s_old);  fclose(fid);
    end
    GUILDA.config([], [], "reset", true);
end


function c_restore = backup_user_config()
% @GUILDA/user の設定ファイルを退避し、終了時 (c_restore の削除) に元へ戻して設定を読み直す
    arguments (Output)
        c_restore  % onCleanup
    end
    s_dir = fullfile(GUILDA.pwd, "@GUILDA", "user");
    sct   = user_texts(s_dir);
    c_restore = onCleanup(@() restore_user_config(s_dir, sct));
end


function sct = user_texts(s_dir)
% @GUILDA/user の Default*.json の中身 (ファイル名 -> 文章)
    sct = dictionary(string.empty, string.empty);
    for f = dir(fullfile(s_dir, "Default*.json"))'
        sct(string(f.name)) = string(fileread(fullfile(s_dir, f.name)));
    end
end


function restore_user_config(s_dir, sct)
    for f = dir(fullfile(s_dir, "Default*.json"))'
        if ~isConfigured(sct) || ~isKey(sct, string(f.name))
            delete(fullfile(s_dir, f.name))
        end
    end
    if isConfigured(sct)
        for s_name = keys(sct)'
            fid = fopen(fullfile(s_dir, s_name), "w");  fwrite(fid, sct(s_name));  fclose(fid);
        end
    end
    GUILDA.config([], [], "reset", true);
end
