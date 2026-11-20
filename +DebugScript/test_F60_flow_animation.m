% F60 ネットワーク図の流れのアニメーション (GraphNetDiagram の FlowMode、FlowAnimation、FlowSpeed)
%
%   G = net.plot_diagram();               % 2D: 各ブランチとリンクの上を、流れの向きに点が動く
%   G.FlowMode = "P" | "Q" | "I" | "none";   % 既定 "P"
%   G.FlowSpeed = 1;                      % 最も大きい流れの点が 1 秒に進む長さ (d0 の倍数)
%   G.FlowAnimation = true | false;       % timer で動かす (見える 2D の図、-batch でない)
%
% 点の速さは |q| / q_max (q_max は全標本の最大) に比例し、間隔は 0.25*d0 で一定
% (notes/graph-diagram-2d.md §3)。テストは timer を使わず、隠しメソッド step_flow(r_dt) で
% 点を決まった時間だけ進めて確かめる。図はすべて見えない figure に描くので timer はできない。
% timer そのものの動作 (見える figure で動き、閉じると消える) は画面のある環境で手で確かめる。
%
% 実行: runtests("DebugScript.test_F60_flow_animation")  または  DebugScript.run_all("Features","F60")

fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
s_tag = "GUILDA:GraphNetDiagram:Flow";
net14 = network.IEEE14bus();
DebugScript.helper.quiet(@() net14.initialize);


%% A hidden figure has no timer and its dots stand still until step_flow
D = net14.plot_diagram(Parent=axes(fig));
assert(D.FlowMode == "P" && D.FlowAnimation && D.FlowSpeed == 1, "既定")
assert(isempty(timerfindall("Tag", s_tag)), "隠れた figure では timer を作らない")
assert(size(D.sct_plt.FlowBranch.Faces, 1) > 0 && size(D.sct_plt.FlowLink.Faces, 1) > 0, "止まった点を描く")
assert(D.sct_plt.FlowBranch.PickableParts == "none")
rm_v = D.sct_plt.FlowBranch.Vertices;
drawnow; pause(0.1);
assert(isequal(D.sct_plt.FlowBranch.Vertices, rm_v), "timer がないので動かない")
D.step_flow(0.05);
assert(~isequal(D.sct_plt.FlowBranch.Vertices, rm_v), "step_flow で進む")
% 点は白で、細い暗い縁 (明るい線と白い背景の上でも見える)。線の色を変えても白のまま
for h = [D.sct_plt.FlowBranch, D.sct_plt.FlowLink]
    assert(isequal(h.FaceColor, [1 1 1]) && isequal(h.EdgeColor, [0.25 0.25 0.25]) && h.LineWidth == 0.5, "点は白、縁は暗い灰色")
end
D.BranchColor(3, :) = [1 1 0];
D.step_flow(0.01);
assert(isequal(D.sct_plt.FlowBranch.FaceColor, [1 1 1]), "線の色を変えても点は白")
% 重ね順: ブランチ・リンク・変圧器の記号の上、母線の下
hv = D.ax.Children(end:-1:1);
i_flow = find(hv == D.sct_plt.FlowBranch);
assert(i_flow > find(hv == D.sct_plt.EdgeMain(1)) && i_flow < find(hv == D.sct_plt.NodeMain(1)))


