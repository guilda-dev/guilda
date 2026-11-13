% F39 シミュレーションのデータの約束 (build_simulation_data と SolverODE.solve) と Format="struct"
%
%   [sct_dae, sct_event, rv_x0, tab_phase] = net.build_simulation_data(tag, time);   % Hidden
%   [sct_sol, flag, output] = net.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);
%   sol = net.simulate(tag, Format="struct");     % モデルの階層を写した struct (表は変数名の列)
%
% solve はデータだけを受け取り、系統を読まない (系統を消しても同じ結果)。外乱は位置で表し、
% "zoh" の入力の各点は区間の境界になる。
%
% 実行: runtests("DebugScript.test_F39_simulation_data")  または  DebugScript.run_all("Features","F39")


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% solve reads only the data
% 発電機の解列 (再接続で f_reconnect を呼ぶ)、地絡、ブランチの開放、オフセット、入力を含む。
% 系統を delete した後でも、同じデータから同じ軌道になる
net = avr_pss_agc();
sc = net.add_scenario("all", Time=[0,3]);
sc.add_trip("B003SG1", [1,1.2]);
sc.add_fault("B008", [1.5,1.55]);
sc.add_open_branch(net.a_Branch{3}.s_tag, [2,2.5]);
sc.add_offset("B001SG1", "delta", 0.01, 0);
sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.01], [0.5, 2.5]);
[d, e, x0, tab_phase] = net.build_simulation_data(sc.s_tag, sc.Time);
opt = DebugScript.helper.ode_options("Progress", "none");
solver = net.solver_ODE;
[s1, f1] = solver.solve(d, e, x0, opt);
assert(f1 == 1)
assert(~has_handle_object(d) && ~has_handle_object(e), "データに handle の物体がある")
assert(height(tab_phase) == numel(e) && isequal(tab_phase.t1, [e.t1].'))
delete(net);
[s2, f2] = solver.solve(d, e, x0, opt);
assert(f2 == 1 && isequaln(s1, s2))


%% Disturbances are positions
net = avr_pss_agc();
sc = net.add_scenario("pos", Time=[0,3]);
sc.add_trip("B003SG1", [1,2]);
sc.add_trip(net.a_GlobalController{1}.s_tag, [1,2]);
sc.add_fault("B008", [1,2]);
sc.add_open_branch(["EL003","EL001"], [1,2]);
sc.add_offset("B001SG1", ["delta","omega"], [0.01, 0.02], 1);
[d, e, x0] = net.build_simulation_data(sc.s_tag, sc.Time);
ph = e(2);
assert(d.sv_comp(ph.iv_tripComp) == "B003SG1" && d.sv_gc(ph.iv_tripGC) == net.a_GlobalController{1}.s_tag)
assert(d.sv_bus(ph.iv_faultBus) == "B008")
assert(isequal(d.sv_branch(ph.iv_openBranch), ["EL001";"EL003"]) && issorted(ph.iv_openBranch))
assert(isequal(d.tab_variable.Name(ph.iv_offset), ["delta";"omega"]) && isequal(ph.rv_offset, [0.01;0.02]))
assert(all(d.tab_variable.Owner(ph.iv_offset) == "B001SG1"))
% 第 1 区間のオフセットは初期値に入る
sc.add_offset("B001SG1", "delta", 0.03, 0, Tag="first");
[d, e, x0] = net.build_simulation_data(sc.s_tag, sc.Time);
i_d = find(d.tab_variable.Owner == "B001SG1" & d.tab_variable.Name == "delta");
assert(isempty(e(1).iv_offset) && x0(i_d) == d.rv_equilibrium(i_d) + 0.03)
% 開放したブランチの行列: 全ブランチを閉じた Y から引くと、そのブランチを除いた Y
k = find(d.sv_branch == "EL003");
iv = d.im_branchBus(k,:);
Y = d.cm_Y;  Y(iv,iv) = Y(iv,iv) - d.c_branchY{k};
net2 = avr_pss_agc();  net2.remove_branch("EL003");
assert(max(abs(Y - net2.get_admittance_matrix().Variables), [], "all") < 1e-12)


%% Errors of the model checks keep the network IDs
net = avr_pss_agc();
net.a_Bus{1}.a_Component{1}.tab_parameter.dynamics.D = 3;
ME = caught(@() net.build_simulation_data(DebugScript.helper.no_disturbance(net), [0,1]));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:SimulateStale", DebugScript.helper.msg_id(ME))


%% Format struct mirrors the model hierarchy
net = avr_pss_agc();
sc = net.add_scenario("trip", Time=[0,2]);
sc.add_trip("B003SG1", [0.5,1]);
sc.add_trip(net.a_GlobalController{1}.s_tag, [1.2,1.5]);
[res, flag, output] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
[sol, flag2, output2] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag, Format="struct"));
assert(flag == 1 && flag2 == 1 && isequal(output.phases, output2.phases) && output2.tEnd == output.tEnd)
assert(isstruct(sol) && isequal(sol.t, res.rv_t) && sol.s_tag == "trip" && isequal(sol.phase, output.phases))
assert(all(ismember(sol.tab_variable.Kind, ["x","Vre","Vim","u","uc"])))
n_t = numel(sol.t);
assert(numel(sol.a_Bus) == numel(net.a_Bus) && numel(sol.a_GlobalController) == 1)

