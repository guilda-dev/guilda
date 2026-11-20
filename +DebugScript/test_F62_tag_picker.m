% F62 タグとモデルキーの表ピッカー (DrawerTagPicker)
%
%   tab = DrawerTagPicker.element_table(net, "Component");   % 1 要素 1 行: Tag, Bus, BusIndex, Position, Class, Key
%   tab = DrawerTagPicker.key_table("Component");            % Key, Class, Description (セッション中キャッシュ)
%   sv  = DrawerTagPicker.pick(fig, tab, Multiple=true, Selected="B001");
%
% 種類ごとの表の列と行 (1 母線に複数の機器がある系統での母線上の位置、AVR の下の PSS)、キーの表、
% 検索による絞り込み (大文字小文字を区別しない、空白区切りの語をすべて含む行)、単一選択・ダブルクリック・
% 複数選択 (検索で隠れた行の選択が残る)、事前選択、キャンセル、ウィンドウの再利用を確かめる。
% ピッカーは見えない親の図に作り、タイマーから検索欄・表・ボタンを操作する (pick は誰も押さなければ
% 10 秒以内に strings(1,0) を返す)。時間の確認 (IEEE68bus の表が 20 ms 未満、2 回目以降の表示が 0.3 秒
% 未満) は medium。
%
% 実行: runtests("DebugScript.test_F62_tag_picker")  または  DebugScript.run_all("Features","F62")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% Every kind of element gives its columns, one row per element
net = build_net();
tab = DrawerTagPicker.element_table(net, "Bus");
assert(isequal(string(tab.Properties.VariableNames), ["Tag", "Index", "Type", "Components"]))
assert(isequal(tab.Tag, ["B001"; "B002"; "B003"]) && isequal(tab.Index, (1:3)'))
assert(isequal(tab.Type, ["slack"; "PV"; "PQ"]) && isequal(tab.Components, [1; 2; 1]))
tab = DrawerTagPicker.element_table(net, "Branch");
assert(isequal(string(tab.Properties.VariableNames), ["Tag", "Index", "From", "To", "Class"]))
assert(height(tab) == 2 && isequal(tab.From, ["B001"; "B002"]) && isequal(tab.To, ["B002"; "B003"]))
assert(all(tab.Class == "branch.pi"))
tab = DrawerTagPicker.element_table(net, "GlobalController");
assert(isequal(string(tab.Properties.VariableNames), ["Tag", "Class", "Units"]))
assert(height(tab) == 1 && tab.Tag == net.a_GlobalController{1}.s_tag && tab.Units == 2 && tab.Class == class(net.a_GlobalController{1}))
tab = DrawerTagPicker.element_table(net, "Scenario");
assert(isequal(string(tab.Properties.VariableNames), ["Tag", "Time", "Description"]))
assert(isequal(tab.Tag, ["case1"; "empty"]) && isequal(tab.Time, ["[0, 3]"; "[0, 10]"]))
assert(isequal(tab.Description, ["fault B003"; ""]))
% 機器のない種類は列だけの表
tab = DrawerTagPicker.element_table(PowerNetwork(), "Component");
assert(height(tab) == 0 && isequal(string(tab.Properties.VariableNames), ["Tag", "Bus", "BusIndex", "Position", "Class", "Key"]))


%% A component row gives its bus and its position on the bus
net = build_net();
tab = DrawerTagPicker.element_table(net, "Component");
assert(isequal(string(tab.Properties.VariableNames), ["Tag", "Bus", "BusIndex", "Position", "Class", "Key"]))
assert(height(tab) == 4)
for i = 1:numel(net.a_Bus)
    a_com = net.a_Bus{i}.a_Component;
    for k = 1:numel(a_com)
        row = tab(tab.Tag == a_com{k}.s_tag, :);
        assert(height(row) == 1 && row.Bus == net.a_Bus{i}.s_tag && row.BusIndex == i && row.Position == k)
        assert(row.Class == class(a_com{k}) && row.Key == a_com{k}.key)
    end
end
assert(isequal(tab.Position(tab.Bus == "B002"), [1; 2]) && isequal(tab.Key(tab.Bus == "B002"), ["gen-park"; "load-power"]))


%% A local controller row gives its component, its bus, its role and the AVR of a PSS
net = build_net();
tab = DrawerTagPicker.element_table(net, "LocalController");
assert(isequal(string(tab.Properties.VariableNames), ["Tag", "Component", "Bus", "Class", "Role", "Parent"]))
gen1 = net.a_Bus{1}.a_Component{1};
gen2 = net.a_Bus{2}.a_Component{1};
avr = gen2.avr;
pss = gen2.pss;
% 母線順、PSS は AVR の直後。調速機の枠は既定の Static の調速機
assert(isequal(tab.Tag, [gen1.avr.s_tag; gen1.governor.s_tag; avr.s_tag; pss.s_tag; gen2.governor.s_tag]))
assert(isequal(tab.Component, [gen1.s_tag; gen1.s_tag; gen2.s_tag; gen2.s_tag; gen2.s_tag]) && isequal(tab.Bus, ["B001"; "B001"; "B002"; "B002"; "B002"]))
assert(isequal(tab.Role, ["avr"; "governor"; "avr"; "pss"; "governor"]) && isequal(tab.Parent, [""; ""; ""; avr.s_tag; ""]))
assert(tab.Class(4) == class(pss) && tab.Class(5) == "controller.governor.Static")


%% The key table lists every key of the key map with the first help line, and is kept
tab = DrawerTagPicker.key_table("Component");
dic = GUILDA.keymap("Component");
assert(isequal(string(tab.Properties.VariableNames), ["Key", "Class", "Description"]))
assert(height(tab) == numEntries(dic) && issorted(tab.Key))
assert(isequal(tab.Class, reshape(dic(tab.Key), [], 1)))
assert(all(tab.Description ~= "") && ~any(startsWith(tab.Description, "%")))
assert(startsWith(tab.Description(tab.Key == "gen-park"), "Park generator model"))
for s_cat = ["Branch", "LocalController", "GlobalController"]
    assert(height(DrawerTagPicker.key_table(s_cat)) == numEntries(GUILDA.keymap(s_cat)))
end
assert(isequal(DrawerTagPicker.key_table("Component"), tab))


%% The search filters the rows on all columns, case-insensitively, with every word
net = build_net();
fig = uifigure("Visible", "off");
tab = DrawerTagPicker.element_table(net, "LocalController");
sv = pick_with(fig, tab, @(h) [search(h, "PSS"), observe("pss", shown(h)), search(h, "b002   AVR_st1"), observe("two", shown(h)), ...
    search(h, "nothing"), observe("none", shown(h)), search(h, ""), observe("all", shown(h)), press(h, "picker_cancel")]);
assert(isempty(sv))
assert(isequal(observed("pss"), tab.Tag(tab.Role == "pss")'))
assert(isequal(observed("two"), tab.Tag(tab.Bus == "B002" & tab.Role == "avr")'))
assert(isempty(observed("none")) && isequal(observed("all"), tab.Tag'))


%% Single pick: the selected row, a double click, and only one row of Selected
net = build_net();
fig = uifigure("Visible", "off");
tab = DrawerTagPicker.element_table(net, "Component");
sv = pick_with(fig, tab, @(h) [search(h, "load"), select(h, 2), press(h, "picker_ok")]);
assert(isequal(sv, tab.Tag(4)))    % 検索後の 2 行目 = B003 の負荷
sv = pick_with(fig, tab, @(h) [search(h, "B002"), double_click(h, 2)]);
assert(isequal(sv, tab.Tag(3)))
sv = pick_with(fig, tab, @(h) [observe("sel", h_table(h).Selection), press(h, "picker_ok")], Selected=tab.Tag([3 1]));
assert(isequal(sv, tab.Tag(1)) && isequal(observed("sel"), 1) && ~h_table_of(fig).Multiselect)
% 列 Key の値を返す (キーの表)
tab_key = DrawerTagPicker.key_table("Component");
sv = pick_with(fig, tab_key, @(h) press(h, "picker_ok"), Column="Key", Selected="gen-park", Title="Component type");
assert(isequal(sv, "gen-park") && h_window(fig).Name == "Component type")
% 表にない列はエラー
try
    DrawerTagPicker.pick(fig, tab, Column="Key2");
    error("F62:NoError", "no error")
catch ME
    assert(string(DebugScript.helper.msg_id(ME)) == "GUILDA:DrawerTagPicker:NoColumn", ME.message)
end


%% Multiple pick keeps the rows hidden by the search, and Selected preselects them
net = build_net();
fig = uifigure("Visible", "off");
tab = DrawerTagPicker.element_table(net, "Bus");
sv = pick_with(fig, tab, @(h) [search(h, "B001"), select(h, 1), search(h, "PQ"), select(h, 1), search(h, ""), ...
    observe("sel", h_table(h).Selection), observe("count", string(findall(h, "Tag", "picker_count").Text)), press(h, "picker_ok")], Multiple=true);
assert(isequal(sv, ["B001", "B003"]) && isequal(observed("sel"), [1 3]) && startsWith(observed("count"), "2 chosen"))
sv = pick_with(fig, tab, @(h) [observe("sel", h_table(h).Selection), press(h, "picker_ok")], Multiple=true, Selected=["B003", "B002", "B099"]);
assert(isequal(sv, ["B002", "B003"]) && isequal(observed("sel"), [2 3]) && h_table_of(fig).Multiselect)
% 検索中に選び直すと、表示中の行だけ選択が替わる
sv = pick_with(fig, tab, @(h) [search(h, "P"), select(h, 2), press(h, "picker_ok")], Multiple=true, Selected=["B001", "B002"]);
assert(isequal(sv, ["B001", "B003"]))


%% Cancel and closing return no value
net = build_net();
fig = uifigure("Visible", "off");
tab = DrawerTagPicker.element_table(net, "Bus");
sv = pick_with(fig, tab, @(h) [select(h, 1), press(h, "picker_cancel")]);
assert(isequal(sv, strings(1, 0)))
sv = pick_with(fig, tab, @(h) [select(h, 1), close_window(h)]);
assert(isequal(sv, strings(1, 0)))
assert(isvalid(h_window(fig)) && ~h_window(fig).Visible)    % 閉じても消さずに隠す


%% One window per parent is reused, recreated when deleted and deleted with its parent
net = build_net();
fig = uifigure("Visible", "off");
tab_bus = DrawerTagPicker.element_table(net, "Bus");
tab_com = DrawerTagPicker.element_table(net, "Component");
pick_with(fig, tab_bus, @(h) press(h, "picker_ok"));
h_first = h_window(fig);
sv = pick_with(fig, tab_com, @(h) [observe("rows", shown(h)), press(h, "picker_ok")], Selected=tab_com.Tag(2));
assert(h_window(fig) == h_first)
assert(isequal(observed("rows"), tab_com.Tag'), strjoin(observed("rows")))
assert(isequal(sv, tab_com.Tag(2)), strjoin(sv))
assert(isempty(getappdata(h_first, "sct_state")))    % 呼び出しが終わると表のデータを持たない
% 別の親は別のウィンドウ、親なしも使える
fig2 = uifigure("Visible", "off");
pick_with(fig2, tab_bus, @(h) press(h, "picker_ok"));
assert(h_window(fig2) ~= h_first)
sv = pick_with([], tab_bus, @(h) [select(h, 3), press(h, "picker_ok")]);
assert(isequal(sv, "B003") && isscalar(findall(groot, "Type", "figure", "Tag", "DrawerTagPicker_none")))
% 消されたウィンドウは作り直す
delete(h_first)
sv = pick_with(fig, tab_bus, @(h) [select(h, 2), press(h, "picker_ok")]);
assert(isequal(sv, "B002") && isvalid(h_window(fig)) && h_window(fig) ~= h_first)
% 親を消すとウィンドウも消える
h_second = h_window(fig);
delete(fig)
assert(~isvalid(h_second))


%% The tables of IEEE68bus take under 20 ms and a second opening under 0.3 s
net = network.IEEE68bus();
for s_kind = ["Bus", "Branch", "Component", "LocalController", "GlobalController", "Scenario"]
    DrawerTagPicker.element_table(net, s_kind);    % 初回の読み込みを除く
    rv_t = zeros(1, 5);
    for r = 1:5
        t_start = tic;
        DrawerTagPicker.element_table(net, s_kind);
        rv_t(r) = toc(t_start);
    end
    fprintf("F62 element_table(IEEE68bus, %s): min %.1f ms, median %.1f ms\n", s_kind, 1000 * min(rv_t), 1000 * median(rv_t));
    assert(min(rv_t) < 0.020, s_kind + " " + min(rv_t))
end
fig = uifigure("Visible", "off");
tab = DrawerTagPicker.element_table(net, "Component");
t_start = tic;
pick_with(fig, tab, @(h) press(h, "picker_ok"));
r_first = toc(t_start);
rv_t = zeros(1, 5);
for r = 1:5
    % 開いてから操作できるまでの時間: 5 ms ごとのタイマーで、開いたウィンドウを最初に見た時刻
    observed();
    t_start = tic;
    tm = timer("StartDelay", 0.001, "Period", 0.005, "ExecutionMode", "fixedSpacing", ...
        "TimerFcn", @(t, ~) act(t, @(h) [observe("ready", toc(t_start)), press(h, "picker_ok")]));
    start(tm);
    DrawerTagPicker.pick(fig, tab, Selected=tab.Tag(r));
    delete(tm)
    rv_t(r) = observed("ready");
end
fprintf("F62 pick(IEEE68bus components): first %.2f s, second and later median %.3f s (max %.3f s)\n", r_first, median(rv_t), max(rv_t));
assert(median(rv_t) < 0.3, "pick " + median(rv_t))


function net = build_net()
% 3 母線: B001 発電機 (AVR)、B002 発電機 (AVR + PSS) と負荷、B003 負荷。AGC 1 台、シナリオ 2 つ
    net = DebugScript.helper.build_3bus("gen-park");
    net.a_Bus{2}.add_component("load-power", "P", -0.1, "Q", -0.05);
    gen2 = net.a_Bus{2}.a_Component{1};
    net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
    gen2.add_local_controller("avr-ST1");
    gen2.add_local_controller("pss-PSS1");
    net.add_global_controller("agc-PI", {net.a_Bus{1}.a_Component{1}, gen2});
    net.add_scenario("case1", Time=[0, 3], Description="fault B003");
    net.add_scenario("empty");
end

function sv = pick_with(h_parent, tab, f_action, varargin)
% ピッカーを開き、データが入ったらタイマーから f_action(ピッカーの図) を実行する
    tm = timer("StartDelay", 0.02, "Period", 0.05, "ExecutionMode", "fixedSpacing", "TimerFcn", @(t, ~) act(t, f_action));
    c_timer = onCleanup(@() delete(tm));
    observed();    % 前回の記録を消す
    start(tm);
    sv = DrawerTagPicker.pick(h_parent, tab, varargin{:});
end

function act(tm, f_action)
% 開いて待っているピッカーがあれば操作する (タイマーの中のエラーは observed("error") に残す)
    h_fig = findall(groot, "Type", "figure", "-regexp", "Tag", "^DrawerTagPicker");
    h_fig = h_fig(arrayfun(@(h) isstruct(getappdata(h, "sct_state")) && getappdata(h, "sct_state").l_open && ~getappdata(h, "sct_state").l_done, h_fig));
    if isempty(h_fig)
        return
    end
    stop(tm);
    try
        f_action(h_fig(1));
    catch ME
        observe("error", ME.message);
        press(h_fig(1), "picker_cancel");
    end
end

function v = observed(s_key, v)
% タイマーの中で見た値を記録し (2 引数)、読む (1 引数)。引数なしで消す
    persistent sct
    if nargin == 0 || isempty(sct)
        sct = struct("error", "");
    end
    if nargin == 2
        sct.(s_key) = v;
    elseif nargin == 1
        assert(sct.error == "", "timer: " + sct.error)
        v = sct.(s_key);
    end
end

function out = observe(s_key, v)
% observed に記録する (配列の中で呼べるよう空を返す)
    observed(s_key, v);
    out = [];
end

function out = search(h_fig, s_text)
% 検索欄に入力する
    h = findall(h_fig, "Tag", "picker_search");
    h.Value = s_text;
    h.ValueChangingFcn(h, struct("Value", s_text));
    out = [];
end

function out = select(h_fig, iv_row)
% 表示中の行を選ぶ
    h = h_table(h_fig);
    h.Selection = iv_row;
    h.SelectionChangedFcn(h, []);
    out = [];
end

function out = double_click(h_fig, i_row)
% 表示中の行をダブルクリックする
    h = h_table(h_fig);
    h.DoubleClickedFcn(h, struct("InteractionInformation", struct("Row", i_row)));
    out = [];
end

function out = press(h_fig, s_tag)
% ボタンを押す
    h = findall(h_fig, "Tag", s_tag);
    h.ButtonPushedFcn(h, []);
    out = [];
end

function out = close_window(h_fig)
% ウィンドウを閉じる
    h_fig.CloseRequestFcn(h_fig, []);
    out = [];
end

function sv = shown(h_fig)
% 表示中の行のタグ
    sv = reshape(string(h_table(h_fig).Data.Tag), 1, []);
end

function h = h_table(h_fig)
% ピッカーの表
    h = findall(h_fig, "Tag", "picker_table");
end

function h = h_window(h_parent)
% 親の図のピッカー
    h = getappdata(h_parent, "DrawerTagPicker");
end

function h = h_table_of(h_parent)
% 親の図のピッカーの表
    h = h_table(h_window(h_parent));
end

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end
