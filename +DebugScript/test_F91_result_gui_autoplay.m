% F91 結果の GUI で、動く描画を描いたら再生を始める (DrawerResultGUI の autoplay、GraphBase.play)
%
%   res.launch_gui();   % plot_spring_model や plot_diagram (時刻が 2 つ以上) を描くと Play を押したように再生する
%
% autoplay は G.play() を呼ぶ (再生バーの Play と同じ timer、Tag "GUILDA:GraphBase:Playback")。
% matlab -batch と見えない窓では再生しない (timer も作らない) こと、プロットのパネルの再生バーの
% Play が animate の間は Pause を示し、Play を押しても二重に再生せず、Pause で次の画で止まること、
% 軸が消える (ほかの描画への置き換え、窓を閉じる) と animate が止まること、Display options が時刻の
% 行のない操作パネル (GraphChart は "No controls for this graph.") でも動くことを確かめる。見える窓で
% 実際に再生が始まり (timer があり Play が Pause を示す)、ボタンの処理を止めず、窓を閉じる・描き直す・
% 軸を消すと timer が残らないことは、batchStartupOptionUsed を隠して見える窓で確かめる (test_F61・F100 と同じ)。
% 小さな系統 (IEEE9bus) の 0.5 秒のシミュレーションを使う。
%
% 実行: runtests("DebugScript.test_F91_result_gui_autoplay")  または  DebugScript.run_all("Features","F91")

% 共通設定 (各テストの前に毎回実行される)
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% A plot that animates does not play under matlab -batch or in a hidden window and leaves no timer
a_before = findall(groot, "Type", "figure");
res = fault_result();
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
press(fig, "plot_spring_model", "ResultODE.plot_spring_model", ["", "Run"]);
G = h.history.get_variable("G");
assert(isa(G, "GraphBase") && numel(G.rv_t) >= 2)
pause(0.3);
assert(G.i_time == 1, "a hidden window does not play")
assert(isempty(timerfindall("Tag", "GUILDA:GraphBase:Playback")))
assert(bar_play(fig).Text == "Play")
press(fig, "plot_diagram", "ResultODE.plot_diagram", ["", "Run"]);
G = h.history.get_variable("G");
pause(0.3);
assert(isa(G, "GraphNetDiagram") && numel(G.rv_t) >= 2 && G.i_time == 1)
assert(isempty(timerfindall("Tag", "GUILDA:GraphBase:Playback")))
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


%% Play of the playback bar shows Pause while animate plays; Play does not start a second one; Pause stops it
a_before = findall(groot, "Type", "figure");
res = fault_result();
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
press(fig, "plot_diagram", "ResultODE.plot_diagram", ["", "Run"]);
G = h.history.get_variable("G");
w_play = bar_play(fig);
assert(w_play.Text == "Play" && ~w_play.Value)
st = containers.Map("KeyType", "char", "ValueType", "any");
st("k") = 0;
st("text") = strings(1, 0);
st("timer") = 0;
G.animate(Speed=Inf, TimeStep=0.01, UpdateFcn=@(~) on_frame(st, w_play));
n_frame = numel(0:0.01:0.5);
assert(st("k") == 4 && st("k") < n_frame, "Pause stops at the next frame: " + st("k"))
assert(all(st("text") == "Pause"), join(st("text")))
assert(st("timer") == 0, "Play while animate plays starts no timer")
assert(G.i_time < numel(G.rv_t))
assert(w_play.Text == "Play" && ~w_play.Value)
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


%% Deleting the axes stops the animation: another plot in the panel or a closed window
a_before = findall(groot, "Type", "figure");
res = fault_result();
fig = uifigure("Visible", "off");
h_parent = uipanel(fig);
G = res.plot_spring_model(Parent=h_parent);
st = containers.Map("KeyType", "char", "ValueType", "any");
st("k") = 0;
G.animate(Speed=Inf, TimeStep=0.01, UpdateFcn=@(~) count_then(st, 3, @() delete(h_parent.Children)));
assert(st("k") == 3)
G = res.plot_spring_model(Parent=h_parent);
st("k") = 0;
G.animate(Speed=Inf, TimeStep=0.01, UpdateFcn=@(~) count_then(st, 3, @() delete(fig)));
assert(st("k") == 3 && ~isvalid(fig))
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


