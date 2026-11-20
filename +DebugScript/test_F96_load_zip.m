% F96 ZIP 負荷 (component.load.ZIP, キー "load-ZIP")
%
% 入力 u = [Pload; Qload] は |V| = 1 pu での電力で、P = Pload*f_P(|V|), Q = Qload*f_Q(|V|)。
% f = kZ V^2 + kI g_I(V) + kP g_P(V)。VswitchP 未満で定電力分、VswitchI 未満で定電流分が
% 定インピーダンスに連続に切り替わる。既定値は IEEJ NLT=2 (kPI = kQZ = 1、他は 0、閾値 0.7)。
%
% 実行: runtests("DebugScript.test_F96_load_zip")  または  DebugScript.run_all("Features","F96")

% 共通設定 (各テストの前に毎回実行される)
sv_para  = ["kPZ";"kPI";"kPP";"kQZ";"kQI";"kQP";"VswitchP";"VswitchI"];
rv_def   = [0, 1, 0, 1, 0, 0, 0.7, 0.7];
c_quiet  = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし


%% Defaults are the IEEJ NLT=2 load and the tag is LZIP
bus = PowerNetwork().add_bus();
ld  = bus.add_component("load-ZIP", "P", -0.8, "Q", -0.3);
assert(isa(ld, "component.load.ZIP") && ld.s_tag == "B001LZIP1")
assert(isequal(ld.sv_u(:), ["Pload";"Qload"]) && isequal(ld.sv_para(:), sv_para))
tab = ld.tab_parameter.dynamics;
assert(isequal(string(tab.Properties.VariableNames(:)), sv_para) && isequal(tab{1,:}, rv_def))
assert(ld.tab_parameter.OPF.HP == 0 && ld.tab_parameter.OPF.fP == 0)   % 負荷のコストは 0


%% A partial table or struct takes the defaults for the other names and NaN values
bus = PowerNetwork().add_bus();
ld  = bus.add_component("load-ZIP", "P", -0.8, "parameter", table(0.2, 0.8, 0.5, 'VariableNames', ["kPZ","kPI","VswitchP"]));
assert(isequal(ld.tab_parameter.dynamics{1,:}, [0.2, 0.8, 0, 1, 0, 0, 0.5, 0.7]))
ld  = DebugScript.helper.quiet(@() bus.add_component("load-ZIP", "P", -0.8, "parameter", struct("kQZ", nan, "kQI", 0.4, "kQP", 0.6)));
assert(isequal(ld.tab_parameter.dynamics{1,:}, [0, 1, 0, 1, 0.4, 0.6, 0.7, 0.7]))   % NaN は既定値 (和 2 は警告)


%% An unknown name, a wrong value or a wrong form stops with an error
bus = PowerNetwork().add_bus();
assert(error_id(@() bus.add_component("load-ZIP", "parameter", struct("kQ", 1))) == "GUILDA:Component:UnknownParameter")
assert(error_id(@() bus.add_component("load-ZIP", "parameter", struct("VswitchP", 0))) == "GUILDA:Component:ZIPParameterValue")
assert(error_id(@() bus.add_component("load-ZIP", "parameter", struct("VswitchI", inf))) == "GUILDA:Component:ZIPParameterValue")
assert(error_id(@() bus.add_component("load-ZIP", "parameter", struct("kPZ", inf))) == "GUILDA:Component:ZIPParameterValue")
assert(error_id(@() bus.add_component("load-ZIP", "parameter", "NGT2")) == "GUILDA:Component:ZIPParameterValue")
assert(error_id(@() bus.add_component("load-ZIP", "parameter", table([1;2], 'VariableNames', "kPZ"))) == "GUILDA:Component:ZIPParameterValue")
assert(isempty(bus.a_Component))
% import の dynamics.csv の ParameterID 列は読み飛ばす
ld = bus.add_component("load-ZIP", "parameter", table("P1", 0.5, 0.5, 'VariableNames', ["ParameterID","kPI","kPP"]));
assert(isequal(ld.tab_parameter.dynamics{1,1:3}, [0, 0.5, 0.5]))


