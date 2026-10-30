% F7 近似線形化 (linearize / get_sys / LinearizationResult / get_variable_map / get_hessian)
%
% 平衡点 (または指定した点) まわりの線形モデルを求める。
%   res = net.linearize("Algorithm", ..., "NonUnit", 母線番号, "Point", 点);
%   sys = res.get_ss("Kron" | "Feedback" | "DAE");
%   sys = net.get_sys("Algorithm", ...);          % linearize + get_ss の近道
%   tab = net.get_variable_map();                 % 変数の順 (res.rm_Axx などの行と列)
% sys は記述子形式の状態空間モデル (dss: E dx = A x + B u)。
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


%% Get sys Kron
sys = net.get_sys("Algorithm", "Kron");
assert(isa(sys, "ss"))
assert(size(sys.A,1) == n_x)
assert(numel(sys.StateName) == size(sys.A,1))


%% Get sys Feedback
% 既定の方式は Feedback
sys = net.get_sys();
assert(isa(sys, "ss"))
assert(size(sys.A,1) >= n_x)


%% Get sys DAE
% DAE 方式は母線電圧・電流などの代数変数も状態に含む (E が特異)
sys = net.get_sys("Algorithm", "DAE");
assert(isa(sys, "ss"))
assert(size(sys.A,1) > n_x)
assert(rank(sys.E) < size(sys.E,1))


%% Three algorithms give same eigenvalues
e_kron = eig_finite(net.get_sys("Algorithm","Kron"));
e_fb   = eig_finite(net.get_sys("Algorithm","Feedback"));
e_dae  = eig_finite(net.get_sys("Algorithm","DAE"));
assert(same_eigs(e_kron, e_fb,  1e-6), "Kron と Feedback の固有値が一致しない")
assert(same_eigs(e_kron, e_dae, 1e-6), "Kron と DAE の固有値が一致しない")


%% IEEE14 equilibrium is stable
% 回転不変性による 0 固有値を除き、すべての固有値の実部が負
e = eig_finite(net.get_sys("Algorithm","Kron"));
assert(max(real(e)) < 1e-6, "不安定な固有値がある: " + max(real(e)))
assert(sum(abs(e) < 1e-6) <= 1)


%% Non unit bus
% B007 を機器のない母線として扱う (旧 Task9)
sys_all = net.get_sys("Algorithm","Kron");
sys_nu  = net.get_sys("Algorithm","Kron", "NonUnit", 7);
assert(isa(sys_nu, "ss"))
assert(size(sys_nu.A,1) <= size(sys_all.A,1))
assert(same_eigs(eig_finite(sys_nu), eig_finite(net.get_sys("Algorithm","Feedback","NonUnit",7)), 1e-6))


%% Bus without components
% 機器の無い母線 (build_9bus の B004, B007, B009) があっても変数マップ・線形化ができる
n9 = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() n9.initialize);
assert(iscell(n9.a_Bus{4}.a_Component) && isempty(n9.a_Bus{4}.a_Component))
tab = n9.a_Bus{4}.get_variable_map();
assert(isequal(tab.Kind, ["Vre";"Vim"]))
tab = n9.get_variable_map();
assert(nnz(tab.Bus == string(n9.a_Bus{4}.str_tag)) == 2)
res = DebugScript.helper.quiet(@() n9.linearize);
assert(isa(res, "LinearizationResult"))
n_x9 = sum(cellfun(@(b) sum(cellfun(@(c) numel(c.sv_x), b.a_Component)), n9.a_Bus));
e_kron = eig_finite(n9.get_sys("Algorithm","Kron"));
assert(size(n9.get_sys("Algorithm","Kron").A, 1) == n_x9)
assert(same_eigs(e_kron, eig_finite(n9.get_sys("Algorithm","DAE")), 1e-6))


%% With local controllers
% AVR/PSS を付けると制御器の状態が加わる (旧 Task15)
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 3 + 3)
assert(max(real(eig_finite(sys))) < 1e-6)


