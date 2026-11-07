% 補完確認: テンプレートと生成 .m をなくす案 (GUILDA.keymap + 静的な functionSignatures.json)
%
% このスクリプトは runtests / run_all の対象外 (ファイル名が test_ で始まらない)。
% GUILDA.keymap の代わりに DebugScript.helper.proto_keymap を使い、次を確かめる。
%   1. Key の候補を関数呼び出し (choices=proto_keymap(...)) で出せるか。変数がない状態も含む
%   2. JSON の項目は arguments ブロックの候補を置き換えるか。arguments ブロックのメタデータ
%   3. 部品のない母線で signature が残るか (choices 式の書き方の比較)
%   4. proto_keymap と、キー表による検証・振り分けの時間
% 候補は未公開の builtin('_programmingAidsTest', ...) で取得する。補完式はベースワークスペース
% で評価されるため、コマンドウィンドウからスクリプトとして実行する。
% 2 と 3 は _GUILDAsystem/resources/functionSignatures.json を一時的に書き換え、最後に元へ戻す
% (補完のキャッシュは manageCaches("all","clear") で読み直す)。
%
% 実行: DebugScript.manual_keymap_completion
%
% 対話での確認 (エディター / ライブエディター、コードを実行する前):
% - 新しいファイルに  sys = network.IEEE9bus;  b1 = sys.a_Bus{1};  b1.replace_component(  と書き、
%   "SG1B001", まで入力 → Key の候補が出る (s_tag の候補は変数がないため出ない)
% - 同じファイルで  b1.add_component(  → Key の候補が出る (arguments ブロックから)
% - コードを実行した後に同じ行 → s_tag にも "SG1B001" が出る

evalc('GUILDA.addpath');
s_json  = fullfile(GUILDA.pwd, '_GUILDAsystem', 'resources', 'functionSignatures.json');
s_orig  = fileread(s_json);
cln_json = onCleanup(@() restore_json(s_json, s_orig));
clearvars sys b1 b4 b5

% 4 の初回呼び出しの時間は、ここ (補完が proto_keymap を呼ぶ前) で測る。同じ MATLAB で
% 2 回目以降に実行すると、キャッシュ済みの時間になる
t_first = tic; DebugScript.helper.proto_keymap("Component"); t_first = toc(t_first);

%% 1. Key の候補 (関数呼び出し)、変数がない状態とある状態
disp(newline + "== 1. Key choices from proto_keymap: no variables (editor before running) ==")
show('b1.replace_component("SG1B001", ')
show(['sys = network.IEEE9bus;' newline 'b1 = sys.a_Bus{1};' newline 'b1.replace_component("SG1B001", '])
show('b1.replace_component(')
show('b1.add_component(')
sys = network.IEEE9bus;
b1  = sys.a_Bus{1};
b4  = sys.a_Bus{4};
disp(newline + "== 1. with variables ==")
show('b1.replace_component(')
show('b1.replace_component("SG1B001", ')
show('b1.add_component(')

%% 2. Key だけの Bus.add_component を JSON に入れる
s_K = '"char", "choices=cellstr(DebugScript.helper.proto_keymap(\"Component\").key)"';
s_add = ['"Bus.add_component": {"inputs": [{"name": "obj", "kind": "required", "type": "Bus"},' ...
         '{"name": "Key", "kind": "required", "type": [' s_K ']}]}'];
write_json(s_json, insert_entry(s_orig, s_add));
disp(newline + "== 2. JSON entry for Bus.add_component with Key only ==")
show('b1.add_component(')
show('b1.add_component("gen-park", ')
show('b1.add_component("gen-park", P=')
write_json(s_json, s_orig);
disp(newline + "== 2. original JSON (arguments block) ==")
show('b1.add_component("gen-park", ')

disp(newline + "== 2. arguments block metadata of Bus.add_component (?Bus) ==")
mc  = ?Bus;
mm  = mc.MethodList(string({mc.MethodList.Name}) == "add_component");
a_in = mm.Signature.Inputs;
for k = 1:numel(a_in)
    arg = a_in(k);
    s_cls = ""; s_fun = ""; s_def = "";
    if ~isempty(arg.Validation)
        if ~isempty(arg.Validation.Class), s_cls = string(arg.Validation.Class.Name); end
        for f = arg.Validation.Functions, s_fun = s_fun + func2str(f.Function) + " "; end
    end
    if ~isempty(arg.DefaultValue), s_def = string(arg.DefaultValue.Expression); end
    s_id = string(arg.Identifier.Name);
    if string(arg.Identifier.GroupName) ~= "", s_id = string(arg.Identifier.GroupName) + "." + s_id; end
    fprintf('  %-22s req=%d nv=%d class=%-8s default=%-6s desc="%s" %s\n', ...
        s_id, arg.Required, arg.NameValue, s_cls, s_def, arg.Description, s_fun);
end

%% 3. 部品のない母線 (sys.a_Bus{4}) で s_tag の型の書き方を比べる
c_type = {
    "a choices only",          '["string", "choices=cellstr(string(obj.a_Component))"]'
    "b choices OR string",     '[["string", "choices=cellstr(string(obj.a_Component))"], ["string"]]'
    "c choices + empty item",  '["string", "choices=[cellstr(string(obj.a_Component)); {''''}]"]'
    "d choices + placeholder", '["string", "choices=[cellstr(string(obj.a_Component)); {''<none>''}]"]'
    };
s_from = '[["string", "choices=cellstr(string(obj.a_Component))"], ["string"]]';
for k = 1:size(c_type, 1)
    write_json(s_json, strrep(s_orig, s_from, c_type{k,2}));
    disp(newline + "== 3. s_tag type " + c_type{k,1} + " ==")
    show('b4.replace_component(')
    show('b4.replace_component("x", ')
    show('b1.replace_component(')
end
write_json(s_json, s_orig);

%% 4. 時間
disp(newline + "== 4. timing ==")
t_refresh = timeit(@() DebugScript.helper.proto_keymap("Component", Refresh=true));
t_cached  = timeit(@() DebugScript.helper.proto_keymap("Component"));
fprintf('  proto_keymap: first call %.1f ms, Refresh %.1f ms, cached %.2f us\n', 1e3*t_first, 1e3*t_refresh, 1e6*t_cached);
t_lit = timeit(@() pick_literal('load-power'));
t_map = timeit(@() pick_keymap('load-power'));
t_dic = timeit(@() pick_dictionary('load-power'));
fprintf('  validate + dispatch per call: literal switch %.2f us, keymap table %.2f us, handle dictionary %.2f us\n', ...
    1e6*t_lit, 1e6*t_map, 1e6*t_dic);
t_net = timeit(@() network.IEEE68bus, 1);
net68 = network.IEEE68bus;
n_comp = sum(cellfun(@(b) numel(b.a_Component), net68.a_Bus));
n_call = n_comp + numel(net68.a_Branch);
fprintf('  network.IEEE68bus: %.1f ms to build, %d add_component + add_branch calls\n', 1e3*t_net, n_call);
fprintf('  extra time for IEEE68bus: keymap table %.2f ms (%.2f %%), handle dictionary %.2f ms (%.2f %%)\n', ...
    1e3*n_call*(t_map - t_lit), 100*n_call*(t_map - t_lit)/t_net, 1e3*n_call*(t_dic - t_lit), 100*n_call*(t_dic - t_lit)/t_net);
clear cln_json    % restores the JSON and clears the completion caches

%% local functions
function show(s_code)
    % Print the choices of the argument at the end of s_code (evaluated in the base workspace)
    assignin('base', 'c_code_completion__', s_code);
    s_out = evalin('base', "builtin('_programmingAidsTest', '', c_code_completion__, numel(c_code_completion__), [])");
    evalin('base', 'clear c_code_completion__');
    sct = jsondecode(s_out);
    s_line = replace(string(s_code), newline, "\n");
    if ~isfield(sct, 'signatures') || isempty(sct.signatures)
        fprintf('  %-56s -> (no signature)\n', s_line);
        return
    end
    sig = sct.signatures(1);
    if iscell(sig), sig = sig{1}; end
    [~, s_src] = fileparts(sig.signatureSource);
    a_arg = sig.inputArguments;
    if ~iscell(a_arg), a_arg = num2cell(a_arg); end
    s = "";
    for i = 1:numel(a_arg)
        arg = a_arg{i};
        if isfield(arg, 'status') && arg.status == "presenting"
            s = s + " | " + arg.name + ":";
            if isfield(arg, 'widgetData') && isfield(arg.widgetData, 'choices')
                c = arg.widgetData.choices;
                if ~iscell(c), c = num2cell(c); end
                for j = 1:numel(c), s = s + " " + string(c{j}.completion); end
            end
        end
    end
    fprintf('  %-56s -> [%s]%s\n', s_line, s_src, s);
end

function write_json(s_file, s_text)
    fid = fopen(s_file, 'w', 'n', 'UTF-8');
    fprintf(fid, '%s', s_text);
    fclose(fid);
    validateFunctionSignaturesJSON(s_file)
    matlab.lang.internal.introspective.tabcompletion.manageCaches("all", "clear");
end

function restore_json(s_file, s_text)
    fid = fopen(s_file, 'w', 'n', 'UTF-8');
    fprintf(fid, '%s', s_text);
    fclose(fid);
    matlab.lang.internal.introspective.tabcompletion.manageCaches("all", "clear");
end

function s = insert_entry(s_orig, s_entry)
    % Add an entry after "_schemaVersion"
    s_key = '"_schemaVersion": "1.0.0",';
    s = strrep(s_orig, s_key, [s_key newline '  ' s_entry ',']);
end

function f = pick_literal(Key)
    % Today's generated method: literal key list and switch
    arguments
        Key (1,:) char {mustBeMember(Key,{'gen-classical','gen-droop','gen-1axis','gen-park','gen-2axis','load-impedance','load-power'})}
    end
    switch Key
        case 'gen-classical';  f = @component.generator.classical;
        case 'gen-droop';      f = @component.generator.droop;
        case 'gen-1axis';      f = @component.generator.one_axis;
        case 'gen-park';       f = @component.generator.park;
        case 'gen-2axis';      f = @component.generator.two_axis;
        case 'load-impedance'; f = @component.load.impedance;
        case 'load-power';     f = @component.load.power;
    end
end

function f = pick_keymap(Key)
    % Candidate design: validation and dispatch through the cached key table.
    % mustBeMember(Key, proto_keymap("Component").key) is refused in an arguments block
    % (a validator may use only literals and earlier arguments), so a validator function is used.
    arguments
        Key (1,:) char {mustBeKeyOf(Key, "Component")}
    end
    tab = DebugScript.helper.proto_keymap("Component");
    f   = str2func(tab.class(tab.key == Key));
end

function f = pick_dictionary(Key)
    % Candidate design, leaner: one lookup in a cached key -> function handle dictionary,
    % which also validates (an unknown key is an error)
    arguments
        Key (1,:) char
    end
    persistent dic
    if isempty(dic)
        tab = DebugScript.helper.proto_keymap("Component");
        dic = dictionary(tab.key, arrayfun(@(c) {str2func(c)}, tab.class));
    end
    if ~isKey(dic, string(Key))
        error("GUILDA:proto:UnknownKey", "Unknown Component key: %s", Key)
    end
    f = dic{string(Key)};
end

function mustBeKeyOf(Key, s_category)
    % Validator: Key is a model key of the category
    if ~any(DebugScript.helper.proto_keymap(s_category).key == string(Key))
        error("GUILDA:proto:UnknownKey", "Unknown %s key: %s", s_category, Key)
    end
end
