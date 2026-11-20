% F7 近似線形化 (get_sys / SolverLIN / ResultLIN / get_variable_map)
%
% 平衡点 (または指定した点) まわりの線形モデルを求める。
%   res = net.get_sys(点, "Type", ...);   % ResultLIN (どの層も同じ get_sys)
%   sys = res.get_ss("ODE" | "DAE");               % ss (Format="struct" で構造体)
%   res = net.get_sys("Output", ["V","I","y"], "Input", 入力名);   % 入出力の選択 (既定は不変)
%   tab = net.get_variable_map();                 % 変数の順 (res.rm_Axx などの行と列)
% モデルは記述子形式 (E dx = A x + B u)。ResultLIN の A, B, C, D, E と名前、構造体、ss のどれでも同じ。
% 2 方式の有限固有値が一致すること、IEEE14 の平衡点が安定であること、v3 の行列と同じであること、
% 接続器に置き換える前の線形モデル (基準値) と一致すること、
% 点 (平衡点 / ベクトル / {シミュレーション結果, 時刻}) を確認する (エネルギー関数のヘッセ行列は F83)。
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

%% Get sys ODE
sys = net.get_sys("Type", "ODE");
assert(isa(sys, "ResultLIN"))
assert(size(sys.A,1) == n_x)
assert(numel(sys.StateName) == size(sys.A,1))


%% Get sys default
% 既定の方式は GUILDA.setting の ODE
sys = net.get_sys();
assert(isa(sys, "ResultLIN") && sys.options.Type == "ODE")
assert(size(sys.A,1) == n_x)


%% Get sys DAE
% DAE 方式は母線電圧・電流などの代数変数も状態に含む (E が特異)
sys = net.get_sys("Type", "DAE");
assert(isa(sys, "ResultLIN"))
assert(size(sys.A,1) > n_x)
assert(rank(sys.E) < size(sys.E,1))


%% Model shape and names per algorithm
% 固有値では分からない形を等式で確認する。n_x, n_v, n_u は変数の表の数
n1 = new_net();
n1.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
n1.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
n1.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]);
c_net = {new_net(), n1, network.Tutorial10bus(), network.IEEE9bus()};
for k = 1:numel(c_net)
    DebugScript.helper.quiet(@() c_net{k}.initialize);
    res = c_net{k}.get_sys();
    tab = res.tab_variable;
    sv_x = tab.Label(tab.Kind == "x");
    sv_u = tab.Label(tab.Kind == "u");
    nx = numel(sv_x);  nv = 2*numel(c_net{k}.a_Bus);  nu = numel(sv_u);
    n_mass = nnz(diag(res.rm_E));
    sK = DebugScript.helper.quiet(@() res.get_ss("ODE"));
    sD = DebugScript.helper.quiet(@() res.get_ss("DAE"));

    assert(isequal(size(sK.A), [nx nx]) && isequal(size(sK.B), [nx nu]) && isequal(sK.C, eye(nx)), "net %d: ODE", k)
    assert(isequal(sort(string(sK.StateName)), sort(sv_x)), "net %d: ODE の状態", k)
    assert(isequal(size(sD.A), [nx+nv nx+nv]) && isequal(size(sD.B), [nx+nv nu]) && isequal(size(sD.C), [nx nx+nv]), "net %d: DAE", k)
    assert(all(ismember(sv_x, string(sD.StateName))) && numel(unique(string(sD.StateName))) == nx+nv, "net %d: DAE の状態", k)

    assert(rank(sK.E) == n_mass && rank(sD.E) == n_mass, "net %d: E の階数", k)
    for s = {sK, sD}
        assert(isequal(string(s{1}.InputName), sv_u), "net %d: 入力の名前と順", k)
        assert(numel(s{1}.StateName) == size(s{1}.A,1) && numel(s{1}.OutputName) == size(s{1}.C,1), "net %d: 名前の数", k)
    end
end


%% Two algorithms give same eigenvalues
e_ode = eig_finite(net.get_sys("Type", "ODE"));
e_dae  = eig_finite(net.get_sys("Type", "DAE"));
assert(same_eigs(e_ode, e_dae, 1e-6), "ODE と DAE の固有値が一致しない")


%% Feedback is not a method
% Feedback は廃止。Type の検証のエラーになる
for f = {@() net.get_sys(Type="Feedback"), @() net.get_sys().get_ss("Feedback"), @() net.get_sys().plot_eigenvalue(Type="Feedback")}
    try
        f{1}();
        error("DebugScript:NoError", "Feedback がエラーにならない")
    catch ME
        assert(ME.identifier ~= "DebugScript:NoError" && contains(ME.message, "ODE"), ME.message)
    end
end
assert(isequal(GUILDA.config("ApproximateLinearization").Type.options(:)', ["ODE","DAE"]) || isequal(string(GUILDA.config("ApproximateLinearization").Type.options(:))', ["ODE","DAE"]))


%% IEEE14 equilibrium is stable
% 回転不変性による 0 固有値を除き、すべての固有値の実部が負
e = eig_finite(net.get_sys("Type", "ODE"));
assert(max(real(e)) < 1e-6, "不安定な固有値がある: " + max(real(e)))
assert(sum(abs(e) < 1e-6) <= 1)


%% ODE keeps the inputs of a zero-power load bus
% B007 は P=Q=0 の負荷。ODE はネットワークと一緒に電圧を消去し、入力は残す (旧 Task9)
res = net.get_sys();
sys_k = res.get_ss("ODE");
sv_u = res.tab_variable.Label(res.tab_variable.Kind == "u" & res.tab_variable.Bus == "B007");
assert(~isempty(sv_u) && all(ismember(sv_u, sys_k.InputName)))


%% Removed options of v3 stop with the validation error
% COMPAT(v3) の Algorithm と NonUnit は削除: arguments ブロックの検証のエラー
for f = {@() net.get_sys("Algorithm", "ODE"), @() net.get_sys("NonUnit", 7)}
    try
        f{1}();
        error("DebugScript:NoError", "削除したオプションがエラーにならない")
    catch ME
        assert(ME.identifier ~= "DebugScript:NoError", ME.message)
    end
end
assert(~isprop(net.solver_LIN, "NonUnit") && ~isprop(net.solver_LIN, "Algorithm"))
assert(~ismethod(net, "linearize"))


%% Zero-power loads keep their inputs
% P=Q=0 の負荷 (IEEE14 の B007) の入力も残る
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
res = n14.get_sys();
sys_k = res.get_ss("ODE");
assert(isequal(sys_k.InputName, res.tab_variable.Label(res.tab_variable.Kind == "u")))
load7 = n14.a_Bus{7}.a_Component{1};
assert(all(ismember(string(load7.attach_tag(load7.sv_u)), string(sys_k.InputName))))


%% Bus without components
% 機器の無い母線 (build_9bus の B004, B007, B009) があっても変数マップ・線形化ができる
n9 = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() n9.initialize);
assert(iscell(n9.a_Bus{4}.a_Component) && isempty(n9.a_Bus{4}.a_Component))
tab = n9.a_Bus{4}.get_variable_map();
assert(isequal(tab.Kind, ["Vre";"Vim"]))
tab = n9.get_variable_map();
assert(nnz(tab.Bus == string(n9.a_Bus{4}.s_tag)) == 2)
res = DebugScript.helper.quiet(@() n9.get_sys);
assert(isa(res, "ResultLIN"))
n_x9 = sum(cellfun(@(b) sum(cellfun(@(c) numel(c.sv_x), b.a_Component)), n9.a_Bus));
e_ode = eig_finite(n9.get_sys("Type", "ODE"));
assert(size(n9.get_sys("Type", "ODE").A, 1) == n_x9)
assert(same_eigs(e_ode, eig_finite(n9.get_sys("Type", "DAE")), 1e-6))


%% Bus models with a zero D
% 機器の無い母線 (build_9bus の B004) と P=Q=0 の負荷 (IEEE14 の B007) も V2I のモデルを返し、網の線形化も動く
n9 = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() n9.initialize);
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
bus = n14.a_Bus{7};
assert(numel(bus.a_Component) == 1 && norm(bus.get_sys().D(1:2,1:2)) == 0)
assert(isa(n9.a_Bus{4}.get_sys(), "ResultLIN") && isa(n9.a_Bus{4}.get_sys(Format="ss"), "ss"))
assert(same_eigs(eig_finite(n14.get_sys("Type", "DAE")), eig_finite(n14.get_sys("Type", "ODE")), 1e-6))


%% With local controllers
% AVR/PSS を付けると制御器の状態が加わる (旧 Task15)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Type", "ODE");
assert(size(sys.A,1) == n_x + 3 + 3)
assert(max(real(eig_finite(sys))) < 1e-6)


%% With global controller
net = new_net();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Type", "ODE");
assert(size(sys.A,1) == n_x + 1)
assert(same_eigs(eig_finite(sys), eig_finite(net.get_sys("Type", "DAE")), 1e-6))
% グローバル制御器の状態: ODE / DAE は先頭 (v3 と同じ。get_ss の help)
res = net.get_sys();
sv_K = string(res.get_ss("ODE").StateName);
sv_D = string(res.get_ss("DAE").StateName);
n_gc = numel(net.a_GlobalController{1}.sv_x);
assert(all(contains(sv_K(1:n_gc), net.a_GlobalController{1}.s_tag)), strjoin(sv_K(1:n_gc), ","))
assert(isequal(sv_D(1:n_gc), sv_K(1:n_gc)))


%% SolverLIN takes no arguments
% v3 の SolverLIN(net, NonUnit, ...) は削除: 引数は MATLAB の引数の数のエラー
assert(error_id(@() SolverLIN(net)) == "MATLAB:TooManyInputs", error_id(@() SolverLIN(net)))
assert(isa(SolverLIN(), "SolverLIN"))
assert(isa(net.solver_LIN, "SolverLIN"))


