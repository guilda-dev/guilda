% F35 制御器の信号構造: 大域制御器の観測と出力の振り分け
%
% 大域制御器 (GC) は制御対象の出力 (同名の状態より優先) と状態を名前で観測し、全母線の電圧を V で
% 受け取る。GC の出力は、制御対象の局所制御器 (LC、入れ子を含む) に同名の入力があればそのすべてへ
% (観測入力なら機器の出力との和)、なければ機器の同名の入力へ足される。
% add_global_controller は接続先を INFO で示し、LC の変更で接続先が変わると simulate が INFO で示す。
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
F = probe(net, @(o) shifted_rhs(o, gen.iv_odeX(gen.sv_x == "omega"), d_w));
assert(abs(F(gc_obs.iv_odeX) - 2*d_w) < 1e-12, "dz/dt = %g", F(gc_obs.iv_odeX))
[sol, flag] = net.simulate([0,2], DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B003"));
assert(flag == 1 && isa(sol, "ResultODE"))


%% An output goes to an external input of a local controller, not to the component
% 調速機の参照値 Pref: GC の出力は調速機の入力 Pref に入り、機器の入力 Pmech には入らない
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gov = gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
c_pref = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_pref", ...
                                          Replace=["sv_y = ""Pmech""", "sv_y = ""Pref"""]);
s_info = evalc("gc = net.add_global_controller(""test-routing-gc-pref"", {gen}, parameter=struct(alpha=3));");
assert(contains(s_info, "INFO: ") && contains(s_info, "Pref of " + gen.s_tag + " goes to the input of " + gov.s_tag), s_info)
assert(isequal(gc.sv_route, "Pref of " + gen.s_tag + " goes to the input of " + gov.s_tag), gc.sv_route)
DebugScript.helper.quiet(@() net.initialize);
d_z = 1e-2;
F = probe(net, @(o) shifted_rhs(o, gc.iv_odeX, d_z));
% 残差 u - (平衡値 + y_GC): y_GC = -alpha z
assert(abs(F(gov.iv_odeU(gov.sv_u == "Pref")) - 3*d_z) < 1e-12, "Pref の残差 %g", F(gov.iv_odeU(gov.sv_u == "Pref")))
assert(abs(F(gen.iv_odeU(gen.sv_u == "Pmech"))) < 1e-12, "Pmech の残差 %g", F(gen.iv_odeU(gen.sv_u == "Pmech")))
% Pmech を出す GC は機器の入力に足される (調速機の出力との和)
c_stub = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc");
s_info = evalc("gc2 = net.add_global_controller(""test-routing-gc"", {gen}, parameter=struct(alpha=2));");
assert(contains(s_info, "Pmech of " + gen.s_tag + " goes directly to the component input"), s_info)
net.remove_global_controller(gc.s_tag);
DebugScript.helper.quiet(@() net.initialize);
F = probe(net, @(o) shifted_rhs(o, gc2.iv_odeX, d_z));
assert(abs(F(gen.iv_odeU(gen.sv_u == "Pmech")) - 2*d_z) < 1e-12, "Pmech の残差 %g", F(gen.iv_odeU(gen.sv_u == "Pmech")))


%% An observation input receives the sum of the component output and the global controller
% PSS と調速機はともに omega を観測する: GC の出力 omega は両方に入り、どちらも y_mac + y_GC を受け取る
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
gov = gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
c_omega = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_omega", ...
                                           Replace=["sv_y = ""Pmech""", "sv_y = ""omega"""]);
s_info = evalc("gc = net.add_global_controller(""test-routing-gc-omega"", {gen}, parameter=struct(alpha=3));");
assert(contains(s_info, "omega of " + gen.s_tag + " goes to the input of " + pss.s_tag + ", " + gov.s_tag), s_info)
s_run = evalc("net.initialize(); net.simulate([0,0.1], DebugScript.helper.noop_event(net,[0,0.1]));");
assert(~contains(s_run, "now goes"), "経路が変わっていないのに表示した: " + s_run)
DebugScript.helper.quiet(@() net.initialize);
d_z = 1e-2;  d_w = 4e-3;
F = probe(net, @(o) shifted_rhs(o, [gc.iv_odeX; gen.iv_odeX(gen.sv_x == "omega")], [d_z; d_w]));
% 残差 u - (omega + y_GC) = 0 - (d_w - 3 d_z)
r_expected = 3*d_z - d_w;
for con = {pss, gov}
    r = F(con{1}.iv_odeU(con{1}.sv_u == "omega"));
    assert(abs(r - r_expected) < 1e-12, "%s の omega の残差 %g (期待 %g)", con{1}.s_tag, r, r_expected)