%% The dots move in the flow direction at a speed proportional to the flow
D = net14.plot_diagram(Parent=axes(fig));
sct_net = struct(net14, false);
[rv_q, rv_ql] = flows(D, sct_net, 1);
r_qmax = max(abs([rv_q; rv_ql]));
assert(isequal(D.BranchDirection, sign(rv_q)) && isequal(D.LinkDirection, sign(rv_ql)), "向きは q の符号")
r_dt = 0.02;
sct_m = measure(D, r_dt);
d0 = D.sct_plt.D0;
lv = abs(rv_q) >= 1e-3*r_qmax;
assert(all(sct_m.n_dot(~lv) == 0), "|q| の小さいブランチに点はない")
lv_two = lv & sct_m.n_dot > 1;
assert(any(lv_two) && all(abs(sct_m.r_spacing(lv_two) - 0.25*d0) < 1e-6*d0), "間隔は 0.25*d0")
rv_expect = D.FlowSpeed*d0*rv_q/r_qmax*r_dt;                     % 符号つきの進み (From -> To が正)
assert(max(abs(sct_m.rv_move(lv) - rv_expect(lv))) < 1e-6*d0, "From -> To の向きに、|q| に比例する速さで進む")
% リンク: 同期調相機 (P = 0) は点がない
lv_l = abs(rv_ql) >= 1e-3*r_qmax;
assert(any(~lv_l), "前提: P が 0 の機器がある")
assert(all(sct_m.n_link(~lv_l) == 0) && all(sct_m.n_link(lv_l) > 0))
rv_expect = D.FlowSpeed*d0*rv_ql/r_qmax*r_dt;
assert(max(abs(sct_m.rv_moveLink(lv_l) - rv_expect(lv_l))) < 1e-6*d0, "リンクは機器 -> 母線が正")
% FlowSpeed に比例
D.FlowSpeed = 2;
sct_2 = measure(D, r_dt);
assert(max(abs(sct_2.rv_move(lv) - 2*sct_m.rv_move(lv))) < 1e-6*d0)
% 向きを逆にした状態 (電圧の位相を反転) では逆向き
sct_s = struct("rv_t", 0, "cm_Vbus", conj(D.sct_state.cm_Vbus), "cm_Icomp", conj(D.sct_state.cm_Icomp));
D.set_data(sct_s);
rv_q2 = flows(D, sct_net, 1);
assert(any(sign(rv_q2) == -sign(rv_q) & lv), "前提: 向きの変わるブランチがある")
sct_r = measure(D, r_dt);
lv2 = abs(rv_q2) >= 1e-3*max(abs(rv_q2));
assert(all(sign(sct_r.rv_move(lv & lv2)) == sign(rv_q2(lv & lv2))), "新しい状態の向きに進む")


%% FlowMode chooses the quantity, and "none" draws no dots
D = net14.plot_diagram(Parent=axes(fig));
for s_mode = ["Q", "I"]
    D.FlowMode = s_mode;
    [rv_q, rv_ql] = flows(D, struct(net14, false), 1);
    r_qmax = max(abs([rv_q; rv_ql]));
    sct_m = measure(D, 0.02);
    lv = abs(rv_q) >= 1e-3*r_qmax;
    rv_expect = D.FlowSpeed*D.sct_plt.D0*rv_q/r_qmax*0.02;
    assert(max(abs(sct_m.rv_move(lv) - rv_expect(lv))) < 1e-6, s_mode)
end
D.FlowMode = "none";
assert(isempty(D.sct_plt.FlowBranch.Faces) && isempty(D.sct_plt.FlowLink.Faces))
D.step_flow(0.1);
assert(isempty(D.sct_plt.FlowBranch.Faces))
D.FlowMode = "P";
assert(~isempty(D.sct_plt.FlowBranch.Faces))


%% A topology diagram and 3D have no dots
D = net14.plot_diagram(Parent=axes(fig), State="topology");
assert(all(isnan(D.sct_state.cm_Vbus)), "前提: 構成だけ")
assert(isempty(D.sct_plt.FlowBranch.Faces) && isempty(D.sct_plt.FlowLink.Faces), "構成だけの図に点はない")
D.step_flow(0.1);
D = net14.plot_diagram(Parent=axes(fig), Dimension="3D");
assert(isempty(D.sct_plt.FlowBranch) && isempty(findall(D.ax, "Tag", "FlowBranch")), "3D に点はない")
D.step_flow(0.1);                       % 何もしない
D.Dimension = "2D";
assert(~isempty(D.sct_plt.FlowBranch.Faces), "2D に戻すと点がある")


%% A network without branches or links, or with one branch, draws without an error
% (F55 の空の系統から作る流れ。点の候補がないときに discretize に辺が 1 つだけ渡っていた)
net = PowerNetwork();
DebugScript.helper.quiet(@() net.add_bus());
D = DebugScript.helper.quiet(@() net.plot_diagram(Parent=axes(fig)));
assert(isempty(D.sct_plt.FlowBranch.Faces) && isempty(D.sct_plt.FlowLink.Faces), "要素がなければ点はない")
D.step_flow(0.1);
DebugScript.helper.quiet(@() net.add_bus(V=1.02));
net.add_branch("pi", ["B001", "B002"], X=0.1);
net.a_Bus{1}.add_component("gen-1axis");
net.a_Bus{2}.add_component("load-impedance");
net.a_Bus{1}.l_isSlack = true;
DebugScript.helper.quiet(@() net.initialize);
D = net.plot_diagram(Parent=axes(fig));
D.step_flow(0.1);
assert(isscalar(D.BranchDirection) && (size(D.sct_plt.FlowBranch.Faces, 1) > 0) == (D.BranchDirection ~= 0), "点があるのは流れのあるとき")


