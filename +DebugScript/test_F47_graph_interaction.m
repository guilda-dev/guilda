% F47 図の操作 (GraphBase): クリック、選択、見た目の初期化、構成図、描き直し、uiaxes
%
%   G.ElementClickedFcn = @(G, data) ...;  addlistener(G, "ElementClicked", ...);   % data: GraphEventData
%   G.select(sr_tag);  G.clear_selection();  G.Selection;  G.SelectionColor = ...;
%   G.reset_style(sr_tag);  G.reset_style();
%   G = net.plot_diagram(State="auto" | "equilibrium" | "topology");
%   G = net.plot_diagram(Graph=G);          % 同じ図に描き直す
%   G = net.plot_diagram(Parent=uiaxes(uifigure));
%   G = net.plot_diagram(Parent=uipanel / uigridlayout / uitab / figure / axes);
%
% クリックはグラフィックスの ButtonDownFcn をプログラムから呼んで確かめる。図はすべて
% 見えない figure / uifigure に描く。
%
% 実行: runtests("DebugScript.test_F47_graph_interaction")  または  DebugScript.run_all("Features","F47")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% 合成のばね質点データ (test_F42 と同じ)
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
% 座標を持たない 3 母線系統 (自動配置を通る)
[net, gen] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
sv_bus = string(cellfun(@(b) b.s_tag, net.a_Bus(:), "UniformOutput", false));
c_com  = cellfun(@(b) cellfun(@(c) string(c.s_tag), b.a_Component(:)), net.a_Bus(:), "UniformOutput", false);
sv_com = vertcat(c_com{:});
sv_br  = string(cellfun(@(b) b.s_tag, net.a_Branch(:), "UniformOutput", false));


%% Clicking an element raises ElementClicked and calls ElementClickedFcn
G = GraphSpring2D(sct, Parent=axes(fig));
assert(isempty(G.ElementClickedFcn))
fig.UserData = strings(0, 3);
G.ElementClickedFcn = @(g, d) set(fig, "UserData", [fig.UserData; d.Tag, d.Kind, string(d.Index)]);
lh = addlistener(G, "ElementClicked", @(g, d) setappdata(fig, "last_event", d));
click(G.sct_plt.Node(4));
click(G.sct_plt.Spring(2));
assert(isequal(fig.UserData, ["G1", "node", "4"; "L23", "edge", "2"]))
d = getappdata(fig, "last_event");
assert(isa(d, "GraphEventData") && isa(d, "event.EventData") && d.Tag == "L23" && d.Kind == "edge" && d.Index == 2)
assert(error_id(@() set_prop(d, "Tag", "x")) ~= "", "Tag は読み取り専用")
delete(lh);
% 関数ハンドルでないものは使えない
assert(error_id(@() set_prop(G, "ElementClickedFcn", "disp")) == "GUILDA:GraphBase:ClickFcn")
% 3D も同じ
G3 = GraphSpring3D(sct, Parent=axes(fig));
G3.ElementClickedFcn = @(g, d) set(fig, "UserData", d.Tag);
click(G3.sct_plt.Node(2));
assert(fig.UserData == "B2")
% ネットワーク図 (3D): 母線、機器、ブランチ、リンク (筒と矢印の子も)
D = net.plot_diagram(Parent=axes(fig), Dimension="3D");
D.ElementClickedFcn = @(g, d) set(fig, "UserData", d.Kind + ":" + d.Tag);
click(D.sct_plt.NodeMain(2));
assert(fig.UserData == "bus:" + sv_bus(2))
click(D.sct_plt.CompMain(1));
assert(fig.UserData == "component:" + sv_com(1))
click(D.sct_plt.EdgeMain(1));
assert(fig.UserData == "branch:" + sv_br(1))
h = findall(D.sct_plt.EdgeArrow(2));
click(h(end));
assert(fig.UserData == "branch:" + sv_br(2))
click(D.sct_plt.CompEdge(1));
assert(fig.UserData == "link:" + sv_com(1))
% 描き直した後 (2D) もクリックできる
D.Dimension = "2D";
click(D.sct_plt.NodeMain(1));
assert(fig.UserData == "bus:" + sv_bus(1))
click(D.sct_plt.CompMain(1));
assert(fig.UserData == "component:" + sv_com(1))
click(D.sct_plt.EdgeMain(2));
assert(fig.UserData == "branch:" + sv_br(2))
click(D.sct_plt.CompEdge(1));
assert(fig.UserData == "link:" + sv_com(1))
% コールバックは図を弱い参照で持つ: 図を消した後のクリックは何もしない
f_click = D.sct_plt.NodeMain(1).ButtonDownFcn;
delete(D);
assert(~isvalid(D), "delete は図を消す (デストラクタ)")
fig.UserData = [];
f_click([], []);
assert(isempty(fig.UserData))


