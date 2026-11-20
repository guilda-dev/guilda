% F95 定電流負荷 (component.load.current, キー "load-current")
%
% 入力 u = [Ip; Iq] は母線電圧と同相・直交の電流 (注入の向き、消費する負荷は負)。
%   I = (Ip - jIq) V/|V|,  P + jQ = |V| (Ip + jIq)
% 次を確かめる。
%   - add_component と潮流計算・initialize (u = [P; Q]/|V|、平衡点で P, Q が戻る)
%   - Component.validate (ヤコビアン) と get_hessian (ポートの釣り合いのヤコビアン)
%   - 地絡のシミュレーションで P, Q が |V| に比例する
%   - get_sys、連続潮流計算 (getCompPQ)、replace_component (power ↔ current)
%   - CSV の書き出しと読み込み、シナリオでの解列
%
% 実行: runtests("DebugScript.test_F95_load_current")  または  DebugScript.run_all("Features","F95")

% 共通設定 (各テストの前に毎回実行される)
[net, ld] = DebugScript.helper.build_3bus("load-current");


%% add_component gives the class, tag and inputs
assert(isa(ld, "component.load.current") && ld.key == "load-current")
assert(ld.s_tag == "B003LI1", ld.s_tag)
assert(isequal(ld.sv_u, ["Ip"; "Iq"]) && isempty(ld.sv_x) && isempty(ld.sv_y) && isempty(ld.sv_para))
assert(isequal(ld.tab_parameter.powerflow{1, ["P","Q"]}, [-1.0, -0.2]))


%% initialize sets u = [P; Q]/|V| and the load injects P, Q at the equilibrium
DebugScript.helper.quiet(@() net.initialize);
c_V = ld.c_Vequilibrium;
assert(max(abs(ld.rv_Uequilibrium - [-1.0; -0.2]/abs(c_V))) < 1e-12)
I = ld.f_I(0, [], [real(c_V); imag(c_V)], ld.rv_Uequilibrium);
assert(abs(c_V*conj(I) - (-1.0 - 0.2j)) < 1e-9)
assert(abs(I - ld.c_Iequilibrium) < 1e-9)
% 電圧を半分にすると P, Q も半分 (電流の大きさと力率が一定)
I2 = ld.f_I(0, [], 0.5*[real(c_V); imag(c_V)], ld.rv_Uequilibrium);
assert(abs(0.5*c_V*conj(I2) - 0.5*(-1.0 - 0.2j)) < 1e-9)
% 解列 (電流と電力が 0) は u = 0
[x0, u0] = ld.get_equilibrium(c_V, 0, 0, 0);
assert(isempty(x0) && isequal(u0, [0; 0]))


%% validate passes and the Jacobians match finite differences
DebugScript.helper.quiet(@() net.initialize);
flag = DebugScript.helper.quiet(@() ld.validate(false));
assert(~any(flag.contract.status == "FAIL"))
assert(max(flag.Div{:,:}, [], "all") < 1e-6 && max(flag.Diu{:,:}, [], "all") < 1e-6)
V = [0.93; -0.21];
u = [-0.8; 0.3];
[~, Div, Diu] = component.load.current.Jacobi_I(0, [], V, u, [], 60);
f = @(V, u) [real(ld.f_I(0, [], V, u)); imag(ld.f_I(0, [], V, u))];
h = 1e-7;
for k = 1:2
    e = zeros(2,1); e(k) = h;
    assert(max(abs((f(V+e, u) - f(V-e, u))/(2*h) - Div(:,k))) < 1e-7, "Div %d", k)
    assert(max(abs((f(V, u+e) - f(V, u-e))/(2*h) - Diu(:,k))) < 1e-7, "Diu %d", k)
end


%% get_hessian is the Jacobian of w_dev = -[P; Q/V] in (theta, V)
DebugScript.helper.quiet(@() net.initialize);
H = ld.get_hessian();
assert(isequal(size(H.Hxx), [0, 0]) && isequal(size(H.Hxv), [0, 2]) && isequal(size(H.R), [0, 0]))
u = ld.rv_Uequilibrium;
w = @(v) w_dev(ld, v, u);
v0 = [angle(ld.c_Vequilibrium); abs(ld.c_Vequilibrium)];
h = 1e-7;
J = zeros(2,2);
for k = 1:2
    e = zeros(2,1); e(k) = h;
    J(:,k) = (w(v0+e) - w(v0-e))/(2*h);
end
assert(max(abs(J - H.Hvv), [], "all") < 1e-7)
assert(abs(H.Hvv(1,2) + u(1)) < 1e-12 && H.Hvv(2,1) == 0 && H.Hvv(2,2) == 0)


