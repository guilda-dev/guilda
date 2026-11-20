% F42 ブランチのイベントと解列 (シミュレーション)
%
%   sc.add_fault("EL003", [1,1.05], Status="3LG", Point=0.3);   % 1 回線の地絡
%   sc.add_open_branch("EL003", 1.05, Status="3open");    % 1 回線の開放
%   sc.add_trip(avr.s_tag, 1);                             % ローカル制御器の解列
%
% build_simulation_data は区間のブランチの状態 (sct_event.tab_branch) の異なる組ごとに
% net.get_admittance_matrix(BranchStatus=...) を 1 回呼び、行列のセル sct_dae.c_Y と区間ごとの
% 位置 sct_event.i_Y を SolverODE に渡す (c_Y{1} はすべて閉じた行列)。源 (観測される機器、
% ローカル制御器、グローバル制御器) が解列した入力は、源がないものとして平衡値をとる。解列した
% ローカル制御器の状態は終わりまで NaN (解列は終わりまで続く)。
%
% 実行: runtests("DebugScript.test_F42_branch_events")  または  DebugScript.run_all("Features","F42")


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% 6open is the old OpenBranch and the rebuilt Y matches the subtraction
net = ieee14();
sc1 = net.add_scenario("open", Time=[0,4]);
sc1.add_open_branch("EL003", 1);
sc2 = net.add_scenario("open6", Time=[0,4]);
sc2.add_open_branch("EL003", 1, Status="6open");
[r1, f1] = net.simulate(sc1.s_tag);
[r2, f2] = net.simulate(sc2.s_tag);
assert(f1 == 1 && f2 == 1 && isequaln(r1.rm_variable, r2.rm_variable) && isequaln(r1.rv_t, r2.rv_t))
% 作り直した行列と、全閉の行列からブランチの行列を引いた行列 (E1 までの計算) の差は丸めだけ
[d, e] = net.build_simulation_data(sc1.s_tag, sc1.Time);
assert(isequal([e.i_Y], [1, 2]) && numel(d.c_Y) == 2 && isequal(d.c_Y{1}, d.cm_Y))
k  = find(d.sv_branch == "EL003");
iv = d.im_branchBus(k,:);
Y_old = d.cm_Y;
Y_old(iv,iv) = Y_old(iv,iv) - net.a_Branch{k}.get_admittance_matrix();
r_diff = max(abs(d.c_Y{2} - Y_old), [], "all");
fprintf("[F42] 6open: max |c_Y{2} - (Y_closed - Y_branch)| = %g\n", r_diff);
assert(r_diff <= GUILDA.config("TimeSimulation").Tolerance.Value && r_diff < 1e-12)


