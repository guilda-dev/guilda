% F34 コード補完 (_GUILDAsystem/resources/functionSignatures.json と
%     _GUILDAsystem/_auxiliary/resources/functionSignatures.json)
%
% functionSignatures.json がメソッドの arguments ブロックから作り直したものと一致すること、
% MATLAB の検証を通ること、補完の候補 (キー、母線ごとの機器のタグ、機器のない母線、
% _auxiliary のクラス (Scenario、結果) のメソッド) を確かめる。
% MATLAB は resources フォルダーの json をそのフォルダーの関数だけに使うため、_auxiliary の
% クラスの項目は _auxiliary/resources にも書く。
% 候補は未公開の builtin('_programmingAidsTest', ...) で取得する。補完式はベースワークスペースで
% 評価されるため、変数はベースワークスペースに置いて最後に消す。
% Tab を押したときの表示は manual_key_completion.m で手動確認する。
%
% 実行: runtests("DebugScript.test_F34_signatures")  または  DebugScript.run_all("Features","F34")

% 共通設定 (各テストの前に毎回実行される)
s_file = fullfile(GUILDA.pwd, "_GUILDAsystem", "resources", "functionSignatures.json");
s_aux  = fullfile(GUILDA.pwd, "_GUILDAsystem", "_auxiliary", "resources", "functionSignatures.json");


%% functionSignatures.json matches the arguments blocks
% GUILDA.update_keymap(Signature=true) で作り直しても 2 つのファイルの内容が変わらない
sv_file = [s_file, s_aux];
sv_old  = arrayfun(@(f) string(fileread(f, "Encoding", "UTF-8")), sv_file);
evalc("GUILDA.update_keymap(Signature=true);");
sv_new  = arrayfun(@(f) string(fileread(f, "Encoding", "UTF-8")), sv_file);
for k = find(sv_new ~= sv_old)
    fid = fopen(sv_file(k), 'w', 'n', 'UTF-8');  fprintf(fid, '%s', sv_old(k));  fclose(fid);
    matlab.lang.internal.introspective.tabcompletion.manageCaches("all", "clear");
end
assert(all(sv_new == sv_old), "functionSignatures.json is out of date: run GUILDA.update_keymap(Signature=true)")


%% functionSignatures.json passes validateFunctionSignaturesJSON
for f = [s_file, s_aux]
    txt = evalc("validateFunctionSignaturesJSON(char(f))");
    assert(isempty(regexp(txt, "^L \d+ \(C", "once", "lineanchors")), f + newline + txt)
end


%% The _auxiliary file holds the entries of the classes in _auxiliary
% 全項目を持つ _GUILDAsystem の json (GUI が読む) から、クラスフォルダーが _auxiliary にある項目を抜き出したもの
sct_all = jsondecode(fileread(s_file));
sct_aux = jsondecode(fileread(s_aux));
sv_all  = setdiff(string(fieldnames(sct_all)), "x_schemaVersion", "stable");
sv_cls  = extractBefore(sv_all, "_");
sv_cls(ismissing(sv_cls)) = sv_all(ismissing(sv_cls));    % a constructor: the key is the class name
lv_in   = arrayfun(@(c) fileparts(fileparts(which(c))) == fullfile(GUILDA.pwd, "_GUILDAsystem", "_auxiliary"), sv_cls);
assert(isequal(string(fieldnames(sct_aux)), ["x_schemaVersion"; sv_all(lv_in)]), join(string(fieldnames(sct_aux)), ", "))
assert(all(ismember(["Scenario", "EventFault", "EventInput", "ResultPF", "ResultOPF", "ResultODE", "ResultLIN", "ResultCPF", "PowerSystemModel"], sv_cls(lv_in))))
assert(~any(ismember(["Bus", "PowerNetwork", "Component"], sv_cls(lv_in))))


%% functionSignatures.json covers the methods that build or remove a model
sct = jsondecode(fileread(s_file));
sv_name = string(fieldnames(sct));
% jsondecode は "Bus.add_component" を Bus_add_component にする
sv_expect = ["Bus_add_component", "Bus_replace_component", "Bus_remove_component", ...
             "Component_add_local_controller", "Component_remove_local_controller", ...
             "PowerNetwork_add_branch", "PowerNetwork_add_global_controller", "PowerNetwork_remove_branch", ...
             "PowerNetwork_remove_bus", "PowerNetwork_remove_global_controller", ...
             "PowerNetwork_add_scenario", "PowerNetwork_remove_scenario", "PowerNetwork_simulate", ...
             "PowerNetwork_get_element", "PowerNetwork_get_element_table", "PowerNetwork_get_parameter", "PowerNetwork_set_parameter"];