%% With heights the dots follow the paths in 3D
D = net14.plot_diagram(Parent=axes(fig), BusHeightMode="V");
[rv_q, rv_ql] = flows(D, struct(net14, false), 1);
r_qmax = max(abs([rv_q; rv_ql]));
r_dt = 0.02;
sct_m = measure(D, r_dt);                % 経路の弧長は 3D で測る
d0 = D.sct_plt.D0;
lv = abs(rv_q) >= 1e-3*r_qmax;
assert(sct_m.r_offPath < 1e-9, "点の中心は経路 (z を含む) の上")
lv_two = lv & sct_m.n_dot > 1;
assert(any(lv_two) && all(abs(sct_m.r_spacing(lv_two) - 0.25*d0) < 1e-6*d0), "間隔は 3D の弧長で 0.25*d0")
rv_expect = D.FlowSpeed*d0*rv_q/r_qmax*r_dt;
assert(max(abs(sct_m.rv_move(lv) - rv_expect(lv))) < 1e-6*d0, "傾いた線の上でも速さは 3D の弧長で一定")
rv_dz = cellfun(@(p) abs(p(end, 3) - p(1, 3)), D.sct_plt.EdgePath);
assert(max(rv_dz) > 0.01, "前提: 傾いたブランチがある")
% 高さを変えても点は飛ばない (位相は弧長のまま)
D.BusHeightMode = "none";
sct_0 = measure(D, 0);
assert(all(abs(sct_0.n_dot - sct_m.n_dot) <= 1), "点の数はほぼ同じ")
assert(all(max(abs(D.sct_plt.FlowBranch.Vertices(:, 3))) < 1e-12), "高さ 0 の線の上")


%% set_time changes the speeds and directions with one scale over all samples
sc = net14.add_scenario("fault");
sc.add_fault("B003", [0.5, 0.55]);
res = DebugScript.helper.quiet(@() net14.simulate("fault", Time=[0, 1]));
D = res.plot_diagram(Parent=axes(fig));
sct_net = struct(net14, false);
n_t = numel(D.rv_t);
rm_all = [];
for k = 1:n_t
    [rv_q, rv_ql] = flows(D, sct_net, k);
    rm_all(:, k) = [rv_q; rv_ql];
end
r_qmax = max(abs(rm_all(:)));
for t = [0.2, 0.52, 0.9]
    D.set_time(t);
    k = D.i_time;
    rv_q = rm_all(1:numel(D.BranchDirection), k);
    assert(isequal(D.BranchDirection, sign(rv_q)), "向きは表示中の標本の q")
    sct_m = measure(D, 0.02);
    lv = abs(rv_q) >= 1e-3*r_qmax;
    rv_expect = D.FlowSpeed*D.sct_plt.D0*rv_q/r_qmax*0.02;
    assert(max(abs(sct_m.rv_move(lv) - rv_expect(lv))) < 1e-6, "速さは全標本の q_max で決まる (t = " + t + ")")
end
% 標本を変えても点は飛ばない (位相が残る)
D.set_time(0.2);
rm_a = D.sct_plt.FlowBranch.Vertices;
D.set_time(0.21);
rm_b = D.sct_plt.FlowBranch.Vertices;
assert(isequal(size(rm_a), size(rm_b)) && max(abs(rm_a(:) - rm_b(:))) < 1e-12, "向きの同じ標本では点は同じ場所")


%% export_video advances the dots and leaves no timer
sc = net14.add_scenario("fault2");
sc.add_fault("B003", [0.5, 0.55]);
res = DebugScript.helper.quiet(@() net14.simulate("fault2", Time=[0, 1]));
D = res.plot_diagram(Parent=axes(fig));
s_file = fullfile(tempdir, "GUILDA_test_F60_flow_animation.mp4");
c_file = onCleanup(@() delete_if_exists(s_file));
D.set_time(0);
D.step_flow(0);
rm_a = D.sct_plt.FlowBranch.Vertices;
D.export_video(s_file, FrameRate=10, TimeStep=0.5, HoldTime=0);
assert(isfile(s_file))
D.set_time(0);
assert(~isequal(D.sct_plt.FlowBranch.Vertices, rm_a), "書き出しの各こまで点が進む")
assert(isempty(timerfindall("Tag", s_tag)), "timer が残らない")


