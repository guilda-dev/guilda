% F86 解列と開放の時刻 1 つ、add_input の入力名の補完、add_scenario の既定のタグ
%
%   sc = net.add_scenario();                   % タグ "CASE" (使用中なら番号を足す)
%   sc.add_trip("B003SG1", 1);                 % t = 1 から終わりまで解列
%   sc.add_open_branch("EL003", 1.05);         % t = 1.05 から終わりまで開放
%   sc.add_input("B002SG1", <Tab>              % name の候補はその機器の入力名
%
% 解列と開放は対象ごとに tab_event の 1 行で、実行の終わりまで続く (再接続はない)。
% 同じ対象の 2 つ目の並列のイベントはエラー。補完の候補は未公開の
% builtin('_programmingAidsTest', ...) で取得する (F34 と同じ。式はベースワークスペースで評価される)。
%
% 実行: runtests("DebugScript.test_F86_scenario_scalar_time")  または  DebugScript.run_all("Features","F86")

c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% A trip and an opening take one time and last to the end of the run
net = network.IEEE9bus();
sc = net.add_scenario("scalar", Time=[0, 2]);
ev_t = sc.add_trip("B005LRX1", 1);
ev_b = sc.add_open_branch("EL006", 1.5);
assert(ev_t.r_time == 1 && ev_b.r_time == 1.5)
tab = sc.tab_event;
assert(isequal(tab.Tag, ["Parallel001"; "Parallel002"]) && isequal(tab.Target, ["B005LRX1"; string(net.a_Branch{6})]))
assert(isequal(tab.Time, [1; 1.5]) && isequal(tab.Status, ["open"; "6open"]) && all(isnan(tab.Point)))
[res, flag, out] = net.simulate(sc.s_tag);
assert(flag == 1, out.message)
assert(isequal(out.phases.t1.', [0, 1, 1.5]) && isequal(out.phases.Parallel001.', [false, true, true]) ...
       && isequal(out.phases.Parallel002.', [false, false, true]), "解列と開放は終わりまで続く")
I = res.odeResults.Bus(5).Component(1).I{:,:};   % B005LRX1
assert(all(isnan(I(res.rv_t > 1, :)), "all") && ~any(isnan(I(res.rv_t < 1, :)), "all"), "解列した負荷は終わりまで NaN")
% 時刻は 1 つ: 2 つの数はエラー
assert(error_id(@() sc.add_trip("B007LRX1", [1, 2])) ~= "")
assert(error_id(@() ev_b.edit(Time=[1, 2])) ~= "" && ev_b.r_time == 1.5)
assert(error_id(@() EventTrip("B005LRX1", [1, 2])) ~= "")


%% A target has at most one parallel event
net = network.IEEE9bus();
sc = net.add_scenario("once");
sc.add_trip("B005LRX1", 1);
assert(error_id(@() sc.add_trip("B005LRX1", 2)) == "GUILDA:Scenario:OverlappingEvents")
sc.add_open_branch("EL006", 1);
assert(error_id(@() sc.add_open_branch("EL006", 0.5, Status="3open")) == "GUILDA:Scenario:OverlappingEvents")
assert(numel(sc.a_Event) == 2, "失敗したら追加しない")
% 開放と同じブランチの地絡は重なってよい
sc.add_fault(string(net.a_Branch{6}), [0.5, 1.2], Status="6LG", Point=0.5);
assert(numel(sc.a_Event) == 3)


%% add_input suggests the input names of the chosen component
net = network.IEEE9bus();
c_cleanup = onCleanup(@() evalin("base", "clear net__F86 sc__F86"));
assignin("base", "net__F86", net);
assignin("base", "sc__F86", net.add_scenario("comp"));
sv_u = net.get_element("B001SG1").sv_u.';
assert(~isempty(sv_u))
sv = choices('sc__F86.add_input("B001SG1", ');
assert(all(ismember(sv_u, sv)) && ~ismember("B001SG1", sv), join(sv, ", "))
% EventInput.edit の Name はそのイベントの機器の入力名
s_file = fullfile(GUILDA.pwd, "_GUILDAsystem", "resources", "functionSignatures.json");
c_in = jsondecode(fileread(s_file, "Encoding", "UTF-8")).EventInput_edit.inputs;
if isstruct(c_in), c_in = num2cell(c_in); end
c_name = c_in(cellfun(@(a) a.name == "Name", c_in));
sv_type = string(c_name{1}.type{1});
obj = net.a_Scenario{1}.add_input("B001SG1", sv_u(1), 0.01, [1, 2]); %#ok<NASGU> used by the choice expression
sv = string(eval(extractAfter(sv_type(startsWith(sv_type, "choices=")), "choices=")));
assert(isequal(sv(:).', sv_u), join(sv, ", "))


%% add_scenario without a tag uses CASE
net = network.IEEE9bus();
sc1 = net.add_scenario();
assert(sc1.s_tag == "CASE" && isequal(sc1.Time, [0, 10]))
s_out = evalc("sc2 = net.add_scenario(Time=[0, 5]);");
assert(sc2.s_tag ~= "CASE" && startsWith(sc2.s_tag, "CASE") && isequal(sc2.Time, [0, 5]), sc2.s_tag)
assert(contains(s_out, sc2.s_tag), s_out)


function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end

function sv = choices(s_code)
    % Completions offered for the argument at the end of s_code (evaluated in the base workspace)
    arguments (Input)
        s_code (1,:) char  % Code typed so far.
    end
    arguments (Output)
        sv  % Suggested values, without quotes (string row).
    end
    assignin("base", "c_code__F86", s_code);
    s_json = evalin("base", "builtin('_programmingAidsTest', '', c_code__F86, numel(c_code__F86), [])");
    evalin("base", "clear c_code__F86");
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
