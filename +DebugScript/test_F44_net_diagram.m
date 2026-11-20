% F44 ネットワーク図 (GraphNetDiagram) と入口 (net.plot_diagram / res.plot_diagram)
%
%   G = net.plot_diagram(Parent=ax, <プロパティ>=...);   % 平衡点
%   G = res.plot_diagram(Parent=ax, ...);                 % ResultPF
%   G = res.plot_diagram(Parent=ax, ...);                 % ResultODE (全時刻、G.set_time(t))
%   G = GraphNetDiagram(struct(net,false), sct_state, Parent=ax, ...);
%
% 図はスナップショット struct(net,false) と状態 (rv_t, cm_Vbus, cm_Icomp) だけから作り、
% 系統を変えない (自動配置の座標も図の中だけに持つ)。既定は 2D (線と記号)、Dimension="3D" で立体。
% 2D の描き方と範囲の正規化は test_F59_diagram_2d。図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F44_net_diagram")  または  DebugScript.run_all("Features","F44")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% 座標を持たない 3 母線系統 (自動配置を通る)
[net, gen] = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);


%% Diagram does not change the model
% 自動配置しても母線・機器の tab_parameter は変わらない
c_before = all_parameters(net);
assert(any(isnan(net.a_Bus{1}.tab_parameter.graph.X)), "前提: 座標なし")
G = net.plot_diagram(Parent=axes(fig));
assert(isequaln(all_parameters(net), c_before), "plot_diagram で tab_parameter が変わった")
assert(~DebugScript.helper.is_stale(net), "plot_diagram で古い状態になった")
G.BusHeightMode = "V";
G.set_time(0);
assert(isequaln(all_parameters(net), c_before))
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
res.plot_diagram(Parent=axes(fig));
assert(isequaln(all_parameters(net), c_before))


%% Every renamed property is settable and redraws
G = net.plot_diagram(Parent=axes(fig));
n_bus = numel(net.a_Bus);
n_br  = numel(net.a_Branch);
n_com = sum(cellfun(@(b) numel(b.a_Component), net.a_Bus));
sct_set = struct( ...
    "ColorLimits", [0, 1], ...
    "Colormap", parula(16), ...
    "BranchWidthMode", "G", ...
    "BranchWidthRange", [2 5], ...
    "MarkerSizeMode", "P", ...
    "MarkerSizeRange", [3 9], ...
    "LinkWidth", 2, ...
    "BusHeightMode", "angle", ...
    "BusColorData", (1:n_bus)'/n_bus, ...
    "ComponentColorData", (1:n_com)'/n_com, ...
    "BranchColorData", (1:n_br)'/n_br, ...
    "LinkColorData", (1:n_com)'/n_com, ...
    "BusLabel", "L" + (1:n_bus)', ...
    "ComponentLabel", "C" + (1:n_com)', ...
    "BranchDirection", -ones(n_br, 1), ...
    "LinkDirection", zeros(n_com, 1), ...
    "LabelMode", "none", ...
    "LabelFontSize", 8, ...
    "LabelFontWeight", "normal", ...
    "GridSpacing", 0.1, ...
    "Dimension", "3D");
for s_name = string(fieldnames(sct_set))'
    G.(s_name) = sct_set.(s_name);
    assert(isequal(G.(s_name), sct_set.(s_name)), s_name + " が設定されない")
    assert(~isempty(G.ax.Children), s_name + " の後に図が空")
end
% 見た目が図に反映される
assert(isequal(G.ax.CLim, [0, 1]))
assert(isequal(G.ax.XTick, 0:0.1:1))
h_label = findobj(G.ax, "Type", "text", "FontSize", 8);
assert(~isempty(h_label) && all(string({h_label.Visible}) == "off"), "LabelMode none でラベルは非表示")
% Name=Value でも設定できる
G = net.plot_diagram(Parent=axes(fig), ColorMode="Q", BranchWidthMode="Y", GridSpacing=0.2);
assert(G.ColorMode == "Q" && G.BranchWidthMode == "Y" && G.GridSpacing == 0.2)
assert(isequal(G.ax.XTick, 0:0.2:1))
% ax は読み取り専用
assert(error_id(@() set_ax(G, axes(fig))) ~= "")
% 旧名は無い
assert(~isprop(G, "ColorLim") && ~isprop(G, "EdgeWidthMode") && ~isprop(G, "NodeHeightMode"))


