% F46 図の共通の基底クラス (GraphBase): GraphSpring2D/3D と GraphNetDiagram
%
%   G.set_style(sr_tag, Color=, Label=, Marker=, MarkerSize=, LineWidth=, LineStyle=, Visible=);
%   G.set_position(sr_tag, rm_xy);      % 自由配置の図 (GraphNetDiagram) だけ
%   G.set_data(sct_data);  G.set_time(t);  G.link(G2);  G.unlink(G2);
%   G.tab_element                       % Tag, Kind, Index
%   G.animate(...);  G.export_video(s_file, ...);
%
% タグによる設定と要素ごとのベクトルのプロパティによる設定が同じ図になること、誤りの
% エラー、位置の変更がモデルを変えないこと、データの差し替えで見た目が残ること、
% リンクした図が時刻に追従することを確かめる。図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F46_graph_base")  または  DebugScript.run_all("Features","F46")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% 合成のばね質点データ (test_F42 と同じ): 母線 B1-B3 と B1 の機器ノード G1
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
sct.rv_circle = [nan; nan; nan; 1.1];
% 座標を持たない 3 母線系統 (自動配置を通る)
[net, gen] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
% 母線、機器 (母線ごと)、ブランチのタグ
sv_bus = string(cellfun(@(b) b.s_tag, net.a_Bus(:), "UniformOutput", false));
c_com  = cellfun(@(b) cellfun(@(c) string(c.s_tag), b.a_Component(:)), net.a_Bus(:), "UniformOutput", false);
sv_com = vertcat(c_com{:});
sv_br  = string(cellfun(@(b) b.s_tag, net.a_Branch(:), "UniformOutput", false));


