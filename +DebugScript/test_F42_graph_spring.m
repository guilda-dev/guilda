% F42 ばね質点モデルの図 (GraphSpring2D / GraphSpring3D)
%
%   G = GraphSpring2D(sct_data, Name=Value);   % 複素平面 (フェーザ図)
%   G = GraphSpring3D(sct_data, Name=Value);   % 曲面 z = log|V| の上
%   G.set_time(t);  G.animate(...);  G.export_video(s_file, ...);
%
% 系統を使わず、3 母線 + 1 機器ノードの合成データ (構造体) で確かめる。
% ノードの位置 (2D は (Re, Im)、3D は (|V|cosθ, |V|sinθ, log|V|))、RotationScale、
% データの誤りのエラー、動画の書き出しを見る。図はすべて見えない figure に描く。
%
% 実行: runtests("DebugScript.test_F42_graph_spring")  または  DebugScript.run_all("Features","F42")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
% 合成データ: 母線 B1-B3 は共通に 0.5 rad/s で回り、t = 0 の平均位相は 0。G1 は B1 の機器ノード
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
sct.sv_marker = ["o"; "o"; "v"; "o"];
sct.sv_color  = ["red"; ""; "#00AA00"; "red"];
sct.rv_circle = [nan; nan; nan; 1.1];


%% Both pictures are built from the data with the defaults of the scripts
G2 = GraphSpring2D(sct, Parent=axes(fig));
assert(isa(G2, "GraphSpringBase") && isa(G2, "GraphBase") && G2.i_time == 1)
assert(numel(G2.sct_plt.Node) == 4 && numel(G2.sct_plt.Spring) == 3 && isequal(size(G2.sct_plt.ArrowP), [2 2]))
assert(G2.RMax == 1.5 && G2.ArrowScaleP == 0.30 && G2.ShowLabel && G2.ShowValue && G2.SpringTurns == 5 && G2.SpringAmplitude == 0.02)
% 省略した色・大きさは種類ごとの既定値、色の名前と "#RRGGBB" は RGB になる
% (データの見た目の項目は要素ごとのベクトルのプロパティの初期値になる)
assert(isequal(G2.NodeColor(1, :), [1 0 0]) && isequal(G2.NodeColor(2, :), [0 0 0]))
assert(max(abs(G2.NodeColor(3, :) - [0 170/255 0])) < 1e-12)
assert(isequal(G2.NodeSize, [5; 5; 5; 15]) && isequal(G2.NodeMarker, sct.sv_marker) && isequal(G2.NodeLabel, sct.sv_node))
assert(~isfield(G2.sct_data, "rm_color") && ~isfield(G2.sct_data, "sv_color"))
assert(G2.sct_plt.Node(3).Marker == "v" && G2.sct_plt.Spring(3).Tag == "X1")
% コイルの半径は pu で固定(ばねの長さによらず、長さの 6 % が上限): 輪の幅は 2*半径
for e = 1:numel(G2.sct_plt.Spring)
    rv_x = G2.sct_plt.Spring(e).XData(:);  rv_y = G2.sct_plt.Spring(e).YData(:);
    rv_d = [rv_x(end) - rv_x(1), rv_y(end) - rv_y(1)];
    r_len = norm(rv_d);
    r_width = max(abs((rv_x - rv_x(1))*rv_d(2) - (rv_y - rv_y(1))*rv_d(1))) / r_len;
    assert(abs(r_width - 2*min(0.02, 0.06*r_len)) < 1e-3*r_len)
end
% 値のラベルと凡例
assert(startsWith(string(G2.sct_plt.LabelP(1).String), "P = ") && G2.sct_plt.Legend.Visible == "on")