%% With global controller
net = new_net();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 1)
assert(same_eigs(eig_finite(sys), eig_finite(net.get_sys("Algorithm","Feedback")), 1e-6))
% 大域制御器の状態: Kron / DAE は先頭、Feedback は末尾 (v3 と同じ。get_ss の help)
res = net.linearize();
sv_K = string(res.get_ss("Kron").StateName);
sv_D = string(res.get_ss("DAE").StateName);
sv_F = string(res.get_ss("Feedback").StateName);
n_gc = numel(net.a_GlobalController{1}.sv_x);
assert(all(contains(sv_K(1:n_gc), net.a_GlobalController{1}.str_tag)), strjoin(sv_K(1:n_gc), ","))
assert(isequal(sv_D(1:n_gc), sv_K(1:n_gc)))
assert(isequal(sv_F(end-n_gc+1:end), sv_K(1:n_gc)), strjoin(sv_F(end-n_gc+1:end), ","))


%% odeLinearizer constructor of v3 names the remedy
% v3 の odeLinearizer(net, NonUnit, ...) は削除: 解法は既定値だけを持つ (net.solver_LIN)
try
    odeLinearizer(net, [], "Algorithm", "Kron");
    error("DebugScript:NoError", "odeLinearizer(net, ...) がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:Deprecated:OdeLinearizerConstructor", ME.identifier)
    assert(contains(ME.message, "net.linearize"))
end
assert(isa(odeLinearizer(), "odeLinearizer"))
assert(isa(net.solver_LIN, "odeLinearizer"))


%% Analytic jacobians match numerical differentiation
% get_sys と odeSimulator が使う f_Jacobi* (Jacobi_dx / Jacobi_I / Jacobi_Y) が f_dx, f_I, f_Y の微分と一致する
for key = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-impedance","load-power"]
    [net3, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net3.initialize);
    err = DebugScript.helper.jacobian_error(comp);
    assert(err < 1e-6, key + ": Jacobian error " + err)
end
net = new_net();
gen = net.a_Bus{1}.a_Component{1};
gen.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr2", kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
con = {gen.a_LocalController{1}, gen.a_LocalController{1}.a_LocalController{1}, ...
       net.a_Bus{2}.a_Component{1}.a_LocalController{1}, net.a_GlobalController{1}};
for k = 1:numel(con)
    err = DebugScript.helper.jacobian_error(con{k});
    assert(err < 1e-6, class(con{k}) + ": Jacobian error " + err)
end


%% Each component type gives same eigenvalues in three algorithms
% 3 母線系統で機器の種類ごとに get_sys を求める (B001: gen-park, B002 または B003: 指定した機器)
for key = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-impedance","load-power"]
    [net3, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net3.initialize);
    sys = net3.get_sys("Algorithm","Kron");
    n_x3 = sum(cellfun(@(b) sum(cellfun(@(cc) numel(cc.sv_x), b.a_Component)), net3.a_Bus));
    assert(size(sys.A,1) == n_x3, key)
    e = eig_finite(sys);
    assert(same_eigs(e, eig_finite(net3.get_sys("Algorithm","Feedback")), 1e-6), key + ": Kron と Feedback の固有値が一致しない")
    assert(same_eigs(e, eig_finite(net3.get_sys("Algorithm","DAE")),      1e-6), key + ": Kron と DAE の固有値が一致しない")
end


%% Local and global controllers in three algorithms
% AVR (ST1, DC1)・PSS・AGC を付けたときも 3 方式の固有値が一致し、IEEE14 は安定
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr2", kap=20));
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1]));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 3 + 3 + 4 + 1)
e = eig_finite(sys);
assert(max(real(e)) < 1e-6)
assert(same_eigs(e, eig_finite(net.get_sys("Algorithm","Feedback")), 1e-6))
assert(same_eigs(e, eig_finite(net.get_sys("Algorithm","DAE")),      1e-6))
sys = net.get_sys("Algorithm","DAE");
assert(numel(sys.StateName) == size(sys.A,1))


%% Two global controllers in three algorithms
% 大域制御器が複数でも 3 方式の固有値が一致し、状態は制御器の数だけ増える
net = new_net();
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc1", "SG1B001"));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc2", "SG1B002", "SG1B003", kI=200));
DebugScript.helper.quiet(@() net.initialize);
sys = net.get_sys("Algorithm","Kron");
assert(size(sys.A,1) == n_x + 2)
str_x = string(sys.StateName);
assert(numel(str_x) == size(sys.A,1) && any(contains(str_x,"agc1")) && any(contains(str_x,"agc2")))
e = eig_finite(sys);
assert(max(real(e)) < 1e-6)
assert(same_eigs(e, eig_finite(net.get_sys("Algorithm","Feedback")), 1e-6))
assert(same_eigs(e, eig_finite(net.get_sys("Algorithm","DAE")),      1e-6))