%% Display options without a time row: the diagram shows its controls and a time chart none
a_before = findall(groot, "Type", "figure");
res = fault_result();
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
h_grid = findall(fig, "Tag", "plot_grid");
h_toggle = findall(fig, "Tag", "controls");
h_toggle = h_toggle(arrayfun(@(x) isa(x, "matlab.ui.control.StateButton"), h_toggle));
h_toggle.Value = true;
h_toggle.ValueChangedFcn(h_toggle, []);
press(fig, "plot_diagram", "ResultODE.plot_diagram", ["", "Run"]);
G = h.history.get_variable("G");
assert(isa(G, "GraphNetDiagram") && h_grid.ColumnWidth{2} == 230)
assert(isempty(findall(G.h_controls, "Tag", "GUILDA:GraphBase:TimeSlider")), "the time is in the bar, not in the panel")
assert(isscalar(findall(findall(fig, "Type", "uipanel", "Tag", "plot"), "Tag", "GUILDA:GraphBase:TimeSlider")))
press(fig, "plot_trajectory", "ResultODE.plot_trajectory", ["", "Run"]);
G = h.history.get_variable("G");
assert(isa(G, "GraphChart") && numel(G.rv_t) >= 2)
assert(h_grid.ColumnWidth{2} == 0, "a chart has no controls: no empty column")
h_label = findall(G.h_controls, "Type", "uilabel");
assert(any(cellfun(@(c) any(string(c) == "No controls for this graph."), {h_label.Text})))
assert(isscalar(bar_play(fig)), "the chart keeps its playback bar")
h_toggle.Value = false;
h_toggle.ValueChangedFcn(h_toggle, []);
assert(h_grid.ColumnWidth{2} == 0)
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


%% A visible window starts playing by a timer and the button returns; closing, replotting or deleting the axes leaves no timer
% -batch では timer を作らないので、この節だけ batchStartupOptionUsed を false を返す関数で隠し
% (test_F61・F100 と同じ)、見える uifigure で本物の timer を確かめる
a_before = findall(groot, "Type", "figure");
s_timer = "GUILDA:GraphBase:Playback";
c_path = hide_batch_startup();    %#ok<NASGU>
res = fault_result();
fig = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
h = res.launch_gui(fig);
press(fig, "plot_spring_model", "ResultODE.plot_spring_model", ["", "Run"]);
G = h.history.get_variable("G");
assert(isa(G, "GraphSpringBase"))
assert(isscalar(timerfindall("Tag", s_timer)), "one playback: the first plot's timer went with its axes")
w_play = bar_play(fig);
assert(w_play.Text == "Pause" && w_play.Value, "the bar shows Pause while it plays")
t_wait = tic;    % the timer plays the samples during a pause (0.5 s of data at real time)
while ~isempty(timerfindall("Tag", s_timer)) && toc(t_wait) < 10
    pause(0.1);