for i = 1:numel(net.a_Bus)
    b  = net.a_Bus{i};
    sb = sol.a_Bus{i};
    assert(sb.s_tag == b.s_tag)
    % 電圧は ResultODE の同じ列と一致し、どの表も高さは numel(sol.t)
    lv_V = res.tab_variable.Owner == b.s_tag & ismember(res.tab_variable.Kind, ["Vre","Vim"]);
    assert(nnz(lv_V) == 2 && isequaln(sb.V{:,:}, res.rm_variable(:, lv_V)))
    assert(isequal(string(sb.V.Properties.VariableNames), ["Vre","Vim"]) && height(sb.I) == n_t)
    assert(isequaln(sb.I{:,:}, res.rm_I(:, 2*i-1:2*i)))
    S = complex(sb.V.Vre, sb.V.Vim) .* conj(complex(sb.I.Ire, sb.I.Iim));
    assert(isequal(sb.P.P, real(S)) && isequal(sb.Q.Q, imag(S)))
    assert(numel(sb.a_Component) == numel(b.a_Component) && iscell(sb.a_Component) && size(sb.a_Component,2) == 1)
    I_sum = zeros(n_t, 2);
    for j = 1:numel(b.a_Component)
        c  = b.a_Component{j};
        sc_j = sb.a_Component{j};
        assert(sc_j.s_tag == c.s_tag && ~isfield(sc_j, "y"))
        assert(isequal(string(sc_j.x.Properties.VariableNames), string(c.sv_x(:)).') && height(sc_j.x) == n_t)
        assert(isequal(string(sc_j.u.Properties.VariableNames), string(c.sv_u(:)).') && height(sc_j.u) == n_t)
        I_sum = I_sum + sc_j.I{:,:};
        assert(numel(sc_j.a_LocalController) == numel(c.a_LocalController))
    end
    lv = sol.t > 0.001 & ~(sol.t >= 0.5 & sol.t <= 1);   % 解列の境界を除く
    assert(max(abs(I_sum(lv,:) - sb.I{lv,:}), [], "all") < 1e-4, "機器の電流の和が母線の電流と違う")
end

% 機器のない母線 (F29 と同じ 3 母線 + B004)
net3 = DebugScript.helper.build_3bus("load-impedance");
net3.add_bus();
net3.add_branch("pi", [3,4], "R", 0.01, "X", 0.1, "C", 0.01);
DebugScript.helper.quiet(@() net3.initialize);
sol3 = DebugScript.helper.quiet(@() net3.simulate(DebugScript.helper.no_disturbance(net3), Time=[0,0.1], Format="struct"));
assert(iscell(sol3.a_Bus{4}.a_Component) && isempty(sol3.a_Bus{4}.a_Component) && height(sol3.a_Bus{4}.V) == numel(sol3.t))
assert(isempty(sol3.a_GlobalController))

% 入れ子のローカル制御器: AVR の下の PSS
g1  = net.a_Bus{1}.a_Component{1};
avr = sol.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(avr.s_tag == g1.a_LocalController{1}.s_tag)
pss = avr.a_LocalController{1};
assert(pss.s_tag == g1.a_LocalController{1}.a_LocalController{1}.s_tag && isempty(pss.a_LocalController))
assert(height(pss.x) == n_t && width(pss.x) > 0 && height(avr.u) == n_t)

% 解列中の機器: 状態と入力は NaN、電流は 0
g3 = sol.a_Bus{3}.a_Component{1};
lv_trip = sol.t > 0.5 & sol.t < 1;
assert(all(isnan(g3.x{lv_trip,:}), "all") && all(isnan(g3.u{lv_trip,:}), "all") && all(g3.I{lv_trip,:} == 0, "all"))
assert(~any(isnan(g3.x{sol.t < 0.5,:}), "all") && any(g3.I{sol.t < 0.5,"Ire"} ~= 0))

% GC: 入力の列は <名前>_<機器タグ>、解列中は NaN
gc = net.a_GlobalController{1};
sg = sol.a_GlobalController{1};
assert(sg.s_tag == gc.s_tag)
sv_expect = strings(1,0);
for k = 1:numel(gc.controlledUnits)
    sv_expect = [sv_expect, string(gc.sv_u(:)).' + "_" + gc.controlledUnits{k}.s_tag]; %#ok<AGROW>
end
assert(isequal(string(sg.u.Properties.VariableNames), sv_expect), strjoin(string(sg.u.Properties.VariableNames)))
lv_trip = sol.t > 1.2 & sol.t < 1.5;
assert(all(isnan(sg.x{lv_trip,:}), "all") && all(isnan(sg.u{lv_trip,:}), "all"))
assert(~any(isnan(sg.u{sol.t < 1.2,:}), "all"))


%% A zoh input makes each point a phase boundary
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
g2  = net.a_Bus{2}.a_Component{1};
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
sc  = net.add_scenario("zoh", Time=[0,4]);
sc.add_input("B002SG1", "Pmech", [0, 0.01; 0.5, 0.03; 1.5, -0.01], [1,3], Method="zoh");
[res, flag, output] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
assert(flag == 1)
assert(isequal(output.phases.t1.', [0, 1, 1.5, 2.5, 3]), mat2str(output.phases.t1.'))
assert(all(output.phases{2:4, sc.tab_input.Tag}))
Pm = res.odeResults.Bus(2).Component(1).U.Pmech;
rv_val = [0, 0.01, 0.03, -0.01, 0];
for p = 1:5
    lv = res.rv_t > output.phases.t1(p) & res.rv_t < output.phases.t2(p);
    assert(max(abs(Pm(lv) - (Pm0 + rv_val(p)))) < 1e-10, "区間 " + p)
end
[~, e] = net.build_simulation_data(sc.s_tag, sc.Time);
assert(all(arrayfun(@(ev) all(cellfun(@isscalar, ev.c_input(:,2))), e)), "zoh は区間ごとに 1 点")


%% A spline input follows griddedInterpolant
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
g2  = net.a_Bus{2}.a_Component{1};
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
sc  = net.add_scenario("spline", Time=[0,3]);
rm_s = [0, 0; 0.4, 0.01; 0.8, 0.03; 1.2, 0.02; 1.6, 0];
sc.add_input("B002SG1", "Pmech", rm_s, [1,2.5], Method="spline");
res = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
Pm  = res.odeResults.Bus(2).Component(1).U.Pmech;
F   = griddedInterpolant(rm_s(:,1), rm_s(:,2), "spline", "nearest");
lv  = res.rv_t > 1.001 & res.rv_t < 2.499;
assert(max(abs(Pm(lv) - (Pm0 + F(res.rv_t(lv) - 1)))) < 1e-8)
[~, e] = net.build_simulation_data(sc.s_tag, sc.Time);
assert(e(2).c_input{1,4} == "spline" && isequal(e(2).c_input{1,2}, rm_s(:,1)))


function net = avr_pss_agc()
% IEEE14: 母線 1, 2 の発電機に AVR+PSS、両方を制御する agc-PI
    net = DebugScript.helper.build_ieee14();
    for i = 1:2
        net.a_Bus{i}.a_Component{1}.add_local_controller("avr-ST1");
        net.a_Bus{i}.a_Component{1}.add_local_controller("pss-PSS1");
    end
    DebugScript.helper.quiet(@() net.add_global_controller("agc-PI", {net.a_Bus{1}.a_Component{1}, net.a_Bus{2}.a_Component{1}}));
    DebugScript.helper.quiet(@() net.initialize);
end

function l = has_handle_object(v)
% 値に handle クラスの物体があるか (関数ハンドルは handle クラスではない)
    l = false;
    if isa(v, "handle")
        l = true;
    elseif isstruct(v)
        for k = 1:numel(v)
            for s_f = string(fieldnames(v)).'
                l = l || has_handle_object(v(k).(s_f));
            end
        end
    elseif iscell(v)
        l = any(cellfun(@has_handle_object, v), "all");
    elseif istable(v)
        l = any(varfun(@(c) has_handle_object(c), v, "OutputFormat", "uniform"));
    end
end

function ME = caught(f)
    ME = [];
    try
        DebugScript.helper.quiet(f);
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end