%% select adds an overlay that does not change the styles
G = GraphSpring2D(sct, Parent=axes(fig));
assert(isequal(G.Selection, strings(1, 0)) && isequal(G.SelectionColor, [1 176/255 0]))
G.set_style("B1", Color="r");
c_before = style_values(G, ["NodeColor", "NodeSize", "NodeVisible", "EdgeColor", "EdgeLineWidth"]);
n_child = numel(G.ax.Children);
G.select("B1");
G.select(["L12", "B1"]);                            % 二度目の B1 は増えない
assert(isequal(G.Selection, ["B1", "L12"]))
assert(numel(G.sct_plt.Selection) == 2 && numel(G.ax.Children) == n_child + 2)
assert(all(string({G.sct_plt.Selection.PickableParts}) == "none"), "重ねた図形はクリックを取らない")
assert(isequal(G.sct_plt.Selection(1).Color, G.SelectionColor) || isequal(G.sct_plt.Selection(1).MarkerEdgeColor, G.SelectionColor))
assert(isequal(style_values(G, ["NodeColor", "NodeSize", "NodeVisible", "EdgeColor", "EdgeLineWidth"]), c_before))
assert(isequal(G.sct_plt.Node(1).MarkerFaceColor, [1 0 0]), "選択は set_style の色を変えない")
% 選択の色を変えると重ねた図形の色が変わる
G.SelectionColor = "c";
assert(any(arrayfun(@(h) isequal(h.MarkerEdgeColor, [0 1 1]), G.sct_plt.Selection)))
assert(error_id(@() set_prop(G, "SelectionColor", "notacolor")) == "GUILDA:GraphBase:StyleValue")
% 時刻を変えても選択は残り、重ねた図形は節点に付いていく
G.set_time(2);
assert(isequal(G.Selection, ["B1", "L12"]) && numel(G.sct_plt.Selection) == 2)
h_ring = G.sct_plt.Selection(arrayfun(@(h) h.Marker == "o", G.sct_plt.Selection));
assert(abs(h_ring.XData - G.sct_plt.Node(1).XData) < 1e-12 && abs(h_ring.YData - G.sct_plt.Node(1).YData) < 1e-12)
% プロパティで描き直しても選択は残る
G.RMax = 2;
assert(numel(G.sct_plt.Selection) == 2 && all(isgraphics(G.sct_plt.Selection)))
n_child = numel(G.ax.Children) - 2;                 % 格子が変わったので数え直す
% clear_selection で元に戻る
G.clear_selection();
assert(isempty(G.Selection) && numel(G.ax.Children) == n_child)
assert(isequal(style_values(G, ["NodeColor", "NodeSize", "NodeVisible", "EdgeColor", "EdgeLineWidth"]), c_before))
% 知らないタグ
assert(error_id(@() G.select("ZZZ")) == "GUILDA:GraphBase:UnknownTag")
% set_data で消えたタグは選択から外れる
G.select(["B2", "B3"]);
s2 = sct;
s2.sv_node(2) = "B9";
G.set_data(s2);
assert(isequal(G.Selection, "B3") && numel(G.sct_plt.Selection) == 1)
% ネットワーク図 (3D: 母線、機器とそのリンク、ブランチ)
D = net.plot_diagram(Parent=axes(fig), Dimension="3D");
D.set_style(sv_bus(1), Color="r");
D.select([sv_bus(1), gen.s_tag, sv_br(1)]);
assert(numel(D.sct_plt.Selection) == 4, "機器のタグはリンクも選ぶ")
assert(isequal(D.sct_plt.NodeMain(1).FaceColor, [1 0 0]))
D.set_time(0);
D.BusHeightMode = "V";
assert(numel(D.sct_plt.Selection) == 4 && all(isgraphics(D.sct_plt.Selection)))
D.clear_selection();
assert(isequal(D.sct_plt.NodeMain(1).FaceColor, [1 0 0]) && isequaln(D.BusColor(1, :), [1 0 0]))


