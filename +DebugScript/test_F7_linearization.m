% F7 近似線形化 (linearize / get_sys / ResultLIN / get_variable_map / get_hessian)
%
% 平衡点 (または指定した点) まわりの線形モデルを求める。
%   res = net.linearize("Method", ..., "Point", 点);
%   sys = res.get_ss("Kron" | "Feedback" | "DAE");   % ss (Format="struct" で構造体)
%   res = net.get_sys("Method", ...);          % linearize + get_ss の近道 (既定は ResultLIN)
%   res = net.get_sys("Output", ["V","I","y"], "Input", 入力名);   % 入出力の選択 (既定は不変)
%   tab = net.get_variable_map();                 % 変数の順 (res.rm_Axx などの行と列)
% モデルは記述子形式 (E dx = A x + B u)。ResultLIN の A, B, C, D, E と名前、構造体、ss のどれでも同じ。
% 3 方式の有限固有値が一致すること、IEEE14 の平衡点が安定であること、v3 の行列と同じであること、
% Point (平衡点 / ベクトル / {シミュレーション結果, 時刻}) と Hessian の契約を確認する。
%
% 実行: runtests("DebugScript.test_F7_linearization")  または  DebugScript.run_all("Features","F7")

% 共通設定 (最初に 1 回だけ実行され、変数は全テストで共有される)
% net はハンドルなので、制御器の追加など net を変更するテストは new_net() で自分用の系統を作ること。
new_net = @() DebugScript.helper.build_ieee14();
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
n_x = sum(cellfun(@(b) sum(cellfun(@(c) numel(c.sv_x), b.a_Component)), net.a_Bus));   % 機器の状態数
eig_finite = @DebugScript.helper.finite_eigs;    % 有限な一般化固有値
same_eigs  = @DebugScript.helper.same_eigs;      % 固有値の集合が一致するか


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Get sys Kron
sys = net.get_sys("Method", "Kron");
assert(isa(sys, "ResultLIN"))
assert(size(sys.A,1) == n_x)
assert(numel(sys.StateName) == size(sys.A,1))


%% Get sys Feedback
% 既定の方式は Feedback
sys = net.get_sys();
assert(isa(sys, "ResultLIN"))
assert(size(sys.A,1) == n_x)


%% Get sys DAE
% DAE 方式は母線電圧・電流などの代数変数も状態に含む (E が特異)
sys = net.get_sys("Method", "DAE");
assert(isa(sys, "ResultLIN"))
assert(size(sys.A,1) > n_x)
assert(rank(sys.E) < size(sys.E,1))


%% Model shape and names per algorithm
% 固有値では分からない形を等式で確認する。n_x, n_v, n_u は変数の表の数
% Feedback は connect が質量のない状態 (AVR の Vst) を消すので、その数だけ小さい
n1 = new_net();
n1.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
n1.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
n1.add_global_controller("agc-PI", ["SG1B001", "SG1B002"]);
c_net = {new_net(), n1, network.Ishizaki6Bus(), network.IEEE9bus()};
n_removed = [0, 1, 0, 3];
for k = 1:numel(c_net)
    DebugScript.helper.quiet(@() c_net{k}.initialize);
    res = c_net{k}.linearize();
    tab = res.tab_variable;
    sv_x = tab.Label(tab.Kind == "x");
    sv_u = tab.Label(tab.Kind == "u");
    nx = numel(sv_x);  nv = 2*numel(c_net{k}.a_Bus);  nu = numel(sv_u);
    n_mass = nnz(diag(res.rm_E));
    sK = DebugScript.helper.quiet(@() res.get_ss("Kron"));
    sF = res.get_ss("Feedback");
    sD = DebugScript.helper.quiet(@() res.get_ss("DAE"));

    assert(isequal(size(sK.A), [nx nx]) && isequal(size(sK.B), [nx nu]) && isequal(sK.C, eye(nx)), "net %d: Kron", k)
    assert(isequal(sort(string(sK.StateName)), sort(sv_x)), "net %d: Kron の状態", k)
    nf = nx - n_removed(k);
    assert(isequal(size(sF.A), [nf nf]) && isequal(size(sF.B), [nf nu]) && size(sF.C,2) == nf, "net %d: Feedback", k)
    sv_gone = setdiff(sv_x, string(sF.StateName));
    assert(numel(sv_gone) == n_removed(k) && all(contains(sv_gone, "Vst")), "net %d: Feedback が消す状態", k)
    assert(all(diag(res.rm_E(ismember(sv_x, sv_gone), ismember(sv_x, sv_gone))) == 0), "net %d: 質量のある状態が消えた", k)
    assert(isequal(size(sD.A), [nx+nv nx+nv]) && isequal(size(sD.B), [nx+nv nu]) && isequal(size(sD.C), [nx nx+nv]), "net %d: DAE", k)
    assert(all(ismember(sv_x, string(sD.StateName))) && numel(unique(string(sD.StateName))) == nx+nv, "net %d: DAE の状態", k)

    assert(rank(sK.E) == n_mass && rank(sF.E) == n_mass && rank(sD.E) == n_mass, "net %d: E の階数", k)
    for s = {sK, sF, sD}
        assert(isequal(string(s{1}.InputName), sv_u), "net %d: 入力の名前と順", k)
        assert(numel(s{1}.StateName) == size(s{1}.A,1) && numel(s{1}.OutputName) == size(s{1}.C,1), "net %d: 名前の数", k)
    end
end


%% Three algorithms give same eigenvalues
e_kron = eig_finite(net.get_sys("Method","Kron"));
e_fb   = eig_finite(net.get_sys("Method","Feedback"));
e_dae  = eig_finite(net.get_sys("Method","DAE"));
assert(same_eigs(e_kron, e_fb,  1e-6), "Kron と Feedback の固有値が一致しない")
assert(same_eigs(e_kron, e_dae, 1e-6), "Kron と DAE の固有値が一致しない")


%% IEEE14 equilibrium is stable
% 回転不変性による 0 固有値を除き、すべての固有値の実部が負
e = eig_finite(net.get_sys("Method","Kron"));
assert(max(real(e)) < 1e-6, "不安定な固有値がある: " + max(real(e)))
assert(sum(abs(e) < 1e-6) <= 1)


%% Bus without an I-to-V form is eliminated automatically
% B007 は P=Q=0 の負荷で I2V 形式がないので、Feedback はネットワークと一緒に消去する (旧 Task9)
res = net.linearize();
sys_k = res.get_ss("Kron");
sys_f = res.get_ss("Feedback");
assert(same_eigs(eig_finite(sys_k), eig_finite(sys_f), 1e-6))
% 消去しても入力は残す
sv_u = res.tab_variable.Label(res.tab_variable.Kind == "u" & res.tab_variable.Bus == "B007");
assert(~isempty(sv_u) && all(ismember(sv_u, sys_f.InputName)))
assert(isequal(sys_f.InputName, sys_k.InputName))


%% Non unit bus with a current is absorbed into Y
% 定電力負荷と定インピーダンス負荷を同じ大きさで並べると、電流があるのに I2V 形式がない
% (D の特異値の 1 つが 0)。Feedback はこの電流を Y に吸収し、Kron と等価で入力も同じ
net_a = PowerNetwork("NoI2V");
net_a.add_bus("V", 1);
net_a.add_bus();
net_a.add_bus();
net_a.add_branch("pi", [1,2], "R", 0.01, "X", 0.085);
net_a.add_branch("pi", [2,3], "R", 0.01, "X", 0.085);
net_a.add_branch("pi", [1,3], "R", 0.01, "X", 0.085);
net_a.a_Bus{1}.add_component("gen-1axis");
net_a.a_Bus{3}.add_component("gen-1axis");
net_a.a_Bus{2}.add_component("load-power", "P", -0.5, "Q", 0);
net_a.a_Bus{2}.add_component("load-impedance", "P", -0.5, "Q", 0);
DebugScript.helper.quiet(@() net_a.initialize);
D = net_a.a_Bus{2}.get_sys("port","V2I").D(1:2,1:2);
assert(rcond(D) < 1e-12 && norm(D) > 0.1, "電流があり I2V 形式がない母線になっていない")
res = net_a.linearize();
sys_k = res.get_ss("Kron");
sys_f = res.get_ss("Feedback");
assert(max(real(eig_finite(sys_f))) < 1e-6, "不安定")
assert(same_eigs(eig_finite(sys_k), eig_finite(sys_f), 1e-6), "固有値")
assert(isequal(sys_f.InputName, sys_k.InputName), "入力の名前と順")
[lv, ix] = ismember(sys_k.StateName, sys_f.StateName);
assert(all(lv), "状態の名前")
w = 1i;
G_k = (w*sys_k.E - sys_k.A) \ sys_k.B;
G_f = (w*sys_f.E - sys_f.A) \ sys_f.B;
assert(norm(G_k - G_f(ix,:), "fro") < 1e-9, "入力から状態までの周波数応答")


%% Deprecated Algorithm option is Method
% COMPAT(v3): v3 の名前 Algorithm は Method と同じ (警告は 1 セッションに 1 回)
clear Deprecated
lastwarn("");
sys_old = net.get_sys("Algorithm", "Kron");
id = DebugScript.helper.msg_id();
assert(string(id) == "GUILDA:Deprecated:LinearizeAlgorithm", id)
sys_new = net.get_sys(Method="Kron");
assert(isequal(sys_old.A, sys_new.A) && isequal(sys_old.StateName, sys_new.StateName) && sys_old.options.Method == "Kron")
res_old = net.linearize(algorithm="DAE");
assert(res_old.options.Method == "DAE" && ~isfield(res_old.options, "Algorithm"))
assert(~isprop(net.solver_LIN, "Algorithm"))