%% Variable maps of the controllers and the Equilibrium column
% 制御器の変数表は親の表の行 (x, 全 V / 母線の V, uc, yc) と同じ列・ラベル。Equilibrium は線形化の平衡点
net = network.IEEE9bus();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
agc = net.add_global_controller("agc-PI", {gen, net.a_Bus{2}.a_Component{1}}, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
assert(all(isnan(agc.get_variable_map().Equilibrium)) && all(isnan(avr.get_variable_map().Equilibrium)))
assert(all(isnan(net.get_variable_map().Equilibrium)))   % 初期化前は列全体が NaN
DebugScript.helper.quiet(@() net.initialize);
tab_net = net.get_variable_map();
assert(all(isfinite(tab_net.Equilibrium)))
assert(isequal(tab_net.Equilibrium(tab_net.Kind == "x"), net.rv_Xequilibrium))
assert(isequal(tab_net.Equilibrium(tab_net.Kind == "Vre") + 1j*tab_net.Equilibrium(tab_net.Kind == "Vim"), net.cv_Vequilibrium))
c_con = {avr, pss, agc};
c_parent = {gen.get_variable_map(), gen.get_variable_map(), tab_net};
for k = 1:numel(c_con)
    con = c_con{k};
    tab = con.get_variable_map();
    tp  = c_parent{k};
    s   = string(con.s_tag);
    iv  = [find(tp.Owner == s & tp.Kind == "x"); find(tp.Kind == "Vre" | tp.Kind == "Vim"); ...
           find(tp.Owner == s & tp.Kind == "uc"); find(tp.Owner == s & tp.Kind == "yc")];
    tq  = tp(iv,:);
    tq.Index = (1:height(tq))';
    assert(isequal(tab, tq), "%s: 親の表の行と違う", s)
    res = con.get_sys();
    assert(isequal(res.rv_point, tab.Equilibrium(tab.Role == "variable")) && isequal(res.tab_variable, tab(tab.Role == "variable",:)))
    assert(isequal(con.get_sys(tab.Equilibrium(tab.Role == "variable")).A, res.A))
end
% 機器・母線・網の Equilibrium の先頭行は get_sys の平衡点
for o = {gen, net.a_Bus{1}, net}
    tab = o{1}.get_variable_map();
    res = o{1}.get_sys();
    assert(isequal(res.rv_point, tab.Equilibrium(1:numel(res.rv_point))))
end
% 出力の Equilibrium は出力関数の平衡点での値
tab = gen.get_variable_map();
V = [real(gen.c_Vequilibrium); imag(gen.c_Vequilibrium)];
assert(isequal(tab.Equilibrium(tab.Kind == "y"), reshape(gen.f_Y(0, gen.rv_Xequilibrium, V), [], 1)))
assert(isequal(tab.Equilibrium(tab.Kind == "yc" & tab.Owner == string(avr.s_tag)), ...
       reshape(avr.f_Y(0, avr.rv_Xequilibrium, V, avr.rv_Uequilibrium), [], 1)))
% 内部の rows 形式は Equilibrium を持たない (中身は変わらない)
c_rows = net.get_variable_map("rows");
assert(iscell(c_rows) && all(cellfun(@(m) size(m,2), c_rows) == 5))


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


%% Each component type gives same eigenvalues in two algorithms
% 3 母線系統で機器の種類ごとに get_sys を求める (B001: gen-park, B002 または B003: 指定した機器)
for key = DebugScript.helper.model_classes("Component").Key'
    [net3, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net3.initialize);
    sys = net3.get_sys("Type", "ODE");
    n_x3 = sum(cellfun(@(b) sum(cellfun(@(cc) numel(cc.sv_x), b.a_Component)), net3.a_Bus));
    assert(size(sys.A,1) == n_x3, key)
    e = eig_finite(sys);
    assert(same_eigs(e, eig_finite(net3.get_sys("Type", "DAE")),      1e-6), key + ": ODE と DAE の固有値が一致しない")
end


%% Local and global controllers in two algorithms
% AVR (ST1, DC1)・PSS・AGC を付けたときも 2 方式の固有値が一致し、IEEE14 は安定
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller("agc-PI", c, parameter=struct(alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Type", "ODE");
assert(size(sys.A,1) == n_x + 3 + 3 + 4 + 1)
e = eig_finite(sys);
assert(max(real(e)) < 1e-6)
assert(same_eigs(e, eig_finite(net.get_sys("Type", "DAE")),      1e-6))
sys = net.get_sys("Type", "DAE");
assert(numel(sys.StateName) == size(sys.A,1))


%% Two global controllers in two algorithms
% グローバル制御器が複数でも 2 方式の固有値が一致し、状態は制御器の数だけ増える
net = new_net();
net.add_global_controller("agc-PI", "B001SG1");
net.add_global_controller("agc-PI", ["B002SG1", "B003SG1"], parameter=struct(kI=200));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Type", "ODE");
assert(size(sys.A,1) == n_x + 2)
sv_x = string(sys.StateName);
assert(numel(sv_x) == size(sys.A,1) && any(contains(sv_x,net.a_GlobalController{1}.s_tag)) && any(contains(sv_x,net.a_GlobalController{2}.s_tag)))
e = eig_finite(sys);
assert(max(real(e)) < 1e-6)
assert(same_eigs(e, eig_finite(net.get_sys("Type", "DAE")),      1e-6))

% 制御対象を系統の順と逆に並べても同じ系になる (端子は名前で対応付ける)
netA = new_net();
netA.add_global_controller("agc-PI", ["B001SG1", "B002SG1"], parameter=struct(alpha=[2;1], beta=[1;3]));
netB = new_net();
netB.add_global_controller("agc-PI", ["B002SG1", "B001SG1"], parameter=struct(alpha=[1;2], beta=[3;1]));
DebugScript.helper.quiet(@() netA.initialize);
DebugScript.helper.quiet(@() netB.initialize);
eA = eig_finite(netA.get_sys("Type", "DAE"));
for alg = ["ODE","DAE"]
    assert(same_eigs(eA, eig_finite(netB.get_sys("Type", alg)), 1e-6), alg + ": 制御対象の順で固有値が変わる")
end
assert(same_eigs(eA, eig_finite(netA.get_sys("Type", "ODE")), 1e-6))


%% Inputs, states and outputs of get_sys on each layer
% 名前は変数表の Label。並びは変数表の順
% 制御器: 入力 [母線の V; uc]、状態 x、出力 yc
% 機器  : 入力 [母線の V; u; uc]、状態 [x; 制御器の x]、出力 [I (機器のタグ); y; yc]
% 母線  : 入力 [V; 全機器の u; 全制御器の uc]、状態、出力 [I (母線のタグ); 全 y; 全 yc]
% 状態は出力に含めず、状態と同名の出力は "Y_" + 名前にして、すべての名前を一意にする
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
tg = @(o, s) reshape(string(o.attach_tag(s)), [], 1);
bus = net.a_Bus{1};
sv_V = tg(bus, ["Vre";"Vim"]);

sa = avr.get_sys();
assert(isequal(string(sa.InputName), [sv_V; tg(avr, avr.sv_u)]))
assert(isequal(string(sa.StateName), tg(avr, avr.sv_x)) && isequal(string(sa.OutputName), tg(avr, avr.sv_y)))

sc = gen.get_sys();
gov = gen.governor;    % 既定の Static の調速機: 状態はなく、入力 Pmech_ref と出力 Pmech を持つ
sv_in  = [sv_V; tg(gen, gen.sv_u); tg(avr, avr.sv_u); tg(pss, pss.sv_u); tg(gov, gov.sv_u)];
sv_x   = [tg(gen, gen.sv_x); tg(avr, avr.sv_x); tg(pss, pss.sv_x)];
sv_out = [tg(gen, ["Ire";"Iim";"Y_omega";"Ifield"]); tg(avr, avr.sv_y); tg(pss, pss.sv_y); tg(gov, gov.sv_y)];
assert(isequal(string(sc.InputName), sv_in) && isequal(string(sc.StateName), sv_x) && isequal(string(sc.OutputName), sv_out))
sv_all = [sv_in; sv_x; sv_out];
assert(numel(unique(sv_all)) == numel(sv_all), "名前が一意でない")
tab = gen.get_variable_map();
assert(all(ismember(sv_in, tab.Label)) && all(ismember(sv_x, tab.Label)) && all(ismember(sv_out(3:end), tab.Label)))

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

% 母線は機器の入出力を並べ、電流を母線の名前にする
sb  = bus.get_sys();
assert(isequal(string(sb.InputName),  sv_in))
assert(isequal(string(sb.OutputName), [tg(bus, ["Ire";"Iim"]); sv_out(3:end)]))
assert(isequal(string(sb.StateName), sv_x) && norm(sb.C - sc.C, 1) == 0 && norm(sb.D - sc.D, 1) == 0)

% 既定の Static の制御器だけの機器も出力に状態を含めない (Static の出力 Vfield, Pmech が続く)
g3 = net.a_Bus{3}.a_Component{1};
c3 = g3.get_sys();
assert(isequal(string(c3.OutputName), [tg(g3, ["Ire";"Iim";"Y_omega";"Ifield"]); tg(g3.avr, "Vfield"); tg(g3.governor, "Pmech")]))

% 母線の入出力の並びは変数表の順 (機器ごとではない)
n2 = network.IEEE9bus();
n2.a_Bus{1}.add_component("load-impedance", "P", -0.1, "Q", 0);
n2.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() n2.initialize);
sb = n2.a_Bus{1}.get_sys();
tab = n2.a_Bus{1}.get_variable_map();
assert(isequal(string(sb.InputName), [tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim"); tab.Label(tab.Kind == "u"); tab.Label(tab.Kind == "uc")]))
assert(isequal(string(sb.OutputName(3:end)), [tab.Label(tab.Kind == "y"); tab.Label(tab.Kind == "yc")]))


%% Index a model of each layer by full channel name
% Format="ss" のモデルでは sys(出力名, 入力名) は sys(行, 列) と同じ。同名のグループがあると曖昧でエラーになる (Issue #79)
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
c_sys = {avr.get_sys(Format="ss"), pss.get_sys(Format="ss"), gen.get_sys(Format="ss"), ...
         net.a_Bus{3}.a_Component{1}.get_sys(Format="ss"), net.a_Bus{1}.get_sys(Format="ss")};
for k = 1:numel(c_sys)
    s = c_sys{k};
    for iy = 1:numel(s.OutputName)
        for iu = 1:numel(s.InputName)
            s1 = s(s.OutputName{iy}, s.InputName{iu});
            assert(isequal(s1.D, s.D(iy,iu)) && isequal(s1.C, s.C(iy,:)) && isequal(s1.B, s.B(:,iu)), "model %d: %s, %s", k, s.OutputName{iy}, s.InputName{iu})
        end
    end
end


%% Layer get_sys: removed arguments, one signature and single computation (#83, #121)
net = network.IEEE9bus();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
agc = net.add_global_controller("agc-PI", {gen, net.a_Bus{2}.a_Component{1}}, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);

% tag, Controllers, full, con, rec, controllerPorts はどの層の get_sys の引数でもない
c_obj = {gen, net.a_Bus{1}, avr, agc, net};
for s_arg = ["tag","Controllers","full","con","rec","controllerPorts"]
    for k = 1:numel(c_obj)
        l_accepted = true;
        try
            c_obj{k}.get_sys(s_arg,false);
        catch
            l_accepted = false;
        end
        assert(~l_accepted, "%s が %s で受け付けられた", s_arg, class(c_obj{k}))
    end
end
assert(~ismember("get_sys_alone", methods(gen)) && ~ismember("get_sys_alone", methods(avr)))
% Port の値は PI, PQ, I だけ (以前の "V2I" は受け付けない)。Type と Port は網のモデルの選択で、ほかの層では効かない
for k = 1:numel(c_obj)
    assert(startsWith(error_id(@() c_obj{k}.get_sys("Port", "V2I")), "MATLAB:"), class(c_obj{k}))
end
assert(isequal(gen.get_sys(Type="DAE").A, gen.get_sys().A))
assert(isequal(gen.get_sys(Port="PI").A, gen.get_sys().A))
% 枝には線形モデルがない
assert(error_id(@() net.a_Branch{1}.get_sys()) == "GUILDA:PowerSystemModel:NoLinearModel")

% どの層も出力は [sys, flag, output] で、output.s_layer は層の種類
c_call = {@() gen.get_sys(), @() net.a_Bus{1}.get_sys(), ...
          @() avr.get_sys(), @() agc.get_sys(), @() net.get_sys()};
sv_layer = ["Component","Bus","LocalController","GlobalController","PowerNetwork"];
for k = 1:numel(c_call)
    [s, flag, output] = c_call{k}();
    assert(isa(s, "ResultLIN") && flag && output.s_layer == sv_layer(k) && output.result == s, "call %d", k)
    assert(numel(s.StateName) == size(s.A,1) && numel(s.InputName) == size(s.B,2) && numel(s.OutputName) == size(s.C,1), "call %d: names", k)
end

% 制御器のブロックは 1 回の gen.get_sys() で 1 個につき 1 回だけ計算する
profile("on");
gen.get_sys();
profile("off");
tab = struct2table(profile("info").FunctionTable);
lv  = contains(string(tab.FileName), "@LocalController") & endsWith(string(tab.FunctionName), "get_linear_matrix");
assert(sum(tab.NumCalls(lv)) == 3, "制御器 3 個 (AVR, PSS, 既定の Static の調速機) に %d 回", sum(tab.NumCalls(lv)))


%% Linear block of the component alone
% get_linear_matrix: 入力は母線の V と u、状態は x、出力は [I; y] (制御器を含まない)。名前は変数表の Label
net = network.IEEE9bus();
gen = net.a_Bus{1}.a_Component{1};
gen.add_local_controller("avr-ST1");
gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
x = gen.rv_Xequilibrium;  V = [real(gen.c_Vequilibrium); imag(gen.c_Vequilibrium)];
u = gen.rv_Uequilibrium;
nx = numel(gen.sv_x);  nu = numel(gen.sv_u);  ny = numel(gen.sv_y);
[Axx, Bxv, Bxu] = gen.f_JacobiDx(0, x, V, u);
[Cix, Div, Diu] = gen.f_JacobiI(0, x, V, u);
[Cyx, Dyv]      = gen.f_JacobiY(0, x, V);
Axx = reshape(full(Axx), nx, nx);  Bxv = reshape(full(Bxv), nx, 2);  Bxu = reshape(full(Bxu), nx, nu);
Cix = reshape(full(Cix), 2, nx);   Div = reshape(full(Div), 2, 2);   Diu = reshape(full(Diu), 2, nu);
Cyx = reshape(full(Cyx), ny, nx);  Dyv = reshape(full(Dyv), ny, 2);
E   = reshape(full(gen.f_Mass(0, x, V, u)), nx, nx);

s = gen.get_linear_matrix(x, V, u);
assert(isequal(s.A, Axx) && isequal(s.B, [Bxv, Bxu]) && isequal(s.C, [Cix; Cyx]) && isequal(s.D, [Div, Diu; Dyv, zeros(ny,nu)]) && isequal(s.E, E))
tab = gen.get_variable_map();
assert(isequal(s.StateName, tab.Label(tab.Kind == "x" & tab.Owner == gen.s_tag)))
assert(isequal(s.InputName, [tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim"); tab.Label(tab.Kind == "u")]))
assert(isequal(s.OutputName, [reshape(string(gen.attach_tag(["Ire";"Iim"])), [], 1); tab.Label(tab.Kind == "y")]))

% 制御器のない機器の get_sys は、そのブロックと同じ
load1 = net.a_Bus{5}.a_Component{1};
sa = load1.get_linear_matrix(load1.rv_Xequilibrium, [real(load1.c_Vequilibrium); imag(load1.c_Vequilibrium)], load1.rv_Uequilibrium);
sb = load1.get_sys(Format="struct");
assert(isequal(sa.A, sb.A) && isequal(sa.B, sb.B) && isequal(sa.C, sb.C) && isequal(sa.D, sb.D) && isequal(sa.E, sb.E) ...
       && isequal(sa.InputName, sb.InputName) && isequal(sa.OutputName, sb.OutputName))

% 機器の ResultLIN は機器と制御器の変数を持つ
res = gen.get_sys();
assert(isa(res, "ResultLIN") && res.output.l_equilibrium)
assert(isequal(res.tab_variable, tab(1:height(res.tab_variable),:)) && isequal(res.rv_point, SolverLIN.point_vector(gen, [])))
assert(isequal(res.rm_Axx, res.A) && isequal(res.rm_Axv, res.B(:,1:2)) && isequal(res.rm_Bx, res.B(:,3:end)))   % u, then uc of its controllers


%% Linearization matches v3 get_sys matrices for every algorithm
% get_sys + get_ss の行列と名前は v3 の SolverLIN と同じ (helper.linearize_v3 に v3 のコードを保存)。
% 違いは DAE の B の代数方程式の行の符号 (v3 は入力 u の符号が逆で、ODE と伝達関数が合わなかった)。
nets = {};
nets{end+1} = new_net();
n4 = new_net();
n4.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
n4.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
n4.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
n4.add_global_controller("agc-PI", {n4.a_Bus{1}.a_Component{1}, n4.a_Bus{2}.a_Component{1}}, parameter=struct(alpha=[1;1], beta=[1;1]));
n4.add_global_controller("agc-PI", "B003SG1", parameter=struct(kI=200));
nets{end+1} = n4;
for key = ["gen-1axis","gen-droop","load-impedance"]
    nets{end+1} = DebugScript.helper.build_3bus(key); %#ok<SAGROW>
end
for k = 1:numel(nets)
    DebugScript.helper.quiet(@() nets{k}.initialize);
    res = nets{k}.get_sys();
    for alg = ["ODE","DAE"]
        sys_new = res.get_ss(alg);
        sys_old = DebugScript.helper.linearize_v3(nets{k}, [], replace(alg, "ODE", "Kron"));   % v3 の名前
        str = nets{k}.s_tag + " " + alg;
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
        % Format="ss" の net.get_sys は get_ss と同じ
        assert(isequal(nets{k}.get_sys("Type", alg, "Format", "ss"), sys_new), str + ": get_sys")
    end
end


%% DAE input matrix agrees with ODE
% DAE と ODE は入力 u から状態 x までの伝達関数が同じ (v3 の DAE は B の符号のため一致しなかった)
res = net.get_sys();
sK = res.get_ss("ODE");
for crd = ["PQ","PI","I"]
    sD = res.get_ss("DAE", "Port", crd);
    s0 = 0.3 + 1i;
    GK = freqresp(sK, s0);  GD = freqresp(sD, s0);
    assert(norm(GK - GD) < 1e-8 * norm(GK), crd)
end


%% Variable map is consistent with the linear model
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
[tab_all, c_idxAll, c_idxGCAll, tab_c] = net.get_variable_map();
% 表は変数 (x, Vre, Vim, u, uc) の後に信号 (y, yc)。線形化の点は先頭の x, Vre, Vim, u, uc
assert(isequal(string(tab_all.Properties.VariableNames), ["Index","Kind","Role","Owner","Name","Label","Bus","Equilibrium"]))
sv_kind = ["x","Vre","Vim","u","uc","y","yc"];
[~, iv_k] = ismember(tab_all.Kind, sv_kind);
iv_k(iv_k == 3) = 2;                       % Vre, Vim は母線ごとに交互
assert(all(iv_k > 0) && issorted(iv_k), "Kind の順")
assert(isequal(tab_all.Role == "signal", ismember(tab_all.Kind, ["y","yc"])))
% 接続表: 先は入力 (u, uc)、源は信号か状態。行は先の順
assert(all(ismember(tab_all.Kind(tab_c.TargetIndex), ["u","uc"])) && issorted(tab_c.TargetIndex))
assert(all(tab_c.SourceIndex(tab_c.Kind == "equilibrium") == 0))
lv_src = tab_c.Kind ~= "equilibrium";
assert(all(ismember(tab_all.Kind(tab_c.SourceIndex(lv_src)), ["x","y","yc"])))
assert(isequal(tab_c.Source(lv_src), tab_all.Label(tab_c.SourceIndex(lv_src))) && isequal(tab_c.Target, tab_all.Label(tab_c.TargetIndex)))
% AGC の出力は機器の入力 Pmech へ (Kind "global")
s_gc = net.a_GlobalController{1}.s_tag;
lv_g = tab_c.Kind == "global";
assert(nnz(lv_g) == 2 && all(tab_all.Owner(tab_c.SourceIndex(lv_g)) == s_gc) && all(tab_all.Name(tab_c.TargetIndex(lv_g)) == "Pmech"))
n_lin = sum(ismember(tab_all.Kind, ["x","Vre","Vim","u","uc"]));
tab = tab_all(1:n_lin,:);
c_idxBus = cellfun(@(iv) iv(iv <= n_lin), c_idxAll, 'UniformOutput', false);
c_idxGC  = cellfun(@(iv) iv(iv <= n_lin), c_idxGCAll, 'UniformOutput', false);
res = net.get_sys();
assert(isequal(res.tab_variable, tab))
assert(isequal(tab.Index, (1:height(tab))'))
n_x = size(res.rm_Axx,1);  n_v = size(res.rm_Avv,1);  n_u = size(res.rm_Bx,2);
assert(sum(tab.Kind == "x") == n_x && sum(tab.Kind == "Vre" | tab.Kind == "Vim") == n_v && sum(tab.Kind == "u") == n_u)
n_uc = nnz(tab_all.Kind == "uc");
assert(n_uc > 0 && isequal(tab.Kind, [repmat("x",n_x,1); repmat(["Vre";"Vim"],n_v/2,1); repmat("u",n_u,1); repmat("uc",n_uc,1)]))
assert(n_v == 2*numel(net.a_Bus) && numel(res.rv_point) == height(tab))
assert(isequal(size(res.rm_Axv), [n_x n_v]) && isequal(size(res.rm_Avx), [n_v n_x]) && isequal(size(res.rm_Bv), [n_v n_u]) && isequal(size(res.rm_E), [n_x n_x]))
% 状態と入力の名前は get_ss の StateName / InputName と同じもの (グローバル制御器の状態は get_ss("ODE") では先頭)
sK = res.get_ss("ODE");
assert(isequal(sort(tab.Label(tab.Kind == "x")), sort(string(sK.StateName))))
assert(isequal(tab.Label(tab.Kind == "u"), string(sK.InputName)))
assert(any(tab.Owner == s_gc) && all(tab.Bus(tab.Owner == s_gc) == "") && isequal(tab.Label(c_idxGC{1}), tab.Label(tab.Owner == s_gc)))
% 制御器の状態は機器の直後 (AVR, その下の PSS の順)
iv = find(tab.Bus == "B001" & tab.Kind == "x");
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(isequal(tab.Owner(iv), [repmat("B001SG1",numel(net.a_Bus{1}.a_Component{1}.sv_x),1); ...
                               repmat(avr.s_tag,numel(avr.sv_x),1); repmat(avr.a_LocalController{1}.s_tag,numel(avr.a_LocalController{1}.sv_x),1)]))
% 母線・機器の変数の表は系統の表の該当行と同じ順
for i = 1:numel(net.a_Bus)
    [tab_b, c_idxC] = net.a_Bus{i}.get_variable_map();
    assert(isequal(tab_b(:,2:end), tab_all(c_idxAll{i},2:end)), "bus " + i)
    for j = 1:numel(c_idxC)
        tab_c = net.a_Bus{i}.a_Component{j}.get_variable_map();
        assert(isequal(tab_c(:,2:end), tab_b(c_idxC{j},2:end)), "bus " + i + " comp " + j)
    end
end
% 平衡点の値: 機器の平衡点と母線電圧
gen = net.a_Bus{1}.a_Component{1};
assert(isequal(res.rv_point(tab.Owner == "B001SG1" & tab.Kind == "x"), gen.rv_Xequilibrium))
assert(isequal(res.rv_point(tab.Owner == "B001SG1" & tab.Kind == "u"), gen.rv_Uequilibrium))
V = net.a_Bus{3}.c_Vequilibrium;
assert(isequal(res.rv_point(tab.Bus == "B003" & (tab.Kind == "Vre" | tab.Kind == "Vim")), [real(V); imag(V)]))
% 制御器の入力は平衡点の値 (列 Equilibrium)
assert(isequal(res.rv_point(tab.Kind == "uc"), tab.Equilibrium(tab.Kind == "uc")))
assert(res.output.l_equilibrium && res.l_success)


%% Point at the equilibrium equals the default
% 平衡点の値を Point に与えると既定 (平衡点) と同じ行列になる (制御器の入力 uc も点の値のまま)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
res0 = net.get_sys();
res1 = net.get_sys(res0.rv_point);
assert(~res1.output.l_equilibrium && isequal(res1.rv_point, res0.rv_point))
for str = ["rm_Axx","rm_Axv","rm_Bx","rm_Avx","rm_Avv","rm_Bv","rm_E"]
    assert(norm(res1.(str) - res0.(str), 1) < 1e-8 * max(1, norm(res0.(str), 1)), str)
end
for alg = ["ODE","DAE"]
    assert(same_eigs(eig_finite(res0.get_ss(alg)), eig_finite(res1.get_ss(alg)), 1e-6), alg)
end
% 機器・母線の get_sys も同じ
[tab, c_idxBus] = net.get_variable_map();
n_lin = sum(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]));   % 線形化の点は表の先頭の行
tab = tab(1:n_lin,:);
c_idxBus = cellfun(@(iv) iv(iv <= n_lin), c_idxBus, 'UniformOutput', false);
bus = net.a_Bus{1};
s0 = bus.get_sys();  s1 = bus.get_sys(res0.rv_point(c_idxBus{1}));
assert(norm(s0.A - s1.A, 1) < 1e-8 * norm(s0.A, 1) && isequal(s0.StateName, s1.StateName))


%% LQR closed loop matches its design model
% 1機無限大母線系統では、系統の線形モデルが LQR の設計モデルと一致する
% (開ループの固有値 = eig(A)、閉ループの固有値 = eig(A - B K)。無限大母線の近似による 0 付近の固有値は除く)
[smib, gen] = DebugScript.helper.build_smib();
DebugScript.helper.quiet(@() smib.initialize);
e_open = eig_finite(smib.get_sys());
lqr = gen.add_local_controller("local-LQR");
DebugScript.helper.quiet(@() smib.initialize);
for alg = ["ODE","DAE"]
    e_closed = eig_finite(smib.get_sys("Type", alg));
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
assert(same_eigs(e1, eig_finite(netL.get_sys("Type", "DAE")), 1e-6))

% 平衡点の値を Point に与えると既定と同じ (LQR の入力 uc も点の値のまま)
res0 = netL.get_sys();
res1 = netL.get_sys(res0.rv_point);
for str = ["rm_Axx","rm_Axv","rm_Bx","rm_Avx","rm_Avv","rm_Bv","rm_E"]
    assert(norm(res1.(str) - res0.(str), 1) < 1e-8 * max(1, norm(res0.(str), 1)), str)
end


%% Point at a perturbed state
% 平衡点からずらした点では、その点の x, V, u で各機器の Jacobian を評価する。モデルと解法は変わらない
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
[tab, c_idxBus] = net.get_variable_map();
n_lin = sum(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]));   % 線形化の点は表の先頭の行
tab = tab(1:n_lin,:);
c_idxBus = cellfun(@(iv) iv(iv <= n_lin), c_idxBus, 'UniformOutput', false);
res0 = net.get_sys();
x = res0.rv_point;
gen  = net.a_Bus{2}.a_Component{1};
iv_x = find(tab.Owner == gen.s_tag & tab.Kind == "x");
iv_V = find(tab.Bus == "B002" & (tab.Kind == "Vre" | tab.Kind == "Vim"));
iv_u = find(tab.Owner == gen.s_tag & tab.Kind == "u");
x(iv_x(1)) = x(iv_x(1)) + 0.2;            % delta
x(iv_V)    = x(iv_V) * 1.03;
x(iv_u(1)) = x(iv_u(1)) + 0.1;
xe = gen.rv_Xequilibrium;
res1 = net.get_sys(x);
assert(isequal(gen.rv_Xequilibrium, xe), "モデルが変わった")
assert(norm(res1.rm_Axx(iv_x,iv_x) - res0.rm_Axx(iv_x,iv_x), 1) > 1e-6, "ずらしても行列が変わらない")
% 期待値: その点での f_JacobiDx / f_JacobiI
xg = x(iv_x);  Vg = x(iv_V);  ug = x(iv_u);
[Axx, Bxv, Bxu] = gen.f_JacobiDx(0, xg, Vg, ug);
[Cix, Div, Diu] = gen.f_JacobiI(0, xg, Vg, ug);
iv_v = iv_V - sum(tab.Kind == "x");   iv_uu = iv_u - sum(ismember(tab.Kind, ["x","Vre","Vim"]));
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
    [~, Divj] = cj.f_JacobiI(0, xj, Vg, uj);
    Div_sum = Div_sum + reshape(full(Divj), 2, 2);
end
Y = tools.complex2matrix(net.get_admittance_matrix.Variables);
assert(norm(res1.rm_Avv(iv_v,iv_v) - (Y(iv_v,iv_v) - Div_sum), 1) < 1e-10)
% 機器の get_sys(...) も同じ点で評価する
[~, c_idxC] = net.a_Bus{2}.get_variable_map();
xb = x(c_idxBus{2});
c_idxC = cellfun(@(iv) iv(iv <= numel(xb)), c_idxC, 'UniformOutput', false);
sc = gen.get_sys(xb(c_idxC{1}));
assert(norm(sc.A - Axx, 1) < 1e-10)
% Point の長さが違うと、変数の表を案内するエラー
try
    net.get_sys(x(1:end-1));
    error("DebugScript:NoError", "長さの違う Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointSize", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "get_variable_map"))
end
try
    net.get_sys("equilibrium");
    error("DebugScript:NoError", "文字列の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointType", DebugScript.helper.msg_id(ME))
end


%% Point gives the controller inputs as given
% 点の行は x, Vre, Vim, u, uc。制御器の入力 uc も点の値をそのまま使う (設定値も含む)。
% ガバナ gov-LPT1 の低値選択 min(Pref - Pgov, Plimit) は uc の Plimit で切り替わる
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
gov = gen.add_local_controller("gov-LPT1", parameter=struct(Prate=3));
DebugScript.helper.quiet(@() net.initialize);
tab = gen.get_variable_map();
n_pt = nnz(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]));
assert(isequal(tab.Kind(1:n_pt), tab.Kind(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]))), "uc が u の直後にない")
p0 = tab.Equilibrium(1:n_pt);
res0 = gen.get_sys();
assert(isequal(res0.rv_point, p0) && isequal(res0.tab_variable, tab(1:n_pt,:)))
assert(isequal(gen.get_sys(p0).A, res0.A))
row = @(s_kind, s_name) find(tab.Kind == s_kind & tab.Owner == gov.s_tag & tab.Name == s_name);
i_Pgov = row("x", "Pgov");  i_Psv = row("x", "Psv");
i_ref  = row("uc", "Pref");  i_lim = row("uc", "Plimit");
assert(res0.A(i_Psv, i_Pgov) ~= 0, "平衡点でゲートが Pref を通さない")
% Plimit を Pref - Pgov より下げると、ゲートは Plimit を通す: Psv は Pgov によらない
p = p0;
p(i_lim) = p0(i_ref) - p0(i_Pgov) - 0.01;
res = gen.get_sys(p);
assert(isequal(res.rv_point, p) && ~res.output.l_equilibrium)
assert(res.A(i_Psv, i_Pgov) == 0, "点の Plimit が制御器のブロックに届かない")
% 制御器のブロックは点の uc での get_linear_matrix と同じ
lv_g = tab.Owner(1:n_pt) == gov.s_tag;
S = gov.get_linear_matrix(p(lv_g & tab.Kind(1:n_pt) == "x"), p(tab.Kind(1:n_pt) == "Vre" | tab.Kind(1:n_pt) == "Vim"), p(lv_g & tab.Kind(1:n_pt) == "uc"));
iv_gx = find(lv_g & tab.Kind(1:n_pt) == "x");
assert(isequal(res.A(iv_gx, iv_gx), S.A))
% 系統の点でも同じ (系統の表の uc の行)
[tab_n, c_idxBus] = net.get_variable_map();
n_net = nnz(ismember(tab_n.Kind, ["x","Vre","Vim","u","uc"]));
q = tab_n.Equilibrium(1:n_net);
i_limN = find(tab_n.Kind == "uc" & tab_n.Owner == gov.s_tag & tab_n.Name == "Plimit");
i_refN = find(tab_n.Kind == "uc" & tab_n.Owner == gov.s_tag & tab_n.Name == "Pref");
i_gN   = find(tab_n.Kind == "x" & tab_n.Owner == gov.s_tag & tab_n.Name == "Pgov");
i_sN   = find(tab_n.Kind == "x" & tab_n.Owner == gov.s_tag & tab_n.Name == "Psv");
q(i_limN) = q(i_refN) - q(i_gN) - 0.01;
rN = net.get_sys(q);
assert(rN.rm_Axx(i_sN, i_gN) == 0 && net.get_sys().rm_Axx(i_sN, i_gN) ~= 0)
% Pref を上げても同じ (設定値の行)
q = tab_n.Equilibrium(1:n_net);
q(i_refN) = q(i_limN) + q(i_gN) + 0.01;
assert(net.get_sys(q).rm_Axx(i_sN, i_gN) == 0)
% 母線の点は系統の点の行
iv_b = c_idxBus{1}(c_idxBus{1} <= n_net);
q(i_refN) = tab_n.Equilibrium(i_refN);
q(i_limN) = q(i_refN) - q(i_gN) - 0.01;
assert(isequal(net.a_Bus{1}.get_sys(q(iv_b)).A, gen.get_sys(p).A))


%% Point without the controller inputs stops with PointSize
% uc の行を除いた (以前の長さの) ベクトルは受け付けない。長さで振り分けない
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
gen.add_local_controller("avr-ST1");
gen.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
c_layer = {net, net.a_Bus{1}, gen};
for k = 1:numel(c_layer)
    layer = c_layer{k};
    tab = layer.get_variable_map();
    lv_old = ismember(tab.Kind, ["x","Vre","Vim","u"]);
    assert(any(tab.Kind == "uc"))
    try
        layer.get_sys(tab.Equilibrium(lv_old));
        error("DebugScript:NoError", "uc のない点がエラーにならない: %s", class(layer))
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointSize", DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, "uc"), ME.message)
    end
    % uc を含む長さなら受け付ける
    assert(isequal(layer.get_sys(tab.Equilibrium(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]))).A, layer.get_sys().A))
end


%% Point from a simulation includes the controller inputs
% {sim, t} の点も x, Vre, Vim, u, uc の行 (sim.get_point が uc を返す)。地絡の後は PSS の出力で
% AVR の入力 Vpss が平衡点から動き、その値で線形化する
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["B002SG1", "B006SG1"]);
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = net.simulate(ev.s_tag, Time=[0,1.5]);
t   = 0.9;
tab = net.get_variable_map();
tab = tab(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]), :);
assert(isequal(sim.tab_variable.Label, tab.Label))   % 結果の変数も uc を含む
res = net.get_sys({sim, t});
assert(isequal(res.tab_variable.Label, tab.Label) && isequal(res.rv_point, sim.get_point(t, tab)))
i_vpss = find(tab.Kind == "uc" & tab.Owner == avr.s_tag & tab.Name == "Vpss");
assert(abs(res.rv_point(i_vpss) - tab.Equilibrium(i_vpss)) > 1e-6, "Vpss が平衡点のまま")
% 結果の uc は接続の源の値 (PSS の出力)
iv_pss = tab.Owner == pss.s_tag;
x_pss = res.rv_point(iv_pss & tab.Kind == "x");
V1 = res.rv_point(tab.Bus == "B001" & (tab.Kind == "Vre" | tab.Kind == "Vim"));
y_pss = pss.f_Y(0, x_pss, V1, res.rv_point(iv_pss & tab.Kind == "uc"));
assert(abs(res.rv_point(i_vpss) - y_pss) < 1e-4)
assert(isequal(net.get_sys(res.rv_point).rm_Axx, res.rm_Axx))
% 機器・母線の {sim, t} も uc の行を含む
tab_g = gen.get_variable_map();
tab_g = tab_g(ismember(tab_g.Kind, ["x","Vre","Vim","u","uc"]), :);
sg = gen.get_sys({sim, t});
assert(any(sg.tab_variable.Kind == "uc") && isequal(sg.rv_point, sim.get_point(t, tab_g)))
assert(isequal(gen.get_sys(sg.rv_point).A, sg.A))