%% tab_element lists every element with its kind and index
G = GraphSpring2D(sct, Parent=axes(fig));
assert(isa(G, "GraphBase"))
tab = G.tab_element;
assert(isequal(tab.Properties.VariableNames, {'Tag', 'Kind', 'Index'}))
assert(isequal(tab.Tag, ["B1"; "B2"; "B3"; "G1"; "L12"; "L23"; "X1"; "G1"; "B3"]))
assert(isequal(tab.Kind, [repmat("node", 4, 1); repmat("edge", 3, 1); "arrow"; "arrow"]))
assert(isequal(tab.Index, [1; 2; 3; 4; 1; 2; 3; 1; 2]))
% ネットワーク図: 母線、機器 (完全なタグ)、ブランチ、リンク (機器のタグ)
D = net.plot_diagram(Parent=axes(fig));
tab = D.tab_element;
assert(isequal(tab.Tag(tab.Kind == "bus"), sv_bus))
assert(isequal(tab.Tag(tab.Kind == "component"), sv_com) && any(sv_com == gen.s_tag))
assert(isequal(tab.Tag(tab.Kind == "branch"), sv_br))
assert(isequal(tab.Tag(tab.Kind == "link"), sv_com))
assert(isequal(unique(tab.Kind)', ["branch", "bus", "component", "link"]))


%% set_style by tag and by vector give the same graphics
% GraphSpring2D: タグで設定
Ga = GraphSpring2D(sct, Parent=axes(fig));
Ga.set_style(["B1", "B2"], Color="r", MarkerSize=20);
Ga.set_style("L12", LineWidth=3, Color=[0 0 1]);
Ga.set_style("B3", Label="load", Visible=false);
% 同じことをベクトルのプロパティで設定
Gb = GraphSpring2D(sct, Parent=axes(fig));
Gb.NodeColor(1:2, :) = [1 0 0; 1 0 0];
Gb.NodeSize(1:2)     = 20;
Gb.EdgeLineWidth(1)  = 3;
Gb.EdgeColor(1, :)   = [0 0 1];
Gb.NodeLabel(3)      = "load";
Gb.NodeVisible(3)    = false;
for s_prop = ["NodeColor", "NodeSize", "NodeLabel", "NodeVisible", "EdgeColor", "EdgeLineWidth"]
    assert(isequal(Ga.(s_prop), Gb.(s_prop)), s_prop + " がタグとベクトルで違う")
end
for n = 1:4
    assert(isequal(Ga.sct_plt.Node(n).MarkerFaceColor, Gb.sct_plt.Node(n).MarkerFaceColor))
    assert(Ga.sct_plt.Node(n).MarkerSize == Gb.sct_plt.Node(n).MarkerSize)
    assert(Ga.sct_plt.Node(n).Visible == Gb.sct_plt.Node(n).Visible)
    assert(string(Ga.sct_plt.LabelNode(n).String) == string(Gb.sct_plt.LabelNode(n).String))
end
assert(isequal(Ga.sct_plt.Node(1).MarkerFaceColor, [1 0 0]) && Ga.sct_plt.Node(1).MarkerSize == 20)
assert(Ga.sct_plt.Spring(1).LineWidth == 3 && isequal(Ga.sct_plt.Spring(1).Color, [0 0 1]))
assert(Ga.sct_plt.Node(3).Visible == "off" && Ga.sct_plt.LabelNode(3).Visible == "off")
assert(string(Ga.sct_plt.LabelNode(3).String) == "load")
% 変えていない要素はそのまま
assert(isequal(Ga.sct_plt.Node(4).MarkerFaceColor, [0 0.447 0.741]) && Ga.sct_plt.Spring(2).LineWidth == 0.8)
% 見た目は時刻を変えても残る
Ga.set_time(1.5);
assert(isequal(Ga.sct_plt.Node(1).MarkerFaceColor, [1 0 0]) && Ga.sct_plt.LabelNode(3).Visible == "off")
% GraphSpring3D でもタグで設定できる (球から円錐へ)
G3 = GraphSpring3D(sct, Parent=axes(fig));
G3.set_style("G1", Color="#00AA00", Marker="v", MarkerSize=10);
assert(G3.NodeMarker(4) == "v" && G3.NodeSize(4) == 10)
assert(max(abs(G3.sct_plt.Node(4).FaceColor - [0 170/255 0])) < 1e-12)
assert(isequal(size(G3.sct_plt.Node(4).XData), size(G3.sct_plt.ConeX)), "円錐の面になる")

% GraphNetDiagram: タグとベクトル (3D の立体の色)
Da = net.plot_diagram(Parent=axes(fig), Dimension="3D");
Db = net.plot_diagram(Parent=axes(fig), Dimension="3D");
Da.set_style(sv_bus(1:2), Color="r");
Da.set_style(sv_br(1), Color=[0 0.5 0]);
Da.set_style(gen.s_tag, Label="SG");
Db.BusColor(1:2, :)  = [1 0 0; 1 0 0];
Db.BranchColor(1, :) = [0 0.5 0];
i_gen = find(sv_com == gen.s_tag);
Db.ComponentLabel(i_gen) = "SG";
assert(isequaln(Da.BusColor, Db.BusColor) && isequaln(Da.BranchColor, Db.BranchColor))
assert(isequal(Da.ComponentLabel, Db.ComponentLabel))
for i = 1:numel(sv_bus)
    assert(isequal(Da.sct_plt.NodeMain(i).FaceColor, Db.sct_plt.NodeMain(i).FaceColor))
end
assert(isequal(Da.sct_plt.NodeMain(1).FaceColor, [1 0 0]))
assert(isequal(Da.sct_plt.EdgeMain(1).FaceColor, [0 0.5 0]) && isequal(Db.sct_plt.EdgeMain(1).FaceColor, [0 0.5 0]))
assert(string(Da.sct_plt.CompLabel(i_gen).String) == "SG")
% 固定の色は ColorMode の色より優先し、時刻や ColorMode を変えても残る
Da.ColorMode = "P";
Da.set_time(0);
assert(isequal(Da.sct_plt.EdgeMain(1).FaceColor, [0 0.5 0]))
assert(~isequal(Da.sct_plt.EdgeMain(2).FaceColor, [0 0.5 0]))
% NaN に戻すと色の値の色に戻る
Da.BranchColor(1, :) = nan;
assert(~isequal(Da.sct_plt.EdgeMain(1).FaceColor, [0 0.5 0]))
% LabelMode "tag" では時刻ごとにタグを書き直し、"user" では設定したラベルが残る
assert(string(Da.sct_plt.CompLabel(i_gen).String) ~= "SG")
Da.LabelMode = "user";
Da.set_style(gen.s_tag, Label="SG");
Da.ColorLimits = [0 1];
Da.set_time(0);
assert(string(Da.sct_plt.CompLabel(i_gen).String) == "SG")


%% Unknown tags and options that do not apply are errors
G = GraphSpring2D(sct, Parent=axes(fig));
assert(error_id(@() G.set_style("ZZZ", Color="r")) == "GUILDA:GraphBase:UnknownTag")
s = error_message(@() G.set_style(["B1", "ZZZ"], Color="r"));
assert(contains(s, "ZZZ") && ~contains(s, "B1,"), "知らないタグだけを示す")
% ばねには MarkerSize がない (種類と使えるオプションを示す)
assert(error_id(@() G.set_style("L12", MarkerSize=3)) == "GUILDA:GraphBase:StyleNotApplicable")
s = error_message(@() G.set_style("L12", MarkerSize=3));
assert(contains(s, "edge") && contains(s, "LineWidth"))
% LineStyle はどの種類にもない
assert(error_id(@() G.set_style("B1", LineStyle="--")) == "GUILDA:GraphBase:StyleNotApplicable")
% 矢印は節点と同じタグを持つが、節点のオプションはその節点に効く
G.set_style("G1", Color="r");
assert(isequal(G.NodeColor(4, :), [1 0 0]))
% 値の誤り
assert(error_id(@() G.set_style("B1", Color="notacolor")) == "GUILDA:GraphBase:StyleValue")
assert(error_id(@() G.set_style(["B1", "B2"], Label=["a", "b", "c"])) == "GUILDA:GraphBase:StyleValue")
% ベクトルの大きさが違うと止まる
assert(error_id(@() set_prop(G, "NodeColor", zeros(2, 3))) == "GUILDA:GraphSpringBase:StyleSize")
% ネットワーク図: ブランチにラベルはない
D = net.plot_diagram(Parent=axes(fig));
assert(error_id(@() D.set_style(sv_br(1), Label="x")) == "GUILDA:GraphBase:StyleNotApplicable")
assert(error_id(@() D.set_style(sv_bus(1), LineWidth=3)) == "GUILDA:GraphBase:StyleNotApplicable")
assert(error_id(@() D.set_style("nobus", Color="r")) == "GUILDA:GraphBase:UnknownTag")
% MarkerSize と LineWidth は 1 つかタグごとに 1 つ
assert(error_id(@() D.set_style(sv_bus(1:2), MarkerSize=[1 2 3])) == "GUILDA:GraphBase:StyleValue")
assert(error_id(@() D.set_style(sv_br(1), LineWidth=[1 2])) == "GUILDA:GraphBase:StyleValue")


%% Marker sizes and branch widths of GraphNetDiagram scale the drawn solids
% ばね質点の図でもタグごとの MarkerSize と LineWidth を受ける
G = GraphSpring2D(sct, Parent=axes(fig));
G.set_style(["B1", "B2"], MarkerSize=[5 7]);
G.set_style(["L12", "L23"], LineWidth=[2 4]);
assert(isequal(G.NodeSize(1:2), [5; 7]) && isequal(G.EdgeLineWidth(1:2), [2; 4]))
assert(G.sct_plt.Node(2).MarkerSize == 7 && G.sct_plt.Spring(2).LineWidth == 4)
% ネットワーク図 (3D の立体): 既定は NaN (MarkerSizeRange の中央 7.5 pt と BranchWidthMode の幅)
D = net.plot_diagram(Parent=axes(fig), Dimension="3D");
r_s = mean(D.MarkerSizeRange);
n_com = numel(sv_com);
i_gen = find(sv_com == gen.s_tag);
assert(isequaln(D.BusMarkerSize, nan(numel(sv_bus), 1)) && isequaln(D.ComponentMarkerSize, nan(n_com, 1)))
assert(isequaln(D.BranchLineWidth, nan(numel(sv_br), 1)))
sct_h0  = D.sct_plt;
c_geom0 = {bus_extent(D, 1), comp_extent(D, i_gen), tube_radius(D, 1), bus_extent(D, 2)};
r_w0    = D.sct_plt.BranchWidth0(1);
% タグで設定: 母線とブランチはタグごと、機器は 1 つの値
D.set_style(sv_bus(1:2), MarkerSize=[2 3]*r_s);
D.set_style(gen.s_tag, MarkerSize=2*r_s);
D.set_style(sv_br(1), LineWidth=2*r_w0);
assert(isequaln(D.BusMarkerSize, [2; 3; nan(numel(sv_bus)-2, 1)]*r_s))
assert(D.ComponentMarkerSize(i_gen) == 2*r_s && D.BranchLineWidth(1) == 2*r_w0)
% 描いた立体は作り直さずに大きさだけ変わる (母線の棒は高さ、機器は全体、ブランチは太さ)
assert(isequal(D.sct_plt.NodeMain, sct_h0.NodeMain) && isequal(D.sct_plt.CompMain, sct_h0.CompMain))
assert(isequal(D.sct_plt.EdgeMain, sct_h0.EdgeMain) && isequal(D.sct_plt.EdgeArrow, sct_h0.EdgeArrow))
assert(abs(bus_extent(D, 1)/c_geom0{1} - 2) < 1e-9, "母線の大きさが 2 倍にならない")
assert(abs(comp_extent(D, i_gen)/c_geom0{2} - 2) < 1e-9, "機器の大きさが 2 倍にならない")
assert(abs(tube_radius(D, 1)/c_geom0{3} - 2) < 1e-9, "ブランチの太さが 2 倍にならない")
% 同じことをベクトルで設定すると同じ図になる
D2 = net.plot_diagram(Parent=axes(fig), Dimension="3D");
D2.BusMarkerSize(1:2) = [2; 3]*r_s;
D2.ComponentMarkerSize(i_gen) = 2*r_s;
D2.BranchLineWidth(1) = 2*r_w0;
for s_prop = ["BusMarkerSize", "ComponentMarkerSize", "BranchLineWidth"]
    assert(isequaln(D.(s_prop), D2.(s_prop)), s_prop + " がタグとベクトルで違う")
end
assert(abs(bus_extent(D2, 2) - bus_extent(D, 2)) < 1e-12 && abs(tube_radius(D2, 1) - tube_radius(D, 1)) < 1e-12)
% 範囲を変えても、設定した大きさは残る (pt で、範囲に写さない)
D2.MarkerSizeRange = 2*D2.MarkerSizeRange;
assert(abs(comp_extent(D2, i_gen) - comp_extent(D, i_gen)) < 1e-12)
% NaN に戻すと既定の大きさに戻る
D.BusMarkerSize(1) = nan;
D.BranchLineWidth(1) = nan;
assert(abs(bus_extent(D, 1) - c_geom0{1}) < 1e-12 && abs(tube_radius(D, 1) - c_geom0{3}) < 1e-12)
assert(abs(comp_extent(D, i_gen)/c_geom0{2} - 2) < 1e-9)
% 時刻を変えても残る
D.set_time(0);
assert(abs(comp_extent(D, i_gen)/c_geom0{2} - 2) < 1e-9)
% reset_style ですべて NaN と既定の大きさに戻る
D.reset_style();
assert(all(isnan([D.BusMarkerSize; D.ComponentMarkerSize; D.BranchLineWidth])))
assert(abs(bus_extent(D, 2) - c_geom0{4}) < 1e-12)
assert(abs(comp_extent(D, i_gen) - c_geom0{2}) < 1e-12)


%% Updating every color size and width of IEEE68 is fast
% 最大の同梱モデル (IEEE68) で全母線・全機器・全ブランチの色・大きさ・太さを 1 回更新する (2D と 3D)。
% 目標は 0.1 秒以下 (負荷平均 10 前後で 0.08〜0.10 秒)。長い medium の実行中に 0.5 秒を
% 超えたことがあるので、上限は 1 秒にする (中央値。測った時間は表示する)。IEEE68 の図を
% 作り直すと 1.5〜1.9 秒 (plot_diagram(Graph=D)、JIT の後) かかるので、1 秒でも 1 回ごとの
% 作り直しへの退行は捕まえる。作り直しそのものはハンドルが変わらないことでも確かめる。
net68 = network.IEEE68bus();
DebugScript.helper.quiet(@() net68.initialize);
for s_dim = ["2D", "3D"]
D = net68.plot_diagram(Parent=axes(fig), Dimension=s_dim);
tab = D.tab_element;
sv_bc = tab.Tag(ismember(tab.Kind, ["bus", "component"]))';
sv_e  = tab.Tag(tab.Kind == "branch")';
n_b = numel(D.BusMarkerSize); n_c = numel(D.ComponentMarkerSize); n_e = numel(D.BranchLineWidth);
h_node = D.sct_plt.NodeMain;
rv_vec = zeros(5, 1);
rv_tag = zeros(5, 1);
for k = 1:5
    t0 = tic;
    D.BusColor = rand(n_b, 3);  D.ComponentColor = rand(n_c, 3);  D.BranchColor = rand(n_e, 3);
    D.BusMarkerSize = 5 + 10*rand(n_b, 1);  D.ComponentMarkerSize = 5 + 10*rand(n_c, 1);
    D.BranchLineWidth = 1 + 5*rand(n_e, 1);
    rv_vec(k) = toc(t0);
    t0 = tic;
    D.set_style(sv_bc, Color=rand(1, 3), MarkerSize=5 + 10*rand(1, numel(sv_bc)));
    D.set_style(sv_e, Color=rand(1, 3), LineWidth=1 + 5*rand(1, numel(sv_e)));
    rv_tag(k) = toc(t0);
end
fprintf("IEEE68 full style update (%s): vectors %.3f s, set_style %.3f s (median of 5)\n", s_dim, median(rv_vec), median(rv_tag));
assert(median(rv_vec) < 1 && median(rv_tag) < 1, ...
    sprintf("色・大きさ・太さの更新が遅い (%s: ベクトル %.3f 秒、set_style %.3f 秒)", s_dim, median(rv_vec), median(rv_tag)))
assert(isequal(D.sct_plt.NodeMain, h_node), "更新で図を作り直した")
end


%% set_position moves the drawing of GraphNetDiagram and not the model
c_before = all_parameters(net);
D = net.plot_diagram(Parent=axes(fig));
rv_comp0 = component_xy(D, 1);
D.set_position(sv_bus(1), [0.2, 0.8]);
assert(abs(D.sct_plt.XMain(1) - 0.2) < 1e-12 && abs(D.sct_plt.YMain(1) - 0.8) < 1e-12)
% 母線の機器は同じだけ動く
rv_xy0 = [D.sct_plt.XMain(1), D.sct_plt.YMain(1)];
assert(all(isfinite(rv_comp0)))
rv_comp1 = component_xy(D, 1);
D.set_position(sv_bus(1), rv_xy0 + [0.1, -0.1]);
assert(norm(component_xy(D, 1) - (rv_comp1 + [0.1, -0.1])) < 1e-12)
% 機器だけを動かす
s_com = string(net.a_Bus{1}.a_Component{1}.s_tag);
D.set_position(s_com, [0.5, 0.5]);
assert(norm(component_xy(D, 1) - [0.5, 0.5]) < 1e-12)
% モデルは変わらない
assert(isequaln(all_parameters(net), c_before), "set_position でモデルが変わった")
assert(~isempty(D.ax.Children))
% 誤り
assert(error_id(@() D.set_position(sv_br(1), [0 0])) == "GUILDA:GraphNetDiagram:PositionKind")
assert(error_id(@() D.set_position(sv_bus(1:2), [0 0])) == "GUILDA:GraphNetDiagram:PositionSize")
assert(error_id(@() D.set_position("nobus", [0 0])) == "GUILDA:GraphBase:UnknownTag")


%% set_position is an error on GraphSpring
G = GraphSpring2D(sct, Parent=axes(fig));
assert(error_id(@() G.set_position("B1", [0 0])) == "GUILDA:GraphSpringBase:PositionPhysical")
assert(contains(error_message(@() G.set_position("B1", [0 0])), "phasor"))
G3 = GraphSpring3D(sct, Parent=axes(fig));
assert(error_id(@() G3.set_position("B1", [0 0])) == "GUILDA:GraphSpringBase:PositionPhysical")


%% set_data keeps the styles by tag
G = GraphSpring2D(sct, Parent=axes(fig));
G.set_style(["B1", "G1"], Color="r", MarkerSize=20);
G.set_style("L23", Visible=false);
G.set_time(1.04);
% B2 を B9 に替え、ばね L23 を残す
s2 = sct;
s2.sv_node(2) = "B9";
s2.cm_V = s2.cm_V * 0.98;
G.set_data(s2);
assert(isequal(G.sct_data.sv_node, s2.sv_node))
assert(isequal(G.NodeColor([1 4], :), [1 0 0; 1 0 0]) && isequal(G.NodeSize([1 4]), [20; 20]))
assert(isequal(G.NodeColor(2, :), [0 0 0]) && G.NodeSize(2) == 5, "新しい節点は既定の見た目")
assert(isequal(G.EdgeVisible, [true; false; true]) && G.sct_plt.Spring(2).Visible == "off")
assert(isequal(G.sct_plt.Node(1).MarkerFaceColor, [1 0 0]))
assert(G.i_time == 11, "前に表示していた時刻の標本")
assert(abs(G.sct_plt.Node(1).XData - real(s2.cm_V(1, 11))) < 1e-12)
% ネットワーク図: 状態を差し替えても見た目が残る
D = net.plot_diagram(Parent=axes(fig), Dimension="3D");
D.set_style(sv_bus(2), Color="r");
sct_s = D.sct_state;
sct_s.rv_t = [0 1];
sct_s.cm_Vbus = sct_s.cm_Vbus .* [1 0.9];
sct_s.cm_Icomp = sct_s.cm_Icomp .* [1 1];
D.set_data(sct_s);
assert(isequal(D.rv_t, [0 1]) && isequal(D.BusColor(2, :), [1 0 0]))
assert(isequal(D.sct_plt.NodeMain(2).FaceColor, [1 0 0]))


%% link makes graphs follow set_time and unlink stops it
s_short = sct;
s_short.rv_t = rv_t * 0.5;                          % 時刻の刻みが違う図 (0 から 1 s)
G1 = GraphSpring2D(sct, Parent=axes(fig));
G2 = GraphSpring2D(s_short, Parent=axes(fig));
G3 = GraphSpring3D(sct, Parent=axes(fig));
G1.link(G2);
G2.link(G3);
G3.link(G1);                                        % 環になっても再帰しない
G1.link(G2);                                        % 二度目は何も変えない
G1.link(G1);                                        % 自分自身も何も変えない
G1.set_time(0.6);
assert(G1.i_time == 7 && G2.i_time == 13 && G3.i_time == 7, "それぞれの時刻で最も近い標本")
G2.set_time(5);                                     % リンクは対称
assert(G1.i_time == 21 && G2.i_time == 21 && G3.i_time == 21)
% unlink は両方向を外す
G1.unlink(G2);
G1.unlink(G3);
G1.set_time(0);
assert(G1.i_time == 1 && G2.i_time == 21 && G3.i_time == 21)
G3.set_time(0);
assert(G2.i_time == 1 && G1.i_time == 1)
% 削除した図は追わない
G1.link(G2);
delete(G3);
G2.set_time(1);
assert(G1.i_time == 11)
% 図を閉じた図はとばす
clf(fig);
G1 = GraphSpring2D(sct, Parent=axes(fig));
f2 = figure("Visible", "off");
G2 = GraphSpring2D(sct, Parent=axes(f2));
G1.link(G2);
close(f2);
G1.set_time(1);
assert(G1.i_time == 11)
assert(error_id(@() G2.set_time(1)) == "GUILDA:GraphBase:NoAxes")
% animate でもリンクした図が動く
G4 = net.plot_diagram(Parent=axes(fig));
G1.link(G4);
G1.animate(Speed=Inf, TimeStep=1);
assert(G1.i_time == 21 && G4.i_time == 1)



%% TimeChanged fires after set_time on linked graphs and during animate
s_short = sct;
s_short.rv_t = rv_t * 0.5;                          % 時刻の刻みが違う図 (0 から 1 s)
G1 = GraphSpring2D(sct, Parent=axes(fig));
G2 = GraphSpring2D(s_short, Parent=axes(fig));
assert(isempty(G1.TimeChangedFcn))
assert(error_id(@() set_prop(G1, "TimeChangedFcn", 3)) == "GUILDA:GraphBase:TimeFcn")
G1.link(G2);
fig.UserData = strings(0, 1);
f_log = @(s, data) set(fig, "UserData", [fig.UserData; sprintf("%s %.2f %d", s, data.Time, data.Index)]);
G1.TimeChangedFcn = @(G, data) f_log("G1", data);
G2.TimeChangedFcn = @(G, data) f_log("G2", data);
l2 = addlistener(G2, "TimeChanged", @(G, data) f_log("L2", data));
G1.set_time(0.6);
% 各図の標本の時刻と番号。図ごとにイベント、コールバックの順。リンクした図も
assert(isequal(fig.UserData, ["G1 0.60 7"; "L2 0.60 13"; "G2 0.60 13"]), strjoin(fig.UserData, ", "))
delete(l2);
% data は GraphTimeEventData。同じ標本でも set_time のたびに出る
G1.TimeChangedFcn = [];
G2.TimeChangedFcn = @(G, data) set(fig, "UserData", data);
G2.set_time(0.6);
assert(isa(fig.UserData, "GraphTimeEventData") && fig.UserData.Time == G2.rv_t(13) && fig.UserData.Index == 13)
% animate のこまごとに出る (0, 1, 2 s)
G1.TimeChangedFcn = @(G, data) f_log("G1", data);
G2.TimeChangedFcn = [];
fig.UserData = strings(0, 1);
G1.animate(Speed=Inf, TimeStep=1);
assert(isequal(fig.UserData, ["G1 0.00 1"; "G1 1.00 11"; "G1 2.00 21"]), strjoin(fig.UserData, ", "))
% コールバックからリンクした図の set_time: この set_time の図は動かさない (無限に回らない)
G1.TimeChangedFcn = @(G, data) G2.set_time(data.Time + 0.3);
G1.set_time(0.2);
assert(G1.i_time == 3 && G2.i_time == 5, "リンクした図は 0.2 s のまま")
% リンクのない図どうしで呼び合っても止まる: G1 → G3 → G1 (G1 は動かない)
G1.unlink(G2);
G3 = GraphSpring2D(sct, Parent=axes(fig));
G1.TimeChangedFcn = @(G, data) G3.set_time(data.Time + 0.1);
G3.TimeChangedFcn = @(G, data) G1.set_time(data.Time + 0.1);
G1.set_time(0);
assert(G1.i_time == 1 && G3.i_time == 2)
G3.set_time(1);                                     % 終わった後はまた動く
assert(G3.i_time == 11 && G1.i_time == 12)
% コールバックの誤りはそのまま出て、図はまた動かせる
G1.TimeChangedFcn = @(G, data) error("F46:Boom", "boom");
G3.TimeChangedFcn = [];
assert(error_id(@() G1.set_time(1.5)) == "F46:Boom")
G1.TimeChangedFcn = [];
G1.set_time(0.5);
assert(G1.i_time == 6)

%% Samples named by the data replace the time in the playback bar
% s_sampleName / sv_sampleText をデータで渡すと、再生バーの文字が標本のものになる
% (GraphChart, GraphSpring2D, GraphNetDiagram)。既定は時刻のまま。リンクも標本の値で動く
n_t = numel(rv_t);
sv_text = "Step " + (1:n_t) + " (λ = " + compose("%.3f", 0.01*(1:n_t)) + ")";
st = sct;
st.rv_t = 1:n_t;
st.s_sampleName = "Step";
st.sv_sampleText = sv_text;
p = uipanel(fig);
G = GraphSpring2D(st, Parent=p);
G.set_time(7);
assert(bar_widget(p, "TimeText").Text == sv_text(7) && bar_widget(p, "TimeSlider").Value == 7)
% 名前だけ: 名前と値。set_data で時刻に戻る
p = uipanel(fig);
C = GraphChart(struct("rv_t", 1:n_t, "s_sampleName", "Step", "sct_panel", struct("l_time", true), ...
    "sct_series", struct("rv_x", 1:n_t, "rm_y", (1:n_t)'.^2, "sv_tag", "y")), Parent=p);
C.set_time(3);
assert(bar_widget(p, "TimeText").Text == "Step 3")
C.set_data(struct("rv_t", rv_t, "sct_panel", struct("l_time", true), ...
    "sct_series", struct("rv_x", rv_t, "rm_y", rv_t'.^2, "sv_tag", "y")));
assert(startsWith(bar_widget(p, "TimeText").Text, "t = "))
% 既定 (時刻) の図は従来どおり
p = uipanel(fig);
G0 = GraphSpring2D(sct, Parent=p);
G0.set_time(0.5);
assert(bar_widget(p, "TimeText").Text == "t = 0.5 s")
% ネットワーク図: 状態の構造体で渡し、題名 (TitleFormat の代わり) と再生バーに出る
p = uipanel(fig);
D = net.plot_diagram(Parent=p);
s_state = struct("rv_t", 1:3, "cm_Vbus", repmat(D.sct_state.cm_Vbus, 1, 3), ...
    "cm_Icomp", repmat(D.sct_state.cm_Icomp, 1, 3), "s_sampleName", "Step", "sv_sampleText", ["a", "b", "c"]);
D.set_data(s_state);
D.set_time(2);
assert(bar_widget(p, "TimeText").Text == "b" && string(D.ax.Title.String) == "b")
s_state.sv_sampleText = ["a", "b"];
assert(error_id(@() D.set_data(s_state)) == "GUILDA:GraphBase:SampleLabel")


%% export_video works on GraphNetDiagram
sc = net.add_scenario("fault");
sc.add_fault("B003", [0.5, 0.55]);
res = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 1]));
D = res.plot_diagram(Parent=axes(fig), ColorMode="I");
s_file = fullfile(tempdir, "GUILDA_test_F46_graph_base.mp4");
c_file = onCleanup(@() delete_if_exists(s_file));
fig.UserData = [];
D.export_video(s_file, FrameRate=10, TimeStep=0.5, HoldTime=0, UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(numel(fig.UserData) == 3 && isfile(s_file) && dir(s_file).bytes > 0)
vr = VideoReader(s_file);
assert(vr.NumFrames == 3 && mod(vr.Width, 2) == 0 && mod(vr.Height, 2) == 0)
clear vr
% 1 時刻の図は動画にできない
D0 = net.plot_diagram(Parent=axes(fig));
assert(error_id(@() D0.export_video(s_file)) == "GUILDA:GraphBase:OneSample")
assert(error_id(@() D0.animate()) == "GUILDA:GraphBase:OneSample")



function rv = component_xy(D, i_bus)
% 母線 i_bus の最初の機器の描画上の位置 (x, y)
    h = D.sct_plt.CompMain(find(D.sct_plt.CompParentBus == i_bus, 1));
    if isprop(h, "Vertices")
        rv = mean(h.Vertices(:, 1:2), 1);
    else
        rv = [mean([min(h.XData(:)), max(h.XData(:))]), mean([min(h.YData(:)), max(h.YData(:))])];
    end
end

function r = bus_extent(D, i)
% 母線 i の立体の高さ (どの形も大きさに比例する; 棒は長さが変わらない)
    r = solid_height(D.sct_plt.NodeMain(i));
end

function r = comp_extent(D, i)
% 機器 i の立体の高さ
    r = solid_height(D.sct_plt.CompMain(i));
end

function r = solid_height(h)
% 立体の z 方向の幅
    if isprop(h, "Vertices")
        rv_z = h.Vertices(:, 3);
    else
        rv_z = h.ZData(:);
    end
    r = max(rv_z) - min(rv_z);
end

function r = tube_radius(D, i)
% ブランチ i の管の始点の断面の半径
    h = findall(D.sct_plt.EdgeMain(i), "Tag", "tube");
    rm_p = [h.XData(1, :)', h.YData(1, :)', h.ZData(1, :)'];
    r = max(vecnorm(rm_p - mean(rm_p(1:end-1, :)), 2, 2));
end

function c = all_parameters(net)
% 全母線・全機器の tab_parameter
    c = {};
    for i = 1:numel(net.a_Bus)
        c{end+1} = net.a_Bus{i}.tab_parameter; %#ok<AGROW>
        for j = 1:numel(net.a_Bus{i}.a_Component)
            c{end+1} = net.a_Bus{i}.a_Component{j}.tab_parameter; %#ok<AGROW>
        end
    end
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

function s = error_message(f)
    s = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        s = string(me.message);
    end
end

function delete_if_exists(s_file)
    if isfile(s_file)
        delete(s_file);
    end
end


function w = bar_widget(h_parent, s_name)
% 部品 s_name (Play, TimeSlider, TimeText, PlaySpeed) の再生バーの中のもの (h_parent の中に一つ)
    w = findall(h_parent, "Tag", "GUILDA:GraphBase:" + s_name);
    assert(isscalar(w), s_name + " が一つ")
end
