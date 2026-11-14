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
% B001: gen-park (slack)、B002: gen-classical + 負荷、B003: 負荷
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
evalc("net.a_Bus{1}.l_isSlack = true;");   % スラック母線は利用者が設定する
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
sc.add_trip(gen.s_tag, [0.5, 1]);
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
gen.tab_parameter.graph.Marker     = "v";
G = net.plot_spring_model(Parent=axes(fig));
s = G.sct_data;
assert(s.sv_color(3) == "red" && s.rv_size(3) == 12)
assert(isequal(s.rm_color(3, :), [1 0 0]))
i_node = find(s.sv_node == gen.s_tag);
assert(s.sv_color(i_node) == "#00AA00" && s.rv_size(i_node) == 20 && s.sv_marker(i_node) == "v")
% 未設定は既定 (母線 5、機器 15)
assert(s.rv_size(1) == 5 && s.rv_size(s.sv_node == "B001SG1") == 15)



function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
