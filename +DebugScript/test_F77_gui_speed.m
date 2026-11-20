% F77 フォーム・選択の表・結果の GUI の速さ (DrawerOptionDialog.ask の再利用、DrawerResultGUI)
%
%   s_code = DrawerOptionDialog.ask(fig, "PowerNetwork.calculate_optimal_powerflow", Object="net", History=h);
%   h = res.launch_gui();
%
% ask は親の図ごとに隠れたダイアログの窓を 1 つ持って使い回し、同じシグネチャ・Object・Output・
% Exclude のフォームは描き直さずに値だけを戻す。使い回したフォームが既定値から始まること、Value を
% 受けること、欄の部品が変わるときは描き直すこと、窓が親ごとに 1 つで、閉じた後は隠れて名前が無い
% ことを確かめる。結果の GUI はボタンを押すとすぐ印 (薄い青) と待ちのポインターが出て、終われば
% 戻ること、新しい窓は既定の表示状態で開くことを確かめる。
% 時間 (IEEE68bus の OPF の ask の 2 回目以降、結果の GUI) は large。F66 と同じく、決まった基準の
% 作業との比と大きな絶対の上限で判定し、目標との比較は表示する。
%
% 実行: runtests("DebugScript.test_F77_gui_speed")  または  DebugScript.run_all("Features","F77")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% ask reuses its window and its form, which starts again from the defaults
h = history_of(network.IEEE9bus());
fig = uifigure("Visible", "off");
a_window = findall(groot, "Type", "figure", "Tag", "DrawerOptionDialog");    % windows of other parents
s_code = ask_with(fig, "Bus.add_component", @(hd) [set_in(hd, "P", "0.5"), press(hd, "dialog_run")], ...
    Object="net.a_Bus{3}", Output="comp", History=h);
assert(endsWith(s_code, ", P=0.5);"), s_code)
h_first = observed("window");
% 2 回目: 同じ窓、P は既定値に戻っている
s_code = ask_with(fig, "Bus.add_component", @(hd) [observe("P", string(findall(hd, "Tag", "P").Value)), press(hd, "dialog_run")], ...
    Object="net.a_Bus{3}", Output="comp", History=h);
assert(observed("window") == h_first)
assert(~contains(s_code, "P=") && startsWith(s_code, "comp = net.a_Bus{3}.add_component("), s_code)
assert(observed("P") ~= "0.5", observed("P"))
% 窓は親ごとに 1 つで、閉じた後は隠れて名前が無い
h_window = findall(groot, "Type", "figure", "Tag", "DrawerOptionDialog");
h_window = h_window(~ismember(h_window, a_window));
assert(isscalar(h_window) && h_window == h_first && ~h_window.Visible && string(h_window.Name) == "")
% 親を消すと窓も消える
delete(fig)
assert(~isvalid(h_first))


%% A reused form takes Value, and a group opened before is closed again
h = history_of(network.IEEE9bus());
fig = uifigure("Visible", "off");
ask_with(fig, "Bus.add_component", @(hd) [press(hd, "group_Limits"), set_in(hd, "Pmax", "2"), press(hd, "dialog_cancel")], ...
    Object="net.a_Bus{3}", History=h);
s_code = ask_with(fig, "Bus.add_component", @(hd) [observe("Pmax", findall(hd, "Tag", "Pmax").Visible), press(hd, "dialog_run")], ...
    Object="net.a_Bus{3}", History=h, Value=struct("Q", "0.25"));
assert(endsWith(s_code, ", Q=0.25);") && ~contains(s_code, "Pmax"), s_code)
assert(~observed("Pmax"))


%% A form whose fields need other widgets is drawn again
net = network.IEEE9bus();
h = history_of(net);
fig = uifigure("Visible", "off");
ask_with(fig, "PowerNetwork.remove_bus", @(hd) press(hd, "dialog_cancel"), Object="net", History=h);
DebugScript.helper.quiet(@() net.add_bus());    % the choices of the tags change
s_new = string(net.a_Bus{end});
s_code = ask_with(fig, "PowerNetwork.remove_bus", @(hd) [set_in(hd, "sr_BusTag", s_new), press(hd, "dialog_run")], ...
    Object="net", History=h);
