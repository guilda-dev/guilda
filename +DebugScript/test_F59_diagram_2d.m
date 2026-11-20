% F59 ネットワーク図の 2D と範囲の正規化 (GraphNetDiagram の Dimension、*Range、*Mode)
%
%   G = net.plot_diagram(Dimension="2D" | "3D");          % 既定は 2D (線と記号)
%   G.BranchWidthMode = "P" | "Q" | "I" | "G" | "B" | "Y" | "Ysvd" | "none";   % 既定 "Ysvd"
%   G.BranchWidthRange = [a b];  G.MarkerSizeRange = [a b];  G.LinkWidth = w;    % 単位は pt
%   G.MarkerSizeMode = "none" | "P" | "Q" | "S";
%
% 量の最小〜最大を範囲に線形に写す。尺度は状態の全標本で 1 つ (notes/graph-diagram-2d.md §4)。
% 2D でも母線の高さ (BusHeightMode) を使い、記号はその z に置く (§2、Q9)。
% 図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F59_diagram_2d")  または  DebugScript.run_all("Features","F59")

fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
net14 = network.IEEE14bus();
DebugScript.helper.quiet(@() net14.initialize);


%% range_map maps the scale onto the range
f = @(v, r, l) DebugScript.helper.GraphPanelStub.call_range_map(v, r, l);
assert(isequal(f([0; 5; 10; NaN], [1 4], [0 10]), [1; 2.5; 4; 1]), "線形、NaN は a")
assert(isequal(f([3; 3], [1 4], [3 3]), [2.5; 2.5]), "全部同じ値は (a+b)/2")
assert(isequal(f([3; NaN], [1 4], [3 3]), [2.5; 1]), "全部同じでも NaN は a")
assert(isequal(f([NaN; NaN], [1 4], [NaN NaN]), [2.5; 2.5]), "尺度がなければ全部 (a+b)/2")
assert(isequal(f([0; 2; 4], [1 4], [0 4]), [1; 2.5; 4]), "0 はただの値")
assert(isequal(f([0; 2; 4], [3 3], [0 4]), [3; 3; 3]), "a = b なら全部その値")
assert(isequal(f([-1; 5], [1 4], [0 4]), [1; 4]), "尺度の外は範囲に収める")
assert(isempty(f(zeros(0, 1), [1 4], [NaN NaN])))


%% 2D draws one line per element and no solid
D = net14.plot_diagram(Parent=axes(fig));
assert(D.Dimension == "2D", "既定は 2D")
tab = D.tab_element;
n_b = sum(tab.Kind == "bus"); n_c = sum(tab.Kind == "component"); n_e = sum(tab.Kind == "branch");
n_tr = sum(arrayfun(@(b) b{1}.tab_parameter.graph.Style == "transformer", net14.a_Branch));
assert(n_tr > 0, "前提: 変圧器がある")
hv_line = findobj(D.ax, "Type", "line");
assert(numel(hv_line) == n_b + 2*n_c + n_e + n_tr, "母線・機器・ブランチ・リンクに 1 本ずつ、変圧器の記号に 1 本")
hv_patch = findall(D.ax, "Type", "patch");
assert(isempty(findall(D.ax, "Type", "surface")) && all(ismember(string({hv_patch.Tag}), ["FlowBranch", "FlowLink"])), "立体がない (patch は流れの点だけ)")
assert(isempty(findall(D.ax, "Type", "light")), "照明がない")
assert(D.ax.Projection == "orthographic" && D.ax.SortMethod == "childorder")
[r_az, r_el] = view(D.ax);
assert(r_az == 0 && r_el == 90, "真上から見る")
% 棒の母線は中心 (X, Y)、長さ Length の線分 (B001: 中心 (0.25, 0.56)、長さ 0.1)
h = D.sct_plt.NodeMain(1);
assert(max(abs(h.XData - [0.2 0.3])) < 1e-12 && all(abs(h.YData - 0.56) < 1e-12))
assert(h.LineWidth == 3.75, "既定の棒は 7.5 pt の半分")
% 変圧器の記号は From 端の近く、ほかのブランチにはない
iv_tr = find(arrayfun(@(b) b{1}.tab_parameter.graph.Style == "transformer", net14.a_Branch));
for k = iv_tr(:)'
    hs = D.sct_plt.EdgeSymbol(k);
    p  = D.sct_plt.EdgePath{k};
    rv_c = [mean(hs.XData(1:48)), mean(hs.YData(1:48))];
    assert(norm(rv_c - p(1, 1:2)) < norm(rv_c - p(end, 1:2)), "記号は From 端の近く")
end
assert(~any(isgraphics(D.sct_plt.EdgeSymbol(setdiff(1:n_e, iv_tr)))))
% 機器は母線の中心 + (DX, DY) のマーカー、リンクはその経路
i_c = 1;
assert(isequal([D.sct_plt.CompMain(i_c).XData, D.sct_plt.CompMain(i_c).YData], D.sct_plt.CompPath{i_c}(1, 1:2)))
assert(D.sct_plt.CompMain(i_c).MarkerSize == 7.5 && D.sct_plt.CompEdge(i_c).LineWidth == 1, "既定の大きさ 7.5 pt、リンク 1 pt")
% 3D は立体
D3 = net14.plot_diagram(Parent=axes(fig), Dimension="3D");
assert(~isempty(findall(D3.ax, "Type", "surface")) && ~isempty(findall(D3.ax, "Type", "light")))
assert(D3.ax.Projection == "perspective")


%% 2D symbols sit at the bus heights
D = net14.plot_diagram(Parent=axes(fig), BusHeightMode="V");
rv_v = abs(D.sct_state.cm_Vbus(:, 1));
for i = 1:numel(rv_v)
    assert(all(abs(D.sct_plt.NodeMain(i).ZData - rv_v(i)) < 1e-12), "母線の z は |V|")
end
sct_net = struct(net14, false);
im_edge = edge_buses(sct_net);
for k = 1:size(im_edge, 2)
    z = D.sct_plt.EdgeMain(k).ZData;
    assert(abs(z(1) - rv_v(im_edge(1, k))) < 1e-12 && abs(z(end) - rv_v(im_edge(2, k))) < 1e-12, "ブランチの端は両端の母線の高さ")
    p = [D.sct_plt.EdgeMain(k).XData(:), D.sct_plt.EdgeMain(k).YData(:)];
    rv_s = [0; cumsum(vecnorm(diff(p), 2, 2))];
    rv_exp = z(1) + rv_s/rv_s(end)*(z(end) - z(1));
    assert(max(abs(z(:) - rv_exp)) < 1e-12, "折れ点の z は弧長の線形補間")
end
assert(any(cellfun(@(p) size(p, 1) > 2, D.sct_plt.EdgePath)), "前提: 折れ点のあるブランチ")
iv_bus = D.sct_plt.CompParentBus;
for c = 1:numel(iv_bus)
    assert(abs(D.sct_plt.CompMain(c).ZData - rv_v(iv_bus(c))) < 1e-12 && all(abs(D.sct_plt.CompEdge(c).ZData - rv_v(iv_bus(c))) < 1e-12), ...
        "機器とリンクは母線の高さ")
