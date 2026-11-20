% F97 連続潮流計算の各ステップの図 (ResultCPF の plot_*)
%
% ResultCPF の図はすべてステップ (1 … n_step) を標本にし、名前 "Step"、文字
% "Step k (λ = …)" を持つ。G1.link(G2) で PV 曲線・ネットワーク図・ばね質点の図・
% net.get_sys({res, steps}) の plot_eigenvalue / plot_eigenvalue_path が同じステップを示す。
%   G = res.plot_pvcurve();          % set_time(k) で各曲線のステップ k にマーカー
%   G = res.plot_diagram();          % GraphNetDiagram
%   G = res.plot_spring_model();     % GraphSpring2D / 3D
%   G = res.plot_stability_index();  % rv_sigmaMin と弱い母線
%   G = res.plot_generator(Quantity="Q");
%   G = res.plot_branch(Quantity="loading");
% 次も確かめる。
%   - 名前のある標本の animate / export_video は TimeStep を省くと 1 標本 1 枚 (秒の図は従来どおり)
%   - ステップのデータのない ResultCPF (手で作ったもの) は GUILDA:ResultCPF:NoStepData
%
% 実行: runtests("DebugScript.test_F97_cpf_analysis_plots")  または  DebugScript.run_all("Features","F97")

% 共通設定 (各テストの前に毎回実行される)
% 3 母線: B002 の発電機に Qmin/Qmax、EL002 に Smax を与え、Limits="Q" で Q の上限への切替を 1 回起こす
net = DebugScript.helper.build_3bus("gen-classical");
gen = net.a_Bus{2}.a_Component{1};
gen.tab_parameter.operation.Qmax = 0.8;
gen.tab_parameter.operation.Qmin = -0.3;
net.a_Branch{2}.tab_parameter.operation.Smax = 1.5;
DebugScript.helper.quiet(@() net.initialize);
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus="B003", Limits="Q", StepSize=0.3));
n_step = numel(res.rv_lambda);
k_nose = res.r_noseStep;
sv_text = "Step " + (1:n_step) + " (λ = " + compose("%.4g", res.rv_lambda) + ")";
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig(isgraphics(fig))));


%% plot_pvcurve takes the steps as samples with a marker cursor
G = res.plot_pvcurve(Parent=uipanel(fig));
assert(isequal(G.rv_t, 1:n_step) && isequal(G.tab_element.Tag, "B003"))
hv = G.sct_plt.CursorMarker;
assert(isscalar(hv) && hv.Visible == "off", "set_time の前は既定の見た目 (マーカーなし)")
assert(isequal(G.sct_plt.Element(1).XData, res.rv_lambda))
G.set_time(k_nose);
assert(hv.Visible == "on" && hv.XData == res.rv_lambda(k_nose) && abs(hv.YData - abs(res.cm_Vbus(3, k_nose))) < 1e-12)
% 再生バー: 文字はステップと λ。操作パネルに時刻の行はない
w = findall(G.ax(1).Parent.Parent, "Tag", "GUILDA:GraphBase:TimeText");
assert(isscalar(w) && w.Text == sv_text(k_nose))
h = G.show_controls(Parent=uipanel(fig));
assert(~any(string([h.UserData.sct_ctl.Property]) == "<time>"))
G = res.plot_pvcurve(Bus="all", Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, res.sv_bus) && numel(G.sct_plt.CursorMarker) == 3)


%% plot_diagram and plot_spring_model show the operating point of each step
D = res.plot_diagram(ColorMode="P", Parent=uipanel(fig));
assert(isa(D, "GraphNetDiagram") && isequal(D.rv_t, 1:n_step))
assert(isequal(D.sct_state.cm_Vbus, res.cm_Vbus) && isequal(D.sct_state.cm_Icomp, res.cm_Icomponent))
D.set_time(k_nose);
assert(D.i_time == k_nose && string(D.ax.Title.String) == sv_text(k_nose), "題名はステップの文字")
S = res.plot_spring_model(Parent=uipanel(fig));
assert(isa(S, "GraphSpring2D") && isequal(S.rv_t, 1:n_step))
S.set_time(5);
assert(contains(string(S.ax.Title.String), sv_text(5)))
assert(ismember("B002SG1", S.tab_element.Tag))
S3 = res.plot_spring_model(Dimension=3, Parent=uipanel(fig));
assert(isa(S3, "GraphSpring3D") && isequal(S3.rv_t, 1:n_step))
% ネットワーク図のブランチの流れは plot_branch と同じ
B = res.plot_branch(Quantity="P", Parent=uipanel(fig));
cm_Ibr = D.sct_state.cm_Ibranch;            % 2 n_branch x n_step (from, to の順)
a_br = res.sct_network.a_Branch;
for k = 1:numel(a_br)
    i_from = find(string(a_br{k}.a_Bus{1}) == "net.a_Bus{" + (1:3) + "}");
    rv_P = real(res.cm_Vbus(i_from, :) .* conj(cm_Ibr(2*k-1, :)));
    assert(max(abs(B.sct_plt.Element(k).YData - rv_P)) < 1e-12)
