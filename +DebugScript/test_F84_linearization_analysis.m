% F84 線形化結果の解析 (ResultLIN の固有値・固有ベクトル・核・縮約行列・表示)
%
%   lambda = res.get_eigenvalue(Type);                       % 有限固有値 (実部の大きい順、get_mode と同じ順)
%   sct = res.get_participation(Type=);                     % 状態と母線の参加率 (tab_bus)
%   sct = res.get_eigenvector(Type);                         % 右 / 左固有ベクトル (cm_right, cm_left) の構造体
%   sct = res.get_kernel(Tolerance=);                        % DAE のヤコビアンの核 (位相の回転、右と左の基底)
%   sct = res.get_reduced_matrix(target);                    % target の変数を消去したシューア補行列
%   res.disp_summary(Index=);  res.disp_mode(MinFrequency=, MaxFrequency=);
% どれも Index (既定 res.Index) / Time をとり、Index="all" で全断面をまとめて返す。
%
% 実行: runtests("DebugScript.test_F84_linearization_analysis")  または  DebugScript.run_all("Features","F84")

% 共通設定 (最初に 1 回だけ実行され、変数は全テストで共有される)
net9 = network.IEEE9bus(LocalController=true);
DebugScript.helper.quiet(@() net9.initialize());
res9 = net9.get_sys();
% 故障の模擬の 4 時刻の断面 (plot_eigenvalue と plot_eigenvalue_path)
ev9 = DebugScript.helper.scenario("fault", net9, "TimeSpan", [0.5, 0.55], "FaultBus", "B008");
sim9 = DebugScript.helper.quiet(@() net9.simulate(ev9.s_tag, Time=[0, 1.5]));
rv_ts = [0, 0.52, 0.8, 1.2];
resS = DebugScript.helper.quiet(@() net9.get_sys({sim9, rv_ts}));


%% get_eigenvalue is the finite eigenvalues in the order of get_mode
% 有限固有値の数は E の階数、実部の大きい順、Im >= 0 の行が get_mode の Eigenvalue 列
for s_type = ["ODE", "DAE"]
    sys = res9.get_ss(s_type, Format="struct");
    lam = res9.get_eigenvalue(s_type);
    assert(iscolumn(lam) && numel(lam) == rank(sys.E), s_type)
    assert(all(diff(real(lam)) <= 1e-9), s_type)
    tab = res9.get_mode(Type=s_type).tab_mode;
    assert(isequal(lam(imag(lam) >= -1e-6), tab.Eigenvalue), s_type)
    e = eig(full(sys.A), full(sys.E));
    assert(DebugScript.helper.same_eigs(lam, e(isfinite(e)), 1e-8), s_type)
end
assert(isequal(res9.get_eigenvalue(), res9.get_eigenvalue(res9.Type)))