end
% set_time は作り直さずに ZData だけ変える
sct = D.sct_state;
sct.rv_t = [0, 1];
sct.cm_Vbus = sct.cm_Vbus .* [1, 0.9];
sct.cm_Icomp = sct.cm_Icomp .* [1, 1];
D2 = GraphNetDiagram(sct_net, sct, Parent=axes(fig), BusHeightMode="V");
h_node = D2.sct_plt.NodeMain;
h_edge = D2.sct_plt.EdgeMain;
D2.set_time(1);
assert(isequal(D2.sct_plt.NodeMain, h_node) && isequal(D2.sct_plt.EdgeMain, h_edge), "2D の set_time は作り直さない")
assert(all(abs(D2.sct_plt.NodeMain(1).ZData - 0.9*rv_v(1)) < 1e-12))
assert(abs(D2.sct_plt.EdgeMain(1).ZData(1) - 0.9*rv_v(im_edge(1, 1))) < 1e-12)
% 視点は描き直しで残る
view(D2.ax, 30, 40);
D2.BusHeightMode = "angle";
[r_az, r_el] = view(D2.ax);
assert(abs(r_az - 30) < 1e-9 && abs(r_el - 40) < 1e-9, "BusHeightMode の後も視点が残る")
D2.Dimension = "3D";
[r_az, r_el] = view(D2.ax);
assert(abs(r_az - 30) < 1e-9 && abs(r_el - 40) < 1e-9, "Dimension の後も視点が残る")
D2.BusHeightMode = "none";
D2.Dimension = "2D";
[r_az, r_el] = view(D2.ax);
assert(abs(r_az - 30) < 1e-9 && abs(r_el - 40) < 1e-9)
assert(all(cellfun(@(z) all(z == 0), {D2.sct_plt.NodeMain.ZData})), "none は平ら")


%% Widths and sizes follow the ranges
D = net14.plot_diagram(Parent=axes(fig));
sct_net = struct(net14, false);
assert(D.BranchWidthMode == "Ysvd" && isequal(D.BranchWidthRange, [1 4]) && isequal(D.MarkerSizeRange, [5 10]))
D.BranchWidthMode = "P";
rv_w = [D.sct_plt.EdgeMain.LineWidth];
assert(abs(min(rv_w) - 1) < 1e-12 && abs(max(rv_w) - 4) < 1e-12, "最小と最大の流れが範囲の端")
q = branch_flow(sct_net, D.sct_state.cm_Vbus, "P");
r_hi = nearest_rank(q, 0.95);   % 幅の尺度は最小〜95 パーセンタイル (上位 5% は b に張り付く)
assert(max(abs(rv_w(:) - (1 + 3*min((q - min(q))/(r_hi - min(q)), 1)))) < 1e-9, "|P_from - P_to|/2 の線形の写し")
D.BranchWidthRange = [2 6];
rv_w = [D.sct_plt.EdgeMain.LineWidth];
assert(abs(min(rv_w) - 2) < 1e-12 && abs(max(rv_w) - 6) < 1e-12)
D.BranchWidthRange = [3 3];
assert(all([D.sct_plt.EdgeMain.LineWidth] == 3), "a = b で全部同じ幅")
D.BranchWidthRange = [1 4];
D.BranchWidthMode = "none";
assert(all([D.sct_plt.EdgeMain.LineWidth] == 2.5), "none は範囲の中央")
for s_mode = ["Q", "I", "G", "B", "Y", "Ysvd"]
    D.BranchWidthMode = s_mode;
    rv_w = [D.sct_plt.EdgeMain.LineWidth];
    assert(abs(min(rv_w) - 1) < 1e-12 && abs(max(rv_w) - 4) < 1e-12, s_mode)
end
% 要素ごとの幅 (pt) は範囲より優先し、NaN で範囲に戻る
D.BranchWidthMode = "P";
r_w2 = D.sct_plt.EdgeMain(2).LineWidth;
D.BranchLineWidth(2) = 7;
assert(D.sct_plt.EdgeMain(2).LineWidth == 7, "範囲で写さない")
D.BranchWidthRange = [1 2];
assert(D.sct_plt.EdgeMain(2).LineWidth == 7, "範囲を変えても残る")
D.BranchWidthRange = [1 4];
D.BranchLineWidth(2) = NaN;
assert(abs(D.sct_plt.EdgeMain(2).LineWidth - r_w2) < 1e-12)
% 節点: none は 7.5 pt (棒は 3.75 pt)、モードで写す、母線と機器は別の尺度
assert(all([D.sct_plt.CompMain.MarkerSize] == 7.5))
for s_mode = ["P", "Q", "S"]
    D.MarkerSizeMode = s_mode;
    rv_s = [D.sct_plt.CompMain.MarkerSize];
    assert(abs(min(rv_s) - 5) < 1e-12 && abs(max(rv_s) - 10) < 1e-12, "機器: " + s_mode)
    rv_b = D.sct_plt.BusSize0;
    assert(abs(min(rv_b) - 5) < 1e-12 && abs(max(rv_b) - 10) < 1e-12, "母線: " + s_mode)
