% F49 潮流の軽い 2D 地図 (GraphNetMap): ResultPF.plot_network の戻り値
%
%   G = res.plot_network(Parent=, Color="V"|"angle", Arrow="P"|"Q"|"none");   % GraphNetMap
%   G = GraphNetMap(sct_data, Parent=, ...);    % sct_data: sv_bus, rm_xy, cv_V, sv_branch, im_end, rm_P, rm_Q, s_color, s_arrow
%   G.tab_element                                % 母線 (bus) とブランチ (branch)
%   G.set_style(sr_tag, Color=, Label=, Marker=, MarkerSize=, LineWidth=, LineStyle=);
%   G.BusColor / BusLabel / BusMarkerSize / BusMarker / BranchColor / BranchLineWidth / BranchLineStyle
%   G.set_position(sr_tag, rm_xy);  G.reset_style(sr_tag);  G.ColorbarLabel
%
% 図は GraphPlot 1 つ (G.sct_plt.Graph)。見た目の変更は GraphPlot のプロパティだけを変え、
% 描き直さない (同じハンドルのまま) ことを確かめる。クリックは GraphPlot の ButtonDownFcn に
% 点 (IntersectionPoint) を渡して当たり判定を確かめる。図はすべて見えない figure / uifigure に描く。
%
% 実行: runtests("DebugScript.test_F49_graph_netmap")  または  DebugScript.run_all("Features","F49")

fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% 合成の 3 母線のデータ: B1→B2 (P 1.0)、B3→B2 (P 0.5、to 端から入る)、B1-B3 (P 0)
sct = struct();
sct.sv_bus    = ["B1"; "B2"; "B3"];
sct.rm_xy     = [0 0; 2 0; 1 2];
sct.cv_V      = [1.05; 0.98*exp(-0.1j); 1.01*exp(0.05j)];
sct.sv_branch = ["L12"; "L23"; "L13"];
sct.im_end    = [1 2; 2 3; 1 3];
sct.rm_P      = [1.0 -0.98; -0.49 0.5; 0 0];
sct.rm_Q      = [0.2 -0.1; 0.1 -0.2; 0.3 -0.3];
sct.s_color   = "V";
sct.s_arrow   = "P";


%% tab_element lists the buses and then the branches
G = GraphNetMap(sct, Parent=axes(fig));
tab = G.tab_element;
assert(isequal(tab.Tag, ["B1"; "B2"; "B3"; "L12"; "L23"; "L13"]))
assert(isequal(tab.Kind, ["bus"; "bus"; "bus"; "branch"; "branch"; "branch"]) && isequal(tab.Index, [1; 2; 3; 1; 2; 3]))
h = G.sct_plt.Graph;
assert(isa(h, "matlab.graphics.chart.primitive.GraphPlot") && isequal(h.XData, [0 2 1]) && isequal(h.YData, [0 0 2]))
% 矢印は電力が入る端から: L23 は to 端 (B3) から B2 へ
[~, iv_e] = ismember(string(h.UserData), sct.sv_branch);
assert(isequal(G.sct_plt.EdgeBranch(:), iv_e(:)))
assert(h.ShowArrows && isequal(string(h.NodeLabel(:)), sct.sv_bus))
% 線幅は |P| の最小〜最大を BranchWidthRange (既定 [1 4] pt) に写す: P = 0 の L13 は 1
rv_w = [4; 2.5; 1];
assert(max(abs(h.LineWidth(:) - rv_w(iv_e))) < 1e-12)
G.BranchWidthRange = [2 8];
assert(max(abs(h.LineWidth(:) - 2*rv_w(iv_e))) < 1e-12, "範囲を変えると幅が変わる")
assert(error_id(@() set_prop(G, "BranchWidthRange", [3 1])) == "GUILDA:GraphNetMap:RangeValue")
G.BranchWidthRange = [1 4];
assert(isequal(G.rv_t, 0))
G.set_time(3);                          % 1 標本: 何も変わらない
assert(G.i_time == 1)
assert(error_id(@() G.animate()) == "GUILDA:GraphBase:OneSample")
% データの誤り
s2 = rmfield(sct, "rm_Q");
assert(error_id(@() GraphNetMap(s2, Parent=axes(fig))) == "GUILDA:GraphNetMap:MissingField")
s2 = sct; s2.cv_V = [1; 1];
assert(error_id(@() GraphNetMap(s2, Parent=axes(fig))) == "GUILDA:GraphNetMap:DataSize")
s2 = sct; s2.s_arrow = "S";
assert(error_id(@() GraphNetMap(s2, Parent=axes(fig))) == "GUILDA:GraphNetMap:DataValue")