%% Eigen pairs satisfy the equations, with the normalization of get_mode
% A v = lambda E v、w' A = lambda w' E、w' E v = 1。右ベクトルは get_mode の cm_shape (最大成分 1)。
% 対の共役は Im > 0 のすぐ後ろで、ベクトルも共役
for s_type = ["ODE", "DAE"]
    sys = res9.get_ss(s_type, Format="struct");
    sctV = res9.get_eigenvector(s_type);
    assert(isscalar(sctV) && isequal(sort(string(fieldnames(sctV)))', sort(["cm_right","cm_left","cv_lambda","sv_state","s_type"])), s_type)
    V = sctV.cm_right;  W = sctV.cm_left;  lam = sctV.cv_lambda;
    assert(isequal(lam, res9.get_eigenvalue(s_type)) && isequal(sctV.sv_state, sys.StateName) && sctV.s_type == s_type, s_type)
    r_scale = norm(sys.A, 1);
    assert(norm(sys.A*V - sys.E*V*diag(lam), 1) <= 1e-8*r_scale*max(1, max(abs(lam))), s_type)
    assert(norm(W'*sys.A - diag(lam)*W'*sys.E, 1) <= 1e-8*r_scale*max(1, max(abs(lam))) * norm(W, 1), s_type)
    assert(max(abs(diag(W'*sys.E*V) - 1)) <= 1e-8, s_type)
    assert(max(abs(max(abs(V), [], 1) - 1)) <= 1e-12, s_type)
    sct = res9.get_mode(Type=s_type);
    lv_mode = imag(lam) >= -1e-6;
    assert(norm(V(:, lv_mode) - sct.cm_shape, 1) <= 1e-12, s_type)
    iv_pair = find(imag(lam) > 1e-6);
    assert(isequal(lam(iv_pair+1), conj(lam(iv_pair))) && isequal(V(:, iv_pair+1), conj(V(:, iv_pair))), s_type)
end


%% get_participation sums the participation of get_mode by bus
% rm_value は get_mode の rm_participation、cv_lambda はその Eigenvalue 列 (同じ計算と順)。
% tab_bus は母線ごとに、その母線の機器と局所制御器の状態 (tab_variable.Bus) の和。DAE では
% 母線の変数も母線のもの。グローバル制御器の状態は tab_global。各モードで合計 1
for s_type = ["ODE", "DAE"]
    sct = res9.get_participation(Type=s_type);
    sctM = res9.get_mode(Type=s_type);
    assert(isscalar(sct) && sct.s_type == s_type && isequal(sct.rm_value, sctM.rm_participation), s_type)
    assert(isequal(sct.cv_lambda, sctM.tab_mode.Eigenvalue) && isequal(sct.sv_state, sctM.sv_state) && isequal(sct.sv_owner, sctM.sv_owner), s_type)
    tab = sct.tab_bus;
    assert(isequal(string(tab.Properties.VariableNames), ["Bus","Participation"]) && isequal(tab.Bus, "B00" + string(1:9)'), s_type)
    assert(isequal(size(tab.Participation), [9, numel(sct.cv_lambda)]) && height(sct.tab_global) == 0, s_type)
    assert(max(abs(sum(tab.Participation, 1) - 1)) <= 1e-12, s_type)
    lv_b2 = startsWith(sct.sv_owner, "B002SG1");    % B002SG1 と制御器 B002SG1CA1, B002SG1CP2
    assert(nnz(lv_b2) == 9 && max(abs(tab.Participation(2, :) - sum(sct.rm_value(lv_b2, :), 1))) <= 1e-12, s_type)
    assert(all(tab.Participation(4:9, :) <= 1e-12, "all"), s_type)   % 状態のない母線
end
% グローバル制御器の状態はどの母線にも属さない
netG = network.IEEE9bus(LocalController=true);
netG.add_global_controller("agc-PI", {netG.a_Bus{1}.a_Component{1}, "B002SG1"});
DebugScript.helper.quiet(@() netG.initialize());
resG = DebugScript.helper.quiet(@() netG.get_sys());
sct = resG.get_participation();
s_gc = resG.tab_variable.Owner(resG.tab_variable.Bus == "" & resG.tab_variable.Kind == "x");
assert(isscalar(s_gc) && isequal(sct.tab_global.Owner, s_gc) && isequal(string(sct.tab_global.Properties.VariableNames), ["Owner","Participation"]))
assert(isequal(sct.tab_global.Participation, sct.rm_value(sct.sv_owner == s_gc, :)))
assert(max(abs(sum(sct.tab_bus.Participation, 1) + sct.tab_global.Participation - 1)) <= 1e-12)
% Index "all" と Time
sct = resS.get_participation(Index="all");
assert(numel(sct) == 4 && isequal(sct(3), resS.get_participation(Time=0.8)) && isequal(sct(2).rm_value, resS.get_mode(Index=2).rm_participation))


%% The right kernel of the DAE is the rotation of the bus and generator angles
% J r = 0。r は位相の変数 (母線の theta と発電機の delta) で 1、他で 0。出力は構造体 1 つ。
% tab_phase は Index, Name, Owner, Kind ("Bus" / "Component"), Kernel, Right, Left
sct = res9.get_kernel();
sys = res9.get_ss("DAE", Format="struct");
assert(isstruct(sct) && isscalar(sct) && ~isfield(sct, "s_side") && ~isfield(sct, "rm_basis"))
assert(sct.s_message == "" && sct.n_dim == 1 && sct.s_port == "PQ")
assert(isequal(sct.sv_state, sys.StateName))
assert(norm(sys.A * sct.rm_right, 1) <= 1e-10 * norm(sys.A, 1))
sv_phase = [res9.tab_variable.Label(res9.tab_variable.Name == "delta"); "theta" + string(1:9)'];
assert(isequal(sort(sct.tab_phase.Name), sort(sv_phase)))
assert(isequal(sct.rm_right, double(ismember(sct.sv_state, sv_phase))))
tab = sct.tab_phase;
assert(isequal(string(tab.Properties.VariableNames), ["Index","Name","Owner","Kind","Kernel","Right","Left"]))
assert(isequal(tab.Name, sct.sv_state(tab.Index)) && all(tab.Right == 1) && all(tab.Kernel == 1))
assert(isequal(tab.Owner(tab.Kind == "Component"), ["B001SG1"; "B002SG1"; "B003SG1"]))
assert(isequal(tab.Owner(tab.Kind == "Bus"), "B00" + string(1:9)'))
assert(startsWith(error_id(@() res9.get_kernel(Side="left")), "MATLAB:"))   % no Side option


%% The left kernel is dual to the right one, and its entry at a delta is D/omega0 of the omega entry
% w' J = 0、w' r = 1。発電機の delta の式の成分は omega の式の成分の D/omega0 倍 (D = 0 なら 0)。
% tab_phase.Left は rm_left のその変数の成分
sct = res9.get_kernel();
sys = res9.get_ss("DAE", Format="struct");
assert(norm(sct.rm_left' * sys.A, 1) <= 1e-10 * norm(sys.A, 1) * norm(sct.rm_left, 1))
assert(abs(sct.rm_left' * sct.rm_right - 1) <= 1e-10)
tab = sct.tab_phase;
assert(isequal(tab.Left, sct.rm_left(tab.Index)))
r_omega0 = 2*pi*60;
for g = ["B001SG1", "B002SG1", "B003SG1"]
    w_d = sct.rm_left(sct.sv_state == "delta_" + g);
    w_w = sct.rm_left(sct.sv_state == "omega_" + g);
    comp = net9.a_Bus{str2double(extractBetween(g, 2, 4))}.a_Component{1};
    assert(abs(w_d / w_w - comp.tab_parameter.dynamics.D / r_omega0) <= 1e-8, g)
end
net0 = network.IEEE9bus(LocalController=true);
for b = 1:3
    net0.a_Bus{b}.a_Component{1}.tab_parameter.dynamics.D = 0;
end
DebugScript.helper.quiet(@() net0.initialize());
tab = net0.get_sys().get_kernel().tab_phase;
assert(max(abs(tab.Left(tab.Kind == "Component"))) <= 1e-10 && abs(sum(tab.Left) - 1) <= 1e-10)


%% Port I computes the kernel in Port PQ, and Port PI keeps its port
res = net9.get_sys(Port="I");
sct = res.get_kernel();
sct9 = res9.get_kernel();
assert(sct.s_port == "PQ" && isequal(sct.rm_right, sct9.rm_right) && isequal(sct.rm_left, sct9.rm_left))
res = net9.get_sys(Port="PI");
sct = res.get_kernel();
sys = res.get_ss("DAE", Format="struct");
assert(sct.s_port == "PI" && sct.n_dim == 1 && norm(sys.A * sct.rm_right, 1) <= 1e-10 * norm(sys.A, 1))


%% Two islands give two kernels, one indicator per island
% B001-B003 と B004-B005 の 2 つの島: 各列はその島の母線と発電機の角だけで 1、左は双対
net = DebugScript.helper.build_3bus("gen-1axis");
net.add_bus("V",1);
net.add_bus();
net.add_branch("pi",[4,5], "R",0, "X",0.1);
net.a_Bus{4}.add_component("gen-park", "P",0.5, "Q",nan);
net.a_Bus{5}.add_component("load-power", "P",-0.5, "Q",-0.1);
DebugScript.helper.quiet(@() net.initialize());
res = net.get_sys();
sys = res.get_ss("DAE", Format="struct");
sct = res.get_kernel();
assert(sct.n_dim == 2 && sct.s_message == "")
assert(norm(sys.A * sct.rm_right, 1) <= 1e-10 * norm(sys.A, 1))
assert(norm(sct.rm_left' * sct.rm_right - eye(2), 1) <= 1e-10)
tab = sct.tab_phase;
assert(isequal(sort(tab.Owner(tab.Kernel == 1 & tab.Kind == "Bus")), ["B001"; "B002"; "B003"]))
assert(isequal(sort(tab.Owner(tab.Kernel == 2 & tab.Kind == "Bus")), ["B004"; "B005"]))
assert(isequal(sort(tab.Owner(tab.Kernel == 2 & tab.Kind == "Component")), "B004SG1"))
assert(all(sum(sct.rm_right, 2) <= 1))
assert(isequal(tab.Left, sct.rm_left(sub2ind(size(sct.rm_left), tab.Index, tab.Kernel))))


%% A Tolerance below the rounding finds no kernel: empty bases and a message
sct = res9.get_kernel(Tolerance=1e-300);
assert(sct.n_dim == 0 && isempty(sct.rm_right) && isempty(sct.rm_left) && size(sct.rm_right, 1) == numel(sct.sv_state))
assert(height(sct.tab_phase) == 0 && contains(sct.s_message, "no kernel"), sct.s_message)


%% get_reduced_matrix with State settled (the default) is the Schur complement over the variables of the targets
% x = 機器と制御器の変数、r = 残り (母線の変数)。Jrr - Jrx / Jxx * Jxr と一致し、名前は残した変数
sct = res9.get_reduced_matrix(["Component", "LocalController"]);
assert(isequal(sct, res9.get_reduced_matrix(["Component", "LocalController"], State="settled")))
sys = res9.get_ss("DAE", Format="struct");
J = sys.A;
lv_x = ~startsWith(sys.StateName, ["theta", "rho"]);
R = J(~lv_x,~lv_x) - J(~lv_x,lv_x) / J(lv_x,lv_x) * J(lv_x,~lv_x);
assert(norm(sct.rm_value - R, 1) <= 1e-10 * norm(R, 1))
assert(isequal(sct.sv_row, sys.StateName(~lv_x), sct.sv_column) && isequal(sct.sv_eliminated, sys.StateName(lv_x)))
assert(sct.s_state == "settled" && isempty(sct.sv_held))
% the AVRs only: their states eliminated, the rest kept
sct = res9.get_reduced_matrix("controller.avr", State="settled");
lv_x = endsWith(sys.StateName, "CA1");
R = J(~lv_x,~lv_x) - J(~lv_x,lv_x) / J(lv_x,lv_x) * J(lv_x,~lv_x);
assert(norm(sct.rm_value - R, 1) <= 1e-10 * norm(R, 1) && isequal(sct.sv_eliminated, sys.StateName(lv_x)))
% a tag, and an element without variables eliminates nothing
sct = res9.get_reduced_matrix("B002SG1", State="settled");
assert(isequal(sct.sv_eliminated, ["delta_B002SG1"; "omega_B002SG1"; "Eq_B002SG1"]))
sct = res9.get_reduced_matrix("Branch", State="settled");
assert(isempty(sct.sv_eliminated) && isequal(sct.rm_value, full(J)))


%% get_reduced_matrix with State fixed removes the held states
% 対象の動的な状態 (E の行が 0 でない) は点の値に固定し、行と列を除くだけ (シューアの項なし)。
% 代数変数 (対象の母線の theta, rho) だけを Jrr - Jra / Jaa * Jar で消去する
sys = res9.get_ss("DAE", Format="struct");
J = full(sys.A);
sv_dev = ["Component", "LocalController"];
sct = res9.get_reduced_matrix(sv_dev, State="fixed");
assert(sct.s_state == "fixed")
% IEEE9 の AVR_ST1 の Vtr, Vst は時定数 0 で E の行が 0 (代数変数) なのでシューアで消去する
lv_x = ~startsWith(sys.StateName, ["theta", "rho"]);
lv_h = lv_x & any(sys.E, 2);
lv_a = lv_x & ~lv_h;
assert(nnz(lv_a) == 6 && all(startsWith(sys.StateName(lv_a), ["Vtr_", "Vst_"])))
R = J(~lv_x,~lv_x) - J(~lv_x,lv_a) / J(lv_a,lv_a) * J(lv_a,~lv_x);
assert(norm(sct.rm_value - R, 1) <= 1e-12 * norm(R, 1) && isequal(sct.sv_row, sys.StateName(~lv_x)))
assert(isequal(sct.sv_eliminated, sys.StateName(lv_x)) && isequal(sct.sv_held, sys.StateName(lv_h)))
% without algebraic variables in the targets it is J(r, r): the generators only
sct = res9.get_reduced_matrix("component.generator.abstract", State="fixed");
lv_x = endsWith(sys.StateName, "SG1");
assert(isequal(sct.rm_value, J(~lv_x, ~lv_x)) && isequal(sct.sv_held, sys.StateName(lv_x)))
% a generator with its bus: the states held, theta2 and rho2 eliminated by the Schur complement
sct = res9.get_reduced_matrix(["B002SG1", "B002"], State="fixed");
lv_h = ismember(sys.StateName, ["delta_B002SG1"; "omega_B002SG1"; "Eq_B002SG1"]);
lv_a = ismember(sys.StateName, ["theta2"; "rho2"]);
lv_r = ~(lv_h | lv_a);
R = J(lv_r,lv_r) - J(lv_r,lv_a) / J(lv_a,lv_a) * J(lv_a,lv_r);
assert(norm(sct.rm_value - R, 1) <= 1e-12 * norm(R, 1))
assert(isequal(sct.sv_held, sys.StateName(lv_h)) && isequal(sct.sv_eliminated, sys.StateName(lv_h | lv_a)))
assert(isequal(sct.sv_row, sys.StateName(lv_r)))


%% The reduced matrix with only the buses kept is the bus admittance seen from the buses
% Port I: 状態をもつ機器のない母線 (B004-B009) の行は、母線アドミタンスに負荷のアドミタンス
% y_L = -(Y V)_i / V_i を足したもの。行は [-Iim; Ire]、列は [Vre; Vim]。回転 [-Vim; Vre] は核に残る
% State fixed (瞬時) と settled (定常) のどちらでも同じ。settled だけが回転を核に残す
res = net9.get_sys(Port="I");
sctF = res.get_reduced_matrix(["Component", "LocalController"], State="fixed");
sct = res.get_reduced_matrix(["Component", "LocalController"], State="settled");
assert(isequal(sct.sv_row, ["Vre" + string(1:9)'; "Vim" + string(1:9)'], sctF.sv_row))
Y = res.sct_model.cm_Y;
V = res.sct_model.cv_V;
M = Y + diag(-(Y*V) ./ V);
iv_bus = 4:9;
R_exp = [-imag(M(iv_bus,:)), -real(M(iv_bus,:)); real(M(iv_bus,:)), -imag(M(iv_bus,:))];
for c = {sct, sctF}
    R = c{1}.rm_value([iv_bus, 9+iv_bus], :);
    assert(norm(R - R_exp, 1) <= 1e-10 * norm(R_exp, 1), c{1}.s_state)
end
assert(norm(sct.rm_value * [-imag(V); real(V)]) <= 1e-10 * norm(sct.rm_value, 1))


%% get_reduced_matrix errors: a singular Jxx, an unknown target, a layer other than the network
% すべてを消去すると Jxx = J (回転の核で特異)
assert(error_id(@() res9.get_reduced_matrix(["Component", "LocalController", "Bus"], State="settled")) == "GUILDA:ResultLIN:SingularReduction")
assert(error_id(@() res9.get_reduced_matrix("Component", State="steady")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() res9.get_reduced_matrix("nosuch")) == "GUILDA:ResultLIN:UnknownTarget")
resG = net9.a_Bus{1}.a_Component{1}.get_sys();
assert(error_id(@() resG.get_reduced_matrix("Component")) == "GUILDA:ResultLIN:NetworkOnly")
assert(error_id(@() resG.get_kernel()) == "GUILDA:ResultLIN:NetworkOnly")


%% Every method takes Index, Time and Index "all" over time sections
% 2 断面 (平衡点と、その近くの点) の結果: Index / Time で選んだ断面は 1 断面の結果と同じ。
% 2 番目の点は回路方程式を満たさない (母線の電流の残差が位相とともに回る) ので核はない。
% "all" は get_eigenvalue が Time と Index の列の表、get_eigenvector、get_mode、get_kernel、
% get_reduced_matrix は構造体配列、disp_* は断面ごとのブロック
p1 = res9.rv_point;
p2 = p1;
p2(1) = p2(1) + 0.05;
res = net9.get_sys([p1, p2]);
res2 = net9.get_sys(p2);
assert(isequal(res.get_eigenvalue(Index=2), res.get_eigenvalue(Time=2), res2.get_eigenvalue()))
tab = res.get_eigenvalue(Index="all");
assert(isequal(string(tab.Properties.VariableNames), ["Time","Index","Eigenvalue"]))
assert(isequal(tab.Eigenvalue(tab.Index == 1), res.get_eigenvalue(Index=1)) && isequal(tab.Eigenvalue(tab.Index == 2), res2.get_eigenvalue()))
assert(isequal(unique(tab.Time), [1; 2]))
sctV = res.get_eigenvector(Index="all");
assert(isstruct(sctV) && numel(sctV) == 2 && isequal(sctV(2).cv_lambda, res2.get_eigenvalue()) && isequal(sctV(1).sv_state, res.StateName))
assert(isequal(sctV(2), res2.get_eigenvector()) && isequal(sctV(1), res.get_eigenvector(Time=0.9)))
assert(startsWith(error_id(@() res9.get_eigenvector(Side="left")), "MATLAB:"))   % no Side option
sctM = res.get_mode(Index="all");
assert(numel(sctM) == 2 && isequal(sctM(2).cm_shape, res2.get_mode().cm_shape) && isequal(vertcat(sctM.tab_mode).Index, [ones(height(sctM(1).tab_mode),1); 2*ones(height(sctM(2).tab_mode),1)]))
sct = res.get_kernel(Index="all");
assert(numel(sct) == 2 && isequal([sct.n_dim], [1 0]))
assert(sct(1).s_message == "" && contains(sct(2).s_message, "no kernel") && isequal(sct(1).rm_right, res9.get_kernel().rm_right))
sct = res.get_reduced_matrix("Component", Index="all");
assert(numel(sct) == 2 && isequal(sct(2), res2.get_reduced_matrix("Component")))
assert(isequal(res.get_reduced_matrix("Component", Time=1.2), sct(1)))
assert(all([sct.s_state] == "settled"))
sct = res.get_reduced_matrix("Component", State="fixed", Index="all");
assert(numel(sct) == 2 && all([sct.s_state] == "fixed") && isequal(sct(2), res2.get_reduced_matrix("Component", State="fixed")))
assert(~isequal(sct(2).rm_value, res.get_reduced_matrix("Component", Index=2).rm_value))
s = res.disp_summary(Index="all");
assert(count(s, "Linearization of") == 2 && contains(s, "section 2 of 2"), s)
s = res.disp_mode(Index="all");
assert(count(s, "Modes of") == 2, s)
assert(error_id(@() res.get_eigenvalue(Index=3)) == "GUILDA:ResultLIN:IndexRange")
assert(error_id(@() res.get_kernel(Index="some")) == "GUILDA:ResultLIN:IndexForm")


%% plot_eigenvalue of several sections follows set_time and links with the simulation
% get_sys({sim, rv_t}) の断面の固有値を 1 つの GraphChart に持ち、set_time(t) で最も近い
% 断面の固有値 (stable / unstable) と題名を出す。始めは Index。1 断面の図は従来どおり
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
G = resS.plot_eigenvalue(Parent=fig, Index=2);
assert(isa(G, "GraphChart") && isequal(G.rv_t, rv_ts) && G.i_time == 2)
assert(isequal(G.tab_element.Tag, ["stable"; "unstable"]))
h = G.sct_plt.Element;
for k = [2, 1, 4]
    if k ~= 2
        G.set_time(rv_ts(k) + 0.01);
    end
    e = resS.get_eigenvalue(Index=k);
    assert(G.i_time == k && numel(h(1).XData) + numel(h(2).XData) == numel(e), "section " + k)
    assert(DebugScript.helper.same_eigs(complex([h(1).XData, h(2).XData], [h(1).YData, h(2).YData]).', e, 1e-8), "section " + k)
    assert(all(h(2).XData > 1e-6) && all(h(1).XData <= 1e-6))
    assert(contains(string(G.ax.Title.String), sprintf("section %d of 4", k)), string(G.ax.Title.String))
end
% 軸の範囲は全断面の固有値を含み、時刻で変わらない
e_all = resS.get_eigenvalue(Index="all").Eigenvalue;
assert(G.ax.XLim(1) <= min(real(e_all)) && G.ax.XLim(2) >= max([real(e_all); 0]))
assert(G.ax.YLim(1) <= min(imag(e_all)) && G.ax.YLim(2) >= max(imag(e_all)))
% 再生バーは断面の文字。同じ ResultODE のばね質点の図とリンク
w = findall(G.ax(1).Parent.Parent, "Tag", "GUILDA:GraphBase:TimeText");
assert(isscalar(w) && startsWith(w.Text, "Section 4 of 4"), w.Text)
S = sim9.plot_spring_model(Parent=uipanel(fig));
G.link(S);
S.set_time(0.8);
assert(G.i_time == 3 && startsWith(w.Text, "Section 3 of 4"))
G.set_time(1.2);
assert(abs(S.rv_t(S.i_time) - 1.2) <= max(diff(S.rv_t)))
% 1 断面の結果は従来どおり (時刻のパネルも時刻の操作もない)
G1 = res9.plot_eigenvalue(Parent=uipanel(fig));
assert(G1.rv_t == 0 && isempty(G1.sct_plt.Cursor) && string(G1.ax.Title.String) == "Eigenvalues (" + res9.Type + ")")
assert(error_id(@() resS.plot_eigenvalue(Index=5)) == "GUILDA:ResultLIN:IndexRange")


%% plot_eigenvalue_path draws the largest real part and the smallest damping ratio over the sections
% 2 つの時刻のパネル (最大の実部・最小の減衰比) を rv_t に対して描く。Tolerance を超えた
% 最初の断面に縦線 (固有値が複素なら Hopf、実なら instability)。plot_eigenvalue とリンク。
% 1 断面の結果はエラー
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
P = resS.plot_eigenvalue_path(Parent=uipanel(fig));
assert(isa(P, "GraphChart") && numel(P.ax) == 2 && isequal(P.rv_t, rv_ts))
assert(isequal(P.tab_element.Tag, ["max_real"; "min_damping"]) && numel(P.sct_plt.Cursor) == 2)
rv_re = zeros(1, 4);  rv_z = zeros(1, 4);  cv_lead = zeros(1, 4);
for k = 1:4
    tab = resS.get_mode(Index=k).tab_mode;
    e = resS.get_eigenvalue(Index=k);
    [rv_re(k), i] = max(real(e));
    cv_lead(k) = e(i);
    rv_z(k) = min(tab.DampingRatio, [], "omitnan");
end
h = P.sct_plt.Element;
assert(max(abs(h(1).YData - rv_re)) < 1e-9 && max(abs(h(2).YData - rv_z)) < 1e-9)
assert(isequal(h(1).XData, rv_ts) && P.ax(1).XLabel.String == "t [s]")
% Tolerance がすべての実部より大きいと縦線はない (y = 0 の点線だけ)
r_tol = max(rv_re) + 1;
P0 = resS.plot_eigenvalue_path(Tolerance=r_tol, Parent=uipanel(fig));
assert(all([P0.sct_plt.RefLine.Value] == 0) && numel(P0.sct_plt.RefLine) == 2)
% 故障中 (t = 0.52) の断面は不安定 (既定の Tolerance)
k_cross = find(rv_re > 1e-6, 1);
assert(~isempty(k_cross) && k_cross >= 2, "故障中の断面が不安定のはず")
hr = P.sct_plt.RefLine(arrayfun(@(h) isa(h, "matlab.graphics.chart.decoration.ConstantLine") && h.InterceptAxis == "x", P.sct_plt.RefLine));
assert(numel(hr) == 2 && all([hr.Value] == rv_ts(k_cross)))
s_kind = "instability";
if abs(imag(cv_lead(k_cross))) > 1e-6
    s_kind = "Hopf";
end
assert(startsWith(string(hr(1).Label), s_kind + " (section " + k_cross), string(hr(1).Label))
% plot_eigenvalue とリンクしてカーソルが動く
G = resS.plot_eigenvalue(Parent=uipanel(fig));
P.link(G);
G.set_time(0.8);
assert(P.i_time == 3 && all([P.sct_plt.Cursor.Value] == 0.8) && P.sct_plt.Cursor(1).Visible == "on")
% 行列の点の結果 (rv_t = 1:n) と Type
P2 = DebugScript.helper.quiet(@() net9.get_sys([res9.rv_point, res9.rv_point])).plot_eigenvalue_path(Type="DAE", Parent=uipanel(fig));
assert(isequal(P2.rv_t, [1 2]) && contains(string(P2.ax(1).Parent.Title.String), "DAE"))
assert(error_id(@() res9.plot_eigenvalue_path()) == "GUILDA:ResultLIN:OneSection")


%% disp_summary shows the model, the sizes, the status, the modes and the kernel
s = res9.disp_summary();
lam = res9.get_eigenvalue();
assert(startsWith(s, "Linearization of " + res9.s_network + " (layer PowerNetwork): usable"), s)
assert(contains(s, "- Model: Type ODE, Port PQ, point the equilibrium"), s)
assert(contains(s, "- Size: n_x = 27 states, n_v = 18 bus variables, n_u = " + nnz(res9.tab_variable.Kind == "u") + " inputs"), s)
assert(contains(s, "- Status: issue none, rcond(Avv) " + sprintf("%.3g", res9.output.rcond_Avv)), s)
assert(contains(s, sprintf("- Modes (ODE): %d eigenvalues, largest real part %.4g 1/s, 0 unstable, 1 zero", numel(lam), max(real(lam)))), s)
assert(contains(s, "- Kernel: dimension 1"), s)
assert(strtrim(evalc("res9.disp_summary()")) == s)
% a layer other than the network: a port model, no kernel
s = net9.a_Bus{1}.a_Component{1}.get_sys().disp_summary();
assert(contains(s, "- Model: port model of the layer") && ~contains(s, "Kernel"), s)


%% disp_mode prints the rows of get_mode, filtered by MinFrequency and MaxFrequency
tab = res9.get_mode(MinFrequency=0.1).tab_mode;
tab = tab(tab.Frequency <= 1, :);
s = res9.disp_mode(MinFrequency=0.1, MaxFrequency=1);
sv = splitlines(s);
assert(sv(1) == sprintf("Modes of %s (Type ODE): %d modes", res9.s_network, height(tab)), s)
assert(numel(sv) == height(tab) + 2 && contains(sv(2), ["Re [1/s]", "Freq [Hz]", "Damping [%]", "Dominant owner"]), s)
for j = 1:height(tab)
    assert(contains(sv(j+2), tab.DominantOwner(j)) && contains(sv(j+2), sprintf("%.2f", 100*tab.DampingRatio(j))), s)
end
s = res9.disp_mode();
assert(count(s, newline) == height(res9.get_mode().tab_mode) + 1)
assert(contains(s, " - "), "a real mode has no damping ratio")


function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        DebugScript.helper.quiet(fcn);
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
        if id == ""
            id = "(no id)";
        end
    end
end