%% The selection of a bent branch or link follows its mid points
% IEEE14: 線路 1-2 は中間点 (0.23,0.5),(0.36,0.33)、B002 の負荷のリンクは中間点 (0.36,0.25)
net14 = network.IEEE14bus();
D = net14.plot_diagram(Parent=axes(fig), State="topology", Dimension="3D");
tab = D.tab_element;
s_br   = tab.Tag(find(tab.Kind == "branch", 1));
s_link = tab.Tag(tab.Kind == "link" & startsWith(tab.Tag, "B002") & contains(tab.Tag, "LPQ"));
D.select([s_br; s_link]);                          % 機器のタグは機器の輪とリンクを選ぶ
h = D.sct_plt.Selection;
h = h(arrayfun(@(x) x.Marker == "none", h));       % 線: ブランチ、リンクの順
assert(numel(h) == 2 && all(arrayfun(@(x) numel(x.XData), h) >= 3), "端と中間点を通る")
h_br = h(1);
assert(all(ismembertol([0.23 0.5; 0.36 0.33], [h_br.XData(:), h_br.YData(:)], 1e-12, "ByRows", true)))
% 選択の線は描いた枝の中心線のすぐ上 (3D。2D は同じ高さで下に描く: test_F59_diagram_2d)
rm_path = D.sct_plt.EdgePath{1};
assert(max(abs([h_br.XData(:), h_br.YData(:)] - rm_path(:, 1:2)), [], "all") < 1e-12)
assert(all(h_br.ZData(:) > rm_path(:, 3)))
h_link = h(2);
assert(any(abs(h_link.XData - 0.36) < 1e-12 & abs(h_link.YData - 0.25) < 1e-12))
% 母線を動かしても枝の経路に付いていく
D.set_position("B001", [0.15, 0.55]);
h_br = D.sct_plt.Selection(arrayfun(@(x) x.Marker == "none", D.sct_plt.Selection));
h_br = h_br(1);
assert(all(ismembertol([0.23 0.5; 0.36 0.33], [h_br.XData(:), h_br.YData(:)], 1e-12, "ByRows", true)))


