% F48 結果の折れ線・棒グラフ (GraphChart) と ResultODE.plot_trajectory
%
%   G = GraphChart(sct, Parent=...);    % sct.sct_panel, sct.sct_series, sct.sct_refline, sct.rv_t, sct.s_title
%   G.set_data(sct);  G.tab_element;  G.set_style(sr_tag, ...);  G.reset_style();
%   G.SeriesColor / SeriesLabel / SeriesLineWidth / SeriesMarker / SeriesMarkerSize / SeriesLineStyle / SeriesVisible
%   G.set_time(t);  G.link(G2);         % 時刻のパネルにカーソル
%   G = res.plot_trajectory(Quantity=, Bus=, Parent=);
%
% 要素は線 ("line")、棒 ("bar")、マーカーの組 ("marker") の 1 本・1 本・1 組ずつ。タグと
% ベクトルの書き方が同じグラフィックスになること、NaN の色が軸の色の順になること、
% カーソルとリンク、Parent の規則、クリックを確かめる。図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F48_graph_chart")  または  DebugScript.run_all("Features","F48")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% 2 パネルの合成データ: 上は時間の線 2 本とマーカーの組 1 つ、下は棒 3 本と基準線
rv_t = 0:0.1:2;
sct = struct();
sct.rv_t      = rv_t;
sct.s_title   = "Synthetic";
sct.sct_panel = [struct("s_title", "time", "s_xlabel", "t [s]", "s_ylabel", "y", "l_time", true, "rv_ylim", []), ...
                 struct("s_title", "bars", "s_xlabel", "", "s_ylabel", "|V| [pu]", "l_time", false, "rv_ylim", [0.8 1.2])];
sct.sct_series = [ ...
    struct("i_panel", 1, "s_type", "line", "rv_x", rv_t, "sv_x", [], "rm_y", [sin(rv_t); cos(rv_t)].', ...
           "sv_tag", ["s"; "c"], "sv_legend", ["sin"; "cos"], "rm_color", []), ...
    struct("i_panel", 1, "s_type", "marker", "rv_x", [0.5; 1.5], "sv_x", [], "rm_y", [0.2; -0.2], ...
           "sv_tag", "m", "sv_legend", [], "rm_color", "k"), ...
    struct("i_panel", 2, "s_type", "bar", "rv_x", [], "sv_x", ["B1"; "B2"; "B3"], "rm_y", [1.00; 0.97; 1.03], ...
           "sv_tag", [], "sv_legend", "|V|", "rm_color", [])];
sct.sct_refline = struct("i_panel", 2, "s_axis", "y", "r_value", 1.05, "s_label", "Vmax");