end
D.MarkerSizeMode = "P";
cv_S = D.sct_state.cm_Vbus(D.sct_plt.CompParentBus) .* conj(D.sct_state.cm_Icomp);
rv_p = abs(real(cv_S));
assert(max(abs([D.sct_plt.CompMain.MarkerSize]' - (5 + 5*(rv_p - min(rv_p))/(max(rv_p) - min(rv_p))))) < 1e-9)
lv_bar = D.sct_plt.NodeBar;
assert(max(abs([D.sct_plt.NodeMain(lv_bar).LineWidth]' - D.sct_plt.BusSize0(lv_bar)/2)) < 1e-12, "棒は大きさの半分の幅")
D.ComponentMarkerSize(1) = 15;
assert(D.sct_plt.CompMain(1).MarkerSize == 15)
D.MarkerSizeRange = [5 5];
assert(D.sct_plt.CompMain(1).MarkerSize == 15 && all([D.sct_plt.CompMain(2:end).MarkerSize] == 5))
D.LinkWidth = 2;
assert(all([D.sct_plt.CompEdge.LineWidth] == 2))
% 範囲の検査
for rv_bad = {[4 1], [0 1], [NaN 2], [1 Inf]}
    assert(error_id(@() set_prop(D, "BranchWidthRange", rv_bad{1})) == "GUILDA:GraphNetDiagram:RangeValue")
    assert(error_id(@() set_prop(D, "MarkerSizeRange", rv_bad{1})) == "GUILDA:GraphNetDiagram:RangeValue")
end
% 構成だけの図は流れの量が NaN なので全部範囲の中央
D = net14.plot_diagram(Parent=axes(fig), State="topology", BranchWidthMode="P", MarkerSizeMode="S");
assert(all([D.sct_plt.EdgeMain.LineWidth] == 2.5) && all([D.sct_plt.CompMain.MarkerSize] == 7.5))


%% One scale over all samples
% 標本 2 は電圧を 0.9 倍、電流も 0.9 倍 (流れは 0.81 倍)、標本 3 は標本 1 と同じ
sct_net = struct(net14, false);
G0 = net14.plot_diagram(Parent=axes(fig));
sct = struct("rv_t", [0 1 2]);
sct.cm_Vbus  = G0.sct_state.cm_Vbus  .* [1, 0.9, 1];
sct.cm_Icomp = G0.sct_state.cm_Icomp .* [1, 0.9, 1];
G = GraphNetDiagram(sct_net, sct, Parent=axes(fig), BranchWidthMode="P");
rv_w1 = [G.sct_plt.EdgeMain.LineWidth];
q1 = branch_flow(sct_net, sct.cm_Vbus(:, 1), "P");
% 尺度は全標本の値の最小〜95 パーセンタイル (最近順位)。上の値は b に張り付く
r_min = 0.81*min(q1);
r_hi  = nearest_rank([q1; 0.81*q1; q1], 0.95);
f_w   = @(q) 1 + 3*min(max((q - r_min)/(r_hi - r_min), 0), 1);
[~, i_max] = max(q1);
assert(abs(rv_w1(i_max) - 4) < 1e-12, "全標本の最大の要素が b")
assert(max(abs(rv_w1(:) - f_w(q1))) < 1e-9, "標本 1 を全標本の尺度で写す")
G.set_time(1);
rv_w2 = [G.sct_plt.EdgeMain.LineWidth];
assert(max(abs(rv_w2(:) - f_w(0.81*q1))) < 1e-9, "全標本の尺度で写す")
assert(max(abs(rv_w2 - rv_w1)) > 0.1, "標本 2 は細くなる (標本ごとの写しではない)")
G.set_time(2);
assert(max(abs([G.sct_plt.EdgeMain.LineWidth] - rv_w1)) < 1e-12, "同じ値なら同じ幅")
% set_data は新しい状態から尺度を決める (標本 2 だけ: 1 標本は標本ごとの写しと同じ)
sct2 = struct("rv_t", 0, "cm_Vbus", sct.cm_Vbus(:, 2), "cm_Icomp", sct.cm_Icomp(:, 2));
G.set_data(sct2);
rv_w = [G.sct_plt.EdgeMain.LineWidth];
assert(abs(max(rv_w) - 4) < 1e-12 && abs(min(rv_w) - 1) < 1e-12, "前の状態の尺度を引き継がない")


%% Dimension switches the drawing and keeps the rest
D = net14.plot_diagram(Parent=axes(fig), Dimension="3D", ColorMode="P");
D.set_position("B002", [0.5, 0.1]);
D.set_style("B003", Color="r", MarkerSize=10);
D.select(["B004", D.tab_element.Tag(find(D.tab_element.Kind == "branch", 1))]);
sct_before = struct("layout", D.get_layout(), "BusColor", D.BusColor, "BusMarkerSize", D.BusMarkerSize, ...
    "Selection", D.Selection, "i_time", D.i_time, "BranchColorData", D.BranchColorData);
D.Dimension = "2D";
assert(isequal(D.get_layout(), sct_before.layout) && isequaln(D.BusColor, sct_before.BusColor) && isequaln(D.BusMarkerSize, sct_before.BusMarkerSize))
assert(isequal(D.Selection, sct_before.Selection) && D.i_time == sct_before.i_time && isequaln(D.BranchColorData, sct_before.BranchColorData))
assert(isequal(D.sct_plt.NodeMain(3).Color, [1 0 0]) && D.sct_plt.NodeMain(3).LineWidth == 5, "set_style の色と大きさが 2D に残る")
assert(numel(D.sct_plt.Selection) == 2)
D.Dimension = "3D";
assert(isequal(D.Selection, sct_before.Selection) && ~isempty(findall(D.ax, "Type", "surface")))
% 3D の管の半径は span に比例する (1 pt = span/400)
r14 = tube_radius(D, 1) / span_of(D);
net68 = network.IEEE68bus();
D68 = DebugScript.helper.quiet(@() net68.plot_diagram(Parent=axes(fig), State="topology", Dimension="3D", BranchWidthMode="P"));
r68 = tube_radius(D68, 1) / span_of(D68);
assert(abs(r68 - 0.5*2.5/400) < 1e-9, "構成だけの図: 2.5 pt の管")
assert(r14 > 0.5*1/400 - 1e-9 && r14 < 0.5*4/400 + 1e-9)


%% Ysvd widths leave out the top outliers on IEEE68
% 既定の Ysvd の尺度は最小〜95 パーセンタイル。上位のブランチは最大の幅 4 pt に張り付く
net68 = network.IEEE68bus();
D68 = DebugScript.helper.quiet(@() net68.plot_diagram(Parent=axes(fig)));
assert(D68.BranchWidthMode == "Ysvd")
sct68 = struct(net68, false);
rv_y = cellfun(@(b) max(svd(b.cm_Y)), sct68.a_Branch(:));
r_lo = min(rv_y);
r_hi = nearest_rank(rv_y, 0.95);
assert(r_hi < max(rv_y), "IEEE68 の Ysvd には 95 パーセンタイルより上の値がある")
rv_w = [D68.sct_plt.EdgeMain.LineWidth]';
lv_top = rv_y >= r_hi;
assert(all(abs(rv_w(lv_top) - 4) < 1e-9) && nnz(lv_top) >= 2, "上位のブランチは最大の幅")
assert(max(abs(rv_w - (1 + 3*min((rv_y - r_lo)/(r_hi - r_lo), 1)))) < 1e-9, "尺度の上端は 95 パーセンタイル")
assert(abs(min(rv_w) - 1) < 1e-12)
% 95 パーセンタイルが最小と等しい (値は異なる) ときは最小〜最大に戻る
sct_net14 = struct(net14, false);
for k = 1:numel(sct_net14.a_Branch)
    sct_net14.a_Branch{k}.cm_Y = sct_net14.a_Branch{1}.cm_Y;
end
sct_net14.a_Branch{end}.cm_Y = 2*sct_net14.a_Branch{1}.cm_Y;
G0 = net14.plot_diagram(Parent=axes(fig));
G14 = GraphNetDiagram(sct_net14, G0.sct_state, Parent=axes(fig));
rv_w = [G14.sct_plt.EdgeMain.LineWidth];
assert(all(abs(rv_w(1:end-1) - 1) < 1e-12) && abs(rv_w(end) - 4) < 1e-12, "最小〜最大に戻る")


%% Removed properties are errors
assert(error_id(@() net14.plot_diagram(Parent=axes(fig), BranchWidthScale=1)) ~= "")
assert(error_id(@() net14.plot_diagram(Parent=axes(fig), BranchWidthOffset=1)) ~= "")
assert(error_id(@() net14.plot_diagram(Parent=axes(fig), MarkerSize=10)) ~= "")
D = net14.plot_diagram(Parent=axes(fig));
assert(~isprop(D, "BranchWidthScale") && ~isprop(D, "BranchWidthOffset") && ~isprop(D, "MarkerSize"))
assert(error_id(@() set_prop(D, "Dimension", "4D")) ~= "")


%% The selection overlay lies under the 2D symbols
D = net14.plot_diagram(Parent=axes(fig));
tab = D.tab_element;
s_br = tab.Tag(find(tab.Kind == "branch", 1));
s_cm = tab.Tag(find(tab.Kind == "component", 1));
D.select(["B001", s_br, s_cm]);
hv = D.sct_plt.Selection;                         % 母線、機器、ブランチ、リンク (機器のタグはリンクも選ぶ)
assert(numel(hv) == 4 && all(string({hv.PickableParts}) == "none"))
assert(all(ismember(hv, D.ax.Children(end-3:end))), "重ね描きは最初に描く (下)")
h_bar = hv(1);
d0 = D.sct_plt.D0;
assert(max(abs(h_bar.XData - [0.2 - 0.1*d0, 0.3 + 0.1*d0])) < 1e-12, "棒の重ね描きは両端に 0.1 d0 長い")
assert(h_bar.LineWidth == D.sct_plt.NodeMain(1).LineWidth + 6)
h_br = hv(3);
p = D.sct_plt.EdgePath{1};
assert(isequal(h_br.XData(:), p(:, 1)) && h_br.LineWidth == D.sct_plt.EdgeMain(1).LineWidth + 5)
h_c = hv(2);
assert(h_c.Marker == "o" && h_c.MarkerSize == D.sct_plt.CompMain(1).MarkerSize + 8 && h_c.XData == D.sct_plt.CompMain(1).XData)
D.BranchWidthRange = [5 9];
assert(D.sct_plt.Selection(3).LineWidth == D.sct_plt.EdgeMain(1).LineWidth + 5, "幅を変えると重ね描きも変わる")


%% Before a power flow the diagram has no colorbar
[net0, ~] = DebugScript.helper.build_3bus("gen-classical");
D = DebugScript.helper.quiet(@() net0.plot_diagram(Parent=axes(fig)));
assert(isempty(D.ax.Colorbar), "色の値がなければ色の棒はない")
D.Dimension = "3D";
assert(isempty(D.ax.Colorbar))
DebugScript.helper.quiet(@() net0.initialize);
D = net0.plot_diagram(Graph=D);
assert(isscalar(D.ax.Colorbar) && D.ax.Colorbar.Location == "eastoutside", "値があれば軸の右に色の棒")
D.ColorMode = "none";
assert(isempty(D.ax.Colorbar))
D.ColorMode = "I";
assert(isscalar(D.ax.Colorbar))


%% Saving the figure gives no recursion warning
% コールバックは図を弱い参照で持つので、savefig は図のオブジェクトを保存しない
net68 = network.IEEE68bus();
DebugScript.helper.quiet(@() net68.initialize);
s_fig = string(tempname) + ".fig";
c_del = onCleanup(@() delete(s_fig));
for s_dim = ["2D", "3D"]
    f2 = figure("Visible", "off");
    c_f2 = onCleanup(@() close(f2));
    D = net68.plot_diagram(Parent=f2, Dimension=s_dim);
    lastwarn("");
    savefig(f2, s_fig);
    [~, s_id] = lastwarn();
    assert(s_id == "", "保存で警告: " + s_id + " (" + s_dim + ")")
    s_info = dir(s_fig);
    assert(s_info.bytes < 5e6, "図のオブジェクトを保存していない")
    clear c_f2
end


%% The title and the colorbar label of plot_lmp lie inside the figure
% 題を [1 0 1]、色の棒のラベルを [0 1 1] で描き、その画素が図の端から離れていること
net9 = network.IEEE9bus();
res = DebugScript.helper.quiet(@() net9.calculate_optimal_powerflow(Method="DC OPF"));
s_png = string(tempname) + ".png";
c_png = onCleanup(@() delete(s_png));
for c_case = {"2D", [560 420]; "2D", [400 300]; "3D", [560 420]; "3D", [400 300]}'
    f2 = figure("Visible", "off", "Position", [100 100 c_case{2}]);
    c_f2 = onCleanup(@() close(f2));
    G = res.plot_lmp(Parent=f2, Dimension=c_case{1});
    G.ax.Title.Color = [1 0 1];
    G.ax.Colorbar.Label.Color = [0 1 1];
    print(f2, s_png, "-dpng", "-r100");
    A = double(imread(s_png));
    for c_txt = {"題", A(:,:,1) > 200 & A(:,:,2) < 90 & A(:,:,3) > 200; "ラベル", A(:,:,1) < 90 & A(:,:,2) > 200 & A(:,:,3) > 200}'
        [iv_r, iv_c] = find(c_txt{2});
        s_case = c_txt{1} + " " + c_case{1} + " " + join(string(c_case{2}), "x");
        assert(numel(iv_r) > 100, s_case + " が描かれていない")
        assert(min(iv_r) > 2 && max(iv_r) < size(A, 1) - 1 && min(iv_c) > 2 && max(iv_c) < size(A, 2) - 1, s_case + " が図の端で切れる")
    end
    exportgraphics(f2, s_png);
    B = double(imread(s_png));
    assert(nnz(B(:,:,1) > 200 & B(:,:,2) < 90 & B(:,:,3) > 200) > 100 && nnz(B(:,:,1) < 90 & B(:,:,2) > 200 & B(:,:,3) > 200) > 100, ...
        "書き出した画像に題とラベルがある")
    clear c_f2
end


%% A capture of the 2D diagram has no axis-wide lines
fig_c = figure("Visible", "off", "Position", [100 100 640 480]);
c_figc = onCleanup(@() close(fig_c));
D = net14.plot_diagram(Parent=fig_c);
drawnow
fr = getframe(fig_c);
rv_pos = getpixelposition(D.ax, true) .* size(fr.cdata, [2 1 2 1]) ./ fig_c.Position([3 4 3 4]);
iv_c = max(1, ceil(rv_pos(1))):min(size(fr.cdata, 2), floor(rv_pos(1) + rv_pos(3)));
iv_r = max(1, ceil(size(fr.cdata, 1) - rv_pos(2) - rv_pos(4))):min(size(fr.cdata, 1), floor(size(fr.cdata, 1) - rv_pos(2)));
lm_dark = double(rgb2gray(fr.cdata(iv_r, iv_c, :))) < 80;
assert(~any(mean(lm_dark, 2) > 0.5) && ~any(mean(lm_dark, 1) > 0.5), "画像に軸を横切る線がない")
assert(nnz(lm_dark) > 100, "図が描かれている")


%% 2D is fast enough on IEEE68
% 目標 (§2.6) の 5 倍を上限にする: 作成と Dimension の切り替え 2.5 s、ベクトルと set_time 0.5 s
net68 = network.IEEE68bus();
DebugScript.helper.quiet(@() net68.initialize);
f2 = figure("Visible", "off");
c_f2 = onCleanup(@() close(f2));
D = net68.plot_diagram(Parent=axes(f2));          % 初回 (JIT)
rv_t = zeros(1, 3);
for r = 1:3
    tic; D = net68.plot_diagram(Parent=axes(f2)); rv_t(r) = toc;
end
assert(median(rv_t) < 2.5, sprintf("作成 %.2f s", median(rv_t)))
tic; D.Dimension = "3D"; D.Dimension = "2D"; r_t = toc;
assert(r_t < 2*2.5 + 5, sprintf("切り替え %.2f s", r_t))
tic; D.Dimension = "2D"; r_t = toc;            %#ok<NASGU> 同じ値でも描き直す
n_b = numel(D.BusMarkerSize); n_c = numel(D.ComponentMarkerSize); n_e = numel(D.BranchLineWidth);
rv_t = zeros(1, 3);
for r = 1:3
    tic
    D.BusColor = rand(n_b, 3); D.ComponentColor = rand(n_c, 3); D.BranchColor = rand(n_e, 3);
    D.BusMarkerSize = 4 + 4*rand(n_b, 1); D.ComponentMarkerSize = 4 + 4*rand(n_c, 1); D.BranchLineWidth = 1 + 3*rand(n_e, 1);
    rv_t(r) = toc;
end
assert(median(rv_t) < 0.5, sprintf("6 つのベクトル %.3f s", median(rv_t)))
sct = D.sct_state;
sct.rv_t = [0 1];
sct.cm_Vbus = sct.cm_Vbus .* [1 0.95];
sct.cm_Icomp = sct.cm_Icomp .* [1 1];
D = GraphNetDiagram(struct(net68, false), sct, Parent=axes(f2), BusHeightMode="V");
rv_t = zeros(1, 4);
for r = 1:4
    tic; D.set_time(mod(r, 2)); rv_t(r) = toc;
end
assert(median(rv_t) < 0.5, sprintf("set_time %.3f s", median(rv_t)))


%% Automatic color limits come from all samples
% 標本 2 は電圧と電流を 1.2 倍 (電流は 1.2 倍、電力は 1.44 倍)
sct_net = struct(net14, false);
G0 = net14.plot_diagram(Parent=axes(fig));
assert(isequaln(G0.ColorLimits, [NaN NaN]) && G0.ColorbarLabel == "", "既定は自動")
mp = findprop(G0, "ColorLimits");
assert(isequaln(mp.DefaultValue, [NaN NaN]), "GUI の書式が読む既定は型に合う値")
sct = struct("rv_t", [0 1]);
sct.cm_Vbus  = G0.sct_state.cm_Vbus  .* [1, 1.2];
sct.cm_Icomp = G0.sct_state.cm_Icomp .* [1, 1.2];
G = GraphNetDiagram(sct_net, sct, Parent=axes(fig));
r_I = nearest_rank(all_values(G), 0.95);
assert(G.ColorMode == "I" && max(abs(G.ax.CLim - [0, r_I])) < 1e-12*r_I, "大きさは 0..全標本の 95 パーセンタイル")
assert(r_I < max(all_values(G)), "最大ではない")
assert(G.ax.Colorbar.Label.String == "|I| [pu]", "ColorMode から色の棒のラベル")
G.set_time(1);
assert(max(abs(G.ax.CLim - [0, r_I])) < 1e-12*r_I, "標本で変わらない")
G.set_time(0);
for s_mode = ["P", "Q"]
    G.ColorMode = s_mode;
    r_m = nearest_rank(all_values(G), 0.95);
    assert(max(abs(G.ax.CLim - [-r_m, r_m])) < 1e-12*r_m, s_mode + " は ±(|x| の 95 パーセンタイル)")
    assert(G.ax.Colorbar.Label.String == s_mode + " [pu]")
end
G.ColorMode = "Loss";
assert(G.ax.CLim(1) == 0 && G.ax.Colorbar.Label.String == "Loss [pu]")
% 数値を設定すると固定、色はその範囲で写す
G.ColorMode = "I";
G.ColorLimits = [0 5];
assert(isequal(G.ax.CLim, [0 5]))
n_map = size(G.Colormap, 1);
v = G.BranchColorData(1);
assert(isequal(G.sct_plt.EdgeMain(1).Color, G.Colormap(round(min(v, 5)/5*(n_map - 1) + 1), :)))
G.set_time(1);
assert(isequal(G.ax.CLim, [0 5]), "固定の範囲は標本で変わらない")
G.ColorLimits = [NaN NaN];
assert(max(abs(G.ax.CLim - [0, r_I])) < 1e-12*r_I, "NaN で自動に戻る")
% ColorbarLabel を設定すると優先、"" で自動に戻る
G.ColorbarLabel = "current";
assert(G.ax.Colorbar.Label.String == "current")
G.ColorMode = "P";
assert(G.ax.Colorbar.Label.String == "current")
G.ColorbarLabel = "";
assert(G.ax.Colorbar.Label.String == "P [pu]")
% "user" は色の値の 5〜95 パーセンタイル、ラベルは空。20 個未満は [最小 最大]
G.ColorMode = "user";
G.LinkColorData = nan(size(G.LinkColorData));
G.ComponentColorData = nan(size(G.ComponentColorData));   % "P" が機器にも入れた値を消す
n_br = numel(G.BranchColorData);
assert(n_br >= 20, "前提: IEEE14 のブランチは 20 本")
rv_u = linspace(2, 7, n_br)';
rv_u(end) = 100;                                       % 外れ値 1 つ
G.BranchColorData = rv_u;
assert(isequal(G.ax.CLim, [nearest_rank(rv_u, 0.05), nearest_rank(rv_u, 0.95)]) && G.ax.CLim(2) < 10, "外れ値は範囲を決めない")
assert(isequal(G.sct_plt.EdgeMain(end).Color, G.Colormap(end, :)), "外れ値は最上の色")
assert(G.ax.Colorbar.Label.String == "")
G.BranchColorData = [linspace(2, 7, 5)'; nan(n_br - 5, 1)];
assert(isequal(G.ax.CLim, [2 7]), "値が 20 個未満なら [最小 最大]")
% 1 つの機器の電流だけ 100 倍 (外れ値): 上限は 95 パーセンタイルで、その最大ではない
sct1 = struct("rv_t", 0, "cm_Vbus", G0.sct_state.cm_Vbus, "cm_Icomp", G0.sct_state.cm_Icomp);
sct1.cm_Icomp(1) = 100*sct1.cm_Icomp(1);
G1 = GraphNetDiagram(sct_net, sct1, Parent=axes(fig));
rv_v = all_values(G1);
assert(G1.ax.CLim(2) == nearest_rank(rv_v, 0.95) && G1.ax.CLim(2) < max(rv_v)/10, "1 つの外れ値は上限を決めない")
assert(isequal(G1.sct_plt.CompEdge(1).Color, G1.Colormap(end, :)), "外れ値のリンクは最上の色")


%% The colorbar ticks of a nearly constant field are a few short values
% 1e-9 だけ違う値 (OPF の LMP など): 範囲を中央 c の c(1 ∓ 1e-3) にし、目盛りは数桁
n_b = numel(net14.a_Bus);
rv_v = 3.1 + (0:n_b-1)'*4e-9/n_b;
D = net14.plot_diagram(Parent=axes(fig), ColorMode="user", BusColorData=rv_v);
assert(max(abs(D.ax.CLim - 3.1*[0.999 1.001])) < 1e-8)
sv_tick = string(D.ax.Colorbar.TickLabels);
assert(numel(sv_tick) >= 3 && numel(unique(sv_tick)) == numel(sv_tick) && max(strlength(sv_tick)) <= 6, join(sv_tick))
D.ColorLimits = [3.1, 3.1 + 4e-9];                     % 固定でも同じ
assert(max(abs(D.ax.CLim - 3.1*[0.999 1.001])) < 1e-8 && max(strlength(string(D.ax.Colorbar.TickLabels))) <= 6)
D.ColorLimits = [2 2];                                 % 同じ 2 つの値もエラーにしない
assert(max(abs(D.ax.CLim - [1.998 2.002])) < 1e-12)
D.ColorLimits = [0 0];
assert(isequal(D.ax.CLim, [-1 1]))
D.ColorLimits = [0 1e-3];                              % 小さくても 0 からなら写す
assert(isequal(D.ax.CLim, [0 1e-3]))


%% LabelMode "bus" shows the bus tags only, apart from each other on IEEE68
mc = ?GraphNetDiagram;
assert(mc.PropertyList(string({mc.PropertyList.Name}) == "LabelMode").DefaultValue == "bus")
net68 = network.IEEE68bus();
f2 = figure("Visible", "off", "Position", [100 100 560 420]);
c_f2 = onCleanup(@() close(f2));
D = net68.plot_diagram(Parent=f2);
assert(D.LabelMode == "bus")
hv = D.sct_plt.NodeLabel;
assert(all(isgraphics(hv)) && all([hv.Visible] == "on") && isequal(string({hv.String})', D.BusLabel))
assert(~any(isgraphics(D.sct_plt.CompLabel)), "機器のラベルは表示するまで作らない")
assert(numel(D.ComponentLabel) == numel(D.sct_plt.CompLabel))
drawnow
assert_apart(vertcat(hv.Extent), "IEEE68 560x420")
assert_inside(D.ax, vertcat(hv.Extent))
% 機器のラベルは LabelMode か パネルで表示できる
D.LabelMode = "tag";
hc = D.sct_plt.CompLabel;
assert(all(isgraphics(hc)) && all([hc.Visible] == "on") && all(strlength(string({hc.String})) > 0))
drawnow
assert_apart(vertcat(hv.Extent, hc.Extent), "tag")
D.LabelMode = "bus";
assert(all([hc.Visible] == "off") && all([hv.Visible] == "on"))
D.LabelMode = "none";
assert(all([hv.Visible] == "off"))
% 大きな図、IEEE14、3D の切り替えの後
D.LabelMode = "bus";
f2.Position = [100 100 1000 750];
D.Dimension = "2D";                                    % 描き直す
drawnow
assert_apart(vertcat(D.sct_plt.NodeLabel.Extent), "IEEE68 1000x750")
D = net14.plot_diagram(Parent=axes(fig));
drawnow
assert_apart(vertcat(D.sct_plt.NodeLabel.Extent), "IEEE14")


%% A component label set by the user gets its text object before LabelMode shows it
D = net14.plot_diagram(Parent=axes(fig));
assert(D.LabelMode == "bus" && ~any(isgraphics(D.sct_plt.CompLabel)))
sv_com = string(D.tab_element.Tag(D.tab_element.Kind == "component"));
D.ComponentLabel(2) = "X";                             % ベクトルで設定
D.set_style(sv_com(3), Label="Y");                     % タグで設定
hc = D.sct_plt.CompLabel;
assert(isequal(find(isgraphics(hc))', [2 3]), "設定した機器のラベルだけを作る")
assert(string(hc(2).String) == "X" && string(hc(3).String) == "Y" && all([hc(2:3).Visible] == "off"))
D.LabelFontSize = 13;
assert(hc(2).FontSize == 13)
D.set_time(0);                                         % "bus" は機器のラベルをタグに書き直す (作らない)
assert(string(hc(2).String) == D.ComponentLabel(2) && D.ComponentLabel(2) ~= "X" && sum(isgraphics(D.sct_plt.CompLabel)) == 2)
D.LabelMode = "user";
D.ComponentLabel(2) = "X";
hc = D.sct_plt.CompLabel;
assert(all(isgraphics(hc)) && all([hc.Visible] == "on") && string(hc(2).String) == "X")
assert(hc(4).FontSize == 13)
D.Dimension = "3D";                                    % 描き直しても設定したラベルが残る
assert(string(D.sct_plt.CompLabel(2).String) == "X" && D.sct_plt.CompLabel(2).Visible == "on")
D.LabelMode = "none";
assert(~any([D.sct_plt.CompLabel.Visible] == "on"))


%% The axes fit the drawing with a small padding
D = net14.plot_diagram(Parent=axes(fig));
rm_box = D.sct_plt.DrawBox;
r_ref = max(rm_box(2, 1:2) - rm_box(1, 1:2));
rm_ext = vertcat(D.sct_plt.NodeLabel.Extent);
rv_x = [min([rm_box(1, 1); rm_ext(:, 1)]), max([rm_box(2, 1); rm_ext(:, 1) + rm_ext(:, 3)])];
rv_y = [min([rm_box(1, 2); rm_ext(:, 2)]), max([rm_box(2, 2); rm_ext(:, 2) + rm_ext(:, 4)])];
assert(D.ax.XLim(1) < rv_x(1) && D.ax.XLim(2) > rv_x(2) && D.ax.YLim(1) < rv_y(1) && D.ax.YLim(2) > rv_y(2), "全部入る")
assert(max(abs([D.ax.XLim - rv_x, D.ax.YLim - rv_y])) <= 0.04*r_ref, "余白は小さい (母線の座標 0.25..0.9 でも [0 1] を含めない)")
D.Dimension = "3D";
assert(max(abs([D.ax.XLim - rm_box(:, 1)', D.ax.YLim - rm_box(:, 2)'])) <= 0.031*r_ref + 1e-12, "3D は図の箱 + 3%")

%% Loss colors are the exact branch losses on IEEE68
% "Loss" は各ブランチの有効電力損失 P_from + P_to (充電容量とタップを含む)。R|I_from|^2 ではない
net68 = network.IEEE68bus();
res68 = DebugScript.helper.quiet(@() net68.calculate_powerflow());
G = DebugScript.helper.quiet(@() net68.plot_diagram(Parent=axes(fig), ColorMode="Loss"));
rv_loss = G.BranchColorData;
sct68 = struct(net68, false);
im_edge = edge_buses(sct68);
cv_V = res68.tab_bus.Vphasor;
n_br = numel(sct68.a_Branch);
rv_ref = zeros(n_br, 1);
rv_RI2 = zeros(n_br, 1);
for k = 1:n_br
    b = sct68.a_Branch{k};
    cv_v = cv_V(im_edge(:, k));
    cv_i = b.cm_Y * cv_v;
    rv_ref(k) = real(sum(cv_v .* conj(cv_i)));
    rv_RI2(k) = b.tab_parameter.dynamics.R * abs(cv_i(1))^2;
end
err = max(abs(rv_loss - rv_ref));
assert(err < 1e-9, "Re(S_from + S_to) と一致: " + err)
assert(max(abs(rv_loss - res68.tab_branch.Ploss)) < 1e-9, "潮流計算の Ploss と一致")
assert(all(rv_loss >= 0), "丸めの負の値は 0")
sv_from = string(res68.tab_branch.From);
sv_to   = string(res68.tab_branch.To);
k = find(sv_from == "B042" & sv_to == "B018" | sv_from == "B018" & sv_to == "B042", 1);
assert(abs(rv_RI2(k) - rv_loss(k)) > 0.3*rv_loss(k), "充電容量の大きい線路 B042-B018 では R|I_from|^2 と違う")
r_total = sum(res68.tab_bus.P) - sum(real(cv_V .* conj(sct_bus_shunt(sct68) .* cv_V)));
assert(abs(sum(rv_loss) - r_total) < 1e-8*abs(r_total), "和は系統全体の損失 (注入の和 - 母線シャント)")
% 片端で開いたブランチ (受電端の電流 0) は送電端の損失 (充電容量の分) で有限
cm_Y = sct68.a_Branch{k}.cm_Y;
y_s = -cm_Y(1, 2);
y_t = cm_Y(2, 2) + cm_Y(1, 2);
cm_Yopen = [cm_Y(1, 1) + cm_Y(1, 2) + y_s*y_t/(y_s + y_t), 0; 0, 0];
c_Y = cell2mat(reshape(cellfun(@(b) b.cm_Y, sct68.a_Branch(:), "UniformOutput", false), 1, 1, []));
c_Y(:, :, k) = cm_Yopen;
sct_state = struct("rv_t", 0, "cm_Vbus", cv_V, "cm_Icomp", G.sct_state.cm_Icomp, "c_Ybranch", {{c_Y}}, "iv_Ybranch", 1);
G1 = GraphNetDiagram(sct68, sct_state, Parent=axes(fig), ColorMode="Loss");
cv_v = cv_V(im_edge(:, k));
r_open = real(cv_v(1) * conj(cm_Yopen(1, :) * cv_v));
assert(r_open > 0 && abs(G1.BranchColorData(k) - r_open) < 1e-12, "片端が開いたブランチは有限")
% 端の値が NaN なら 0 として足し、両端 NaN は NaN
c_Y(:, :, k) = [NaN NaN; cm_Y(2, :)];
sct_state.c_Ybranch = {c_Y};
G1 = GraphNetDiagram(sct68, sct_state, Parent=axes(fig), ColorMode="Loss");
r_to = real(cv_v(2) * conj(cm_Y(2, :) * cv_v));
assert(abs(G1.BranchColorData(k) - r_to) < 1e-12, "NaN の端は 0")
c_Y(:, :, k) = NaN;
sct_state.c_Ybranch = {c_Y};
G1 = GraphNetDiagram(sct68, sct_state, Parent=axes(fig), ColorMode="Loss");
assert(isnan(G1.BranchColorData(k)), "両端 NaN は NaN")


%% Components take the colormap color of their links and are black without a value
% "I"/"P"/"Q" は機器の印を接続線と同じ値で塗る。値がない ("Loss"、停止した機器) と黒、"none" は機器の種類の色
G = net14.plot_diagram(Parent=axes(fig), ColorMode="none");
rm_class = vertcat(G.sct_plt.CompMain.MarkerFaceColor);
G.ColorMode = "P";
assert(isequal(G.ComponentColorData, G.LinkColorData) && all(isfinite(G.ComponentColorData)))
rm_face = vertcat(G.sct_plt.CompMain.MarkerFaceColor);
assert(isequal(rm_face, map_color(G, G.LinkColorData)), "P: 接続線の値の色")
assert(isequal(vertcat(G.sct_plt.CompEdge.Color), rm_face), "接続線と同じ色")
r_m = nearest_rank(all_values(G), 0.95);
assert(max(abs(G.ax.CLim - [-r_m, r_m])) < 1e-12*r_m, "範囲は機器の値を含めても 95 パーセンタイル")
G.ColorMode = "Loss";
assert(all(isnan(G.ComponentColorData)) && all(vertcat(G.sct_plt.CompMain.MarkerFaceColor) == 0, "all"), "Loss: 黒")
G.ColorMode = "none";
assert(isequal(vertcat(G.sct_plt.CompMain.MarkerFaceColor), rm_class), "none: 種類の色")
G.ComponentColor(1, :) = [0 1 0];
G.ColorMode = "P";
assert(isequal(G.sct_plt.CompMain(1).MarkerFaceColor, [0 1 0]), "固定の色が優先")
% 停止した機器 (電流 NaN) は黒、時刻を動かすと色が変わる
sct_state = G.sct_state;
sct_state.rv_t = [0 1];
sct_state.cm_Vbus = repmat(sct_state.cm_Vbus, 1, 2);
sct_state.cm_Icomp = repmat(sct_state.cm_Icomp, 1, 2);
sct_state.cm_Icomp(2, 2) = NaN;
sct_state = rmfield(sct_state, "cm_Ibranch");
for s_dim = ["2D", "3D"]
    G1 = GraphNetDiagram(struct(net14, false), sct_state, Parent=axes(fig), ColorMode="P", Dimension=s_dim);
    c_face = @() comp_face(G1, 2);
    assert(any(c_face() ~= 0), s_dim + ": 運転中は色")
    G1.set_time(1);
    assert(isnan(G1.ComponentColorData(2)) && all(c_face() == 0), s_dim + ": 停止した機器は黒")
    G1.set_time(0);
    assert(isequal(c_face(), map_color(G1, G1.ComponentColorData(2))), s_dim + ": 戻すと値の色")
end


function rm_c = map_color(G, rv)
% 値の colormap の色 (CLim で切って最も近い行)
    rv_lim = G.ax.CLim;
    n = size(G.Colormap, 1);
    rm_c = G.Colormap(round((min(max(rv(:), rv_lim(1)), rv_lim(2)) - rv_lim(1))/diff(rv_lim)*(n - 1) + 1), :);
end

function rv_c = comp_face(G, k)
% 機器 k の印の色 (2D: MarkerFaceColor、3D: 立体の FaceColor)
    h = G.sct_plt.CompMain(k);
    if G.Dimension == "2D"
        rv_c = h.MarkerFaceColor;
    else
        hv = findall(h, "-property", "FaceColor");
        rv_c = hv(1).FaceColor;
    end
end

function im_edge = edge_buses(sct_net)
% 各ブランチの両端の母線の番号 (2 x n_branch)
    n = numel(sct_net.a_Branch);
    sv_bus = string(cellfun(@(b) b.s_tag, sct_net.a_Bus(:), "UniformOutput", false));
    im_edge = zeros(2, n);
    for k = 1:n
        for m = 1:2
            x = sct_net.a_Branch{k}.a_Bus{m};
            if isstruct(x)
                im_edge(m, k) = find(sv_bus == string(x.s_tag), 1);
            else
                im_edge(m, k) = str2double(regexp(string(x), "a_Bus\{(\d+)\}$", "tokens", "once"));
            end
        end
    end
end

function cv_y = sct_bus_shunt(sct_net)
% 各母線のシャントアドミタンス (n_bus x 1)
    cv_y = cellfun(@(b) complex(b.tab_parameter.dynamics.Gshunt, b.tab_parameter.dynamics.Bshunt), sct_net.a_Bus(:));
end

function q = branch_flow(sct_net, cv_V, s_mode)
% ブランチの流れ |P_from - P_to|/2 (s_mode "P")
    im_edge = edge_buses(sct_net);
    n = size(im_edge, 2);
    q = zeros(n, 1);
    for k = 1:n
        cv_v = cv_V(im_edge(:, k));
        cv_s = cv_v .* conj(sct_net.a_Branch{k}.cm_Y * cv_v);
        if s_mode == "P"
            q(k) = abs(real(cv_s(1)) - real(cv_s(2)))/2;
        end
    end
end

function r = tube_radius(D, k)
% ブランチ k の管の始点の断面の半径
    h = findall(D.sct_plt.EdgeMain(k), "Tag", "tube");
    rm_p = [h.XData(1, :)', h.YData(1, :)', h.ZData(1, :)'];
    r = max(vecnorm(rm_p - mean(rm_p(1:end-1, :)), 2, 2));
end

function r = span_of(D)
% 母線の中心の外接箱の長い辺
    r = max([max(D.sct_plt.XMain) - min(D.sct_plt.XMain), max(D.sct_plt.YMain) - min(D.sct_plt.YMain)]);
end

function rv = all_values(G)
% 全標本のブランチとリンクの色の値の |x| (有限のもの)。表示中の標本は戻す
    t0 = G.rv_t(G.i_time);
    rv = zeros(0, 1);
    for t = G.rv_t
        G.set_time(t);
        rv = [rv; abs([G.BranchColorData; G.LinkColorData])]; %#ok<AGROW>
    end
    G.set_time(t0);
    rv = rv(isfinite(rv));
end

function r = nearest_rank(rv, q)
% 最近順位法のパーセンタイル (20 個未満は最大か最小)
    rv = sort(rv(isfinite(rv)));
    n = numel(rv);
    if n < 20
        r = rv(end);
        if q < 0.5
            r = rv(1);
        end
        return
    end
    r = rv(ceil(q*n));
end

%% plot_diagram reads the same network as the whole snapshot struct(net, false)
D = net14.plot_diagram(Parent=axes(fig));
c_Icomp = cellfun(@(b) cellfun(@(c) c.c_Iequilibrium, b.a_Component(:)), net14.a_Bus(:), "UniformOutput", false);
sct_state = struct("rv_t", 0, "cm_Vbus", cellfun(@(b) b.c_Vequilibrium, net14.a_Bus(:)), "cm_Icomp", vertcat(c_Icomp{:}));
D2 = GraphNetDiagram(struct(net14, false), sct_state, Parent=axes(fig));
assert(isequal(D.tab_element, D2.tab_element), "同じ要素")
assert(isequaln(D.sct_plt.DrawBox, D2.sct_plt.DrawBox) && isequaln(D.ax.XLim, D2.ax.XLim), "同じ配置")
assert(isequal(get(D.sct_plt.EdgeMain, "Color"), get(D2.sct_plt.EdgeMain, "Color")) ...
    && isequal(get(D.sct_plt.EdgeMain, "LineWidth"), get(D2.sct_plt.EdgeMain, "LineWidth")), "同じ色と幅")

%% A Graph=G redraw keeps the objects while the drawing stays
ax1 = axes(fig);
D = net14.plot_diagram(Parent=ax1);
hv_edge = D.sct_plt.EdgeMain;
hv_label = D.sct_plt.NodeLabel;
D.set_style("B001", Color=[1 0 0]);
D.select("B002");
n_child = numel(allchild(ax1));
G = net14.plot_diagram(Graph=D, ColorMode="Q");
assert(G == D && isequal(D.sct_plt.EdgeMain, hv_edge) && isequal(D.sct_plt.NodeLabel, hv_label), "同じオブジェクト")
assert(numel(allchild(ax1)) == n_child, "オブジェクトが増えない (選択の重ね描きは描き直す)")
assert(isequal(D.sct_plt.NodeMain(1).Color, [1 0 0]), "set_style が残る")
assert(D.ColorMode == "Q" && ~isempty(D.ax.Colorbar), "新しい ColorMode で塗り直す")
assert(all(isgraphics(D.sct_plt.Selection)), "選択が残る")
assert(isa(hv_edge(1).ButtonDownFcn, "function_handle"), "クリックはそのまま")
% 同じ大きさの軸に新しく描いた図と同じ見た目
D2 = net14.plot_diagram(Parent=axes(fig, "Position", ax1.Position), ColorMode="Q");
D2.set_style("B001", Color=[1 0 0]);
assert(isequal(get(D.sct_plt.EdgeMain, "Color"), get(D2.sct_plt.EdgeMain, "Color")) ...
    && isequal(get(D.sct_plt.EdgeMain, "LineWidth"), get(D2.sct_plt.EdgeMain, "LineWidth")), "新しく描いた図と同じ色と幅")
assert(max(abs([D.ax.XLim - D2.ax.XLim, D.ax.YLim - D2.ax.YLim])) < 1e-9, "同じ範囲")
% 別の系統 (描くものが変わる) では描き直し、古いオブジェクトは残らない
net9 = network.IEEE9bus();
DebugScript.helper.quiet(@() net9.initialize);
net9.plot_diagram(Graph=D);
assert(~any(isgraphics(hv_edge)), "古いオブジェクトは消える")
assert(numel(D.sct_plt.EdgeMain) == numel(net9.a_Branch) && all(isgraphics(D.sct_plt.EdgeMain)))
assert(numel(findobj(ax1, "Type", "text")) == numel(net9.a_Bus), "ラベルは母線の数だけ")

%% Labels stay next to their elements after the limits and the size change (GUI)
% GUILDA.launch_gui の左の図と同じ入れ子: 描いた後で軸の範囲を変え (axis tight + 余白)、
% 操作パネルの列を開け閉めし、ログの行を隠し、figure の大きさを変える
net68 = network.IEEE68bus();
uf = uifigure("Visible", "off", "Position", [50 50 1200 760]);
c_uf = onCleanup(@() delete(uf));
g0 = uigridlayout(uf, [1 2], "ColumnWidth", {"1x", "1x"});
gl = uigridlayout(g0, [3 1], "RowHeight", {30, "1x", 130});
gl.Layout.Column = 1;
uilabel(gl, "Text", "top");
h_side = uigridlayout(gl, [1 2], "ColumnWidth", {"1x", 0}, "Padding", 0);
h_side.Layout.Row = 2;
h_diag = uipanel(h_side);
h_diag.Layout.Column = 1;
uitextarea(gl);
drawnow
D = net68.plot_diagram(Parent=h_diag, TitleFormat="");
wait_layout(D, false)
assert_labels(D, "描いた後")
ax = D.ax;
axis(ax, "tight");
r_pad = 0.04*max([diff(ax.XLim), diff(ax.YLim)]);
ax.XLim = ax.XLim + [-1 1]*r_pad;
ax.YLim = ax.YLim + [-1 1]*r_pad;
rv_lim = [ax.XLim, ax.YLim];
wait_layout(D, false)
assert_labels(D, "axis tight + 余白")
h_panel = D.show_controls(Parent=h_side);
h_panel.Layout.Column = 2;
h_side.ColumnWidth{2} = 230;
wait_layout(D, true)
assert_labels(D, "操作パネルを開く")
h_side.ColumnWidth{2} = 0;
gl.RowHeight{3} = 0;
wait_layout(D, true)
assert_labels(D, "操作パネルを閉じ、ログを隠す")
uf.Position = [50 50 800 500];
wait_layout(D, true)
assert_labels(D, "figure を小さく")
assert(isequal([ax.XLim, ax.YLim], rv_lim), "外から設定した範囲はそのまま")
% 同じ大きさ・範囲で描き直した図と同じ位置 (変化の順によらない)
rm_pos = vertcat(D.sct_plt.NodeLabel.Position);
D.Dimension = "2D";
ax = D.ax;
ax.XLim = rv_lim(1:2);
ax.YLim = rv_lim(3:4);
wait_layout(D, false)
assert(max(abs(rm_pos - vertcat(D.sct_plt.NodeLabel.Position)), [], "all") < 1e-9, "描き直した図と同じ位置")
% 範囲を外から変えていなければ、大きさが変わると範囲もラベルに合わせ直す
D.Dimension = "2D";
uf.Position = [50 50 1200 760];
wait_layout(D, true)
assert_labels(D, "描き直して大きく")
rm_ext = vertcat(D.sct_plt.NodeLabel.Extent);
assert_inside(D.ax, rm_ext)
delete(uf);

%% A diagram drawn in a hidden tab lays its labels out when the tab is shown
net68 = network.IEEE68bus();
uf = uifigure("Visible", "off", "Position", [50 50 900 700]);
c_uf = onCleanup(@() delete(uf));
tg = uitabgroup(uf, "Position", [10 10 880 680]);
t1 = uitab(tg, "Title", "one");
t2 = uitab(tg, "Title", "two");
drawnow
D = net68.plot_diagram(Parent=t2, TitleFormat="");
wait_layout(D, false)
tg.SelectedTab = t2;
wait_layout(D, false)
assert_labels(D, "隠れたタブを表示")
rm_ext = vertcat(D.sct_plt.NodeLabel.Extent);
assert_inside(D.ax, rm_ext)
delete(uf);


function wait_layout(D, l_change)
% uifigure の配置は非同期: (l_change なら軸の画素の大きさが変わるのを待ってから) 範囲と大きさが
% 0.3 s 変わらず、ラベルがその範囲と大きさで配置される (sct_plt.LabelView) まで待つ。最大 5 s ずつ
    ax = D.ax(1);
    f_view = @() [ax.XLim, ax.YLim, round(subsref(getpixelposition(ax), substruct("()", {3:4})))];
    rv_old = f_view();
    t0 = tic;
    while l_change && toc(t0) < 5
        drawnow
        if ~isequal(f_view(), rv_old)
            break
        end
        pause(0.05)
    end
    rv_last = [];
    t0 = tic;
    t_same = tic;
    while toc(t0) < 5
        drawnow
        rv = f_view();
        if ~isequal(rv, rv_last)
            rv_last = rv;
            t_same = tic;
        elseif toc(t_same) > 0.3 && isequal(D.sct_plt.LabelView, rv)
            break
        end
        pause(0.05)
    end
end

function assert_labels(D, s_case)
% 表示中の母線のラベルが重ならず、その母線のすぐ横 (元の位置から縦に 3 行以内、横はそのまま) にある
    hv = D.sct_plt.NodeLabel(:);
    lv = isgraphics(hv) & strcmp(get(hv, "Visible"), "on");
    hv = hv(lv);
    rm_ext = vertcat(hv.Extent);
    assert_apart(rm_ext, s_case)
    rm_pos = vertcat(hv.Position);
    rm_xyz = D.sct_plt.NodeLabelXYZ(lv, :);
    assert(max(abs(rm_pos(:, 1) - rm_xyz(:, 1))) < 1e-12, s_case + ": ラベルが横にずれた")
    rv_line = abs(rm_pos(:, 2) - rm_xyz(:, 2)) ./ rm_ext(:, 4);
    assert(max(rv_line) <= 3, sprintf("%s: ラベルが母線から %.1f 行離れた", s_case, max(rv_line)))
end

function assert_apart(rm_ext, s_case)
% ラベルの箱 [x y w h] が互いに重ならない
    for i = 1:size(rm_ext, 1)
        for j = i+1:size(rm_ext, 1)
            r_ox = min(rm_ext(i,1) + rm_ext(i,3), rm_ext(j,1) + rm_ext(j,3)) - max(rm_ext(i,1), rm_ext(j,1));
            r_oy = min(rm_ext(i,2) + rm_ext(i,4), rm_ext(j,2) + rm_ext(j,4)) - max(rm_ext(i,2), rm_ext(j,2));
            assert(r_ox <= 1e-9 || r_oy <= 1e-9, sprintf("%s: ラベル %d と %d が重なる", s_case, i, j))
        end
    end
end

function assert_inside(ax, rm_ext)
% ラベルの箱が軸の範囲の中
    assert(all(rm_ext(:, 1) >= ax.XLim(1)) && all(rm_ext(:, 1) + rm_ext(:, 3) <= ax.XLim(2)) ...
        && all(rm_ext(:, 2) >= ax.YLim(1)) && all(rm_ext(:, 2) + rm_ext(:, 4) <= ax.YLim(2)), "ラベルが軸の外")
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