%% reset_style returns the styles to the defaults of the data
G = GraphSpring2D(sct, Parent=axes(fig));
c_default = style_values(G, ["NodeColor", "NodeLabel", "NodeSize", "NodeMarker", "NodeVisible", "EdgeColor", "EdgeLineWidth", "EdgeVisible"]);
G.set_style(["B1", "B2"], Color="r", MarkerSize=20, Label="x");
G.set_style("L12", LineWidth=4, Visible=false);
G.select("B1");
G.reset_style("B1");
assert(isequal(G.NodeColor(1, :), [0 0 0]) && G.NodeSize(1) == 5 && G.NodeLabel(1) == "B1")
assert(isequal(G.NodeColor(2, :), [1 0 0]) && G.NodeSize(2) == 20, "ほかのタグは変えない")
assert(isequal(G.sct_plt.Node(1).MarkerFaceColor, [0 0 0]) && string(G.sct_plt.LabelNode(1).String) == "B1")
assert(isequal(G.Selection, "B1"), "選択は変えない")
G.reset_style();
assert(isequal(style_values(G, ["NodeColor", "NodeLabel", "NodeSize", "NodeMarker", "NodeVisible", "EdgeColor", "EdgeLineWidth", "EdgeVisible"]), c_default))
assert(G.sct_plt.Spring(1).Visible == "on" && G.sct_plt.Spring(1).LineWidth == 0.8)
assert(error_id(@() G.reset_style("ZZZ")) == "GUILDA:GraphBase:UnknownTag")
% コンストラクタの Name-Value で変えた見た目ではなく、データの既定値に戻る
G = GraphSpring2D(sct, Parent=axes(fig), NodeSize=[9; 9; 9; 9]);
G.reset_style("B1");
assert(G.NodeSize(1) == 5 && G.NodeSize(2) == 9)
% ネットワーク図 (3D)
D = net.plot_diagram(Parent=axes(fig), LabelMode="user", Dimension="3D");
D.set_style(sv_bus(2), Color="r", Label="X");
D.set_style(sv_br(1), Color="b");
D.reset_style([sv_bus(2), sv_br(1)]);
assert(all(isnan(D.BusColor(2, :))) && all(isnan(D.BranchColor(1, :))) && D.BusLabel(2) == sv_bus(2))
assert(~isequal(D.sct_plt.NodeMain(2).FaceColor, [1 0 0]))


%% plot_diagram draws the topology of a network that is not up to date
[net0, gen0] = DebugScript.helper.build_3bus("gen-classical");
% auto: 初期化前は構成だけ (INFO を出す)
s_log = evalc("D = net0.plot_diagram(Parent=axes(fig), Dimension=""3D"");");
assert(contains(s_log, "topology only"), "INFO が出ない")
assert(all(isnan(D.sct_state.cm_Vbus)) && all(isnan(D.sct_state.cm_Icomp)))
assert(all(D.sct_plt.ZMain == 0), "高さなし")
assert(all(isnan(D.BranchColorData)) && all(isnan(D.LinkColorData)))
for i = 1:numel(D.sct_plt.EdgeArrow)
    hv = allchild(D.sct_plt.EdgeArrow(i));
    assert(all(string({hv.Visible}) == "off"), "矢印なし")
end
assert(isempty(D.ax.Colorbar), "色の値がないので色の棒なし")
txt = string(D.hover_bus(1));
assert(contains(txt(1), sv_bus(1)) && ~any(contains(txt, "|V|")), "ホバーにタグだけ")
txt = string(D.hover_branch(1));
assert(contains(txt(1), sv_br(1)) && any(contains(txt, "R")) && ~any(contains(txt, "|I|")))
txt = string(D.hover_component(1));
assert(~any(contains(txt, "|I|")))
% equilibrium: 今までどおり止まる
assert(error_id(@() net0.plot_diagram(Parent=axes(fig), State="equilibrium")) == "GUILDA:PowerNetwork:DiagramStale")
% 初期化済みなら auto は平衡点、topology は構成
D = net.plot_diagram(Parent=axes(fig));
assert(all(isfinite(D.sct_state.cm_Vbus)))
D = net.plot_diagram(Parent=axes(fig), State="topology", BusHeightMode="V");
assert(all(isnan(D.sct_state.cm_Vbus)) && all(D.sct_plt.ZMain == 0))
% 作りかけの系統: スラック母線なし、機器のない母線、ブランチのない母線、ブランチなし
nb = PowerNetwork("Building");
nb.add_bus();
nb.add_bus();
nb.add_bus();
nb.add_branch("pi", [1, 2], "R", 0.01, "X", 0.1);
D = DebugScript.helper.quiet(@() nb.plot_diagram(Parent=axes(fig)));
assert(isequal(D.tab_element.Kind, ["bus"; "bus"; "bus"; "branch"]))
nb2 = PowerNetwork("OneBus");
nb2.add_bus();
D = DebugScript.helper.quiet(@() nb2.plot_diagram(Parent=axes(fig), State="topology"));
assert(height(D.tab_element) == 1 && ~isempty(D.ax.Children))
% モデルは変わらない
assert(isempty(nb.a_Bus{1}.a_Component) && ~any(cellfun(@(b) b.l_isSlack, nb.a_Bus)))


