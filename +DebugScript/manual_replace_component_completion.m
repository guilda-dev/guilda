% 補完確認: Bus.replace_component の s_tag 候補 (functionSignatures.json の試作)
%
% このスクリプトは runtests / run_all の対象外 (ファイル名が test_ で始まらない)。
% _GUILDAsystem/resources/functionSignatures.json による補完候補を、未公開の内部関数
% builtin('_programmingAidsTest', '', code, position, []) で取得して表示する。
% 補完式はベースワークスペースの変数で評価されるため、スクリプトとしてコマンド
% ウィンドウから実行する (関数の中からは呼ばない)。
%
% 実行: DebugScript.manual_replace_component_completion
%
% 対話での確認 (このスクリプトの実行後、sys, b1, b5 がワークスペースにある状態で):
% - コマンドウィンドウ: b1.replace_component( で Tab → "SG1B001"、b5.replace_component( → "LRX1B005" と "LPQ2B005"
% - エディター / ライブエディター: 同じ行を入力 → 同じ候補 (変数がワークスペースにある場合だけ)
% - "SG1B001", の後 → キーの一覧、Controllers= の後 → "drop" "keep"
% - b1.add_component( → キーの一覧 (arguments ブロックからの候補のまま)

evalc('GUILDA.addpath');
evalc('GUILDA.update_keymap');
validateFunctionSignaturesJSON(fullfile(GUILDA.pwd, '_GUILDAsystem', 'resources', 'functionSignatures.json'))

sys = network.IEEE9bus;    % net 以外の変数名
b1  = sys.a_Bus{1};
b5  = sys.a_Bus{5};
sc_case = {
    "1  object, bus 1",          'b1.replace_component('
    "1  object, bus 5",          'b5.replace_component('
    "2  indexed, bus 1",         'sys.a_Bus{1}.replace_component('
    "2  indexed, bus 5",         'sys.a_Bus{5}.replace_component('
    "2  indexed, bus 4 (empty)", 'sys.a_Bus{4}.replace_component('
    "3  function, bus 1",        'replace_component(sys.a_Bus{1}, '
    "3  function, bus 5",        'replace_component(b5, '
    "4  Key",                    'b1.replace_component("SG1B001", '
    "4  after Key",              'b1.replace_component("SG1B001", "gen-park", '
    "4  Controllers=",           'b1.replace_component("SG1B001", "gen-park", Controllers='
    "4  'Controllers',",         'b1.replace_component("SG1B001", "gen-park", ''Controllers'', '
    "6  typed prefix",           'b1.replace_component("SG'
    "5  add_component",          'b1.add_component('
    "5  add_component P=",       'b1.add_component("gen-park", '
    };
for k = 1:size(sc_case, 1)
    s_code = sc_case{k,2};
    fprintf('\n[%s]  %s|\n    %s\n', sc_case{k,1}, s_code, completion_summary(s_code));
end

% The choices follow the current state: a second component on bus 5
evalc('b5.add_component("load-power");');
s_code = 'b5.replace_component(';
fprintf('\n[6  after add_component]  %s|\n    %s\n', s_code, completion_summary(s_code));

function s = completion_summary(s_code)
    % Choices of the argument at the end of s_code, from the programming aids.
    % The choices= expressions are evaluated in the workspace of the caller of the
    % builtin, so it is called in the base workspace, where sys, b1 and b5 live.
    assignin('base', 'c_code_completion__', s_code);
    s_json = evalin('base', "builtin('_programmingAidsTest', '', c_code_completion__, numel(c_code_completion__), [])");
    evalin('base', 'clear c_code_completion__');
    sct = jsondecode(s_json);
    if ~isfield(sct, 'signatures') || isempty(sct.signatures)
        s = "(no signature)";
        return
    end
    sig = sct.signatures(1);
    if iscell(sig), sig = sig{1}; end
    s = "source: " + string(sig.signatureSource);
    a_arg = sig.inputArguments;
    if ~iscell(a_arg), a_arg = num2cell(a_arg); end
    for i = 1:numel(a_arg)
        arg = a_arg{i};
        if isfield(arg, 'status') && arg.status == "presenting"
            s = s + newline + "    presenting " + arg.name + ": " + choices_of(arg);
        end
    end
end

function s = choices_of(arg)
    if ~isfield(arg, 'widgetData') || ~isfield(arg.widgetData, 'choices')
        s = "(no choices, widget " + string(arg.widgetType) + ")";
        return
    end
    c = arg.widgetData.choices;
    if ~iscell(c), c = num2cell(c); end
    sv = strings(1, 0);
    for i = 1:numel(c)
        sv(end+1) = string(c{i}.completion);    %#ok<AGROW>
    end
    s = "[" + join(sv, " ") + "]";
    if isempty(sv), s = "[] (empty)"; end
end