% 制御対象を系統の順と逆に並べても同じ系になる (端子は名前で対応付ける)
netA = new_net();
netA.add_global_controller(controller.agc.broadcast_PI_AGC(netA, "agc", "SG1B001", "SG1B002", alpha=[2;1], beta=[1;3]));
netB = new_net();
netB.add_global_controller(controller.agc.broadcast_PI_AGC(netB, "agc", "SG1B002", "SG1B001", alpha=[1;2], beta=[3;1]));
DebugScript.helper.quiet(@() netA.initialize);
DebugScript.helper.quiet(@() netB.initialize);
eA = eig_finite(netA.get_sys("Algorithm","Feedback"));
for alg = ["Kron","Feedback","DAE"]
    assert(same_eigs(eA, eig_finite(netB.get_sys("Algorithm",alg)), 1e-6), alg + ": 制御対象の順で固有値が変わる")
end
assert(same_eigs(eA, eig_finite(netA.get_sys("Algorithm","Kron")), 1e-6))


%% Non unit choice does not remain on the bus
% NonUnit を指定した後に指定なしで呼ぶと、元の結果に戻る
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
sys1 = net.get_sys("Algorithm","Feedback");
net.get_sys("Algorithm","Feedback","NonUnit",[7,9]);
sys2 = net.get_sys("Algorithm","Feedback");
assert(isequal(size(sys1.A), size(sys2.A)))
assert(same_eigs(eig_finite(sys1), eig_finite(sys2), 1e-9))


%% Linearize matches v3 get_sys matrices for every algorithm
% linearize + get_ss の行列と名前は v3 の odeLinearizer と同じ (helper.linearize_v3 に v3 のコードを保存)。
% 違いは DAE の B の代数方程式の行の符号だけ (v3 は入力 u の符号が逆で、Kron と伝達関数が合わなかった)
nets = {};  nonunit = {};
nets{end+1} = new_net();  nonunit{end+1} = [];
nets{end+1} = new_net();  nonunit{end+1} = [7, 9];
n4 = new_net();
n4.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
n4.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr2", kap=20));
n4.add_global_controller(controller.agc.broadcast_PI_AGC(n4, "agc", n4.a_Bus{1}.a_Component{1}, n4.a_Bus{2}.a_Component{1}, alpha=[1;1], beta=[1;1]));
n4.add_global_controller(controller.agc.broadcast_PI_AGC(n4, "agc2", "SG1B003", kI=200));
nets{end+1} = n4;  nonunit{end+1} = [];
for key = ["gen-1axis","gen-droop","load-impedance"]
    nets{end+1} = DebugScript.helper.build_3bus(key);  nonunit{end+1} = []; %#ok<SAGROW>
end
for k = 1:numel(nets)
    DebugScript.helper.quiet(@() nets{k}.initialize);
    res = nets{k}.linearize("NonUnit", nonunit{k});
    for alg = ["Kron","Feedback","DAE"]
        s_new = res.get_ss(alg);
        s_old = DebugScript.helper.linearize_v3(nets{k}, nonunit{k}, alg);
        str = nets{k}.str_tag + " " + alg;
        B_old = s_old.B;
        if alg == "DAE"
            n_x = size(res.rm_Axx,1);
            B_old(n_x+1:end,:) = -B_old(n_x+1:end,:);
        end
        assert(isequal(size(s_new.A), size(s_old.A)), str)
        tol = 1e-10 * max(1, norm(s_old.A, 1));
        assert(norm(s_new.A - s_old.A, 1) <= tol && norm(s_new.E - s_old.E, 1) <= tol, str + ": A, E")
        assert(norm(s_new.B - B_old, 1) <= tol && norm(s_new.C - s_old.C, 1) <= tol && norm(s_new.D - s_old.D, 1) <= tol, str + ": B, C, D")
        assert(isequal(s_new.StateName, s_old.StateName) && isequal(s_new.InputName, s_old.InputName) && ...
               isequal(s_new.OutputName, s_old.OutputName), str + ": names")
        % net.get_sys は linearize + get_ss と同じ
        assert(isequal(nets{k}.get_sys("Algorithm", alg, "NonUnit", nonunit{k}), s_new), str + ": get_sys")
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
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002"));
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
str_gc = net.a_GlobalController{1}.str_tag;
assert(any(tab.Owner == str_gc) && all(tab.Bus(tab.Owner == str_gc) == "") && isequal(tab.Label(c_idxGC{1}), tab.Label(tab.Owner == str_gc)))
% 制御器の状態は機器の直後 (AVR, その下の PSS の順)
iv = find(tab.Bus == "B001" & tab.Kind == "x");
avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(isequal(tab.Owner(iv), [repmat("SG1B001",numel(net.a_Bus{1}.a_Component{1}.sv_x),1); ...
                               repmat(avr.str_tag,numel(avr.sv_x),1); repmat(avr.a_LocalController{1}.str_tag,numel(avr.a_LocalController{1}.sv_x),1)]))
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
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr2", kap=20));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002"));
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