%% set_style by tag and by vector give the same graph plot without a redraw
G1 = GraphNetMap(sct, Parent=axes(fig));
G2 = GraphNetMap(sct, Parent=axes(fig));
h1 = G1.sct_plt.Graph;
G1.set_style(["B2", "L23"], Color="r");
G1.set_style("B3", Label="load", Marker="s", MarkerSize=12);
G1.set_style(["L12", "L13"], LineWidth=[2 3], LineStyle=":");
G2.BusColor(2, :) = [1 0 0];
G2.BranchColor(2, :) = [1 0 0];
G2.BusLabel(3) = "load";
G2.BusMarker(3) = "s";
G2.BusMarkerSize(3) = 12;
G2.BranchLineWidth([1 3]) = [2 3];
G2.BranchLineStyle([1 3]) = ":";
sv_p = ["BusColor", "BusLabel", "BusMarker", "BusMarkerSize", "BranchColor", "BranchLineWidth", "BranchLineStyle"];
assert(isequaln(style_values(G1, sv_p), style_values(G2, sv_p)))
h2 = G2.sct_plt.Graph;
for s_p = ["NodeColor", "NodeLabel", "Marker", "MarkerSize", "EdgeColor", "LineWidth", "LineStyle"]
    assert(isequal(h1.(s_p), h2.(s_p)), "GraphPlot の " + s_p)
end
assert(isgraphics(h1) && G1.sct_plt.Graph == h1, "描き直さない (同じ GraphPlot)")
assert(isequal(h1.NodeColor(2, :), [1 0 0]) && isequal(h1.Marker{3}, 'square') && h1.MarkerSize(3) == 12 && h1.NodeLabel{3} == "load")
i_e = find(G1.sct_plt.EdgeBranch == 2);
assert(isequal(h1.EdgeColor(i_e, :), [1 0 0]))
i_e = find(G1.sct_plt.EdgeBranch == 1);
assert(h1.LineWidth(i_e) == 2 && isequal(h1.LineStyle{i_e}, ':'))
% 使えないオプション
assert(error_id(@() G1.set_style("B1", LineStyle="--")) == "GUILDA:GraphBase:StyleNotApplicable")
assert(error_id(@() G1.set_style("L12", Marker="s")) == "GUILDA:GraphBase:StyleNotApplicable")
assert(error_id(@() G1.set_style("X9", Color="r")) == "GUILDA:GraphBase:UnknownTag")


