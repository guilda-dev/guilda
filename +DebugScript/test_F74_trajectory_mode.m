% F74 軌道の表 (ResultODE.get_trajectory) とモードの表 (ResultLIN.get_mode)
%
%   tab = result.get_trajectory(Quantity, Bus=, Owner=, Reference="none"|"COI");   % t と 1 所有者 1 列の table
%   sct = res.get_mode(Type=, MinFrequency=);   % sct.tab_mode: Eigenvalue, Frequency, DampingRatio, DominantOwner
%
% get_trajectory は plot_trajectory と同じ列 (plot_trajectory は get_trajectory を描く)。
% Reference="COI" は judge_out_of_step(Reference="COI") と同じ慣性中心 (M の重み付き平均)。
% get_mode と安定度制約付き OPF (sct_stability.tab_mode) は同じ計算 (tools.linear_modes) を使う。
%
% 実行: runtests("DebugScript.test_F74_trajectory_mode")  または  DebugScript.run_all("Features","F74")

% 各テストは新しい系統で始める
c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   %#ok<NASGU> 進捗表示なし


%% get_trajectory of the bus quantities matches odeResults and plot_trajectory
% Vabs, Vangle, P, Q は odeResults の V と PQ から作った値と一致し、列は t と母線のタグ。
% Bus の順に並び、plot_trajectory の線 (タグと YData) は get_trajectory の列と同じ
r = simulate_ieee9();
o = r.odeResults;
tab = r.get_trajectory();                                  % 既定は Vabs、全母線
assert(isequal(string(tab.Properties.VariableNames), ["t"; r.sv_bus].') && isequal(tab.t, r.rv_t))
assert(tab.Properties.Description == "Vabs" && isequal(string(tab.Properties.VariableUnits), ["s", repmat("pu", 1, 9)]))
for i = 1:numel(r.sv_bus)
    cv = o.Bus(i).V{:,:} * [1; 1j];
    b = r.sv_bus(i);
    assert(max(abs(tab.(b) - abs(cv))) < 1e-12)
    tabA = r.get_trajectory("Vangle", Bus=b);
    tabP = r.get_trajectory("P", Bus=b);
    tabQ = r.get_trajectory("Q", Bus=b);
    assert(max(abs(tabA.(b) - angle(cv))) < 1e-12 && max(abs(tabP.(b) - o.Bus(i).PQ.P)) < 1e-12 && max(abs(tabQ.(b) - o.Bus(i).PQ.Q)) < 1e-12)
end
tab = r.get_trajectory("Vabs", Bus=["B007", "B004"]);
assert(isequal(string(tab.Properties.VariableNames), ["t", "B007", "B004"]))
for s_q = ["Vabs", "P", "omega", "Vfield"]
    G = r.plot_trajectory(Quantity=s_q);
    tab = r.get_trajectory(s_q);
    sv_tag = string(tab.Properties.VariableNames(2:end));
    assert(isequal(reshape(G.tab_element.Tag, 1, []), sv_tag), s_q)
    for k = 1:numel(sv_tag)
        assert(isequaln(G.sct_plt.Element(k).YData(:), tab.(sv_tag(k))), s_q)
    end
    delete(ancestor(G.ax(1), "figure"));
end


%% get_trajectory of the components: states, inputs, outputs and the Owner filter
% omega (状態)、Vfield (入力)、機器の出力 y は odeResults の X・U・Y と一致する。
% Owner で列を絞り、Bus と Owner は両方かかる。未知の量・母線・所有者はエラー
r = simulate_ieee9();
o = r.odeResults;
tab = r.get_trajectory("omega");
assert(isequal(string(tab.Properties.VariableNames), ["t", "B001SG1", "B002SG1", "B003SG1"]))
assert(isequal(tab.B002SG1, o.Bus(2).Component(1).X.omega))
tab = r.get_trajectory("Vfield", Owner="B003SG1");
assert(isequal(string(tab.Properties.VariableNames), ["t", "B003SG1"]) && isequal(tab.B003SG1, o.Bus(3).Component(1).U.Vfield))
tab_y = r.tab_output(r.tab_output.Kind == "y" & r.tab_output.Owner == "B001SG1", :);
s_y = tab_y.Name(1);
tab = r.get_trajectory(s_y, Bus="B001");
assert(isequaln(tab.B001SG1, o.Bus(1).Component(1).Y.(s_y)))
tab = r.get_trajectory("omega", Bus=["B001", "B002"], Owner=["B002SG1", "B001SG1"]);
assert(isequal(string(tab.Properties.VariableNames), ["t", "B001SG1", "B002SG1"]))
tab = r.get_trajectory("P", Owner="B005");
assert(isequal(string(tab.Properties.VariableNames), ["t", "B005"]))
assert(error_id(@() r.get_trajectory("nosuch")) == "GUILDA:ResultODE:UnknownQuantity")
assert(error_id(@() r.get_trajectory("omega", Bus="B005")) == "GUILDA:ResultODE:UnknownQuantity")   % 発電機のない母線
assert(error_id(@() r.get_trajectory("omega", Bus="B099")) == "GUILDA:ResultODE:UnknownBus")
assert(error_id(@() r.get_trajectory("omega", Owner="B005")) == "GUILDA:ResultODE:UnknownOwner")
assert(error_id(@() r.get_trajectory("omega", Bus="B001", Owner="B002SG1")) == "GUILDA:ResultODE:UnknownOwner")
assert(error_id(@() r.get_trajectory("omega", Reference="slack")) == "MATLAB:validators:mustBeMember")


%% get_trajectory with Reference COI
% delta の COI 列は M の重み付き平均で、列 + COI がもとの値。最大の |delta - COI| は
% judge_out_of_step(Reference="COI") の MaxAngle。Vangle は delta の COI からの角を (-pi, pi] に
% 折り返したもの。omega の COI は omega の M の重み付き平均。Vabs, P, Q に COI はない
r = simulate_ieee9();
tab0 = r.get_trajectory("delta");
tab  = r.get_trajectory("delta", Reference="COI");
sv_g = ["B001SG1", "B002SG1", "B003SG1"];
assert(isequal(string(tab.Properties.VariableNames), ["t", sv_g, "COI"]) && contains(tab.Properties.Description, "center of inertia"))
rv_M = arrayfun(@(i) r.sct_network.a_Bus{i}.a_Component{1}.tab_parameter.dynamics.M, 1:3);
rv_coi = (tab0{:, sv_g} * rv_M.') / sum(rv_M);
assert(max(abs(tab.COI - rv_coi)) < 1e-12 && max(abs(tab{:, sv_g} + tab.COI - tab0{:, sv_g}), [], "all") < 1e-12)
v = r.judge_out_of_step(Reference="COI");
assert(abs(max(abs(tab{:, sv_g}), [], "all")*180/pi - v.MaxAngle) < 1e-9)
tabV = r.get_trajectory("Vangle", Reference="COI", Bus=["B004", "B007"]);
tabA = r.get_trajectory("Vangle", Bus=["B004", "B007"]);
assert(isequal(tabV.COI, tab.COI) && max(abs(exp(1j*tabV.B007) - exp(1j*(tabA.B007 - tab.COI)))) < 1e-12 && all(abs(tabV.B007) <= pi))
tab0 = r.get_trajectory("omega");
tab  = r.get_trajectory("omega", Reference="COI", Owner="B002SG1");
assert(isequal(string(tab.Properties.VariableNames), ["t", "B002SG1", "COI"]))
assert(max(abs(tab.COI - (tab0{:, sv_g} * rv_M.') / sum(rv_M))) < 1e-15 && max(abs(tab.B002SG1 + tab.COI - tab0.B002SG1)) < 1e-15)
for s_q = ["Vabs", "P", "Q"]
    assert(error_id(@() r.get_trajectory(s_q, Reference="COI")) == "GUILDA:ResultODE:NoCenterOfInertia", s_q)
end


%% get_trajectory with Reference COI leaves a tripped unit out of the center
% 解列中 (1〜1.5 s) の B003SG1 の delta・omega は NaN。その間の COI は残りの 2 機の M の重み付き平均で、
% B003SG1 の列は NaN のまま。解列の前後は 3 機の平均。judge_out_of_step の COI と同じ値を使う
net = network.IEEE9bus(LocalController=true);
DebugScript.helper.quiet(@() net.initialize());
sc = net.add_scenario("trip", Time=[0, 3]);
sc.add_trip("B003SG1", 1);
ws = warning("off", "all");  c_ws = onCleanup(@() warning(ws));
r = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
clear c_ws
sv_g = ["B001SG1", "B002SG1", "B003SG1"];
rv_M = arrayfun(@(i) r.sct_network.a_Bus{i}.a_Component{1}.tab_parameter.dynamics.M, 1:3);
for s_q = ["delta", "omega"]
    tab0 = r.get_trajectory(s_q);
    tab  = r.get_trajectory(s_q, Reference="COI");
    lv_off = isnan(tab0.B003SG1);
    assert(any(lv_off) && ~any(isnan(tab.COI)) && isequal(isnan(tab.B003SG1), lv_off), s_q)
    rv_on  = (tab0{~lv_off, sv_g} * rv_M.') / sum(rv_M);
    rv_off = (tab0{lv_off, sv_g(1:2)} * rv_M(1:2).') / sum(rv_M(1:2));
    assert(max(abs(tab.COI(~lv_off) - rv_on)) < 1e-12 && max(abs(tab.COI(lv_off) - rv_off)) < 1e-12, s_q)
    assert(max(abs(tab.B001SG1 + tab.COI - tab0.B001SG1)) < 1e-12, s_q)
end
v = r.judge_out_of_step(Reference="COI");
tab = r.get_trajectory("delta", Reference="COI");
assert(abs(max(abs(tab{:, sv_g}), [], "all", "omitnan")*180/pi - v.MaxAngle) < 1e-9)

%% get_mode of IEEE9bus: eigenvalues, damping ratios, frequencies and owners
% 行は eig(A, E) の有限の固有値のうち、複素共役の組の Im > 0 の方と実固有値 (ゼロ固有値を含む)。
% Frequency = |Im|/(2 pi)、DampingRatio = -Re/|lambda| (実のモードは NaN)。行は実部の大きい順。
% 参加係数は各モードで和 1、DominantOwner は所有者ごとの参加係数の和が最大のもの。
% モード形は右固有ベクトルで最大の要素が 1。MinFrequency は振動モードだけに絞る
net = network.IEEE9bus(LocalController=true);
DebugScript.helper.quiet(@() net.initialize());
res = net.get_sys();
sys = res.get_ss("ODE", Format="struct");
sct = res.get_mode();
tab = sct.tab_mode;
assert(isscalar(sct) && isequal(string(tab.Properties.VariableNames), ["Eigenvalue", "Frequency", "DampingRatio", "DominantOwner"]))
lam = eig(sys.A, sys.E);
lam = lam(isfinite(lam) & imag(lam) >= -1e-6);
assert(height(tab) == numel(lam) && max(abs(sort(tab.Eigenvalue) - sort(lam))) < 1e-9)
assert(issorted(real(tab.Eigenvalue), "descend"))
assert(max(abs(tab.Frequency - abs(imag(tab.Eigenvalue))/(2*pi))) < 1e-12)
lv_osc = abs(imag(tab.Eigenvalue)) > 1e-6;
assert(max(abs(tab.DampingRatio(lv_osc) + real(tab.Eigenvalue(lv_osc))./abs(tab.Eigenvalue(lv_osc)))) < 1e-12 && all(isnan(tab.DampingRatio(~lv_osc))))
assert(isequal(sct.sv_state, sys.StateName) && sct.s_type == "ODE" && isequal(size(sct.rm_participation), [numel(sys.StateName), height(tab)]))
assert(max(abs(sum(sct.rm_participation, 1) - 1)) < 1e-12 && all(sct.rm_participation >= 0, "all"))
assert(max(abs(max(abs(sct.cm_shape), [], 1) - 1)) < 1e-12)
assert(max(vecnorm(sys.A * sct.cm_shape - sys.E * sct.cm_shape .* tab.Eigenvalue.')) < 1e-8)   % 右固有ベクトル
tab_var = res.tab_variable;
[~, iv] = ismember(sys.StateName, tab_var.Label);
assert(isequal(sct.sv_owner, tab_var.Owner(iv)))
[sv_own, ~, iv_own] = unique(sct.sv_owner, "stable");
for k = 1:height(tab)
    [~, i_max] = max(accumarray(iv_own, sct.rm_participation(:, k)));
    assert(tab.DominantOwner(k) == sv_own(i_max))
end
% 電気機械モード 2 つ (0.58 Hz と 1.28 Hz) と、その減衰比
tab1 = res.get_mode(MinFrequency=0.5).tab_mode;
assert(height(tab1) == 2 && all(tab1.Frequency >= 0.5) && all(ismember(tab1.DominantOwner, ["B002SG1", "B003SG1"])))
assert(all(abs(sort(tab1.Frequency) - [0.5847; 1.2808]) < 1e-3) && all(abs(tab1.DampingRatio - 0.0406) < 1e-3))
tab2 = res.get_mode(MinFrequency=1e-9).tab_mode;
assert(all(abs(imag(tab2.Eigenvalue)) > 1e-6) && height(tab2) == nnz(lv_osc))
sct3 = res.get_mode(MinFrequency=1e6);
tab3 = sct3.tab_mode;
assert(height(tab3) == 0 && size(sct3.rm_participation, 2) == 0 && size(sct3.cm_shape, 2) == 0)
assert(error_id(@() res.get_mode(MinFrequency=-1)) == "MATLAB:validators:mustBeNonnegative")


%% get_mode of the DAE gives the modes of the ODE
% Type="DAE" (E が特異) の無限の固有値はモードではない。有限の固有値・所有者は ODE と同じで、
% 母線の変数 (代数変数) の参加係数は 0、その所有者は母線のタグ
net = network.IEEE9bus(LocalController=true);
DebugScript.helper.quiet(@() net.initialize());
res = net.get_sys();
tabO = res.get_mode().tab_mode;
sctD = res.get_mode(Type="DAE");
tabD = sctD.tab_mode;
assert(height(tabD) == height(tabO) && max(abs(tabD.Eigenvalue - tabO.Eigenvalue)) < 1e-8 && sctD.s_type == "DAE")
assert(isequal(tabD.DominantOwner, tabO.DominantOwner))
n_x = nnz(res.tab_variable.Kind == "x");
assert(all(sctD.rm_participation(n_x+1:end, :) < 1e-12, "all") && all(ismember(sctD.sv_owner(n_x+1:end), res.tab_variable.Bus(res.tab_variable.Kind == "Vre"))))
res.Type = "DAE";
assert(isequal(res.get_mode().tab_mode.Eigenvalue, tabD.Eigenvalue))


%% Stability-constrained OPF reports the modes of get_mode
% 安定度制約付き OPF の tab_mode は、解の点の get_sys の get_mode からゼロ固有値を除いたもの
% (同じ tools.linear_modes)。IEEE9 の制約なしの解 (StabilityMaxIteration=1) で確かめる
net = network.IEEE9bus(LocalController=true);
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method="AC OPF", MaxRealPart=100, StabilityMaxIteration=1));
tab_opf = res.sct_stability.tab_mode;
net2 = network.IEEE9bus(LocalController=true);
DebugScript.helper.quiet(@() net2.initialize(Method="OPF"));
tab = net2.get_sys().get_mode(Type="ODE").tab_mode;
tab = tab(abs(tab.Eigenvalue) > 1e-6*max(1, max(abs(tab.Eigenvalue))), :);
% get_mode の DominantOwner は OPF の tab_mode では Owner
assert(isequal(replace(string(tab.Properties.VariableNames), "DominantOwner", "Owner"), string(tab_opf.Properties.VariableNames)) && height(tab) == height(tab_opf))
[~, i1] = sort(real(tab_opf.Eigenvalue), "descend");
tab_opf = tab_opf(i1, :);
assert(max(abs(tab.Eigenvalue - tab_opf.Eigenvalue)) < 1e-6 && isequal(tab.DominantOwner, tab_opf.Owner))
assert(max(abs(tab.DampingRatio - tab_opf.DampingRatio)) < 1e-6 && isequaln(isnan(tab.DampingRatio), isnan(tab_opf.DampingRatio)))


%% Code suggestions of get_trajectory and get_mode
% functionSignatures.json (_auxiliary) に 2 つのメソッドの項目があり、Quantity・Bus・Owner の候補は
% 結果から作る (F34 が json と arguments ブロックの一致を確かめる)
s_aux = fullfile(GUILDA.pwd, "_GUILDAsystem", "_auxiliary", "resources", "functionSignatures.json");
s_txt = string(fileread(s_aux, "Encoding", "UTF-8"));
assert(contains(s_txt, """ResultLIN.get_mode"""))
s_entry = extractBetween(s_txt, """ResultODE.get_trajectory""", newline + "  }");
assert(isscalar(s_entry) && contains(s_entry, "obj.sv_bus") && contains(s_entry, "obj.c_component") && contains(s_entry, """Owner"""))

function r = simulate_ieee9()
% IEEE9bus の B007 の短い地絡 (1 s から 1.05 s、0〜3 s) の結果
    net = network.IEEE9bus(LocalController=true);
    DebugScript.helper.quiet(@() net.initialize());
    sc = net.add_scenario("fault", Time=[0, 3]);
    sc.add_fault("B007", [1, 1.05]);
    r = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