%% Point at a perturbed state
% 平衡点からずらした点では、その点の x, V, u で各機器の Jacobian を評価する。モデルと解法は変わらない
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
[tab, c_idxBus] = net.get_variable_map();
res0 = net.linearize();
x = res0.rv_point;
gen  = net.a_Bus{2}.a_Component{1};
iv_x = find(tab.Owner == gen.str_tag & tab.Kind == "x");
iv_V = find(tab.Bus == "B002" & (tab.Kind == "Vre" | tab.Kind == "Vim"));
iv_u = find(tab.Owner == gen.str_tag & tab.Kind == "u");
x(iv_x(1)) = x(iv_x(1)) + 0.2;            % delta
x(iv_V)    = x(iv_V) * 1.03;
x(iv_u(1)) = x(iv_u(1)) + 0.1;
xe = gen.rv_Xequilibrium;
res1 = net.linearize("Point", x);
assert(isequal(gen.rv_Xequilibrium, xe) && isempty(net.solver_LIN.Point), "モデルまたは解法が変わった")
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
    xj = x(tab.Owner == cj.str_tag & tab.Bus == "B002" & tab.Kind == "x");
    uj = x(tab.Owner == cj.str_tag & tab.Bus == "B002" & tab.Kind == "u");
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
    assert(ME.identifier == "GUILDA:odeLinearizer:PointSize", ME.identifier)
    assert(contains(ME.message, "get_variable_map"))
end
try
    net.linearize("Point", "equilibrium");
    error("DebugScript:NoError", "文字列の Point がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:odeLinearizer:PointType", ME.identifier)
end