%% A fault keeps Ip, Iq: P and Q are proportional to |V|
% 負荷へつながる B002 の地絡では電流を流せない (整合な初期値が無い) ため、B001 を地絡する
DebugScript.helper.quiet(@() net.initialize);
sc = net.add_scenario("f", Time=[0, 1.5]);
sc.add_fault("B001", [0.5, 0.55]);
[r, flag] = DebugScript.helper.quiet(@() net.simulate("f"));
assert(flag == 1 && r.rv_t(end) == 1.5)
o = r.odeResults;
cV = o.Bus(3).V{:,:} * [1; 1j];
cI = o.Bus(3).Component(1).I{:,:} * [1; 1j];
S  = cV .* conj(cI);
assert(max(abs(S./abs(cV) - [1, 1j]*ld.rv_Uequilibrium)) < 1e-9)
assert(max(abs(cV)) - min(abs(cV)) > 0.05, "地絡で電圧が変わる")


%% get_sys and the continuation power flow
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys();
net_p = DebugScript.helper.build_3bus("load-power");
DebugScript.helper.quiet(@() net_p.initialize);
sys_p = net_p.get_sys();
assert(isequal(size(sys.A), size(sys_p.A)))
assert(max(abs(sys.A - sys_p.A), [], "all") > 1e-6, "負荷の電圧特性が線形化に現れる")
% getCompPQ は |V| [Ip; Iq] (V は [abs; angle])
assert(isequal(ld.getCompPQ([], [0.9; 0.1], [-1; -0.2], []), 0.9*[-1; -0.2]))
[res, flag] = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus="B003", UseInternalState=true));
assert(flag && res.r_lambdaMax > 0)


%% replace_component switches between load-power and load-current
[net, ld_p] = DebugScript.helper.build_3bus("load-power");
bus = net.a_Bus{3};
ld = DebugScript.helper.quiet(@() bus.replace_component(ld_p.s_tag, "load-current"));
assert(isa(ld, "component.load.current") && ld.s_tag == "B003LI1", ld.s_tag)
assert(isequal(ld.tab_parameter.powerflow{1, ["P","Q"]}, [-1.0, -0.2]))
DebugScript.helper.quiet(@() net.initialize);
assert(max(abs(ld.rv_Uequilibrium - [-1.0; -0.2]/abs(ld.c_Vequilibrium))) < 1e-12)
ld_p = DebugScript.helper.quiet(@() bus.replace_component(ld.s_tag, "load-power"));
assert(isa(ld_p, "component.load.power"))
DebugScript.helper.quiet(@() net.initialize);
assert(max(abs(ld_p.rv_Uequilibrium - [-1.0; -0.2])) < 1e-12)


%% CSV export and import round trip
DebugScript.helper.quiet(@() net.initialize);
s_dir = tempname;
mkdir(s_dir);
c_del = onCleanup(@() rmdir(s_dir, "s")); %#ok<NASGU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net3")));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path));
ld2 = net2.a_Bus{3}.a_Component{1};
assert(isa(ld2, "component.load.current") && ld2.s_tag == "B003LI1", ld2.s_tag)
assert(isequal(ld2.tab_parameter.powerflow{1, ["P","Q"]}, [-1.0, -0.2]))
DebugScript.helper.quiet(@() net2.initialize);
assert(max(abs(ld2.rv_Uequilibrium - ld.rv_Uequilibrium)) < 1e-9)


%% A trip in a Scenario removes the load current
DebugScript.helper.quiet(@() net.initialize);
sc = net.add_scenario("t", Time=[0, 1]);
sc.add_trip("B003LI1", 0.5);
r = DebugScript.helper.quiet(@() net.simulate("t"));
o = r.odeResults;
I = o.Bus(3).Component(1).I{:,:};
lv_after = r.rv_t > 0.5;
assert(all(isnan(I(lv_after,:)) | I(lv_after,:) == 0, "all"), "解列後の負荷電流")
assert(all(~isnan(I(r.rv_t < 0.5,:)), "all"))
cV = o.Bus(3).V{:,:} * [1; 1j];
assert(abs(abs(cV(end)) - abs(cV(1))) > 1e-3, "解列で負荷母線の電圧が変わる")


function w = w_dev(ld, v, u)
% 機器の釣り合い w_dev = -[P; Q/V] (v = [theta; V])
    c_V = v(2)*exp(1j*v(1));
    S   = c_V*conj(ld.f_I(0, [], [real(c_V); imag(c_V)], u));
    w   = -[real(S); imag(S)/v(2)];
end