%% Each mode value works
G = net.plot_diagram(Parent=axes(fig));
for s_mode = ["none","Loss","I","P","Q","user"]
    G.ColorMode = s_mode;
end
for s_mode = ["none","P","Q","I","G","B","Y","Ysvd"]
    G.BranchWidthMode = s_mode;
end
for s_mode = ["none","P","Q","S"]
    G.MarkerSizeMode = s_mode;
end
for s_mode = ["none","V","angle","Vimag","P","Q"]
    G.BusHeightMode = s_mode;
end
for s_mode = ["none","tag","value"]
    G.LabelMode = s_mode;
end
assert(~isempty(G.ax.Children))
% 旧い値は使えない
assert(error_id(@() set_prop(G, "ColorMode", "I (current)")) ~= "")
assert(error_id(@() set_prop(G, "BusHeightMode", "Vmag")) ~= "")
assert(error_id(@() set_prop(G, "BranchWidthMode", "SvdMaxYmat")) ~= "")
assert(error_id(@() set_prop(G, "LabelMode", "name")) ~= "")
% "user" では設定した色の値が残る
G.ColorMode = "user";
G.BranchColorData = [0.5; 1.5];
G.set_time(0);
assert(isequal(G.BranchColorData, [0.5; 1.5]), "user の値が上書きされた")
% "I" ではブランチの色は送り端の電流の大きさ
G.ColorMode = "I";
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(max(abs(G.BranchColorData - abs(res.tab_branch.Ifrom))) < 1e-6)
% "tag" のラベルは母線のタグ
G.LabelMode = "tag";
assert(isequal(G.BusLabel, string(cellfun(@(b) b.s_tag, net.a_Bus(:), "UniformOutput", false))))


%% Uninitialized or stale net stops with run net.initialize first
[net0, gen0] = DebugScript.helper.build_3bus("gen-classical");
assert(error_id(@() net0.plot_diagram(Parent=axes(fig), State="equilibrium")) == "GUILDA:PowerNetwork:DiagramStale")
DebugScript.helper.quiet(@() net0.initialize);
assert(isa(net0.plot_diagram(Parent=axes(fig)), "GraphNetDiagram"))
gen0.set_input(gen0.rv_Uequilibrium * 1.01);
assert(error_id(@() net0.plot_diagram(Parent=axes(fig), State="equilibrium")) == "GUILDA:PowerNetwork:DiagramStale")
% Parent は容器か axes
assert(error_id(@() net.plot_diagram(Parent=5)) == "GUILDA:GraphBase:ParentType")