%% Point from a simulation result and a time
% Point={sim, t}: 時刻 t の機器の状態・入力と母線電圧 (odeSimulationResult の値) で線形化する
net = new_net();
DebugScript.helper.quiet(@() net.initialize);
ev  = odeEventSet("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = net.simulate([0,1.5], ev);
r   = sim.odeResults;
tab = net.get_variable_map();
k   = find(r.t > 0.8, 1);
t   = r.t(k);
x   = zeros(height(tab),1);
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    x(tab.Bus == bus.str_tag & tab.Kind == "Vre") = r.Bus(i).V{k,1};
    x(tab.Bus == bus.str_tag & tab.Kind == "Vim") = r.Bus(i).V{k,2};
    for j = 1:numel(bus.a_Component)
        c = bus.a_Component{j};
        x(tab.Owner == c.str_tag & tab.Bus == bus.str_tag & tab.Kind == "x") = r.Bus(i).Component(j).X{k,:};
        x(tab.Owner == c.str_tag & tab.Bus == bus.str_tag & tab.Kind == "u") = r.Bus(i).Component(j).U{k,:};
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
iv_x = tab.Owner == gen.str_tag & tab.Kind == "x";
assert(norm(sc.A - res.rm_Axx(iv_x,iv_x), 1) < 1e-10)
sb  = net.a_Bus{1}.get_sys("Point", {sim, t});
assert(norm(sb.A - sc.A, 1) == 0)
% 範囲外の時刻
try
    net.linearize("Point", {sim, 10});
    error("DebugScript:NoError", "範囲外の時刻がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:odeSimulationResult:PointTime", ME.identifier)
end
% Point={sim, t, Side}: 第 3 要素は sim.get_point の Side
assert(isequal(net.linearize("Point", {sim, t, "before"}).rv_point, res.rv_point))
try
    net.linearize("Point", {sim, t, "middle"});
    error("DebugScript:NoError", "知らない Side がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:odeLinearizer:PointType", ME.identifier)
end


%% Point from a simulation with controllers at an equilibrium time
% 局所制御器 (AVR + PSS, AVR) と大域制御器 (AGC) の状態も結果に入るので、外乱のない
% シミュレーションの途中の時刻で線形化すると既定 (平衡点) と同じ行列になる
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr2", kap=20));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002"));
DebugScript.helper.quiet(@() net.initialize);
sim  = net.simulate([0,1]);
res0 = net.linearize();
res1 = net.linearize("Point", {sim, 0.5});
tab  = res0.tab_variable;
assert(~res1.output.l_equilibrium && height(res1.tab_variable) == height(tab))
avr1 = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
sv_con = [avr1.str_tag, avr1.a_LocalController{1}.str_tag, net.a_Bus{2}.a_Component{1}.a_LocalController{1}.str_tag, ...
          net.a_GlobalController{1}.str_tag];
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
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B002", "SG1B006", kP=100, kI=500));   % SG1B001, SG1B003 は AGC の外
DebugScript.helper.quiet(@() net.initialize);
ev  = odeEventSet("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
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
for str = [avr1.str_tag, avr1.a_LocalController{1}.str_tag, net.a_GlobalController{1}.str_tag]
    iv = tab.Owner == str;
    assert(norm(x(iv) - res0.rv_point(iv)) > 1e-6, str + " の状態が平衡点のまま")
end
% 制御器のない発電機: その点での f_JacobiDx / f_JacobiI
gen  = net.a_Bus{3}.a_Component{1};
iv_x = find(tab.Owner == gen.str_tag & tab.Kind == "x");
iv_V = find(tab.Bus == "B003" & (tab.Kind == "Vre" | tab.Kind == "Vim"));
iv_u = find(tab.Owner == gen.str_tag & tab.Kind == "u");
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
s_before = net.solver_LIN.get_options();
res = net.linearize("Algorithm", "Kron", "NonUnit", 7);
assert(isequal(net.solver_LIN.get_options(), s_before))
assert(res.options.Algorithm == "Kron" && isequal(res.options.NonUnit, 7))
assert(isequal(res.get_ss(), res.get_ss("Kron")))
% 既定値の変更は残る
n_x = size(res.rm_Axx,1);
net.solver_LIN.Algorithm = "DAE";
assert(size(net.get_sys().A,1) > n_x)
net.solver_LIN.Algorithm = "Feedback";
% 知らない名前は受け付ける名前を示すエラー
try
    net.linearize("Methd", "Kron");
    error("DebugScript:NoError", "知らない名前がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:resolve_options:UnknownName", ME.identifier)
end
% 存在しない母線番号
try
    net.linearize("NonUnit", 99);
    error("DebugScript:NoError", "存在しない NonUnit がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:odeLinearizer:NonUnit", ME.identifier)
end


%% Get sys returns sys, flag and output
% v4: [sys, flag, output] = net.get_sys(...) (v3 の 2 番目の出力 lin は flag になった)。
% v3 と同じ名前の引数 (NonUnit, Algorithm) はそのまま使える
[sys, flag, output] = net.get_sys("Algorithm", "Kron", "NonUnit", []);
assert(isa(sys, "ss") && islogical(flag) && flag)
assert(isa(output.result, "LinearizationResult") && isequal(output.result.get_ss(), sys))
assert(isstring(output.message))


%% Linearization result Plot
res = net.linearize();
ax = res.Plot();
assert(isa(ax, "matlab.graphics.axis.Axes"))
close(ancestor(ax, "figure"))
ax = res.Plot("Algorithm", "Feedback");
close(ancestor(ax, "figure"))


%% Hessian is not supported by default
% Hessian は機器・制御器のクラスごとの任意の解析。定義していないクラスはクラス名を示すエラー
net = new_net();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001"));
DebugScript.helper.quiet(@() net.initialize);
obj = {net.a_Bus{1}.a_Component{1}, net.a_Bus{1}.a_Component{1}.a_LocalController{1}, net.a_GlobalController{1}};
str_id = ["GUILDA:Component:HessianNotSupported", "GUILDA:LocalController:HessianNotSupported", "GUILDA:GlobalController:HessianNotSupported"];
for k = 1:numel(obj)
    try
        obj{k}.get_hessian();
        error("DebugScript:NoError", class(obj{k}) + ".get_hessian がエラーにならない")
    catch ME
        assert(ME.identifier == str_id(k), ME.identifier)
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
    assert(ME.identifier == "GUILDA:Component:HessianNotSupported" && contains(ME.message, "Hessian_I"), ME.identifier)
end