%% NaN rows give the color of the data and the flow width, and reset_style returns them
G = GraphNetMap(sct, Parent=axes(fig));
h = G.sct_plt.Graph;
assert(all(isnan(G.BusColor(:))) && all(isnan(G.BranchLineWidth)) && all(isnan(G.BranchColor(:))))
assert(isequal(h.NodeColor, 'flat') && max(abs(h.NodeCData(:) - abs(sct.cv_V))) < 1e-12)
assert(isequal(G.BusLabel, sct.sv_bus) && all(G.BusMarkerSize == 6) && all(G.BusMarker == "o") && all(G.BranchLineStyle == "-"))
rv_w0 = h.LineWidth;
rm_e0 = h.EdgeColor;
G.set_style("B1", Color="g");
% NaN の行は色の値の色: B3 の色はカラーマップの色
cm = colormap(G.ax); rv_lim = clim(G.ax);
i_c = min(max(fix((abs(sct.cv_V(3)) - rv_lim(1)) / diff(rv_lim) * size(cm, 1)) + 1, 1), size(cm, 1));
assert(isequal(h.NodeColor(1, :), [0 1 0]) && isequal(h.NodeColor(3, :), cm(i_c, :)))
G.set_style("L12", LineWidth=9, Color="k");
G.reset_style("B1");
assert(isequal(h.NodeColor, 'flat') && all(isnan(G.BusColor(:))))
assert(G.BranchLineWidth(1) == 9, "B1 だけを戻す")
G.reset_style();
assert(all(isnan(G.BranchLineWidth)) && isequal(h.LineWidth, rv_w0) && isequal(h.EdgeColor, rm_e0))
% 色の棒のラベル: "" はデータの量、設定すると文字だけを変える
assert(G.sct_plt.Colorbar.Label.String == "|V| [pu]")
G.ColorbarLabel = "voltage";
assert(G.sct_plt.Colorbar.Label.String == "voltage" && G.sct_plt.Graph == h)
s2 = sct; s2.s_color = "angle"; s2.s_arrow = "none";
G = GraphNetMap(s2, Parent=axes(fig));
h = G.sct_plt.Graph;
assert(~h.ShowArrows && all(h.LineWidth == 2.5) && G.sct_plt.Colorbar.Label.String == "\angleV [deg]", "矢印なしは範囲の中央")
assert(max(abs(h.NodeCData(:) - rad2deg(angle(sct.cv_V)))) < 1e-12)