%% Point from a simulation result and a time
% get_sys({sim, t}): 時刻 t の機器の状態・入力と母線電圧 (ResultODE の値) で線形化する
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = net.simulate(ev.s_tag, Time=[0,1.5]);
r   = sim.odeResults;
tab = net.get_variable_map();
tab = tab(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]), :);   % rv_point の行 (信号 y は含まない)
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
% uc は既定の Static の制御器の入力 (Pmech_ref, Vfd_ref) だけで、平衡値のまま
x(tab.Kind == "uc") = tab.Equilibrium(tab.Kind == "uc");
res = net.get_sys({sim, t});
assert(norm(res.rv_point - x) < 1e-12)
res_x = net.get_sys(x);
assert(isequal(res.rm_Axx, res_x.rm_Axx) && isequal(res.rm_Avv, res_x.rm_Avv))
assert(norm(res.rv_point - net.get_sys().rv_point) > 1e-4, "t が平衡点のまま")
% 出力時刻の間は線形補間
tm = (r.t(k) + r.t(k+1)) / 2;
res_m = net.get_sys({sim, tm});
assert(norm(res_m.rv_point - (net.get_sys({sim,r.t(k)}).rv_point + net.get_sys({sim,r.t(k+1)}).rv_point)/2) < 1e-12)
% 機器・母線でも同じ形
gen = net.a_Bus{1}.a_Component{1};
sc  = gen.get_sys({sim, t});
iv_x = tab.Owner == gen.s_tag & tab.Kind == "x";
assert(norm(sc.A - res.rm_Axx(iv_x,iv_x), 1) < 1e-10)
sb  = net.a_Bus{1}.get_sys({sim, t});
assert(norm(sb.A - sc.A, 1) == 0)
% 範囲外の時刻
try
    net.get_sys({sim, 10});
    error("DebugScript:NoError", "範囲外の時刻がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultODE:PointTime", DebugScript.helper.msg_id(ME))
