% F35 制御器の信号構造: グローバル制御器の観測と出力の振り分け
%
% グローバル制御器 (GC) は制御対象の出力 (同名の状態より優先) と状態を名前で観測し、全母線の電圧を V で
% 受け取る。GC の出力は、制御対象のローカル制御器 (LC、入れ子を含む) に同名の入力があればそのすべてへ
% (観測入力なら機器の出力との和)、なければ機器の同名の入力へ足される。
% 接続は net.get_variable_map の接続表 (Kind "global") だけが決める。add_global_controller は接続を INFO で示し、
% LC の編集 (add/remove_local_controller) で接続先が変わると、その編集が INFO で示す (simulate は何も示さない)。
% simulate の変数ベクトルは z = [x; V; I; u; uc] (変数表の順、u と uc は母線電流 I の後)。
% 右辺の値は PhaseProbe で ode の右辺から確かめ、ヤコビアンは右辺の中心差分と比べる。
% 試験用の GC は DebugScript.helper.RoutingGCStub。sv_u と sv_y は register_stub の Replace で変え、
% 変えた写しはそれぞれ別のクラス名で登録する (インスタンスのあるクラスは定義を読み直せないため)。
%
% 実行: runtests("DebugScript.test_F35_controller_signal_routing")  または  DebugScript.run_all("Features","F35")

% 共通設定 (各テストの前に毎回実行される)
c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)


%% A global controller reads an output of its unit before a state of the same name
% one_axis の omega は出力 (sv_y) と状態 (sv_x) の両方にある: 出力を読む。delta は状態だけ
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
c_od = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_od", ...
                                        Replace=["sv_u = ""omega""", "sv_u = [""omega"";""delta""]"]);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-od", {gen}, parameter=struct(beta=0)));
assert(isequal(gc.iv_obsY, [find(gen.sv_y == "omega"); 0]), mat2str(gc.iv_obsY))
assert(isequal(gc.iv_obsX, [0; find(gen.sv_x == "delta")]), mat2str(gc.iv_obsX))
% 出力にも状態にもない名前は追加できない (droop は omega を持たない)
c_stub = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc");
[net2, droop] = DebugScript.helper.build_3bus("gen-droop");
ME = caught(@() net2.add_global_controller("test-routing-gc", {droop}));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:GconPorts", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "output or state omega"), ME.message)
% 観測した値は u の中: 出力 omega をずらすと z の右辺が beta * omega だけ変わる
net.remove_global_controller(gc.s_tag);
gc_obs = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc", {gen}, parameter=struct(beta=2)));
DebugScript.helper.quiet(@() net.initialize);
d_w = 1e-3;
% GC の入力 omega は DAE の変数: 出力 omega をずらすとその残差 u - omega が -d_w、入力をずらすと dz/dt が beta * d_w
F = probe(net, @(o) shifted_rhs(o, zpos(net, gen, "x", "omega"), d_w));
assert(abs(F(zpos(net, gc_obs, "uc", "omega")) + d_w) < 1e-12, "u の残差 %g", F(zpos(net, gc_obs, "uc", "omega")))
F = probe(net, @(o) shifted_rhs(o, zpos(net, gc_obs, "uc", "omega"), d_w));
assert(abs(F(zpos(net, gc_obs, "x")) - 2*d_w) < 1e-12, "dz/dt = %g", F(zpos(net, gc_obs, "x")))
[sol, flag] = net.simulate(DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B003").s_tag, Time=[0,2]);
assert(flag == 1 && isa(sol, "ResultODE"))


%% An output goes to an external input of a local controller, not to the component
% 調速機の参照値 Pref: GC の出力は調速機の入力 Pref に入り、機器の入力 Pmech には入らない
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gov = gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
c_pref = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_pref", ...
                                          Replace=["sv_y = ""Pmech""", "sv_y = ""Pref"""]);