%% Deprecated NonUnit option warns and ignores buses without states
s_id = "GUILDA:Deprecated:LinearizeNonUnit";
clear Deprecated
lastwarn("");
sys_nu = net.get_sys("Method", "Feedback", "NonUnit", 7);
id = DebugScript.helper.msg_id();
assert(string(id) == s_id, id)
assert(isequal(sys_nu, net.get_sys("Method", "Feedback")))
% 1 セッションに 1 回。名前の大文字小文字は問わない
lastwarn("");
sys_nu = net.get_sys("Method", "Feedback", "nonunit", 7);
id = DebugScript.helper.msg_id();
assert(string(id) == "", id)
assert(isequal(sys_nu, net.get_sys("Method", "Feedback")))
% 状態のない母線の指定は、負荷があっても Method によらず結果を変えない (B009 は負荷あり)
lv_static = tools.vcellfun(@(b) sum(cellfun(@(c) numel(c.sv_x), b.a_Component)) == 0, net.a_Bus);
for nu = {[], [7 9], find(lv_static(:)')}
    for alg = ["Kron", "Feedback", "DAE"]
        sys_ref = net.get_sys("Method", alg);
        assert(isequal(net.get_sys("Method", alg, "NonUnit", nu{1}), sys_ref), alg)
    end
end
% 結果の options には、指定したときだけ残る
assert(isequal(net.linearize("NonUnit", [7 9]).options.NonUnit, [7 9]))
assert(~isfield(net.linearize().options, "NonUnit"))
assert(~isfield(net.linearize("NonUnit", []).options, "NonUnit"))
% 値の検証と、受け付ける名前の一覧
assert(~isfield(SolverLIN.OptionMap, "NonUnit"))
assert(~contains(strjoin(string(properties(net.solver_LIN))), "NonUnit"))
try
    net.linearize("NonUnit", 1.5);
    error("DebugScript:NoError", "整数でない NonUnit がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) ~= "DebugScript:NoError", ME.message)
end


%% Deprecated NonUnit naming a bus with states is rejected
% 状態を持つ機器のある母線は Y に吸収できない。Feedback だけがエラーで、NonUnit を使わない Kron, DAE は動く
res = net.linearize("NonUnit", [7 2]);
try
    res.get_ss("Feedback");
    error("DebugScript:NoError", "状態のある母線の NonUnit がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:v3_nonunit_dynamic:NonUnitDynamicBus", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "bus 2"), ME.message)
end
assert(size(res.get_ss("Kron").A,1) == n_x)
assert(size(res.get_ss("DAE").A,1) > n_x)
% 指定は呼び出しの間だけで、残らない
assert(isequal(net.get_sys("Method","Feedback","Format","ss"), net.linearize().get_ss("Feedback")))


%% Deprecated NonUnit naming a missing bus is rejected
try
    net.linearize("NonUnit", 99);
    error("DebugScript:NoError", "存在しない NonUnit がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:v3_nonunit_range:NonUnit", DebugScript.helper.msg_id(ME))
end


%% Deprecated solver_LIN.NonUnit warns and acts as the option
net_d = new_net();
DebugScript.helper.quiet(@() net_d.initialize);
sys_ref = net_d.get_sys("Method", "Feedback");
clear Deprecated
lastwarn("");
net_d.solver_LIN.NonUnit = [7 9];
id = DebugScript.helper.msg_id();
assert(string(id) == "GUILDA:Deprecated:SolverLinNonUnit", id)
assert(isequal(net_d.solver_LIN.NonUnit, [7 9]))
assert(isequal(net_d.get_sys("Method", "Feedback"), sys_ref))
% 状態のある母線と存在しない母線は、オプションと同じエラー
for c = {{2, "GUILDA:v3_nonunit_dynamic:NonUnitDynamicBus"}, {99, "GUILDA:v3_nonunit_range:NonUnit"}}
    net_d.solver_LIN.NonUnit = c{1}{1};
    try
        net_d.get_sys("Method", "Feedback");
        error("DebugScript:NoError", "エラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == c{1}{2}, DebugScript.helper.msg_id(ME))
    end
end
% 呼び出しの指定が優先し、値は解法に保存しない
assert(isequal(net_d.get_sys("Method", "Feedback", "NonUnit", 7), sys_ref))
assert(isequal(net_d.solver_LIN.NonUnit, 99))
% 空の値は警告しない (.mat の読み込みでも代入される)
clear Deprecated
lastwarn("");
net_d.solver_LIN.NonUnit = [];
id = DebugScript.helper.msg_id();
assert(string(id) == "", id)


%% Feedback keeps the inputs of zero-power loads
% P=Q=0 の負荷の入力も Kron と同じように残り、同じ応答を持つ
n6 = network.Ishizaki6Bus();
DebugScript.helper.quiet(@() n6.initialize);
res = n6.linearize();
sys_k = res.get_ss("Kron");
sys_f = res.get_ss("Feedback");
assert(isequal(sys_f.InputName, sys_k.InputName))
assert(same_eigs(eig_finite(sys_k), eig_finite(sys_f), 1e-6))
[~, ix] = ismember(sys_k.StateName, sys_f.StateName);
G_k = (1i*sys_k.E - sys_k.A) \ sys_k.B;
G_f = (1i*sys_f.E - sys_f.A) \ sys_f.B;
assert(norm(G_k - G_f(ix,:), "fro") < 1e-9)


%% Bus without components
% 機器の無い母線 (build_9bus の B004, B007, B009) があっても変数マップ・線形化ができる
n9 = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() n9.initialize);
assert(iscell(n9.a_Bus{4}.a_Component) && isempty(n9.a_Bus{4}.a_Component))
tab = n9.a_Bus{4}.get_variable_map();
assert(isequal(tab.Kind, ["Vre";"Vim"]))
tab = n9.get_variable_map();
assert(nnz(tab.Bus == string(n9.a_Bus{4}.s_tag)) == 2)
res = DebugScript.helper.quiet(@() n9.linearize);
assert(isa(res, "ResultLIN"))
n_x9 = sum(cellfun(@(b) sum(cellfun(@(c) numel(c.sv_x), b.a_Component)), n9.a_Bus));
e_kron = eig_finite(n9.get_sys("Method","Kron"));
assert(size(n9.get_sys("Method","Kron").A, 1) == n_x9)
assert(same_eigs(e_kron, eig_finite(n9.get_sys("Method","DAE")), 1e-6))


%% I2V port stops when D is singular
% I2V は V2I の D の逆行列を使うので、D が特異なら NaN を返さずにエラーで止まる
% 機器の無い母線 (build_9bus の B004)
n9 = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() n9.initialize);
try
    n9.a_Bus{4}.get_sys("port","I2V");
    error("DebugScript:NoError", "機器の無い母線の I2V がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:NoI2V", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, n9.a_Bus{4}.s_tag) && contains(ME.message, "V2I"))
end
% P=Q=0 の load-power (IEEE14 の B007): 母線と機器のどちらも止まる
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
bus = n14.a_Bus{7};
assert(numel(bus.a_Component) == 1 && norm(bus.get_sys().D(1:2,1:2)) == 0)
try
    bus.get_sys("port","I2V");
    error("DebugScript:NoError", "P=Q=0 の負荷の母線の I2V がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:NoI2V", DebugScript.helper.msg_id(ME))
end
try
    bus.a_Component{1}.get_sys("port","I2V");
    error("DebugScript:NoError", "P=Q=0 の負荷の I2V がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:NoI2V", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, bus.a_Component{1}.s_tag))
end
% V2I は従来どおり使え、3 方式の線形化もこれらの母線を含む系統で動く (既存の内部呼び出しは I2V を通らない)
assert(isa(n9.a_Bus{4}.get_sys(), "ResultLIN") && isa(n9.a_Bus{4}.get_sys(Format="ss"), "ss"))
assert(same_eigs(eig_finite(n14.get_sys("Method","Feedback")), eig_finite(n14.get_sys("Method","Kron")), 1e-6))
% D が正則なら I2V の D は V2I の D の逆行列
for obj = {n14.a_Bus{1}, n14.a_Bus{1}.a_Component{1}}
    D_V = obj{1}.get_sys().D(1:2,1:2);
    D_I = obj{1}.get_sys("port","I2V").D(1:2,1:2);
    assert(all(isfinite(D_I(:))) && norm(D_I*D_V - eye(2)) < 1e-10)
end


%% With local controllers
% AVR/PSS を付けると制御器の状態が加わる (旧 Task15)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Method","Kron");
assert(size(sys.A,1) == n_x + 3 + 3)
assert(max(real(eig_finite(sys))) < 1e-6)


%% With global controller
net = new_net();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Method","Kron");
assert(size(sys.A,1) == n_x + 1)
assert(same_eigs(eig_finite(sys), eig_finite(net.get_sys("Method","Feedback")), 1e-6))
% 大域制御器の状態: Kron / DAE は先頭、Feedback は末尾 (v3 と同じ。get_ss の help)
res = net.linearize();
sv_K = string(res.get_ss("Kron").StateName);
sv_D = string(res.get_ss("DAE").StateName);
sv_F = string(res.get_ss("Feedback").StateName);
n_gc = numel(net.a_GlobalController{1}.sv_x);
assert(all(contains(sv_K(1:n_gc), net.a_GlobalController{1}.s_tag)), strjoin(sv_K(1:n_gc), ","))
assert(isequal(sv_D(1:n_gc), sv_K(1:n_gc)))
assert(isequal(sv_F(end-n_gc+1:end), sv_K(1:n_gc)), strjoin(sv_F(end-n_gc+1:end), ","))


%% SolverLIN constructor of v3 names the remedy
% v3 の SolverLIN(net, NonUnit, ...) は削除: 解法は既定値だけを持つ (net.solver_LIN)
try
    SolverLIN(net, [], "Method", "Kron");
    error("DebugScript:NoError", "SolverLIN(net, ...) がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:v3_linearizer_constructor:OdeLinearizerConstructor", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "net.linearize"))
end
assert(isa(SolverLIN(), "SolverLIN"))
assert(isa(net.solver_LIN, "SolverLIN"))


%% Analytic jacobians match numerical differentiation
% get_sys と SolverODE が使う f_Jacobi* (Jacobi_dx / Jacobi_I / Jacobi_Y) が f_dx, f_I, f_Y の微分と一致する
for key = DebugScript.helper.model_classes("Component").Key'
    [net3, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net3.initialize);
    err = DebugScript.helper.jacobian_error(comp);
    assert(err < 1e-6, key + ": Jacobian error " + err)
end
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
gen.add_local_controller("avr-ST1");
gen.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
con = {gen.a_LocalController{1}, gen.a_LocalController{1}.a_LocalController{1}, ...
       net.a_Bus{2}.a_Component{1}.a_LocalController{1}, net.a_GlobalController{1}};
for k = 1:numel(con)
    err = DebugScript.helper.jacobian_error(con{k});
    assert(err < 1e-6, class(con{k}) + ": Jacobian error " + err)
end


%% Each component type gives same eigenvalues in three algorithms
% 3 母線系統で機器の種類ごとに get_sys を求める (B001: gen-park, B002 または B003: 指定した機器)
for key = DebugScript.helper.model_classes("Component").Key'
    [net3, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net3.initialize);
    sys = net3.get_sys("Method","Kron");
    n_x3 = sum(cellfun(@(b) sum(cellfun(@(cc) numel(cc.sv_x), b.a_Component)), net3.a_Bus));
    assert(size(sys.A,1) == n_x3, key)
    e = eig_finite(sys);
    assert(same_eigs(e, eig_finite(net3.get_sys("Method","Feedback")), 1e-6), key + ": Kron と Feedback の固有値が一致しない")
    assert(same_eigs(e, eig_finite(net3.get_sys("Method","DAE")),      1e-6), key + ": Kron と DAE の固有値が一致しない")
