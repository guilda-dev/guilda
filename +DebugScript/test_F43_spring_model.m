% F43 ばね質点モデルの図の入口 (plot_spring_model)
%
%   G = net.plot_spring_model(Dimension=2|3);   % 平衡点
%   G = res.plot_spring_model(...);             % ResultODE (全時刻、アニメーション可)
%   G = res.plot_spring_model(...);             % ResultPF (母線だけ)
%
% 3 つの入口は共通の tools.spring_model_data で GraphSpring のデータを作る。
% ノード: 全母線 + 自身のノードを持つ機器 (get_spring_node の cv_E が空でない)。
% 矢印: 自身のノードごとに 1 組、自身のノードを持たない機器のある母線ごとに 1 組
% (母線注入電流 − 自身のノードを持つ機器の電流)。図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F43_spring_model")  または  DebugScript.run_all("Features","F43")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% B001: gen-park (スラック)、B002: gen-classical + 負荷、B003: 負荷
% (定インピーダンス負荷: 定電力負荷では B003 の地絡で解けなくなるため)
net = PowerNetwork("Test3Bus");
net.add_bus("V", 1.00);
net.add_bus("V", 1.02);
net.add_bus();
net.add_branch("pi", [1,2], "R", 0.010, "X", 0.085);
net.add_branch("pi", [2,3], "R", 0.017, "X", 0.092);
net.a_Bus{1}.add_component("gen-park");
gen   = net.a_Bus{2}.add_component("gen-classical", "P", 0.5, "Q", nan);
load2 = net.a_Bus{2}.add_component("load-impedance", "P", -0.2, "Q", -0.05);
net.a_Bus{3}.add_component("load-impedance", "P", -1.0, "Q", -0.2);
evalc("net.a_Bus{1}.l_isSlack = true;");     % スラック母線 (自動では選ばれない)。INFO は抑制
DebugScript.helper.quiet(@() net.initialize);