end
% get_sys({sim, t, Side}): 第 3 要素は sim.get_point の Side
assert(isequal(net.get_sys({sim, t, "before"}).rv_point, res.rv_point))
try
    net.get_sys({sim, t, "middle"});
    error("DebugScript:NoError", "知らない Side がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointType", DebugScript.helper.msg_id(ME))
end


%% Point from a simulation with controllers at an equilibrium time
% ローカル制御器 (AVR + PSS, AVR) とグローバル制御器 (AGC) の状態も結果に入るので、外乱のない
% シミュレーションの途中の時刻で線形化すると既定 (平衡点) と同じ行列になる
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.a_Bus{2}.a_Component{1}.add_local_controller("avr-DC1", parameter=struct(kap=20));
net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
sim  = net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,1]);
res0 = net.get_sys();
res1 = net.get_sys({sim, 0.5});
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
for alg = ["ODE","DAE"]
    assert(same_eigs(eig_finite(res0.get_ss(alg)), eig_finite(res1.get_ss(alg)), 1e-4), alg)
end


%% Point from a simulation with controllers at a perturbed time
% 地絡後の時刻では、その時刻の機器・制御器の状態で各機器の Jacobian を評価する
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["B002SG1", "B006SG1"], parameter=struct(kP=100, kI=500));   % B001SG1, B003SG1 は AGC の外
DebugScript.helper.quiet(@() net.initialize);
ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = net.simulate(ev.s_tag, Time=[0,1.5]);
t   = 0.9;
res0 = net.get_sys();
res  = net.get_sys({sim, t});
[tab, c_idxBus, c_idxGC] = net.get_variable_map();
n_lin = sum(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]));   % 線形化の点は表の先頭の行
tab = tab(1:n_lin,:);
c_idxBus = cellfun(@(iv) iv(iv <= n_lin), c_idxBus, 'UniformOutput', false);
c_idxGC = cellfun(@(iv) iv(iv <= n_lin), c_idxGC, 'UniformOutput', false);
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
[Axx, Bxv, Bxu] = gen.f_JacobiDx(0, xg, Vg, ug);
[Cix, ~, Diu]   = gen.f_JacobiI(0, xg, Vg, ug);
iv_v = iv_V - sum(tab.Kind == "x");   iv_uu = iv_u - sum(ismember(tab.Kind, ["x","Vre","Vim"]));
assert(norm(res.rm_Axx(iv_x,iv_x) - Axx, 1) < 1e-10)
assert(norm(res.rm_Axv(iv_x,iv_v) - Bxv, 1) < 1e-10)
assert(norm(res.rm_Bx(iv_x,iv_uu) - Bxu, 1) < 1e-10)
assert(norm(res.rm_Avx(iv_v,iv_x) + Cix, 1) < 1e-10)
assert(norm(res.rm_Bv(iv_v,iv_uu) + Diu, 1) < 1e-10)
% AVR + PSS 付きの発電機: 機器の get_sys({sim, t}) と同じブロック (制御器の状態を含む)
gen1 = net.a_Bus{1}.a_Component{1};
[~, c_idxC] = net.a_Bus{1}.get_variable_map();
iv_b = c_idxBus{1};
c_idxC = cellfun(@(iv) iv(iv <= numel(iv_b)), c_idxC, 'UniformOutput', false);
iv_c = iv_b(c_idxC{1});
iv_cx = iv_c(tab.Kind(iv_c) == "x");
sc = gen1.get_sys({sim, t});
assert(norm(sc.A - res.rm_Axx(iv_cx,iv_cx), 1) < 1e-10)
assert(norm(sc.A - res0.rm_Axx(iv_cx,iv_cx), 1) > 1e-6, "制御器付きの機器の行列が平衡点のまま")
assert(isequal(gen1.get_sys(x(iv_c)).A, sc.A))
% グローバル制御器の状態は Point の値のまま
assert(isequal(res.rv_point(c_idxGC{1}), x(c_idxGC{1})))