s_info = evalc("gc = net.add_global_controller(""test-routing-gc-pref"", {gen}, parameter=struct(alpha=3));");
assert(contains(s_info, "INFO: ") && contains(s_info, ysrc(gc, gen, "Pref") + " -> " + gov.attach_tag("Pref")), s_info)
assert(isequal(gc_targets(net, gc), string(gov.attach_tag("Pref"))), join(gc_targets(net, gc), ", "))
DebugScript.helper.quiet(@() net.initialize);
d_z = 1e-2;
F = probe(net, @(o) shifted_rhs(o, zpos(net, gc, "x"), d_z));
% 残差 u - (平衡値 + y_GC): y_GC = -alpha z
assert(abs(F(zpos(net, gov, "uc", "Pref")) - 3*d_z) < 1e-12, "Pref の残差 %g", F(zpos(net, gov, "uc", "Pref")))
assert(abs(F(zpos(net, gen, "u", "Pmech"))) < 1e-12, "Pmech の残差 %g", F(zpos(net, gen, "u", "Pmech")))
% Pmech を出す GC は機器の入力に足される (調速機の出力との和)
c_stub = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc");
s_info = evalc("gc2 = net.add_global_controller(""test-routing-gc"", {gen}, parameter=struct(alpha=2));");
assert(contains(s_info, ysrc(gc2, gen, "Pmech") + " -> " + gen.attach_tag("Pmech")), s_info)
net.remove_global_controller(gc.s_tag);
DebugScript.helper.quiet(@() net.initialize);
F = probe(net, @(o) shifted_rhs(o, zpos(net, gc2, "x"), d_z));
assert(abs(F(zpos(net, gen, "u", "Pmech")) - 2*d_z) < 1e-12, "Pmech の残差 %g", F(zpos(net, gen, "u", "Pmech")))


%% An observation input receives the sum of the component output and the global controller
% PSS と調速機はともに omega を観測する: GC の出力 omega は両方に入り、どちらも y_mac + y_GC を受け取る
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
gov = gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
c_omega = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_omega", ...
                                           Replace=["sv_y = ""Pmech""", "sv_y = ""omega"""]);
s_info = evalc("gc = net.add_global_controller(""test-routing-gc-omega"", {gen}, parameter=struct(alpha=3));");
assert(contains(s_info, ysrc(gc, gen, "omega") + " -> " + pss.attach_tag("omega")) && ...
       contains(s_info, ysrc(gc, gen, "omega") + " -> " + gov.attach_tag("omega")), s_info)
s_run = evalc("net.initialize(); net.simulate(DebugScript.helper.noop_event(net,[0,0.1]).s_tag, Time=[0,0.1]);");
assert(~contains(s_run, "elsewhere"), "simulate が振り分けを表示した: " + s_run)
DebugScript.helper.quiet(@() net.initialize);
d_z = 1e-2;  d_w = 4e-3;
F = probe(net, @(o) shifted_rhs(o, [zpos(net, gc, "x"); zpos(net, gen, "x", "omega")], [d_z; d_w]));
% 残差 u - (omega + y_GC) = 0 - (d_w - 3 d_z)
r_expected = 3*d_z - d_w;
for con = {pss, gov}
    r = F(zpos(net, con{1}, "uc", "omega"));
    assert(abs(r - r_expected) < 1e-12, "%s の omega の残差 %g (期待 %g)", con{1}.s_tag, r, r_expected)
end


%% Two local controllers with the same input name both receive the output
% 接続先は接続表 (Kind "global") と、LC の validate の inputs に現れる
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
gov = gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
c_omega = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_omega", ...
                                           Replace=["sv_y = ""Pmech""", "sv_y = ""omega"""]);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-omega", {gen}));
assert(isequal(gc_targets(net, gc), string([pss.attach_tag("omega"); gov.attach_tag("omega")])), join(gc_targets(net, gc), ", "))
DebugScript.helper.quiet(@() net.initialize);
for con = {pss, gov}
    flag = con{1}.validate(false);
    assert(flag.inputs{"omega","source"} == "output of " + gen.s_tag + " + output of " + gc.s_tag, flag.inputs{"omega","source"})
end


%% A changed routing after remove_local_controller is reported once
% LC の入力 Pmech (試験用の LC) に入っていた出力は、LC を外すと機器の入力 Pmech へ直接入る。
% 変化は remove_local_controller が 1 度だけ示し、simulate は示さない (振り分けを記録しない)
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
c_lc = DebugScript.helper.register_stub("ObserveStub", "controller.test_observe");
lc = gen.add_local_controller("test-observe", parameter=struct(Input="Pmech"));
c_stub = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc");
s_info = evalc("gc = net.add_global_controller(""test-routing-gc"", {gen});");
assert(contains(s_info, ysrc(gc, gen, "Pmech") + " -> " + lc.attach_tag("Pmech")), s_info)
DebugScript.helper.quiet(@() net.initialize);
s_run = evalc("net.simulate(DebugScript.helper.noop_event(net,[0,0.1]).s_tag, Time=[0,0.1]);");
assert(~contains(s_run, "elsewhere"), s_run)
s_rm = evalc("gen.remove_local_controller(lc.s_tag);");
assert(contains(s_rm, "INFO: ") && contains(s_rm, "elsewhere now") && ...
       contains(s_rm, ysrc(gc, gen, "Pmech") + " -> " + gen.attach_tag("Pmech")), s_rm)