%% net 2D and 3D pictures hold the buses, the own nodes and the arrows
G = net.plot_spring_model(Parent=axes(fig));
assert(isa(G, "GraphSpring2D"))
s = G.sct_data;
assert(isequal(s.sv_node, ["B001"; "B002"; "B003"; "B001SG1"; gen.s_tag]), "母線 3 + 発電機の自身のノード 2")
assert(isequal(s.sv_kind, ["bus"; "bus"; "bus"; "component"; "component"]))
assert(isequal(s.rv_t, 0) && size(s.cm_V, 2) == 1)
% ばね: ブランチ 2 本 + 母線と自身のノード 2 本
assert(isequal(s.im_edge, [1 2; 2 3; 1 4; 2 5]'))
assert(isequal(s.sv_edge, ["EL001"; "EL002"; "B001SG1"; gen.s_tag]))
% 矢印: 自身のノード 2 組 + 自身のノードを持たない機器 (負荷) のある母線 B002, B003
assert(isequal(sort(s.iv_arrow), [2; 3; 4; 5]))
% 母線は平衡点の電圧
assert(max(abs(s.cm_V(1:3) - cellfun(@(b) b.c_Vequilibrium, net.a_Bus(:)))) < 1e-12)
% 自身のノードは get_spring_node の E (平衡点の x, V, u)
V2 = net.a_Bus{2}.c_Vequilibrium;
p  = gen.tab_parameter.dynamics{:, gen.sv_para};
E  = gen.get_spring_node(gen.rv_Xequilibrium, [real(V2); imag(V2)], zeros(2,1), gen.rv_Uequilibrium, p);
assert(abs(s.cm_V(5) - E) < 1e-12)
% 1 時刻では |E| の円は描かない
assert(all(isnan(s.rv_circle)))

clf(fig);
G3 = net.plot_spring_model(Dimension=3, Parent=axes(fig));
assert(isa(G3, "GraphSpring3D") && isequal(G3.sct_data.sv_node, s.sv_node))
% Dimension は 2 か 3
assert(error_id(@() net.plot_spring_model(Dimension=4, Parent=axes(fig))) ~= "")


%% Uninitialized or stale net stops with run net.initialize first
% (共有の net は変えず、別の系統で確かめる)
[net0, gen0] = DebugScript.helper.build_3bus("gen-classical");
assert(error_id(@() net0.plot_spring_model(Parent=axes(fig))) == "GUILDA:PowerNetwork:SpringModelStale")
DebugScript.helper.quiet(@() net0.initialize);
G = net0.plot_spring_model(Parent=axes(fig));
assert(isa(G, "GraphSpring2D"))
% 初期化後の編集 (入力の変更) でも止まる
gen0.set_input(gen0.rv_Uequilibrium * 1.01);
assert(error_id(@() net0.plot_spring_model(Parent=axes(fig))) == "GUILDA:PowerNetwork:SpringModelStale")


%% Simulation result animates with every output time
sc = net.add_scenario("fault");
sc.add_fault("B003", [0.5, 0.55]);
res = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 1.5]));
G = res.plot_spring_model(Parent=axes(fig));
s = G.sct_data;
assert(isequal(s.rv_t, res.rv_t.'), "rv_t は結果の全時刻")
assert(size(s.cm_V, 2) == numel(res.rv_t) && size(s.rm_P, 2) == numel(res.rv_t))
G.animate(Speed=Inf, TimeStep=0.25);
assert(G.sct_data.rv_t(G.i_time) == res.rv_t(end), "アニメーションは最後の時刻で終わる")
G.set_time(1);
assert(abs(G.sct_data.rv_t(G.i_time) - 1) < 0.05)
clf(fig);
G3 = res.plot_spring_model(Dimension=3, Parent=axes(fig));
assert(isa(G3, "GraphSpring3D"))
G3.set_time(0.52);


%% Own node of a classical generator equals Vfield e^jdelta
sc = net.add_scenario("fault");
sc.add_fault("B003", [0.5, 0.55]);
res = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 1.5]));
G = res.plot_spring_model(Parent=axes(fig));
s = G.sct_data;
i_node = find(s.sv_node == gen.s_tag);
k  = find(res.rv_t >= 1, 1);
r  = res.odeResults;
X  = r.Bus(2).Component(1).X;
U  = r.Bus(2).Component(1).U;
E1 = U.Vfield(k) .* exp(1j*X.delta(k));
assert(abs(s.cm_V(i_node, k) - E1) < 1e-12, "t = 1 の自身のノードは Vfield·e^{jδ}")
% AVR のない classical は |E| = Vfield が一定なので円を描く。park は描かない
assert(abs(s.rv_circle(i_node) - U.Vfield(1)) < 1e-9)
assert(isnan(s.rv_circle(s.sv_node == "B001SG1")))


%% Remaining current at a bus equals the load current
G = net.plot_spring_model(Parent=axes(fig));
s = G.sct_data;
% B002 は発電機と負荷: 矢印の電流 = 母線注入 − 発電機の電流 = 負荷の電流
V2 = net.a_Bus{2}.c_Vequilibrium;
I_load = load2.c_Iequilibrium;
S = V2 * conj(I_load);
i_arrow = find(s.iv_arrow == 2);
assert(abs(s.rm_P(i_arrow)  - real(S)) < 1e-9)
assert(abs(s.rm_Iq(i_arrow) - imag(S)/abs(V2)) < 1e-9)
% B003 は負荷だけ: 母線注入電流そのもの
V3 = net.a_Bus{3}.c_Vequilibrium;
S3 = V3 * conj(net.a_Bus{3}.c_Iequilibrium);
i_arrow = find(s.iv_arrow == 3);
assert(abs(s.rm_P(i_arrow) - real(S3)) < 1e-9 && s.rm_P(i_arrow) < 0)