%% A coefficient sum other than 1 warns, a sum of 1 does not
bus = PowerNetwork().add_bus();
lastwarn("");
ld = bus.add_component("load-ZIP", "parameter", struct("kPZ", 0.3, "kPI", 0.3, "kPP", 0.4, "kQZ", 0.5, "kQP", 0.5));
assert(string(lastwarn) == "")
evalc("ld.tab_parameter.dynamics.kPZ = 0.5;");    % 和 1.2
[s_msg, s_id] = lastwarn(); s_id = DebugScript.helper.msg_id(s_msg, s_id);
assert(string(s_id) == "GUILDA:Component:ZIPCoefficientSum" && contains(s_msg, ld.s_tag) && contains(s_msg, "1.2"))
% 書き込みの検査は値を変えない
assert(error_id(@() set_dyn(ld, "VswitchI", -1)) == "GUILDA:Component:ZIPParameterValue")
assert(ld.tab_parameter.dynamics.VswitchI == 0.7)


%% An edit of the dynamics makes the load stale and initialize takes the new values
[net, ld] = DebugScript.helper.build_3bus("load-ZIP");
DebugScript.helper.quiet(@() net.initialize);
assert(~DebugScript.helper.is_stale(net))
u0 = ld.rv_Uequilibrium;
assert(norm(u0 - [-1.0; -0.2]./abs(ld.c_Vequilibrium).^[1; 2]) < 1e-10)   % kPI = kQZ = 1
tab = net.get_parameter("dynamics", Key="load-ZIP");
tab{1, ["kPI","kPP"]} = [0, 1];
net.set_parameter("dynamics", tab);
assert(~isempty(ld.sct_stale.equilibrium) && ~isempty(ld.sct_stale.odefcn))
DebugScript.helper.quiet(@() net.initialize);
assert(~DebugScript.helper.is_stale(net))
assert(abs(ld.rv_Uequilibrium(1) - (-1.0)) < 1e-10 && abs(ld.rv_Uequilibrium(2) - u0(2)) < 1e-12)


%% The power flow and initialize reproduce P and Q at the equilibrium
for rv_k = {[0.3,0.3,0.4,0.2,0.3,0.5], [1,0,0,1,0,0], [0,1,0,0,1,0], [0,0,1,0,0,1]}
    s = cell2struct(num2cell(rv_k{1}(:)), cellstr(sv_para(1:6)), 1);
    [net, ld] = DebugScript.helper.build_3bus("load-ZIP", parameter=s);
    DebugScript.helper.quiet(@() net.initialize);
    rv_V = [real(ld.c_Vequilibrium); imag(ld.c_Vequilibrium)];
    c_S  = ld.c_Vequilibrium*conj(ld.f_I(0, [], rv_V, ld.rv_Uequilibrium));
    assert(abs(c_S - (-1.0 - 0.2j)) < 1e-9, mat2str(rv_k{1}))
    assert(abs(ld.c_Iequilibrium - ld.f_I(0, [], rv_V, ld.rv_Uequilibrium)) < 1e-9)
    assert(norm(ld.getCompPQ([], [abs(ld.c_Vequilibrium); angle(ld.c_Vequilibrium)], ld.rv_Uequilibrium, ld.tab_parameter.dynamics{1,:}) - [-1.0; -0.2]) < 1e-9)
    assert(DebugScript.helper.jacobian_error(ld) < 1e-5)
    assert_no_fail(ld.validate(false))
end


%% Analytic Jacobians match numerical ones on both sides of each threshold
bus = PowerNetwork().add_bus();
ld  = bus.add_component("load-ZIP", "parameter", struct("kPZ", 0.2, "kPI", 0.3, "kPP", 0.5, ...
          "kQZ", 0.1, "kQI", 0.6, "kQP", 0.3, "VswitchP", 0.8, "VswitchI", 0.5));
rr_p = ld.tab_parameter.dynamics{1,:};
u    = [-0.9; -0.4];
f_I  = @(V, u) [real(ld.fcn_I(0, [], V, u, rr_p, 60)); imag(ld.fcn_I(0, [], V, u, rr_p, 60))];
h    = 1e-7;
for r_V = [1.05, 0.81, 0.79, 0.6, 0.51, 0.49, 0.2]     % 0.8 (VswitchP) と 0.5 (VswitchI) の両側
    V = r_V*[cos(0.3); sin(0.3)];
    [~, Div, Diu] = component.load.ZIP.Jacobi_I(0, [], V, u, rr_p, 60);
    Div_n = [f_I(V + [h;0], u) - f_I(V - [h;0], u), f_I(V + [0;h], u) - f_I(V - [0;h], u)]/(2*h);
    Diu_n = [f_I(V, u + [h;0]) - f_I(V, u - [h;0]), f_I(V, u + [0;h]) - f_I(V, u - [0;h])]/(2*h);
    assert(norm(Div - Div_n) < 1e-6 && norm(Diu - Diu_n) < 1e-6, string(r_V))
    % get_hessian は w_dev = -[P; Q/V] の (theta, V) についてのヤコビアン
    H   = ld.get_hessian([], V, u);
    w   = @(th, v) w_dev(ld, v*[cos(th); sin(th)], u, rr_p);
    Hvv = [w(0.3 + h, r_V) - w(0.3 - h, r_V), w(0.3, r_V + h) - w(0.3, r_V - h)]/(2*h);
    assert(norm(H.Hvv - Hvv) < 1e-6, string(r_V))