clf(fig);
G3 = GraphSpring3D(sct, Parent=axes(fig));
assert(G3.RMin == 0.02 && G3.RMax == 1.70 && isequal(G3.View, [-20 50]) && G3.SurfaceAlpha == 0.40)
assert(~G3.ShowLabel && ~G3.ShowValue && abs(G3.SpringTurns - 1/0.09) < 1e-12 && G3.SpringAmplitude == 0.013)
assert(isscalar(G3.sct_plt.Rod))                    % 機器ノードへの棒は 1 本
% 指定した値は 3D の既定値より優先する
clf(fig);
G3 = GraphSpring3D(sct, Parent=axes(fig), ShowLabel=true, SpringTurns=5);
assert(G3.ShowLabel && G3.SpringTurns == 5 && G3.sct_plt.LabelNode(1).Visible == "on")


%% set_time draws the nearest sample at the expected coordinates
G2 = GraphSpring2D(sct, Parent=axes(fig));
G2.set_time(1.04);                                  % 最も近いのは t = 1.0 (11 番目)
assert(G2.i_time == 11)
cv = sct.cm_V(:, 11);                               % t = 0 の母線の平均位相は 0 なので回転なし
for n = 1:4
    h = G2.sct_plt.Node(n);
    assert(abs(h.XData - real(cv(n))) < 1e-12 && abs(h.YData - imag(cv(n))) < 1e-12, "2D node " + n)
end
assert(contains(string(G2.ax.Title.String), "1.00"))
% P の矢印は接線方向、長さは ArrowScaleP * P (矢じりを含む)
h = G2.sct_plt.ArrowP(1, :);
rv_tip = [h(2).XData(1), h(2).YData(1)];
rv_dir = 1j * cv(4) / abs(cv(4));
r_len  = 0.30 * sct.rm_P(1, 11);
assert(norm(rv_tip - [real(cv(4)) + r_len*real(rv_dir), imag(cv(4)) + r_len*imag(rv_dir)]) < 1e-12)

clf(fig);
G3 = GraphSpring3D(sct, Parent=axes(fig));
G3.set_time(2);
for n = 1:4
    h = G3.sct_plt.Node(n);
    rv_c = [mean([min(h.XData(:)), max(h.XData(:))]), mean([min(h.YData(:)), max(h.YData(:))]), ...
            mean([min(h.ZData(:)), max(h.ZData(:))])];
    v = sct.cm_V(n, end);
    assert(norm(rv_c - [abs(v)*cos(angle(v)), abs(v)*sin(angle(v)), log(abs(v))]) < 1e-12, "3D node " + n)
end


%% RotationScale 0 removes the common rotation of the buses
G2 = GraphSpring2D(sct, Parent=axes(fig), RotationScale=0);
G2.set_time(2);
cv0 = sct.cm_V(:, 1);                               % 共通の回転を除くと t = 0 と同じ位置
for n = 1:4
    h = G2.sct_plt.Node(n);
    assert(abs(h.XData - real(cv0(n))) < 1e-12 && abs(h.YData - imag(cv0(n))) < 1e-12)
end
% プロパティを変えると今の時刻を描き直す
G2.RotationScale = 1;
assert(abs(G2.sct_plt.Node(1).XData - real(sct.cm_V(1, end))) < 1e-12)
% 0.5 は回転の半分を残す
G2.RotationScale = 0.5;
v = sct.cm_V(1, end) * exp(-0.5j * 0.5 * rv_t(end));
assert(abs(G2.sct_plt.Node(1).XData - real(v)) < 1e-12 && abs(G2.sct_plt.Node(1).YData - imag(v)) < 1e-12)
% 表示の切り替え
G2.ShowLabel  = false;
G2.ShowLegend = false;
G2.ShowValue  = false;
assert(G2.sct_plt.LabelNode(1).Visible == "off" && G2.sct_plt.Legend.Visible == "off")
assert(string(G2.sct_plt.LabelP(1).String) == "")
% RMax を変えると図を作り直す
G2.RMax = 2;
assert(G2.i_time == numel(rv_t) && all(isgraphics(G2.sct_plt.Node)))


