% F94 連続潮流計算の各ステップの運転点 (ResultCPF.get_point, tab_variable, rm_variable)
%
% ResultCPF は経路の各ステップの運転点 (変数マップの x, Vre, Vim, u, uc) を持ち、
% net.get_sys({res, ステップ}) でステップごとの区間を持つ ResultLIN を作れる。
%   x   = res.get_point(k);                       % ステップ k の運転点
%   lin = net.get_sys({res, [1 res.r_noseStep]}); % 初期点とノーズの 2 区間
% 次も確認する。
%   - ステップ 1 は initialize の平衡点
%   - 途中のステップの線形化は、負荷を (1 + λ) 倍した系統の潮流計算・initialize と一致
%   - 電圧安定度の指標 rv_sigmaMin、弱い母線 tab_weakbus、余裕 r_marginP
%   - 不正な Step のエラー、UseInternalState と Limits="Q" の経路
%
% 実行: runtests("DebugScript.test_F94_cpf_operating_points")  または  DebugScript.run_all("Features","F94")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_3bus("gen-classical");
DebugScript.helper.quiet(@() net.initialize);
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus="B003"));
n_step = numel(res.rv_lambda);


%% Step 1 is the equilibrium and every step has a full point
tab = net.get_variable_map();
tab = tab(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]), :);
assert(isequal(res.tab_variable(:, ["Kind","Owner","Name","Bus"]), tab(:, ["Kind","Owner","Name","Bus"])))
assert(isequal(size(res.rm_variable), [n_step, height(tab)]) && all(isfinite(res.rm_variable), "all"))
assert(max(abs(res.get_point(1) - tab.Equilibrium)) < 1e-9)
% 母線電圧の行は cm_Vbus と同じ
lv_re = res.tab_variable.Kind == "Vre";
lv_im = res.tab_variable.Kind == "Vim";
assert(max(abs(res.rm_variable(:,lv_re) + 1j*res.rm_variable(:,lv_im) - res.cm_Vbus.'), [], "all") < 1e-12)
% 機器の電流: 母線ごとの和は Y V
I = res.cm_Icomponent;
assert(isequal(size(I), [3, n_step]))
cm_Y = net.get_admittance_matrix.Variables;
assert(max(abs(cm_Y*res.cm_Vbus - I), [], "all") < 1e-3)   % 1 母線に 1 機器。差は CPF の残差 (Tolerance 1e-5 [pu] の電力) 程度
assert(max(abs(I(:,1) - [net.a_Bus{1}.a_Component{1}.c_Iequilibrium; net.a_Bus{2}.a_Component{1}.c_Iequilibrium; ...
                         net.a_Bus{3}.a_Component{1}.c_Iequilibrium])) < 1e-9)
% 系統のスナップショット
assert(isstruct(res.sct_network) && numel(res.sct_network.a_Bus) == 3)
% 一部の行 (母線の変数マップ)
tab_b = net.a_Bus{3}.get_variable_map();
rv = res.get_point(res.r_noseStep, tab_b(ismember(tab_b.Kind, ["x","Vre","Vim","u","uc"]), :));
assert(numel(rv) == 4 && abs(rv(1) + 1j*rv(2) - res.cm_Vbus(3, res.r_noseStep)) < 1e-12)


%% get_sys of a step matches the network with loads scaled by (1 + lambda)
k   = round(res.r_noseStep / 2);
lam = res.rv_lambda(k);
net2 = DebugScript.helper.build_3bus("gen-classical");
comp = net2.a_Bus{3}.a_Component{1};
comp.tab_parameter.powerflow.P = comp.tab_parameter.powerflow.P * (1 + lam);
comp.tab_parameter.powerflow.Q = comp.tab_parameter.powerflow.Q * (1 + lam);
DebugScript.helper.quiet(@() net2.initialize);
tab2 = net2.get_variable_map();
tab2 = tab2(1:height(res.tab_variable), :);
assert(max(abs(res.get_point(k) - tab2.Equilibrium)) < 1e-5)
lin  = net.get_sys({res, k});
lin2 = net2.get_sys();
assert(norm(full(lin.A - lin2.A)) < 1e-5 * norm(full(lin2.A)))
% 2 区間: 初期点とノーズ
lin = net.get_sys({res, [1 res.r_noseStep]});
assert(isa(lin, "ResultLIN") && isequal(lin.rv_t, [1 res.r_noseStep]))
lin0 = net.get_sys();
assert(norm(full(lin.A - lin0.A)) < 1e-9 * norm(full(lin0.A)))   % 選択中の区間は最初の区間


%% Voltage stability index, weak buses and loading margin
sig = res.rv_sigmaMin;
n   = res.r_noseStep;
assert(isequal(size(sig), [1, n_step]) && all(sig > 0))
assert(all(diff(sig(1:n)) < 0), "ノーズまで減少していない")
assert(sig(n) < 0.1 * sig(1) && sig(n) == min(sig))
% 弱い母線: 負荷母線 B003 が最上位、スラック母線の参与は 0
tab_w = res.tab_weakbus;
assert(isequal(string(tab_w.Properties.VariableNames), ["Bus","Participation","dVdLambda"]))
assert(height(tab_w) == 3 && tab_w.Bus(1) == "B003" && tab_w.Participation(1) == 1)
assert(issorted(tab_w.Participation, "descend") && tab_w.Participation(tab_w.Bus == "B001") < 1e-9)
r_dV = (abs(res.cm_Vbus(3,n)) - abs(res.cm_Vbus(3,1))) / res.rv_lambda(n);
assert(abs(tab_w.dVdLambda(1) - r_dV) < 1e-12 && r_dV < 0)
% 余裕 = λmax × 初期の負荷の有効電力 (B003 の負荷 1.0 pu)
assert(abs(res.r_marginP - res.r_lambdaMax * 1.0) < 1e-6)


%% get_point with an invalid Step or map stops with an error
for r_step = [0, n_step + 1, 1.5, NaN]
    assert(error_id(@() res.get_point(r_step)) == "GUILDA:ResultCPF:PointStep", string(r_step))
end
assert(error_id(@() res.get_point(1, table(1, 'VariableNames', "Kind"))) == "GUILDA:ResultCPF:InvalidMap")
tab = net.get_variable_map();
assert(error_id(@() res.get_point(1, tab(tab.Kind == "y", :))) == "GUILDA:ResultCPF:UnknownVariable")
assert(isempty(res.get_point(1, tab([], :))))


%% UseInternalState keeps the CPF states of the components
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus="B003", UseInternalState=true, MaxIteration=10));
tab = res.tab_variable;
assert(max(abs(res.get_point(1) - tab.Equilibrium)) < 1e-9)
% 状態は rm_x の値 (B002 の発電機の delta)
comp = net.a_Bus{2}.a_Component{1};
lv_d = tab.Kind == "x" & tab.Owner == string(comp.s_tag) & tab.Name == "delta";
assert(max(abs(res.rm_variable(:,lv_d).' - res.rm_x(comp.iv_CPFX(1),:))) < 1e-12)
lin = net.get_sys({res, [1 5 11]});
assert(isequal(lin.rv_t, [1 5 11]) && all(isfinite(lin.A), "all"))
% 状態のある機器の入力は CPF の式の入力 rv_Uequilibrium で、各ステップで dx = 0
% (スラック母線の発電機の delta, omega は CPF の未知数でないので、その 2 行の式は除く)
for i_bus = 1:2
    comp = net.a_Bus{i_bus}.a_Component{1};
    lv_u = tab.Kind == "u" & tab.Owner == string(comp.s_tag);
    lv_x = tab.Kind == "x" & tab.Owner == string(comp.s_tag);
    assert(max(abs(res.rm_variable(:,lv_u) - comp.rv_Uequilibrium.'), [], "all") == 0)
    iv_row = 1:numel(comp.sv_x);
    if net.a_Bus{i_bus}.l_isSlack
        iv_row = 3:numel(comp.sv_x);
    end
    for k = 1:numel(res.rv_lambda)
        V  = res.cm_Vbus(i_bus,k);
        dx = comp.f_dx(0, res.rm_variable(k,lv_x).', [real(V); imag(V)], comp.rv_Uequilibrium);
        assert(max(abs(dx(iv_row))) < 1e-6, sprintf("%s step %d", comp.s_tag, k))
    end
end
% 余裕: UseInternalState では CPF が全母線の機器を (1 + λ) 倍するので、全機器の初期の消費
r_P = 0;
for i_bus = 1:3
    r_P = r_P - sum(cellfun(@(c) real(c.c_Vequilibrium*conj(c.c_Iequilibrium)), net.a_Bus{i_bus}.a_Component));
end
assert(abs(res.r_marginP - res.r_lambdaMax * r_P) < 1e-12)


%% Limits "Q" keeps the fixed Q of a switched bus
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
sr_load = ["B009","B010","B011","B012","B013","B014"];
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus=sr_load, Limits="Q", StepSize=0.5, MaxIteration=10));
assert(height(res.tab_switch) >= 1 && all(isfinite(res.rm_variable), "all"))
assert(max(abs(res.get_point(1) - res.tab_variable.Equilibrium)) < 1e-9)
% 切り替えた母線の発電機 (Q = NaN) の Q の和は境界の値
s_bus = res.tab_switch.Bus(1);
i_bus = find(res.sv_bus == s_bus);
a_comp = net.a_Bus{i_bus}.a_Component;
i_0   = sum(cellfun(@(b) numel(b.a_Component), net.a_Bus(1:i_bus-1)));
lv_g  = cellfun(@(c) isnan(c.tab_parameter.powerflow.Q), a_comp(:));
cv_S  = res.cm_Vbus(i_bus,end) * conj(res.cm_Icomponent(i_0 + (1:numel(a_comp)), end));
assert(abs(sum(imag(cv_S(lv_g))) - res.tab_switch.Bound(1)) < 1e-6)
% 余裕: λmax × LoadBus の負荷の有効電力
r_P = 0;
for s = sr_load
    b = net.a_Bus{res.sv_bus == s};
    r_P = r_P - sum(cellfun(@(c) real(c.c_Vequilibrium*conj(c.c_Iequilibrium)), b.a_Component));
end
assert(abs(res.r_marginP - res.r_lambdaMax * r_P) < 1e-9 && r_P > 0)


%% Controllers that observe the states get the state of the component at a step
% pss-retrofit (Static AVR の下) と local-LQR は get_equilibrium の 4 番目の引数 x (その点の
% 機器の状態) から hat_x と uc を返す。ステップ k の点の制御器の行は、その点の機器の x と一致し、
% get_sys({res, k}) は、負荷を (1 + λ) 倍して initialize した系統の平衡点で、同じ系統 (設計は
% initialize のまま) を線形化した結果と一致する
for s_case = ["pss-retrofit", "local-LQR"]
    c_net = cell(1, 2);
    for m = 1:2
        [c_net{m}, gen] = DebugScript.helper.build_3bus("gen-1axis");
        if s_case == "pss-retrofit"
            gen.add_local_controller("pss-retrofit", parameter=struct(R=0.01));
        else
            DebugScript.helper.quiet(@() gen.add_local_controller("local-LQR"));
        end
    end
    [net, net2] = c_net{:};
    gen = net.a_Bus{2}.a_Component{1};
    con = gen.a_LocalController{1};
    if s_case == "pss-retrofit"
        con = con.a_LocalController{1};     % the PSS under the Static AVR
    end
    DebugScript.helper.quiet(@() net.initialize);
    rv_K = con.K(:);
    res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus="B003"));
    k   = round(res.r_noseStep / 2);
    lam = res.rv_lambda(k);
    tab = res.tab_variable;
    rv  = res.get_point(k);
    x_k = rv(tab.Kind == "x" & tab.Owner == string(gen.s_tag));
    assert(max(abs(rv(tab.Kind == "uc" & tab.Owner == string(con.s_tag)) - x_k)) == 0, s_case)
    if s_case == "pss-retrofit"
        assert(max(abs(rv(tab.Kind == "x" & tab.Owner == string(con.s_tag)) - x_k)) == 0, s_case)
    end
    assert(max(abs(x_k - gen.rv_Xequilibrium)) > 1e-3, s_case)   % the step is away from the equilibrium
    % 負荷を (1 + λ) 倍した系統の平衡点
    ld = net2.a_Bus{3}.a_Component{1};
    ld.tab_parameter.powerflow.P = ld.tab_parameter.powerflow.P * (1 + lam);
    ld.tab_parameter.powerflow.Q = ld.tab_parameter.powerflow.Q * (1 + lam);
    DebugScript.helper.quiet(@() net2.initialize);
    tab2 = net2.get_variable_map();
    tab2 = tab2(1:height(tab), :);
    assert(isequal(tab2(:, ["Kind","Name","Bus"]), tab(:, ["Kind","Name","Bus"])))
    assert(max(abs(rv - tab2.Equilibrium)) < 1e-5, s_case)
    lin  = net.get_sys({res, k});
    lin2 = net.get_sys(tab2.Equilibrium);
    assert(norm(full(lin.A - lin2.A)) < 1e-5 * norm(full(lin2.A)), s_case)
    assert(isequal(con.K(:), rv_K), s_case)     % the design is not changed
end


%% A local controller with get_equilibrium(obj, V, u) still works at the steps
% 4 番目の引数のない利用者の制御器は get_equilibrium_at が 3 つの引数で呼び直す
c_stub = DebugScript.helper.register_stub("ObserveStub", "controller.test_observe"); %#ok<NASGU>
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
con = DebugScript.helper.quiet(@() gen.add_local_controller("test-observe", parameter=struct(Input="Xall")));
DebugScript.helper.quiet(@() net.initialize);
[x0, u0] = con.get_equilibrium_at(gen.c_Vequilibrium, gen.rv_Uequilibrium, gen.rv_Xequilibrium);
assert(isempty(x0) && isequal(u0, zeros(numel(con.sv_u), 1)) && isequal(con.rv_Uequilibrium, u0))
res = DebugScript.helper.quiet(@() net.calculate_continuation_powerflow(LoadBus="B003"));
k   = round(res.r_noseStep / 2);
tab = res.tab_variable;
rv  = res.get_point(k);
assert(all(isfinite(res.rm_variable), "all"))
assert(isequal(rv(tab.Kind == "uc" & tab.Owner == string(con.s_tag)), rv(tab.Kind == "x" & tab.Owner == string(gen.s_tag))))


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