%% set_data and tab_element follow the data contract
G = GraphChart(sct, Parent=fig);
tab = G.tab_element;
assert(isequal(tab.Tag, ["s"; "c"; "m"; "B1"; "B2"; "B3"]))
assert(isequal(tab.Kind, ["line"; "line"; "marker"; "bar"; "bar"; "bar"]))
assert(isequal(tab.Index, (1:6)'))
assert(numel(G.ax) == 2 && isequal(G.rv_t, rv_t))
% 線とマーカーは line、棒は 1 つの Bar のバー
assert(isequal(G.sct_plt.Element(1).YData, sin(rv_t)) && G.sct_plt.Element(3).LineStyle == "none")
assert(isa(G.sct_plt.Element(4), "matlab.graphics.chart.primitive.Bar") && G.sct_plt.Element(4) == G.sct_plt.Element(6))
assert(isequal(string(G.ax(2).XTickLabel), ["B1"; "B2"; "B3"]) && isequal(G.ax(2).YLim, [0.8 1.2]))
assert(G.ax(1).Title.String == "time" && string(G.ax(1).Parent.Title.String) == "Synthetic")
assert(isequal(string(G.ax(1).Legend.String), ["sin", "cos", "m"]), "凡例の既定はタグ")
assert(isscalar(G.sct_plt.RefLine) && G.sct_plt.RefLine.Value == 1.05 && G.sct_plt.RefLine.Parent == G.ax(2))
assert(isequal(G.SeriesColor(3, :), [0 0 0]) && all(isnan(G.SeriesColor([1 2 4 5 6], :)), "all"))
assert(isequal(G.SeriesLabel, ["sin"; "cos"; "m"; "B1"; "B2"; "B3"]))
% set_data: 見た目はタグで残り、新しい要素は既定値。パネルの数は変えられない
G.set_style("c", Color="r");
G.set_style("B2", Visible=false);
sct2 = sct;
sct2.sct_series(1).rm_y = [sin(rv_t); cos(rv_t); 0.5*sin(rv_t)].';
sct2.sct_series(1).sv_tag = ["s"; "c"; "h"];
sct2.sct_series(1).sv_legend = [];
G.set_data(sct2);
assert(isequal(G.tab_element.Tag(1:3), ["s"; "c"; "h"]) && height(G.tab_element) == 7)
assert(isequal(G.SeriesColor(2, :), [1 0 0]) && all(isnan(G.SeriesColor(3, :))))
assert(~G.SeriesVisible(6) && isnan(G.sct_plt.Element(6).YData(2)))
assert(isequal(string(G.ax(1).Legend.String), ["sin", "cos", "h", "m"]), "ラベルもタグで残る")
sct3 = sct;
sct3.sct_panel = sct.sct_panel(1);
sct3.sct_series = sct.sct_series(1);
assert(error_id(@() G.set_data(sct3)) == "GUILDA:GraphChart:PanelCount")
% データの誤り
bad = sct;  bad.sct_series(1).sv_tag = "s";
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldSize")
bad = sct;  bad.sct_series(1).i_panel = 3;
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldValue")
bad = sct;  bad.sct_series(3).rm_y = [1 1; 1 1; 1 1];
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldSize")
bad = sct;  bad.sct_series = rmfield(bad.sct_series, "rm_y");
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:MissingField")
assert(error_id(@() set_prop(G, "SeriesColor", zeros(2, 3))) == "GUILDA:GraphChart:StyleSize")


%% set_style by tag and by vector give the same graphics
G1 = GraphChart(sct, Parent=uipanel(fig, "Position", [0 0 0.5 1]));
G2 = GraphChart(sct, Parent=uipanel(fig, "Position", [0.5 0 0.5 1]));
G1.set_style(["s", "c"], Color="#00A000", LineWidth=[2 3], LineStyle="--", Marker="o", MarkerSize=[4 8]);
G1.set_style("m", Label="points", Marker="x", MarkerSize=12);
G1.set_style("B2", Color="m");
G1.set_style(["c", "B3"], Visible=false);
G2.SeriesColor(1:2, :) = [0 160/255 0; 0 160/255 0];
G2.SeriesLineWidth(1:2) = [2; 3];
G2.SeriesLineStyle(1:2) = "--";
G2.SeriesMarker(1:2) = "o";
G2.SeriesMarkerSize(1:2) = [4; 8];
G2.SeriesLabel(3) = "points";
G2.SeriesMarker(3) = "x";
G2.SeriesMarkerSize(3) = 12;
G2.SeriesColor(5, :) = [1 0 1];
G2.SeriesVisible([2 6]) = false;
assert(isequaln(graphics_of(G1), graphics_of(G2)))
assert(isequal(G1.sct_plt.Element(2).Visible, matlab.lang.OnOffSwitchState.off))
assert(isequal(G1.sct_plt.Element(5).CData(2, :), [1 0 1]) && isnan(G1.sct_plt.Element(6).YData(3)))
assert(isequal(string(G1.ax(1).Legend.String), ["sin", "points"]), "隠した線は凡例から外れる")
% 種類に合わないオプション、知らないタグ、タグの数と合わない値
assert(error_id(@() G1.set_style("B1", LineWidth=2)) == "GUILDA:GraphBase:StyleNotApplicable")
assert(error_id(@() G1.set_style("m", LineStyle=":")) == "GUILDA:GraphBase:StyleNotApplicable")
assert(error_id(@() G1.set_style("zz", Color="r")) == "GUILDA:GraphBase:UnknownTag")
assert(error_id(@() G1.set_style(["s", "c"], LineWidth=[1 2 3])) == "GUILDA:GraphBase:StyleValue")
% 見た目の変更はグラフィックスを作り直さない
h_line = G1.sct_plt.Element(1);
h_bar  = G1.sct_plt.Element(4);
G1.set_style("s", Color="b");
G1.SeriesColor(4, :) = [1 0 0];
assert(G1.sct_plt.Element(1) == h_line && G1.sct_plt.Element(4) == h_bar && isgraphics(h_line))


%% NaN colors follow the color order and reset_style returns the data defaults
G = GraphChart(sct, Parent=fig);
rm_order = G.ax(1).ColorOrder;
assert(isequal(G.sct_plt.Element(1).Color, rm_order(1, :)) && isequal(G.sct_plt.Element(2).Color, rm_order(2, :)))
assert(isequal(G.sct_plt.Element(3).Color, [0 0 0]), "rm_color の初期値")
assert(isequal(G.sct_plt.Element(4).CData, repmat(G.ax(2).ColorOrder(1, :), 3, 1)))
G.set_style(["s", "B1"], Color="r");
G.set_style("s", LineWidth=4, Label="x");
G.SeriesColor(1, :) = NaN;                        % NaN に戻すと既定の色
assert(isequal(G.sct_plt.Element(1).Color, rm_order(1, :)))
G.SeriesColor(1, :) = [1 0 0];
G.reset_style("s");
assert(isequal(G.sct_plt.Element(1).Color, rm_order(1, :)) && G.sct_plt.Element(1).LineWidth == 1)
assert(G.SeriesLabel(1) == "sin" && isequal(G.sct_plt.Element(4).CData(1, :), [1 0 0]))
G.set_style("m", Color="g");
G.reset_style();
assert(isequal(G.sct_plt.Element(4).CData(1, :), G.ax(2).ColorOrder(1, :)) && isequal(G.sct_plt.Element(3).Color, [0 0 0]))
% 選択は reset_style で変わらない
G.select("c");
G.reset_style();
assert(isequal(G.Selection, "c"))


%% set_time draws a cursor on the time panels and follows a linked GraphSpring2D
G = GraphChart(sct, Parent=fig);
h_cur = G.sct_plt.Cursor;
assert(isscalar(h_cur) && h_cur.Parent == G.ax(1) && h_cur.Visible == "off", "set_time の前はカーソルなし")
G.set_time(1.04);
assert(h_cur.Value == 1.0 && h_cur.Visible == "on" && G.i_time == 11)
G.set_data(sct);                                   % set_data の後も時刻とカーソルが残る
assert(G.sct_plt.Cursor.Value == 1.0 && G.sct_plt.Cursor.Visible == "on")
% 時刻のパネルのない図は set_time を無視する
sct_bar = sct;
sct_bar.sct_panel = sct.sct_panel(2);
sct_bar.sct_series = sct.sct_series(3);
sct_bar.sct_series.i_panel = 1;
sct_bar.sct_refline = struct.empty;
sct_bar = rmfield(sct_bar, "rv_t");
B = GraphChart(sct_bar, Parent=fig);
B.set_time(5);
assert(isempty(B.sct_plt.Cursor) && B.i_time == 1)
% 同じ ResultODE のばね質点の図とリンク
[net, ~] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5, 0.55], "FaultBus", net.a_Bus{3}.s_tag);
res = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=[0, 2]));
T = res.plot_trajectory(Parent=uipanel(fig, "Position", [0 0 0.5 1]));
S = res.plot_spring_model(Parent=uipanel(fig, "Position", [0.5 0 0.5 1]));
T.link(S);
S.set_time(1.2);
[~, k] = min(abs(res.rv_t - 1.2));
assert(T.i_time == k && T.sct_plt.Cursor.Value == res.rv_t(k) && T.sct_plt.Cursor.Visible == "on")
T.set_time(0.3);
assert(abs(S.rv_t(S.i_time) - 0.3) <= max(diff(S.rv_t)))