%% plot_diagram Graph redraws into the same diagram
[net1, gen1] = DebugScript.helper.build_3bus("gen-classical");
D = DebugScript.helper.quiet(@() net1.plot_diagram(Parent=axes(fig)));   % 構成
ax = D.ax;
D.set_style(sv_bus(2), Color="r");
D.set_position(sv_bus(1), [0.2, 0.8]);
D.select(sv_bus(3));
n_child = numel(ax.Children);
DebugScript.helper.quiet(@() net1.initialize);
D2 = net1.plot_diagram(Graph=D);
assert(D2 == D && D.ax == ax, "同じハンドル、同じ軸")
assert(all(isfinite(D.sct_state.cm_Vbus)), "平衡点になる")
assert(numel(ax.Children) == n_child, "古い図形が残る")
assert(isequal(D.BusColor(2, :), [1 0 0]) && isequal(D.sct_plt.NodeMain(2).Color, [1 0 0]))
assert(isequal(D.Selection, sv_bus(3)) && numel(D.sct_plt.Selection) == 1)
assert(abs(D.sct_plt.XMain(1) - 0.2) < 1e-12, "動かした位置が残る")
% 系統を編集 (母線とブランチを加える) して描き直す
net1.add_bus();
net1.add_branch("pi", [3, 4], "R", 0.01, "X", 0.1);
s_new = string(net1.a_Bus{4}.s_tag);
D2 = DebugScript.helper.quiet(@() net1.plot_diagram(Graph=D, ColorMode="P"));
assert(D2 == D && D.ColorMode == "P")
assert(any(D.tab_element.Tag == s_new) && numel(D.sct_plt.NodeMain) == 4)
assert(all(isnan(D.sct_state.cm_Vbus)), "編集後は構成だけ")
assert(isequal(D.BusColor(2, :), [1 0 0]) && all(isnan(D.BusColor(4, :))))
assert(abs(D.sct_plt.XMain(1) - 0.2) < 1e-12)
assert(isequal(D.Selection, sv_bus(3)))
% 同じ系統で描き直しても図形は増えない (前の図形は消える)
n_after = numel(ax.Children);
DebugScript.helper.quiet(@() net1.plot_diagram(Graph=D));
assert(numel(ax.Children) == n_after, "描き直しで図形が増える")
% Graph は GraphNetDiagram
G = GraphSpring2D(sct, Parent=axes(fig));
assert(error_id(@() net1.plot_diagram(Graph=G)) == "GUILDA:PowerNetwork:DiagramGraph")


%% uiaxes in a uifigure work as Parent
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
ua = uiaxes(uf);
D = net.plot_diagram(Parent=ua);
assert(D.ax == ua && ~isempty(ua.Children))
D.set_style(sv_bus(1), Color="r");
D.select(sv_bus(2));
D.ElementClickedFcn = @(g, d) set(uf, "UserData", d.Tag);
click(D.sct_plt.NodeMain(3));
assert(uf.UserData == sv_bus(3))
% 当たり判定: 要素の図形はクリックを受け、選択の図形は受けない
h = D.sct_plt.NodeMain(3);
assert(h.HitTest == "on" && h.PickableParts ~= "none" && ~isempty(h.ButtonDownFcn))
assert(D.sct_plt.Selection(1).PickableParts == "none")
G = GraphSpring2D(sct, Parent=uiaxes(uf));
G.select("B1");
G.ElementClickedFcn = @(g, d) set(uf, "UserData", d.Tag);
click(G.sct_plt.Spring(1));
assert(uf.UserData == "L12")
G.set_time(1);
assert(G.i_time == 11 && numel(G.sct_plt.Selection) == 1)
G3 = GraphSpring3D(sct, Parent=uiaxes(uf));
assert(~isempty(G3.ax.Children))