%% No timer is left after FlowAnimation, Dimension, delete and close
D = net14.plot_diagram(Parent=axes(fig));
D.FlowAnimation = false;
D.FlowAnimation = true;
D.Dimension = "3D";
D.Dimension = "2D";
delete(D);
assert(isempty(timerfindall("Tag", s_tag)))
fig2 = figure("Visible", "off");
D = net14.plot_diagram(Parent=fig2);
close(fig2);
assert(isvalid(D) && isempty(timerfindall("Tag", s_tag)))
D.step_flow(0.1);                       % 軸が消えた図: 何もしない


%% A redraw by Graph=G keeps one timer and deleting the container contents removes it
% GUI の系統図の描き直し: (a) delete(h_parent.Children)、(b) net.plot_diagram(Graph=G)。
% -batch では timer を作らないので、この節だけ batchStartupOptionUsed を false を返す関数で
% 隠し (一時フォルダを path の先頭に置く)、見える uifigure の uipanel に描いて本物の timer を動かす。
s_dir = tempname;
mkdir(s_dir);
fid = fopen(fullfile(s_dir, "batchStartupOptionUsed.m"), "w");
fprintf(fid, "function tf = batchStartupOptionUsed()\ntf = false;\nend\n");
fclose(fid);
sct_warn = warning("off", "MATLAB:dispatcher:nameConflict");
addpath(s_dir);
c_path = onCleanup(@() restore_path(s_dir, sct_warn, s_tag));
assert(~batchStartupOptionUsed(), "前提: 隠せた")
uf = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
c_uf = onCleanup(@() delete(uf(isvalid(uf))));
h_panel = uipanel(uf);
D = net14.plot_diagram(Parent=h_panel);
assert(numel(timerfindall("Tag", s_tag)) == 1, "見える図では timer が 1 つ")
rm_v = D.sct_plt.FlowBranch.Vertices;
pause(0.3);
assert(~isequal(D.sct_plt.FlowBranch.Vertices, rm_v), "timer で点が動く")
% (b) 同じ図に描き直す: timer は 1 つで動いている
D2 = net14.plot_diagram(Graph=D);
hv_t = timerfindall("Tag", s_tag);
assert(D2 == D && isscalar(hv_t) && hv_t.Running == "on", "Graph=G の後も timer は 1 つで動く")
rm_v = D.sct_plt.FlowBranch.Vertices;
pause(0.3);
assert(~isequal(D.sct_plt.FlowBranch.Vertices, rm_v))
% (a) 容器の中身を消す: 軸が消えると timer も消える (図のオブジェクトは残る)
delete(h_panel.Children);
assert(isempty(timerfindall("Tag", s_tag)) && isvalid(D), "delete(h_parent.Children) で timer が消える")
D = net14.plot_diagram(Parent=h_panel);
assert(numel(timerfindall("Tag", s_tag)) == 1)
delete(uf);
assert(isempty(timerfindall("Tag", s_tag)), "uifigure を消すと timer が消える")