assert(contains(s_code, """" + s_new + """"), "code: " + s_code)


%% A method button of the result GUI shows at once that it runs
res = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_powerflow());
fig = uifigure("Visible", "off");
res.launch_gui(fig);
h_button = findall(fig, "Type", "uibutton", "Tag", "method", "UserData", "ResultPF.plot_voltage");
assert(isscalar(h_button))
rv_back = h_button.BackgroundColor;
tm = timer("StartDelay", 0.001, "Period", 0.02, "ExecutionMode", "fixedSpacing", "TimerFcn", @(t, ~) act(t, ...
    @(hd) [observe("back", h_button.BackgroundColor), observe("pointer", string(fig.Pointer)), press(hd, "dialog_cancel")]));
c_timer = onCleanup(@() delete(tm));
observed();
start(tm);
h_button.ButtonPushedFcn(h_button, []);
assert(isequal(observed("back"), tools.gui_palette().rv_header_subtext) && observed("pointer") == "watch")
assert(isequal(h_button.BackgroundColor, rv_back) && string(fig.Pointer) == "arrow")


%% A new result window opens with the default visibility of figures
res = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_powerflow());
fig_vis = get(groot, "DefaultFigureVisible");
c_vis = onCleanup(@() set(groot, "DefaultFigureVisible", fig_vis));
set(groot, "DefaultFigureVisible", "off");
a_before = findall(groot, "Type", "figure");
g = res.launch_gui();
h_window = findall(groot, "Type", "figure");
h_window = h_window(~ismember(h_window, a_before));
assert(isscalar(h_window) && ~h_window.Visible && ~isempty(findall(h_window, "Tag", "DrawerResultGUI")))
assert(isa(g, "DrawerResultGUI"))


%% ask of the OPF form opens fast the second time and the result GUI opens fast on IEEE68bus
% 時間の判定は F66 と同じ: 各回の直前に基準の作業を測り、2 回目以降の最小で比と絶対の上限を見る。
% ask は比 6 未満・1.5 秒未満 (目標 0.3 秒)。結果の GUI は最初のプロットを含み、見えない図では基準の
% 作業がほとんど描かれないので比が大きい (2026-11-18 の計測で 18〜20): 比 30 未満・4 秒未満とし、
% 2 倍の退行で失敗する。窓が描かれるまでの時間 (目標 0.5 秒) は見える図でしか測れないので、ここでは見ない。
net = network.IEEE68bus();
h = history_of(net);
fig = uifigure("Visible", "off");
fig_ref = uifigure("Visible", "off");
n_run = 7;
rv_ref = zeros(1, n_run);
rv_ask = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    t_start = tic;
    ask_with(fig, "PowerNetwork.calculate_optimal_powerflow", @(hd) [observe("ready", toc(t_start)), press(hd, "dialog_cancel")], ...
        Object="net", Output=["res", "flag"], History=h);
    rv_ask(r) = observed("ready");
end
check_time("ask of the OPF form", rv_ask, rv_ref, 6, 1.5);
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
n_run = 4;
rv_ref = zeros(1, n_run);
rv_gui = zeros(1, n_run);
for r = 1:n_run
    rv_ref(r) = reference_time(fig_ref);
    f = uifigure("Visible", "off");
    t_start = tic;
    res.launch_gui(f);
    drawnow
    rv_gui(r) = toc(t_start);
    delete(f)
end
check_time("result GUI of ResultPF (with its first plot)", rv_gui, rv_ref, 30, 4);