%% set_position moves buses in the drawing only, not in the model
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
G = res.plot_network(Parent=axes(fig));
h = G.sct_plt.Graph;
rv_x0 = h.XData;
x_net = net.a_Bus{1}.tab_parameter.graph.X;
x_snp = res.sct_network.a_Bus{1}.tab_parameter.graph.X;
G.set_position(["B001", "B002"], [10 20; 30 40]);
assert(G.sct_plt.Graph == h && isequal([h.XData(1:2); h.YData(1:2)], [10 30; 20 40]) && isequal(h.XData(3:end), rv_x0(3:end)))
assert(isequaln(net.a_Bus{1}.tab_parameter.graph.X, x_net) && isequaln(res.sct_network.a_Bus{1}.tab_parameter.graph.X, x_snp))
assert(error_id(@() G.set_position("B001", [1 2; 3 4])) == "GUILDA:GraphNetMap:PositionSize")
assert(error_id(@() G.set_position(G.tab_element.Tag(end), [1 2])) == "GUILDA:GraphNetMap:PositionKind")
assert(error_id(@() G.set_position("X9", [1 2])) == "GUILDA:GraphBase:UnknownTag")
% get_layout は描いた位置 (Tag, X, Y)。net.set_layout で位置だけを書ける
L = G.get_layout();
assert(isequal(string(fieldnames(L))', "tab_bus") && isequal(string(L.tab_bus.Properties.VariableNames), ["Tag", "X", "Y"]))
assert(isequal(L.tab_bus.Tag, string(res.tab_bus.Properties.RowNames)))
assert(isequal(L.tab_bus{:, ["X","Y"]}, [h.XData(:), h.YData(:)]))
L_model = net.get_layout();
net.set_layout(L);
L_new = net.get_layout();
assert(isequal(L_new.tab_bus{:, ["X","Y"]}, L.tab_bus{:, ["X","Y"]}))
assert(isequaln(removevars(L_new.tab_bus, ["X","Y"]), removevars(L_model.tab_bus, ["X","Y"])) && isequaln(L_new.tab_component, L_model.tab_component))
% set_data: 座標のない母線は描いた位置を引き継ぎ、見た目と選択はタグで残る
G = GraphNetMap(sct, Parent=axes(fig));
G.set_position("B1", [-1 -1]);
G.set_style("L23", Color="r");
G.select("B2");
s2 = sct; s2.rm_xy(1, :) = NaN; s2.cv_V = [1.00; 0.97; 1.02];
G.set_data(s2);
h = G.sct_plt.Graph;
assert(isequal(h.XData, [-1 2 1]) && isequal(G.BranchColor(2, :), [1 0 0]) && G.Selection == "B2")
assert(max(abs(h.NodeCData(:) - abs(s2.cv_V))) < 1e-12)


%% Parent is a container, an axes or a uiaxes
G = GraphNetMap(sct, Parent=fig);
assert(isa(G.ax.Parent, "matlab.graphics.layout.TiledChartLayout"))
clf(fig);
uf = uifigure("Visible", "off");
c_uf = onCleanup(@() delete(uf));
ua = uiaxes(uf);
G = GraphNetMap(sct, Parent=ua);
assert(G.ax == ua && isgraphics(G.sct_plt.Graph))
G.set_style("B1", Color="r");
G.select(["B1", "L12"]);
assert(numel(G.sct_plt.Selection) == 2)
G = GraphNetMap(sct, Parent=uipanel(uf));
assert(isscalar(G.ax) && isgraphics(G.sct_plt.Graph))
assert(error_id(@() GraphNetMap(sct, Parent=uilabel(uf))) == "GUILDA:GraphBase:ParentType")
% plot_network も同じ規則
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
G = res.plot_network(Parent=uiaxes(uf), Color="angle", Arrow="Q");
assert(isa(G, "GraphNetMap") && isa(G, "GraphBase") && height(G.tab_element) == numel(net.a_Bus) + numel(net.a_Branch))


%% A click is matched to the nearest bus, else to the nearest branch
G = GraphNetMap(sct, Parent=axes(fig));
h = G.sct_plt.Graph;
fig.UserData = strings(0, 1);
G.ElementClickedFcn = @(g, d) set(fig, "UserData", [fig.UserData; d.Kind + ":" + d.Tag + ":" + d.Index]);
lh = addlistener(G, "ElementClicked", @(g, d) setappdata(fig, "last_event", d));
click_at(h, [2 0]);                     % B2 の上
click_at(h, [1.02 0.01]);               % L12 の中点の近く
click_at(h, [1.5 1]);                   % L23 の中点
click_at(h, [0.5 1]);                   % L13 の中点
click_at(h, [1 0.9]);                   % 何もないところ
assert(isequal(fig.UserData, ["bus:B2:2"; "branch:L12:1"; "branch:L23:2"; "branch:L13:3"]))
d = getappdata(fig, "last_event");
assert(isa(d, "GraphEventData") && d.Tag == "L13" && d.Kind == "branch")
delete(lh);
% 選択: 輪と太い線、クリックを取らない
G.select(["B1", "L23"]);
hv = G.sct_plt.Selection;
assert(numel(hv) == 2 && all(string({hv.PickableParts}) == "none"))
assert(isequal(hv(2).XData, [2 1]) && isequal(hv(2).YData, [0 2]))
G.set_position("B3", [3 3]);
assert(isequal(G.sct_plt.Selection(2).XData, [2 3]), "選択は位置に従う")
G.clear_selection();
assert(isempty(G.sct_plt.Selection) && isgraphics(h))


%% plot_network returns a GraphNetMap with the drawing of the power flow
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
G = res.plot_network(Parent=axes(fig));
tab = res.tab_branch;
h = G.sct_plt.Graph;
assert(isa(G, "GraphNetMap") && isequal(G.tab_element.Tag, [string(res.tab_bus.Properties.RowNames); string(tab.Properties.RowNames)]))
rv_P = max(abs([tab.Pfrom, tab.Pto]), [], 2);
[~, iv_e] = ismember(h.UserData, string(tab.Properties.RowNames));
assert(max(abs(h.LineWidth(:) - (1 + 3*(rv_P(iv_e) - min(rv_P))/(max(rv_P) - min(rv_P))))) < 1e-12)
G.set_style(string(tab.Properties.RowNames(1)), LineWidth=7);
assert(h.LineWidth(G.sct_plt.EdgeBranch == 1) == 7)


function click_at(h, rv_xy)
% GraphPlot の ButtonDownFcn を、その点のクリックとして呼ぶ
    f = h.ButtonDownFcn;
    f(h, struct("IntersectionPoint", [rv_xy 0]));
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