%% Closing a window while the dots move gives no warning and leaves no timer
% 窓を閉じる途中でも timer のこまが走ることがある (MATLAB は削除の途中で、待っている timer の
% コールバックを実行する)。そのこまでは軸がまだ有効なのに figure から外れていて (ancestor が空)、
% 以前は fig.Visible の参照のエラーで GUILDA:GraphNetDiagram:FlowTimer の警告が出た。
% (a) 軸を figure から外した状態 (Parent = []) を作ってこまを待つ (決定的に再現する)、
% (b) uigridlayout の 2 つの軸の片方に描いた見える窓を、点が動いている間に閉じる (5 回)。
% 前の節と同じく batchStartupOptionUsed を隠し、見える uifigure で本物の timer を動かす。
s_dir = tempname;
mkdir(s_dir);
fid = fopen(fullfile(s_dir, "batchStartupOptionUsed.m"), "w");
fprintf(fid, "function tf = batchStartupOptionUsed()\ntf = false;\nend\n");
fclose(fid);
sct_warn = warning("off", "MATLAB:dispatcher:nameConflict");
addpath(s_dir);
c_path = onCleanup(@() restore_path(s_dir, sct_warn, s_tag));
assert(~batchStartupOptionUsed(), "前提: 隠せた")
% (a) 軸が figure から外れた
lastwarn("");
uf = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
c_uf = onCleanup(@() delete(uf(isvalid(uf))));
ax = axes(uf);
D = net14.plot_diagram(Parent=ax);
assert(numel(timerfindall("Tag", s_tag)) == 1, "前提: 見える図では timer が 1 つ")
pause(0.2);
ax.Parent = [];
pause(0.3);
[~, s_id] = lastwarn;
assert(isvalid(ax) && isvalid(D), "前提: 軸と図は有効")
assert(s_id ~= "GUILDA:GraphNetDiagram:FlowTimer", "figure のない軸のこまで警告を出さない")
assert(isempty(timerfindall("Tag", s_tag)), "figure のない軸のこまで timer を止めて消す")
delete(ax);
delete(uf);
% (b) 2 つの軸の窓を、点が動いている間に閉じる
for i = 1:5
    lastwarn("");
    uf = DebugScript.helper.quiet(@() uifigure("Visible", "on"));
    c_uf = onCleanup(@() delete(uf(isvalid(uf))));
    h_grid = uigridlayout(uf, [1 2]);
    plot(axes(h_grid), 1:3);
    D = net14.plot_diagram(Parent=axes(h_grid));
    assert(numel(timerfindall("Tag", s_tag)) == 1, "前提: timer が 1 つ")
    t0 = tic;
    while toc(t0) < 0.2 + 0.03*i
        pause(0.05);
        drawnow;
    end
    close(uf);
    pause(0.2);
    [~, s_id] = lastwarn;
    assert(s_id ~= "GUILDA:GraphNetDiagram:FlowTimer", "閉じても警告を出さない (" + i + " 回目)")
    assert(isempty(timerfindall("Tag", s_tag)), "閉じると timer が消える (" + i + " 回目)")
end


%% One frame of IEEE68 takes a few milliseconds
net68 = network.IEEE68bus();
DebugScript.helper.quiet(@() net68.initialize);
D = net68.plot_diagram(Parent=axes(fig));
D.step_flow(0.04);
rv_time = zeros(1, 20);
for i = 1:20
    t0 = tic;
    D.step_flow(0.04);
    rv_time(i) = toc(t0);
end
r_med = median(rv_time);
fprintf("F60: step_flow IEEE68 %.2f ms (dots %d + %d)\n", 1e3*r_med, ...
    size(D.sct_plt.FlowBranch.Faces, 1), size(D.sct_plt.FlowLink.Faces, 1));
assert(r_med < 0.025, "1 こま 5 ms の目標の 5 倍以内")


function [rv_q, rv_ql] = flows(D, sct_net, k)
% 標本 k のブランチとリンクの流れ (FlowMode の量、符号つき) をモデルの外で計算する
    cv_V = D.sct_state.cm_Vbus(:, k);
    cv_I = D.sct_state.cm_Icomp(:, k);
    im_edge = edge_buses(sct_net);
    n = size(im_edge, 2);
    rv_q = zeros(n, 1);
    for j = 1:n
        cv_v = cv_V(im_edge(:, j));
        cv_i = sct_net.a_Branch{j}.cm_Y * cv_v;
        cv_s = cv_v .* conj(cv_i);
        x = (cv_s(1) - cv_s(2))/2;
        switch D.FlowMode
            case "P"; rv_q(j) = real(x);
            case "Q"; rv_q(j) = imag(x);
            case "I"; rv_q(j) = max(abs(cv_i)) * sign_of(x);
        end
    end
    cv_s = cv_V(D.sct_plt.CompParentBus) .* conj(cv_I);
    switch D.FlowMode
        case "P"; rv_ql = real(cv_s);
        case "Q"; rv_ql = imag(cv_s);
        case "I"; rv_ql = abs(cv_I) .* arrayfun(@sign_of, cv_s);
    end
end

function s = sign_of(x)
% P の符号 (0 なら Q の符号)
    s = sign(real(x));
    if s == 0
        s = sign(imag(x));
    end
end