assert(all(ismember(sv_expect, sv_name)), join(setdiff(sv_expect, sv_name), ", "))
% simulate: シナリオのタグを補完し、設定の名前を Name-Value に並べる (SolverOptions, Export はない)
c_in = sct.PowerNetwork_simulate.inputs;
if isstruct(c_in)
    c_in = num2cell(c_in);
end
sv_in = string(cellfun(@(a) a.name, c_in, 'UniformOutput', false));
assert(isequal(sv_in(:)', ["obj","s_scenario","Time","Solver","Tolerance","AbsoluteTolerance","MaxStep","InitialStep", ...
                           "SeparateComplexParts","SampleTime","StopOnOutOfStep","StopAngle","TimeLimit","Progress","Verbose","PlotFcn","Format"]), join(sv_in, ", "))
assert(contains(jsonencode(c_in{2}.type), "choices=cellstr(string(obj.a_Scenario))"))


%% Key suggests the model keys of the category
c_cleanup = onCleanup(@() evalin("base", "clear sys__F34"));
assignin("base", "sys__F34", network.IEEE9bus);
sv_key = keys(GUILDA.keymap("Component"));
assert(isequal(sort(choices('sys__F34.a_Bus{1}.add_component(')), sort(sv_key(:)')))
assert(isequal(sort(choices('sys__F34.a_Bus{1}.replace_component("B001SG1", ')), sort(sv_key(:)')))
sv_key = keys(GUILDA.keymap("Branch"));
assert(isequal(sort(choices('sys__F34.add_branch(')), sort(sv_key(:)')))
sv_key = keys(GUILDA.keymap("LocalController"));
% 波括弧の添字が 2 つ続く式は MATLAB が型を解決しないので、変数を通す
assignin("base", "gen__F34", evalin("base", "sys__F34.a_Bus{1}.a_Component{1}"));
c_gen = onCleanup(@() evalin("base", "clear gen__F34"));
assert(isequal(sort(choices('gen__F34.add_local_controller(')), sort(sv_key(:)')))


%% Tag arguments suggest the tags of the current object
c_cleanup = onCleanup(@() evalin("base", "clear sys__F34"));
assignin("base", "sys__F34", network.IEEE9bus);
assert(ismember("B001SG1", choices('sys__F34.a_Bus{1}.replace_component(')))
assert(~ismember("B001SG1", choices('sys__F34.a_Bus{5}.replace_component(')))
assert(ismember("B005LRX1", choices('sys__F34.a_Bus{5}.remove_component(')))
assert(ismember("B004", choices('sys__F34.remove_bus(')))
evalin("base", "sys__F34.add_scenario(""case1"");");
sv = choices('sys__F34.remove_scenario(');
assert(ismember("case1", sv) && ~any(ismember(evalin("base", "string(sys__F34.a_Bus)"), sv)), join(sv, ", "))
sv = choices('sys__F34.simulate(');
assert(ismember("case1", sv) && ~any(ismember(evalin("base", "string(sys__F34.a_Bus)"), sv)), join(sv, ", "))
assert(ismember("B001SG1", choices('replace_component(sys__F34.a_Bus{1}, ')))
% ローカル制御器のタグは入れ子 (AVR の下の PSS) も含む
assignin("base", "gen__F34", evalin("base", "sys__F34.a_Bus{1}.a_Component{1}"));
c_gen = onCleanup(@() evalin("base", "clear gen__F34"));
sv_con = evalin("base", "string(gen__F34.a_LocalController)");
assert(all(ismember(sv_con, choices('gen__F34.remove_local_controller('))))


%% A bus without components keeps the suggestions of the later arguments
c_cleanup = onCleanup(@() evalin("base", "clear sys__F34"));
assignin("base", "sys__F34", network.IEEE9bus);
assert(isempty(evalin("base", "sys__F34.a_Bus{4}.a_Component")))
assert(~ismember("B001SG1", choices('sys__F34.a_Bus{4}.replace_component(')))
assert(ismember("gen-park", choices('sys__F34.a_Bus{4}.replace_component("x", ')))


%% A (1,1) argument has the attribute "scalar"
% GUI は "scalar" を見て 1 つだけ選ぶ部品にする。タグの引数では選択肢ごとに付く
sct = jsondecode(fileread(s_file));
c_in = sct.ResultODE_plot_trajectory.inputs;
if isstruct(c_in), c_in = num2cell(c_in); end
sct_in = cell2struct(c_in, string(cellfun(@(a) a.name, c_in, 'UniformOutput', false)));
assert(all(cellfun(@(c) ismember("scalar", string(c)), sct_in.Quantity.type)), jsonencode(sct_in.Quantity.type))    % Quantity (1,1) string
assert(~any(cellfun(@(c) ismember("scalar", string(c)), sct_in.Bus.type)), jsonencode(sct_in.Bus.type))           % Bus (1,:) string
c_in = sct.Bus_add_component.inputs;
if isstruct(c_in), c_in = num2cell(c_in); end
sct_in = cell2struct(c_in, string(cellfun(@(a) a.name, c_in, 'UniformOutput', false)));
assert(isequal(string(sct_in.P.type), ["double"; "scalar"]), jsonencode(sct_in.P.type))                          % P (1,1) double


%% functionSignatures.json covers the Scenario events, get_sys and the result methods
% GUI のフォーム (DrawerOptionDialog) が使う。Scenario のタグの選択肢は obj を Scenario にして評価できる
sct = jsondecode(fileread(s_file));
sv_name = string(fieldnames(sct));
sv_expect = ["Scenario_add_fault", "Scenario_add_trip", "Scenario_add_open_branch", ...
             "Scenario_add_offset", "Scenario_add_input", "Scenario_remove_event", ...
             "EventFault", "EventTrip", "EventOpenBranch", "EventOffset", "EventInput", ...
             "EventFault_edit", "EventTrip_edit", "EventOpenBranch_edit", "EventOffset_edit", "EventInput_edit", ...
             "LocalController_add_local_controller", "LocalController_remove_local_controller", "PowerSystemModel_get_sys", ...
             "ResultPF_plot_voltage", "ResultPF_disp_summary", "ResultPF_get_summary", "ResultPF_export", "ResultOPF_get_lmp", "ResultOPF_get_summary", ...
             "ResultCPF_plot_pvcurve", "ResultODE_plot_trajectory", "ResultODE_get_point", "ResultLIN_get_ss", "ResultLIN_plot_eigenvalue"];
assert(all(ismember(sv_expect, sv_name)), join(setdiff(sv_expect, sv_name), ", "))
assert(~any(ismember(["Scenario_add_disturbance", "Scenario_remove_disturbance", "Scenario_insert_event", ...
                      "Scenario_add_from_json_struct", "EventFault_table_rows", "EventBase_edit"], sv_name)))
% A constructor has no obj input; edit has obj of the event class
c_f = sct.EventFault.inputs;
c_e = sct.EventFault_edit.inputs;
if isstruct(c_f), c_f = num2cell(c_f); end
if isstruct(c_e), c_e = num2cell(c_e); end
assert(c_f{1}.name == "target" && c_e{1}.type == "EventFault")
net = network.IEEE9bus;
obj = net.add_scenario("case1");
ev = obj.add_fault("B004", [1 1.05]);
obj.add_offset("B001SG1", "delta", 0.1, Tag="kick");
for s_key = ["Scenario_add_fault", "Scenario_add_trip", "Scenario_add_open_branch", "Scenario_add_offset", "Scenario_remove_event"]
    c_in = sct.(s_key).inputs;
    if isstruct(c_in)
        c_in = num2cell(c_in);
    end
    sv_type = string(c_in{2}.type{1});
    sv = string(eval(extractAfter(sv_type(startsWith(sv_type, "choices=")), "choices=")));
    switch s_key
        case "Scenario_add_fault",          assert(all(ismember(["B004", string(net.a_Branch{1})], sv)), join(sv))
        case "Scenario_add_trip",           assert(all(ismember(["B001SG1", "B005LRX1"], sv)), join(sv))
        case "Scenario_add_open_branch",    assert(isequal(sv(:), string(net.a_Branch)), join(sv))
        case "Scenario_add_offset",         assert(ismember("B001SG1", sv) && ~ismember("B004", sv), join(sv))
        case "Scenario_remove_event",       assert(numel(sv) == 2 && sv(2) == "kick" && startsWith(sv(1), "Fault"), join(sv))
    end
end
% The tag choices of edit evaluate on the event (obj), through its scenario
obj = ev;
c_in = sct.EventFault_edit.inputs;
if isstruct(c_in)
    c_in = num2cell(c_in);
end
sv_type = string(c_in{2}.type{1});
sv = string(eval(extractAfter(sv_type(startsWith(sv_type, "choices=")), "choices=")));
assert(all(ismember(["B004", string(net.a_Branch{1})], sv)), join(sv))
assert(endsWith(c_in{2}.purpose, "Default: obj.sv_target."), c_in{2}.purpose)


%% Every public plot_, disp_, get_ and export method of the results is signed
% ResultBase.launch_gui (DrawerResultGUI) は functionSignatures.json の項目から一覧を作る。
% sig_methods の一覧は手書きなので、公開メソッドとの差をここで見つける。
% ResultBase の export (Unsupported を出す既定の実装) だけを継承したクラスは対象外
sct = jsondecode(fileread(s_file));
sv_name = string(fieldnames(sct));
sv_missing = strings(1, 0);
for s_class = ["ResultPF", "ResultOPF", "ResultCPF", "ResultODE", "ResultLIN"]
    a_method = meta.class.fromName(s_class).MethodList;
    for k = 1:numel(a_method)
        m = a_method(k);
        s_method = string(m.Name);
        if ~isequal(m.Access, 'public') || m.Hidden || m.Static || m.DefiningClass.Name == "ResultBase" ...
                || ~(startsWith(s_method, ["plot_", "disp_", "get_"]) || s_method == "export")
            continue
        end
        if ~ismember(s_class + "_" + s_method, sv_name)
            sv_missing(end+1) = s_class + "." + s_method;    %#ok<AGROW>
        end
    end
end
assert(isempty(sv_missing), "Not in functionSignatures.json (sig_methods of GUILDA.update_keymap): " + join(sv_missing, ", "))


%% Methods of the _auxiliary classes suggest their choices
% Scenario のタグ、ResultODE.plot_trajectory の量、ResultPF の選択肢 (_auxiliary/resources の json による)
c_cleanup = onCleanup(@() evalin("base", "clear net__F34 sc__F34 res__F34 pf__F34"));
assignin("base", "net__F34", network.IEEE14bus);
assignin("base", "sc__F34", evalin("base", "net__F34.add_scenario(""case1"")"));
sv_tag = evalin("base", "[string(net__F34.a_Bus); string(net__F34.a_Branch)]");
sv = choices('sc__F34.add_fault(');
assert(all(ismember(sv_tag, sv)), join(sv, ", "))
sv = choices('net__F34.a_Scenario{1}.add_fault(');
assert(all(ismember(sv_tag, sv)), join(sv, ", "))
evalin("base", "res__F34 = DebugScript.helper.quiet(@() net__F34.simulate(DebugScript.helper.no_disturbance(net__F34), Time=[0,0.1]));");
sv = choices('res__F34.plot_trajectory(Quantity=');
assert(all(ismember(["Vabs", "Vangle", "P", "Q", "omega"], sv)), join(sv, ", "))
assert(~any(ismember(evalin("base", "string(net__F34.a_Bus)"), sv)), join(sv, ", "))
sv = choices('res__F34.plot_trajectory(Bus=');
% 候補の後に文字列の変数 (c_code__F34) が続くことがある
sv_expect = ["all", evalin("base", "string(net__F34.a_Bus)")'];
assert(numel(sv) >= numel(sv_expect) && isequal(sv(1:numel(sv_expect)), sv_expect), join(sv, ", "))
evalin("base", "pf__F34 = DebugScript.helper.quiet(@() net__F34.calculate_powerflow());");
sv = choices('pf__F34.plot_voltage(Quantity=');
assert(isequal(sort(sv), sort(["magnitude", "angle", "both"])), join(sv, ", "))
% 空の結果でも plot_trajectory の選択肢の式はエラーにならない
c_type = jsondecode(fileread(s_aux)).ResultODE_plot_trajectory.inputs;
if isstruct(c_type), c_type = num2cell(c_type); end
obj = ResultODE();    %#ok<NASGU> used by the choice expressions
c_expect = {["Vabs", "Vangle", "P", "Q"], "all"};    % Quantity (input 2), Bus (input 3)
for i = 1:2
    s_type = string(c_type{i+1}.type{1});
    sv = string(eval(extractAfter(s_type(startsWith(s_type, "choices=")), "choices=")));
    assert(isequal(sv(:)', c_expect{i}), join(sv, ", "))
end


function sv = choices(s_code)
    % Completions offered for the argument at the end of s_code (evaluated in the base workspace)
    arguments (Input)
        s_code (1,:) char  % Code typed so far.
    end
    arguments (Output)
        sv  % Suggested values, without quotes (string row).
    end
    assignin("base", "c_code__F34", s_code);
    s_json = evalin("base", "builtin('_programmingAidsTest', '', c_code__F34, numel(c_code__F34), [])");
    evalin("base", "clear c_code__F34");
    sct = jsondecode(s_json);
    sv  = strings(1, 0);
    if ~isfield(sct, "signatures") || isempty(sct.signatures)
        return
    end
    sig = sct.signatures(1);
    if iscell(sig), sig = sig{1}; end
    a_arg = sig.inputArguments;
    if ~iscell(a_arg), a_arg = num2cell(a_arg); end
    for i = 1:numel(a_arg)
        arg = a_arg{i};
        if isfield(arg, "status") && arg.status == "presenting" && isfield(arg, "widgetData") && isfield(arg.widgetData, "choices")
            c = arg.widgetData.choices;
            if ~iscell(c), c = num2cell(c); end
            for j = 1:numel(c)
                sv(end+1) = erase(string(c{j}.completion), ["""", "'"]);    %#ok<AGROW>
            end
        end
    end
end