%% Tripped unit is NaN and the picture still draws
sc = net.add_scenario("trip");
sc.add_trip(gen.s_tag, 0.5);
res = DebugScript.helper.quiet(@() net.simulate("trip", Time=[0, 1.5]));
G = res.plot_spring_model(Parent=axes(fig));
s = G.sct_data;
i_node = find(s.sv_node == gen.s_tag);
lv_trip = res.rv_t.' > 0.55 & res.rv_t.' < 0.95;
assert(any(lv_trip) && all(isnan(s.cm_V(i_node, lv_trip))), "トリップ中の自身のノードは NaN")
assert(all(isfinite(s.cm_V(1:3, :)), "all"), "母線は常に有限")
% トリップ中の B002 の矢印は発電機の電流を 0 として数える (有限)
assert(all(isfinite(s.rm_P(s.iv_arrow == 2, :))))
G.set_time(0.75);
clf(fig);
G3 = res.plot_spring_model(Dimension=3, Parent=axes(fig));
G3.set_time(0.75);


%% Power flow result shows the buses only
pf = DebugScript.helper.quiet(@() net.calculate_powerflow());
G = pf.plot_spring_model(Parent=axes(fig));
s = G.sct_data;
assert(isequal(s.sv_node, ["B001"; "B002"; "B003"]) && all(s.sv_kind == "bus"))
assert(isequal(s.iv_arrow, [1; 2; 3]), "機器のある母線ごとに 1 組")
assert(max(abs(s.cm_V - pf.tab_bus.Vphasor)) < 1e-12)
S = pf.tab_bus.Vphasor .* conj(pf.tab_bus.Iphasor);
assert(max(abs(s.rm_P - real(S))) < 1e-12)
clf(fig);
G3 = pf.plot_spring_model(Dimension=3, Parent=axes(fig));
assert(isa(G3, "GraphSpring3D"))


%% Graph Color and MarkerSize are carried into the picture
net.a_Bus{3}.tab_parameter.graph.Color      = "red";
net.a_Bus{3}.tab_parameter.graph.MarkerSize = 12;
gen.tab_parameter.graph.Color      = "#00AA00";
gen.tab_parameter.graph.MarkerSize = 20;
gen.tab_parameter.graph.Shape      = "v";
G = net.plot_spring_model(Parent=axes(fig));
s = G.sct_data;
% (見た目は要素ごとのベクトルのプロパティに入る)
assert(isequal(G.NodeColor(3, :), [1 0 0]) && G.NodeSize(3) == 12)
i_node = find(s.sv_node == gen.s_tag);
assert(max(abs(G.NodeColor(i_node, :) - [0 170/255 0])) < 1e-12 && G.NodeSize(i_node) == 20 && G.NodeMarker(i_node) == "v")
% 未設定は既定 (母線 5、機器 15)
assert(G.NodeSize(1) == 5 && G.NodeSize(s.sv_node == "B001SG1") == 15)


%% Bus shapes map to GraphSpring markers
% "circle" は "o" (MATLAB のマーカーに "circle" はない)、"square" は "s"、
% 棒 ("hbar"、"vbar") は既定の "o"、ほかの点の形はそのまま
net.a_Bus{1}.tab_parameter.graph.Shape = "circle";
net.a_Bus{2}.tab_parameter.graph.Shape = "square";
net.a_Bus{3}.tab_parameter.graph.Shape = "^";
G = net.plot_spring_model(Parent=axes(fig));
assert(isequal(G.NodeMarker(1:3), ["o"; "s"; "^"]))
net.a_Bus{3}.tab_parameter.graph.Shape = "none";
G = net.plot_spring_model(Parent=axes(fig));
assert(G.NodeMarker(3) == "none")
net.a_Bus{1}.tab_parameter.graph.Length = 0.1;
net.a_Bus{1}.tab_parameter.graph.Shape  = "hbar";
net.a_Bus{2}.tab_parameter.graph.Length = 0.1;
net.a_Bus{2}.tab_parameter.graph.Shape  = "vbar";
G = net.plot_spring_model(Parent=axes(fig));
assert(isequal(G.NodeMarker(1:2), ["o"; "o"]), "棒の母線は既定の o")
clf(fig);
G3 = net.plot_spring_model(Dimension=3, Parent=axes(fig));
assert(isequal(G3.NodeMarker(1:2), ["o"; "o"]))