%% Overrides apply to one call and leave the solver unchanged
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
res = net.get_sys("Type", "DAE");
assert(res.options.Type == "DAE" && net.get_sys().options.Type == "ODE")
assert(isequal(res.get_ss(), res.get_ss("DAE")))
% 既定値は GUILDA.setting の Linearization。変えると以後の呼び出しに効く (solver_LIN は設定を持たない)
n_x = size(res.rm_Axx,1);
assert(GUILDA.config("ApproximateLinearization", "Type") == "ODE" && ~isprop(net.solver_LIN, "Type") && ~isprop(net.solver_LIN, "Point"))
assert(~isprop(net.solver_LIN, "OptionMap") && ~ismethod(net.solver_LIN, "get_options"))
c_cfg = DebugScript.helper.user_config("ApproximateLinearization", struct("Type", "DAE"));
assert(size(net.get_sys().A,1) > n_x)
clear c_cfg
% Plot オプションは廃止 (図は result.plot_eigenvalue)、PlotFcn は "none" のみ
assert(error_id(@() net.get_sys(Plot=true)) ~= "")
assert(error_id(@() net.get_sys(PlotFcn="eig")) == "GUILDA:check_plotfcn:InDevelopment")
assert(net.get_sys(PlotFcn="none").options.PlotFcn == "none")
% 知らない名前は arguments ブロックのエラー
assert(error_id(@() net.get_sys("Typo", "ODE")) ~= "")


%% Get sys returns sys, flag and output
% v4: [sys, flag, output] = net.get_sys(...) (v3 の 2 番目の出力 lin は flag になった)。
[sys, flag, output] = net.get_sys("Type", "ODE");
assert(isa(sys, "ResultLIN") && islogical(flag) && flag)
assert(sys == output.result)
assert(isstring(output.message))
% Format で形を選ぶ: 既定 "GUILDAorigin" は ResultLIN。構造体と ss はどれも同じ行列と名前
assert(isa(net.get_sys("Type", "ODE", "Format", "GUILDAorigin"), "ResultLIN"))
try
    net.get_sys(Format="ResultLIN");
    error("DebugScript:NoError", "Format=""ResultLIN"" should stop")
catch ME
    assert(ME.identifier == "MATLAB:validators:mustBeMember", ME.identifier)
