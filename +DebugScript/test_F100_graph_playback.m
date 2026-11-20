% F100 図の再生バー (GraphBase): 2 標本以上の図の軸の下の Play/Pause・時刻のスライダー・文字・速度
%
%   G = GraphSpring2D(sct, Parent=...);   % 2 標本以上で軸の下に再生バー (1 標本はなし)
%   G.PlaySpeed = 2;                       % 速度のドロップダウンと同じ (animate の既定の Speed)
%   部品の Tag: GUILDA:GraphBase:PlaybackBar / Play / TimeSlider / TimeText / PlaySpeed
%   timer の Tag: GUILDA:GraphBase:Playback
%
% 2 標本以上でバーがあり 1 標本ではないこと (set_data で出入りする)、軸がバーに重ならないこと、
% set_time・link・スライダー・set_data でバーが動くこと、Play と G.play() が timer で再生し Pause と
% G.pause() で止まること、play がすぐ戻ること、二重に再生しないこと、PlaySpeed とドロップダウンが
% 同じになること、図を閉じる・軸を消す・図を置き換える・図を消すと timer が残らないこと、再生中に窓を閉じても警告を出さないこと、
% matlab -batch と見えない図では timer を作らずバーは動くこと、部品の Tag、animate の間はボタンが Pause でバーの Pause で止まること、uifigure の
% uipanel・uigridlayout・uitab にバーが出ること、操作パネルに時刻の行がないこと、export_video の
% 画にバーが入らないことを確かめる。timer を確かめる節は batchStartupOptionUsed を隠して見える
% figure に描く (test_F61 と同じ)。ほかは見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F100_graph_playback")  または  DebugScript.run_all("Features","F100")

% 各テストは自分の見えない figure で始め、終わりに閉じる (共有の節は一度だけ走るので、ここでは作らない)。
% 前のテストの timer は残さない
delete(timerfindall("Tag", "GUILDA:GraphBase:Playback"));
% 合成のばね質点データ (test_F61 と同じ): 母線 B1-B3 と B1 の機器ノード G1、21 標本 (0 から 2 s)
rv_t = 0:0.1:2;
sct = struct();
sct.rv_t      = rv_t;
sct.sv_node   = ["B1"; "B2"; "B3"; "G1"];
sct.sv_kind   = ["bus"; "bus"; "bus"; "component"];
sct.cm_V      = [1.00*exp(1j*0.1); 0.95*exp(-0.1j); 0.90; 1.10*exp(0.4j)] .* exp(0.5j*rv_t);
sct.im_edge   = [1 2; 2 3; 1 4]';
sct.sv_edge   = ["L12"; "L23"; "X1"];
sct.iv_arrow  = [4; 3];
sct.rm_P      = [0.8 + 0.2*sin(rv_t); -0.5*ones(size(rv_t))];
sct.rm_Iq     = [0.3*ones(size(rv_t)); -0.2*ones(size(rv_t))];
% 1 標本のデータ
sct1 = sct;
sct1.rv_t  = 0;
sct1.cm_V  = sct.cm_V(:, 1);
sct1.rm_P  = sct.rm_P(:, 1);
sct1.rm_Iq = sct.rm_Iq(:, 1);
s_timer = "GUILDA:GraphBase:Playback";


