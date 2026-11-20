% F82 行と列に変数名をもつ行列の図 (GraphMatrix)
%
%   G = GraphMatrix(sct, Parent=..., Display=, ColorLimits=, Tolerance=);
%   sct.c_matrix, sct.rv_t, sct.sv_rowName, sct.sv_colName, sct.sv_rowGroup, sct.sv_colGroup,
%   sct.s_title, sct.s_rowLabel, sct.s_colLabel
%   G.Display = "pattern" | "magnitude" | "value";  G.ColorLimits;  G.Tolerance
%   G.SeparatorColor / SeparatorLineWidth;  G.set_style(tag, Color=, LineWidth=);  G.select(tag)
%   G.set_time(t);  G.show_controls();  G.animate();  再生バー (2 標本以上)
%
% 要素は行のグループ ("rowgroup") と列のグループ ("colgroup")。表示の種類ごとの描画、許容値、
% 色の範囲、時刻、選択と見た目、空の行列と標本 1 つ、目盛りの間引き、データチップを確かめる。
% 図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F82_graph_matrix")  または  DebugScript.run_all("Features","F82")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% 3 x 4 の行列を 2 標本。行のグループは G1, B1, G1 (G1 は離れた 2 つのブロック)
sct = struct();
sct.rv_t        = [0 0.5];
sct.c_matrix    = {sparse([1 0 -2e-3 0; 0 3 0 1e-9; -40 0 0 5]), sparse([2 0 0 0; 0 -3 0 0; 0 0 100 5])};
sct.sv_rowName  = ["delta"; "V"; "omega"];
sct.sv_colName  = ["delta"; "omega"; "Vr"; "Vi"];
sct.sv_rowGroup = ["G1"; "B1"; "G1"];
sct.sv_colGroup = ["G1"; "G1"; "B1"; "B1"];
sct.s_title     = "J";
sct.s_rowLabel  = "equation";
sct.s_colLabel  = "variable";