%% 3open of two circuits halves the branch
net = ieee14();
br  = net.a_Branch{3};
assert(br.tab_parameter.dynamics.circuit == 2)
sc = net.add_scenario("half", Time=[0,3]);
sc.add_open_branch(br.s_tag, 1, Status="3open");
[d, e] = net.build_simulation_data(sc.s_tag, sc.Time);
iv = d.im_branchBus(3,:);
Y_ref = d.cm_Y;
Y_ref(iv,iv) = Y_ref(iv,iv) - br.get_admittance_matrix()/2;
assert(isequal([e.i_Y], [1, 2]) && max(abs(d.c_Y{2} - Y_ref), [], "all") < 1e-12)
% 結果の母線電流は各区間の行列と電圧から I = Y V (半分の線路に電流が流れる)
[res, flag] = net.simulate(sc.s_tag);
assert(flag == 1)
V = complex(res.rm_variable(:, res.tab_variable.Kind == "Vre"), res.rm_variable(:, res.tab_variable.Kind == "Vim"));
I = complex(res.rm_I(:, 1:2:end), res.rm_I(:, 2:2:end));
lv = res.rv_t > 1.001;
assert(max(abs(I(lv,:) - V(lv,:)*d.c_Y{2}.'), [], "all") < 1e-10)
assert(max(abs(I(lv,:) - V(lv,:)*d.cm_Y.'), [], "all") > 1e-3)


%% A 3LG near the to end is close to a fault of that bus
% ET020 は B007-B008 の変圧器 (受電端 B008 は発電機だけの母線)。定電力負荷のある母線の近くの
% 地絡は、負荷が電圧 0 付近で電力を受け取れず解けないので、B008 の側で比べる
net = avr_pss_agc();
br  = net.a_Branch{string(net.a_Branch) == "ET020"};
s_to = string(br.a_Bus{2});
assert(s_to == "B008")
sc_b = net.add_scenario("bus", Time=[0,2]);
sc_b.add_fault(s_to, [1,1.05]);
sc_l = net.add_scenario("line", Time=[0,2]);
sc_l.add_fault(br.s_tag, [1,1.05], Status="3LG", Point=1-1e-6);
[rb, fb] = net.simulate(sc_b.s_tag, SampleTime=0.01);
[rl, fl] = net.simulate(sc_l.s_tag, SampleTime=0.01);
assert(fb == 1 && fl == 1 && isequal(rb.rv_t, rl.rv_t))
lv_x = rb.tab_variable.Kind == "x";
r_rel = max(abs(rb.rm_variable(:, lv_x) - rl.rm_variable(:, lv_x)), [], "all") / max(abs(rb.rm_variable(:, lv_x)), [], "all");
fprintf("[F42] 3LG at Point 1-1e-6 vs BG at %s: relative difference of the states %g\n", s_to, r_rel);
assert(r_rel < 1e-3)


%% Combined branch states share one matrix per set
net = avr_pss_agc();
br  = net.a_Branch{3};
sc = net.add_scenario("comb", Time=[0,2]);
sc.add_fault(br.s_tag, [1,1.05], Status="3LG", Point=0.3);
sc.add_open_branch(br.s_tag, 1.05, Status="3open");
sc.add_fault("B008", [1.5,1.55]);
[d, e] = net.build_simulation_data(sc.s_tag, sc.Time);
assert(isequal([e.t1], [0, 1, 1.05, 1.5, 1.55]) && isequal([e.i_Y], [1, 2, 3, 3, 3]) && numel(d.c_Y) == 3)
assert(isequal(e(2).tab_branch.Status, "3LG") && e(2).tab_branch.Point == 0.3 && isequal(e(3).tab_branch.Status, "3open"))
tab_open = table(br.s_tag, "3open", NaN, VariableNames=["Target","Status","Point"]);
assert(isequal(d.c_Y{3}, net.get_admittance_matrix(BranchStatus=tab_open).Variables))
[~, flag] = net.simulate(sc.s_tag);
assert(flag == 1)
% 地絡の間に開放: 3LG と 3open は故障した回線の開放 (= 3open)。6LG と 3open は残りの回線の地絡
sc2 = net.add_scenario("comb2", Time=[0,2]);
sc2.add_fault(br.s_tag, [1,1.1], Status="3LG", Point=0.3);
sc2.add_fault("EL005", [1,1.1], Status="6LG", Point=0.4);
sc2.add_open_branch([br.s_tag; "EL005"], 1.05, Status="3open");
[d, e] = net.build_simulation_data(sc2.s_tag, sc2.Time);
assert(isequal([e.t1], [0, 1, 1.05, 1.1]) && numel(d.c_Y) == 4 && isequal([e.i_Y], [1, 2, 3, 4]), "開放は終わりまで")
assert(isequal(e(3).tab_branch.Target, [br.s_tag; br.s_tag; "EL005"; "EL005"]) ...
       && isequal(e(3).tab_branch.Status, ["3LG"; "3open"; "6LG"; "3open"]))
k5 = find(d.sv_branch == "EL005");
Y_ref = d.cm_Y;
for c_b = {3, br.get_admittance_matrix(Status="3open"); k5, net.a_Branch{k5}.get_admittance_matrix(Status="6LG", Point=0.4)/2}.'
    iv = d.im_branchBus(c_b{1},:);
    Y_ref(iv,iv) = Y_ref(iv,iv) - net.a_Branch{c_b{1}}.get_admittance_matrix() + c_b{2};
end
assert(max(abs(d.c_Y{3} - Y_ref), [], "all") < 1e-10)


%% An end at or after tend adds no boundary
net = ieee14();
for t_end = [20, Inf]
    sc = net.add_scenario("long", Time=[0,10]);
    sc.add_open_branch("EL003", 1);
    [d, e, ~, tab_phase] = net.build_simulation_data(sc.s_tag, [0,10]);
    assert(isequal(tab_phase.t1.', [0, 1]) && isequal(tab_phase.t2.', [1, 10]) && isequal([e.i_Y], [1, 2]) && numel(d.c_Y) == 2)
    net.remove_scenario(sc.s_tag);
end


%% A branch grounded on all circuits that cuts off a part without components is an error
% B004 は機器がなく、EL003 だけで B003 につながる
net3 = DebugScript.helper.build_3bus("load-impedance");
net3.add_bus();
net3.add_branch("pi", [3,4], "R", 0.01, "X", 0.1, "C", 0.01);
DebugScript.helper.quiet(@() net3.initialize);
sc = net3.add_scenario("g6", Time=[0,2]);
sc.add_fault("EL003", [1,1.5], Status="6LG", Point=0.5);
ME = caught(@() net3.build_simulation_data(sc.s_tag, sc.Time));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:OpenBranchIsland" && all(contains(ME.message, ["EL003", "B004"])), ME.message)
% 1 回線の地絡は両端を結んだまま
sc3 = net3.add_scenario("g3", Time=[0,2]);
sc3.add_fault("EL003", [1,1.5], Status="3LG", Point=0.5);
[~, e] = net3.build_simulation_data(sc3.s_tag, sc3.Time);
assert(numel(e) == 3)


%% A branch of one circuit has no 3LG and no 3open
net = ieee14();
net.a_Branch{3}.tab_parameter.dynamics.circuit = 1;
DebugScript.helper.quiet(@() net.initialize);
sc = net.add_scenario("one", Time=[0,2]);
assert(error_id(@() sc.add_open_branch("EL003", 1, Status="3open")) == "GUILDA:Scenario:SingleCircuit")
assert(error_id(@() sc.add_fault("EL003", [1,2], Status="3LG", Point=0.5)) == "GUILDA:Scenario:SingleCircuit")
assert(height(sc.tab_event) == 0)
% 追加の後に回線数を変えると、計算の前の検査で止まる
sc.add_open_branch("EL004", 1, Status="3open");
net.a_Branch{4}.tab_parameter.dynamics.circuit = 1;
DebugScript.helper.quiet(@() net.initialize);
assert(error_id(@() net.simulate(sc.s_tag)) == "GUILDA:Scenario:SingleCircuit")


%% A tripped source gives the equilibrium of the input
% 平衡値が 0 でないことを確かめるため、データの入力の平衡値だけを変えて SolverODE.solve で解く
% (入力の平衡値は源が解列した区間だけで使われる)
net = avr_pss_agc();
gc  = net.a_GlobalController{1};
s_pss = net.a_Bus{2}.a_Component{1}.a_LocalController{1}.a_LocalController{1}.s_tag;
sc = net.add_scenario("src", Time=[0,2]);
sc.add_trip("B002SG1", 1);
[d, e, x0] = net.build_simulation_data(sc.s_tag, sc.Time);
tab = d.tab_variable;
i_gc  = find(tab.Owner == gc.s_tag & tab.Kind == "uc" & endsWith(tab.Label, "omega_B002SG1_" + gc.s_tag));
i_gc2 = find(tab.Owner == gc.s_tag & tab.Kind == "uc" & endsWith(tab.Label, "omega_B001SG1_" + gc.s_tag));
i_pss = find(tab.Owner == s_pss & tab.Kind == "uc");
assert(isscalar(i_gc) && isscalar(i_gc2) && isscalar(i_pss))
d.rv_equilibrium([i_gc; i_pss]) = [0.01; 0.02];
[s, flag] = net.solver_ODE.solve(d, e, x0, DebugScript.helper.ode_options("Progress", "none"));
assert(flag == 1)
lv_trip = s.rv_phase == 2;
lv_on   = s.rv_phase ~= 2 & s.rv_t > 0;
assert(all(abs(s.rm_variable(lv_trip, i_gc) - 0.01) < 1e-10), "GC の観測は平衡値")
assert(all(abs(s.rm_variable(lv_trip, i_pss) - 0.02) < 1e-10), "LC の観測は平衡値")
assert(all(abs(s.rm_variable(lv_on, i_gc) - 0.01) > 1e-6), "接続中は機器の出力を読む")
i_om2 = find(tab.Owner == "B001SG1" & tab.Name == "omega" & tab.Kind == "x");
assert(max(abs(s.rm_variable(:, i_gc2) - s.rm_variable(:, i_om2))) < 1e-8, "解列していない機器の観測は変わらない")
% 解列した GC の "global" の接続は何も足さない: 発電機の Pmech は主な源 (平衡値) だけ
sc = net.add_scenario("gc", Time=[0,2]);
sc.add_trip(gc.s_tag, 1);
sc.add_input("B002SG1", "Pmech", 0.01, [0.5,1.5]);
res = net.simulate(sc.s_tag);
g1  = net.a_Bus{1}.a_Component{1};
Pm  = res.odeResults.Bus(1).Component(1).U.Pmech;
lv  = res.rv_t > 1.001 & res.rv_t < 1.499;
assert(any(lv) && max(abs(Pm(lv) - g1.rv_Uequilibrium(g1.sv_u == "Pmech"))) < 1e-12)
assert(max(abs(Pm(res.rv_t > 0.6 & res.rv_t < 0.999) - g1.rv_Uequilibrium(g1.sv_u == "Pmech"))) > 1e-6, "GC は接続中に Pmech を動かす")


%% A tripped local controller is NaN to the end
net = avr_pss_agc();
g1  = net.a_Bus{1}.a_Component{1};
avr = g1.a_LocalController{1};
pss = avr.a_LocalController{1};
Vf0 = g1.rv_Uequilibrium(g1.sv_u == "Vfield");
sc = net.add_scenario("avr", Time=[0,3]);
sc.add_trip(avr.s_tag, 1);
sc.add_fault("B008", [1,1.05]);
[res, flag] = net.simulate(sc.s_tag);
assert(flag == 1)
tab = res.tab_variable;
lv_avr = tab.Owner == avr.s_tag & tab.Kind == "x";
lv_pss = tab.Owner == pss.s_tag & tab.Kind == "x";
lv_trip = res.rv_t > 1 & res.rv_t < 1.5;
assert(any(lv_avr) && all(isnan(res.rm_variable(lv_trip, lv_avr)), "all"), "解列中の AVR の状態は NaN")
assert(all(isfinite(res.rm_variable(:, lv_pss)), "all"), "子の PSS は動き続ける")
assert(all(isfinite(res.rm_variable(res.rv_t < 1, lv_avr)), "all"))
assert(all(isnan(res.rm_variable(res.rv_t > 1, lv_avr)), "all"), "解列は終わりまで続く")
% 発電機の Vfield は終わりまで平衡値 (AVR の出力の代わり)
Vf = res.odeResults.Bus(1).Component(1).U.Vfield;
assert(max(abs(Vf(res.rv_t > 1) - Vf0)) < 1e-10)
% Format="struct" の x と u は NaN
sol = net.simulate(sc.s_tag, Format="struct");
s_avr = sol.a_Bus{1}.a_Component{1}.a_LocalController{1};
lv_trip = sol.t > 1;
assert(s_avr.s_tag == avr.s_tag && all(isnan(s_avr.x{lv_trip,:}), "all") && all(isnan(s_avr.u{lv_trip,:}), "all"))
assert(~any(isnan(s_avr.u{sol.t < 1,:}), "all") && ~any(isnan(s_avr.a_LocalController{1}.u{:,:}), "all"))
% 界磁喪失は Vfield への入力で明示する: 平衡値に -Vfield0 を足して 0
sc.add_input(g1.s_tag, "Vfield", -Vf0, [1,1.5]);
res = net.simulate(sc.s_tag);
Vf  = res.odeResults.Bus(1).Component(1).U.Vfield;
assert(max(abs(Vf(res.rv_t > 1 & res.rv_t < 1.5))) < 1e-10)


%% The inputs of a tripped unit are NaN in ResultODE and Format="struct"
% 負荷 (u)、AVR (uc)、GC (u: 観測) の入力は解列の後 NaN、前は有限。struct の表と同じ値
net = ieee14();
sc = net.add_scenario("load", Time=[0,3]);
sc.add_trip("B003LPQ2", 1);
[res, flag] = net.simulate(sc.s_tag);
sol = net.simulate(sc.s_tag, Format="struct");
assert(flag == 1 && isequal(sol.t, res.rv_t))
tab = res.tab_variable;
lv_u = tab.Owner == "B003LPQ2" & tab.Kind == "u";
U   = res.rm_variable(:, lv_u);
lv_trip = res.rv_t > 1;
assert(nnz(lv_u) == 2 && all(isnan(U(lv_trip,:)), "all"), "解列中の負荷の u は NaN")
assert(all(isfinite(U(res.rv_t < 1, :)), "all"), "解列の前の負荷の u は有限")
c_c = sol.a_Bus{3}.a_Component;
s_c = c_c{cellfun(@(c) c.s_tag == "B003LPQ2", c_c)};
assert(isequaln(s_c.u{:,:}, U))

net = avr_pss_agc();
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
gc  = net.a_GlobalController{1};
for s_tag = [avr.s_tag, gc.s_tag]
    sc = net.add_scenario("in_" + s_tag, Time=[0,3]);
    sc.add_trip(s_tag, 1);
    sc.add_fault("B008", [1,1.05]);
    [res, flag] = net.simulate(sc.s_tag);
    sol = net.simulate(sc.s_tag, Format="struct");
    assert(flag == 1 && isequal(sol.t, res.rv_t))
    tab = res.tab_variable;
    U   = res.rm_variable(:, tab.Owner == s_tag & ismember(tab.Kind, ["u","uc"]));
    lv_trip = res.rv_t > 1;
    assert(~isempty(U) && all(isnan(U(lv_trip,:)), "all"), "解列中の入力は NaN: " + s_tag)
    assert(all(isfinite(U(res.rv_t < 1, :)), "all"), "解列の前の入力は有限: " + s_tag)
    if s_tag == avr.s_tag
        s_b = sol.a_Bus{1}.a_Component{1}.a_LocalController{1};
    else
        s_b = sol.a_GlobalController{1};
    end
    assert(s_b.s_tag == s_tag && isequaln(s_b.u{:,:}, U))
end


%% A tripped PSS gives its equilibrium output 0 to the AVR
net = avr_pss_agc();
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
pss = avr.a_LocalController{1};
sc = net.add_scenario("pss", Time=[0,2]);
sc.add_trip(pss.s_tag, 1);
sc.add_fault("B008", [1,1.05]);
sol = net.simulate(sc.s_tag, Format="struct");
s_avr = sol.a_Bus{1}.a_Component{1}.a_LocalController{1};
s_pss = s_avr.a_LocalController{1};
lv_trip = sol.t > 1;
assert(s_pss.s_tag == pss.s_tag && all(isnan(s_pss.x{lv_trip,:}), "all"))
assert(all(abs(s_avr.u.Vpss(lv_trip)) < 1e-12), "解列の後は終わりまで 0")


% ---- local functions ----
function net = ieee14()
    net = DebugScript.helper.build_ieee14();
    DebugScript.helper.quiet(@() net.initialize);
end

function net = avr_pss_agc()
% IEEE14: 母線 1, 2 の発電機に AVR+PSS、両方を制御する agc-PI (F39 と同じ)
    net = DebugScript.helper.build_ieee14();
    for i = 1:2
        net.a_Bus{i}.a_Component{1}.add_local_controller("avr-ST1");
        net.a_Bus{i}.a_Component{1}.add_local_controller("pss-PSS1");
    end
    DebugScript.helper.quiet(@() net.add_global_controller("agc-PI", {net.a_Bus{1}.a_Component{1}, net.a_Bus{2}.a_Component{1}}));
    DebugScript.helper.quiet(@() net.initialize);
end

function s_id = error_id(f)
    s_id = "";
    try
        DebugScript.helper.quiet(f);
    catch ME
        s_id = string(DebugScript.helper.msg_id(ME));
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