%% Positions of a spring model are not a layout
G = net.plot_spring_model(Parent=axes(fig));
assert(error_id(@() G.get_layout()) == "GUILDA:GraphSpringBase:PositionPhysical")
clf(fig);
G3 = net.plot_spring_model(Dimension=3, Parent=axes(fig));
assert(error_id(@() G3.get_layout()) == "GUILDA:GraphSpringBase:PositionPhysical")


%% IEEE14 with bus bars draws in 2D and 3D
net14 = network.IEEE14bus();
DebugScript.helper.quiet(@() net14.initialize);
sv_shape = cellfun(@(b) string(b.tab_parameter.graph.Shape), net14.a_Bus(:));
assert(any(ismember(sv_shape, ["hbar", "vbar"])), "IEEE14 は棒の母線を持つ")
clf(fig);
G = net14.plot_spring_model(Parent=axes(fig));
l_bar = ismember(sv_shape, ["hbar", "vbar"]);
assert(all(G.NodeMarker(l_bar) == "o"), "棒の母線は o")
clf(fig);
G3 = net14.plot_spring_model(Dimension=3, Parent=axes(fig));
assert(isa(G3, "GraphSpring3D"))
pf14 = DebugScript.helper.quiet(@() net14.calculate_powerflow());
clf(fig);
G = pf14.plot_spring_model(Parent=axes(fig));
assert(all(G.NodeMarker(l_bar) == "o"))
clf(fig);
pf14.plot_spring_model(Dimension=3, Parent=axes(fig));
sc14 = net14.add_scenario("fault");
sc14.add_fault(net14.a_Bus{2}.s_tag, [0.1, 0.15]);
res14 = DebugScript.helper.quiet(@() net14.simulate("fault", Time=[0, 0.5]));
clf(fig);
G = res14.plot_spring_model(Parent=axes(fig));
G.set_time(0.3);
clf(fig);
G3 = res14.plot_spring_model(Dimension=3, Parent=axes(fig));
G3.set_time(0.3);


%% A bus at zero voltage during a fault draws nothing outside the 3D axes
% IEEE 9 母線系統で母線 7 に地絡: 事故中 (t = 1.1 s) の母線 7 は |V| = 0。2 つ並べた 3D の図で、
% 低い電圧の母線の矢じり (ほぼ真横から見た細い三角形) の辺が軸の外へ長い細線として描かれていた。
% 書き出した画像の大きさは事故の前と同じ (線が外へ出ると画像が大きくなる)
net9 = network.IEEE9bus();
sc9  = net9.add_scenario("fault");
sc9.add_fault("B007", [1, 1.15]);
res9 = DebugScript.helper.quiet(@() net9.simulate("fault", Time=[0, 3]));
fig.Position = [0 0 560 420];
layout = tiledlayout(fig, 1, 2, TileSpacing="compact", Padding="compact");
G0 = res9.plot_spring_model(Dimension=3, Parent=nexttile(layout));
G3 = res9.plot_spring_model(Dimension=3, Parent=nexttile(layout));
G0.ShowLegend = false;
G3.ShowLegend = false;
G3.RotationScale = 0;
G3.set_time(1.1);
assert(abs(G3.sct_data.cm_V(7, G3.i_time)) == 0, "事故中の母線 7 は |V| = 0")
rm_lim = [G3.ax.XLim; G3.ax.YLim; G3.ax.ZLim];
assert(all(isfinite(rm_lim(:))))
sv_xyz = ["XData", "YData", "ZData"];
for h = findobj(G3.ax, "-property", "ZData")'
    for j = 1:3
        rv = h.(sv_xyz(j))(:);
        assert(~any(isinf(rv)))
        rv = rv(~isnan(rv));
        assert(all(rv >= rm_lim(j, 1) - 1e-12 & rv <= rm_lim(j, 2) + 1e-12), class(h) + " が軸の外")
    end
end
s_png = [tempname, '.png'];
c_png = onCleanup(@() delete(s_png));
G3.set_time(0);
exportgraphics(fig, s_png);
n_before = size(imread(s_png), 1);
for t = [1.02 1.05 1.1]
    G3.set_time(t);
    exportgraphics(fig, s_png);
    assert(size(imread(s_png), 1) == n_before, "t = " + t + " の図に軸の外の線がない")
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
