% 補完確認: モデルのキーとタグの候補 (_GUILDAsystem/resources/functionSignatures.json)
%
% このスクリプトは runtests / run_all の対象外 (ファイル名が test_ で始まらない)。
% 自動の確認は test_F34_signatures.m。ここでは候補の一覧を表示し、Tab を押したときの表示を
% 手で確かめる。候補は未公開の builtin('_programmingAidsTest', ...) で取得する。補完式は
% ベースワークスペースで評価されるため、コマンドウィンドウからスクリプトとして実行する。
%
% 実行: DebugScript.manual_key_completion
%
% 手動の確認 (このスクリプトの実行後、sys, b1, b4, b5, g1 がワークスペースにある状態で)
% コマンドウィンドウ:
%   1. b1.replace_component(  で Tab → "SG1B001"
%   2. b5.replace_component(  で Tab → "LRX1B005" と "LPQ2B005" (b5 には機器を 1 つ追加済み)
%   3. sys.a_Bus{5}.remove_component(  で Tab → b5 と同じタグ
%   4. b1.replace_component("SG1B001",  で Tab → 機器のキーの一覧 ("gen-park" など)
%   5. b1.replace_component("SG1B001", "gen-park", Controllers=  で Tab → "drop" "keep"
%   6. b4.replace_component(  で Tab → 機器のタグはない (文字列の変数が出ることはある)。続けて
%      "x",  の後で Tab → キーの一覧
%   7. sys.add_branch(  で Tab → ブランチのキー。sys.add_branch("pi",  の後 → 母線のタグ
%   8. sys.remove_bus(  /  sys.remove_branch(  で Tab → 母線 / ブランチのタグ
%   9. b1.add_component("gen-park",  で Tab → P, Q, baseMVA など名前と値の引数
%  10. g1.remove_local_controller(  で Tab → AVR と PSS のタグ。sys.a_Bus{1}.a_Component{1}.remove_local_controller(
%      では候補が出ない (波括弧の添字が 2 つ続く式は MATLAB が型を解決しない)
% エディター (新しいスクリプト、まだ実行しない):
%  11. sys = network.IEEE9bus;  b1 = sys.a_Bus{1};  b1.replace_component("SG1B001",  と書く
%      → Ctrl+Space / Tab でキーの一覧 (変数がなくても出る)
%  12. 同じファイルの  b1.replace_component(  → タグは出ない (変数がまだない)。スクリプトを
%      実行した後 (またはブレークポイントで止めた状態) なら "SG1B001"
% ライブエディター: 11 と 12 を新しいライブスクリプトで同じように確かめる。

evalc('GUILDA.addpath');
evalc('GUILDA.update_keymap');
s_json = fullfile(GUILDA.pwd, '_GUILDAsystem', 'resources', 'functionSignatures.json');
validateFunctionSignaturesJSON(s_json)

sys = network.IEEE9bus;    % net 以外の変数名
b1  = sys.a_Bus{1};
b4  = sys.a_Bus{4};        % 機器のない母線
b5  = sys.a_Bus{5};
evalc('b5.add_component("load-power");');
g1  = b1.a_Component{1};   % 波括弧の添字が 2 つ続く式 (sys.a_Bus{1}.a_Component{1}.) は候補が出ないため変数を通す
sc_case = {
    "Key of add_component",          'b1.add_component('
    "name-value of add_component",   'b1.add_component("gen-park", '
    "tags of bus 1",                 'b1.replace_component('
    "tags of bus 5",                 'b5.replace_component('
    "indexed expression",            'sys.a_Bus{5}.remove_component('
    "function form",                 'replace_component(sys.a_Bus{1}, '
    "Key after the tag",             'b1.replace_component("SG1B001", '
    "Controllers=",                  'b1.replace_component("SG1B001", "gen-park", Controllers='
    "empty bus",                     'b4.replace_component('
    "empty bus, after the tag",      'b4.replace_component("x", '
    "Key of add_branch",             'sys.add_branch('
    "from_to of add_branch",         'sys.add_branch("pi", '
    "remove_bus",                    'sys.remove_bus('
    "remove_branch",                 'sys.remove_branch('
    "Key of add_local_controller",   'b1.a_Component{1}.add_local_controller('
    "remove_local_controller",       'g1.remove_local_controller('
    "two brace indices (none)",      'sys.a_Bus{1}.a_Component{1}.remove_local_controller('
    "Key of add_global_controller",  'sys.add_global_controller('
    "remove_global_controller",      'sys.remove_global_controller('
    };
for k = 1:size(sc_case, 1)
    s_code = sc_case{k,2};
    fprintf('%-30s %-62s -> %s\n', sc_case{k,1}, [s_code '|'], completion_summary(s_code));
end

function s = completion_summary(s_code)
    % Choices of the argument at the end of s_code, evaluated in the base workspace
    arguments (Input)
        s_code (1,:) char   % Code typed so far.
    end
    arguments (Output)
        s   % Name of the argument and its choices.
    end
    assignin('base', 'c_code_completion__', s_code);
    s_out = evalin('base', "builtin('_programmingAidsTest', '', c_code_completion__, numel(c_code_completion__), [])");
    evalin('base', 'clear c_code_completion__');
    sct = jsondecode(s_out);
    if ~isfield(sct, 'signatures') || isempty(sct.signatures)
        s = "(no signature)";
        return
    end
    sig = sct.signatures(1);
    if iscell(sig), sig = sig{1}; end
    a_arg = sig.inputArguments;
    if ~iscell(a_arg), a_arg = num2cell(a_arg); end
    s = "";
    for i = 1:numel(a_arg)
        arg = a_arg{i};
        if isfield(arg, 'status') && arg.status == "presenting"
            s = s + arg.name + ":";
            if isfield(arg, 'widgetData') && isfield(arg.widgetData, 'choices')
                c = arg.widgetData.choices;
                if ~iscell(c), c = num2cell(c); end
                for j = 1:numel(c), s = s + " " + string(c{j}.completion); end
            end
            s = s + "  ";
        end
    end
end
