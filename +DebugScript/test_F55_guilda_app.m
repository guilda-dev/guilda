% F55 GUILDA のアプリ (GUILDA.launch_gui, DrawerGUILDA)
%
%   h = GUILDA.launch_gui();        % 開始画面: 空の系統 / サンプル系統 / フォルダ / MATPOWER
%   h = GUILDA.launch_gui(net);     % 渡した系統で始める
%   h.history.get_script()          % アプリの操作を再現するスクリプト
%
% 開始画面の 4 つの選択肢 (読み込みは一時フォルダに書き出した小さな系統)、launch_gui(net) のヘッダー、
% タブの切り替え、図のクリック → モデルの GUI → 母線の追加 → 図の描き直しと選択の維持、パンくずの
% 移動 (TargetChanged) → 選択、古い状態の帯 → initialize、書き出したスクリプトが同じ系統を作ることを
% 確かめる。アプリは見えない図 (DrawerGUILDA(..., Visible=false)) に作る。追加ボタンのダイアログは
% F51 と同じくタイマーで押す (ask は誰も押さなければ 10 秒以内に "" を返す)。
%
% 実行: runtests("DebugScript.test_F55_guilda_app")  または  DebugScript.run_all("Features","F55")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% The start screen makes an empty network as the first line of the script
h = DrawerGUILDA([], Visible=false);
f = h.h_figure;
assert(isa(h.history, "HistoryGUILDA") && isempty(h.history.tab_entry) && isempty(h.G))
h_tab = findall(f, "Tag", "tab");
assert(numel(h_tab) == 6 && ~any([h_tab.Enable]))    % 系統がないうちはタブを押せない
assert(isempty(findall(f, "Tag", "main")))
h_sample = findall(f, "Tag", "start_sample");
assert(all(ismember(["IEEE9bus", "IEEE14bus", "Tutorial3bus"], string(h_sample.Items))) && ~ismember("archive", string(h_sample.Items)))
press(f, "start_empty");
assert(isempty(findall(f, "Tag", "start")) && isscalar(findall(f, "Tag", "main")) && all([h_tab.Enable]))
net = h.history.get_variable("net");
assert(isa(net, "PowerNetwork") && isempty(net.a_Bus))
assert(contains(h.history.get_script(), "% New network" + newline + "net = PowerNetwork();"))
assert(isscalar(findall(f, "Tag", "diagram_empty")) && isempty(h.G))    % 母線がない系統は図の代わりに案内
assert(contains(info_text(f), "0 buses") && contains(info_text(f), "New network"))