%% Parent is a container or, for single-panel graphs, an axes
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
% figure: 新しい tiledlayout とその中の axes
f2 = figure("Visible", "off");
c_f2 = onCleanup(@() close(f2));
D = net.plot_diagram(Parent=f2);
assert(isa(D.ax.Parent, "matlab.graphics.layout.TiledChartLayout") && D.ax.Parent.Parent == f2)
% uipanel (uifigure の中)
up = uipanel(uf);
D = net.plot_diagram(Parent=up);
assert(isa(D.ax.Parent, "matlab.graphics.layout.TiledChartLayout") && D.ax.Parent.Parent == up)
G = GraphSpring2D(sct, Parent=uipanel(uf));
assert(~isempty(G.ax.Children))
% uitab
ut = uitab(uitabgroup(uf));
G3 = GraphSpring3D(sct, Parent=ut);
assert(G3.ax.Parent.Parent == ut)
% uigridlayout: 次の空いたセルの枠のない uipanel に入る (GridLayout は tiledlayout を持てない)
ug = uigridlayout(uf, [1, 2]);
uilabel(ug, "Text", "left");
lastwarn("");
D = net.plot_diagram(Parent=ug);
h_panel = D.ax.Parent.Parent;
assert(isequal(lastwarn(), ''), "警告なし")
assert(isa(h_panel, "matlab.ui.container.Panel") && h_panel.Parent == ug && h_panel.Layout.Column == 2, "次の空いたセル")
% axes と uiaxes にはそのまま描く
ax = axes(f2);
G = GraphSpring2D(sct, Parent=ax);
assert(G.ax == ax)
ua = uiaxes(uf);
D = net.plot_diagram(Parent=ua);
assert(D.ax == ua)
% 描き直しで tiledlayout や axes が増えない
D = net.plot_diagram(Parent=up);
n_tl = numel(findall(up, "Type", "tiledlayout"));
n_ax = numel(findall(up, "Type", "axes"));
D2 = net.plot_diagram(Graph=D);
DebugScript.helper.quiet(@() net.plot_diagram(Graph=D2, State="topology"));
assert(numel(findall(up, "Type", "tiledlayout")) == n_tl && numel(findall(up, "Type", "axes")) == n_ax)
% 容器でも axes でもないものは止まる
assert(error_id(@() net.plot_diagram(Parent=5)) == "GUILDA:GraphBase:ParentType")
assert(error_id(@() GraphSpring2D(sct, Parent=uilabel(uf))) == "GUILDA:GraphBase:ParentType")
% 複数のパネルの図 (テスト用の 2 パネルの図): 容器には 2 つの axes、axes は止まる
s_y = struct("rv_t", 0:0.5:2, "rm_y", [0:0.5:2; (0:0.5:2).^2]);
P = DebugScript.helper.GraphPanelStub(s_y, Parent=uipanel(uf));
assert(numel(P.ax) == 2 && P.ax(1).Parent == P.ax(2).Parent)
assert(error_id(@() DebugScript.helper.GraphPanelStub(s_y, Parent=uiaxes(uf))) == "GUILDA:GraphBase:ParentNeedsContainer")
assert(error_id(@() DebugScript.helper.GraphPanelStub(s_y, Parent=axes(f2))) == "GUILDA:GraphBase:ParentNeedsContainer")
% 2 パネルの図でも共通のメソッドが働く
P.set_time(1.2);
assert(P.i_time == 3 && P.sct_plt.Cursor(2).Value == 1)
P.set_style("y2", Color="r");
assert(isequal(P.sct_plt.Line(2).Color, [1 0 0]))
P.select("y1");
assert(P.sct_plt.Line(1).LineWidth == 3)
P.ElementClickedFcn = @(g, d) set(uf, "UserData", d.Tag);
click(P.sct_plt.Line(2));
assert(uf.UserData == "y2")
P.reset_style();
assert(isequal(P.sct_plt.Line(2).Color, [0 0.5 0]))
D = net.plot_diagram(Parent=uipanel(uf));
P.link(D);
P.set_time(0);
assert(D.i_time == 1)