%% A marker cursor puts a marker on each line at its point of the sample
% PV 曲線のように x が時刻でない時刻のパネル: 標本 k ごとに (rv_x(k), rm_y(k, 列)) へマーカー。
% 色と表示は要素に従い、リンクと set_data でも動く。行数が標本数と違うと誤り
rv_k = 1:6;
rv_l = [0 0.3 0.55 0.7 0.75 0.72];
pv = struct();
pv.rv_t = rv_k;
pv.sct_panel  = struct("s_xlabel", "lambda", "s_ylabel", "|V|", "l_time", true, "s_cursor", "marker");
pv.sct_series = struct("rv_x", rv_l, "rm_y", [1 0.98 0.95 0.9 0.82 0.7; 1 0.99 0.97 0.94 0.9 0.8].', ...
                       "sv_tag", ["B1"; "B2"]);
P = GraphChart(pv, Parent=fig);
hv = P.sct_plt.CursorMarker;
assert(numel(hv) == 2 && all(isgraphics(hv)) && isempty(P.sct_plt.Cursor))
assert(all(string(get(hv, "Visible")) == "off"), "set_time の前はマーカーなし")
P.set_time(4);
assert(P.i_time == 4 && hv(1).XData == 0.7 && hv(1).YData == 0.9 && hv(2).YData == 0.94)
assert(all(string(get(hv, "Visible")) == "on"))
assert(isequal(hv(1).MarkerFaceColor, P.ax.ColorOrder(1, :)) && isequal(hv(2).MarkerFaceColor, P.ax.ColorOrder(2, :)))
P.set_style("B2", Color="r");
assert(isequal(hv(2).MarkerFaceColor, [1 0 0]))
P.set_style("B1", Visible=false);
assert(hv(1).Visible == "off" && hv(2).Visible == "on")
P.set_time(5);
assert(hv(1).Visible == "off" && hv(2).XData == 0.75)
assert(~ismember(hv(1), P.ax.Legend.PlotChildren) && hv(1).PickableParts == "none")
% リンクした線のカーソルの図と動く (標本の値が同じ 1..6)
L = GraphChart(struct("rv_t", rv_k, "sct_panel", struct("l_time", true), ...
    "sct_series", struct("rv_x", rv_k, "rm_y", rv_l.', "sv_tag", "lambda")), Parent=uipanel(fig));
P.link(L);
L.set_time(2);
assert(P.i_time == 2 && hv(2).XData == 0.3 && L.sct_plt.Cursor.Value == 2)
P.set_data(pv);
assert(P.i_time == 2 && P.sct_plt.CursorMarker(2).XData == 0.3 && P.sct_plt.CursorMarker(2).Visible == "on")
bad = pv;  bad.sct_series.rm_y = bad.sct_series.rm_y(1:5, :);  bad.sct_series.rv_x = rv_l(1:5);
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldSize")
bad = pv;  bad.sct_panel.l_time = false;
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldValue")
bad = pv;  bad.sct_panel.s_cursor = "dot";
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldValue")


%% A series with iv_sample shows the rows of the sample shown, and a panel takes a title per sample
% iv_sample: 各行の標本。set_time で標本の行だけを出し、選択の輪も追う。題名は標本ごと。
% 再生バーが出る。棒や範囲外の標本、題名の数の誤りはエラー
ss = struct();
ss.rv_t = [0 1 2];
ss.sct_panel  = struct("s_title", ["a", "b", "c"]);
ss.sct_series = struct("s_type", "marker", "rv_x", [1; 2; 3; 4], "rm_y", [10; 20; 30; 40], ...
                       "iv_sample", [1; 1; 2; 3], "sv_tag", "e");
E = GraphChart(ss, Parent=fig);
h = E.sct_plt.Element;
assert(isequal(h.XData, [1 2]) && string(E.ax.Title.String) == "a")
E.select("e");
E.set_time(1.2);
assert(isequal(h.XData, 3) && isequal(h.YData, 30) && string(E.ax.Title.String) == "b")
assert(isequal(E.sct_plt.Selection.XData, 3), "選択の輪も標本の点")
E.set_time(5);
assert(isequal(h.XData, 4) && string(E.ax.Title.String) == "c")
pE = uipanel(fig);
GraphChart(ss, Parent=pE);
assert(isscalar(findall(pE, "Tag", "GUILDA:GraphBase:PlaybackBar")), "標本ごとの系列には再生バー")
bad = ss;  bad.sct_series.iv_sample = [1; 1; 2; 4];
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldValue")
bad = ss;  bad.sct_series.s_type = "bar";
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldValue")
bad = ss;  bad.sct_panel.s_title = ["a", "b"];
assert(error_id(@() GraphChart(bad, Parent=fig)) == "GUILDA:GraphChart:FieldSize")


%% Parent is a container or, for a single panel, an axes or uiaxes
sct1 = sct;
sct1.sct_panel = sct.sct_panel(1);
sct1.sct_series = sct.sct_series(1:2);
sct1.sct_refline = struct.empty;
ax = axes(figure("Visible", "off"));
c_f2 = onCleanup(@() close(ancestor(ax, "figure")));
G = GraphChart(sct1, Parent=ax);
assert(G.ax == ax && ax.Title.String == "time")
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
ua = uiaxes(uf);
G = GraphChart(sct1, Parent=ua);
assert(G.ax == ua && height(G.tab_element) == 3)
G.set_style("s", Color="r");
G.set_time(1);
assert(isequal(G.sct_plt.Element(1).Color, [1 0 0]) && G.sct_plt.Cursor.Visible == "on")
% 2 パネルの図は容器が要る
assert(error_id(@() GraphChart(sct, Parent=uiaxes(uf))) == "GUILDA:GraphBase:ParentNeedsContainer")
assert(error_id(@() GraphChart(sct, Parent=ax)) == "GUILDA:GraphBase:ParentNeedsContainer")
% uifigure の uitab にも描ける
tg = uitabgroup(uf);
G = GraphChart(sct, Parent=uitab(tg));
assert(numel(G.ax) == 2)
% uigridlayout: 次の空いたセルに枠のない uipanel を置き、その中にタイルを並べる (GridLayout は
% tiledlayout を直接持てず、警告が出るため)。1 パネルでも 2 パネルでも警告なし
ug = uigridlayout(uf, [1, 3]);
uilabel(ug, "Text", "left");
for c = {sct1, 1; sct, 2}'
    lastwarn("");
    G = GraphChart(c{1}, Parent=ug);
    [s_warn, s_id] = lastwarn();
    h_panel = G.ax(1).Parent.Parent;
    assert(s_warn == "" && s_id == "", "警告: %s (%s)", s_warn, s_id)
    assert(numel(G.ax) == c{2} && isa(h_panel, "matlab.ui.container.Panel") && h_panel.Parent == ug ...
           && h_panel.BorderType == "none" && h_panel.Layout.Column == c{2} + 1, "次の空いたセル")
end
assert(error_id(@() GraphChart(sct, Parent="x")) == "GUILDA:GraphBase:ParentType")


%% rv_grid lays the panels out row by row
% 4 パネル (1 つは対数軸) を 2 x 2 に。パネル 2 は右上、3 は左下
rv_k = 1:20;
f_panel  = @(s_title, s_yscale) struct("s_title", s_title, "s_xlabel", "iteration", "s_yscale", s_yscale, "l_time", true);
f_series = @(i_panel, rm_y, sv_tag) struct("i_panel", i_panel, "rv_x", rv_k, "rm_y", rm_y, "sv_tag", sv_tag);
sct4 = struct("rv_t", rv_k, "rv_grid", [2 2], ...
    "sct_panel", [f_panel("objective", "linear"), f_panel("violation", "log"), f_panel("P", "linear"), f_panel("|V|", "linear")], ...
    "sct_series", [f_series(1, 10 ./ rv_k(:), "Fval"), f_series(2, 10.^(-rv_k(:) / 3), "Viol"), ...
                   f_series(3, [sin(rv_k(:)), cos(rv_k(:))], ["G1"; "G2"]), f_series(4, 1 + 0.01*rv_k(:), "B1")]);
G = GraphChart(sct4, Parent=fig);
tl = G.ax(1).Parent;
assert(isa(tl, "matlab.graphics.layout.TiledChartLayout") && isequal(tl.GridSize, [2 2]) && numel(G.ax) == 4)
assert(isequal(arrayfun(@(a) a.Layout.Tile, G.ax(:)'), 1:4) && G.ax(2).YScale == "log")
drawnow;
rm_pos = vertcat(G.ax.Position);
assert(rm_pos(2, 1) > rm_pos(1, 1) && abs(rm_pos(2, 2) - rm_pos(1, 2)) < 1e-6, "パネル 2 は右上")
assert(abs(rm_pos(3, 1) - rm_pos(1, 1)) < 1e-6 && rm_pos(3, 2) < rm_pos(1, 2), "パネル 3 は左下")
% set_data は同じ格子で描き直す。格子の違うデータ (省略は 1 列) は GridChange
sct4b = sct4;
sct4b.sct_series(1).rm_y = 20 ./ rv_k(:);
G.set_data(sct4b);
assert(isequal(G.ax(1).Parent.GridSize, [2 2]) && isequal(G.sct_plt.Element(1).YData, 20 ./ rv_k))
% 時刻ごとの題は TimeChangedFcn で書く
G.TimeChangedFcn = @(G, data) title(G.ax(1).Parent, sprintf("iteration %d", data.Index));
G.set_time(7);
assert(string(G.ax(1).Parent.Title.String) == "iteration 7")
sct4b.rv_grid = [4 1];
assert(error_id(@() G.set_data(sct4b)) == "GUILDA:GraphChart:GridChange")
assert(error_id(@() G.set_data(rmfield(sct4b, "rv_grid"))) == "GUILDA:GraphChart:GridChange")
% 3 x 1 (既定と同じ) と、3 パネルの 2 x 2 (4 つ目のタイルは空)
sct3 = sct4;
sct3.sct_panel = sct4.sct_panel(1:3);
sct3.sct_series = sct4.sct_series(1:3);
sct3.rv_grid = [3 1];
G3 = GraphChart(sct3, Parent=fig);
assert(isequal(G3.ax(1).Parent.GridSize, [3 1]) && isequal(arrayfun(@(a) a.Layout.Tile, G3.ax(:)'), 1:3))
G3.set_data(rmfield(sct3, "rv_grid"));             % 省略は [n_panel 1] なので同じ格子
sct3.rv_grid = [2 2];
G3 = GraphChart(sct3, Parent=uipanel(fig));
assert(isequal(G3.ax(1).Parent.GridSize, [2 2]) && numel(G3.ax) == 3 && G3.ax(3).Layout.Tile == 3)
% 誤り: タイルが足りない、正の整数でない。軸の Parent は複数パネルなら格子があっても誤り
sct3.rv_grid = [1 2];
assert(error_id(@() GraphChart(sct3, Parent=fig)) == "GUILDA:GraphChart:FieldValue")
sct3.rv_grid = [0 3];
assert(error_id(@() GraphChart(sct3, Parent=fig)) == "GUILDA:GraphChart:FieldValue")
sct3.rv_grid = [2 2];
assert(error_id(@() GraphChart(sct3, Parent=axes(fig))) == "GUILDA:GraphBase:ParentNeedsContainer")


%% Clicking a line, a marker set or a bar raises ElementClicked
G = GraphChart(sct, Parent=fig);
fig.UserData = strings(0, 3);
G.ElementClickedFcn = @(g, d) set(fig, "UserData", [fig.UserData; d.Tag, d.Kind, string(d.Index)]);
lh = addlistener(G, "ElementClicked", @(g, d) setappdata(fig, "last_event", d));
click(G.sct_plt.Element(2), []);
click(G.sct_plt.Element(3), []);
h_bar = G.sct_plt.Element(4);
click(h_bar, struct("IntersectionPoint", [h_bar.XEndPoints(2) + 0.1, 0.5, 0]));
assert(isequal(fig.UserData, ["c", "line", "2"; "m", "marker", "3"; "B2", "bar", "5"]))
d = getappdata(fig, "last_event");
assert(isa(d, "GraphEventData") && d.Tag == "B2" && d.Index == 5)
delete(lh);
% 選択: 線の下に太い線、マーカーに輪、棒に枠。凡例には入らず、見た目を変えない
G.select(["s", "m", "B3"]);
hv = G.sct_plt.Selection;
assert(numel(hv) == 3 && all(string({hv.PickableParts}) == "none"))
assert(hv(1).LineWidth == G.sct_plt.Element(1).LineWidth + 4 && isequal(hv(1).Color, G.SelectionColor))
assert(hv(2).Marker == "o" && hv(3).Parent == G.ax(2))
assert(isequal(string(G.ax(1).Legend.String), ["sin", "cos", "m"]))
assert(all(isnan(G.SeriesColor(1, :))))
G.set_time(1);
assert(numel(G.sct_plt.Selection) == 3, "set_time の後も選択が残る")
G.set_style("B3", Visible=false);
assert(numel(G.sct_plt.Selection) == 3)
G.clear_selection();
assert(isempty(G.sct_plt.Selection))


%% plot_trajectory returns a GraphChart with the bus or component tags
[net, ~] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5, 0.55], "FaultBus", net.a_Bus{3}.s_tag);
res = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=[0, 1]));
G = res.plot_trajectory(Parent=fig);
assert(isa(G, "GraphChart") && isa(G, "GraphBase") && isscalar(G.ax))
assert(isequal(G.tab_element.Tag, res.sv_bus(:)) && all(G.tab_element.Kind == "line"))
assert(isequal(G.sct_plt.Element(1).XData, reshape(res.odeResults.t, 1, [])))
assert(max(abs(G.sct_plt.Element(2).YData(:) - abs(res.odeResults.Bus(2).V{:,:} * [1; 1j]))) < 1e-12)
assert(G.ax.XLabel.String == "t [s]" && G.ax.YLabel.String == "|V| [pu]" && startsWith(G.ax.Title.String, "Time response"))
assert(isequal(string(G.ax.Legend.String), res.sv_bus(:)') && G.sct_plt.Element(1).LineWidth == 1.2)
G = res.plot_trajectory(Quantity="omega", Parent=fig);
sv_com = vertcat(res.c_component{:});
assert(all(ismember(G.tab_element.Tag, sv_com)) && height(G.tab_element) >= 1)
G.set_style(G.tab_element.Tag(1), Color="r");
assert(isequal(G.sct_plt.Element(1).Color, [1 0 0]))
G = res.plot_trajectory(Quantity="Vangle", Bus=res.sv_bus(2), Parent=fig);
assert(isequal(G.tab_element.Tag, res.sv_bus(2)) && G.ax.YLabel.String == "\angle V [rad]")


%% The figure keeps the graph; savefig does not recurse; deleting the figure frees it
% クリックのコールバックは弱い参照でチャートをたどり、図 (ax(1) のリスナー) がチャートを持つ。
% 出力を clear してもクリックは ElementClicked になり、savefig は警告を出さず、保存した図のコールバックは
% グラフを持たない (強い参照だと .fig にチャートの複製が入る)。図を消すとチャートは解放される
f2 = figure("Visible", "off");
c_f2 = onCleanup(@() close(f2(isgraphics(f2))));
G = GraphChart(sct, Parent=f2);                            % 線・マーカー・棒
G.ElementClickedFcn = @(g, d) set(f2, "UserData", d.Tag);
wr = matlab.lang.WeakReference(G);
clear G
assert(is_alive(wr), "出力を clear してもチャートは図とともに残る")
h_bar = wr.Handle.sct_plt.Element(4);
click(h_bar, struct("IntersectionPoint", [h_bar.XEndPoints(3), 0.5, 0]));
assert(f2.UserData == "B3")
s_fig = string(tempname) + ".fig";
c_file = onCleanup(@() delete(s_fig(isfile(s_fig))));
lastwarn("");
savefig(f2, s_fig);
[s_warn, s_warnId] = lastwarn();
assert(isempty(s_warn), "savefig warned: %s (%s)", s_warn, s_warnId)
assert(saved_graphs(s_fig) == "", "保存した図のコールバックがグラフを持つ")
click(findobj(f2, "Type", "line", "-not", "Tag", "TimeCursor", "-and", "YData", cos(rv_t)), []);
assert(f2.UserData == "c", "保存のあともクリックが効く")
delete(f2);
assert(~is_alive(wr), "図を消すとチャートは解放される")
% plot_trajectory の出力を受け取らなくてもクリックが効く (図がチャートを持つ)
[net, ~] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5, 0.55], "FaultBus", net.a_Bus{3}.s_tag);
res = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=[0, 1]));
f2 = figure("Visible", "off");
G = res.plot_trajectory(Parent=f2);
G.ElementClickedFcn = @(g, d) set(f2, "UserData", d.Tag);
G.show_controls();                                         % 操作パネルのコールバックも弱い参照
s_tag = G.tab_element.Tag(1);
h_line = G.sct_plt.Element(1);
wr = matlab.lang.WeakReference(G);
clear G
click(h_line, []);
assert(f2.UserData == s_tag)
lastwarn("");
savefig(f2, s_fig);
[s_warn, s_warnId] = lastwarn();
assert(isempty(s_warn), "savefig warned: %s (%s)", s_warn, s_warnId)
assert(saved_graphs(s_fig) == "", "保存した図のコールバックがグラフを持つ")
clear h_line
delete(f2);
assert(~is_alive(wr))
% ばね質点の図 (GraphSpring2D/3D) も同じ: 出力を clear してもクリックが効き、保存した図はグラフを持たない
for i_dim = [2, 3]
    f2 = figure("Visible", "off");
    G = res.plot_spring_model(Dimension=i_dim, Parent=f2);
    G.ElementClickedFcn = @(g, d) set(f2, "UserData", d.Tag);
    s_tag = G.tab_element.Tag(1);
    h_node = G.sct_plt.Node(1);
    wr = matlab.lang.WeakReference(G);
    clear G
    click(h_node, []);
    assert(f2.UserData == s_tag)
    lastwarn("");
    savefig(f2, s_fig);
    [s_warn, s_warnId] = lastwarn();
    assert(isempty(s_warn), "savefig warned: %s (%s)", s_warn, s_warnId)
    assert(saved_graphs(s_fig) == "", "保存した図のコールバックがグラフを持つ")
    clear h_node
    delete(f2);
    assert(~is_alive(wr))
end
clear c_file c_f2


function c = graphics_of(G)
% 要素のグラフィックスの見た目 (線とマーカーはプロパティ、棒は CData と YData の行)
    tab = G.tab_element;
    c = cell(height(tab), 1);
    for i = 1:height(tab)
        h = G.sct_plt.Element(i);
        if tab.Kind(i) == "bar"
            k = i - find(tab.Kind == "bar", 1) + 1;
            c{i} = {h.CData(k, :), h.YData(k)};
        else
            c{i} = {h.Color, h.LineWidth, string(h.LineStyle), string(h.Marker), h.MarkerSize, ...
                    string(h.DisplayName), string(h.Visible)};
        end
    end
end

function s = saved_graphs(s_fig)
% 保存した図を開き、コールバックの関数のワークスペースにある GraphBase を "クラス.プロパティ" で返す ("" はなし)
    sct_warn = warning("off", "all");                     % 開いた図の弱い参照は空
    c_warn = onCleanup(@() warning(sct_warn));
    f = openfig(s_fig, "invisible");
    c_fig = onCleanup(@() delete(f));
    sv = strings(0, 1);
    for h = findall(f)'
        for s_prop = ["ButtonDownFcn", "ValueChangedFcn", "DeleteFcn", "Callback", "CreateFcn"]
            if isprop(h, s_prop) && isa(h.(s_prop), "function_handle")
                sct = functions(h.(s_prop));
                if isfield(sct, "workspace") && ~isempty(sct.workspace)
                    w = sct.workspace{1};
                    if any(structfun(@(v) isa(v, "GraphBase"), w))
                        sv(end+1, 1) = class(h) + "." + s_prop; %#ok<AGROW>
                    end
                end
            end
        end
    end
    s = join([""; sv], " ");
    s = strtrim(s);
end

function l = is_alive(wr)
% 弱い参照の先のグラフがまだ有効か
    G = wr.Handle;
    l = ~isempty(G) && isvalid(G);
end

function click(h, e)
% グラフィックスの ButtonDownFcn をプログラムから呼ぶ
    f = h.ButtonDownFcn;
    f(h, e);
end

function set_prop(G, s_name, val)
    G.(s_name) = val;
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