%% A graph of two or more samples has the bar below its axes, and one sample has none
fig = figure("Visible", "off", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
G = GraphSpring2D(sct, Parent=fig);
h_bar = bar_widget(fig, "PlaybackBar");
tl = G.ax(1).Parent;
assert(h_bar.Parent == fig && h_bar.Visible == "on")
assert(abs(h_bar.Position(2)) < 1e-9 && h_bar.Position(4) > 0 && h_bar.Position(4) < 0.4)
assert(tl.OuterPosition(2) >= h_bar.Position(2) + h_bar.Position(4) - 1e-9, "軸はバーに重ならない")
assert(abs(sum(tl.OuterPosition([2 4])) - 1) < 1e-9)
assert(isscalar(bar_widget(h_bar, "Play")) && isscalar(bar_widget(h_bar, "TimeSlider")) ...
    && isscalar(bar_widget(h_bar, "TimeText")) && isscalar(bar_widget(h_bar, "PlaySpeed")))
% 1 標本の図にはない
p1 = uipanel(fig);
G1 = GraphSpring2D(sct1, Parent=p1);
assert(isempty(findall(p1, "Tag", "GUILDA:GraphBase:PlaybackBar")))
assert(isequal(G1.ax(1).Parent.OuterPosition([2 4]), [0 1]))
% set_data で 1 標本にするとバーはなくなり軸が場所を取り戻す。2 標本以上に戻すと出る
G.set_data(sct1);
assert(~isvalid(h_bar) && isempty(findall(fig, "Tag", "GUILDA:GraphBase:PlaybackBar")))
assert(abs(tl.OuterPosition(2)) < 1e-9 && abs(tl.OuterPosition(4) - 1) < 1e-9)
G.set_data(sct);
assert(isscalar(findall(fig, "Tag", "GUILDA:GraphBase:PlaybackBar")) && tl.OuterPosition(2) > 0)
% 軸を渡した図 (使う人の軸) にはバーを付けない
p2 = uipanel(fig);
G2 = GraphSpring2D(sct, Parent=axes(p2));
assert(isempty(findall(p2, "Tag", "GUILDA:GraphBase:PlaybackBar")) && G2.i_time == 1)
% 新しい figure でも出る
G3 = GraphSpring2D(sct);
f3 = ancestor(G3.ax(1), "figure");
c_f3 = onCleanup(@() close(f3(isgraphics(f3))));
assert(f3 ~= fig && isscalar(findall(f3, "Tag", "GUILDA:GraphBase:PlaybackBar")))


%% set_time, link, the slider and set_data move the bar
fig = figure("Visible", "off", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
w_slider = bar_widget(p, "TimeSlider");
w_text   = bar_widget(p, "TimeText");
assert(isequal(w_slider.Limits, [1 numel(rv_t)]) && w_slider.Value == 1 && w_text.Text == "t = 0 s")
G.set_time(1.2);
assert(w_slider.Value == 13 && w_text.Text == "t = 1.2 s")
% スライダー → set_time (TimeChanged も出る)
st = containers.Map("n", 0);
G.TimeChangedFcn = @(g, d) count_call(st);
w_slider.Value = 6;
w_slider.ValueChangedFcn(w_slider, []);
assert(G.i_time == 6 && w_text.Text == "t = 0.5 s" && st("n") == 1)
G.TimeChangedFcn = [];
% ドラッグの途中 (ValueChangingFcn) も追う
w_slider.ValueChangingFcn(w_slider, struct("Value", 8.4));
assert(G.i_time == 8)
% リンクした図の set_time でも動く
p2 = uipanel(fig);
G2 = GraphSpring2D(sct, Parent=p2);
G2.link(G);
G2.set_time(0.3);
assert(w_slider.Value == 4 && bar_widget(p2, "TimeSlider").Value == 4)
% set_data: スライダーは新しい標本の範囲
sct3 = sct;
sct3.rv_t  = rv_t(1:5);
sct3.cm_V  = sct.cm_V(:, 1:5);
sct3.rm_P  = sct.rm_P(:, 1:5);
sct3.rm_Iq = sct.rm_Iq(:, 1:5);
G.set_data(sct3);
assert(isequal(w_slider.Limits, [1 5]) && w_slider.Value == G.i_time)


%% Play plays the samples by a timer and Pause stops it
c_batch = hide_batch();
fig = figure("Visible", "on", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
w_play = bar_widget(p, "Play");
assert(w_play.Text == "Play" && ~w_play.Value)
press(w_play, true);
assert(isscalar(timerfindall("Tag", s_timer)) && w_play.Text == "Pause" && w_play.Value)
% もう一度 Play を押しても 2 つ目の再生は始まらない
press(w_play, true);
assert(isscalar(timerfindall("Tag", s_timer)))
pause(0.5);
k = G.i_time;
assert(k > 1 && k < numel(rv_t), "0.5 s で途中まで: " + k)
press(w_play, false);
assert(isempty(timerfindall("Tag", s_timer)) && w_play.Text == "Play" && ~w_play.Value)
k = G.i_time;
pause(0.2);
assert(G.i_time == k, "止めた後は動かない")
% 最後まで再生すると timer は消え、ボタンは Play に戻る
G.PlaySpeed = 10;
press(w_play, true);
wait_until(@() isempty(timerfindall("Tag", s_timer)), 5);
assert(G.i_time == numel(rv_t) && w_play.Text == "Play" && ~w_play.Value)
% 最後の標本からの Play は最初から再生する
press(w_play, true);
assert(G.i_time == 1 || ~isempty(timerfindall("Tag", s_timer)))
press(w_play, false);
assert(G.i_time < numel(rv_t) && isempty(timerfindall("Tag", s_timer)))


%% PlaySpeed and the speed dropdown stay the same
c_batch = hide_batch();
fig = figure("Visible", "on", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
w_speed = bar_widget(p, "PlaySpeed");
rv_speed = [0.1 0.25 0.5 1 2 5 10];
assert(G.PlaySpeed == 1 && w_speed.Value == 1 && isequal(w_speed.ItemsData, rv_speed))
assert(isequal(string(w_speed.Items), ["0.1×" "0.25×" "0.5×" "1×" "2×" "5×" "10×"]))
% ドロップダウン → PlaySpeed
w_speed.Value = 5;
w_speed.ValueChangedFcn(w_speed, []);
assert(G.PlaySpeed == 5)
% PlaySpeed → ドロップダウン。一覧にない値は項目を足し、一覧の値に戻すと消える
G.PlaySpeed = 0.25;
assert(w_speed.Value == 0.25 && numel(w_speed.Items) == 7)
G.PlaySpeed = 0.3;
assert(w_speed.Value == 0.3 && numel(w_speed.Items) == 8 && string(w_speed.Items{end}) == "0.3×")
G.PlaySpeed = 2;
assert(w_speed.Value == 2 && numel(w_speed.Items) == 7)
% 正の有限の数だけ
for v = {0, -1, Inf, NaN, [1 2], "fast"}
    assert(error_id(@() set_prop(G, "PlaySpeed", v{1})) ~= "", "PlaySpeed = " + string(mat2str(v{1})))
end
assert(G.PlaySpeed == 2)
% 再生中に速度を変えても続く (今の位置から新しい速度で)
G.PlaySpeed = 0.5;
press(bar_widget(p, "Play"), true);
pause(0.2);
G.PlaySpeed = 10;
wait_until(@() isempty(timerfindall("Tag", s_timer)), 5);
assert(G.i_time == numel(rv_t))
% animate は Speed を渡さないと PlaySpeed (2 s のデータを 4 倍: 0.5 s 以上、1 倍の 2 s より短い)
G.PlaySpeed = 4;
t0 = tic;
G.animate();
r_time = toc(t0);
assert(r_time >= 0.45 && r_time < 1.9, "animate の時間: " + r_time)
assert(G.i_time == numel(rv_t))


%% play and pause: play returns at once, follows PlaySpeed and plays once; pause stops it
c_batch = hide_batch();
fig = figure("Visible", "on", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
w_play = bar_widget(p, "Play");
G.PlaySpeed = 0.5;
drawnow;                                        % 見える図を描き終えてから測る
t0 = tic;
G.play();
assert(toc(t0) < 0.5, "play はすぐ戻る: " + toc(t0))
assert(isscalar(timerfindall("Tag", s_timer)) && w_play.Text == "Pause" && w_play.Value)
% 2 度目の play は何もしない
G.play();
assert(isscalar(timerfindall("Tag", s_timer)))
pause(0.6);
k = G.i_time;
assert(k > 1 && k <= 5, "0.5 倍で 0.6 s: 標本 " + k)
G.pause();
assert(isempty(timerfindall("Tag", s_timer)) && w_play.Text == "Play" && ~w_play.Value)
k = G.i_time;
pause(0.2);
assert(G.i_time == k, "pause の後は動かない")
G.pause();                                      % 止まっていれば何もしない
% 最後まで play すると止まる
G.PlaySpeed = 10;
G.play();
wait_until(@() isempty(timerfindall("Tag", s_timer)), 5);
assert(G.i_time == numel(rv_t))
% 1 標本の図は再生できない
G1 = GraphSpring2D(sct1, Parent=uipanel(fig));
assert(error_id(@() G1.play()) == "GUILDA:GraphBase:OneSample")
G1.pause();


%% The timer is deleted when the figure closes, the axes or the graph are deleted, or the graph is replaced
c_batch = hide_batch();
fig = figure("Visible", "on", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
% 図を閉じる
f2 = figure("Visible", "on");
c_f2 = onCleanup(@() close(f2(isgraphics(f2))));
G = GraphSpring2D(sct, Parent=f2);
G.PlaySpeed = 0.1;
G.play();
assert(isscalar(timerfindall("Tag", s_timer)))
close(f2);
assert(isempty(timerfindall("Tag", s_timer)), "図を閉じると timer も消える")
pause(0.1);
assert(isempty(timerfindall("Tag", s_timer)))
% 軸を消す
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
G.PlaySpeed = 0.1;
G.play();
assert(isscalar(timerfindall("Tag", s_timer)))
delete(G.ax(1));
assert(isempty(timerfindall("Tag", s_timer)), "軸を消すと timer も消える")
% 図を置き換える (GUI のように同じ入れ物の中身を消して別の図を描き、前の図を消す)
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
G.PlaySpeed = 0.1;
press(bar_widget(p, "Play"), true);
assert(isscalar(timerfindall("Tag", s_timer)))
delete(p.Children);
G2 = GraphChart(struct("rv_t", rv_t, "sct_panel", struct("l_time", true), ...
    "sct_series", struct("rv_x", rv_t, "rm_y", sin(rv_t)', "sv_tag", "y")), Parent=p);
delete(G);
assert(isempty(timerfindall("Tag", s_timer)), "置き換えると timer も消える")
assert(isscalar(bar_widget(p, "PlaybackBar")) && G2.i_time == 1)
% 軸は残したまま図だけ消す
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
G.PlaySpeed = 0.1;
G.play();
assert(isscalar(timerfindall("Tag", s_timer)))
delete(G);
assert(isempty(timerfindall("Tag", s_timer)), "delete(G) で timer も消える")
% 出力を受け取らない図の figure を閉じる
f3 = figure("Visible", "on");
GraphSpring2D(sct, Parent=f3);
press(bar_widget(f3, "Play"), true);
assert(isscalar(timerfindall("Tag", s_timer)))
close(f3);
pause(0.1);
assert(isempty(timerfindall("Tag", s_timer)))


%% Closing a window during playback gives no warning and leaves no timer
% 窓を閉じる途中でも再生の timer のこまが走ることがある (MATLAB は削除の途中で、待っている timer の
% コールバックを実行する)。そのこまでは軸がまだ有効なのに figure から外れていたり消える途中だったりして、
% 以前は TimeChangedFcn などの描画のエラーで GUILDA:GraphBase:PlaybackTimer の警告が出た。
% (a) 軸を figure から外した状態 (Parent = []) を作ってこまを待つ (決定的に再現する)、
% (b) 時刻ごとに別の軸の題を書く図 (ResultOPF.plot_iteration と同じ) の見える窓を、再生中に閉じる (5 回)。
c_batch = hide_batch();
% (a) 軸が figure から外れた
lastwarn("");
uf = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
c_uf = onCleanup(@() delete(uf(isvalid(uf))));
G = GraphSpring2D(sct, Parent=uipanel(uf));
G.PlaySpeed = 0.1;
G.play();
assert(isscalar(timerfindall("Tag", s_timer)), "前提: 見える図では timer が 1 つ")
pause(0.2);
ax = G.ax(1);
ax.Parent = [];
pause(0.3);
[~, s_id] = lastwarn;
assert(isvalid(ax) && isvalid(G), "前提: 軸と図は有効")
assert(s_id ~= "GUILDA:GraphBase:PlaybackTimer", "figure のない軸のこまで警告を出さない")
assert(isempty(timerfindall("Tag", s_timer)), "figure のない軸のこまで timer を止めて消す")
delete(ax);
delete(uf);
% (b) 再生中に窓を閉じる
for i = 1:5
    lastwarn("");
    uf = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
    c_uf = onCleanup(@() delete(uf(isvalid(uf))));
    h_grid = uigridlayout(uf, [1 2]);
    ax2 = axes(h_grid);
    plot(ax2, 1:3);
    G = GraphSpring2D(sct, Parent=h_grid);
    G.TimeChangedFcn = @(g, d) title(ax2, "k = " + d.Index);
    G.PlaySpeed = 0.1;
    G.play();
    assert(isscalar(timerfindall("Tag", s_timer)), "前提: timer が 1 つ")
    t0 = tic;
    while toc(t0) < 0.2 + 0.03*i
        pause(0.05);
        drawnow;
    end
    close(uf);
    pause(0.2);
    [~, s_id] = lastwarn;
    assert(s_id ~= "GUILDA:GraphBase:PlaybackTimer", "閉じても警告を出さない (" + i + " 回目)")
    assert(isempty(timerfindall("Tag", s_timer)), "閉じると timer が消える (" + i + " 回目)")
end


%% Under matlab -batch and for an invisible figure no timer is made, and the bar still works
% この節は本物の batchStartupOptionUsed のまま (run_all は matlab -batch で走る)
fig = figure("Visible", "off", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
w_play = bar_widget(p, "Play");
if batchStartupOptionUsed
    f4 = figure("Visible", "on");            % -batch: 見える図でも作らない
    c_f4 = onCleanup(@() close(f4(isgraphics(f4))));
    G4 = GraphSpring2D(sct, Parent=f4);
    G4.play();
    assert(isempty(timerfindall("Tag", s_timer)) && bar_widget(f4, "Play").Text == "Play")
end
% 見えない図: play もボタンも何もしない
G.play();
assert(isempty(timerfindall("Tag", s_timer)) && G.i_time == 1)
press(w_play, true);
assert(isempty(timerfindall("Tag", s_timer)) && w_play.Text == "Play" && ~w_play.Value)
% バーとスライダーは動く
w_slider = bar_widget(p, "TimeSlider");
w_slider.Value = 9;
w_slider.ValueChangedFcn(w_slider, []);
assert(G.i_time == 9 && bar_widget(p, "TimeText").Text == "t = 0.8 s")
G.set_time(1.5);
assert(w_slider.Value == 16)
% batchStartupOptionUsed を隠しても見えない図では作らない
c_batch = hide_batch();
G.play();
assert(isempty(timerfindall("Tag", s_timer)))
% 部品の Tag
for s_tag = ["PlaybackBar", "PlaybackGrid", "Play", "TimeSlider", "TimeText", "PlaySpeed"]
    assert(isscalar(findall(p, "Tag", "GUILDA:GraphBase:" + s_tag)), s_tag)
end


%% animate shows Pause on the bar, Play starts nothing more, and Pause of the bar stops it
c_batch = hide_batch();
fig = figure("Visible", "on", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
w_play = bar_widget(p, "Play");
st = containers.Map(["text", "k"], {strings(1, 0), 0});
G.TimeChangedFcn = @(g, d) on_frame(w_play, d.Index, st);
G.animate(Speed=Inf);
assert(all(st("text") == "Pause"), join(st("text")))
assert(st("k") == 4 && G.i_time == 4, "4 画目の Pause で止まる: " + G.i_time)
assert(w_play.Text == "Play" && ~w_play.Value && isempty(timerfindall("Tag", s_timer)))
% バーの再生中に animate を呼ぶと、バーの再生を止めてから再生する
G.TimeChangedFcn = [];
G.PlaySpeed = 0.1;
press(w_play, true);
assert(isscalar(timerfindall("Tag", s_timer)))
G.animate(Speed=Inf);
assert(isempty(timerfindall("Tag", s_timer)) && G.i_time == numel(rv_t) && w_play.Text == "Play")


%% The bar is in a uipanel, a uigridlayout or a uitab of a uifigure
c_batch = hide_batch();
fig = figure("Visible", "on", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
uf = uifigure("Visible", "on", "Position", [100 100 700 500]);
c_uf = onCleanup(@() delete(uf));
p = uipanel(uf, "Position", [0 0 350 500]);
G = GraphSpring2D(sct, Parent=p);
h_bar = bar_widget(p, "PlaybackBar");
assert(h_bar.Parent == p && G.ax(1).Parent.OuterPosition(2) >= h_bar.Position(4) - 1e-9)
G.set_time(0.5);
assert(bar_widget(p, "TimeSlider").Value == 6)
press(bar_widget(p, "Play"), true);
assert(isscalar(timerfindall("Tag", s_timer)))
press(bar_widget(p, "Play"), false);
assert(isempty(timerfindall("Tag", s_timer)))
% uigridlayout: make_axes が置いたセルのパネルの中
gl = uigridlayout(uf, [1 2]);
G = GraphSpring2D(sct, Parent=gl);
h_bar = bar_widget(gl, "PlaybackBar");
assert(h_bar.Parent == G.ax(1).Parent.Parent && h_bar.Parent.Parent == gl)
% uitab
tg = uitabgroup(uf);
tb = uitab(tg);
G = GraphSpring2D(sct, Parent=tb);
assert(bar_widget(tb, "PlaybackBar").Parent == tb)
% ResultODE の図 (GraphNetDiagram) と時刻の GraphChart にもある。時刻のない GraphChart にはない
pc = uipanel(uf);
GraphChart(struct("rv_t", rv_t, "sct_panel", struct("l_time", true), ...
    "sct_series", struct("rv_x", rv_t, "rm_y", sin(rv_t)', "sv_tag", "y")), Parent=pc);
assert(isscalar(findall(pc, "Tag", "GUILDA:GraphBase:PlaybackBar")))
pc = uipanel(uf);
GraphChart(struct("rv_t", rv_t, "sct_panel", struct("l_time", false), ...
    "sct_series", struct("rv_x", rv_t, "rm_y", sin(rv_t)', "sv_tag", "y")), Parent=pc);
assert(isempty(findall(pc, "Tag", "GUILDA:GraphBase:PlaybackBar")), "時刻で変わらない図")


%% The panel of controls has no time row and the bar keeps the width of the axes
fig = figure("Visible", "off", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
G = GraphSpring2D(sct, Parent=fig);
tl = G.ax(1).Parent;
h_bar = bar_widget(fig, "PlaybackBar");
rv_pos = tl.OuterPosition;
h = G.show_controls();
assert(~any(string([h.UserData.sct_ctl.Property]) == "<time>") && isempty(findall(h, "Tag", "GUILDA:GraphBase:Play")))
assert(isempty(findall(h, "-isa", "matlab.ui.control.StateButton")))
assert(abs(h_bar.Position(3) - tl.OuterPosition(3)) < 1e-9 && tl.OuterPosition(3) < 1)
assert(tl.OuterPosition(2) >= h_bar.Position(4) - 1e-9)
G.hide_controls();
assert(max(abs(tl.OuterPosition - rv_pos)) < 1e-9 && abs(h_bar.Position(3) - 1) < 1e-9)


%% export_video and exportgraphics of the axes leave out the bar
fig = figure("Visible", "off", "Position", [100 100 800 600]);
c_fig = onCleanup(@() close(fig(isgraphics(fig))));
G = GraphSpring2D(sct, Parent=fig);
tl = G.ax(1).Parent;
h_bar = bar_widget(fig, "PlaybackBar");
rv_pos = tl.OuterPosition;
st = containers.Map("KeyType", "char", "ValueType", "any");
st("vis") = strings(1, 0);
s_file = string(tempname) + ".mp4";
c_file = onCleanup(@() delete_if_exists(s_file));
G.export_video(s_file, TimeStep=0.5, HoldTime=0, ...
    UpdateFcn=@(t) record_bar(st, h_bar, tl));
assert(all(st("vis") == "off"), "書き出しの間はバーを隠し軸が全体を使う: " + join(st("vis")))
assert(h_bar.Visible == "on" && max(abs(tl.OuterPosition - rv_pos)) < 1e-9, "書き出しの後は戻る")
vr = VideoReader(s_file);
assert(vr.NumFrames == 5)
% exportgraphics(軸) は軸だけ: 画像の縦横の比は軸の外形の比 (バーの帯が入ると縦に伸びる)
s_png = string(tempname) + ".png";
c_png = onCleanup(@() delete_if_exists(s_png));
exportgraphics(G.ax(1), s_png);
img = imread(s_png);
G.ax(1).Units = "pixels";
rv_ax = G.ax(1).OuterPosition;
r_img = size(img, 1) / size(img, 2);
assert(abs(r_img / (rv_ax(4) / rv_ax(3)) - 1) < 0.25, "軸の画像の縦横の比: " + r_img + " / " + rv_ax(4) / rv_ax(3))


function c = hide_batch()
% batchStartupOptionUsed を false を返す関数で隠す (test_F61 と同じ)。戻り値を消すと元に戻し、残った timer を消す
    s_dir = tempname;
    mkdir(s_dir);
    fid = fopen(fullfile(s_dir, "batchStartupOptionUsed.m"), "w");
    fprintf(fid, "function tf = batchStartupOptionUsed()\ntf = false;\nend\n");
    fclose(fid);
    sct_warn = warning("off", "MATLAB:dispatcher:nameConflict");
    addpath(s_dir);
    assert(~batchStartupOptionUsed(), "前提: 隠せた")
    c = onCleanup(@() restore_batch(s_dir, sct_warn));
end

function restore_batch(s_dir, sct_warn)
% hide_batch を戻し、残った timer を消す
    rmpath(s_dir);
    rmdir(s_dir, "s");
    warning(sct_warn);
    hv_t = timerfindall("Tag", "GUILDA:GraphBase:Playback");
    if ~isempty(hv_t)
        stop(hv_t);
        delete(hv_t);
    end
end

function w = bar_widget(h_parent, s_name)
% 部品 s_name (PlaybackBar, Play, TimeSlider, TimeText, PlaySpeed) の h_parent の中のもの (一つ)
    w = findall(h_parent, "Tag", "GUILDA:GraphBase:" + s_name);
    assert(isscalar(w), s_name + " が一つ: " + numel(w))
end

function press(w_play, l_value)
% 再生ボタンを押す (状態ボタンの値を変えてコールバックを呼ぶ)
    w_play.Value = l_value;
    w_play.ValueChangedFcn(w_play, []);
end

function wait_until(fcn, r_max)
% fcn() が真になるまで待つ (r_max 秒まで)
    t0 = tic;
    while ~fcn() && toc(t0) < r_max
        pause(0.05);
    end
    assert(fcn(), "時間内に終わらない")
end

function count_call(st)
% TimeChangedFcn の呼び出しを数える
    st("n") = st("n") + 1;
end

function on_frame(w_play, k, st)
% animate の各画: ボタンの表示を記録し、2 画目に Play を押し (何も始まらない)、4 画目に Pause を押す
    st("text") = [st("text"), string(w_play.Text)];
    if k == 2
        press(w_play, true);
        assert(isempty(timerfindall("Tag", "GUILDA:GraphBase:Playback")), "animate の間の Play は timer を作らない")
    elseif k == 4
        st("k") = k;
        press(w_play, false);
    end
end

function record_bar(st, h_bar, tl)
% export_video の各画のバーの見え方 (軸が下まで使うときだけ "off")
    s = string(h_bar.Visible);
    if abs(tl.OuterPosition(2)) > 1e-9
        s = "moved";
    end
    st("vis") = [st("vis"), s];
end

function set_prop(G, s_name, val)
% プロパティの設定 (error_id 用)
    G.(s_name) = val;
end

function id = error_id(f)
% f() のエラーの識別子 (エラーがなければ ""。GUILDA のメッセージは helper.msg_id で読む)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
        if id == ""
            id = "error";
        end
    end
end

function delete_if_exists(s_file)
% ファイルがあれば消す
    if isfile(s_file)
        delete(s_file);
    end
end