%% The data gives the groups as elements and wrong data stops with its field
G = GraphMatrix(sct, Parent=fig);
tab = G.tab_element;
assert(isequal(tab.Tag, ["G1"; "B1"; "G1"; "B1"]))
assert(isequal(tab.Kind, ["rowgroup"; "rowgroup"; "colgroup"; "colgroup"]))
assert(isequal(tab.Index, (1:4)'))
assert(isequal(G.rv_t, [0 0.5]) && G.Display == "pattern" && isequaln(G.ColorLimits, [NaN NaN]))
assert(isequal(string(G.ax.YTickLabel), sct.sv_rowName) && isequal(string(G.ax.XTickLabel), sct.sv_colName))
assert(G.ax.YDir == "reverse" && string(G.ax.XLabel.String) == "variable" && string(G.ax.YLabel.String) == "equation")
% 区切り線: 行のグループ G1 は行 1 と行 3 の前に 1 本ずつ (最初は軸の縁)
h = G.sct_plt.Separator(1);
assert(isequaln(h.YData, [0.5 0.5 NaN 2.5 2.5 NaN]) && isequaln(h.XData, [0.5 4.5 NaN 0.5 4.5 NaN]))
h = G.sct_plt.Separator(4);
assert(isequaln(h.XData, [2.5 2.5 NaN]) && isequaln(h.YData, [0.5 3.5 NaN]))
bad = sct;  bad.sv_rowName = ["a"; "b"];
assert(error_id(@() GraphMatrix(bad, Parent=fig)) == "GUILDA:GraphMatrix:FieldSize")
bad = sct;  bad.c_matrix{2} = zeros(3, 3);
assert(error_id(@() GraphMatrix(bad, Parent=fig)) == "GUILDA:GraphMatrix:FieldSize")
bad = sct;  bad.sv_colGroup(2) = "";
assert(error_id(@() GraphMatrix(bad, Parent=fig)) == "GUILDA:GraphMatrix:FieldSize")
bad = sct;  bad.rv_t = [0 1 2];
assert(error_id(@() GraphMatrix(bad, Parent=fig)) == "GUILDA:GraphMatrix:FieldSize")
bad = rmfield(sct, "rv_t");
assert(error_id(@() GraphMatrix(bad, Parent=fig)) == "GUILDA:GraphMatrix:MissingField")
bad = sct;  bad.c_matrix{1} = 1i * ones(3, 4);
assert(error_id(@() GraphMatrix(bad, Parent=fig)) == "GUILDA:GraphMatrix:FieldValue")
assert(error_id(@() set_prop(G, "SeparatorColor", zeros(2, 3))) == "GUILDA:GraphMatrix:StyleSize")
assert(error_id(@() set_prop(G, "ColorLimits", [2 1])) == "GUILDA:GraphMatrix:StyleValue")


%% pattern draws a dot at every entry above Tolerance
G = GraphMatrix(sct, Parent=fig);
h = G.sct_plt.Pattern;
[iv_i, iv_j] = find(sct.c_matrix{1});
assert(h.Visible == "on" && G.sct_plt.Image.Visible == "off" && G.sct_plt.Colorbar.Visible == "off")
assert(isequal(sort(h.XData + 10*h.YData), sort(iv_j' + 10*iv_i')), "非ゼロの数は 6")
G.Tolerance = 1e-6;
assert(numel(h.XData) == 5, "1e-9 は 0 として描かない")
G.Tolerance = 0.01;
assert(numel(h.XData) == 4 && ~any(h.XData == 3 & h.YData == 1))
G2 = GraphMatrix(sct, Parent=uipanel(fig), Tolerance=0.01);
assert(numel(G2.sct_plt.Pattern.XData) == 4, "名前と値の引数でも同じ")


%% magnitude draws log10|value| with blank zeros and limits over all samples
G = GraphMatrix(sct, Parent=fig, Display="magnitude");
h = G.sct_plt.Image;
assert(h.Visible == "on" && G.sct_plt.Pattern.Visible == "off" && G.sct_plt.Colorbar.Visible == "on")
assert(isequal(h.AlphaData, double(full(sct.c_matrix{1}) ~= 0)))
assert(abs(h.CData(3, 1) - log10(40)) < 1e-12 && isnan(h.CData(1, 2)))
assert(norm(G.ax.CLim - [-9, 2]) < 1e-12, "2 標本すべての |値| の最小 1e-9 から最大 100")
G.Tolerance = 1e-6;
assert(norm(G.ax.CLim - log10([2e-3 100])) < 1e-12 && h.AlphaData(2, 4) == 0)
G.ColorLimits = [NaN 1];
assert(norm(G.ax.CLim - [log10(2e-3) 1]) < 1e-12, "NaN の側だけ自動")
G.ColorLimits = [-1 1];
assert(isequal(G.ax.CLim, [-1 1]))
G.ColorLimits = [NaN NaN];
G.set_time(0.5);
assert(abs(h.CData(3, 3) - 2) < 1e-12 && norm(G.ax.CLim - log10([2e-3 100])) < 1e-12, "範囲は時刻で変わらない")


%% value draws the signed values with a diverging colormap and symmetric limits
G = GraphMatrix(sct, Parent=fig, Display="value");
h = G.sct_plt.Image;
assert(h.CData(3, 1) == -40 && isnan(h.CData(1, 2)) && isequal(G.ax.CLim, [-100 100]))
rm_map = colormap(G.ax);
assert(isequal(rm_map(1, :), [0 0 1]) && isequal(rm_map(end, :), [1 0 0]) && all(rm_map(128, :) > 0.99))
G.ColorLimits = [-50 50];
assert(isequal(G.ax.CLim, [-50 50]))
G.Display = "pattern";
assert(G.sct_plt.Pattern.Visible == "on" && h.Visible == "off")


%% set_time shows the nearest sample and its time in the title
G = GraphMatrix(sct, Parent=fig);
assert(string(G.ax.Title.String) == "J, t = 0 s")
G.set_time(0.4);
assert(G.i_time == 2 && string(G.ax.Title.String) == "J, t = 0.5 s")
assert(numel(G.sct_plt.Pattern.XData) == 4)
G.animate(Speed=Inf, TimeStep=0.25);
assert(G.i_time == 2)


%% select highlights the rows and columns of a group and set_style changes its separators
G = GraphMatrix(sct, Parent=fig);
G.select("G1");
hv = G.sct_plt.Selection;
assert(numel(hv) == 2 && all(string({hv.PickableParts}) == "none"), "行のグループと列のグループ")
assert(isequal(hv(1).YData, [0.5 2.5; 0.5 2.5; 1.5 3.5; 1.5 3.5]), "G1 の行は 2 つのブロック")
assert(isequal(hv(2).XData, [0.5; 2.5; 2.5; 0.5]) && isequal(hv(2).YData, [0.5; 0.5; 3.5; 3.5]))
G.Display = "magnitude";
assert(numel(G.sct_plt.Selection) == 2 && all(isgraphics(G.sct_plt.Selection)), "表示を変えても選択は残る")
G.clear_selection();
assert(isempty(G.sct_plt.Selection))
G.set_style("G1", Color="r", LineWidth=2);
assert(isequal(G.sct_plt.Separator(1).Color, [1 0 0]) && G.sct_plt.Separator(3).LineWidth == 2)
assert(isequal(G.SeparatorColor([1 3], :), [1 0 0; 1 0 0]) && isequal(G.SeparatorColor(2, :), [0.6 0.6 0.6]))
G.SeparatorLineWidth(2) = 3;
assert(G.sct_plt.Separator(2).LineWidth == 3, "ベクトルの書き換えも同じ")
G.reset_style("G1");
assert(isequal(G.sct_plt.Separator(1).Color, [0.6 0.6 0.6]))
% set_data: 残るグループの見た目はタグで残る
G.set_style("B1", Color="b");
sct2 = sct;
sct2.sv_rowGroup = ["G1"; "B1"; "G2"];
G.set_data(sct2);
assert(isequal(G.tab_element.Tag, ["G1"; "B1"; "G2"; "G1"; "B1"]))
assert(isequal(G.SeparatorColor(2, :), [0 0 1]) && isequal(G.SeparatorColor(3, :), [0.6 0.6 0.6]))
assert(error_id(@() G.set_style("G1", Marker="o")) == "GUILDA:GraphBase:StyleNotApplicable")


%% An empty matrix draws empty axes with no elements
sct0 = struct("c_matrix", {{zeros(0, 0)}}, "sv_rowName", strings(0, 1), "sv_colName", strings(0, 1), ...
              "sv_rowGroup", strings(0, 1), "sv_colGroup", strings(0, 1));
for s_display = ["pattern", "magnitude", "value"]
    G = GraphMatrix(sct0, Parent=uipanel(fig), Display=s_display);
    assert(height(G.tab_element) == 0 && isempty(G.sct_plt.Separator))
    assert(G.sct_plt.Image.Visible == "off" && isempty(G.ax.XTick) && isempty(G.ax.YTick))
end
G.show_controls();
assert(isgraphics(G.h_controls))
% 行が 0 で列がある行列も同じ
sct0 = struct("c_matrix", {{zeros(0, 2)}}, "sv_rowName", strings(0, 1), "sv_colName", ["a"; "b"], ...
              "sv_rowGroup", strings(0, 1), "sv_colGroup", ["X"; "X"]);
G = GraphMatrix(sct0, Parent=fig, Display="value");
assert(isequal(G.tab_element.Kind, "colgroup") && G.sct_plt.Image.Visible == "off")


%% One sample needs no times and has no playback bar
sct1 = rmfield(sct, "rv_t");
sct1.c_matrix = sct.c_matrix(1);
sct1.s_title  = "";
p1 = uipanel(fig);
G = GraphMatrix(sct1, Parent=p1, Display="magnitude");
assert(isequal(G.rv_t, 0) && isempty(G.ax.Title.String), "t = 0 の 1 標本は時刻を書かない")
assert(error_id(@() G.animate()) == "GUILDA:GraphBase:OneSample")
h = G.show_controls();
c_label = string({findall(h, "Type", "uilabel").Text});
assert(all(ismember(["Display", "Color limits", "Tolerance"], c_label)) && ~any(c_label == "Time"))
assert(isempty(findall(p1, "Tag", "GUILDA:GraphBase:PlaybackBar")))
sct1.rv_t = 2;
G = GraphMatrix(sct1, Parent=fig);
assert(string(G.ax.Title.String) == "t = 2 s")


%% The controls set Display, ColorLimits and Tolerance; the playback bar has the time
p = uipanel(fig);
G = GraphMatrix(sct, Parent=p);
h = G.show_controls();
c_label = string({findall(h, "Type", "uilabel").Text});
assert(all(ismember(["Display", "Color limits", "Tolerance"], c_label)) && ~any(c_label == "Time"))
assert(isscalar(findall(p, "Tag", "GUILDA:GraphBase:PlaybackBar")))
dd = findall(h, "Type", "uidropdown");
assert(isequal(string(dd.Items), ["pattern" "magnitude" "value"]))
w_spin = findall(h, "Type", "uispinner");
assert(sum(string({w_spin.Enable}) == "off") == 2, "pattern では色の範囲は操作できない")
G.Display = "value";
assert(string(dd.Value) == "value", "パネルはプロパティに従う")
assert(all(string({w_spin.Enable}) == "on"))
dd.Value = "magnitude";
dd.ValueChangedFcn(dd, []);
assert(G.Display == "magnitude" && G.sct_plt.Image.Visible == "on")


%% Tick labels of 300 variables are thinned out so that they do not overlap
n = 300;
sv_name = "x" + (1:n)';
sv_group = "G" + ceil((1:n)' / 10);
sctL = struct("c_matrix", {{speye(n) + sparse(1:n-1, 2:n, 1, n, n)}}, "sv_rowName", sv_name, "sv_colName", sv_name, ...
              "sv_rowGroup", sv_group, "sv_colGroup", sv_group);
figL = figure("Visible", "off", "Position", [0 0 800 800]);
c_figL = onCleanup(@() close(figL));
G = GraphMatrix(sctL, Parent=figL);
n_tick = numel(G.ax.YTick);
assert(n_tick > 10 && n_tick < n && isequal(string(G.ax.YTickLabel), sv_name(G.ax.YTick)))
assert(numel(G.sct_plt.Pattern.XData) == 2*n - 1 && height(G.tab_element) == 60)
% 小さな図では少なく (見えない figure では SizeChanged が起きないので、小さな図に描き直す)
figS = figure("Visible", "off", "Position", [0 0 400 400]);
c_figS = onCleanup(@() close(figS));
GS = GraphMatrix(sctL, Parent=figS);
assert(numel(GS.ax.YTick) < n_tick && GS.ax.YTick(1) == 1)


%% A data tip shows the names, the groups and the value; on a separator it clicks the group
figT = figure("Visible", "off");              % its own figure: no UpdateFcn of another graph before
c_figT = onCleanup(@() close(figT));
G = GraphMatrix(sct, Parent=figT);
fcn = datacursormode(figT).UpdateFcn;
assert(isempty(functions(fcn).workspace{1}.fcn_prev))
txt = fcn([], struct("Target", G.sct_plt.Pattern, "Position", [1 3]));
assert(isequal(string(txt), ["Row: omega (G1)", "Column: delta (G1)", "Value: -40"]))
G.set_time(0.5);
G.Display = "value";
txt = fcn([], struct("Target", G.sct_plt.Image, "Position", [3 3]));
assert(string(txt{3}) == "Value: 100")
G.ElementClickedFcn = @(~, data) assignin_cell(data);
txt = fcn([], struct("Target", G.sct_plt.Separator(4), "Position", [2.5 1]));
assert(string(txt) == "Column group: B1")
data = getappdata(0, "F82_click");
rmappdata(0, "F82_click");
assert(data.Tag == "B1" && data.Kind == "colgroup" && data.Index == 4)
% set_data は前の UpdateFcn を二重に包まない
G.set_data(sct);
fcn2 = datacursormode(figT).UpdateFcn;
assert(isempty(functions(fcn2).workspace{1}.fcn_prev))
% 同じ figure の 2 つ目の図: 自分の要素は自分で答え、ほかは前の図の UpdateFcn に渡す
G2 = GraphMatrix(sct, Parent=uipanel(figT));
fcn3 = datacursormode(figT).UpdateFcn;
txt = fcn3([], struct("Target", G.sct_plt.Pattern, "Position", [1 1]));
assert(string(txt{1}) == "Row: delta (G1)")
txt = fcn3([], struct("Target", G2.sct_plt.Separator(1), "Position", [1 0.5]));
assert(string(txt) == "Row group: G1")


function assignin_cell(data)
% ElementClickedFcn のイベントデータを残す
    setappdata(0, "F82_click", data);
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
