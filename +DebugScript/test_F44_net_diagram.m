% F44 3D ネットワーク図 (DrawerNetDiagram) と入口 (net.plot_diagram / res.plot_diagram)
%
%   G = net.plot_diagram(Parent=ax, <プロパティ>=...);   % 平衡点
%   G = res.plot_diagram(Parent=ax, ...);                 % ResultPF
%   G = DrawerNetDiagram(struct(net,false), sct_state, Parent=ax, ...);
%
% 図はスナップショット struct(net,false) と状態 (rv_t, cm_Vbus, cm_Icomp) だけから作り、
% 系統を変えない (自動配置の座標も図の中だけに持つ)。図はすべて見えない figure に描く。
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
assert(any(isnan(net.a_Bus{1}.tab_parameter.graph.Xaxis)), "前提: 座標なし")
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
    "BranchWidthScale", 0.3, ...
    "BranchWidthOffset", 2, ...
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
    "MarkerSize", 12);
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
for s_mode = ["none","G","B","Y","Ysvd"]
    G.BranchWidthMode = s_mode;
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
assert(error_id(@() net0.plot_diagram(Parent=axes(fig))) == "GUILDA:PowerNetwork:DiagramStale")
DebugScript.helper.quiet(@() net0.initialize);
assert(isa(net0.plot_diagram(Parent=axes(fig)), "DrawerNetDiagram"))
gen0.set_input(gen0.rv_Uequilibrium * 1.01);
assert(error_id(@() net0.plot_diagram(Parent=axes(fig))) == "GUILDA:PowerNetwork:DiagramStale")
% Parent は axes
assert(error_id(@() net.plot_diagram(Parent=fig)) == "GUILDA:DrawerNetDiagram:ParentNotAxes")


%% ResultPF plot_diagram uses the solution
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
G = res.plot_diagram(Parent=axes(fig), LabelMode="value");
assert(isa(G, "DrawerNetDiagram") && G.LabelMode == "value")
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
G = DrawerNetDiagram(sct_net, sct, Parent=axes(fig), BusHeightMode="V", LabelMode="value");
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
assert(error_id(@() DrawerNetDiagram(sct_net, sct, Parent=axes(fig))) == "GUILDA:DrawerNetDiagram:StateSize")
assert(error_id(@() DrawerNetDiagram(sct_net, struct("rv_t", 0), Parent=axes(fig))) == "GUILDA:DrawerNetDiagram:MissingStateField")


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