%% A node at zero voltage in 3D sits at the bottom and nothing leaves the axes
% B3 は t = 0.5-0.9 で |V| = 0 (Iq = Q/|V| は NaN)。RMax = 1.2 では G1 (|V| = 1.1) の矢印が
% 曲面の外へ出るので、矢印は向きを保って縮み、残りは箱の面に押し付けられる
s = sct;
s.cm_V(3, 6:10)  = 0;
s.rm_Iq(2, 6:10) = NaN;
G3 = GraphSpring3D(s, Parent=axes(fig), RMax=1.2);
for t = [0 0.7 2]
    G3.set_time(t);
    assert_inside(G3.ax, "t = " + t)
end
G3.set_time(0.7);
h = G3.sct_plt.Node(3);                             % 曲面の底 (RMin, 角度 0) で、下半分は底面に載る
assert(abs(max(h.XData(:)) + min(h.XData(:)) - 2*G3.RMin) < 1e-12 && min(h.ZData(:)) == log(G3.RMin))
h = G3.sct_plt.ArrowP(1, :);                        % G1 の P の矢印: 縮むが向きは接線のまま
rv_d = [h(1).XData(end) - h(1).XData(1), h(1).YData(end) - h(1).YData(1), h(1).ZData(end) - h(1).ZData(1)];
v = G3.sct_plt.Node(4);
rv_p = [mean([min(v.XData(:)), max(v.XData(:))]), mean([min(v.YData(:)), max(v.YData(:))])];
assert(abs(dot(rv_d(1:2), rv_p)) < 1e-9 && rv_d(3) == 0, "P の矢印は |V| 一定の円の接線方向")
hv = [G3.sct_plt.ArrowP(:, 2); G3.sct_plt.ArrowQ(:, 2)];
assert(all(string({hv.EdgeColor}) == "none"), "矢じりは辺なし (辺が軸の外へ細い線として描かれることがある)")


%% Two 3D pictures in one figure keep their objects in their own axes
% 1 つの figure に 2 つ並べ、片方の矢印の長さを後から変えても、それぞれの図の要素は自分の
% 軸の子で、軸の範囲の外に出ない (細い線は矢じりの辺だった。矢じりは辺なし)
layout = tiledlayout(fig, 1, 2);
s = sct;
s.cm_V(3, 6:10) = 0;
c_G = {GraphSpring3D(s, Parent=nexttile(layout), RMax=1.2), GraphSpring3D(s, Parent=nexttile(layout), RMin=0.3, RMax=1.3)};
c_G{1}.set_time(0.7);
c_G{2}.set_time(2);
c_G{1}.ArrowScaleP = 0.12;
c_G{1}.ArrowScaleQ = 0.12;
for i = 1:2
    plt = c_G{i}.sct_plt;
    hv  = [plt.Spring; plt.Rod; plt.RodLine; plt.Node; plt.ArrowP(:); plt.ArrowQ(:); plt.LabelNode; plt.LabelP; plt.LabelQ];
    assert(all(arrayfun(@(h) h.Parent == c_G{i}.ax, hv)), "図 " + i + " の要素はその軸の子")
    assert_inside(c_G{i}.ax, "図 " + i)
    hv = [plt.ArrowP(:, 2); plt.ArrowQ(:, 2)];
    assert(all(string({hv.EdgeColor}) == "none"))
end


%% Tick labels of small 2D pictures do not overlap
% 560 x 420 の figure に 2 x 2 で並べると角度の目盛りは間引かれ、表示した目盛りは重ならない
fig.Position = [0 0 560 420];
layout = tiledlayout(fig, 2, 2, TileSpacing="compact", Padding="compact");
c_G = cell(1, 4);
for i = 1:4
    c_G{i} = GraphSpring2D(sct, Parent=nexttile(layout));
