% F53 座標のない母線の自動配置 (tools.layout_place_buses、notes/graph-layout.md §4.7)
%
%   [rm_xy, d0] = tools.layout_place_buses(rm_xy, im_edge, Length=, Path=, Iteration=, StepSize=)
%   G = net.plot_diagram();  G.get_layout();  res.plot_network();
%
% 座標のある母線は決して動かず (isequal)、新しい母線は隣の近くに決定的に置く。全母線に座標が
% ないときだけ "force"。自動の位置は図の中だけにあり、net.set_layout(G.get_layout()) で保存する。
% 図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F53_layout_placement")  または  DebugScript.run_all("Features","F53")

fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
net14 = network.IEEE14bus();
L14   = net14.get_layout();
rm_14 = L14.tab_bus{:, ["X","Y"]};
im_14 = edges(net14);
[~, d0] = tools.layout_place_buses(rm_14, im_14);
rv_len14 = signed_length(L14.tab_bus);
% 元の外接箱 (棒は両端)
rm_end = [rm_14 - [max(rv_len14, 0), -min(rv_len14, 0)]/2; rm_14 + [max(rv_len14, 0), -min(rv_len14, 0)]/2];
rm_end(isnan(rm_end)) = 0;
rm_end = [rm_end; rm_14];


%% A bus connected to B014 is placed near it and the other buses stay
net = network.IEEE14bus();
net.add_bus();
net.add_branch("pi", [14, 15], "R", 0.01, "X", 0.1);
G = net.plot_diagram(Parent=axes(fig), State="topology");
L = G.get_layout();
assert(isequal(L.tab_bus{1:14, ["X","Y"]}, rm_14), "座標のある母線は動かない")
p = L.tab_bus{15, ["X","Y"]};
assert(L.tab_bus.Tag(15) == "B015" && all(isfinite(p)))
r = norm(p - rm_14(14, :));
assert(r >= 0.5*d0 && r <= 2*d0, "B014 との距離 %.3g (d0 = %.3g)", r, d0)
assert(min(vecnorm(rm_14(1:13, :) - p, 2, 2)) >= 0.25*d0, "ほかの母線から離れる")


%% A bus connected to B013 and B014 lies between them, off their line
rm = [rm_14; NaN NaN];
im = [im_14; 13 15; 14 15];
rm = tools.layout_place_buses(rm, im, Length=[rv_len14; NaN]);
p = rm(15, :);
assert(norm(p - mean(rm_14([13 14], :), 1)) <= d0, "2 つの重心から d0 以内")
assert(point_segment(p, rm_14(13, :), rm_14(14, :)) >= 0.1*d0, "線分 B013-B014 から離れる")


%% A bus without a branch goes right of the bounding box
rm = tools.layout_place_buses([rm_14; NaN NaN], im_14, Length=[rv_len14; NaN]);
assert(isequal(rm(1:14, :), rm_14))
assert(rm(15, 1) > max(rm_end(:, 1)) && rm(15, 2) <= max(rm_end(:, 2)))


%% A chain of two new buses is placed in breadth-first order
rm = tools.layout_place_buses([rm_14; NaN NaN; NaN NaN], [im_14; 15 14; 16 15], Length=[rv_len14; NaN; NaN]);
assert(isequal(rm(1:14, :), rm_14))
r15 = norm(rm(15, :) - rm_14(14, :));
r16 = norm(rm(16, :) - rm(15, :));
assert(r15 >= 0.5*d0 && r15 <= 2*d0 && r16 >= 0.5*d0 && r16 <= 2*d0, "隣との距離 %.3g, %.3g", r15, r16)
% 手順 1 だけ (Iteration=0): B015 は B014 から、B016 は置いた B015 から 0.5*d0 の候補点
rm0 = tools.layout_place_buses([rm_14; NaN NaN; NaN NaN], [im_14; 15 14; 16 15], Length=[rv_len14; NaN; NaN], Iteration=0);
assert(abs(norm(rm0(15, :) - rm_14(14, :)) - 0.5*d0) < 1e-12 && abs(norm(rm0(16, :) - rm0(15, :)) - 0.5*d0) < 1e-12, "順は B015、B016")
for i = 15:16
    rv_d = vecnorm(rm - rm(i, :), 2, 2);
    rv_d(i) = Inf;
    assert(min(rv_d) >= 0.25*d0, "B%03d はほかの母線から離れる", i)
end


%% The placement is deterministic, keeps full input and lays out an empty one
rm_in = [rm_14; NaN NaN; NaN NaN];
im    = [im_14; 15 14; 16 15];
c_path = cell(size(im, 1), 1);
c_path(:) = {zeros(0, 2)};
c_path{1} = tools.layout_parse_path(net14.a_Branch{1}.tab_parameter.graph.Path);
rm1 = tools.layout_place_buses(rm_in, im, Length=[rv_len14; NaN; NaN], Path=c_path);
rm2 = tools.layout_place_buses(rm_in, im, Length=[rv_len14; NaN; NaN], Path=c_path);
assert(isequal(rm1, rm2), "同じ入力なら同じ出力")
assert(isequal(tools.layout_place_buses(rm_14, im_14), rm_14), "全母線に座標があればそのまま")
rm_force = tools.layout_place_buses(nan(14, 2), im_14);
assert(isequal(size(rm_force), [14 2]) && all(isfinite(rm_force), "all"), "全母線に座標がなければ force")
assert(isequal(size(tools.layout_place_buses(zeros(0, 2), zeros(0, 2))), [0 2]))


%% The model keeps NaN, get_layout saves the placement and the map agrees
net = network.IEEE14bus();
net.add_bus();
net.add_branch("pi", [14, 15], "R", 0.01, "X", 0.1);
G = net.plot_diagram(Parent=axes(fig), State="topology");
assert(all(isnan([net.a_Bus{15}.tab_parameter.graph.X, net.a_Bus{15}.tab_parameter.graph.Y])), "図はモデルに書かない")
L = G.get_layout();
assert(all(isfinite(L.tab_bus{:, ["X","Y"]}), "all"))
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
M = res.plot_network(Parent=axes(fig));
LM = M.get_layout();
assert(max(abs(LM.tab_bus{:, ["X","Y"]} - L.tab_bus{:, ["X","Y"]}), [], "all") < 1e-12, "GraphNetMap も同じ位置")
net.set_layout(L);
assert(isequal([net.a_Bus{15}.tab_parameter.graph.X, net.a_Bus{15}.tab_parameter.graph.Y], L.tab_bus{15, ["X","Y"]}))


function im = edges(net)
% ブランチの from・to 母線の番号 (n_branch x 2)
    sv_bus = string(cellfun(@(b) b.s_tag, net.a_Bus, "UniformOutput", false));
    im = zeros(numel(net.a_Branch), 2);
    for k = 1:numel(net.a_Branch)
        im(k, :) = [find(sv_bus == net.a_Branch{k}.a_Bus{1}.s_tag), find(sv_bus == net.a_Branch{k}.a_Bus{2}.s_tag)];
    end
end

function rv = signed_length(tab_bus)
% 棒の長さ (水平は正、縦は負、点は NaN)
    rv = nan(height(tab_bus), 1);
    rv(tab_bus.Shape == "hbar") =  tab_bus.Length(tab_bus.Shape == "hbar");
    rv(tab_bus.Shape == "vbar") = -tab_bus.Length(tab_bus.Shape == "vbar");
end

function s = point_segment(p, a, b)
% 点 p と線分 [a, b] の距離
    t = min(max(dot(p - a, b - a) / dot(b - a, b - a), 0), 1);
    s = norm(p - (a + t*(b - a)));
end