end


%% Local and global controllers in three algorithms
% AVR (ST1, DC1)・PSS・AGC を付けたときも 3 方式の固有値が一致し、IEEE14 は安定
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Method","Kron");
assert(size(sys.A,1) == n_x + 3 + 3 + 4 + 1)
e = eig_finite(sys);
assert(max(real(e)) < 1e-6)
assert(same_eigs(e, eig_finite(net.get_sys("Method","Feedback")), 1e-6))
assert(same_eigs(e, eig_finite(net.get_sys("Method","DAE")),      1e-6))
sys = net.get_sys("Method","DAE");
assert(numel(sys.StateName) == size(sys.A,1))


%% Two global controllers in three algorithms
% 大域制御器が複数でも 3 方式の固有値が一致し、状態は制御器の数だけ増える
net = new_net();
net.add_global_controller("agc-PI", "SG1B001");
net.add_global_controller("agc-PI", ["SG1B002", "SG1B003"], parameter=struct(kI=200));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Method","Kron");
assert(size(sys.A,1) == n_x + 2)
sv_x = string(sys.StateName);
assert(numel(sv_x) == size(sys.A,1) && any(contains(sv_x,net.a_GlobalController{1}.s_tag)) && any(contains(sv_x,net.a_GlobalController{2}.s_tag)))
e = eig_finite(sys);
assert(max(real(e)) < 1e-6)
assert(same_eigs(e, eig_finite(net.get_sys("Method","Feedback")), 1e-6))
assert(same_eigs(e, eig_finite(net.get_sys("Method","DAE")),      1e-6))

% 制御対象を系統の順と逆に並べても同じ系になる (端子は名前で対応付ける)
netA = new_net();
netA.add_global_controller("agc-PI", ["SG1B001", "SG1B002"], parameter=struct(alpha=[2;1], beta=[1;3]));
netB = new_net();
netB.add_global_controller("agc-PI", ["SG1B002", "SG1B001"], parameter=struct(alpha=[1;2], beta=[3;1]));
DebugScript.helper.quiet(@() netA.initialize);
DebugScript.helper.quiet(@() netB.initialize);
eA = eig_finite(netA.get_sys("Method","Feedback"));
for alg = ["Kron","Feedback","DAE"]
    assert(same_eigs(eA, eig_finite(netB.get_sys("Method",alg)), 1e-6), alg + ": 制御対象の順で固有値が変わる")
end
assert(same_eigs(eA, eig_finite(netA.get_sys("Method","Kron")), 1e-6))


%% Inputs, states and outputs of get_sys on each layer
% 制御器: 入力 [V; ucon]、状態 xcon、出力 ycon
% 機器  : 入力 [V; umac; ucon]、状態 [xmac; xcon]、出力 [I; ymac; ycon]
% 母線  : 入力 [V; 各機器の umac, ucon]、状態 [xmac; xcon]、出力 [I; 各機器の ymac, ycon]
% 状態は出力に含めず、状態と同名の出力は "Y_" + 名前にして、すべての名前を一意にする
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
tg = @(o, s) reshape(string(o.attach_tag(s)), [], 1);

sa = avr.get_sys();
assert(isequal(string(sa.InputName), tg(avr, ["Vre";"Vim";avr.sv_u])))
assert(isequal(string(sa.StateName), tg(avr, avr.sv_x)) && isequal(string(sa.OutputName), tg(avr, avr.sv_y)))

sc = gen.get_sys();
sv_in  = [tg(gen, ["Vre";"Vim";gen.sv_u]); tg(avr, avr.sv_u); tg(pss, pss.sv_u)];
sv_x   = [tg(gen, gen.sv_x); tg(avr, avr.sv_x); tg(pss, pss.sv_x)];
sv_out = [tg(gen, ["Ire";"Iim";"Y_omega"]); tg(avr, avr.sv_y); tg(pss, pss.sv_y)];
assert(isequal(string(sc.InputName), sv_in) && isequal(string(sc.StateName), sv_x) && isequal(string(sc.OutputName), sv_out))
sv_all = [sv_in; sv_x; sv_out];
assert(numel(unique(sv_all)) == numel(sv_all), "名前が一意でない")