end
drawnow;
for i = 1:4
    plt = c_G{i}.sct_plt;
    hv  = [plt.TickAngle; plt.TickRadius];
    hv  = hv(string({hv.Visible}) == "on");
    assert(nnz(string({plt.TickAngle.Visible}) == "on") < 12, "小さい図では角度の目盛りを間引く")
    assert(~isempty(hv) && ~any_overlap(vertcat(hv.Extent)), "表示した目盛りは重ならない")
    assert(~tick_on_data(c_G{i}), "小さい図でも目盛りはデータに重ならない")
end
% 時刻を変えると、その時刻のデータに重なる目盛りを選び直す
c_G{1}.set_time(1.3);
drawnow;
assert(~tick_on_data(c_G{1}))
% 通常の大きさ (同じ figure に 1 つ) では、12 本の角度と半径の目盛りをすべて出し、重ならない
% (半径の目盛りは角度の目盛りの間の 165° の線の上)
clf(fig);
G2 = GraphSpring2D(sct, Parent=axes(fig));
drawnow;
hv = [G2.sct_plt.TickAngle; G2.sct_plt.TickRadius];
assert(all(string({hv.Visible}) == "on"), "通常の大きさでは目盛りをすべて出す")
assert(~any_overlap(vertcat(hv.Extent)))
% 目盛りはデータ (ノード、ばね、矢印) の下の層にあり、表示した目盛りの箱にデータの点はない
hv = [G2.sct_plt.TickAngle; G2.sct_plt.TickRadius];
assert(all(arrayfun(@(h) h.Position(3), hv) == -1), "目盛りは z = -1 (データは 0)")
assert(~tick_on_data(G2), "目盛りはデータに重ならない")
% 利用者が隠した目盛りは、軸の範囲や文字の大きさが変わっても隠したまま (別の figure)
fig2 = figure("Visible", "off", "Position", [0 0 560 420]);
c_fig2 = onCleanup(@() close(fig2));
G2b = GraphSpring2D(sct, Parent=axes(fig2));
set(G2b.sct_plt.TickAngle, "Visible", "off");
set([G2b.sct_plt.TickAngle; G2b.sct_plt.TickRadius], "FontSize", 6);
set(G2b.ax, XLim=[-1.3 1.3], YLim=[-1.3 1.3]);
drawnow;
assert(all(string({G2b.sct_plt.TickAngle.Visible}) == "off"), "隠した角度の目盛りは隠したまま")
assert(any(string({G2b.sct_plt.TickRadius.Visible}) == "on"))
% 図の大きさが変わると目盛りを選び直す
fig.Position = [0 0 280 210];
drawnow;
assert(nnz(string({G2.sct_plt.TickAngle.Visible}) == "on") < 12)
fig.Position = [0 0 560 420];
drawnow;
assert(all(string({G2.sct_plt.TickAngle.Visible}) == "on"))


%% Value labels stay at finite positions when the node labels are empty
% 空のラベル (箱が NaN) は重なりの判定に入れない (min, max は NaN を無視するため、以前は位置が NaN になった)
G = GraphSpring2D(sct, Parent=axes(fig));
G.NodeLabel = repmat("", 4, 1);
G.set_time(1);
rm_pos = vertcat(G.sct_plt.LabelP.Position, G.sct_plt.LabelQ.Position);
assert(all(isfinite(rm_pos), "all"))


%% ShowTickLabel false hides every tick label of the polar grid
% 図の大きさや時刻を変えても隠れたまま。true に戻すと再び選ばれて表示される
G = GraphSpring2D(sct, Parent=axes(fig), ShowTickLabel=false);
hv = [G.sct_plt.TickAngle; G.sct_plt.TickRadius];
drawnow;
G.set_time(1);
fig.Position = [0 0 560 420];
drawnow;
assert(all(string({hv.Visible}) == "off"))
G.ShowTickLabel = true;
drawnow;
hv = [G.sct_plt.TickAngle; G.sct_plt.TickRadius];
assert(any(string({hv.Visible}) == "on"))