%% The title is inside an exported image
% 題があるときとないときの書き出しが違えば、題は画像の中にある (以前は図の外に出て同じ画像だった)
s_png = string(tempname) + ".png";
c_png = onCleanup(@() delete(s_png));
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
f2 = figure("Visible", "off", "Position", [100 100 640 480]);
c_f2 = onCleanup(@() close(f2));
up = uipanel(uf, "Position", [1 1 500 400]);
c_case = {f2, "none"; f2, "V"; up, "none"; up, "V"};
for i_case = 1:size(c_case, 1)
    h_parent = c_case{i_case, 1};
    D = net.plot_diagram(Parent=h_parent, BusHeightMode=c_case{i_case, 2});
    exportgraphics(h_parent, s_png);
    A = imread(s_png);
    title(D.ax, "Exported title", "FontSize", 16);
    exportgraphics(h_parent, s_png);
    B = imread(s_png);
    assert(~isequal(A, B), "題が書き出した画像に入る (case %d)", i_case)
    if isequal(size(A), size(B))
        [rv_r, ~] = find(any(A ~= B, 3));
        assert(max(rv_r) < 0.2 * size(A, 1), "変わるのは上の題の部分だけ (case %d)", i_case)
    end
    delete(allchild(h_parent));
end


%% A capture of the diagram has no axis-wide lines
% 直方体の辺を描くと、getframe / exportgraphics の画像に要素の角から軸の端までの細い線が出る
% (MATLAB の描画の不具合)。直方体は辺を描かず、画像に軸を横切る暗い行・列がない
fig_c = figure("Visible", "off", "Position", [100 100 640 480]);
c_figc = onCleanup(@() close(fig_c));
D = net.plot_diagram(Parent=fig_c, Dimension="3D");
drawnow
fr = getframe(fig_c);
rv_pos = getpixelposition(D.ax, true) .* size(fr.cdata, [2 1 2 1]) ./ fig_c.Position([3 4 3 4]);
iv_c = max(1, ceil(rv_pos(1))):min(size(fr.cdata, 2), floor(rv_pos(1) + rv_pos(3)));
iv_r = max(1, ceil(size(fr.cdata, 1) - rv_pos(2) - rv_pos(4))):min(size(fr.cdata, 1), floor(size(fr.cdata, 1) - rv_pos(2)));
lm_dark = double(rgb2gray(fr.cdata(iv_r, iv_c, :))) < 80;     % 軸の中だけ (色棒を除く)
assert(~any(mean(lm_dark, 2) > 0.5) && ~any(mean(lm_dark, 1) > 0.5), "画像に軸を横切る線がない")
hv_box = findall(D.ax, "Type", "patch", "-function", @(h) size(h.Faces, 2) == 4);
assert(~isempty(hv_box), "母線の直方体がある")
assert(all(arrayfun(@(h) isequal(h.EdgeColor, 'none'), hv_box)), "直方体は辺を描かない")


function click(h)
% グラフィックスの ButtonDownFcn をプログラムから呼ぶ
    f = h.ButtonDownFcn;
    f(h, []);
end

function c = style_values(G, sv_prop)
% 見た目のプロパティの値
    c = arrayfun(@(s) G.(s), sv_prop, "UniformOutput", false);
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