function sct = measure(D, r_dt)
% 点の数・間隔・進み (経路の弧長、From 端から) を要素ごとに測る。点の中心は先端と底辺の中点の中点。
% 点はみな白なので、要素は patch の UserData.Index (面ごと) で見分ける。
    c_ph = {phases(D, D.sct_plt.FlowBranch, D.sct_plt.EdgePath), ...
            phases(D, D.sct_plt.FlowLink, D.sct_plt.CompPath)};
    D.step_flow(r_dt);
    c_ph2 = {phases(D, D.sct_plt.FlowBranch, D.sct_plt.EdgePath), ...
             phases(D, D.sct_plt.FlowLink, D.sct_plt.CompPath)};
    r_delta = 0.25*D.sct_plt.D0;
    f_move = @(a, b) mod(b.rv_phase - a.rv_phase + r_delta/2, r_delta) - r_delta/2;
    sct = struct("n_dot", c_ph{1}.n_dot, "r_spacing", c_ph{1}.r_spacing, ...
        "rv_move", f_move(c_ph{1}, c_ph2{1}), "n_link", c_ph{2}.n_dot, ...
        "rv_moveLink", f_move(c_ph{2}, c_ph2{2}), "r_offPath", max([c_ph{1}.r_off, c_ph{2}.r_off]));
end

function sct = phases(D, h, c_path)
% 要素ごとの点の数、間隔 (隣り合う点の弧長の差の最小)、位相 (From 端からの弧長 mod 0.25*d0)
    r_delta = 0.25*D.sct_plt.D0;
    n = numel(c_path);
    rm_v = h.Vertices;
    rm_c = (rm_v(1:3:end, :) + (rm_v(2:3:end, :) + rm_v(3:3:end, :))/2)/2;
    iv_own = h.UserData.Index;                            % element of each dot (face)
    assert(numel(iv_own) == size(rm_c, 1), "UserData.Index に点ごとの要素")
    sct = struct("n_dot", zeros(n, 1), "r_spacing", nan(n, 1), "rv_phase", nan(n, 1), "r_off", 0);
    for i = 1:n
        lv = iv_own == i;
        sct.n_dot(i) = nnz(lv);
        if ~any(lv)
            continue
        end
        [rv_s, rv_d] = arclength(c_path{i}, rm_c(lv, :));
        sct.r_off = max([sct.r_off; rv_d]);
        rv_s = sort(rv_s);
        if numel(rv_s) > 1
            sct.r_spacing(i) = min(diff(rv_s));
        end
        rv_ph = mod(rv_s, r_delta);
        rv_ph = rv_ph(1) + mod(rv_ph - rv_ph(1) + r_delta/2, r_delta) - r_delta/2;
        assert(max(abs(rv_ph - rv_ph(1))) < 1e-6, "1 つの要素の点は同じ位相 (間隔 0.25*d0)")
        sct.rv_phase(i) = rv_ph(1);
    end
end

function [rv_s, rv_d] = arclength(rm_p, rm_x)
% 点 rm_x の、折れ線 rm_p (3D) の上の弧長と、線からの距離
    rm_p = rm_p([true; any(diff(rm_p, 1, 1) ~= 0, 2)], :);
    rv_cum = [0; cumsum(vecnorm(diff(rm_p, 1, 1), 2, 2))];
    rv_s = zeros(size(rm_x, 1), 1);
    rv_d = inf(size(rm_x, 1), 1);
    for m = 1:size(rm_p, 1) - 1
        a = rm_p(m, :);
        u = rm_p(m+1, :) - a;
        L = norm(u);
        tt = min(max((rm_x - a)*u'/L^2, 0), 1);
        dd = vecnorm(rm_x - (a + tt.*u), 2, 2);
        lv = dd < rv_d - 1e-12;
        rv_d(lv) = dd(lv);
        rv_s(lv) = rv_cum(m) + tt(lv)*L;
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

function restore_path(s_dir, sct_warn, s_tag)
% batchStartupOptionUsed を隠す一時フォルダを外して消し、残った timer を消す
    rmpath(s_dir);
    rmdir(s_dir, "s");
    warning(sct_warn);
    hv_t = timerfindall("Tag", s_tag);
    if ~isempty(hv_t)
        stop(hv_t);
        delete(hv_t);
    end
end

function delete_if_exists(s_file)
    if isfile(s_file)
        delete(s_file);
    end
end
