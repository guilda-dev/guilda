% F34 コード補完 (_GUILDAsystem/resources/functionSignatures.json)
%
% functionSignatures.json がメソッドの arguments ブロックから作り直したものと一致すること、
% MATLAB の検証を通ること、補完の候補 (キー、母線ごとの機器のタグ、機器のない母線) を確かめる。
% 候補は未公開の builtin('_programmingAidsTest', ...) で取得する。補完式はベースワークスペースで
% 評価されるため、変数はベースワークスペースに置いて最後に消す。
% Tab を押したときの表示は manual_key_completion.m で手動確認する。
%
% 実行: runtests("DebugScript.test_F34_signatures")  または  DebugScript.run_all("Features","F34")

% 共通設定 (各テストの前に毎回実行される)
s_file = fullfile(GUILDA.pwd, "_GUILDAsystem", "resources", "functionSignatures.json");


%% functionSignatures.json matches the arguments blocks
% GUILDA.update_keymap(Signature=true) で作り直しても内容が変わらない
s_old = string(fileread(s_file, "Encoding", "UTF-8"));
evalc("GUILDA.update_keymap(Signature=true);");
s_new = string(fileread(s_file, "Encoding", "UTF-8"));
if s_new ~= s_old
    fid = fopen(s_file, 'w', 'n', 'UTF-8');  fprintf(fid, '%s', s_old);  fclose(fid);
    matlab.lang.internal.introspective.tabcompletion.manageCaches("all", "clear");
end
assert(s_new == s_old, "functionSignatures.json is out of date: run GUILDA.update_keymap(Signature=true)")


%% functionSignatures.json passes validateFunctionSignaturesJSON
txt = evalc("validateFunctionSignaturesJSON(char(s_file))");
assert(isempty(regexp(txt, "^L \d+ \(C", "once", "lineanchors")), txt)


%% functionSignatures.json covers the methods that build or remove a model
sct = jsondecode(fileread(s_file));
sv_name = string(fieldnames(sct));
% jsondecode は "Bus.add_component" を Bus_add_component にする
sv_expect = ["Bus_add_component", "Bus_replace_component", "Bus_remove_component", ...
             "Component_add_local_controller", "Component_remove_local_controller", ...
             "PowerNetwork_add_branch", "PowerNetwork_add_global_controller", "PowerNetwork_remove_branch", ...
             "PowerNetwork_remove_bus", "PowerNetwork_remove_global_controller", ...
             "PowerNetwork_add_scenario", "PowerNetwork_remove_scenario", "PowerNetwork_simulate"];
assert(all(ismember(sv_expect, sv_name)), join(setdiff(sv_expect, sv_name), ", "))
% simulate: シナリオのタグを補完し、設定の名前を Name-Value に並べる (SolverOptions, Export はない)
c_in = sct.PowerNetwork_simulate.inputs;
if isstruct(c_in)
    c_in = num2cell(c_in);
end
sv_in = string(cellfun(@(a) a.name, c_in, 'UniformOutput', false));
assert(isequal(sv_in(:)', ["obj","s_scenario","Time","Solver","Tolerance","AbsoluteTolerance","MaxStep","InitialStep", ...
                           "SeparateComplexParts","TimeLimit","Progress","Verbose","PlotFcn","Format"]), join(sv_in, ", "))
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


function sv = choices(s_code)
    % Completions offered for the argument at the end of s_code (evaluated in the base workspace)
    arguments (Input)
        s_code (1,:) char   % Code typed so far.
    end
    arguments (Output)
        sv   % Suggested values, without quotes (string row).
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