% 出力の値: Y_omega は発電機の omega、AVR の出力 Vfield は AVR の状態 Vap
iy = string(sc.OutputName) == tg(gen, "Y_omega");
assert(isequal(sc.C(iy,:), double(string(sc.StateName) == tg(gen, "omega"))') && all(sc.D(iy,:) == 0))
iy = string(sc.OutputName) == tg(avr, "Vfield");
assert(isequal(sc.C(iy,:), double(string(sc.StateName) == tg(avr, "Vap"))'))

% 制御器の入力 Vref は外部入力として AVR の状態に入る (AVR 単体の B と同じ)
iu = string(sc.InputName) == tg(avr, "Vref");
ix = ismember(string(sc.StateName), tg(avr, avr.sv_x));
assert(norm(sc.B(ix,iu) - sa.B(:, string(sa.InputName) == tg(avr, "Vref"))) < 1e-12)
assert(all(sc.B(~ix,iu) == 0))

% 母線は機器の入出力を並べ、ポートを母線の名前にする
bus = net.a_Bus{1};
sb  = bus.get_sys();
assert(isequal(string(sb.InputName),  [tg(bus, ["Vre";"Vim"]); sv_in(3:end)]))
assert(isequal(string(sb.OutputName), [tg(bus, ["Ire";"Iim"]); sv_out(3:end)]))
assert(isequal(string(sb.StateName), sv_x) && norm(sb.C - sc.C, 1) == 0 && norm(sb.D - sc.D, 1) == 0)
sbI = bus.get_sys("port", "I2V");
assert(isequal(string(sbI.InputName),  [tg(bus, ["Ire";"Iim"]); sv_in(3:end)]))
assert(isequal(string(sbI.OutputName), [tg(bus, ["Vre";"Vim"]); sv_out(3:end)]))

% 制御器の無い機器も出力に状態を含めない
c3 = net.a_Bus{3}.a_Component{1}.get_sys();
assert(isequal(string(c3.OutputName), tg(net.a_Bus{3}.a_Component{1}, ["Ire";"Iim";"Y_omega"])))


%% Index a model of each layer by full channel name
% Format="ss" のモデルでは sys(出力名, 入力名) は sys(行, 列) と同じ。同名のグループがあると曖昧でエラーになる (Issue #79)
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
c_sys = {avr.get_sys(Format="ss"), pss.get_sys(Format="ss"), gen.get_sys(Format="ss"), gen.get_sys("port","I2V",Format="ss"), ...
         gen.get_sys("tag",false,Format="ss"), net.a_Bus{3}.a_Component{1}.get_sys(Format="ss"), net.a_Bus{1}.get_sys(Format="ss")};
for k = 1:numel(c_sys)
    s = c_sys{k};
    for iy = 1:numel(s.OutputName)
        for iu = 1:numel(s.InputName)
            s1 = s(s.OutputName{iy}, s.InputName{iu});
            assert(isequal(s1.D, s.D(iy,iu)) && isequal(s1.C, s.C(iy,:)) && isequal(s1.B, s.B(:,iu)), "model %d: %s, %s", k, s.OutputName{iy}, s.InputName{iu})
        end
    end
end


%% Layer get_sys: removed arguments, no internal arguments, names and single computation (#83)
net = network.IEEE9bus();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
agc = net.add_global_controller("agc-PI", {gen, net.a_Bus{2}.a_Component{1}}, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);

% full, rec, controllerPorts は機器の get_sys の引数ではない ("con" は名前の部分一致で Controllers になる)
for s_arg = ["full","rec","controllerPorts"]
    l_accepted = true;
    try
        gen.get_sys(s_arg,false);
    catch
        l_accepted = false;
    end
    assert(~l_accepted, "%s が受け付けられた", s_arg)
end
assert(~ismember("get_sys_alone", methods(gen)) && ~ismember("get_sys_alone", methods(avr)))

% どの層でも 2 番目以降の出力は sys の名前と同じ
c_call = {@() gen.get_sys(), @() gen.get_sys("port","I2V"), @() gen.get_sys("tag",false), @() gen.get_sys(Controllers=false), @() net.a_Bus{1}.get_sys(), ...
          @() net.a_Bus{1}.get_sys("port","I2V"), @() avr.get_sys(), @() avr.get_sys("full",true), @() avr.get_sys("tag",false), @() agc.get_sys()};
for k = 1:numel(c_call)
    [s, c_x, c_u, c_y] = c_call{k}();
    assert(iscellstr(c_x) && isequal(string(c_x(:)), s.StateName), "call %d: states", k) %#ok<ISCLSTR>
    assert(iscellstr(c_u) && isequal(string(c_u(:)), s.InputName), "call %d: inputs", k) %#ok<ISCLSTR>
    assert(iscellstr(c_y) && isequal(string(c_y(:)), s.OutputName), "call %d: outputs", k) %#ok<ISCLSTR>
end

% 制御器のモデルは 1 回の gen.get_sys() で 1 個につき 1 回だけ計算する
profile("on");
gen.get_sys();
profile("off");
tab = struct2table(profile("info").FunctionTable);
lv  = contains(string(tab.FileName), "@LocalController") & endsWith(string(tab.FunctionName), "linearize_alone");
assert(sum(tab.NumCalls(lv)) == 2, "制御器 2 個に %d 回", sum(tab.NumCalls(lv)))


%% Component get_sys without controllers is the component alone
% Controllers=false: 入力はポートと sv_u、状態は sv_x、出力は他方のポート (制御器を含まない)
net = network.IEEE9bus();
gen = net.a_Bus{1}.a_Component{1};
gen.add_local_controller("avr-ST1");
gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
x = gen.rv_Xequilibrium;  V = [real(gen.c_Vequilibrium); imag(gen.c_Vequilibrium)];
I = [real(gen.c_Iequilibrium); imag(gen.c_Iequilibrium)];  u = gen.rv_Uequilibrium;
nx = numel(gen.sv_x);  nu = numel(gen.sv_u);
[Axx, Bxv, ~, Bxu] = gen.f_JacobiDx(0, x, V, I, u);
[Cix, Div, ~, Diu] = gen.f_JacobiI(0, x, V, I, u);
Axx = reshape(full(Axx), nx, nx);  Bxv = reshape(full(Bxv), nx, 2);  Bxu = reshape(full(Bxu), nx, nu);
Cix = reshape(full(Cix), 2, nx);   Div = reshape(full(Div), 2, 2);   Diu = reshape(full(Diu), 2, nu);
E   = reshape(full(gen.f_Mass(0, x, V, I, u)), nx, nx);

s = gen.get_sys(Controllers=false, Format="struct", tag=false);
assert(isequal(s.A, Axx) && isequal(s.B, [Bxv, Bxu]) && isequal(s.C, Cix) && isequal(s.D, [Div, Diu]) && isequal(s.E, E))
assert(isequal(s.StateName, reshape(gen.sv_x, [], 1)) && isequal(s.InputName, ["Vre";"Vim";reshape(gen.sv_u, [], 1)]) ...
       && isequal(s.OutputName, ["Ire";"Iim"]))
assert(isequal(gen.get_sys(x, V, I, u, Controllers=false, Format="struct", tag=false), s))   % 平衡点を与えても同じ

% I2V は V2I の D の電圧の列を解いた形
s2 = gen.get_sys(Controllers=false, Format="struct", tag=false, port="I2V");
assert(norm(s2.A - (Axx - Bxv/Div*Cix)) < 1e-12 && norm(s2.D - [inv(Div), -Div\Diu]) < 1e-12)
assert(isequal(s2.InputName, ["Ire";"Iim";reshape(gen.sv_u, [], 1)]) && isequal(s2.OutputName, ["Vre";"Vim"]))

% 名前は tag で機器のタグを付け、ResultLIN は機器自身の変数だけを持つ
res = gen.get_sys(Controllers=false);
assert(isa(res, "ResultLIN") && isequal(res.A, s.A) && isequal(res.D, s.D) && res.output.l_equilibrium)
assert(isequal(res.StateName, reshape(string(gen.attach_tag(gen.sv_x)), [], 1)))
assert(isequal(res.rv_point, [x; V; u]) && height(res.tab_variable) == nx + 2 + nu)
assert(all(res.tab_variable.Kind(1:nx) == "x" & res.tab_variable.Owner(1:nx) == gen.s_tag))
assert(isequal(res.rm_Axx, s.A) && isequal(res.rm_Axv, s.B(:,1:2)) && isequal(res.rm_Bx, s.B(:,3:end)))

% 制御器のない機器では get_sys と同じ
load1 = net.a_Bus{5}.a_Component{1};
sa = load1.get_sys(Controllers=false, Format="struct");
sb = load1.get_sys(Format="struct");
assert(isequal(sa.A, sb.A) && isequal(sa.B, sb.B) && isequal(sa.C, sb.C) && isequal(sa.D, sb.D) && isequal(sa.E, sb.E) ...
       && isequal(sa.InputName, sb.InputName) && isequal(sa.OutputName, sb.OutputName))


%% Linearize matches v3 get_sys matrices for every algorithm
% linearize + get_ss の行列と名前は v3 の SolverLIN と同じ (helper.linearize_v3 に v3 のコードを保存)。
% 違いは DAE の B の代数方程式の行の符号 (v3 は入力 u の符号が逆で、Kron と伝達関数が合わなかった) と、
% Feedback が P=Q=0 の負荷の入力を残すこと (v3 は落とした)。nonunit は v3 に渡す指定で、v4 は自動判定で同じ行列になる。
% 電流のある母線の指定は v3 と別の結果になる (v3 は機器を落とした) ので、ここでは比べない。
nets = {};  nonunit = {};
nets{end+1} = new_net();  nonunit{end+1} = [];
nets{end+1} = new_net();  nonunit{end+1} = 7;
n4 = new_net();
n4.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
n4.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
n4.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
n4.add_global_controller("agc-PI", {n4.a_Bus{1}.a_Component{1}, n4.a_Bus{2}.a_Component{1}}, parameter=struct(alpha=[1;1], beta=[1;1]));
n4.add_global_controller("agc-PI", "SG1B003", parameter=struct(kI=200));
nets{end+1} = n4;  nonunit{end+1} = [];
for key = ["gen-1axis","gen-droop","load-impedance"]
    nets{end+1} = DebugScript.helper.build_3bus(key);  nonunit{end+1} = []; %#ok<SAGROW>
end
for k = 1:numel(nets)
    DebugScript.helper.quiet(@() nets{k}.initialize);
    res = nets{k}.linearize();
    for alg = ["Kron","Feedback","DAE"]
        sys_ful = res.get_ss(alg);
        sys_new = sys_ful;
        sys_old = DebugScript.helper.linearize_v3(nets{k}, nonunit{k}, alg);
        str = nets{k}.s_tag + " " + alg;
        if alg == "Feedback"
            sys_new = sys_ful(:, ismember(sys_ful.InputName, sys_old.InputName));
        end
        B_old = sys_old.B;
        if alg == "DAE"
            n_x = size(res.rm_Axx,1);
            B_old(n_x+1:end,:) = -B_old(n_x+1:end,:);
        end
        assert(isequal(size(sys_new.A), size(sys_old.A)), str)
        tol = 1e-10 * max(1, norm(sys_old.A, 1));
        assert(norm(sys_new.A - sys_old.A, 1) <= tol && norm(sys_new.E - sys_old.E, 1) <= tol, str + ": A, E")
        assert(norm(sys_new.B - B_old, 1) <= tol && norm(sys_new.C - sys_old.C, 1) <= tol && norm(sys_new.D - sys_old.D, 1) <= tol, str + ": B, C, D")
        assert(isequal(sys_new.StateName, sys_old.StateName) && isequal(sys_new.InputName, sys_old.InputName) && ...
               isequal(sys_new.OutputName, sys_old.OutputName), str + ": names")
        % net.get_sys は linearize + get_ss と同じ
        assert(isequal(nets{k}.get_sys("Method", alg, "Format", "ss"), sys_ful), str + ": get_sys")
    end
end


%% DAE input matrix agrees with Kron
% DAE と Kron は入力 u から状態 x までの伝達関数が同じ (v3 の DAE は B の符号のため一致しなかった)
res = net.linearize();
sK = res.get_ss("Kron");
for crd = ["theta&rho","theta&V","Vre&Vim"]
    sD = res.get_ss("DAE", "Coordinate", crd);
    s0 = 0.3 + 1i;
    GK = freqresp(sK, s0);  GD = freqresp(sD, s0);
    assert(norm(GK - GD) < 1e-8 * norm(GK), crd)
end


%% Variable map is consistent with the linear model
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["SG1B001", "SG1B002"]);
DebugScript.helper.quiet(@() net.initialize);
[tab, c_idxBus, c_idxGC] = net.get_variable_map();
res = net.linearize();
assert(isequal(res.tab_variable, tab))
assert(isequal(string(tab.Properties.VariableNames), ["Index","Kind","Owner","Name","Label","Bus"]))
assert(isequal(tab.Index, (1:height(tab))'))
n_x = size(res.rm_Axx,1);  n_v = size(res.rm_Avv,1);  n_u = size(res.rm_Bx,2);
assert(sum(tab.Kind == "x") == n_x && sum(tab.Kind == "Vre" | tab.Kind == "Vim") == n_v && sum(tab.Kind == "u") == n_u)
assert(isequal(tab.Kind, [repmat("x",n_x,1); repmat(["Vre";"Vim"],n_v/2,1); repmat("u",n_u,1)]))
assert(n_v == 2*numel(net.a_Bus) && numel(res.rv_point) == height(tab))
assert(isequal(size(res.rm_Axv), [n_x n_v]) && isequal(size(res.rm_Avx), [n_v n_x]) && isequal(size(res.rm_Bv), [n_v n_u]) && isequal(size(res.rm_E), [n_x n_x]))
% 状態と入力の名前は get_ss の StateName / InputName と同じもの (大域制御器の状態は get_ss("Kron") では先頭)
sK = res.get_ss("Kron");
assert(isequal(sort(tab.Label(tab.Kind == "x")), sort(string(sK.StateName))))
assert(isequal(tab.Label(tab.Kind == "u"), string(sK.InputName)))
s_gc = net.a_GlobalController{1}.s_tag;
assert(any(tab.Owner == s_gc) && all(tab.Bus(tab.Owner == s_gc) == "") && isequal(tab.Label(c_idxGC{1}), tab.Label(tab.Owner == s_gc)))
% 制御器の状態は機器の直後 (AVR, その下の PSS の順)
iv = find(tab.Bus == "B001" & tab.Kind == "x");
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(isequal(tab.Owner(iv), [repmat("SG1B001",numel(net.a_Bus{1}.a_Component{1}.sv_x),1); ...
                               repmat(avr.s_tag,numel(avr.sv_x),1); repmat(avr.a_LocalController{1}.s_tag,numel(avr.a_LocalController{1}.sv_x),1)]))
% 母線・機器の変数の表は系統の表の該当行と同じ順
for i = 1:numel(net.a_Bus)
    [tab_b, c_idxC] = net.a_Bus{i}.get_variable_map();
    assert(isequal(tab_b(:,2:end), tab(c_idxBus{i},2:end)), "bus " + i)
    for j = 1:numel(c_idxC)
        tab_c = net.a_Bus{i}.a_Component{j}.get_variable_map();
        assert(isequal(tab_c(:,2:end), tab_b(c_idxC{j},2:end)), "bus " + i + " comp " + j)
    end
end
% 平衡点の値: 機器の平衡点と母線電圧
gen = net.a_Bus{1}.a_Component{1};
assert(isequal(res.rv_point(tab.Owner == "SG1B001" & tab.Kind == "x"), gen.rv_Xequilibrium))
assert(isequal(res.rv_point(tab.Owner == "SG1B001" & tab.Kind == "u"), gen.rv_Uequilibrium))
V = net.a_Bus{3}.c_Vequilibrium;
assert(isequal(res.rv_point(tab.Bus == "B003" & tab.Kind ~= "x" & tab.Kind ~= "u"), [real(V); imag(V)]))
assert(res.output.l_equilibrium && res.l_success)


%% Point at the equilibrium equals the default
% 平衡点の値を Point に与えると既定 (平衡点) と同じ行列になる (制御器の入力も出力から求め直す)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
net.add_global_controller("agc-PI", ["SG1B001", "SG1B002"]);
DebugScript.helper.quiet(@() net.initialize);
res0 = net.linearize();
res1 = net.linearize("Point", res0.rv_point);
assert(~res1.output.l_equilibrium && isequal(res1.rv_point, res0.rv_point))
for str = ["rm_Axx","rm_Axv","rm_Bx","rm_Avx","rm_Avv","rm_Bv","rm_E"]
    assert(norm(res1.(str) - res0.(str), 1) < 1e-8 * max(1, norm(res0.(str), 1)), str)
end
for alg = ["Kron","Feedback","DAE"]
    assert(same_eigs(eig_finite(res0.get_ss(alg)), eig_finite(res1.get_ss(alg)), 1e-6), alg)
end
% 機器・母線の get_sys も同じ
[tab, c_idxBus] = net.get_variable_map();
bus = net.a_Bus{1};
s0 = bus.get_sys();  s1 = bus.get_sys("Point", res0.rv_point(c_idxBus{1}));
assert(norm(s0.A - s1.A, 1) < 1e-8 * norm(s0.A, 1) && isequal(s0.StateName, s1.StateName))


%% LQR closed loop matches its design model
% 1機無限大母線系統では、系統の線形モデルが LQR の設計モデルと一致する
% (開ループの固有値 = eig(A)、閉ループの固有値 = eig(A - B K)。無限大母線の近似による 0 付近の固有値は除く)
[smib, gen] = DebugScript.helper.build_smib();
DebugScript.helper.quiet(@() smib.initialize);
e_open = eig_finite(smib.get_sys());
lqr = gen.add_local_controller("local-LQR");
DebugScript.helper.quiet(@() smib.initialize);
for alg = ["Kron","Feedback","DAE"]
    e_closed = eig_finite(smib.get_sys("Method", alg));
    e_closed = e_closed(abs(e_closed) > 1e-2);
    assert(same_eigs(e_closed, eig(lqr.sys_design.A - lqr.sys_design.B*lqr.K), 1e-3), alg)
end
e_open = e_open(abs(e_open) > 1e-2);
assert(same_eigs(e_open, eig(lqr.sys_design.A), 1e-3))

% LQR は開ループより減衰を良くする (最も右の固有値が左へ動く)
assert(max(real(e_closed)) < max(real(e_open)) - 0.5)


%% LQR improves the damping of IEEE14
% IEEE14 の発電機 1, 2 に既定の重み (Q = I, R = I) の LQR を付けると、
% 最も右の固有値が左へ動き、振動モードの最小減衰比が大きくなる
damping = @(e) min(-real(e(abs(imag(e)) > 1e-3)) ./ abs(e(abs(imag(e)) > 1e-3)));
rightmost = @(e) max(real(e(abs(e) > 1e-6)));
e0 = eig_finite(net.get_sys());
netL = new_net();
for b = 1:2
    netL.a_Bus{b}.a_Component{1}.add_local_controller("local-LQR");
end
DebugScript.helper.quiet(@() netL.initialize);
e1 = eig_finite(netL.get_sys());
assert(rightmost(e1) < rightmost(e0) - 0.01, "rightmost " + rightmost(e0) + " -> " + rightmost(e1))
assert(damping(e1) > damping(e0), "damping " + damping(e0) + " -> " + damping(e1))
for alg = ["Kron","Feedback"]
    assert(same_eigs(e1, eig_finite(netL.get_sys("Method", alg)), 1e-6), alg)
end

% 平衡点の値を Point に与えると既定と同じ (LQR の入力は機器の状態から求め直す)
res0 = netL.linearize();
res1 = netL.linearize("Point", res0.rv_point);
for str = ["rm_Axx","rm_Axv","rm_Bx","rm_Avx","rm_Avv","rm_Bv","rm_E"]
    assert(norm(res1.(str) - res0.(str), 1) < 1e-8 * max(1, norm(res0.(str), 1)), str)
end


%% Point at a perturbed state
% 平衡点からずらした点では、その点の x, V, u で各機器の Jacobian を評価する。モデルと解法は変わらない
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
[tab, c_idxBus] = net.get_variable_map();
res0 = net.linearize();
x = res0.rv_point;
gen  = net.a_Bus{2}.a_Component{1};
iv_x = find(tab.Owner == gen.s_tag & tab.Kind == "x");
iv_V = find(tab.Bus == "B002" & (tab.Kind == "Vre" | tab.Kind == "Vim"));
iv_u = find(tab.Owner == gen.s_tag & tab.Kind == "u");
x(iv_x(1)) = x(iv_x(1)) + 0.2;            % delta
x(iv_V)    = x(iv_V) * 1.03;
x(iv_u(1)) = x(iv_u(1)) + 0.1;
xe = gen.rv_Xequilibrium;
res1 = net.linearize("Point", x);
assert(isequal(gen.rv_Xequilibrium, xe) && isempty(net.solver_LIN.get_options().Point), "モデルまたは解法が変わった")
assert(norm(res1.rm_Axx(iv_x,iv_x) - res0.rm_Axx(iv_x,iv_x), 1) > 1e-6, "ずらしても行列が変わらない")
% 期待値: その点での f_JacobiDx / f_JacobiI (I は fcn_I から)
xg = x(iv_x);  Vg = x(iv_V);  ug = x(iv_u);
Ig = gen.f_I(0, xg, Vg, zeros(2,1), ug);  Ig = [real(Ig); imag(Ig)];
[Axx, Bxv, ~, Bxu] = gen.f_JacobiDx(0, xg, Vg, Ig, ug);
[Cix, Div, ~, Diu] = gen.f_JacobiI(0, xg, Vg, Ig, ug);
iv_v = iv_V - sum(tab.Kind == "x");   iv_uu = iv_u - sum(tab.Kind ~= "u");
assert(norm(res1.rm_Axx(iv_x,iv_x) - Axx, 1) < 1e-10)
assert(norm(res1.rm_Axv(iv_x,iv_v) - Bxv, 1) < 1e-10)
assert(norm(res1.rm_Bx(iv_x,iv_uu) - Bxu, 1) < 1e-10)
assert(norm(res1.rm_Avx(iv_v,iv_x) + Cix, 1) < 1e-10)
assert(norm(res1.rm_Bv(iv_v,iv_uu) + Diu, 1) < 1e-10)
% Avv: Y から母線 B002 のすべての機器 (発電機と負荷) の Div を引いたもの
Div_sum = Div;
for j = 2:numel(net.a_Bus{2}.a_Component)
    cj = net.a_Bus{2}.a_Component{j};
    xj = x(tab.Owner == cj.s_tag & tab.Bus == "B002" & tab.Kind == "x");
    uj = x(tab.Owner == cj.s_tag & tab.Bus == "B002" & tab.Kind == "u");
    Ij = cj.f_I(0, xj, Vg, zeros(2,1), uj);  Ij = [real(Ij); imag(Ij)];
    [~, Divj] = cj.f_JacobiI(0, xj, Vg, Ij, uj);
    Div_sum = Div_sum + reshape(full(Divj), 2, 2);
end
Y = tools.complex2matrix(net.get_admittance_matrix.Variables);
assert(norm(res1.rm_Avv(iv_v,iv_v) - (Y(iv_v,iv_v) - Div_sum), 1) < 1e-10)
% 機器の get_sys(Point=...) も同じ点で評価する
[~, c_idxC] = net.a_Bus{2}.get_variable_map();
xb = x(c_idxBus{2});
sc = gen.get_sys("Point", xb(c_idxC{1}));
assert(norm(sc.A - Axx, 1) < 1e-10)
% Point の長さが違うと、変数の表を案内するエラー
try
    net.linearize("Point", x(1:end-1));
    error("DebugScript:NoError", "長さの違う Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointSize", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "get_variable_map"))
end
try
    net.linearize("Point", "equilibrium");
    error("DebugScript:NoError", "文字列の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointType", DebugScript.helper.msg_id(ME))
end


%% Point from a simulation result and a time
% Point={sim, t}: 時刻 t の機器の状態・入力と母線電圧 (ResultODE の値) で線形化する
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = net.simulate([0,1.5], ev);
r   = sim.odeResults;
tab = net.get_variable_map();
k   = find(r.t > 0.8, 1);
t   = r.t(k);
x   = zeros(height(tab),1);
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    x(tab.Bus == bus.s_tag & tab.Kind == "Vre") = r.Bus(i).V{k,1};
    x(tab.Bus == bus.s_tag & tab.Kind == "Vim") = r.Bus(i).V{k,2};
    for j = 1:numel(bus.a_Component)
        c = bus.a_Component{j};
        x(tab.Owner == c.s_tag & tab.Bus == bus.s_tag & tab.Kind == "x") = r.Bus(i).Component(j).X{k,:};
        x(tab.Owner == c.s_tag & tab.Bus == bus.s_tag & tab.Kind == "u") = r.Bus(i).Component(j).U{k,:};
    end
end
res = net.linearize("Point", {sim, t});
assert(norm(res.rv_point - x) < 1e-12)
res_x = net.linearize("Point", x);
assert(isequal(res.rm_Axx, res_x.rm_Axx) && isequal(res.rm_Avv, res_x.rm_Avv))
assert(norm(res.rv_point - net.linearize().rv_point) > 1e-4, "t が平衡点のまま")
% 出力時刻の間は線形補間
tm = (r.t(k) + r.t(k+1)) / 2;
res_m = net.linearize("Point", {sim, tm});
assert(norm(res_m.rv_point - (net.linearize("Point",{sim,r.t(k)}).rv_point + net.linearize("Point",{sim,r.t(k+1)}).rv_point)/2) < 1e-12)
% 機器・母線でも同じ形
gen = net.a_Bus{1}.a_Component{1};
sc  = gen.get_sys("Point", {sim, t});
iv_x = tab.Owner == gen.s_tag & tab.Kind == "x";
assert(norm(sc.A - res.rm_Axx(iv_x,iv_x), 1) < 1e-10)
sb  = net.a_Bus{1}.get_sys("Point", {sim, t});
assert(norm(sb.A - sc.A, 1) == 0)
% 範囲外の時刻
try
    net.linearize("Point", {sim, 10});
    error("DebugScript:NoError", "範囲外の時刻がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultODE:PointTime", DebugScript.helper.msg_id(ME))
end
% Point={sim, t, Side}: 第 3 要素は sim.get_point の Side
assert(isequal(net.linearize("Point", {sim, t, "before"}).rv_point, res.rv_point))
try
    net.linearize("Point", {sim, t, "middle"});
    error("DebugScript:NoError", "知らない Side がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointType", DebugScript.helper.msg_id(ME))
end


%% Point from a simulation with controllers at an equilibrium time
% 局所制御器 (AVR + PSS, AVR) と大域制御器 (AGC) の状態も結果に入るので、外乱のない
% シミュレーションの途中の時刻で線形化すると既定 (平衡点) と同じ行列になる
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
net.add_global_controller("agc-PI", ["SG1B001", "SG1B002"]);
DebugScript.helper.quiet(@() net.initialize);
sim  = net.simulate([0,1]);
res0 = net.linearize();
res1 = net.linearize("Point", {sim, 0.5});
tab  = res0.tab_variable;
assert(~res1.output.l_equilibrium && height(res1.tab_variable) == height(tab))
avr1 = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
sv_con = [avr1.s_tag, avr1.a_LocalController{1}.s_tag, net.a_Bus{2}.a_Component{1}.a_LocalController{1}.s_tag, ...
          net.a_GlobalController{1}.s_tag];
assert(all(ismember(sv_con, tab.Owner)))
assert(norm(res1.rv_point - res0.rv_point, Inf) < 1e-6, "平衡点のシミュレーションの点が平衡点と違う")
for str = ["rm_Axx","rm_Axv","rm_Bx","rm_Avx","rm_Avv","rm_Bv","rm_E"]
    assert(norm(res1.(str) - res0.(str), 1) < 1e-5 * max(1, norm(res0.(str), 1)), str)
end
for alg = ["Kron","Feedback","DAE"]
    assert(same_eigs(eig_finite(res0.get_ss(alg)), eig_finite(res1.get_ss(alg)), 1e-4), alg)
end


%% Point from a simulation with controllers at a perturbed time
% 地絡後の時刻では、その時刻の機器・制御器の状態で各機器の Jacobian を評価する
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["SG1B002", "SG1B006"], parameter=struct(kP=100, kI=500));   % SG1B001, SG1B003 は AGC の外
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = net.simulate([0,1.5], ev);
t   = 0.9;
res0 = net.linearize();
res  = net.linearize("Point", {sim, t});
[tab, c_idxBus, c_idxGC] = net.get_variable_map();
x   = sim.get_point(t);
assert(isequal(res.rv_point, x))
assert(all(isfinite(x)))
% 制御器の状態も平衡点から動いている
avr1 = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
for str = [avr1.s_tag, avr1.a_LocalController{1}.s_tag, net.a_GlobalController{1}.s_tag]
    iv = tab.Owner == str;
    assert(norm(x(iv) - res0.rv_point(iv)) > 1e-6, str + " の状態が平衡点のまま")
end
% 制御器のない発電機: その点での f_JacobiDx / f_JacobiI
gen  = net.a_Bus{3}.a_Component{1};
iv_x = find(tab.Owner == gen.s_tag & tab.Kind == "x");
iv_V = find(tab.Bus == "B003" & (tab.Kind == "Vre" | tab.Kind == "Vim"));
iv_u = find(tab.Owner == gen.s_tag & tab.Kind == "u");
xg = x(iv_x);  Vg = x(iv_V);  ug = x(iv_u);
Ig = gen.f_I(0, xg, Vg, zeros(2,1), ug);  Ig = [real(Ig); imag(Ig)];
[Axx, Bxv, ~, Bxu] = gen.f_JacobiDx(0, xg, Vg, Ig, ug);
[Cix, ~, ~, Diu]   = gen.f_JacobiI(0, xg, Vg, Ig, ug);
iv_v = iv_V - sum(tab.Kind == "x");   iv_uu = iv_u - sum(tab.Kind ~= "u");
assert(norm(res.rm_Axx(iv_x,iv_x) - Axx, 1) < 1e-10)
assert(norm(res.rm_Axv(iv_x,iv_v) - Bxv, 1) < 1e-10)
assert(norm(res.rm_Bx(iv_x,iv_uu) - Bxu, 1) < 1e-10)
assert(norm(res.rm_Avx(iv_v,iv_x) + Cix, 1) < 1e-10)
assert(norm(res.rm_Bv(iv_v,iv_uu) + Diu, 1) < 1e-10)
% AVR + PSS 付きの発電機: 機器の get_sys(Point={sim, t}) と同じブロック (制御器の状態を含む)
gen1 = net.a_Bus{1}.a_Component{1};
[~, c_idxC] = net.a_Bus{1}.get_variable_map();
iv_b = c_idxBus{1};
iv_c = iv_b(c_idxC{1});
iv_cx = iv_c(tab.Kind(iv_c) == "x");
sc = gen1.get_sys("Point", {sim, t});
assert(norm(sc.A - res.rm_Axx(iv_cx,iv_cx), 1) < 1e-10)
assert(norm(sc.A - res0.rm_Axx(iv_cx,iv_cx), 1) > 1e-6, "制御器付きの機器の行列が平衡点のまま")
assert(isequal(gen1.get_sys("Point", x(iv_c)).A, sc.A))
% 大域制御器の状態は Point の値のまま
assert(isequal(res.rv_point(c_idxGC{1}), x(c_idxGC{1})))


%% Overrides apply to one call and leave the solver unchanged
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
sct_before = net.solver_LIN.get_options();
res = net.linearize("Method", "Kron");
assert(isequal(net.solver_LIN.get_options(), sct_before))
assert(res.options.Method == "Kron")
assert(isequal(res.get_ss(), res.get_ss("Kron")))
% 既定値は GUILDA.setting の Linearization。変えると以後の呼び出しに効く (solver_LIN は設定を持たない)
n_x = size(res.rm_Axx,1);
assert(GUILDA.config("Linearization", "Method") == "Feedback" && ~isprop(net.solver_LIN, "Method") && ~isprop(net.solver_LIN, "Point"))
c_cfg = DebugScript.helper.user_config("Linearization", struct("Method", "DAE"));
assert(size(net.get_sys().A,1) > n_x)
clear c_cfg
% Plot オプションは廃止 (図は result.Plot)、PlotFcn は "none" のみ
assert(error_id(@() net.linearize(Plot=true)) == "GUILDA:resolve_options:UnknownName")
assert(error_id(@() net.get_sys(Plot=true)) == "GUILDA:resolve_options:UnknownName")
assert(error_id(@() net.linearize(PlotFcn="eig")) == "GUILDA:check_plotfcn:InDevelopment")
assert(net.linearize(PlotFcn="none").options.PlotFcn == "none")
% 知らない名前は受け付ける名前を示すエラー
try
    net.linearize("Methd", "Kron");
    error("DebugScript:NoError", "知らない名前がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:resolve_options:UnknownName", DebugScript.helper.msg_id(ME))
end


%% Get sys returns sys, flag and output
% v4: [sys, flag, output] = net.get_sys(...) (v3 の 2 番目の出力 lin は flag になった)。
[sys, flag, output] = net.get_sys("Method", "Kron");
assert(isa(sys, "ResultLIN") && islogical(flag) && flag)
assert(sys == output.result)
assert(isstring(output.message))
% Format で形を選ぶ: 既定 "GUILDAorigin" は ResultLIN。構造体と ss はどれも同じ行列と名前
assert(isa(net.get_sys("Method", "Kron", "Format", "GUILDAorigin"), "ResultLIN"))
try
    net.get_sys(Format="ResultLIN");
    error("DebugScript:NoError", "Format=""ResultLIN"" should stop")
catch ME
    assert(ME.identifier == "MATLAB:validators:mustBeMember", ME.identifier)
end
sct =net.get_sys("Method", "Kron", "Format", "struct");
assert(isstruct(sct) && isequal(string(fieldnames(sct))', ["A","B","C","D","E","StateName","InputName","OutputName"]))
sss = net.get_sys("Method", "Kron", "Format", "ss");
assert(isa(sss, "ss") && isequal(output.result.get_ss(), sss))
for str = ["A","B","C","D","E","StateName","InputName","OutputName"]
    assert(isequal(sct.(str), sys.(str)), str)
end
assert(isequal(sss.A, sys.A) && isequal(string(sss.StateName), sys.StateName))


%% Flag reports a singular Avv
% P=Q=0 の負荷だけの 2 母線は Y が特異で、出荷モデルだけで rcond(Avv)=0 になる (Issue #76)
net_s = PowerNetwork("Floating");
net_s.add_bus("V", 1);
net_s.add_bus();
net_s.add_branch("pi", [1,2], "R", 0.01, "X", 0.085);
net_s.a_Bus{1}.add_component("load-power", "P", 0, "Q", 0);
net_s.a_Bus{2}.add_component("load-power", "P", 0, "Q", 0);
DebugScript.helper.quiet(@() net_s.initialize);
[res, flag, output] = net_s.linearize();
assert(islogical(flag) && ~flag && ~res.l_success)
assert(output.s_issue == "SingularAvv" && output.rcond_Avv < 1e-14)
assert(contains(output.message, "Avv") && contains(output.message, "B001"), output.message)
for alg = ["Kron", "Feedback"]
    try
        net_s.get_sys("Method", alg);
        error("DebugScript:NoError", alg + ": エラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultLIN:SingularAvv", DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, "DAE") && contains(ME.message, "B001"), ME.message)
    end
end
% DAE は電圧を消去しないので取り出せる
[sys, flag, output] = net_s.get_sys("Method", "DAE");
assert(isa(sys, "ResultLIN") && ~flag && output.s_issue == "SingularAvv" && ~isempty(sys.A))
% Kron は使えないので linearize の結果の A などは空
res = net_s.linearize("Method", "Kron");
assert(isempty(res.A) && isempty(res.StateName))
% 使える結果は flag が true で s_issue は空
[~, flag, output] = net.linearize();
assert(flag && output.s_issue == "" && output.rcond_Avv > 1e-14)


%% Point that is not finite names the variables
% NaN の点は dss に届く前に、変数の名前を示すエラーで止まる (Issue #76)
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
tab = n14.get_variable_map();
x = n14.linearize().rv_point;
x(5) = NaN;
x(7) = Inf;
try
    n14.get_sys("Point", x);
    error("DebugScript:NoError", "NaN の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, tab.Label(5)) && contains(ME.message, tab.Label(7)), ME.message)
    assert(~contains(ME.message, tab.Label(6) + ","), ME.message)
end
try
    n14.linearize("Point", nan(height(tab),1));
    error("DebugScript:NoError", "NaN の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "more"), ME.message)
end
% トリップ中の {sim, t}: 解列した機器の状態が NaN
sim = n14.simulate([0,2], DebugScript.helper.scenario("trip", n14, "TimeSpan", [1,1.5], "TripUnit", "SG1B002"));
try
    n14.get_sys("Point", {sim, 1.2});
    error("DebugScript:NoError", "トリップ中の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "SG1B002") && contains(ME.message, "trip"), ME.message)
end
assert(n14.linearize("Point", {sim, 0.5}).l_success)


%% Point around a trip
% トリップの区間だけ NaN の点で止まり、境界は Side に従う。復帰後は機器を含めた通常の点として線形化する
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
sim = n14.simulate([0,2], DebugScript.helper.scenario("trip", n14, "TimeSpan", [1,1.5], "TripUnit", "SG1B002"), Progress="none");
res0 = n14.linearize();
tab  = res0.tab_variable;
for c_point = {{sim,1}, {sim,1.2}, {sim,1.5,"before"}}
    try
        n14.linearize("Point", c_point{1});
        error("DebugScript:NoError", "トリップ中の Point がエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, "SG1B002") && contains(ME.message, "trip"), ME.message)
    end
end
for c_point = {{sim,1,"before"}, {sim,1.5}, {sim,1.8}}
    [res, flag, output] = n14.linearize("Point", c_point{1});
    assert(flag && all(isfinite(res.rv_point)))
    assert(isequal(res.tab_variable, tab))
    for alg = ["Kron","Feedback","DAE"]
        s = DebugScript.helper.quiet(@() res.get_ss(alg, "Coordinate", "Vre&Vim"));
        s0 = DebugScript.helper.quiet(@() res0.get_ss(alg, "Coordinate", "Vre&Vim"));
        assert(isequal(size(s.A), size(s0.A)) && isequal(s.StateName, s0.StateName) && isequal(s.InputName, s0.InputName), alg)
    end
end
% トリップ中でも、トリップしていない機器は単独で線形化できる
x = sim.get_point(1.2);
gen3 = n14.a_Bus{3}.a_Component{1};
[~, c_idxBus] = n14.get_variable_map();
[~, c_idxC] = n14.a_Bus{3}.get_variable_map();
iv = c_idxBus{3}(c_idxC{1});
sc = gen3.get_sys("Point", {sim, 1.2});
assert(all(isfinite(sc.A), "all") && isequal(sc.A, gen3.get_sys("Point", x(iv)).A))


%% Point inside a fault is reported and keeps the model network
% Point は変数の点で、網はモデルのもの: 故障中の {sim, t} でも Y は故障前のまま。呼び出しがそれを知らせる (Issue #82)
n9 = network.IEEE9bus();
DebugScript.helper.quiet(@() n9.initialize);
ev  = DebugScript.helper.scenario("short", n9, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = n9.simulate([0,1], ev, Progress="none", TimeLimit=120);
str = evalc('[res, flag, output] = n9.linearize("Point", {sim, 0.52});');
assert(contains(str, "INFO") && contains(str, "B008"), str)
assert(flag && output.s_issue == "" && isequal(output.sv_faultBus, "B008"))
assert(contains(output.message, "B008"), output.message)
assert(norm(res.sct_model.cm_Y - n9.get_admittance_matrix.Variables, 1) == 0)
% 極座標の DAE はここでは使えないが、Vre&Vim は Kron, Feedback と同じ固有値になる
e_k = eig_finite(res.get_ss("Kron"));
assert(max(real(e_k)) > 1, "故障中の点の固有値が変わった")
assert(same_eigs(e_k, eig_finite(res.get_ss("Feedback")), 1e-6))
assert(same_eigs(e_k, eig_finite(DebugScript.helper.quiet(@() res.get_ss("DAE", "Coordinate", "Vre&Vim"))), 1e-6))
% 故障の前後は故障として扱わない。境界では Side に従う
[~, ~, out_b] = n9.linearize("Point", {sim, 0.5, "before"});
[~, ~, out_a] = n9.linearize("Point", {sim, 0.5});
assert(isempty(out_b.sv_faultBus) && isequal(out_a.sv_faultBus, "B008"))
str = evalc('[~, ~, out_p] = n9.linearize("Point", {sim, 0.8});');
assert(isempty(out_p.sv_faultBus) && ~contains(str, "INFO") && ~contains(out_p.message, "ground fault"))


%% Message tells the equilibrium from a given point
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
res0 = n14.linearize();
assert(res0.output.l_equilibrium && res0.output.message == "Linearized at the equilibrium.")
[~, ~, output] = n14.linearize("Point", res0.rv_point);
assert(~output.l_equilibrium && output.message == "Linearized at the given point.")


%% Jacobian that is not finite names the bus
% 有限な点でも V=0 では定電力負荷の Jacobian が有限にならない (Issue #76)
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
tab = n14.get_variable_map();
x = n14.linearize().rv_point;
x(tab.Kind == "Vre" | tab.Kind == "Vim") = 0;
try
    n14.linearize("Point", x);
    error("DebugScript:NoError", "V=0 の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:JacobianNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "bus B"), ME.message)
end


%% Linearization result Plot
res = net.linearize();
ax = res.Plot();
assert(isa(ax, "matlab.graphics.axis.Axes"))
close(ancestor(ax, "figure"))
ax = res.Plot("Method", "Feedback");
close(ancestor(ax, "figure"))


%% Plot draws the algorithm of the options
% 既定は options.Method。Method を渡せばそちらを描く
for alg = ["Feedback", "Kron", "DAE"]
    res = DebugScript.helper.quiet(@() net.linearize("Method", alg));
    ax = res.Plot();
    assert(ax.Title.String == "Eigenvalues (" + alg + ")", ax.Title.String)
    close(ancestor(ax, "figure"))
end
res = net.linearize("Method", "Kron");
ax = res.Plot("Method", "DAE");
assert(ax.Title.String == "Eigenvalues (DAE)", ax.Title.String)
close(ancestor(ax, "figure"))
% Feedback で描けない NonUnit は get_ss と同じエラー
try
    res = DebugScript.helper.quiet(@() net.linearize("Method", "Feedback", "NonUnit", [7 2]));
    res.Plot();
    error("DebugScript:NoError", "状態のある母線の NonUnit がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:v3_nonunit_dynamic:NonUnitDynamicBus", DebugScript.helper.msg_id(ME))
    close(gcf)
end


%% No message about NonUnit without the option
% IEEE68 には機器のない母線がある。指定していない NonUnit について何も表示しない
net_68 = network.IEEE68bus();
DebugScript.helper.quiet(@() net_68.initialize);
assert(any(tools.vcellfun(@(b) isempty(b.a_Component), net_68.a_Bus)))
for alg = ["Kron", "Feedback", "DAE"]
    assert(~contains(evalc('net_68.get_sys("Method", alg);'), "NonUnit"), alg)
end
res = net_68.linearize();
assert(~contains(evalc('res.get_ss("Kron");'), "NonUnit"))


%% Configurations that cannot be linearized stop with a GUILDA error
% 全母線を NonUnit にしても、状態のある母線があれば NonUnitDynamicBus
net_14 = network.IEEE14bus();
DebugScript.helper.quiet(@() net_14.initialize);
try
    net_14.get_sys("NonUnit", 1:14);
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:v3_nonunit_dynamic:NonUnitDynamicBus", DebugScript.helper.msg_id(ME))
end
% 状態のない系統は Feedback では扱えない (NonUnit の有無によらない)。Kron と DAE は使える
net_load = PowerNetwork("LoadOnly");
net_load.add_bus("V", 1);
net_load.add_bus();
net_load.add_branch("pi", [1,2], "R", 0.01, "X", 0.085);
net_load.a_Bus{1}.add_component("load-impedance", "P", -0.5, "Q", -0.1);
net_load.a_Bus{2}.add_component("load-impedance", "P", -0.5, "Q", -0.1);
DebugScript.helper.quiet(@() net_load.initialize);
for c_arg = {{}, {"NonUnit", 1:2}}
    try
        net_load.get_sys(c_arg{1}{:});
        error("DebugScript:NoError", "エラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultLIN:NoUnitBus", DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, "Kron") && contains(ME.message, "DAE"), ME.message)
    end
end
assert(isempty(net_load.get_sys("Method", "Kron").A))
assert(size(net_load.get_sys("Method", "DAE").A, 1) == 4)
% 出力のない機器の AGC は追加で止まる。追加前に get_sys しても同じ原因を示す
net_droop = DebugScript.helper.build_3bus("gen-droop");
gen_droop = net_droop.a_Bus{2}.a_Component{1};
agc = controller.agc.broadcast_PI_AGC(net_droop, "agc", gen_droop);
try
    net_droop.add_global_controller("agc-PI", gen_droop);
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:GconPorts", DebugScript.helper.msg_id(ME))
end
try
    agc.get_sys(0, zeros(2,1), zeros(2,1), 0);
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:GlobalController:GlobalControllerPort", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, gen_droop.s_tag) && contains(ME.message, "omega"), ME.message)
end


%% Coordinate is an option of linearize and get_sys
% Coordinate は GUILDA.setting の Linearization の設定で、呼び出しごとに上書きできる。既定は変わらない
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
assert(GUILDA.config("Linearization", "Coordinate") == "theta&rho")
sD0 = net.get_sys(Method="DAE");
assert(any(string(sD0.StateName) == "rho1"))
sD = net.get_sys(Method="DAE", Coordinate="theta&V");
assert(any(string(sD.StateName) == "V1") && GUILDA.config("Linearization", "Coordinate") == "theta&rho")
assert(isequal(net.get_sys(Method="DAE", Coordinate="theta&V", Format="ss"), net.linearize(Coordinate="theta&V").get_ss("DAE")))
assert(isequal(net.get_sys(Method="DAE", Format="struct"), net.linearize(Coordinate="theta&V").get_ss("DAE", Coordinate="theta&rho", Format="struct")))
c_cfg = DebugScript.helper.user_config("Linearization", struct("Coordinate", "Vre&Vim"));
assert(any(string(net.get_sys(Method="DAE").StateName) == "Vre1"))
clear c_cfg
try
    net.get_sys(Coordinate="polar");
    error("DebugScript:NoError", "不正な Coordinate がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) ~= "DebugScript:NoError", DebugScript.helper.msg_id(ME))
end


%% Default channels of get_sys do not change
% Input, Output を与えなければ v3 互換の既定のまま。Kron の出力名は空
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
res = net.linearize();
sK = net.get_sys(Method="Kron");
assert(all(sK.OutputName == "") && numel(sK.OutputName) == size(sK.A,1) && isequal(sK.C, eye(size(sK.A,1))))
for alg = ["Kron","Feedback","DAE"]
    assert(isequal(net.get_sys(Method=alg, Format="ss"), res.get_ss(alg)), alg)
    assert(isequal(net.get_sys(Method=alg, Format="struct"), res.get_ss(alg, Format="struct")), alg)
end


%% Output and Input select the channels
% 3 方式の V, I, y の伝達関数が一致する (global controller, 制御器, 非ユニット母線の負荷あり)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["SG1B001", "SG1B002"]);
DebugScript.helper.quiet(@() net.initialize);
res = net.linearize();
tab = res.tab_variable;
sv_v = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
sK = res.get_ss("Kron", Output=["V","I","y"]);
s0 = 0.3 + 1i;
GK = freqresp(sK, s0);
for s = {res.get_ss("Feedback", Output=["V","I","y"]), ...
         res.get_ss("DAE", Output=["V","I","y"]), ...
         res.get_ss("DAE", Output=["V","I","y"], Coordinate="theta&V"), ...
         res.get_ss("DAE", Output=["V","I","y"], Coordinate="Vre&Vim")}
    assert(isequal(s{1}.OutputName, sK.OutputName) && isequal(s{1}.InputName, sK.InputName))
    assert(norm(freqresp(s{1}, s0) - GK) < 1e-8 * norm(GK))
end
n_b = numel(net.a_Bus);
sv_out = string(sK.OutputName);
assert(isequal(sv_out(1:2*n_b), sv_v) && numel(unique(sv_out)) == numel(sv_out))
assert(startsWith(sv_out(2*n_b+1), "Ire") && startsWith(sv_out(2*n_b+2), "Iim"))

% V は電圧を消去した式と同じ。I は機器の注入電流 (-Avx x + (Y - Avv) v - Bv u) と同じ
n_v = 2*n_b;
sV = res.get_ss("Kron", Output="V");
[~, ix] = ismember(string(sV.StateName), tab.Label(tab.Kind == "x"));
assert(norm(sV.C + res.rm_Avv \ res.rm_Avx(:,ix), 1) < 1e-10 && norm(sV.D + res.rm_Avv \ res.rm_Bv, 1) < 1e-10)
sI = res.get_ss("Kron", Output="I");
rm_Y = tools.complex2matrix(net.get_admittance_matrix.Variables);
assert(norm(sI.C - (-res.rm_Avx(:,ix) + (rm_Y - res.rm_Avv)*sV.C), 1) < 1e-8)
assert(norm(sI.D - (-res.rm_Bv + (rm_Y - res.rm_Avv)*sV.D), 1) < 1e-8)

% y: 状態と同名の出力は Y_ 付きで、状態そのもの。AVR の出力 Vfield は状態 Vap
gen = net.a_Bus{1}.a_Component{1};
avr = gen.a_LocalController{1};
s_y = string(gen.attach_tag("Y_omega"));
sy = res.get_ss("Kron", Output=[s_y, string(avr.attach_tag("Vfield"))]);
assert(isequal(string(sy.OutputName), [s_y; string(avr.attach_tag("Vfield"))]))
assert(isequal(sy.C(1,:), double(string(sy.StateName) == string(gen.attach_tag("omega")))'))
assert(isequal(sy.C(2,:), double(string(sy.StateName) == string(avr.attach_tag("Vap")))'))
assert(all(sy.D == 0, "all"))

% 種類と名前の混在は指定の順で、重複は 1 つ。x はモデルのすべての状態を StateName の順に出す
s_w = string(gen.attach_tag("omega"));
sM = net.get_sys(Method="Kron", output=[sv_v(3), s_w, sv_v(3)]);
assert(isequal(string(sM.OutputName), [sv_v(3); s_w]))
for alg = ["Kron","Feedback","DAE"]
    sys_def = res.get_ss(alg);
    sys_x = res.get_ss(alg, Output="x");
    assert(isequal(sys_x.A, sys_def.A) && isequal(sys_x.E, sys_def.E) && isequal(sys_x.B, sys_def.B) && all(sys_x.D == 0, "all"), alg)
    sv_state = string(sys_x.StateName);
    assert(isequal(string(sys_x.OutputName), sv_state(ismember(sv_state, tab.Label(tab.Kind == "x")))), alg)
    assert(isequal(sys_x.C, eye(size(sys_x.C,1), size(sys_x.A,1))), alg)
end
% Feedback の既定の出力は v3 と同じで、global controller の状態を含まない。消えた Vst の行を持つ
sys_def = res.get_ss("Feedback");
assert(~any(string(sys_def.OutputName) == string(net.a_GlobalController{1}.attach_tag("xi"))))

% Input: 指定の順。状態は変わらない。Output と併用できる。列ベクトルも受ける
sv_u = tab.Label(tab.Kind == "u");
for alg = ["Kron","Feedback","DAE"]
    sys_all = net.get_sys(Method=alg, Output="V");
    sys_sel = net.get_sys(Method=alg, Output="V", Input=sv_u([3;1]));
    assert(isequal(string(sys_sel.InputName), sv_u([3;1])), alg)
    assert(isequal(sys_sel.A, sys_all.A) && isequal(sys_sel.StateName, sys_all.StateName), alg)
    [~, iu] = ismember(sv_u([3;1]), string(sys_all.InputName));
    assert(isequal(sys_sel.D, sys_all.D(:,iu)) && isequal(sys_sel.B, sys_all.B(:,iu)), alg)
    assert(isequal(net.get_sys(Method=alg, Input="u").InputName, net.get_sys(Method=alg).InputName), alg)
end

% 不明な名前。net.linearize は Input, Output を受けない
for c = {{"Output","nope","UnknownOutput"}, {"Input","nope","UnknownInput"}, {"Input","V","UnknownInput"}}
    try
        net.get_sys("Method", "Kron", c{1}{1:2});
        error("DebugScript:NoError", "不明な名前がエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultLIN:" + c{1}{3}, DebugScript.helper.msg_id(ME))
    end
end
try
    net.linearize(Output="V");
    error("DebugScript:NoError", "linearize が Output を受けた")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:resolve_options:UnknownName", DebugScript.helper.msg_id(ME))
end


%% Feedback cannot output a state it removes
% connect が消す状態は名前で指定するとエラー。Kron なら取れる。消える状態は V, I, y に効かない
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
res = net.linearize();
sv_x  = res.tab_variable.Label(res.tab_variable.Kind == "x");
sv_gone = setdiff(sv_x, string(res.get_ss("Feedback").StateName));
assert(~isempty(sv_gone))
try
    res.get_ss("Feedback", Output=sv_gone(1));
    error("DebugScript:NoError", "消えた状態がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultLIN:StateNotInModel", DebugScript.helper.msg_id(ME))
end
assert(string(res.get_ss("Kron", Output=sv_gone(1)).OutputName) == sv_gone(1))
sK = res.get_ss("Kron", Output=["V","I","y"]);
assert(all(sK.C(:, ismember(string(sK.StateName), sv_gone)) == 0, "all"))


%% Canonical linearization demo runs
% 正規デモ +DebugScript/Task_linearization.m が最後まで動く (run_all は test_F*, test_I* だけを読むのでここから呼ぶ)
DebugScript.helper.quiet(@() run_task_linearization());


%% Hessian is not supported by default
% Hessian は機器・制御器のクラスごとの任意の解析。定義していないクラスはクラス名を示すエラー
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.add_global_controller("agc-PI", "SG1B001");
DebugScript.helper.quiet(@() net.initialize);
obj = {net.a_Bus{1}.a_Component{1}, net.a_Bus{1}.a_Component{1}.a_LocalController{1}, net.a_GlobalController{1}};
sr_id = ["GUILDA:Component:HessianNotSupported", "GUILDA:LocalController:HessianNotSupported", "GUILDA:GlobalController:HessianNotSupported"];
for k = 1:numel(obj)
    try
        obj{k}.get_hessian();
        error("DebugScript:NoError", class(obj{k}) + ".get_hessian がエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == sr_id(k), DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, class(obj{k})) && contains(ME.message, "does not support Hessian"))
    end
end


%% Hessian contract of a class that overrides it
% Hessian_dx を定義したクラスは n_x x n_z x n_z (z = [x; V; I; u]) を返す。Hessian_I が無ければ H_I は要求したときだけエラー
c = DebugScript.helper.HessianStub();
x = [0.3; 0.7];  V = [1.01; 0.05];  I = [0.2; -0.1];  u = 0.4;
H = c.get_hessian(x, V, I, u);
assert(isequal(size(H), [2 7 7]))
assert(H(1,1,1) == 2*V(1) && H(1,1,3) == 2*x(1) && H(1,3,1) == 2*x(1) && H(2,1,7) == 1 && H(2,7,1) == 1)
assert(nnz(H) == 5)
% H(k,:,:) は対称
for k = 1:2
    Hk = squeeze(H(k,:,:));
    assert(isequal(Hk, Hk.'))
end
try
    [~, ~] = c.get_hessian(x, V, I, u);
    error("DebugScript:NoError", "Hessian_I が無いのにエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:HessianNotSupported" && contains(ME.message, "Hessian_I"), DebugScript.helper.msg_id(ME))
end


%% Format ss and the LQR controllers stop without Control System Toolbox
% Toolbox が無い環境を license の代わりで再現する。ResultLIN と struct はそのまま使える
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
s_tmp = tempname;  mkdir(s_tmp);
writelines(["function varargout = license(varargin)", ...
    "if nargin >= 2 && strcmpi(varargin{1}, 'test') && strcmpi(varargin{2}, 'Control_Toolbox')", ...
    "    varargout = {false};  return", "end", ...
    "[varargout{1:max(nargout,1)}] = builtin('license', varargin{:});", "end"], ...
    fullfile(s_tmp, "license.m"));
w = warning("off", "MATLAB:dispatcher:nameConflict");
addpath(s_tmp);
c_tmp = onCleanup(@() cellfun(@feval, {@() rmpath(s_tmp), @() rmdir(s_tmp, "s"), ...
    @() clear("license"), @() warning(w)}));
assert(~license("test", "Control_Toolbox"))
res = net.linearize();
assert(isa(net.get_sys(), "ResultLIN") && ~isempty(res.A))
sct = res.get_ss(res.options.Method, Format="struct");
assert(isequal(sct.A, res.A))
c_call = {@() res.get_ss("Kron"), @() net.get_sys(Format="ss"), ...
    @() net.a_Bus{1}.a_Component{1}.get_sys(Format="ss"), ...
    @() controller.local_LQR("1"), ...
    @() controller.modeling.get_environment(net, 1)};
sv_feature = ["ResultLIN.get_ss", "ResultLIN.get_ss", "ResultLIN.get_ss", ...
    "controller.local_LQR", "controller.modeling.get_environment"];
% controller.local_LQR_retrofit は v2 の抽象メソッドを実装していないため生成できず、ここでは確認しない
for k = 1:numel(c_call)
    try
        c_call{k}();
        error("DebugScript:NoError", "エラーにならない: %s", sv_feature(k))
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:require_toolbox:Unavailable", ME.message)
        assert(contains(ME.message, "Control System Toolbox") && contains(ME.message, sv_feature(k)), ME.message)
    end
end
clear c_tmp


% ローカル関数
function run_task_linearization()
% スクリプトの変数がテストの変数と混ざらないように関数の中で実行する
    DebugScript.Task_linearization
end


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