%% ResultPF plot_diagram uses the solution
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
G = res.plot_diagram(Parent=axes(fig), LabelMode="value");
assert(isa(G, "GraphNetDiagram") && G.LabelMode == "value")
s = G.sct_state;
assert(isequal(s.rv_t, 0))
assert(max(abs(s.cm_Vbus - res.tab_bus.Vphasor)) < 1e-12)
% 機器の電流は initialize と同じ分け方 (平衡点の電流と一致する)
cv_Ieq = cell2mat(cellfun(@(b) cellfun(@(c) c.c_Iequilibrium, b.a_Component(:)), net.a_Bus(:), "UniformOutput", false));
assert(max(abs(s.cm_Icomp - cv_Ieq)) < 1e-8)
% 母線ごとの和は母線の注入電流
iv_bus = repelem((1:numel(net.a_Bus))', cellfun(@(b) numel(b.a_Component), net.a_Bus(:)));
assert(max(abs(accumarray(iv_bus, s.cm_Icomp, [numel(net.a_Bus), 1]) - res.tab_bus.Iphasor)) < 1e-8)
% スナップショットのない結果は止まる
assert(error_id(@() ResultPF().plot_diagram(Parent=axes(fig))) == "GUILDA:ResultPF:NoNetworkSnapshot")


%% set_time shows the nearest sample
sct_net = struct(net, false);
G0 = net.plot_diagram(Parent=axes(fig));
sct = G0.sct_state;
sct.rv_t     = [0, 1, 2];
sct.cm_Vbus  = sct.cm_Vbus  .* [1, 0.9, 0.8];
sct.cm_Icomp = sct.cm_Icomp .* [1, 1, 1];
G = GraphNetDiagram(sct_net, sct, Parent=axes(fig), BusHeightMode="V", LabelMode="value");
assert(G.i_time == 1)
G.set_time(1.3);
assert(G.i_time == 2)
assert(contains(string(G.ax.Title.String), "1.00"))
G.set_time(10);
assert(G.i_time == 3)
% 1 時刻のときは同じ時刻を描き直すだけ
G0.set_time(5);
assert(G0.i_time == 1 && ~isempty(G0.ax.Children))
% 状態の大きさが合わなければ止まる
sct.cm_Vbus = sct.cm_Vbus(1:2, :);
assert(error_id(@() GraphNetDiagram(sct_net, sct, Parent=axes(fig))) == "GUILDA:GraphNetDiagram:StateSize")
assert(error_id(@() GraphNetDiagram(sct_net, struct("rv_t", 0), Parent=axes(fig))) == "GUILDA:GraphNetDiagram:MissingStateField")


%% TitleFormat and ColorbarLabel set the texts and stay when the diagram is drawn again
sct_net = struct(net, false);
G0 = net.plot_diagram(Parent=axes(fig));
sct = G0.sct_state;
sct.rv_t     = [0, 1, 2];
sct.cm_Vbus  = sct.cm_Vbus  .* [1, 0.9, 0.8];
sct.cm_Icomp = sct.cm_Icomp .* [1, 1, 1];
% 既定の書式は時刻
G = GraphNetDiagram(sct_net, sct, Parent=axes(fig));
assert(G.TitleFormat == "t = %.2f s" && string(G.ax.Title.String) == "t = 0.00 s")
G.set_time(1);
assert(string(G.ax.Title.String) == "t = 1.00 s")
% 書式を変えるとすぐに書き直し、以後の時刻もその書式
G.TitleFormat = "iteration %d";
assert(string(G.ax.Title.String) == "iteration 1")
G.set_time(2);
assert(string(G.ax.Title.String) == "iteration 2")
% "" では set_time が題を書かない: 利用者の題が描き直し (BusHeightMode) をまたいで残る
G = GraphNetDiagram(sct_net, sct, Parent=axes(fig), TitleFormat="", BusHeightMode="V");
assert(string(G.ax.Title.String) == "")
title(G.ax, "my title");
G.set_time(2);
assert(string(G.ax.Title.String) == "my title")
G.Dimension = "3D";
assert(string(G.ax.Title.String) == "my title")
G.set_time(1);
assert(string(G.ax.Title.String) == "my title", "3D の高さの描き直しでも残る")
% 1 時刻の図では題を書かない
assert(string(G0.ax.Title.String) == "")
% ColorbarLabel: 作成時、変更、set_data と描き直しのあとも残る
G = GraphNetDiagram(sct_net, sct, Parent=axes(fig), ColorbarLabel="|I| [pu]");
assert(string(G.ax.Colorbar.Label.String) == "|I| [pu]")
h_cb = G.ax.Colorbar;
G.ColorbarLabel = "LMP";
assert(G.ax.Colorbar == h_cb && string(h_cb.Label.String) == "LMP", "ラベルだけを変える (描き直さない)")
G.set_data(sct);
assert(string(G.ax.Colorbar.Label.String) == "LMP")
G.BusHeightMode = "V";
G.set_time(1);
assert(string(G.ax.Colorbar.Label.String) == "LMP")

%% ResultODE plot_diagram holds every output time
sc = net.add_scenario("fault");
sc.add_fault("B003", [0.5, 0.55]);
res = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 1.5]));
G = res.plot_diagram(Parent=axes(fig), ColorMode="I");
s = G.sct_state;
n_t = numel(res.rv_t);
assert(isequal(s.rv_t, res.rv_t.'), "rv_t は結果の全時刻")
assert(isequal(size(s.cm_Vbus), [numel(net.a_Bus), n_t]))
% 機器の電流は rm_Icomponent そのもの (分け方の推定なし)
assert(isequal(s.cm_Icomp, res.rm_Icomponent(:,1:2:end).' + 1j*res.rm_Icomponent(:,2:2:end).'))
% 母線電圧は変数 Vre, Vim
k = find(res.rv_t > 0.52, 1);
V1 = res.odeResults.Bus(1).V{k,:};
assert(abs(s.cm_Vbus(1,k) - (V1(1) + 1j*V1(2))) < 1e-12)
% 最初は先頭の時刻、set_time で色が動く
assert(G.i_time == 1)
rv_c0 = G.LinkColorData;
G.set_time(0.52);
assert(G.i_time == k - 1 || G.i_time == k || G.i_time == k + 1)
assert(max(abs(G.LinkColorData - rv_c0)) > 1e-3, "地絡中は機器の電流の色が変わる")
assert(contains(string(G.ax.Title.String), "0.5"))
% 平衡点の時刻は net.plot_diagram と同じ色
G.set_time(0);
G0 = net.plot_diagram(Parent=axes(fig), ColorMode="I");
assert(max(abs(G.BranchColorData - G0.BranchColorData)) < 1e-6)


%% ResultODE plot_diagram draws a tripped unit
% B002 の発電機を解列する (test_F43 と同じ系統: B002 に負荷、B003 は定インピーダンス負荷)
netL = PowerNetwork("Test3Bus");
netL.add_bus("V", 1.00);
netL.add_bus("V", 1.02);
netL.add_bus();
netL.add_branch("pi", [1,2], "R", 0.010, "X", 0.085);
netL.add_branch("pi", [2,3], "R", 0.017, "X", 0.092);
netL.a_Bus{1}.add_component("gen-park");
genL = netL.a_Bus{2}.add_component("gen-classical", "P", 0.5, "Q", nan);
netL.a_Bus{2}.add_component("load-impedance", "P", -0.2, "Q", -0.05);
netL.a_Bus{3}.add_component("load-impedance", "P", -1.0, "Q", -0.2);
evalc("netL.a_Bus{1}.l_isSlack = true;");
DebugScript.helper.quiet(@() netL.initialize);
sc = netL.add_scenario("trip");
sc.add_trip(genL.s_tag, 0.5);
[res, flag] = DebugScript.helper.quiet(@() netL.simulate("trip", Time=[0, 1.5]));
assert(flag == 1)
G = res.plot_diagram(Parent=axes(fig), LabelMode="value", BusHeightMode="P");
sv_com = vertcat(res.c_component{:});
i_load = find(sv_com == genL.s_tag);
lv_trip = res.rv_t.' > 0.5;
assert(any(lv_trip) && all(isnan(G.sct_state.cm_Icomp(i_load, lv_trip))), "解列後は終わりまで電流が NaN")
G.set_time(0.25);
assert(isfinite(G.LinkColorData(i_load)), "解列前は色がつく")
G.set_time(0.75);
assert(isnan(G.LinkColorData(i_load)), "解列中のリンクは色なし (灰色)")
assert(all(isfinite(G.BranchColorData)), "ブランチは有限")
assert(~isempty(G.ax.Children))
G.set_time(1.5);
assert(isnan(G.LinkColorData(i_load)), "解列は終わりまで続く (再接続しない)")
% 機器の電流のない結果は止まる
assert(error_id(@() ResultODE().plot_diagram(Parent=axes(fig))) == "GUILDA:ResultODE:NoDiagramData")

%% A bar is centered at X, Y and the branches meet it on its center line
% IEEE14: B001 は中心 (0.25,0.56) 長さ 0.1 の水平の棒、B002 は (0.405,0.28) 長さ 0.13。
% 線路 1 (B001→B002) は FromOffset -0.02、ToOffset -0.045
net14 = network.IEEE14bus();
D = net14.plot_diagram(Parent=axes(fig), State="topology", Dimension="3D");
rm_v = D.sct_plt.NodeMain(1).Vertices;
assert(abs(min(rm_v(:, 1)) - 0.2) < 1e-12 && abs(max(rm_v(:, 1)) - 0.3) < 1e-12, "棒は中心から両側に Length/2")
assert(abs(mean(rm_v(:, 2)) - 0.56) < 1e-12)
assert(max(abs(D.sct_plt.EdgePath{1}(1, 1:2) - [0.23, 0.56])) < 1e-12, "From の接続は X + FromOffset、中心線の上")
assert(max(abs(D.sct_plt.EdgePath{1}(end, 1:2) - [0.36, 0.28])) < 1e-12, "To の接続は X + ToOffset")
% 機器: 位置は母線の中心 + (DX, DY)、接続線は Path (相対) を通り Offset で棒につながる
tab = D.tab_element;
i_load = tab.Index(tab.Kind == "component" & startsWith(tab.Tag, "B002") & contains(tab.Tag, "LPQ"));
rm_c = D.sct_plt.CompPath{i_load};
assert(max(abs(rm_c(1, 1:2) - [0.31, 0.25])) < 1e-12 && max(abs(rm_c(2, 1:2) - [0.36, 0.25])) < 1e-12)
assert(max(abs(rm_c(end, 1:2) - [0.36, 0.28])) < 1e-12)
% NaN のオフセット: 最初・最後の折れ点を棒の範囲に押し込んだ中心線の上の点
net14.a_Branch{1}.tab_parameter.graph.FromOffset = NaN;
net14.a_Branch{1}.tab_parameter.graph.ToOffset   = NaN;
net14.a_Branch{1}.tab_parameter.graph.Path = "0.1 0.5; 0.6 0.3";
net14.a_Branch{2}.tab_parameter.graph.FromOffset = NaN;
net14.a_Branch{2}.tab_parameter.graph.Path = "";
net14.a_Branch{3}.tab_parameter.graph.FromOffset = 1;      % 棒の長さの半分を超える: 端に押し込む
D = net14.plot_diagram(Parent=axes(fig), State="topology");
assert(max(abs(D.sct_plt.EdgePath{1}(1, 1:2) - [0.2, 0.56])) < 1e-12, "x = 0.1 は棒の左端 0.2 に")
assert(max(abs(D.sct_plt.EdgePath{1}(end, 1:2) - [0.47, 0.28])) < 1e-12, "x = 0.6 は棒の右端 0.47 に")
assert(max(abs(D.sct_plt.EdgePath{2}(1, 1:2) - [0.25, 0.56])) < 1e-12, "折れ点なし: 中心")
assert(max(abs(D.sct_plt.EdgePath{3}(1, 1:2) - [0.47, 0.28])) < 1e-12, "オフセットは棒の端まで")


%% Style transformer draws the symbol at the From end
% 3D: 2 つの球 (2D の 2 つの円は test_F59_diagram_2d)
net14 = network.IEEE14bus();
D = net14.plot_diagram(Parent=axes(fig), State="topology", Dimension="3D");
i_tr = find(arrayfun(@(b) b{1}.tab_parameter.graph.Style == "transformer", net14.a_Branch), 1);
h_tr = D.sct_plt.EdgeMain(i_tr);
assert(isa(h_tr, "matlab.graphics.primitive.Group"), "変圧器は管と球のグループ")
hv_s = findall(h_tr, "Type", "surface", "-not", "Tag", "tube");
assert(numel(hv_s) == 2, "球が 2 つ")
rm_p = D.sct_plt.EdgePath{i_tr};
for h = hv_s'
    rv_c = [mean(h.XData(:)), mean(h.YData(:)), mean(h.ZData(:))];
    assert(norm(rv_c - rm_p(1, :)) < norm(rv_c - rm_p(end, :)), "記号は From 端の近く")
end
assert(D.sct_plt.EdgeMain(1).Tag == "tube", "line は管だけ")


%% Moving a bus moves its components
net14 = network.IEEE14bus();
D = net14.plot_diagram(Parent=axes(fig), State="topology");
tab = D.tab_element;
i_load = tab.Index(tab.Kind == "component" & startsWith(tab.Tag, "B002") & contains(tab.Tag, "LPQ"));
L0 = D.get_layout();
D.set_position("B002", [0.5, 0.1]);
rm_c = D.sct_plt.CompPath{i_load};
assert(max(abs(rm_c(1, 1:2) - [0.405, 0.07])) < 1e-12, "機器は母線と同じだけ動く")
assert(max(abs(rm_c(2, 1:2) - [0.455, 0.07])) < 1e-12, "接続線の折れ点も動く")
assert(max(abs(rm_c(end, 1:2) - [0.455, 0.1])) < 1e-12)
L1 = D.get_layout();
assert(isequal(L1.tab_component, L0.tab_component), "機器の DX, DY は変わらない")
assert(isequal(L1.tab_bus{2, ["X","Y"]}, [0.5, 0.1]))
% 機器を動かすと母線からの相対位置になる
s_load = tab.Tag(tab.Kind == "component" & tab.Index == i_load);
D.set_position(s_load, [0.6, 0.2]);
L2 = D.get_layout();
assert(max(abs(L2.tab_component{L2.tab_component.Tag == s_load, ["DX","DY"]} - [0.1, 0.1])) < 1e-12)


%% net.set_layout(G.get_layout()) writes only the positions
% 座標のない 3 母線: 自動配置の位置を明示的にモデルへ保存する
L_model = net.get_layout();
G = net.plot_diagram(Parent=axes(fig));
L = G.get_layout();
assert(isequal(string(fieldnames(L))', ["tab_bus", "tab_component"]))
assert(isequal(string(L.tab_bus.Properties.VariableNames), ["Tag", "X", "Y"]))
assert(isequal(string(L.tab_component.Properties.VariableNames), ["Tag", "DX", "DY"]))
assert(all(isfinite(L.tab_bus{:, ["X","Y"]}), "all") && all(isfinite(L.tab_component{:, ["DX","DY"]}), "all"))
assert(all(isnan(L_model.tab_bus.X)), "図はモデルに書かない")
net.set_layout(L);
L_new = net.get_layout();
assert(isequal(L_new.tab_bus{:, ["X","Y"]}, L.tab_bus{:, ["X","Y"]}))
assert(isequal(L_new.tab_component{:, ["DX","DY"]}, L.tab_component{:, ["DX","DY"]}))
assert(isequaln(removevars(L_new.tab_bus, ["X","Y"]), removevars(L_model.tab_bus, ["X","Y"])), "ほかの列は変わらない")
assert(isequaln(L_new.tab_branch, L_model.tab_branch))
assert(isequaln(removevars(L_new.tab_component, ["DX","DY"]), removevars(L_model.tab_component, ["DX","DY"])))
% 保存した位置で描き直すと同じ図
G2 = net.plot_diagram(Parent=axes(fig));
assert(isequal(G2.get_layout(), L))
% 位置を持たない図は GraphBase の既定のエラー
G3 = DebugScript.helper.quiet(@() net.calculate_powerflow()).plot_voltage(Parent=fig);
assert(error_id(@() G3.get_layout()) == "GUILDA:GraphBase:PositionNotSupported")


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

function set_ax(G, ax)
    G.ax = ax;
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