end


%% Below both thresholds the current is that of the impedance, finite at V = 0
% VswitchP, VswitchI の両方より下では f = c |V|^2 (c = kZ + kI/VswitchI + kP/VswitchP^2) の
% 定インピーダンスで、I = conj(u.*c)*V。conj(S/V) の 0/0 がなく、V = 0 で I = 0。
% IEEJ_EAST10 で変圧器だけでつながる負荷母線 (B025-B044 など) の地絡で電圧が 0 になり、
% 以前は NaN で相の初期条件の計算が止まった
bus = PowerNetwork().add_bus();
ld  = bus.add_component("load-ZIP", "parameter", struct("kPZ", 0.2, "kPI", 0.3, "kPP", 0.5, ...
          "kQZ", 0.1, "kQI", 0.6, "kQP", 0.3, "VswitchP", 0.8, "VswitchI", 0.5));
rr_p = ld.tab_parameter.dynamics{1,:};
u    = [-0.9; -0.4];
rv_c = [0.2 + 0.3/0.5 + 0.5/0.8^2; 0.1 + 0.6/0.5 + 0.3/0.8^2];
Y    = conj(u(1)*rv_c(1) + 1j*u(2)*rv_c(2));        % I = Y*V
I0   = ld.fcn_I(0, [], [0;0], u, rr_p, 60);
[~, Div, Diu] = component.load.ZIP.Jacobi_I(0, [], [0;0], u, rr_p, 60);
assert(I0 == 0 && all(isfinite([Div(:); Diu(:)])))
assert(norm(Div - [real(Y), -imag(Y); imag(Y), real(Y)]) < 1e-14 && isequal(Diu, zeros(2)))
f_I  = @(V, u) [real(ld.fcn_I(0, [], V, u, rr_p, 60)); imag(ld.fcn_I(0, [], V, u, rr_p, 60))];
h    = 1e-7;
for r_V = [0.3, 1e-9]
    V = r_V*[cos(0.3); sin(0.3)];
    assert(abs(ld.fcn_I(0, [], V, u, rr_p, 60) - Y*([1,1j]*V)) < 1e-14)
    % 0/0 のない形でも、電力は u.*f_P, f_Q のまま
    S = ([1,1j]*V)*conj(ld.fcn_I(0, [], V, u, rr_p, 60));
    PQ = ld.getCompPQ([], [r_V; 0.3], u, rr_p);
    assert(abs(S - (PQ(1) + 1j*PQ(2))) < 1e-12)
    [~, Div, Diu] = component.load.ZIP.Jacobi_I(0, [], V, u, rr_p, 60);
    Div_n = [f_I(V + [h;0], u) - f_I(V - [h;0], u), f_I(V + [0;h], u) - f_I(V - [0;h], u)]/(2*h);
    Diu_n = [f_I(V, u + [h;0]) - f_I(V, u - [h;0]), f_I(V, u + [0;h]) - f_I(V, u - [0;h])]/(2*h);
    assert(norm(Div - Div_n) < 1e-6 && norm(Diu - Diu_n) < 1e-6, string(r_V))
end
% 下の閾値 (0.5) の両側で電流は連続
for r_d = [-1, 1]*1e-9
    V = (0.5 + r_d)*[cos(0.3); sin(0.3)];
    assert(abs(ld.fcn_I(0, [], V, u, rr_p, 60) - Y*([1,1j]*V)) < 1e-8)
end


%% The power is continuous at VswitchP and VswitchI
bus = PowerNetwork().add_bus();
ld  = bus.add_component("load-ZIP", "parameter", struct("kPZ", 0.2, "kPI", 0.3, "kPP", 0.5, ...
          "kQZ", 0.1, "kQI", 0.6, "kQP", 0.3, "VswitchP", 0.8, "VswitchI", 0.5));