end


%% Two local controllers with the same input name both receive the output
% 接続先は制御対象ごとの記録 sv_route と、LC の validate の inputs に現れる
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
gov = gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
c_omega = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_omega", ...
                                           Replace=["sv_y = ""Pmech""", "sv_y = ""omega"""]);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-omega", {gen}));
assert(isequal(gc.sv_route, "omega of " + gen.s_tag + " goes to the input of " + pss.s_tag + ", " + gov.s_tag), gc.sv_route)
DebugScript.helper.quiet(@() net.initialize);
for con = {pss, gov}
    flag = con{1}.validate(false);
    assert(flag.inputs{"omega","source"} == "output of " + gen.s_tag + " + output of " + gc.s_tag, flag.inputs{"omega","source"})
end


%% A changed routing after remove_local_controller is reported once
% LC の入力 Pmech (試験用の LC) に入っていた出力は、LC を外すと機器の入力 Pmech へ直接入る
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
c_lc = DebugScript.helper.register_stub("ObserveStub", "controller.test_observe");
lc = gen.add_local_controller("test-observe", parameter=struct(Input="Pmech"));
c_stub = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc");
s_info = evalc("gc = net.add_global_controller(""test-routing-gc"", {gen});");
assert(contains(s_info, "Pmech of " + gen.s_tag + " goes to the input of " + lc.s_tag), s_info)
DebugScript.helper.quiet(@() net.initialize);
s_run = evalc("net.simulate([0,0.1], DebugScript.helper.noop_event(net,[0,0.1]));");
assert(~contains(s_run, "now goes"), s_run)
gen.remove_local_controller(lc.s_tag);
DebugScript.helper.quiet(@() net.initialize);
s_run = evalc("net.simulate([0,0.1], DebugScript.helper.noop_event(net,[0,0.1]));");
assert(contains(s_run, "INFO: ") && contains(s_run, "Pmech of " + gen.s_tag + " now goes directly to the component input"), s_run)
assert(isequal(gc.sv_route, "Pmech of " + gen.s_tag + " goes directly to the component input"), gc.sv_route)
s_run = evalc("net.simulate([0,0.1], DebugScript.helper.noop_event(net,[0,0.1]));");
assert(~contains(s_run, "now goes"), "同じ変化を 2 度表示した: " + s_run)
% 接続先がなくなった出力はエラー (Pref は調速機にしかない)
c_pref = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc_pref", ...
                                          Replace=["sv_y = ""Pmech""", "sv_y = ""Pref"""]);
gov = gen.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
net.remove_global_controller(gc.s_tag);
gc = DebugScript.helper.quiet(@() net.add_global_controller("test-routing-gc-pref", {gen}));
gen.remove_local_controller(gov.s_tag);
DebugScript.helper.quiet(@() net.initialize);
ME = caught(@() net.simulate([0,0.1], DebugScript.helper.noop_event(net,[0,0.1])));
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
F = probe(net, @(o) shifted_rhs(o, net.a_Bus{1}.iv_odeX(1), 1e-3));
assert(abs(F(gc.iv_odeX)) > 1e-5, "母線 1 の電圧が GC に届かない: %g", F(gc.iv_odeX))


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


function F = probe(net, f)
% 第 1 区間 (外乱なし) の ode に f を適用した値
    c = probe_all(net, [0,0.1], {DebugScript.helper.noop_event(net,[0,0.1])}, f);
    F = c{1};
end

function c_val = probe_all(net, tspan, c_events, f)
% 各区間の ode に f を適用した値 (区間の順)
    box = containers.Map("KeyType", "double", "ValueType", "any");
    sct_options = net.solver_ODE.get_options({"Progress", "none"});
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