assert(isequal(gc_targets(net, gc), string(gen.attach_tag("Pmech"))), join(gc_targets(net, gc), ", "))
DebugScript.helper.quiet(@() net.initialize);
s_run = evalc("net.simulate(DebugScript.helper.noop_event(net,[0,0.1]).s_tag, Time=[0,0.1]);");
assert(~contains(s_run, "elsewhere"), "simulate が振り分けを表示した: " + s_run)
% 振り分けの変わらない編集は何も示さない (調速機は Pmech を入力に持たない)
s_add = evalc("gov = gen.add_local_controller(""gov-LPT1"", parameter=struct(PLM=5));");
assert(~contains(s_add, "elsewhere"), s_add)
% 接続先がなくなった出力は編集で示し、simulate はエラー (Pref は調速機にしかない)
c_pref = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_pref", ...
                                          Replace=["sv_y = ""Pmech""", "sv_y = ""Pref"""]);
net.remove_global_controller(gc.s_tag);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-pref", {gen}));
s_rm = evalc("gen.remove_local_controller(gov.s_tag);");
assert(contains(s_rm, ysrc(gc, gen, "Pref") + " -> (no input)"), s_rm)
DebugScript.helper.quiet(@() net.initialize);
ME = caught(@() net.simulate(DebugScript.helper.noop_event(net,[0,0.1]).s_tag, Time=[0,0.1]));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:GconNoTarget", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "Pref") && contains(ME.message, gen.s_tag), ME.message)


%% The Jacobian matches finite differences with a global controller on outputs and voltages
% 出力 omega を観測し、全母線の電圧 (母線 1) に依存し、出力 omega (PSS と調速機) と Pref (調速機) を出す
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gen.add_local_controller("avr-ST1");
gen.add_local_controller("pss-PSS1");
gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
DebugScript.helper.quiet(@() net.initialize);
V0 = abs(net.a_Bus{1}.c_Vequilibrium);
c_two = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_two", ...
                                         Replace=["sv_y = ""Pmech""", "sv_y = [""omega"";""Pref""]"]);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-two", {gen}, ...
                                                            parameter=struct(alpha=2, beta=3, gV=0.5, V0=V0)));
DebugScript.helper.quiet(@() net.initialize);
assert(all(gc.iv_obsY > 0))
c_err = probe_all(net, [0,1.2], {DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B003")}, @jacobian_error_ode);
err = [c_err{:}];
assert(numel(err) == 3 && max(err) < 1e-5, "誤差 " + mat2str(err,3))
% 全母線の電圧に依存すること (gV) が右辺に現れる
F = probe(net, @(o) shifted_rhs(o, zpos(net, net.a_Bus{1}, "Vre"), 1e-3));
assert(abs(F(zpos(net, gc, "x"))) > 1e-5, "母線 1 の電圧が GC に届かない: %g", F(zpos(net, gc, "x")))


%% The linear model agrees with the Jacobian of the simulation
% net.linearize (Kron, Feedback, DAE) の有限な固有値は、simulate の DAE の Jacobian の有限な固有値と同じ
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gen.add_local_controller("avr-ST1");
gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
DebugScript.helper.quiet(@() net.initialize);
V0 = abs(net.a_Bus{1}.c_Vequilibrium);
c_three = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_three", ...
                                           Replace=["sv_y = ""Pmech""", "sv_y = [""omega"";""Pref"";""Vfield""]"]);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-three", {gen}, ...
                                                            parameter=struct(alpha=0.2, beta=3, gV=0.5, V0=V0)));