function s_code = ask_with(fig, s_signature, f_action, opt)
% ask を開き、ダイアログができたらタイマーから f_action(ダイアログの図) を実行する (窓は observed("window"))
    arguments
        fig
        s_signature (1,1) string
        f_action
        opt.Object (1,1) string
        opt.Output (1,:) string = ""
        opt.History
        opt.Value (1,1) struct = struct()
    end
    tm = timer("StartDelay", 0.001, "Period", 0.01, "ExecutionMode", "fixedSpacing", "TimerFcn", @(t, ~) act(t, f_action, s_signature));
    c_timer = onCleanup(@() delete(tm));
    observed();
    start(tm);
    s_code = DrawerOptionDialog.ask(fig, s_signature, Object=opt.Object, Output=opt.Output, History=opt.History, Value=opt.Value);
    assert(~isstring(observed("error")), "error in the timer: " + observed("error"))
end

function act(tm, f_action, s_name)
% 名前の付いた (開いて待っている) ダイアログがあれば操作する (タイマーの中のエラーは observed("error") に残す)
    if nargin < 3
        h_fig = findall(groot, "Type", "figure", "-regexp", "Tag", "^DrawerOptionDialog");
        h_fig = h_fig(arrayfun(@(f) string(f.Name) ~= "", h_fig));
    else
        h_fig = findall(groot, "Type", "figure", "Name", s_name);
    end
    if isempty(h_fig)
        return
    end
    stop(tm);
    observe("window", h_fig(1));
    try
        f_action(h_fig(1));
    catch ME
        observe("error", string(ME.message));
        press(h_fig(1), "dialog_cancel");
    end
end

function out = press(h_fig, s_tag)
% ボタンを押す (ユーザーの操作と同じくコールバックを呼ぶ)
    h = findall(h_fig, "Tag", s_tag);
    assert(isscalar(h), "button " + s_tag)
    h.ButtonPushedFcn(h, []);
    out = [];
end

function out = set_in(h_fig, s_tag, value)
% 欄に値を入れ、ユーザーの操作と同じくコールバックを呼ぶ
    h = findall(h_fig, "Tag", s_tag);
    assert(isscalar(h), "field " + s_tag)
    h.Value = value;
    h.ValueChangedFcn(h, []);
    out = [];
end

function v = observed(s_key, v)
% タイマーの中で見た値を記録し (2 引数)、読む (1 引数)。引数なしで消す
    persistent sct
    if nargin == 0 || isempty(sct)
        sct = struct();
    end
    if nargin == 2
        sct.(s_key) = v;
    elseif nargin == 1
        v = [];
        if isfield(sct, s_key)
            v = sct.(s_key);
        end
    end
end

function out = observe(s_key, v)
% observed に記録する (式の中で使えるように値を返す)
    observed(s_key, v);
    out = [];
end

function t = reference_time(fig)
% 決まった基準の作業の時間: 20 行の uilabel と uieditfield の格子を作って描く (F66 と同じ)
    t_start = tic;
    g = uigridlayout(fig, [20 2]);
    for k = 1:20
        uilabel(g, "Text", "label " + k);
        uieditfield(g, "text", "Value", string(k));
    end
    drawnow
    t = toc(t_start);
    delete(g);
end

function check_time(s_name, rv_time, rv_ref, r_ratio, r_limit)
% 2 回目以降の最小を、基準の最小との比と絶対の上限で判定する
    r_time = min(rv_time(2:end));
    r_ref  = min(rv_ref(2:end));
    fprintf("F77 %s (IEEE68bus): first %.2f s, second and later min %.3f s, median %.3f s; reference min %.3f s, ratio %.2f\n", ...
        s_name, rv_time(1), r_time, median(rv_time(2:end)), r_ref, r_time / r_ref);
    assert(r_time / r_ref < r_ratio, sprintf("%s: %.3f s is %.1f times the reference (%.3f s)", s_name, r_time, r_time / r_ref, r_ref))
    assert(r_time < r_limit, sprintf("%s: %.3f s", s_name, r_time))
end

function h = history_of(net)
% net を持つ実行記録
    h = HistoryGUILDA();
    h.set_variable("net", net);
end

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end
