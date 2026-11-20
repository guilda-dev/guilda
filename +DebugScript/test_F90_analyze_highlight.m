% F90 GUILDA のアプリで、解析の後に「Analyze result」を強調する
%
%   h = DrawerGUILDA(net, Visible=false);   % Run → Analyze result が青の塗り・太字・白字になる
%
% 解析のタブ (潮流計算) と時間シミュレーションのタブで、新しい結果がまだ開かれていない間は
% Analyze result が主のボタン (ロゴの青の塗り、太字、白字) で Run が普通のボタンになり、
% 状態の行の終わりに "open Analyze result" と出ること、結果を開くか実行が失敗すると元の
% 見た目に戻ること、強調にタイマーを使わないことを確かめる。小さな系統 (IEEE9bus) を
% 見えない図で使う。
%
% 実行: runtests("DebugScript.test_F90_analyze_highlight")  または  DebugScript.run_all("Features","F90")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% After a run of an analysis tab Analyze result is the filled primary button until the result is opened
a_before = findall(groot, "Type", "figure");
sct_color = tools.gui_palette();
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
n_timer = numel(timerfindall);    % the app has its own redraw timer
select_tab(f, "pf");
h_tab = findall(f, "Tag", "tab_pf");
h_run = findall(h_tab, "Tag", "run");
h_analyze = findall(h_tab, "Tag", "analyze");
% 実行前: Run が主のボタン、Analyze result は普通で押せない
assert(is_primary(h_run, sct_color) && is_plain(h_analyze, sct_color) && ~h_analyze.Enable)
press(h_tab, "run");
% 実行後: 入れ替わる。状態の行が次の操作を書く
assert(is_primary(h_analyze, sct_color) && is_plain(h_run, sct_color) && h_analyze.Enable)
assert(endsWith(status_text(h_tab), "open Analyze result"), status_text(h_tab))
assert(numel(timerfindall) == n_timer, "the highlight leaves no timer")
% ほかのタブへ移って戻っても強調は残る
select_tab(f, "model");
select_tab(f, "pf");
assert(is_primary(h_analyze, sct_color))
% 開くと元に戻る
press(h_tab, "analyze");
assert(is_primary(h_run, sct_color) && is_plain(h_analyze, sct_color) && h_analyze.Enable)
assert(~contains(status_text(h_tab), "open Analyze result"), status_text(h_tab))
% もう一度実行すると新しい結果なので再び強調
press(h_tab, "run");
assert(is_primary(h_analyze, sct_color) && is_plain(h_run, sct_color))
% 実行の失敗: 変数は前の結果のままなので強調しない
set_field(findall(h_tab, "Tag", "form"), "MaxIteration", "-1");
press(h_tab, "run");
assert(h.history.tab_entry.Status(end) == "fail")
assert(is_primary(h_run, sct_color) && is_plain(h_analyze, sct_color) && h_analyze.Enable)
assert(numel(timerfindall) == n_timer)
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


%% A result that the log makes is new too, and each analysis tab follows its own result
a_before = findall(groot, "Type", "figure");
sct_color = tools.gui_palette();
h = DrawerGUILDA(network.IEEE9bus(), Visible=false);
f = h.h_figure;
select_tab(f, "pf");
h_pf = findall(f, "Tag", "tab_pf");
h.history.run("Power flow", "Power flow", "[res_pf, flag_pf] = net.calculate_powerflow();");
assert(is_primary(findall(h_pf, "Tag", "analyze"), sct_color))
% CPF のタブには結果がないので強調しない
select_tab(f, "cpf");
h_cpf = findall(f, "Tag", "tab_cpf");
assert(is_primary(findall(h_cpf, "Tag", "run"), sct_color) && ~findall(h_cpf, "Tag", "analyze").Enable)
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


%% After a simulation Analyze result of the time simulation tab is highlighted until it is opened
a_before = findall(groot, "Type", "figure");
sct_color = tools.gui_palette();
h = DrawerGUILDA(network.IEEE9bus, Visible=false);
f = h.h_figure;
n_timer = numel(timerfindall);    % the app has its own redraw timer
h.history.run("Time simulation", "Add", "net.add_scenario(""case1"", Time=[0 0.5]); net.a_Scenario{1}.add_fault(""B007"", [0.1 0.15]);");
select_tab(f, "sim");
h_run = findall(f, "Tag", "sim_run");
h_analyze = findall(f, "Tag", "sim_analyze");
assert(is_primary(h_run, sct_color) && is_plain(h_analyze, sct_color) && ~h_analyze.Enable)
press(f, "sim_run");
assert(h.history.tab_entry.Status(end) == "done", h.history.tab_entry.Detail(end))
assert(is_primary(h_analyze, sct_color) && is_plain(h_run, sct_color) && h_analyze.Enable)
s_status = string(findall(f, "Tag", "sim_status").Text);
assert(endsWith(s_status, "open Analyze result"), s_status)
assert(numel(timerfindall) == n_timer)
press(f, "sim_analyze");
assert(is_primary(h_run, sct_color) && is_plain(h_analyze, sct_color) && h_analyze.Enable)
assert(~contains(string(findall(f, "Tag", "sim_status").Text), "open Analyze result"))
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


function l = is_primary(h, sct_color)
% 主のボタン: ロゴの青の塗り、太字、白字
    l = isequal(h.BackgroundColor, sct_color.rv_blue) && isequal(h.FontColor, sct_color.rv_header_text) ...
        && string(h.FontWeight) == "bold";
end

function l = is_plain(h, sct_color)
% 普通のボタン: カードの色、本文の色、太字でない
    l = isequal(h.BackgroundColor, sct_color.rv_card) && isequal(h.FontColor, sct_color.rv_text) ...
        && string(h.FontWeight) == "normal";
end

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function press(h_parent, s_tag)
% Tag のボタンを押す
    h = findall(h_parent, "Tag", s_tag);
    assert(isscalar(h), "button " + s_tag)
    h.ButtonPushedFcn(h, []);
end

function set_field(h_parent, s_tag, value)
% フォームの欄に値を入れ、ユーザーの操作と同じくコールバックを呼ぶ
    h = findall(h_parent, "Tag", s_tag);
    assert(isscalar(h), "field " + s_tag)
    h.Value = value;
    h.ValueChangedFcn(h, []);
end

function select_tab(f, s_key)
% タブのボタンを押す
    h = findall(f, "Tag", "tab", "UserData", s_key);
    h.Value = true;
    h.ValueChangedFcn(h, []);
end

function s = status_text(h_tab)
% タブの状態の行
    s = string(findall(h_tab, "Tag", "status").Text);
end