end
sct =net.get_sys("Type", "ODE", "Format", "struct");
assert(isstruct(sct) && isequal(string(fieldnames(sct))', ["A","B","C","D","E","StateName","InputName","OutputName"]))
sss = net.get_sys("Type", "ODE", "Format", "ss");
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
evalc("net_s.a_Bus{1}.l_isSlack = true;");
DebugScript.helper.quiet(@() net_s.initialize);
[res, flag, output] = net_s.get_sys();
assert(islogical(flag) && ~flag && ~res.l_success)
assert(output.s_issue == "SingularAvv" && output.rcond_Avv < 1e-14)
assert(contains(output.message, "Avv") && contains(output.message, "B001"), output.message)
for alg = "ODE"
    try
        net_s.get_sys("Type", alg, "Format", "struct");
        error("DebugScript:NoError", alg + ": エラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultLIN:SingularAvv", DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, "DAE") && contains(ME.message, "B001"), ME.message)
    end
end
% DAE は電圧を消去しないので取り出せる
[sys, flag, output] = net_s.get_sys("Type", "DAE");
assert(isa(sys, "ResultLIN") && ~flag && output.s_issue == "SingularAvv" && ~isempty(sys.A))
% Format="GUILDAorigin" は flag が false でも結果を返す。ODE は使えないので A などは空
[res, flag] = net_s.get_sys("Type", "ODE");
assert(isa(res, "ResultLIN") && ~flag && isempty(res.A) && isempty(res.StateName))
% 使える結果は flag が true で s_issue は空
[~, flag, output] = net.get_sys();
assert(flag && output.s_issue == "" && output.rcond_Avv > 1e-14)


%% Point that is not finite names the variables
% NaN の点は dss に届く前に、変数の名前を示すエラーで止まる (Issue #76)
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
tab = n14.get_variable_map();
x = n14.get_sys().rv_point;
x(5) = NaN;
x(7) = Inf;
try
    n14.get_sys(x);
    error("DebugScript:NoError", "NaN の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, tab.Label(5)) && contains(ME.message, tab.Label(7)), ME.message)
    assert(~contains(ME.message, tab.Label(6) + ","), ME.message)
end
try
    n14.get_sys(nan(numel(x),1));
    error("DebugScript:NoError", "NaN の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "more"), ME.message)
end
% トリップ中の {sim, t}: 解列した機器の状態が NaN
sim = n14.simulate(DebugScript.helper.scenario("trip", n14, "TimeSpan", 1, "TripUnit", "B002SG1").s_tag, Time=[0,2]);
try
    n14.get_sys({sim, 1.2});
    error("DebugScript:NoError", "トリップ中の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "B002SG1") && contains(ME.message, "trip"), ME.message)
end
assert(n14.get_sys({sim, 0.5}).l_success)


%% Point around a trip
% トリップは t = 1 から終わりまで続く。トリップ後の点は NaN の点で止まり、境界は Side に従う。
% トリップ前の点は機器を含めた通常の点として線形化する
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
sim = n14.simulate(DebugScript.helper.scenario("trip", n14, "TimeSpan", 1, "TripUnit", "B002SG1").s_tag, Time=[0,2], Progress="none");
res0 = n14.get_sys();
tab  = res0.tab_variable;
for c_point = {{sim,1}, {sim,1.2}, {sim,2}}
    try
        n14.get_sys(c_point{1});
        error("DebugScript:NoError", "トリップ中の Point がエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:PointNotFinite", DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, "B002SG1") && contains(ME.message, "trip"), ME.message)
    end
end
for c_point = {{sim,1,"before"}, {sim,0.5}}
    [res, flag, output] = n14.get_sys(c_point{1});
    assert(flag && all(isfinite(res.rv_point)))
    assert(isequal(res.tab_variable, tab))
    for alg = ["ODE","DAE"]
        s = DebugScript.helper.quiet(@() res.get_ss(alg, "Port", "I"));
        s0 = DebugScript.helper.quiet(@() res0.get_ss(alg, "Port", "I"));
        assert(isequal(size(s.A), size(s0.A)) && isequal(s.StateName, s0.StateName) && isequal(s.InputName, s0.InputName), alg)
    end
end
% トリップ中でも、トリップしていない機器は単独で線形化できる
x = sim.get_point(1.2);
gen3 = n14.a_Bus{3}.a_Component{1};
[tab, c_idxBus] = n14.get_variable_map();
[~, c_idxC] = n14.a_Bus{3}.get_variable_map();
n_lin = numel(x);
c_idxBus = cellfun(@(iv) iv(iv <= n_lin), c_idxBus, 'UniformOutput', false);
c_idxC = cellfun(@(iv) iv(iv <= numel(c_idxBus{3})), c_idxC, 'UniformOutput', false);
iv = c_idxBus{3}(c_idxC{1});
sc = gen3.get_sys({sim, 1.2});
assert(all(isfinite(sc.A), "all") && isequal(sc.A, gen3.get_sys(x(iv)).A))


%% Point inside a fault is reported and keeps the model network
% Point は変数の点で、網はモデルのもの: 故障中の {sim, t} でも Y は故障前のまま。呼び出しがそれを知らせる (Issue #82)
n9 = network.IEEE9bus();
DebugScript.helper.quiet(@() n9.initialize);
ev  = DebugScript.helper.scenario("short", n9, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = n9.simulate(ev.s_tag, Time=[0,1], Progress="none", TimeLimit=120);
str = evalc('[res, flag, output] = n9.get_sys({sim, 0.52});');
assert(contains(str, "INFO") && contains(str, "B008"), str)
assert(flag && output.s_issue == "" && isequal(output.sv_faultBus, "B008"))
assert(contains(output.message, "B008"), output.message)
assert(norm(res.sct_model.cm_Y - n9.get_admittance_matrix.Variables, 1) == 0)
% 極座標の DAE はここでは使えないが、Port "I" は ODE と同じ固有値になる
e_k = eig_finite(res.get_ss("ODE"));
assert(max(real(e_k)) > 1, "故障中の点の固有値が変わった")
assert(same_eigs(e_k, eig_finite(DebugScript.helper.quiet(@() res.get_ss("DAE", "Port", "I"))), 1e-6))
% 故障の前後は故障として扱わない。境界では Side に従う
[~, ~, out_b] = n9.get_sys({sim, 0.5, "before"});
[~, ~, out_a] = n9.get_sys({sim, 0.5});
assert(isempty(out_b.sv_faultBus) && isequal(out_a.sv_faultBus, "B008"))
str = evalc('[~, ~, out_p] = n9.get_sys({sim, 0.8});');
assert(isempty(out_p.sv_faultBus) && ~contains(str, "INFO") && ~contains(out_p.message, "ground fault"))


%% Message tells the equilibrium from a given point
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
res0 = n14.get_sys();
assert(res0.output.l_equilibrium && endsWith(res0.output.message, "at the equilibrium."), res0.output.message)
[~, ~, output] = n14.get_sys(res0.rv_point);
assert(~output.l_equilibrium && endsWith(output.message, "at the given point."), output.message)
sc = n14.a_Bus{1}.a_Component{1}.get_sys();
assert(contains(sc.output.message, "B001SG1") && endsWith(sc.output.message, "at the equilibrium."), sc.output.message)


%% Jacobian that is not finite names the bus
% 有限な点でも V=0 では定電力負荷の Jacobian が有限にならない (Issue #76)
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
tab = n14.get_variable_map();
x = n14.get_sys().rv_point;
x(tab.Kind == "Vre" | tab.Kind == "Vim") = 0;
try
    n14.get_sys(x);
    error("DebugScript:NoError", "V=0 の Point がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverLIN:JacobianNotFinite", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, "bus B"), ME.message)
end


%% Linearization result Plot
res = net.get_sys();
% 戻り値は GraphChart。マーカーの組 "stable" と "unstable" (点がなくても要素はある)、虚軸は固定の描画
G = res.plot_eigenvalue();
assert(isa(G, "GraphChart") && isequal(G.tab_element.Tag, ["stable"; "unstable"]) && all(G.tab_element.Kind == "marker"))
e = eig(full(res.get_ss(Format="struct").A), full(res.get_ss(Format="struct").E));
e = e(isfinite(e));
h = G.sct_plt.Element;
assert(numel(h(1).XData) + numel(h(2).XData) == numel(e) && h(1).Marker == "." && h(1).MarkerSize == 16)
assert(isequal(h(1).Color, [0 0.30 0.80]) && isequal(h(2).Color, [0.85 0 0]))
assert(isempty(G.ax.Legend) && isscalar(G.sct_plt.RefLine) && G.sct_plt.RefLine.Value == 0)
G.set_style("stable", Color="k", MarkerSize=10);
assert(isequal(h(1).Color, [0 0 0]) && h(1).MarkerSize == 10 && isequal(h(2).Color, [0.85 0 0]))
G.reset_style();
assert(isequal(h(1).Color, [0 0.30 0.80]) && h(1).MarkerSize == 16)
close(ancestor(G.ax, "figure"))
% Tolerance を大きくすると不安定の組は空
G = res.plot_eigenvalue("Type", "DAE", Tolerance=1e9);
assert(isempty(G.sct_plt.Element(2).XData))
close(ancestor(G.ax, "figure"))


%% Plot draws the algorithm of the options
% 既定は options.Type。Type を渡せばそちらを描く
for alg = ["ODE","DAE"]
    res = DebugScript.helper.quiet(@() net.get_sys("Type", alg));
    G = res.plot_eigenvalue();
    assert(G.ax.Title.String == "Eigenvalues (" + alg + ")", G.ax.Title.String)
    close(ancestor(G.ax, "figure"))
end
res = net.get_sys("Type", "ODE");
G = res.plot_eigenvalue("Type", "DAE");
assert(G.ax.Title.String == "Eigenvalues (DAE)", G.ax.Title.String)
close(ancestor(G.ax, "figure"))
% 機器の結果は層の種類を題にする
G = net.a_Bus{1}.a_Component{1}.get_sys().plot_eigenvalue();
assert(G.ax.Title.String == "Eigenvalues (Component)", G.ax.Title.String)
close(ancestor(G.ax, "figure"))


%% Bus without components in a large network
% IEEE68 には機器のない母線がある。ODE と DAE の固有値は一致する
net_68 = network.IEEE68bus();
DebugScript.helper.quiet(@() net_68.initialize);
assert(any(tools.vcellfun(@(b) isempty(b.a_Component), net_68.a_Bus)))
res = net_68.get_sys();
assert(same_eigs(eig_finite(res.get_ss("ODE")), eig_finite(res.get_ss("DAE")), 1e-6))


%% Configurations that cannot be linearized stop with a GUILDA error
% 状態のない系統も ODE と DAE で扱える
net_load = PowerNetwork("LoadOnly");
net_load.add_bus("V", 1);
net_load.add_bus();
net_load.add_branch("pi", [1,2], "R", 0.01, "X", 0.085);
net_load.a_Bus{1}.add_component("load-impedance", "P", -0.5, "Q", -0.1);
net_load.a_Bus{2}.add_component("load-impedance", "P", -0.5, "Q", -0.1);
evalc("net_load.a_Bus{1}.l_isSlack = true;");
DebugScript.helper.quiet(@() net_load.initialize);
assert(isempty(net_load.get_sys("Type", "ODE").A) && net_load.get_sys("Type", "ODE").l_success)
assert(size(net_load.get_sys("Type", "DAE").A, 1) == 4)
% 出力のない機器の AGC は追加で止まり、原因 (機器と入力 omega) を示す。系統は変わらない
net_droop = DebugScript.helper.build_3bus("gen-droop");
gen_droop = net_droop.a_Bus{2}.a_Component{1};
try
    net_droop.add_global_controller("agc-PI", gen_droop);
    error("DebugScript:NoError", "エラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:GconPorts", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, gen_droop.s_tag) && contains(ME.message, "omega"), ME.message)
end
assert(isempty(net_droop.a_GlobalController))


%% Port is an option of get_sys
% Port は GUILDA.setting の Linearization の設定で、呼び出しごとに上書きできる。既定は変わらない
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
assert(GUILDA.config("ApproximateLinearization", "Port") == "PQ")
sD0 = net.get_sys(Type="DAE");
assert(any(string(sD0.StateName) == "rho1"))
sD = net.get_sys(Type="DAE", Port="PI");
assert(any(string(sD.StateName) == "V1") && GUILDA.config("ApproximateLinearization", "Port") == "PQ")
assert(isequal(net.get_sys(Type="DAE", Port="PI", Format="ss"), net.get_sys(Port="PI").get_ss("DAE")))
assert(isequal(net.get_sys(Type="DAE", Format="struct"), net.get_sys(Port="PI").get_ss("DAE", Port="PQ", Format="struct")))
c_cfg = DebugScript.helper.user_config("ApproximateLinearization", struct("Port", "I"));
assert(any(string(net.get_sys(Type="DAE").StateName) == "Vre1"))
clear c_cfg
try
    net.get_sys(Port="polar");
    error("DebugScript:NoError", "不正な Port がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) ~= "DebugScript:NoError", DebugScript.helper.msg_id(ME))
end
% PI と PQ の DAE は、I の DAE を手で変換したものと同じ (列 v、行 w。Coordinate の theta&V, theta&rho と同じ式)
%   PQ: [dVre; dVim] = [-Vi, Vr; Vr, Vi] [theta; rho],     [P; Q]   = [-Vi, Vr; Vr, Vi] [-Iim; Ire]
%   PI: [dVre; dVim] = [-Vi, Vr/|V|; Vr, Vi/|V|] [theta; V], [P; Q/V] = [-Vi, Vr; Vr/|V|, Vi/|V|] [-Iim; Ire]
res = net.get_sys();
tab = res.tab_variable;
cv_V = res.rv_point(tab.Kind == "Vre") + 1j*res.rv_point(tab.Kind == "Vim");
Vr = diag(real(cv_V));  Vi = diag(imag(cv_V));  Vm = diag(abs(cv_V));
sI = res.get_ss("DAE", Port="I", Format="struct");
n_x = size(sI.A,1) - 2*numel(cv_V);
c_port = {"PQ", [-Vi, Vr; Vr, Vi], [-Vi, Vr; Vr, Vi], ["theta","rho"]; ...
          "PI", [-Vi, Vm\Vr; Vr, Vm\Vi], [-Vi, Vr; Vm\Vr, Vm\Vi], ["theta","V"]};
for k = 1:size(c_port,1)
    sP = res.get_ss("DAE", Port=c_port{k,1}, Format="struct");
    To = blkdiag(eye(n_x), c_port{k,3});
    Ti = blkdiag(eye(n_x), c_port{k,2});
    assert(norm(sP.A - To*sI.A*Ti, Inf) <= 1e-12*norm(sI.A, Inf), c_port{k,1} + ": A")
    assert(norm(sP.B - To*sI.B, Inf) <= 1e-12*max(1, norm(sI.B, Inf)), c_port{k,1} + ": B")
    assert(isequal(sP.C, sI.C) && isequal(sP.D, sI.D) && isequal(sP.E, sI.E), c_port{k,1} + ": C, D, E")
    sv_bus = [c_port{k,4}(1) + (1:numel(cv_V)), c_port{k,4}(2) + (1:numel(cv_V))]';
    assert(isequal(sP.StateName, [sI.StateName(1:n_x); sv_bus]), c_port{k,1} + ": StateName")
end
assert(isequal(sI.StateName(n_x+1:end), ["Vre" + (1:numel(cv_V)), "Vim" + (1:numel(cv_V))]'))


%% Default channels of get_sys do not change
% Input, Output を与えなければ v3 互換の既定のまま。ODE の出力名は空
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
res = net.get_sys();
sK = net.get_sys(Type="ODE");
assert(all(sK.OutputName == "") && numel(sK.OutputName) == size(sK.A,1) && isequal(sK.C, eye(size(sK.A,1))))
for alg = ["ODE","DAE"]
    assert(isequal(net.get_sys(Type=alg, Format="ss"), res.get_ss(alg)), alg)
    assert(isequal(net.get_sys(Type=alg, Format="struct"), res.get_ss(alg, Format="struct")), alg)
end


%% Output and Input select the channels
% ODE と DAE の V, I, y の伝達関数が一致する (global controller, 制御器, 非ユニット母線の負荷あり)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
res = net.get_sys();
tab = res.tab_variable;
sv_v = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
sK = res.get_ss("ODE", Output=["V","I","y"]);
s0 = 0.3 + 1i;
GK = freqresp(sK, s0);
for s = {res.get_ss("DAE", Output=["V","I","y"]), ...
         res.get_ss("DAE", Output=["V","I","y"], Port="PI"), ...
         res.get_ss("DAE", Output=["V","I","y"], Port="I")}
    assert(isequal(s{1}.OutputName, sK.OutputName) && isequal(s{1}.InputName, sK.InputName))
    assert(norm(freqresp(s{1}, s0) - GK) < 1e-8 * norm(GK))
end
n_b = numel(net.a_Bus);
sv_out = string(sK.OutputName);
assert(isequal(sv_out(1:2*n_b), sv_v) && numel(unique(sv_out)) == numel(sv_out))
assert(startsWith(sv_out(2*n_b+1), "Ire") && startsWith(sv_out(2*n_b+2), "Iim"))

% V は電圧を消去した式と同じ。I は機器の注入電流 (-Avx x + (Y - Avv) v - Bv u) と同じ
n_v = 2*n_b;
sV = res.get_ss("ODE", Output="V");
[~, ix] = ismember(string(sV.StateName), tab.Label(tab.Kind == "x"));
assert(norm(sV.C + res.rm_Avv \ res.rm_Avx(:,ix), 1) < 1e-10 && norm(sV.D + res.rm_Avv \ res.rm_Bv, 1) < 1e-10)
sI = res.get_ss("ODE", Output="I");
rm_Y = tools.complex2matrix(net.get_admittance_matrix.Variables);
assert(norm(sI.C - (-res.rm_Avx(:,ix) + (rm_Y - res.rm_Avv)*sV.C), 1) < 1e-8)
assert(norm(sI.D - (-res.rm_Bv + (rm_Y - res.rm_Avv)*sV.D), 1) < 1e-8)

% y: 状態と同名の出力は Y_ 付きで、状態そのもの。AVR の出力 Vfield は状態 Vap
gen = net.a_Bus{1}.a_Component{1};
avr = gen.a_LocalController{1};
s_y = string(gen.attach_tag("Y_omega"));
sy = res.get_ss("ODE", Output=[s_y, string(avr.attach_tag("Vfield"))]);
assert(isequal(string(sy.OutputName), [s_y; string(avr.attach_tag("Vfield"))]))
assert(isequal(sy.C(1,:), double(string(sy.StateName) == string(gen.attach_tag("omega")))'))
assert(isequal(sy.C(2,:), double(string(sy.StateName) == string(avr.attach_tag("Vap")))'))
assert(all(sy.D == 0, "all"))

% 種類と名前の混在は指定の順で、重複は 1 つ。x はモデルのすべての状態を StateName の順に出す
s_w = string(gen.attach_tag("omega"));
sM = net.get_sys(Type="ODE", output=[sv_v(3), s_w, sv_v(3)]);
assert(isequal(string(sM.OutputName), [sv_v(3); s_w]))
for alg = ["ODE","DAE"]
    sys_def = res.get_ss(alg);
    sys_x = res.get_ss(alg, Output="x");
    assert(isequal(sys_x.A, sys_def.A) && isequal(sys_x.E, sys_def.E) && isequal(sys_x.B, sys_def.B) && all(sys_x.D == 0, "all"), alg)
    sv_state = string(sys_x.StateName);
    assert(isequal(string(sys_x.OutputName), sv_state(ismember(sv_state, tab.Label(tab.Kind == "x")))), alg)
    assert(isequal(sys_x.C, eye(size(sys_x.C,1), size(sys_x.A,1))), alg)
end
% y は機器 (y)、ローカル制御器とグローバル制御器 (yc) の出力
tab_all = net.get_variable_map();
sy = res.get_ss("ODE", Output="y");
assert(isequal(string(sy.OutputName), tab_all.Label(tab_all.Kind == "y" | tab_all.Kind == "yc")))

% Input: 指定の順。状態は変わらない。Output と併用できる。列ベクトルも受ける
sv_u = tab.Label(tab.Kind == "u");
for alg = ["ODE","DAE"]
    sys_all = net.get_sys(Type=alg, Output="V");
    sys_sel = net.get_sys(Type=alg, Output="V", Input=sv_u([3;1]));
    assert(isequal(string(sys_sel.InputName), sv_u([3;1])), alg)
    assert(isequal(sys_sel.A, sys_all.A) && isequal(sys_sel.StateName, sys_all.StateName), alg)
    [~, iu] = ismember(sv_u([3;1]), string(sys_all.InputName));
    assert(isequal(sys_sel.D, sys_all.D(:,iu)) && isequal(sys_sel.B, sys_all.B(:,iu)), alg)
    assert(isequal(net.get_sys(Type=alg, Input="u").InputName, net.get_sys(Type=alg).InputName), alg)
end

% 不明な名前
for c = {{"Output","nope","UnknownOutput"}, {"Input","nope","UnknownInput"}, {"Input","V","UnknownInput"}}
    try
        net.get_sys("Type", "ODE", c{1}{1:2});
        error("DebugScript:NoError", "不明な名前がエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultLIN:" + c{1}{3}, DebugScript.helper.msg_id(ME))
    end
end
% Format="GUILDAorigin" でも、flag が true なら不明な名前で止まる
assert(error_id(@() net.get_sys(Output="nope")) == "GUILDA:ResultLIN:UnknownOutput")


%% ODE outputs every state
% ODE は状態を消さないので、どの状態も名前で出力にできる (AVR の質量のない Vst も)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
res = net.get_sys();
sv_x  = res.tab_variable.Label(res.tab_variable.Kind == "x");
s_vst = sv_x(contains(sv_x, "Vst"));
assert(~isempty(s_vst))
assert(string(res.get_ss("ODE", Output=s_vst(1)).OutputName) == s_vst(1))
assert(isequal(sort(string(res.get_ss("ODE").StateName)), sort(sv_x)))


%% Canonical linearization demo runs
% 正規デモ +DebugScript/Task_linearization.m が最後まで動く (run_all は test_F*, test_I* だけを読むのでここから呼ぶ)
DebugScript.helper.quiet(@() run_task_linearization());


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
res = net.get_sys();
assert(isa(net.get_sys(), "ResultLIN") && ~isempty(res.A))
sct = res.get_ss(res.options.Type, Format="struct");
assert(isequal(sct.A, res.A))
c_call = {@() res.get_ss("ODE"), @() net.get_sys(Format="ss"), ...
    @() net.a_Bus{1}.a_Component{1}.get_sys(Format="ss"), ...
    @() net.a_Bus{1}.a_Component{1}.add_local_controller("local-LQR"), ...
    @() net.a_Bus{1}.a_Component{1}.add_local_controller("pss-retrofit")};
sv_feature = ["ResultLIN.get_ss", "ResultLIN.get_ss", "ResultLIN.get_ss", ...
    "controller.local_LQR", "controller.pss.Retrofit"];
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


%% Type switches the model of the result
% res.Type は A ... OutputName のモデルを選ぶ。既定は get_sys の Type。結果は DAE を持つので線形化は 1 回
res = net.get_sys();
assert(res.Type == "ODE" && net.get_sys(Type="DAE").Type == "DAE")
sO = res.get_ss("ODE", Format="struct");
sD = res.get_ss("DAE", Format="struct");
for s = ["A","B","C","D","E","StateName","InputName","OutputName"]
    assert(isequal(res.(s), sO.(s)), "ODE: " + s)
end
res.Type = "DAE";
for s = ["A","B","C","D","E","StateName","InputName","OutputName"]
    assert(isequal(res.(s), sD.(s)), "DAE: " + s)
end
assert(size(res.A,1) == size(sO.A,1) + 2*numel(net.a_Bus) && rank(res.E) == rank(sO.E))
res.Type = "ODE";
assert(isequal(res.A, sO.A) && isequal(res.E, sO.E))
assert(error_id(@() set_type(res, "Kron")) ~= "")
% Input, Output, Port の選択は Type を変えても同じ
resV = net.get_sys(Output="V", Port="I");
nO = numel(resV.OutputName);
resV.Type = "DAE";
assert(numel(resV.OutputName) == nO && isequal(resV.C, resV.get_ss("DAE", Output="V", Port="I", Format="struct").C))
assert(all(startsWith(resV.StateName(end-1:end), "Vim")))


%% Reduce eliminates the algebraic variables of a DAE
% SolverLIN.reduce は E が 0 の行と列 (母線電圧) を消去する。get_ss("ODE") はこれを使う
res = net.get_sys();
sD = res.get_ss("DAE", Port="I", Format="struct");
sR = SolverLIN.reduce(sD);
sO = res.get_ss("ODE", Format="struct");
assert(isequal(sR.StateName, sO.StateName) && isequal(sR.InputName, sO.InputName))
for s = ["A","B","C","D","E"]
    assert(norm(sR.(s) - sO.(s), Inf) <= 1e-12*max(1, norm(sO.(s), Inf)), s)
end
% 極座標の DAE でも消去した結果は同じ
sR2 = SolverLIN.reduce(res.get_ss("DAE", Port="PQ", Format="struct"));
assert(norm(sR2.A - sO.A, Inf) <= 1e-9*norm(sO.A, Inf))
% 代数変数のないモデルはそのまま
sP = net.a_Bus{1}.a_Component{1}.get_sys(Format="struct");
assert(isequal(SolverLIN.reduce(sP).A, sP.A))
% 代数変数の部分が特異なら止まる
sS = struct("A", [-1 1; 1 0], "B", [1; 0], "C", [1 0], "D", 0, "E", diag([1 0]), ...
            "StateName", ["x";"z"], "InputName", "u", "OutputName", "y");
sS.A(2,2) = 0;  sS.A(2,1) = 0;
assert(error_id(@() SolverLIN.reduce(sS)) == "GUILDA:SolverLIN:SingularAvv")
sS.A(2,2) = 2;
sRS = SolverLIN.reduce(sS);
assert(sRS.StateName == "x" && abs(sRS.A - (-1 - 1*0/2)) < 1e-15 && abs(sRS.C - 1) < 1e-15)


%% Contributions by tag, by class and by several targets
% get_contribution は要素の DAE への寄与を返す。状態の行は状態の所有者、母線の電流の釣り合いの行は
% 機器の電流の項がその機器、Y が送電線 (と母線のシャント) のもの
netc = contribution_net("IEEE14bus");
res = netc.get_sys(Output=["x","V","I","y"]);
tab = res.tab_variable;
tab_owner = res.sct_model.sct_sys.tab_owner;
res.Type = "DAE";
s_gen = string(netc.a_Bus{1}.a_Component{1}.s_tag);
con = netc.a_Bus{1}.a_Component{1}.a_LocalController{1};
s_con = string(con.s_tag);
[v_gen, m_gen] = res.get_contribution(s_gen);
assert(isequal(size(v_gen.A), size(res.A)) && isequal(size(v_gen.B), size(res.B)) && isequal(size(v_gen.C), size(res.C)))
assert(isequal(v_gen.StateName, res.StateName) && isequal(v_gen.OutputName, res.OutputName) && islogical(m_gen.A))
% 状態の行は所有者のもの: 発電機の行はすべて発電機、制御器の行 (B_con C_gen を含む) に発電機の項はない
lv_gen = ismember(res.StateName, tab.Label(tab.Kind == "x" & tab.Owner == s_gen));
lv_con = ismember(res.StateName, tab.Label(tab.Kind == "x" & tab.Owner == s_con));
assert(any(lv_gen) && any(lv_con))
assert(isequal(v_gen.A(lv_gen,:), res.A(lv_gen,:)) && isequal(v_gen.E(lv_gen,:), res.E(lv_gen,:)) && ~any(v_gen.A(lv_con,:), "all"))
v_con = res.get_contribution(s_con);
assert(isequal(v_con.A(lv_con,:), res.A(lv_con,:)) && any(v_con.A(lv_con, lv_gen), "all"))
% マスクは値の変わる要素を含む
for s = ["A","B","C","D","E"]
    assert(~any(v_gen.(s) ~= 0 & ~m_gen.(s), "all"), s)
end
% 出力の行: 状態はその所有者、電圧は母線
lv_out = res.OutputName == tab.Label(find(tab.Kind == "x" & tab.Owner == s_gen, 1));
assert(isequal(v_gen.C(lv_out,:), res.C(lv_out,:)))
% 複数の対象は和
v_two = res.get_contribution([s_gen, s_con]);
for s = ["A","B","C","D","E"]
    assert(norm(v_two.(s) - v_gen.(s) - v_con.(s), Inf) <= 1e-12*max(1, norm(res.(s), Inf)), s)
end
% クラス名: そのクラスの要素の和。親クラスは子クラスを含む。パッケージ名はその中のクラス
s_cls = tab_owner.Class(tab_owner.Owner == s_gen);
v_cls = res.get_contribution(s_cls);
v_sum = sum_contribution(res, tab_owner.Owner(tab_owner.Class == s_cls));
assert(same_parts(v_cls, v_sum, res))
lv_lc = arrayfun(@(c) any(superclasses(char(c)) == "LocalController"), tab_owner.Class);
assert(same_parts(res.get_contribution("LocalController"), sum_contribution(res, tab_owner.Owner(lv_lc)), res))
lv_avr = startsWith(tab_owner.Class, "controller.avr.");
assert(any(lv_avr) && same_parts(res.get_contribution("controller.avr"), sum_contribution(res, tab_owner.Owner(lv_avr)), res))
% 送電線: Y の行と列の部分だけ。母線はシャントと電圧の出力
br = netc.a_Branch{1};
v_br = res.get_contribution(string(br.s_tag));
n_xd = nnz(tab.Kind == "x");
assert(~any(v_br.A(1:n_xd,:), "all") && any(v_br.A(n_xd+1:end, n_xd+1:end), "all") && ~any(v_br.A(n_xd+1:end, 1:n_xd), "all"))
lv_br = arrayfun(@(c) any(superclasses(char(c)) == "Branch"), tab_owner.Class);
assert(any(lv_br) && same_parts(res.get_contribution("Branch"), sum_contribution(res, tab_owner.Owner(lv_br)), res))
lv_vout = res.OutputName == tab.Label(find(tab.Kind == "Vre", 1));
v_bus = res.get_contribution(tab.Bus(find(tab.Kind == "Vre", 1)));
assert(isequal(v_bus.C(lv_vout,:), res.C(lv_vout,:)))
% 不明な対象は止まる
assert(error_id(@() res.get_contribution("NoSuchElement")) == "GUILDA:ResultLIN:UnknownTarget")


%% Contributions of all elements sum to the DAE
% すべての要素の寄与の和は DAE (IEEE14: 要素ごと、IEEE68: 種類ごと)
netc = contribution_net("IEEE14bus");
res = netc.get_sys(Output=["x","V","I","y"]);
res.Type = "DAE";
tab_owner = res.sct_model.sct_sys.tab_owner;
assert(same_parts(sum_contribution(res, tab_owner.Owner), res, res), "IEEE14: 要素の和が DAE と違う")
assert(same_parts(sum_contribution(res, ["Component","LocalController","GlobalController","Branch","Bus"]), res, res))
% 結果の座標で求める
resR = netc.get_sys(Type="DAE", Port="I");
assert(same_parts(sum_contribution(resR, ["Component","LocalController","GlobalController","Branch","Bus"]), resR, resR))
% 機器の結果 (ポートのモデル) も同じ規則で分かれる
resC = netc.a_Bus{1}.a_Component{1}.get_sys();
assert(same_parts(sum_contribution(resC, resC.sct_model.sct_sys.tab_owner.Owner), resC, resC))


%% Contributions of all elements sum to the DAE of IEEE68
netc = contribution_net("IEEE68bus");
res = netc.get_sys(Type="DAE", Output=["V","y"]);
assert(same_parts(sum_contribution(res, ["Component","LocalController","GlobalController","Branch","Bus"]), res, res), "IEEE68: 種類の和が DAE と違う")
tab_owner = res.sct_model.sct_sys.tab_owner;
assert(same_parts(sum_contribution(res, tab_owner.Owner), res, res), "IEEE68: 要素の和が DAE と違う")


%% Linear models match the reference values
% 接続器 SolverLIN に置き換える前のコードで求めた基準値 (+helper/linearization_reference.mat) と、
% 網 (rm_*, ODE, DAE)・機器・母線・LC・GC のモデルが数値精度で一致する (Issue #121)
tab = DebugScript.helper.linearization_reference_check(["IEEE9bus","Txt3Bus","IEEE14bus+GC"]);
assert(all(tab.Diff <= 1e-9), "基準値と違う: %s", strjoin(tab.Case(tab.Diff > 1e-9) + " " + tab.Point(tab.Diff > 1e-9) + " " + tab.Part(tab.Diff > 1e-9), "; "))

%% Linear models of every bundled network match the reference values
% 前のテスト (Linear models match the reference values) で比べた 3 件を除く残りの系統
S = load(fullfile(fileparts(which("DebugScript.helper.linearization_reference_check")), "linearization_reference.mat"), "ref");
sv_case = setdiff(unique([S.ref.name], "stable"), ["IEEE9bus","Txt3Bus","IEEE14bus+GC"], "stable");
tab = DebugScript.helper.linearization_reference_check(sv_case);
assert(all(tab.Diff <= 1e-9), "基準値と違う: %s", strjoin(tab.Case(tab.Diff > 1e-9) + " " + tab.Point(tab.Diff > 1e-9) + " " + tab.Part(tab.Diff > 1e-9), "; "))


%% Time sections: one section keeps the result of a single point
% 平衡点・ベクトルは 1 断面 (rv_t = NaN, Index = 1)。Index を指定しても同じ行列で、struct は 1x1
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
res = n14.get_sys();
assert(isscalar(res.rv_t) && isnan(res.rv_t) && res.Index == 1)
assert(isequal(res.output.lv_flag, true) && res.output.sv_issue == "" && res.output.sv_message == res.output.message)
S = res.sct_model.sct_sys;
n_xs = size(S.A,1) - S.n_v;
assert(isequal(res.rm_Axx, S.A(1:n_xs,1:n_xs)) && isequal(res.rm_Avv, S.A(n_xs+1:end,n_xs+1:end)) && isequal(res.rm_E, S.E(1:n_xs,1:n_xs)))
sct1 = res.get_ss(Format="struct");
assert(isequal(sct1, res.get_ss(Index=1, Format="struct"), res.get_ss(Time=5, Format="struct")))
sct = n14.get_sys(Format="struct");
assert(isscalar(sct) && isequal(sct, sct1))
resv = n14.get_sys(res.rv_point);
assert(isscalar(resv.rv_t) && isnan(resv.rv_t) && isequal(resv.A, res.A) && isequal(resv.rv_point, res.rv_point))
% 網の結果は系統のスナップショットを持つ (機器の結果は空)
assert(isfield(res.sct_network, "s_tag") && string(res.sct_network.s_tag) == string(n14.s_tag) && isfield(res.sct_network, "a_Bus"))
assert(isempty(fieldnames(n14.a_Bus{1}.a_Component{1}.get_sys().sct_network)))
% 範囲外の Index
try
    res.Index = 2;
    error("DebugScript:NoError", "範囲外の Index がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultLIN:IndexRange", DebugScript.helper.msg_id(ME))
end
assert(error_id(@() res.get_ss(Index=2)) == "GUILDA:ResultLIN:IndexRange")


%% Time sections of a simulation equal separate calls
% get_sys({sim, rv_t}) の断面 k は get_sys({sim, rv_t(k)}) と同じ。Index を変えると A と rv_point が変わる
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
ev  = DebugScript.helper.scenario("fault", n14, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = n14.simulate(ev.s_tag, Time=[0,1.5]);
rv_t = [0.3, 0.8, 1.2];
[res, flag, output] = n14.get_sys({sim, rv_t});
assert(flag && isequal(res.rv_t, rv_t) && res.Index == 1 && isequal(output.lv_flag, true(1,3)))
assert(numel(output.sv_message) == 3 && contains(output.message, "3 sections"), output.message)
A1 = res.A;  x1 = res.rv_point;
for k = 1:3
    res.Index = k;
    rk = n14.get_sys({sim, rv_t(k)});
    assert(isequal(res.rv_point, rk.rv_point) && isequal(res.rm_Axx, rk.rm_Axx) && isequal(res.rm_Avv, rk.rm_Avv), "断面 %d", k)
    assert(isequal(res.A, rk.A) && isequal(res.E, rk.E) && isequal(res.StateName, rk.StateName), "断面 %d の ODE", k)
    assert(isequal(res.get_ss("DAE", Index=k, Format="struct"), rk.get_ss("DAE", Format="struct")), "断面 %d の DAE", k)
    assert(isequal(res.get_contribution("Branch", Index=k), rk.get_contribution("Branch")), "断面 %d の寄与", k)
end
assert(norm(res.A - A1, Inf) > 0 && norm(res.rv_point - x1) > 0, "Index で A と rv_point が変わらない")
% 型の切り替えも断面ごと
res.Type = "DAE";
assert(isequal(res.A, n14.get_sys({sim, rv_t(3)}, Type="DAE").A))
res.Index = 1;
assert(isequal(res.A, n14.get_sys({sim, rv_t(1)}, Type="DAE").A))
% Time は最も近い断面、Side は全断面に
assert(isequal(res.get_ss("ODE", Time=0.9, Format="struct"), res.get_ss("ODE", Index=2, Format="struct")))
resB = n14.get_sys({sim, rv_t, "before"});
assert(isequal(resB.rm_point, res.rm_point))
% 行列の点: 列ごとの断面、rv_t = 1:n
resM = n14.get_sys(res.rm_point(:, [3 1]));
assert(isequal(resM.rv_t, [1 2]))
resM.Index = 2;
assert(isequal(resM.rv_point, x1) && isequal(resM.A, A1))
assert(error_id(@() n14.get_sys(res.rm_point(1:end-1,:))) == "GUILDA:SolverLIN:PointSize")


%% Modes of every time section
% get_mode(Index="all"): 断面ごとの構造体の配列。tab_mode は Time と Index の列つきで、vertcat で 1 つの表に
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
ev  = DebugScript.helper.scenario("fault", n14, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = n14.simulate(ev.s_tag, Time=[0,1.5]);
res = n14.get_sys({sim, [0.3, 1.2]});
sct = res.get_mode(Index="all", MinFrequency=0.1);
sct1 = res.get_mode(Index=1, MinFrequency=0.1);
sct2 = res.get_mode(Index=2, MinFrequency=0.1);
tab = vertcat(sct.tab_mode);
tab1 = sct1.tab_mode;
tab2 = sct2.tab_mode;
assert(isequal(tab.Properties.VariableNames(1:2), {'Time','Index'}) && height(tab) == height(tab1) + height(tab2))
assert(all(tab.Time(tab.Index == 1) == 0.3) && all(tab.Time(tab.Index == 2) == 1.2))
assert(isequal(tab(tab.Index == 2, 3:end), tab2) && isequal(tab(tab.Index == 1, 3:end), tab1))
assert(isequal(size(sct), [1 2]) && isequal(rmfield(sct(1), "tab_mode"), rmfield(sct1, "tab_mode")) && isequal(rmfield(sct(2), "tab_mode"), rmfield(sct2, "tab_mode")))
assert(isequal(res.get_mode(Time=1.0, MinFrequency=0.1), sct2))
assert(error_id(@() res.get_mode(Index="every")) == "GUILDA:ResultLIN:IndexForm")
fig = figure("Visible", "off");
G = res.plot_eigenvalue(Index=2, Parent=fig);
assert(isa(G, "GraphChart"))
close(fig)


%% Time sections as struct and ss arrays
% Format="struct" は 1 x n_t の構造体配列、"ss" は ss 配列 (sys(:,:,k))
n14 = new_net();
DebugScript.helper.quiet(@() n14.initialize);
x0 = n14.get_sys().rv_point;
tab = n14.get_variable_map();
x1 = x0;
iv = find(tab.Kind == "x", 1);
x1(iv) = x1(iv) + 0.05;
X = [x0, x1];
res = n14.get_sys(X);
sct = n14.get_sys(X, Format="struct");
assert(isequal(size(sct), [1 2]))
for k = 1:2
    assert(isequal(sct(k), res.get_ss(Index=k, Format="struct")), "断面 %d", k)
end
sctD = n14.get_sys(X, Type="DAE", Output="V", Format="struct");
assert(isequal(size(sctD), [1 2]) && isequal(sctD(2), res.get_ss("DAE", Index=2, Output="V", Format="struct")))
if license("test", "Control_Toolbox") && ~isempty(ver("control"))
    sys = n14.get_sys(X, Format="ss");
    assert(size(sys, 3) == 2)
    for k = 1:2
        assert(norm(sys(:,:,k).A - sct(k).A, Inf) == 0 && norm(sys(:,:,k).B - sct(k).B, Inf) == 0, "ss 断面 %d", k)
    end
end


% ローカル関数
function run_task_linearization()
% スクリプトの変数がテストの変数と混ざらないように関数の中で実行する
    DebugScript.Task_linearization
end


function set_type(res, s_type)
% res.Type に代入する (error_id で検証のエラーを調べるため)
    res.Type = s_type;
end


function net = contribution_net(s_case)
% 寄与のテストの系統: 最初の発電機に AVR と PSS (なければ)、Pmech を入力にもつ 2 台に AGC
    net = DebugScript.helper.quiet(@() network.(s_case)());
    g = net.a_Bus{1}.a_Component{1};
    if isempty(g.avr) || isempty(g.avr.sv_x)    % 状態を持つ AVR がない (既定の Static だけ)
        g.add_local_controller("avr-ST1");
        g.add_local_controller("pss-PSS1");
    end
    cc = {};
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            c = net.a_Bus{i}.a_Component{j};
            if any(c.sv_u == "Pmech")
                cc{end+1} = c; %#ok<AGROW>
            end
        end
    end
    DebugScript.helper.quiet(@() net.add_global_controller("agc-PI", cc(1:2), parameter=struct(alpha=[1;1], beta=[1;1])));
    DebugScript.helper.quiet(@() net.initialize());
end


function sct = sum_contribution(res, sv_target)
% 対象ごとの寄与 (1 つずつ求めたもの) の和
    sct = struct();
    for s = ["A","B","C","D","E"]
        sct.(s) = 0;
    end
    for t = reshape(string(sv_target), 1, [])
        v = res.get_contribution(t);
        for s = ["A","B","C","D","E"]
            sct.(s) = sct.(s) + v.(s);
        end
    end
end


function tf = same_parts(a, b, res)
% A ... E が res の大きさに比べて丸めの範囲で一致するか
    tf = true;
    for s = ["A","B","C","D","E"]
        tf = tf && isequal(size(a.(s)), size(res.(s))) && ...
             norm(a.(s) - b.(s), Inf) <= 1e-10*max(1, norm(res.(s), Inf));
    end
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
