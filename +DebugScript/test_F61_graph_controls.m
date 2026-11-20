% F61 図の操作パネル (GraphBase.show_controls): GraphSpring2D/3D、GraphChart、GraphNetDiagram、GraphNetMap
%
%   h = G.show_controls(Parent=[], ChangedFcn=[]);   % 宣言 control_list から作るパネル
%   G.hide_controls();  G.h_controls
%
% 宣言の行の数の部品ができること、部品の操作 → プロパティ、コードでの設定 → 部品、
% EnableFcn、エラーで部品が戻ること、ChangedFcn の引数、パネルに時刻の行がないこと (時刻は
% 再生バー: test_F100_graph_playback)、set_data でパネルが残ること、
% hide_controls で軸の位置が戻ること、軸を消すとパネルも消えること、Parent の種類を確かめる。
% GraphNetDiagram では、EnableFcn (3D で流れの操作を止める)、パネルからの Dimension の切り替えで
% パネルが残り timer が増えないこと、ResultODE の図のパネルに時刻がなく再生バーがあることも確かめる。GraphNetMap は
% 範囲だけ (色と矢印はデータ)。図は見えない figure に描く (timer を確かめる節だけ見える uifigure)。
%
% 実行: runtests("DebugScript.test_F61_graph_controls")  または  DebugScript.run_all("Features","F61")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off", "Position", [100 100 900 600]);
c_fig = onCleanup(@() close(fig));
% 合成のばね質点データ (test_F46 と同じ): 母線 B1-B3 と B1 の機器ノード G1
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
% 時刻のパネルのあるグラフとないグラフ
sct_chart = struct();
sct_chart.rv_t       = rv_t;
sct_chart.sct_panel  = struct("s_xlabel", "t [s]", "s_ylabel", "y", "l_time", true);
sct_chart.sct_series = struct("rv_x", rv_t, "rm_y", [sin(rv_t); cos(rv_t)].', "sv_tag", ["s"; "c"]);
sct_bar = struct();
sct_bar.sct_panel  = struct("l_time", false);
sct_bar.sct_series = struct("s_type", "bar", "sv_x", ["B1"; "B2"], "rm_y", [1.0; 0.98]);
% 部品の種類 (findall の -isa)
s_check   = "matlab.ui.control.CheckBox";
s_slider  = "matlab.ui.control.Slider";
s_spinner = "matlab.ui.control.Spinner";
s_state   = "matlab.ui.control.StateButton";
s_label   = "matlab.ui.control.Label";


%% GraphSpring2D: one widget per declared control, next to the axes
G = GraphSpring2D(sct, Parent=fig);
tl = G.ax(1).Parent;
rv_pos = tl.OuterPosition;
h = G.show_controls();
assert(isa(h, "matlab.ui.container.Panel") && G.h_controls == h && h.Parent == fig)
% Label: 3 つのチェックボックス、View: スライダー 1 つとスピナー 2 つ。時刻の行はない (再生バーにある)
assert(numel(findall(h, "-isa", s_check)) == 3)
assert(numel(findall(h, "-isa", s_slider)) == 1)
assert(numel(findall(h, "-isa", s_spinner)) == 2)
assert(isempty(findall(h, "-isa", s_state)))
sv_text = label_texts(h);
assert(all(ismember(["Label", "View"], sv_text)) && ~any(sv_text == "Time"))
% 軸は右をパネルに譲り、パネルは右端にある
assert(tl.OuterPosition(3) < 1 && abs(tl.OuterPosition(3) + h.Position(3) - 1) < 1e-9)
assert(abs(h.Position(1) + h.Position(3) - 1) < 1e-9)
% hide_controls で軸の位置が戻る
G.hide_controls();
assert(isempty(G.h_controls) && isempty(findall(fig, "Tag", "GUILDA:GraphBase:Controls")))
assert(max(abs(tl.OuterPosition - rv_pos)) < 1e-9)
% もう一度出すと前のパネルを置き換える
h1 = G.show_controls();
h2 = G.show_controls();
assert(~isvalid(h1) && isvalid(h2) && numel(findall(fig, "Tag", "GUILDA:GraphBase:Controls")) == 1)
assert(abs(tl.OuterPosition(3) + h2.Position(3) - 1) < 1e-9)


%% A widget sets the property and calls ChangedFcn
G = GraphSpring2D(sct, Parent=fig);
record_call();                                  % 記録を空にする
h = G.show_controls(ChangedFcn=@record_call);
cb = findall(h, "-isa", s_check);
w = cb(string({cb.Text}) == "Labels");
w.Value = false;
w.ValueChangedFcn(w, []);
assert(G.ShowLabel == false)
assert(all(string({G.sct_plt.LabelNode.Visible}) == "off"))
c = record_call();
assert(c{1} == G && c{2} == "ShowLabel" && c{3} == false)
% スピナー
sp = findall(h, "-isa", s_spinner);
w = sp(1);
w.Value = 0.5;
w.ValueChangedFcn(w, []);
assert(G.ArrowScaleP == 0.5 || G.ArrowScaleQ == 0.5)
% スライダー (RotationScale)
sl = findall(h, "-isa", s_slider);
w = sl(arrayfun(@(x) isequal(x.Limits, [0 1]), sl));
w.Value = 0;
w.ValueChangedFcn(w, []);
assert(G.RotationScale == 0)


%% Setting the property in code updates the widget
G = GraphSpring2D(sct, Parent=fig);
h = G.show_controls();
cb = findall(h, "-isa", s_check);
G.ShowLegend = false;
assert(cb(string({cb.Text}) == "Legend").Value == false)
G.ShowLegend = true;
assert(cb(string({cb.Text}) == "Legend").Value == true)
sl = findall(h, "-isa", s_slider);
G.RotationScale = 0.3;
assert(any(arrayfun(@(x) isequal(x.Limits, [0 1]) && abs(x.Value - 0.3) < 1e-12, sl)))
% 範囲の外の値は部品の範囲を広げて表示する
G.ArrowScaleP = 3;
sp = findall(h, "-isa", s_spinner);
assert(any(arrayfun(@(x) x.Value == 3 && x.Limits(2) >= 3, sp)))


%% EnableFcn is evaluated again after each change
G = GraphSpring2D(sct, Parent=fig);
h = G.show_controls();
ud = h.UserData;
i_rot = find([ud.sct_ctl.Property] == "RotationScale");
ud.sct_ctl(i_rot).EnableFcn = @(g) g.ShowLabel;
h.UserData = ud;
w = ud.c_widget{i_rot};
G.ShowLabel = false;
assert(w.Enable == "off")
G.ShowLabel = true;
assert(w.Enable == "on")


%% A value the property refuses puts the widget back with a warning
G3 = GraphSpring3D(sct, Parent=fig);
h = G3.show_controls();
assert(any([h.UserData.sct_ctl.Property] == "SurfaceAlpha"))
w = h.UserData.c_widget{[h.UserData.sct_ctl.Property] == "SurfaceAlpha"};
w.Limits = [0 2];
w.Value  = 1.5;
lastwarn("");
DebugScript.helper.quiet(@() w.ValueChangedFcn(w, []));
[~, s_id] = lastwarn();
assert(s_id == "GUILDA:GraphBase:ControlValue")
assert(G3.SurfaceAlpha == 0.4 && w.Value == 0.4 && isequal(w.Limits, [0 1]))


%% The panel has no time row: the time is in the playback bar below the axes
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
h = G.show_controls();
assert(~any(string([h.UserData.sct_ctl.Property]) == "<time>") && ~any(string([h.UserData.sct_ctl.Widget]) == "time"))
assert(isscalar(findall(p, "Tag", "GUILDA:GraphBase:PlaybackBar")))
assert(isempty(findall(h, "Tag", "GUILDA:GraphBase:Play")) && isempty(findall(h, "Tag", "GUILDA:GraphBase:TimeSlider")))


%% set_data keeps the panel and its rows, also through one sample
p = uipanel(fig);
G = GraphSpring2D(sct, Parent=p);
h = G.show_controls();
sv_label = sort(label_texts(h));
sct3 = sct;
sct3.rv_t  = rv_t(1:5);
sct3.cm_V  = sct.cm_V(:, 1:5);
sct3.rm_P  = sct.rm_P(:, 1:5);
sct3.rm_Iq = sct.rm_Iq(:, 1:5);
G.set_data(sct3);
assert(G.h_controls == h)
G.set_data(sct1);
assert(G.h_controls == h && isvalid(h))
G.set_data(sct);
assert(G.h_controls == h && numel(findall(p, "Tag", "GUILDA:GraphBase:Controls")) == 1)
assert(isequal(sort(label_texts(h)), sv_label) && isempty(findall(h, "-isa", s_state)))


%% Parent: a uipanel of a uifigure and a uigridlayout
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
gl = uigridlayout(uf, [1 2]);
G = GraphSpring2D(sct, Parent=gl);
rv_pos = G.ax(1).Parent.OuterPosition;
h = G.show_controls(Parent=gl);
assert(h.Parent == gl && h.Layout.Column == 2)
assert(isequal(G.ax(1).Parent.OuterPosition, rv_pos))
p = uipanel(uf);
h = G.show_controls(Parent=p);
assert(h.Parent == p && h.Units == "normalized" && isequal(h.Position, [0 0 1 1]))
assert(numel(findall(uf, "Tag", "GUILDA:GraphBase:Controls")) == 1)
% 誤り
assert(error_id(@() G.show_controls(Parent=axes(fig))) == "GUILDA:GraphBase:ControlsParent")
assert(error_id(@() G.show_controls(ChangedFcn="f")) == "GUILDA:GraphBase:ChangedFcn")


%% Deleting the axes deletes the panel
G = GraphSpring2D(sct, Parent=uipanel(fig));
h = G.show_controls(Parent=uipanel(fig));
delete(G.ax(1));
assert(~isvalid(h) && isempty(G.h_controls))
assert(error_id(@() G.show_controls()) == "GUILDA:GraphBase:NoAxes")


%% GraphChart: no controls in the panel; the playback bar only with a time panel
p = uipanel(fig);
C = GraphChart(sct_chart, Parent=p);
h = C.show_controls();
assert(isempty(findall(h, "-isa", s_slider)) && isempty(findall(h, "-isa", s_state)))
assert(any(label_texts(h) == "No controls for this graph."))
assert(isscalar(findall(p, "Tag", "GUILDA:GraphBase:PlaybackBar")))
% 時刻のパネルがない: 再生バーもない
p_bar = uipanel(fig);
B = GraphChart(sct_bar, Parent=p_bar);
h = B.show_controls(Parent=uipanel(fig));
assert(isempty(findall(h, "-isa", s_slider)) && isempty(findall(h, "-isa", s_state)))
assert(any(label_texts(h) == "No controls for this graph."))
assert(isempty(findall(p_bar, "Tag", "GUILDA:GraphBase:PlaybackBar")))



%% GraphNetDiagram: one widget per declared control, next to the axes
net14 = ieee14();
D = net14.plot_diagram(Parent=fig);
tl = D.ax(1).Parent;
rv_pos = tl.OuterPosition;
h = D.show_controls();
ud = h.UserData;
assert(isequal([ud.sct_ctl.Property], ["Dimension", "BusHeightMode", "ColorMode", "ColorLimits", ...
    "BranchWidthMode", "BranchWidthRange", "MarkerSizeMode", "MarkerSizeRange", "LinkWidth", ...
    "FlowMode", "FlowAnimation", "FlowSpeed", "LabelMode", "LabelFontSize"]), "1 標本の図には時刻がない")
% dropdown 7 つ、range 3 つ (スピナー 6 つ) とスピナー 2 つ、スライダー 1 つ (FlowSpeed)、トグル 1 つ
assert(numel(findall(h, "-isa", "matlab.ui.control.DropDown")) == 7)
assert(numel(findall(h, "-isa", s_spinner)) == 8)
assert(numel(findall(h, "-isa", s_slider)) == 1)
assert(numel(findall(h, "-isa", s_state)) == 1)
assert(all(ismember(["View", "Color", "Size", "Flow", "Label"], label_texts(h))) && ~any(label_texts(h) == "Time"))
% dropdown の選択肢はプロパティの検査の値と同じ
for i = find([ud.sct_ctl.Widget] == "dropdown")
    p = ud.sct_ctl(i).Property;
    v0 = D.(p);
    for s_item = ud.sct_ctl(i).Items                 % 検査を通ること (値は戻す)
        assert(error_id(@() set_prop(D, p, s_item)) == "", p + " の " + s_item)
    end
    D.(p) = v0;
end
assert(D.Dimension == "2D" && D.ColorMode == "I")
% 既定の値が部品に出ている
assert(widget_of(h, "Dimension").Value == "2D" && widget_of(h, "BranchWidthMode").Value == "Ysvd")
w = widget_of(h, "MarkerSizeRange");
assert(w(1).Value == 5 && w(2).Value == 10)
assert(widget_of(h, "FlowAnimation").Value == true && widget_of(h, "FlowSpeed").Value == 1)
% ColorLimits は自動 (NaN): Auto のチェックボックスが付き、スピナーは使っている範囲を出す
assert(numel(findall(h, "-isa", "matlab.ui.control.CheckBox")) == 1)
w = widget_of(h, "ColorLimits");
assert(numel(w) == 3 && w(3).Value == true && isequal([w(1).Value, w(2).Value], D.ax.CLim) && w(2).Value > 0)
D.hide_controls();
assert(max(abs(tl.OuterPosition - rv_pos)) < 1e-9)


%% GraphNetDiagram: widgets set the properties and the properties update the widgets
net14 = ieee14();
D = net14.plot_diagram(Parent=fig);
record_call();
h = D.show_controls(ChangedFcn=@record_call);
% 部品 → プロパティ
w = widget_of(h, "ColorMode");
w.Value = "P";
w.ValueChangedFcn(w, []);
assert(D.ColorMode == "P")
c = record_call();
assert(c{1} == D && c{2} == "ColorMode" && c{3} == "P")
w = widget_of(h, "BranchWidthRange");
w(2).Value = 6;
w(2).ValueChangedFcn(w(2), []);
assert(isequal(D.BranchWidthRange, [1 6]))
assert(abs(max([D.sct_plt.EdgeMain.LineWidth]) - 6) < 1e-9, "最も太いブランチが範囲の最大")
w = widget_of(h, "BusHeightMode");
w.Value = "V";
w.ValueChangedFcn(w, []);
assert(D.BusHeightMode == "V")
w = widget_of(h, "FlowAnimation");
w.Value = false;
w.ValueChangedFcn(w, []);
assert(D.FlowAnimation == false)
w = widget_of(h, "LinkWidth");
w.Value = 2;
w.ValueChangedFcn(w, []);
assert(D.LinkWidth == 2)
% プロパティ → 部品
D.MarkerSizeMode = "S";
assert(widget_of(h, "MarkerSizeMode").Value == "S")
D.MarkerSizeRange = [3 12];
w = widget_of(h, "MarkerSizeRange");
assert(w(1).Value == 3 && w(2).Value == 12)
D.FlowSpeed = 2.5;
assert(widget_of(h, "FlowSpeed").Value == 2.5)
D.LabelMode = "none";
assert(widget_of(h, "LabelMode").Value == "none")
D.FlowAnimation = true;
assert(widget_of(h, "FlowAnimation").Value == true)
% 検査で止まる値 (最小 > 最大) は部品が戻り、警告になる
w = widget_of(h, "MarkerSizeRange");
w(1).Value = 20;
lastwarn("");
DebugScript.helper.quiet(@() w(1).ValueChangedFcn(w(1), []));
[~, s_id] = lastwarn();
assert(s_id == "GUILDA:GraphBase:ControlValue")
assert(isequal(D.MarkerSizeRange, [3 12]) && w(1).Value == 3)


%% GraphNetDiagram: the Auto checkbox of ColorLimits
net14 = ieee14();
D = net14.plot_diagram(Parent=fig);
record_call();
h = D.show_controls(ChangedFcn=@record_call);
w = widget_of(h, "ColorLimits");
rv_auto = D.ax.CLim;
% Auto を外すと、そのときの範囲が固定の値になる
w(3).Value = false;
w(3).ValueChangedFcn(w(3), []);
assert(isequal(D.ColorLimits, rv_auto) && w(3).Value == false)
c = record_call();
assert(c{2} == "ColorLimits" && isequal(c{3}, rv_auto))
% スピナーを変えると固定の値
w(2).Value = 5;
w(2).ValueChangedFcn(w(2), []);
assert(isequal(D.ColorLimits, [rv_auto(1) 5]) && isequal(D.ax.CLim, [rv_auto(1) 5]))
% Auto に戻すと [NaN NaN]、スピナーはデータの範囲
w(3).Value = true;
w(3).ValueChangedFcn(w(3), []);
assert(all(isnan(D.ColorLimits)) && isequal(D.ax.CLim, rv_auto) && w(1).Value == rv_auto(1) && w(2).Value == rv_auto(2))
% コードで固定すると Auto が外れ、ColorMode を変えるとスピナーが新しい自動の範囲になる
D.ColorLimits = [0 1];
assert(w(3).Value == false && w(1).Value == 0 && w(2).Value == 1)
D.ColorLimits = [NaN NaN];
D.ColorMode = "P";
assert(w(3).Value == true && w(1).Value == -w(2).Value && isequal([w(1).Value, w(2).Value], D.ax.CLim), "P は 0 を中心に対称")


%% GraphNetDiagram: EnableFcn disables the flow animation and speed in 3D
net14 = ieee14();
D = net14.plot_diagram(Parent=fig);
h = D.show_controls();
sv_on2d = ["FlowAnimation", "FlowSpeed"];
sv_always = ["Dimension", "BusHeightMode", "ColorMode", "BranchWidthMode", "MarkerSizeMode", "FlowMode", "LabelMode"];
assert(all(arrayfun(@(p) widget_of(h, p).Enable == "on", [sv_on2d, sv_always])))
w = widget_of(h, "Dimension");
w.Value = "3D";
w.ValueChangedFcn(w, []);
assert(D.Dimension == "3D")
assert(all(arrayfun(@(p) widget_of(h, p).Enable == "off", sv_on2d)), "3D では流れの点の操作を止める")
assert(all(arrayfun(@(p) widget_of(h, p).Enable == "on", sv_always)), "高さなどは 3D でも操作できる")
D.Dimension = "2D";
assert(all(arrayfun(@(p) widget_of(h, p).Enable == "on", sv_on2d)))


%% GraphNetDiagram: switching Dimension from the panel keeps the panel and its place
net14 = ieee14();
D = net14.plot_diagram(Parent=fig);
tl = D.ax(1).Parent;
h = D.show_controls();
rv_pos = tl.OuterPosition;
c_w = h.UserData.c_widget;
ax = D.ax;
w = widget_of(h, "Dimension");
w.Value = "3D";
w.ValueChangedFcn(w, []);
assert(isvalid(h) && D.h_controls == h && isequal(h.UserData.c_widget, c_w), "パネルと部品はそのまま")
assert(D.ax == ax && max(abs(tl.OuterPosition - rv_pos)) < 1e-9, "軸の位置もそのまま")
assert(widget_of(h, "Dimension").Value == "3D")
w.Value = "2D";
w.ValueChangedFcn(w, []);
assert(isvalid(h) && D.Dimension == "2D" && max(abs(tl.OuterPosition - rv_pos)) < 1e-9)
% plot_diagram(Graph=D) で描き直してもパネルは残る
D2 = net14.plot_diagram(Graph=D);
assert(D2 == D && isvalid(h) && D.h_controls == h)


%% GraphNetDiagram: the Dimension switch and the toggle leave no extra timer
% -batch では timer を作らないので、この節だけ batchStartupOptionUsed を false を返す関数で
% 隠し (F60 と同じ)、見える uifigure に描いて本物の timer を確かめる。
s_tag = "GUILDA:GraphNetDiagram:Flow";
net14 = ieee14();
s_dir = tempname;
mkdir(s_dir);
fid = fopen(fullfile(s_dir, "batchStartupOptionUsed.m"), "w");
fprintf(fid, "function tf = batchStartupOptionUsed()\ntf = false;\nend\n");
fclose(fid);
sct_warn = warning("off", "MATLAB:dispatcher:nameConflict");
addpath(s_dir);
c_path = onCleanup(@() restore_path(s_dir, sct_warn, s_tag));
assert(~batchStartupOptionUsed(), "前提: 隠せた")
uf = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
c_uf = onCleanup(@() delete(uf(isvalid(uf))));
gl = uigridlayout(uf, [1 2], "ColumnWidth", {"1x", 240});
D = net14.plot_diagram(Parent=uipanel(gl));
h = D.show_controls(Parent=gl);
assert(numel(timerfindall("Tag", s_tag)) == 1, "見える 2D の図では timer が 1 つ")
w = widget_of(h, "Dimension");
w.Value = "3D";
w.ValueChangedFcn(w, []);
assert(isempty(timerfindall("Tag", s_tag)), "3D では timer がない")
w.Value = "2D";
w.ValueChangedFcn(w, []);
assert(numel(timerfindall("Tag", s_tag)) == 1 && isvalid(h), "2D に戻すと timer は 1 つ")
for k = 1:3                                      % 何度切り替えても 1 つ
    w.Value = "3D";  w.ValueChangedFcn(w, []);
    w.Value = "2D";  w.ValueChangedFcn(w, []);
end
assert(numel(timerfindall("Tag", s_tag)) == 1)
wa = widget_of(h, "FlowAnimation");
wa.Value = false;
wa.ValueChangedFcn(wa, []);
assert(isempty(timerfindall("Tag", s_tag)), "再生のトグルを切ると timer が消える")
wa.Value = true;
wa.ValueChangedFcn(wa, []);
assert(numel(timerfindall("Tag", s_tag)) == 1)
delete(uf);
assert(isempty(timerfindall("Tag", s_tag)), "uifigure を消すと timer が消える")


%% GraphNetDiagram: the time slider of a ResultODE diagram
net14 = ieee14();
sc = net14.add_scenario("fault");
sc.add_fault("B003", [0.1, 0.15]);
res = DebugScript.helper.quiet(@() net14.simulate("fault", Time=[0, 0.3]));
p = uipanel(fig);
D = res.plot_diagram(Parent=p);
n_t = numel(D.rv_t);
assert(n_t > 2)
h = D.show_controls();
ud = h.UserData;
assert(~any(string([ud.sct_ctl.Property]) == "<time>") && isscalar(findall(h, "-isa", s_state)), "FlowAnimation だけ")
w = findall(p, "Tag", "GUILDA:GraphBase:TimeSlider");
assert(isscalar(w) && isequal(w.Limits, [1 n_t]) && w.Value == 1)
k = round(n_t/2);
w.Value = k;
w.ValueChangedFcn(w, []);
assert(D.i_time == k)
D.set_time(D.rv_t(end));
assert(w.Value == n_t)
% パネルの Dimension の切り替えで表示中の標本と再生バーが残る
wd = widget_of(h, "Dimension");
wd.Value = "3D";
wd.ValueChangedFcn(wd, []);
assert(D.i_time == n_t && isvalid(w) && w.Value == n_t)


%% GraphNetDiagram: Parent is a uipanel of a uifigure or a uigridlayout
net14 = ieee14();
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
gl = uigridlayout(uf, [1 2]);
D = net14.plot_diagram(Parent=gl);
h = D.show_controls(Parent=gl);
assert(h.Parent == gl && h.Layout.Column == 2)
p = uipanel(uf);
h = D.show_controls(Parent=p);
assert(h.Parent == p && isequal(h.Position, [0 0 1 1]))
assert(numel(findall(uf, "Tag", "GUILDA:GraphBase:Controls")) == 1)
w = widget_of(h, "ColorMode");
w.Value = "Q";
w.ValueChangedFcn(w, []);
assert(D.ColorMode == "Q")
% 軸を Parent にした図は、Parent なしではその軸の隣に置く
D2 = net14.plot_diagram(Parent=axes(fig));
h2 = D2.show_controls();
assert(h2.Parent == fig && D2.ax.OuterPosition(3) < 1)
assert(error_id(@() D.show_controls(Parent=axes(fig))) == "GUILDA:GraphBase:ControlsParent")


%% GraphNetMap: the range of the branch widths only
net14 = ieee14();
res = DebugScript.helper.quiet(@() net14.calculate_powerflow());
M = res.plot_network(Parent=fig, Color="angle", Arrow="Q");
h = M.show_controls();
ud = h.UserData;
assert(isequal([ud.sct_ctl.Property], "BranchWidthRange"), "色と矢印はデータなので出さない")
assert(numel(findall(h, "-isa", s_spinner)) == 2 && isempty(findall(h, "-isa", "matlab.ui.control.DropDown")))
assert(isempty(findall(h, "-isa", s_slider)) && isempty(findall(h, "-isa", s_state)))
w = widget_of(h, "BranchWidthRange");
assert(w(1).Value == 1 && w(2).Value == 4)
w(2).Value = 8;
w(2).ValueChangedFcn(w(2), []);
assert(isequal(M.BranchWidthRange, [1 8]))
M.BranchWidthRange = [0.5 3];
assert(w(1).Value == 0.5 && w(2).Value == 3)
w(1).Value = 5;
lastwarn("");
DebugScript.helper.quiet(@() w(1).ValueChangedFcn(w(1), []));
[~, s_id] = lastwarn();
assert(s_id == "GUILDA:GraphBase:ControlValue" && isequal(M.BranchWidthRange, [0.5 3]) && w(1).Value == 0.5)
% uifigure の uigridlayout
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
gl = uigridlayout(uf, [1 2]);
M2 = res.plot_network(Parent=gl);
h2 = M2.show_controls(Parent=gl);
assert(h2.Parent == gl && h2.Layout.Column == 2)


function c = record_call(g, s, v)
% ChangedFcn の呼び出しを記録し、引数なしで呼ぶと記録を返して空にする
    persistent c_last
    if nargin == 0
        c = c_last;
        c_last = {};
        return
    end
    c_last = {g, s, v};
end

function sv = label_texts(h)
% パネルの中のラベルの文字 (複数行は改行でつなぐ)
    hv = findall(h, "-isa", "matlab.ui.control.Label");
    sv = arrayfun(@(x) join(string(x.Text), newline), hv)';
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end

function net = ieee14()
% 潮流を解いた IEEE14 母線系統
    net = network.IEEE14bus();
    DebugScript.helper.quiet(@() net.initialize);
end

function w = widget_of(h, s_property)
% パネルの宣言の行 s_property の部品 (range は 2 つのスピナー)
    ud = h.UserData;
    w = ud.c_widget{[ud.sct_ctl.Property] == s_property};
end

function set_prop(G, s_property, value)
    G.(s_property) = value;
end

function restore_path(s_dir, sct_warn, s_tag)
% batchStartupOptionUsed を隠す一時フォルダを外して消し、残った timer を消す
    rmpath(s_dir);
    rmdir(s_dir, "s");
    warning(sct_warn);
    hv_t = timerfindall("Tag", s_tag);
    if ~isempty(hv_t)
        stop(hv_t);
        delete(hv_t);
    end
end