DebugScript.helper.quiet(@() net.initialize);
res = net.linearize();
e_sim = probe(net, @(o) finite_eigs_ode(o));
for s_method = ["Kron","Feedback","DAE"]
    e_lin = DebugScript.helper.finite_eigs(res.get_ss(s_method, Format="struct"));
    assert(DebugScript.helper.same_eigs(e_lin, e_sim, 1e-6), "%s: %s / %s", s_method, mat2str(e_lin,4), mat2str(e_sim,4))
end
% GC の get_sys: 入力は全母線の電圧と観測した出力、出力は駆動する入力ごとの行
sys = gc.get_sys(Format="struct");
assert(numel(sys.InputName) == 2*numel(net.a_Bus) + 1)
assert(sys.InputName(end) == gen.attach_tag("Y_omega"), sys.InputName(end))
assert(isequal(sys.OutputName, [gen.a_LocalController{2}.attach_tag("omega"); gen.a_LocalController{2}.attach_tag("Pref"); ...
                                 gen.attach_tag("Vfield")]), join(sys.OutputName, ", "))


%% Feedback lets a global controller read the voltage of an eliminated bus
% B004 は機器のない母線で、Feedback はネットワークと一緒に消去する。GC は B004 の電圧を読む
% (以前は GUILDA:ResultLIN:GlobalControllerPort で止まった)。固有値は Kron、DAE、simulate と同じ
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
net.add_bus();
net.add_branch("pi",[3,4], "R",0.010, "X",0.050);
gen.add_local_controller("avr-ST1");
gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
DebugScript.helper.quiet(@() net.initialize);
V0 = abs(net.a_Bus{4}.c_Vequilibrium);
c_vb4 = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_vb4", ...
                                         Replace=["V(1:2)", "V(7:8)"; "Bxv(1:2)", "Bxv(7:8)"]);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-vb4", {gen}, ...
                                                            parameter=struct(alpha=0.2, beta=3, gV=0.5, V0=V0)));
DebugScript.helper.quiet(@() net.initialize);
res = net.linearize();
e_sim = probe(net, @(o) finite_eigs_ode(o));
for s_method = ["Kron","Feedback","DAE"]
    e_lin = DebugScript.helper.finite_eigs(res.get_ss(s_method, Format="struct"));
    assert(DebugScript.helper.same_eigs(e_lin, e_sim, 1e-6), "%s: %s / %s", s_method, mat2str(e_lin,4), mat2str(e_sim,4))
end
% 電圧は GC の観測に使うだけで、既定の出力には加えない
sysF = res.get_ss("Feedback", Format="struct");
assert(~any(contains(sysF.OutputName, "B004")), join(sysF.OutputName, ", "))
% B004 の電圧が GC に届いている: gV = 0 の GC とは固有値が違う
net.remove_global_controller(gc.s_tag);
DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-vb4", {gen}, ...
                                                       parameter=struct(alpha=0.2, beta=3, gV=0, V0=V0)));
DebugScript.helper.quiet(@() net.initialize);
e_0 = DebugScript.helper.finite_eigs(net.linearize().get_ss("Feedback", Format="struct"));
assert(~DebugScript.helper.same_eigs(e_0, DebugScript.helper.finite_eigs(sysF), 1e-6), "B004 の電圧が GC に届かない")


%% Feedback lets a global controller read the output of a component on an eliminated bus
% B004 の負荷 (DebugScript.helper.OutputLoadStub) は状態がなく、電流が V によらない (I-to-V の形がない)
% ので、Feedback はこの母線をネットワークと一緒に消去する。GC はこの負荷の出力 Vabs (= |V_4|) を読み、
% 負荷の入力 Ire へ返す。固有値は Kron、DAE、simulate と同じ
c_ld = DebugScript.helper.register_stub("OutputLoadStub", "component.load.test_output_load");
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
bus4 = net.add_bus();
net.add_branch("pi",[3,4], "R",0.010, "X",0.050);
ld = bus4.add_component("test-output-load");
gen.add_local_controller("avr-ST1");
gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
DebugScript.helper.quiet(@() net.initialize);
c_ly = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_ly", ...
                                        Replace=["sv_u = ""omega""", "sv_u = ""Vabs"""; "sv_y = ""Pmech""", "sv_y = ""Ire"""]);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-ly", {ld}, ...
                                                            parameter=struct(alpha=0.5, beta=3, gV=0)));