%% An arrow scale of 0 hides the values of that arrow
% ArrowScaleQ = 0 で Iq の矢印と値が消え、P の値は残る (ArrowScaleP も同じ)
G = GraphSpring2D(sct, Parent=axes(fig), ArrowScaleQ=0);
assert(all(string({G.sct_plt.LabelQ.String}) == "") && all(string({G.sct_plt.LabelP.String}) ~= ""))
G.ArrowScaleQ = 0.3;
G.ArrowScaleP = 0;
assert(all(string({G.sct_plt.LabelP.String}) == "") && all(string({G.sct_plt.LabelQ.String}) ~= ""))


%% Samples named by the data are shown in the title instead of the time
% s_sampleName と sv_sampleText (連続潮流計算の段など): 題名は標本の文字、名前だけなら
% 名前と値。2D と 3D、set_data で消える。誤った大きさはエラー
n_t = numel(rv_t);
st = sct;
st.rv_t = 1:n_t;
st.s_sampleName = "Step";
st.sv_sampleText = "Step " + (1:n_t) + " (λ = " + compose("%.3f", 0.01*(1:n_t)) + ")";
for f_make = {@GraphSpring2D, @GraphSpring3D}
    G = f_make{1}(st, Parent=axes(fig));
    G.set_time(12);
    assert(string(G.ax.Title.String) == "Step 12 (λ = 0.120)", class(G))
    s2 = rmfield(st, "sv_sampleText");
    G.set_data(s2);
    assert(string(G.ax.Title.String) == "Step 12", class(G))
    G.set_data(sct);
    assert(startsWith(string(G.ax.Title.String), "t = "), class(G))
end
bad = st;  bad.sv_sampleText = bad.sv_sampleText(1:3);
assert(error_id(@() GraphSpring2D(bad, Parent=axes(fig))) == "GUILDA:GraphBase:SampleLabel")
bad = st;  bad.s_sampleName = ["a", "b"];
assert(error_id(@() GraphSpring2D(bad, Parent=axes(fig))) == "GUILDA:GraphBase:SampleLabel")


%% Errors for data of the wrong size or value
f_make = @(s) GraphSpring2D(s, Parent=axes(fig));
s = rmfield(sct, "cm_V");
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:MissingField")
s = sct;  s.cm_V = s.cm_V(:, 1:end-1);
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldSize")
s = sct;  s.sv_kind = ["bus"; "bus"; "component"];
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldSize")
s = sct;  s.sv_kind(2) = "load";
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldValue")
s = sct;  s.im_edge = [1 5]';
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldValue")
s = sct;  s.im_edge = [1 2 3];
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldSize")
s = sct;  s.rm_P = s.rm_P(1, :);
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldSize")
s = sct;  s.sv_color(2) = "notacolor";
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldValue")
s = sct;  s.rv_size = [5; 5];
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldSize")
s = sct;  s.rv_t = fliplr(s.rv_t);
assert(error_id(@() f_make(s)) == "GUILDA:GraphSpringBase:FieldValue")
assert(error_id(@() GraphSpring3D(sct, Parent=5)) == "GUILDA:GraphBase:ParentType")
% 省略できる項目を省いても描ける (矢印なし、静止画)
s = rmfield(sct, ["sv_edge", "iv_arrow", "rm_P", "rm_Iq", "sv_marker", "sv_color", "rv_circle"]);
s.rv_t = 0;  s.cm_V = s.cm_V(:, 1);
G2 = f_make(s);
assert(isempty(G2.sct_plt.ArrowP) && isempty(G2.ax.Title.String))
assert(isequal(G2.sct_data.sv_edge, ["E1"; "E2"; "E3"]), "タグのないばねは E1, E2, ...")
% 1 時刻の図はアニメーションにできない
assert(error_id(@() G2.animate()) == "GUILDA:GraphBase:OneSample")