%% A sample network, a model folder and a MATPOWER case are loaded through the history
% サンプル系統
h = DrawerGUILDA([], Visible=false);
h_sample = findall(h.h_figure, "Tag", "start_sample");
h_sample.Value = "Tutorial3bus";
press(h.h_figure, "start_sample_load");
assert(isa(h.history.get_variable("net"), "network.Tutorial3bus") && h.history.tab_entry.Code(1) == "net = network.Tutorial3bus();")
assert(isa(h.G, "GraphNetDiagram") && sum(h.G.tab_element.Kind == "bus") == 3)
% フォルダ: net.export で書き出した系統
s_dir = fullfile(tempname, "app_net");
mkdir(fileparts(s_dir));
c_dir = onCleanup(@() rmdir(fileparts(s_dir), "s"));
DebugScript.helper.quiet(@() network.Tutorial3bus().export(s_dir));
h = DrawerGUILDA([], Visible=false);
h_path = findall(h.h_figure, "Tag", "start_folder");
h_path.Value = s_dir;
press(h.h_figure, "start_folder_load");
assert(h.history.tab_entry.Code(1) == "net = PowerNetwork.import(""" + s_dir + """);" && h.history.tab_entry.Status(1) == "done")
assert(numel(h.history.get_variable("net").a_Bus) == 3)
% MATPOWER: .mat のケース
mpc = DebugScript.helper.case14_data(); %#ok<NASGU> save が使う
s_mat = fullfile(fileparts(s_dir), "case14_app.mat");
save(s_mat, "mpc");
h = DrawerGUILDA([], Visible=false);
h_path = findall(h.h_figure, "Tag", "start_matpower");
h_path.Value = s_mat;
press(h.h_figure, "start_matpower_load");
assert(h.history.tab_entry.Code(1) == "net = PowerNetwork.import_matpower(""" + s_mat + """);" && h.history.tab_entry.Status(1) == "done", h.history.tab_entry.Detail(1))
assert(numel(h.history.get_variable("net").a_Bus) == 14)


%% A failed choice stays on the start screen with its message
h = DrawerGUILDA([], Visible=false);
h_path = findall(h.h_figure, "Tag", "start_folder");
h_path.Value = fullfile(tempdir, "no_such_folder_F55");
press(h.h_figure, "start_folder_load");
assert(h.history.tab_entry.Status(1) == "fail" && isscalar(findall(h.h_figure, "Tag", "start")))
assert(startsWith(findall(h.h_figure, "Tag", "start_message").Text, "Could not load"))
assert(h.history.get_script() == "% Script of the GUILDA app (GUILDA.launch_gui)." + newline)


%% launch_gui(net) works on the network passed and says so in the script header
net = network.IEEE9bus;
h = GUILDA.launch_gui(net);
h.h_figure.Visible = "off";
assert(isa(h, "DrawerGUILDA") && h.history.get_variable("net") == net && isempty(h.history.tab_entry))
assert(contains(h.history.get_script(), "% net is the network passed at startup (GUILDA.launch_gui(net))"))
assert(isa(h.G, "GraphNetDiagram") && isempty(h.G.Selection) && contains(info_text(h.h_figure), "9 buses"))
assert(error_id(@() GUILDA.launch_gui(5)) == "GUILDA:DrawerGUILDA:NotNetwork")


%% The tab bar switches the panel of the right half
h = DrawerGUILDA(network.IEEE9bus, Visible=false);
f = h.h_figure;
sv_key = ["model", "pf", "opf", "cpf", "sim", "lin"];
h_tab = arrayfun(@(k) findall(f, "Tag", "tab", "UserData", k), sv_key);
assert(isequal(string({h_tab.Text}), ["Model", "Power flow", "OPF", "CPF", "Time simulation", "Linearization"]))
assert(isequal([h_tab.Value], [true false false false false false]))
for k = [2:6, 1]
    h_tab(k).Value = true;
    h_tab(k).ValueChangedFcn(h_tab(k), []);
    assert(isequal([h_tab.Value], (1:6) == k))
    h_panel = arrayfun(@(s) findall(f, "Tag", "tab_" + s), sv_key);
    assert(isequal(logical([h_panel.Visible]), (1:6) == k))
    assert(k == 1 || isscalar(findall(h_panel(k), "Tag", "run")) || isscalar(findall(h_panel(k), "Tag", "sim_run")))    % 解析のタブは実行ボタン (時間シミュレーションは sim_run、F57)
end
assert(isa(h.G, "GraphNetDiagram"))


%% A click on the diagram shows the element; the selection stays when the diagram is drawn again
net = network.IEEE9bus;
h = DrawerGUILDA(net, Visible=false);
f = h.h_figure;
gui = model_gui(f);
assert(gui.a_target == net)
click(h, "B002");
assert(gui.a_target == net.a_Bus{2} && isequal(h.G.Selection, "B002"))
s_comp = string(net.a_Bus{1}.a_Component{1}.s_tag);
click(h, s_comp, "link");    % 機器と母線の間の線も機器を表示する
assert(gui.a_target == net.a_Bus{1}.a_Component{1} && isequal(h.G.Selection, s_comp))
click(h, string(net.a_Branch{3}.s_tag));
assert(gui.a_target == net.a_Branch{3})
click(h, "B002");
% 母線を追加すると図を描き直し、選択は残る (描き直しは記録しない)
G = h.G;
h.history.run("Model building", "Add a bus", "net.add_bus();");
assert(h.G == G && sum(h.G.tab_element.Kind == "bus") == 10 && isequal(h.G.Selection, "B002"))
assert(height(h.history.tab_entry) == 1)
% モデルの GUI の追加ボタン (ModelChanged) でも描き直し、選択は残る
press_add(gui, "+ Component", "Bus.add_component", ["Key", "load-impedance"; "", "Run"]);
assert(h.history.tab_entry.Code(end) == "net.a_Bus{2}.add_component(""load-impedance"");", h.history.tab_entry.Code(end))
assert(sum(h.G.tab_element.Kind == "component") == 7 && isequal(h.G.Selection, "B002") && gui.a_target == net.a_Bus{2})
assert(contains(info_text(f), "10 buses") && contains(info_text(f), "run initialize"))


%% Navigation in the model GUI (TargetChanged) moves the selection of the diagram
net = network.IEEE9bus;
h = DrawerGUILDA(net, Visible=false);
gui = model_gui(h.h_figure);
count_target();
c_listener = listener(gui, "TargetChanged", @(~, ~) count_target(1)); %#ok<NASGU>
% 子カード: 系統 → 母線 B001 → 機器
press_card(gui, "B001");
assert(isequal(h.G.Selection, "B001"))
comp = net.a_Bus{1}.a_Component{1};
press_card(gui, string(comp.s_tag));
assert(isequal(h.G.Selection, string(comp.s_tag)))
% 制御器は、その機器を選ぶ
avr = comp.a_LocalController{1};
press_card(gui, string(avr.s_tag));
assert(gui.a_target == avr && isequal(h.G.Selection, string(comp.s_tag)))
% パンくず: 母線へ、系統へ (系統は選択なし)
press_crumb(gui, "B001");
assert(gui.a_target == net.a_Bus{1} && isequal(h.G.Selection, "B001"))
press_crumb(gui, string(net.s_tag));
assert(gui.a_target == net && isempty(h.G.Selection))
assert(count_target() == 5)
% 同じモデルを描き直しても TargetChanged は出ない
gui.render();
assert(count_target() == 0)


%% The stale banner runs net.initialize() through the history
net = network.IEEE9bus;
h = DrawerGUILDA(net, Visible=false);
f = h.h_figure;
select_tab(f, "cpf");
h_banner = findall(findall(f, "Tag", "tab_cpf"), "Tag", "stale_banner");
assert(isscalar(h_banner) && ~h_banner.Visible && isequal(h_banner.Parent.RowHeight{h_banner.Layout.Row}, 0))
assert(isempty(findall(findall(f, "Tag", "tab_pf"), "Tag", "stale_banner")))
h.history.run("Model building", "Edit V", "net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;");
assert(h_banner.Visible && contains(findall(h_banner, "Tag", "stale_text").Text, "powerflow"))
assert(contains(info_text(f), "run initialize"))
press(h_banner, "initialize");
assert(h.history.tab_entry.Code(end) == "net.initialize();" && h.history.tab_entry.Group(end) == "Continuation power flow")
assert(h.history.tab_entry.Status(end) == "done" && ~h_banner.Visible && contains(info_text(f), "up to date"))
% 時間シミュレーションと近似線形解析のタブにも帯がある
select_tab(f, "sim");
select_tab(f, "lin");
assert(numel(findall(f, "Tag", "stale_banner")) == 3)


%% The exported script builds the same network in another workspace
h = DrawerGUILDA([], Visible=false);
f = h.h_figure;
press(f, "start_empty");
sv_code = ["net.add_bus();", "net.add_bus(V=1.02);", "net.add_branch(""pi"", [""B001"", ""B002""], X=0.1);", ...
    "net.a_Bus{1}.add_component(""gen-1axis"");", "net.a_Bus{2}.add_component(""load-impedance"");", ...
    "net.a_Bus{1}.l_isSlack = true;", "net.initialize();"];
for s_code = sv_code
    [l_ok, s_detail] = h.history.run("Model building", "Step", s_code);
    assert(l_ok, s_code + ": " + s_detail)
end
assert(sum(h.G.tab_element.Kind == "bus") == 2 && contains(info_text(f), "up to date"))
h_export = findall(f, "Tag", "export");
press(f, "export");
s_file = h_export.UserData;
c_file = onCleanup(@() delete(s_file));
assert(isfile(s_file) && string(fileread(s_file)) == h.history.get_script())
net = h.history.get_variable("net");
net2 = DebugScript.helper.quiet(@() run_script(s_file));
assert(isequal(string(net2.a_Bus), string(net.a_Bus)) && isequal(string(net2.a_Branch), string(net.a_Branch)))
assert(isequal(tools.vcellfun(@(b) string(b.a_Component(:)), net2.a_Bus), tools.vcellfun(@(b) string(b.a_Component(:)), net.a_Bus)))
assert(abs(net2.a_Bus{2}.c_Vequilibrium - net.a_Bus{2}.c_Vequilibrium) < 1e-10)


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function net = run_script(s_file) %#ok<STOUT> net はスクリプトが作る
% 書き出したスクリプトを、このテストと共有しないワークスペースで実行する
    run(s_file);
end

function n = count_target(n_add)
% TargetChanged の回数を数える (引数なしで呼ぶと回数を返して 0 に戻す)
    persistent n_count
    if isempty(n_count)
        n_count = 0;
    end
    if nargin == 0
        n = n_count;
        n_count = 0;
        return
    end
    n_count = n_count + n_add;
end

function press(h_parent, s_tag)
% Tag のボタンを押す
    h = findall(h_parent, "Tag", s_tag);
    assert(isscalar(h), "button " + s_tag)
    h.ButtonPushedFcn(h, []);
end

function s = info_text(f)
% 図の上の情報の帯 (2 行を改行でつなぐ)
    s = join(string(findall(f, "Tag", "info").Text), newline);
end

function select_tab(f, s_key)
% タブのボタンを押す
    h = findall(f, "Tag", "tab", "UserData", s_key);
    h.Value = true;
    h.ValueChangedFcn(h, []);
end

function gui = model_gui(f)
% モデルのタブの DrawerModelGUI
    gui = findall(f, "Tag", "tab_model").UserData.gui;
    assert(isa(gui, "DrawerModelGUI"))
end

function click(h, s_tag, s_kind)
% 図の要素のクリック (ElementClicked) を起こす
    tab = h.G.tab_element;
    l_row = tab.Tag == s_tag;
    if nargin > 2
        l_row = l_row & tab.Kind == s_kind;
    end
    i_row = find(l_row, 1);
    assert(~isempty(i_row), "element " + s_tag)
    notify(h.G, "ElementClicked", GraphEventData(tab.Tag(i_row), tab.Kind(i_row), tab.Index(i_row)));
end

function press_card(gui, s_tag)
% モデルの GUI の子の表で s_tag の行をクリックする
    h_table = findall(gui.h_container, "Type", "uitable", "Tag", "children");
    h_kind = findall(gui.h_container, "Tag", "kind");
    i_row = [];
    for k = string(h_kind.ItemsData)
        h_kind.Value = k;
        h_kind.ValueChangedFcn(h_kind, []);
        h_table = findall(gui.h_container, "Type", "uitable", "Tag", "children");
        i_row = find(cellfun(@(c) string(c.s_tag) == s_tag, h_table.UserData));
        if ~isempty(i_row)
            break
        end
    end
    assert(isscalar(i_row), "row " + s_tag)
    h_table.ClickedFcn(h_table, struct("InteractionInformation", struct("Row", i_row)));
end

function press_crumb(gui, s_tag)
% モデルの GUI のパンくずのリンクを押す
    h_link = findall(gui.h_container, "Type", "uihyperlink", "Tag", "breadcrumb", "Text", s_tag);
    assert(isscalar(h_link), "breadcrumb " + s_tag)
    h_link.HyperlinkClickedFcn(h_link, []);
end

function press_add(gui, s_text, s_signature, sm_step)
% 追加ボタンを押し、開いたフォームでタイマーが欄の入力とボタンの押下を行う
    h_add = findall(gui.h_container, "Type", "uibutton", "Tag", "add", "Text", s_text);
    assert(isscalar(h_add), "button " + s_text)
    t = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, s_signature, sm_step));
    c_timer = onCleanup(@() delete_timer(t));
    start(t);
    n_entry = height(gui.history.tab_entry);
    h_add.ButtonPushedFcn(h_add, []);
    assert(height(gui.history.tab_entry) > n_entry, s_text + ": nothing ran (timer pressed: " + string(t.UserData) + ")")
end

function press_in_dialog(t, s_name, sm_step)
% ask のダイアログで、欄への入力とボタンの押下を順に行う ([タグ, 値] または ["", ボタンの文字])
    h_fig = findall(groot, "Type", "figure", "Name", s_name);
    if ~isscalar(h_fig) || isempty(findall(h_fig, "Type", "uibutton", "Text", "Cancel"))
        t.UserData = sprintf("no (%d figures)", numel(h_fig));
        return
    end
    stop(t);
    t.UserData = "yes";
    for i = 1:size(sm_step, 1)
        if ~isvalid(h_fig)
            return
        end
        if sm_step(i, 1) == ""
            h = findall(h_fig, "Type", "uibutton", "Text", sm_step(i, 2));
            h.ButtonPushedFcn(h, []);
        else
            h = findall(h_fig, "Tag", sm_step(i, 1));
            h.Value = char(sm_step(i, 2));
            h.ValueChangedFcn(h, []);
        end
        drawnow
    end
end

function delete_timer(t)
% タイマーを止めて消す
    if isvalid(t)
        stop(t);
        delete(t);
    end
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