end


%% Linked plots of the steps follow each other and the eigenvalues of net.get_sys({res, steps})
G = res.plot_pvcurve(Parent=uipanel(fig));
D = res.plot_diagram(Parent=uipanel(fig));
S = res.plot_spring_model(Parent=uipanel(fig));
iv_step = unique([1:10:n_step, k_nose]);
lin = DebugScript.helper.quiet(@() net.get_sys({res, iv_step}));
E = lin.plot_eigenvalue_path(Parent=uipanel(fig));
M = lin.plot_eigenvalue(Parent=uipanel(fig));
G.link(D); G.link(S); G.link(E); G.link(M);
D.set_time(k_nose);
i_sec = find(iv_step == k_nose);
assert(G.i_time == k_nose && S.i_time == k_nose && E.i_time == i_sec && M.i_time == i_sec)
assert(G.sct_plt.CursorMarker.XData == res.rv_lambda(k_nose))
E.set_time(iv_step(2));
assert(G.i_time == iv_step(2) && D.i_time == iv_step(2) && S.i_time == iv_step(2))
% 他の ResultCPF の図もステップでつながる
I = res.plot_stability_index(Parent=uipanel(fig));
Q = res.plot_generator(Parent=uipanel(fig));
I.link(G); Q.link(G);
G.set_time(7);
assert(I.i_time == 7 && Q.i_time == 7 && D.i_time == 7)
assert(I.sct_plt.CursorMarker(1).YData == res.rv_sigmaMin(7))


%% plot_stability_index draws sigmaMin against lambda and the weak buses at the nose
G = res.plot_stability_index(Parent=uipanel(fig));
tab = G.tab_element;
assert(isequal(tab.Tag, ["sigmaMin"; res.tab_weakbus.Bus]) && isequal(tab.Kind, ["line"; "bar"; "bar"; "bar"]))
assert(numel(G.ax) == 2 && isequal(G.sct_plt.Element(1).XData, res.rv_lambda) && isequal(G.sct_plt.Element(1).YData, res.rv_sigmaMin))
assert(isequal(G.rv_t, 1:n_step))
G = res.plot_stability_index(TopBus=1, Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, ["sigmaMin"; res.tab_weakbus.Bus(1)]))
G = res.plot_stability_index(TopBus=0, Parent=uipanel(fig));
assert(isscalar(G.ax) && height(G.tab_element) == 1)


%% plot_generator draws P, Q and the Q margin of the generators and marks the switches
% 発電機は powerflow の Q が NaN の機器 (スラックの B001SG1 と B002SG1)。Q は V conj(I)
G = res.plot_generator(Quantity="Q", Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, ["B001SG1"; "B002SG1"]))
rv_Q = imag(res.cm_Vbus(2, :) .* conj(res.cm_Icomponent(2, :)));
assert(max(abs(G.sct_plt.Element(2).YData - rv_Q)) < 1e-12)
k_sw = res.tab_switch.Step(1);
assert(height(res.tab_switch) == 1 && abs(rv_Q(k_sw) - 0.8) < 1e-6 && all(abs(rv_Q(k_sw:end) - 0.8) < 1e-6), "切替の後は Qmax")
% 切替の λ の縦線 (ラベル "B002 Qmax")
h_ref = findall(G.ax, "Type", "ConstantLine");
assert(any(string(get(h_ref, "Label")) == "B002 Qmax"))
assert(any([h_ref.Value] == res.tab_switch.lambda(1)))
G = res.plot_generator(Quantity="P", Generator="B002SG1", Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, "B002SG1") && max(abs(G.sct_plt.Element(1).YData - 0.5)) < 1e-6)
% Q の余裕: 限界のない B001SG1 は線なし。近い方 (Qmax) までの距離
G = res.plot_generator(Quantity="Qmargin", Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, "B002SG1"))
assert(max(abs(G.sct_plt.Element(1).YData - min(rv_Q + 0.3, 0.8 - rv_Q))) < 1e-12)
assert(abs(G.sct_plt.Element(1).YData(end)) < 1e-6)
assert(error_id(@() res.plot_generator(Generator="B003L1")) == "GUILDA:ResultCPF:UnknownGenerator")
G.set_time(k_sw);
assert(G.sct_plt.CursorMarker.XData == res.rv_lambda(k_sw))