end
assert(G.i_time == numel(G.rv_t), "played to the end")
assert(isempty(timerfindall("Tag", s_timer)) && w_play.Text == "Play")
% 描き直す: 前の図の timer は軸とともに消え、新しい図が再生する
press(fig, "plot_diagram", "ResultODE.plot_diagram", ["", "Run"]);
G = h.history.get_variable("G");
assert(G.FlowAnimation && isscalar(timerfindall("Tag", s_timer)))
press(fig, "plot_spring_model", "ResultODE.plot_spring_model", ["", "Run"]);
assert(isscalar(timerfindall("Tag", s_timer)), "replotting leaves only the new timer")
% 時刻のグラフは再生しない
press(fig, "plot_trajectory", "ResultODE.plot_trajectory", ["", "Run"]);
assert(isa(h.history.get_variable("G"), "GraphChart") && isempty(timerfindall("Tag", s_timer)))
% 軸を消す
press(fig, "plot_spring_model", "ResultODE.plot_spring_model", ["", "Run"]);
G = h.history.get_variable("G");
assert(isscalar(timerfindall("Tag", s_timer)))
delete(G.ax(1));
assert(isempty(timerfindall("Tag", s_timer)), "deleting the axes deletes the timer")
% 窓を閉じる
press(fig, "plot_diagram", "ResultODE.plot_diagram", ["", "Run"]);
assert(isscalar(timerfindall("Tag", s_timer)))
delete(fig);
assert(isempty(timerfindall("Tag", s_timer)), "closing the window deletes the timer")
pause(0.3);
assert(isempty(timerfindall("Tag", s_timer)))
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


%% The iterations of an OPF play: the chart plays by one timer and the linked network diagram follows; closing the window leaves no timer
% GraphChart の G_chart は、同じ呼び出しの出力 G_net (GraphNetDiagram、反復が 2 つ以上) を動かすので
% 再生する (plot_iteration)。timer は G_chart の 1 つだけで、G_net は link で同じ反復に動く。
% 見えない窓では再生しない。見える窓は batchStartupOptionUsed を隠して確かめる
a_before = findall(groot, "Type", "figure");
s_timer = "GUILDA:GraphBase:Playback";
res = DebugScript.helper.quiet(@() network.IEEE9bus().calculate_optimal_powerflow(Method="AC OPF"));
fig = uifigure("Visible", "off");
h = res.launch_gui(fig);
press(fig, "plot_iteration", "", strings(0, 2));
G_net = h.history.get_variable("G_net");
assert(isa(h.history.get_variable("G_chart"), "GraphChart") && numel(G_net.rv_t) >= 2)
i_drawn = G_net.i_time;
pause(0.3);
assert(G_net.i_time == i_drawn && isempty(timerfindall("Tag", s_timer)), "a hidden window does not play")
delete(fig);
c_path = hide_batch_startup();    %#ok<NASGU>
fig = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
h = res.launch_gui(fig);
assert(isempty(timerfindall("Tag", s_timer)), "the default plot (plot_dispatch, a chart alone) does not play")
press(fig, "plot_iteration", "", strings(0, 2));
G_chart = h.history.get_variable("G_chart");
G_net = h.history.get_variable("G_net");
assert(isscalar(timerfindall("Tag", s_timer)), "one playback: " + numel(timerfindall("Tag", s_timer)))
assert(bar_play(fig).Text == "Pause")
iv_seen = G_net.i_time;
t_wait = tic;    % 1 iteration per second (PlaySpeed 1)
while numel(unique(iv_seen)) < 3 && toc(t_wait) < 10
    pause(0.1);
    iv_seen(end+1) = G_net.i_time; %#ok<AGROW>
end
assert(numel(unique(iv_seen)) >= 3, "the network diagram moves: " + join(string(unique(iv_seen))))
assert(G_net.i_time == G_chart.i_time, "the network diagram follows the chart")
assert(isscalar(timerfindall("Tag", s_timer)))
delete(fig);
assert(isempty(timerfindall("Tag", s_timer)), "closing the window deletes the timer")
pause(0.3);
assert(isempty(timerfindall("Tag", s_timer)) && isempty(timerfindall("Tag", "GUILDA:GraphNetDiagram:Flow")))
close_new_figures(a_before);    % このテストで開いた図を閉じる (共通設定はファイルで 1 回だけ実行されるため)


function res = fault_result()
% IEEE9bus の 0.5 秒の故障のシミュレーション
    net = network.IEEE9bus();
    sc = net.add_scenario("fault");
    sc.add_fault("B004", [0.1, 0.15]);
    res = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 0.5]));
end

