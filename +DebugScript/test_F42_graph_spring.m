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
assert(isa(G2, "GraphSpringBase") && G2.i_time == 1)
assert(numel(G2.sct_plt.Node) == 4 && numel(G2.sct_plt.Spring) == 3 && isequal(size(G2.sct_plt.ArrowP), [2 2]))
assert(G2.RMax == 1.5 && G2.ArrowScaleP == 0.30 && G2.ShowLabel && G2.ShowValue && G2.SpringTurns == 5)
% 省略した色・大きさは種類ごとの既定値、色の名前と "#RRGGBB" は RGB になる
assert(isequal(G2.sct_data.rm_color(1, :), [1 0 0]) && isequal(G2.sct_data.rm_color(2, :), [0 0 0]))
assert(max(abs(G2.sct_data.rm_color(3, :) - [0 170/255 0])) < 1e-12)
assert(isequal(G2.sct_data.rv_size, [5; 5; 5; 15]))
assert(G2.sct_plt.Node(3).Marker == "v" && G2.sct_plt.Spring(3).Tag == "X1")
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
assert(error_id(@() GraphSpring3D(sct, Parent=fig)) == "GUILDA:GraphSpringBase:ParentNotAxes")
% 省略できる項目を省いても描ける (矢印なし、静止画)
s = rmfield(sct, ["sv_edge", "iv_arrow", "rm_P", "rm_Iq", "sv_marker", "sv_color", "rv_circle"]);
s.rv_t = 0;  s.cm_V = s.cm_V(:, 1);
G2 = f_make(s);
assert(isempty(G2.sct_plt.ArrowP) && isempty(G2.ax.Title.String))


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