%% plot_branch draws P, S, the loading and the loss of the branches
G = res.plot_branch(Quantity="S", Parent=uipanel(fig));
sv_br = string(cellfun(@(b) b.s_tag, res.sct_network.a_Branch, "UniformOutput", false));
assert(isequal(G.tab_element.Tag, sv_br(:)))
br = res.sct_network.a_Branch{2};
cm_V = res.cm_Vbus([2 3], :);
cm_S = cm_V .* conj(br.cm_Y * cm_V);
assert(max(abs(G.sct_plt.Element(2).YData - max(abs(cm_S), [], 1))) < 1e-12)
% 負荷率: Smax が有限の EL002 だけ。1 の点線
G = res.plot_branch(Quantity="loading", Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, sv_br(2)))
assert(max(abs(G.sct_plt.Element(1).YData - max(abs(cm_S), [], 1) / 1.5)) < 1e-12)
assert(any([findall(G.ax, "Type", "ConstantLine").Value] == 1))
% 損失: Branch なしは系統全体 ("total")、Branch ありはブランチごと
G = res.plot_branch(Quantity="loss", Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, "total"))
rv_loss = zeros(1, n_step);
for k = 1:numel(res.sct_network.a_Branch)
    b = res.sct_network.a_Branch{k};
    i_end = cellfun(@(s) find(string(s) == "net.a_Bus{" + (1:3) + "}"), b.a_Bus);
    cm_Vb = res.cm_Vbus(i_end, :);
    rv_loss = rv_loss + real(sum(cm_Vb .* conj(b.cm_Y * cm_Vb), 1));
end
assert(max(abs(G.sct_plt.Element(1).YData - rv_loss)) < 1e-12 && all(rv_loss > 0))
G = res.plot_branch(Quantity="loss", Branch="all", Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, sv_br(:)))
G = res.plot_branch(Quantity="P", Branch=sv_br(1), Parent=uipanel(fig));
assert(isequal(G.tab_element.Tag, sv_br(1)))
assert(error_id(@() res.plot_branch(Branch="EL099")) == "GUILDA:ResultCPF:UnknownBranch")
% Smax がどれも無限なら負荷率は描けない
net2 = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net2.initialize);
res2 = DebugScript.helper.quiet(@() net2.calculate_continuation_powerflow(LoadBus="B003", MaxIteration=5));
assert(error_id(@() res2.plot_branch(Quantity="loading")) == "GUILDA:ResultCPF:NoLimit")
assert(error_id(@() res2.plot_generator(Quantity="Qmargin")) == "GUILDA:ResultCPF:NoLimit")


%% animate and export_video play one frame per step by default
% 名前のある標本 (ステップ): TimeStep を省くと 1 標本 1 枚。秒の図は従来どおり TimeStep 0.05
res2 = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus="B003", MaxIteration=6));
n2 = numel(res2.rv_lambda);
G = res2.plot_pvcurve(Parent=uipanel(fig));
fig.UserData = [];
G.animate(Speed=Inf, UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(isequal(fig.UserData, 1:n2), "1 ステップ 1 枚")
fig.UserData = [];
G.animate(Speed=Inf, TimeStep=0.5, UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(numel(fig.UserData) == 2*(n2 - 1) + 1, "TimeStep を与えると従来どおり")
C = GraphChart(struct("rv_t", 0:0.1:0.5, "sct_panel", struct("l_time", true), ...
    "sct_series", struct("rv_x", 0:0.1:0.5, "rm_y", (0:0.1:0.5).', "sv_tag", "y")), Parent=uipanel(fig));
fig.UserData = [];
C.animate(Speed=Inf, UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(numel(fig.UserData) == 11, "秒の図は 0.05 s ごと")
% export_video: 1 ステップ 1 枚 (ネットワーク図の動画は F46 の large で確かめているので、ここは PV 曲線の軸だけ)
s_file = string(tempname) + ".mp4";
c_file = onCleanup(@() delete(s_file(isfile(s_file))));
fig.UserData = [];
G.export_video(s_file, HoldTime=0, Capture="axes", UpdateFcn=@(t) set(fig, "UserData", [fig.UserData, t]));
assert(isfile(s_file) && isequal(fig.UserData, 1:n2))
vr = VideoReader(s_file);
assert(vr.NumFrames == n2)


%% A ResultCPF without the data of the steps stops with NoStepData
r0 = ResultCPF([], "SolverCPF", struct(), true, struct(), 0, ["A"; "B"], [0 0.1], ones(2, 2));
G = r0.plot_pvcurve(Bus="all", Parent=uipanel(fig));          % PV 曲線はデータなしでも描ける
assert(isequal(G.rv_t, [1 2]))
for s_method = ["plot_diagram", "plot_spring_model", "plot_stability_index", "plot_generator", "plot_branch"]
    assert(error_id(@() r0.(s_method)()) == "GUILDA:ResultCPF:NoStepData", s_method)
end
% 経路のない結果でも PV 曲線は従来どおり
r1 = ResultCPF([], "SolverCPF", struct(), false, struct(), 0, ["A"; "B"], zeros(1, 0), zeros(2, 0));
G = r1.plot_pvcurve(Bus="all", Parent=uipanel(fig));
assert(isa(G, "GraphChart"))


function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        evalc("fcn();");
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
        if id == ""
            id = "(no id)";
        end
    end
end