rr_p = ld.tab_parameter.dynamics{1,:};
u    = [-0.9; -0.4];
for r_Vs = [0.8, 0.5]
    rv_PQ = [ld.getCompPQ([], [r_Vs - 1e-10; 0], u, rr_p), ld.getCompPQ([], [r_Vs; 0], u, rr_p)];
    assert(norm(diff(rv_PQ, 1, 2)) < 1e-9)
end
% 閾値の下で定電力分・定電流分は定インピーダンス: |V| -> 0 で電流も 0 に近づく
assert(abs(ld.fcn_I(0, [], [1e-4; 0], u, rr_p, 60)) < 1e-3)
% 閾値の下: P = Pload*(kPZ V^2 + kPI V^2/VswitchI + kPP V^2/VswitchP^2)
r_V = 0.3;
assert(abs(ld.getCompPQ([], [r_V; 0], u, rr_p)'*[1;0] - u(1)*(0.2 + 0.3/0.5 + 0.5/0.64)*r_V^2) < 1e-12)


%% Pure Z, I and P loads give the response of load-impedance, the current law and load-power
% Z: load-impedance と同じ応答 (故障で電圧が閾値を下回っても Z 分は切り替わらない)
[r_zip, r_ref] = simulate_pair("load-impedance", struct("kPZ", 1, "kPI", 0, "kQZ", 1), "fault");
assert(max_diff(r_zip, r_ref) < 1e-3)
% P: 閾値より上にとどまる外乱では load-power と同じ応答
[r_zip, r_ref] = simulate_pair("load-power", struct("kPI", 0, "kPP", 1, "kQZ", 0, "kQP", 1), "input");
assert(max_diff(r_zip, r_ref) < 1e-3)
% I: P = Pload |V|, Q = Qload |V| (電流の大きさが一定)
[r_zip, ~, ld] = simulate_pair("load-power", struct("kPI", 1, "kQZ", 0, "kQI", 1), "input");
i_bus = find(r_zip.sv_bus == ld.a_Bus.s_tag);
rm_V  = r_zip.odeResults.Bus(i_bus).V{:,:};
rm_I  = r_zip.odeResults.Bus(i_bus).Component(1).I{:,:};
c_S   = (rm_V*[1;1j]).*conj(rm_I*[1;1j]);
r_Va  = abs(rm_V*[1;1j]);
assert(max(abs(c_S - (ld.rv_Uequilibrium.'*[1;1j]).*r_Va)) < 1e-6)
assert(max(r_Va) - min(r_Va) > 1e-4)     % 電圧は動いている


%% get_sys of a pure Z ZIP load has the eigenvalues of load-impedance
net1 = network.IEEE9bus(LocalController=true);  net2 = network.IEEE9bus(LocalController=true);
swap_loads(net2, struct("kPZ", 1, "kPI", 0, "kQZ", 1));
DebugScript.helper.quiet(@() net1.initialize);  DebugScript.helper.quiet(@() net2.initialize);
sys1 = net1.get_sys();  sys2 = net2.get_sys();
assert(isequal(size(sys1.A), size(sys2.A)) && norm(sys1.A - sys2.A) < 1e-8)
% 定電流分を含む既定値では固有値が変わり、安定なまま
swap_loads(net2, struct());
DebugScript.helper.quiet(@() net2.initialize);
sys3 = net2.get_sys();
assert(norm(sys3.A - sys1.A) > 1e-6 && max(real(DebugScript.helper.finite_eigs(sys3))) < 1e-6)


%% CPF with the internal state follows the voltage dependence of the load
% 定電力の ZIP は load-power と同じ経路
[net1, ~] = DebugScript.helper.build_3bus("load-power");
[net2, ~] = DebugScript.helper.build_3bus("load-ZIP", parameter=struct("kPI", 0, "kPP", 1, "kQZ", 0, "kQP", 1));
DebugScript.helper.quiet(@() net1.initialize);  DebugScript.helper.quiet(@() net2.initialize);
[res1, flag1] = DebugScript.helper.quiet(@() net1.calculate_continuation_powerflow(LoadBus="B003", UseInternalState=true, MaxIteration=10));
[res2, flag2] = DebugScript.helper.quiet(@() net2.calculate_continuation_powerflow(LoadBus="B003", UseInternalState=true, MaxIteration=10));
assert(flag1 == flag2 && isequal(size(res1.cm_Vbus), size(res2.cm_Vbus)))   % 10 歩ではノーズを越えない
assert(norm(res1.cm_Vbus - res2.cm_Vbus) < 1e-6 && norm(res1.rv_lambda - res2.rv_lambda) < 1e-6)
% 既定値 (定電流 P・定インピーダンス Q) でも解け、出発点は潮流計算の解
[net3, ~] = DebugScript.helper.build_3bus("load-ZIP");
DebugScript.helper.quiet(@() net3.initialize);
[res3, flag3] = DebugScript.helper.quiet(@() net3.calculate_continuation_powerflow(LoadBus="B003", UseInternalState=true, MaxIteration=10));
assert(all(isfinite(res3.rv_lambda)) && res3.rv_lambda(end) > 0 && norm(res3.cm_Vbus(:,1) - net3.cv_Vequilibrium) < 1e-6)


%% CSV export and import keep the dynamics (dynamics.csv)
[net, ld] = DebugScript.helper.build_3bus("load-ZIP", parameter=struct("kPZ", 0.2, "kPI", 0.3, "kPP", 0.5, "VswitchP", 0.6));
DebugScript.helper.quiet(@() net.initialize);
s_dir  = tempname;  mkdir(s_dir);  c_clean = onCleanup(@() rmdir(s_dir, "s"));
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
assert(isfile(fullfile(s_path, "component", "load-ZIP", "dynamics.csv")))
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path));
ld2  = net2.a_Bus{3}.a_Component{1};
assert(isa(ld2, "component.load.ZIP") && ld2.s_tag == ld.s_tag)
assert(isequal(ld2.tab_parameter.dynamics, ld.tab_parameter.dynamics))
assert(norm(ld2.rv_Uequilibrium - ld.rv_Uequilibrium) < 1e-9)


%% Scenario trip and input of a ZIP load
[net, ld] = DebugScript.helper.build_3bus("load-ZIP");
DebugScript.helper.quiet(@() net.initialize);
sc = net.add_scenario("zip");
sc.add_input(ld.s_tag, "Pload", -0.1, [0.5, 1]);
sc.add_trip(ld.s_tag, 2);
[r, flag] = DebugScript.helper.quiet(@() net.simulate("zip", Time=[0, 3]));
assert(flag == 1)
U = r.odeResults.Bus(3).Component(1).U{:,:};
t = r.odeResults.t;
assert(all(abs(U(t > 0.6 & t < 0.9, 1) - (ld.rv_Uequilibrium(1) - 0.1)) < 1e-9))
assert(all(isnan(U(t > 2.1, :)), "all"))
I = r.odeResults.Bus(3).Component(1).I{:,:};
assert(all(isnan(I(t > 2.1, :)), "all") && all(isfinite(I(t < 1.9, :)), "all"))


%% get_equilibrium: zero power gives zero input, a zero factor with a power stops
bus = PowerNetwork().add_bus();
ld  = DebugScript.helper.quiet(@() bus.add_component("load-ZIP", "parameter", struct("kPI", 0, "kQZ", 0, "kQP", 1), "P", -1));
[x, u] = ld.get_equilibrium(1.0, 0, 0, 0);     % simulate の解列
assert(isempty(x) && isequal(u, [0; 0]))
[~, u] = ld.get_equilibrium(0.9, 0, 0, -0.3);  % f_P = 0 でも P = 0 なら Pload = 0
assert(isequal(u, [0; -0.3]))
assert(error_id(@() ld.get_equilibrium(0.9, 0, -1, 0)) == "GUILDA:Component:ZIPNoPower")


%% The class is a load with get_hessian and getCompPQ, listed in the key map
assert(isKey(GUILDA.keymap("Component"), "load-ZIP"))
dic = GUILDA.keymap("Component");
assert(dic("load-ZIP") == "component.load.ZIP")
ld = PowerNetwork().add_bus().add_component("load-ZIP");
assert(isa(ld, "component.load.abstract") && ismethod(ld, "getCompPQ") && ismethod(ld, "get_hessian"))



%% The loads of the IEEJ networks are load-ZIP with the defaults
% IEEJ の 4 系統 (昼間・夜間) の負荷はすべて load-ZIP の既定値 (NLT=2)。CSV で確かめ、WEST10 の
% 昼間断面は構築して機器のクラスとタグ (LZIP) を確かめる
for s_net = ["IEEJ_EAST10", "IEEJ_EAST30", "IEEJ_WEST10", "IEEJ_WEST30"]
    for s_section = ["peak", "night"]
        s_dir = fullfile(fileparts(which("network." + s_net)), s_section, "component");
        assert(~isfolder(fullfile(s_dir, "load-impedance")) && isfolder(fullfile(s_dir, "load-ZIP")), s_dir)
        tab = readtable(fullfile(s_dir, "load-ZIP", "dynamics.csv"));
        assert(isequal(tab{:, cellstr(sv_para)}, repmat(rv_def, height(tab), 1)), s_net + " " + s_section)
    end
end
net = DebugScript.helper.quiet(@() network.IEEJ_WEST10(LocalController=true));
a_Comp = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
a_Load = a_Comp(cellfun(@(c) isa(c, "component.load.abstract"), a_Comp));
assert(numel(a_Load) == 17 && all(cellfun(@(c) isa(c, "component.load.ZIP") && endsWith(c.s_tag, "LZIP1"), a_Load)))


% ---- local functions ----
function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end

function set_dyn(ld, s_name, r_val)
    ld.tab_parameter.dynamics.(s_name) = r_val;
end

function assert_no_fail(flag)
    assert(~any(flag.contract.status == "FAIL"), strjoin(flag.contract.Properties.RowNames(flag.contract.status == "FAIL"), ", "))
end

function w = w_dev(ld, V, u, rr_p)
    % -[P; Q/V]: 負荷が母線へ入れる電力から作るエネルギー関数の勾配 (Component.get_hessian)
    c_V = [1, 1j]*V;
    c_S = c_V*conj(ld.fcn_I(0, [], V, u, rr_p, 60));
    w   = -[real(c_S); imag(c_S)/abs(c_V)];
end

function swap_loads(net, sct_para)
    % IEEE9bus の負荷をすべて ZIP に置き換える (同じ潮流計算の設定)
    for i = 1:numel(net.a_Bus)
        bus = net.a_Bus{i};
        for k = numel(bus.a_Component):-1:1
            c = bus.a_Component{k};
            if isa(c, "component.load.abstract")
                pf = c.tab_parameter.powerflow;
                DebugScript.helper.quiet(@() bus.replace_component(c.s_tag, "load-ZIP", sct_para));
                bus.a_Component{k}.tab_parameter.powerflow = pf;
            end
        end
    end
end

function [r_zip, r_ref, ld] = simulate_pair(s_key, sct_para, s_event)
    % IEEE9bus の B005 の負荷を s_key と ZIP にした 2 つの系統で同じ外乱を与える
    net_ref = network.IEEE9bus(LocalController=true);
    net_zip = network.IEEE9bus(LocalController=true);
    for net = {net_ref, net_zip}
        bus = net{1}.a_Bus{5};
        c   = bus.a_Component{1};
        pf  = c.tab_parameter.powerflow;
        if net{1} == net_ref
            s_k = s_key;  p = nan;
        else
            s_k = "load-ZIP";  p = sct_para;
        end
        DebugScript.helper.quiet(@() bus.replace_component(c.s_tag, s_k, p));
        bus.a_Component{1}.tab_parameter.powerflow = pf;
        DebugScript.helper.quiet(@() net{1}.initialize);
        sc = net{1}.add_scenario("ev");
        if s_event == "fault"
            sc.add_fault("B005", [0.1, 0.15]);
        else
            sc.add_input(net{1}.a_Bus{2}.a_Component{1}.s_tag, "Pmech", 0.05, [0.1, 2]);
        end
    end
    r_ref = DebugScript.helper.quiet(@() net_ref.simulate("ev", Time=[0, 2]));
    r_zip = DebugScript.helper.quiet(@() net_zip.simulate("ev", Time=[0, 2]));
    ld = net_zip.a_Bus{5}.a_Component{1};
end

function d = max_diff(r1, r2)
    % 全母線電圧の軌道の差 (同じ時刻へ補間)
    V1 = cell2mat(arrayfun(@(b) b.V{:,:}, r1.odeResults.Bus(:).', "UniformOutput", false));
    V2 = cell2mat(arrayfun(@(b) b.V{:,:}, r2.odeResults.Bus(:).', "UniformOutput", false));
    [t1, i1] = unique(r1.odeResults.t, "last");
    [t2, i2] = unique(r2.odeResults.t, "last");
    t = linspace(0, min(t1(end), t2(end)), 400)';
    d = max(abs(interp1(t1, V1(i1,:), t) - interp1(t2, V2(i2,:), t)), [], "all");
end