function w = bar_play(fig)
% プロットのパネルの再生バーの Play (状態ボタン、一つ)
    w = findall(findall(fig, "Type", "uipanel", "Tag", "plot"), "Tag", "GUILDA:GraphBase:Play");
    assert(isscalar(w), "Play of the playback bar: " + numel(w))
end

function on_frame(st, w_play)
% 再生の各画: 2 画目にバーの Play の表示を記録して Play を押す (無視される)。3 画目に timer を数え、4 画目に Pause を押す
    st("k") = st("k") + 1;
    switch st("k")
        case 2
            st("text") = [st("text"), string(w_play.Text)];
            w_play.Value = true;
            w_play.ValueChangedFcn(w_play, []);    % Play while playing: ignored
        case 3
            st("text") = [st("text"), string(w_play.Text)];
            st("timer") = numel(timerfindall("Tag", "GUILDA:GraphBase:Playback"));
        case 4
            w_play.Value = false;
            w_play.ValueChangedFcn(w_play, []);    % Pause
    end
end

function c_path = hide_batch_startup()
% batchStartupOptionUsed を false を返す関数で隠す (test_F61・F100 と同じ)。c_path が消えると戻す
    s_dir = tempname;
    mkdir(s_dir);
    fid = fopen(fullfile(s_dir, "batchStartupOptionUsed.m"), "w");
    fprintf(fid, "function tf = batchStartupOptionUsed()\ntf = false;\nend\n");
    fclose(fid);
    sct_warn = warning("off", "MATLAB:dispatcher:nameConflict");
    addpath(s_dir);
    c_path = onCleanup(@() restore_path(s_dir, sct_warn));
    assert(~batchStartupOptionUsed(), "前提: 隠せた")
end

function restore_path(s_dir, sct_warn)
% batchStartupOptionUsed を隠す一時フォルダを外して消し、残った timer を消す
    rmpath(s_dir);
    rmdir(s_dir, "s");
    warning(sct_warn);
    hv_t = [timerfindall("Tag", "GUILDA:GraphBase:Playback"), timerfindall("Tag", "GUILDA:GraphNetDiagram:Flow")];
    if ~isempty(hv_t)
        stop(hv_t);
        delete(hv_t);
    end
end

function count_then(st, k_act, f_act)
% 再生の画を数え、k_act 画目に f_act を呼ぶ
    st("k") = st("k") + 1;
    if st("k") == k_act
        f_act();
    end
end

function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function press(fig, s_method, s_dialog, sm_step)
% メソッドのボタンを押す。s_dialog のダイアログの欄の入力とボタンの押下をタイマーで行う (s_dialog が "" ならダイアログなし)
    if s_dialog ~= ""    % "": a method without a dialog (plot_iteration)
        t = timer("ExecutionMode", "fixedSpacing", "Period", 0.2, "TimerFcn", @(t, ~) press_in_dialog(t, s_dialog, sm_step));
        c_timer = onCleanup(@() delete(t));
        start(t);
    end
    h = findall(fig, "Type", "uibutton", "Tag", "method");
    h = h(endsWith(string({h.UserData}), "." + s_method));
    assert(isscalar(h), "button " + s_method)
    h.ButtonPushedFcn(h, []);
end

function press_in_dialog(t, s_name, sm_step)
% ask のダイアログで、欄への入力とボタンの押下を順に行う ([タグ, 値] または ["", ボタンの文字])
    h_fig = findall(groot, "Type", "figure", "Name", s_name);
    if ~isscalar(h_fig) || isempty(findall(h_fig, "Type", "uibutton", "Text", "Cancel"))
        return
    end
    stop(t);
    for i = 1:size(sm_step, 1)
        if ~isvalid(h_fig)
            return
        end
        if sm_step(i, 1) == ""
            h = findall(h_fig, "Type", "uibutton", "Text", sm_step(i, 2));
            h.ButtonPushedFcn(h, []);
        else
            h = findall(h_fig, "Tag", sm_step(i, 1));
            h.Value = sm_step(i, 2);
            h.ValueChangedFcn(h, []);
        end
        drawnow
    end
end