DebugScript.helper.quiet(@() net.initialize);
res = net.linearize();
e_sim = probe(net, @(o) finite_eigs_ode(o));
for s_method = ["Kron","Feedback","DAE"]
    e_lin = DebugScript.helper.finite_eigs(res.get_ss(s_method, Format="struct"));
    assert(DebugScript.helper.same_eigs(e_lin, e_sim, 1e-6), "%s: %s / %s", s_method, mat2str(e_lin,4), mat2str(e_sim,4))
end
% 出力は GC の観測に使うだけで、既定の出力には加えない
sysF = res.get_ss("Feedback", Format="struct");
assert(~any(contains(sysF.OutputName, [ld.s_tag, "B004"])), join(sysF.OutputName, ", "))
% 負荷の出力が GC に届いている: beta = 0 の GC とは固有値が違う
net.remove_global_controller(gc.s_tag);
DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-ly", {ld}, ...
                                                       parameter=struct(alpha=0.5, beta=0, gV=0)));
DebugScript.helper.quiet(@() net.initialize);
e_0 = DebugScript.helper.finite_eigs(net.linearize().get_ss("Feedback", Format="struct"));
assert(~DebugScript.helper.same_eigs(e_0, DebugScript.helper.finite_eigs(sysF), 1e-6), "B004 の負荷の出力が GC に届かない")


function iv = zpos(net, owner, s_kind, s_name)
% simulate の変数ベクトル z = [x; V; I; u; uc] での owner の行の位置 (変数表の順。u と uc は母線電流 I の後)
    tab = net.get_variable_map();
    lv = tab.Owner == string(owner.s_tag) & tab.Kind == s_kind;
    if nargin > 3
        lv = lv & tab.Name == s_name;
    end
    iv = find(lv);
    if ismember(s_kind, ["u","uc"])
        iv = iv + 2*numel(net.a_Bus);
    end
end

function s = ysrc(gc, unit, s_name)
% 制御対象 unit への gc の出力 s_name の Label (変数表の yc の行)
    s = string(gc.attach_tag(s_name + "_" + unit.s_tag));
end

function sv = gc_targets(net, gc)
% 接続表で gc の出力が入る入力 (Label)
    [tab, ~, ~, tab_c] = net.get_variable_map();
    lv = tab_c.Kind == "global" & tab.Owner(max(tab_c.SourceIndex,1)) == string(gc.s_tag);
    sv = tab_c.Target(lv);
end

function F = probe(net, f)
% 第 1 区間 (外乱なし) の ode に f を適用した値
    c = probe_all(net, [0,0.1], {DebugScript.helper.noop_event(net,[0,0.1])}, f);
    F = c{1};
end

function c_val = probe_all(net, tspan, c_events, f)
% 各区間の ode に f を適用した値 (区間の順)
    box = containers.Map("KeyType", "double", "ValueType", "any");
    sct_options = DebugScript.helper.ode_options("Progress", "none");
    sct_options.PhaseProbe = @(o) store(box, f(o));
    DebugScript.helper.quiet(@() net.solver_ODE.solve(net, tspan, c_events, sct_options));
    c_val = box.values;
end

function store(box, val)
    box(box.Count+1) = val;
end

function F = shifted_rhs(o, iv, d)
% 初期値の iv 番目を d だけずらした点での右辺
    x = o.InitialValue;
    x(iv) = x(iv) + d;
    F = o.ODEFcn(0, x);
end

function err = jacobian_error_ode(o)
% 解析的なヤコビアンと右辺の中心差分の最大誤差 (平衡点でだけ 0 になる項も確かめるため、ずらした点で)
    n  = numel(o.InitialValue);
    x  = o.InitialValue + 1e-3*sin(1:n)';
    J  = o.Jacobian.Jacobian(0, x);
    h  = 1e-6;
    Jn = zeros(n);
    for i = 1:n
        e = zeros(n,1);  e(i) = h;
        Jn(:,i) = (o.ODEFcn(0, x+e) - o.ODEFcn(0, x-e)) / (2*h);
    end
    err = max(abs(J - Jn), [], "all");
end

function e = finite_eigs_ode(o)
% simulate の DAE (M x' = F(x)) の初期値での有限な一般化固有値
    J = o.Jacobian.Jacobian(0, o.InitialValue);
    e = DebugScript.helper.finite_eigs(struct("A", J, "E", o.MassMatrix.MassMatrix));
end

function ME = caught(fcn)
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end