%% animate calls UpdateFcn at every frame and export_video writes an MPEG-4 file
G2 = GraphSpring2D(sct, Parent=axes(fig));
fig.UserData = [];
G2.animate(Speed=Inf, TimeStep=0.5, UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(isequal(fig.UserData, [0 0.5 1 1.5 2]) && G2.i_time == numel(rv_t))   % 各フレームの標本の時刻
fig.UserData = [];
G2.animate(Speed=Inf, TimeStep=0.3, UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(abs(fig.UserData(end) - 2) < 1e-12 && numel(fig.UserData) == 8)       % 最後の標本も描く

s_file = fullfile(tempdir, "GUILDA_test_F42_graph_spring.mp4");
c_file = onCleanup(@() delete_if_exists(s_file));
fig.UserData = [];
G2.export_video(s_file, FrameRate=10, TimeStep=0.5, HoldTime=0.2, UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(numel(fig.UserData) == 5)
assert(isfile(s_file) && dir(s_file).bytes > 0)
vr = VideoReader(s_file);
assert(vr.NumFrames == 5 + 2 && mod(vr.Width, 2) == 0 && mod(vr.Height, 2) == 0)   % 5 フレーム + 最後を 0.2 s 保持
clear vr
delete(s_file);
% 3D、軸だけを録画
clf(fig);
G3 = GraphSpring3D(sct, Parent=axes(fig));
G3.export_video(s_file, TimeStep=1, HoldTime=0, Capture="axes");
assert(isfile(s_file))



function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end

function delete_if_exists(s_file)
    if isfile(s_file)
        delete(s_file);
    end
end


function assert_inside(ax, s_msg)
% Every coordinate of the graphics in the axes is NaN (hidden) or a finite value inside the limits.
    rm_lim = [ax.XLim; ax.YLim; ax.ZLim];
    sv_xyz = ["XData", "YData", "ZData"];
    for h = findobj(ax, "-property", "ZData")'
        for j = 1:3
            rv = h.(sv_xyz(j))(:);
            assert(~any(isinf(rv)), s_msg + ": Inf in " + class(h))
            rv = rv(~isnan(rv));
            assert(all(rv >= rm_lim(j, 1) - 1e-12 & rv <= rm_lim(j, 2) + 1e-12), s_msg + ": " + class(h) + " outside " + sv_xyz(j))
        end
    end
    for h = findobj(ax, "Type", "text")'
        rv = h.Position;
        assert(all(isnan(rv)) || all(rv(:) >= rm_lim(:, 1) - 1e-12 & rv(:) <= rm_lim(:, 2) + 1e-12), s_msg + ": text outside")
    end
end


function l = any_overlap(rm)
% True when two of the rectangles [left bottom width height] overlap.
    l = false;
    for i = 1:size(rm, 1)
        for j = i+1:size(rm, 1)
            l = l || (rm(i, 1) < rm(j, 1) + rm(j, 3) && rm(j, 1) < rm(i, 1) + rm(i, 3) && ...
                      rm(i, 2) < rm(j, 2) + rm(j, 4) && rm(j, 2) < rm(i, 2) + rm(i, 4));
        end
    end
end


function l = tick_on_data(G)
% True when a shown tick label box holds a point of a spring or an arrow, or the centre of a node.
    plt = G.sct_plt;
    hv  = [plt.TickAngle; plt.TickRadius];
    hv  = hv(string({hv.Visible}) == "on");
    rm_pt = zeros(0, 2);
    for h = [plt.Node; plt.Spring; plt.ArrowP(:); plt.ArrowQ(:)]'
        rm_pt = [rm_pt; h.XData(:), h.YData(:)]; %#ok<AGROW>
    end
    rm_pt = rm_pt(all(isfinite(rm_pt), 2), :);
    l = false;
    for h = hv'
        rv_b = h.Extent;
        l = l || any(rm_pt(:, 1) > rv_b(1) & rm_pt(:, 1) < rv_b(1) + rv_b(3) & ...
                     rm_pt(:, 2) > rv_b(2) & rm_pt(:, 2) < rv_b(2) + rv_b(4));
    end
end
