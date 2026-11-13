% F45 時間応答の機器ごとの電流 (ResultODE.rm_Icomponent)
%
%   res = net.simulate(tag);
%   res.rm_Icomponent                          % n_t x 2 n_component: 機器ごとの Ireal, Iimag
%   res.odeResults.Bus(i).Component(j).I       % 同じ値の table [Ireal, Iimag]
%
% 列は sv_bus / c_component の順 (母線ごと、母線内は機器の順)。値は各機器の f_I を出力時刻で
% 評価したもの (母線へ流れ込む向きが正)。解列中は NaN。
% 母線の機器電流の和は rm_I (Y V) と、ソルバーの許容誤差 (電流の釣り合いの残差) の範囲で一致する。
% 地絡中の地絡母線では rm_I が地絡電流も含むため一致しない。
% 1e-9 で比べるため、和の確認は Tolerance = AbsoluteTolerance = 1e-10 で計算する。
%
% 実行: runtests("DebugScript.test_F45_ode_component_current")  または  DebugScript.run_all("Features","F45")

c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% IEEE9bus: the sum of the component currents of each bus equals rm_I
% B007 の地絡 [1, 1.05] と B002 の発電機の解列 [1.5, 2]
net = ieee9();
sc = net.add_scenario("f", Time=[0, 2.5]);
sc.add_fault("B007", [1, 1.05]);
s_gen = net.a_Bus{2}.a_Component{1}.s_tag;
sc.add_trip(s_gen, [1.5, 2]);
r = net.simulate("f", Tolerance=1e-10, AbsoluteTolerance=1e-10);
n_comp = numel(vertcat(r.c_component{:}));
assert(isequal(size(r.rm_Icomponent), [numel(r.rv_t), 2*n_comp]))
% 解列中だけ NaN
j_gen = component_index(r, s_gen);
lv_trip = r.rv_t > 1.5 & r.rv_t < 2;
lv_nan  = any(isnan(r.rm_Icomponent(:, 2*j_gen - 1 + (0:1))), 2);
assert(all(lv_nan(lv_trip)) && ~any(lv_nan(r.rv_t < 1.5 | r.rv_t > 2)), "解列中だけ NaN でない")
assert(~any(isnan(r.rm_Icomponent(:, setdiff(1:2*n_comp, 2*j_gen - 1 + (0:1)))), "all"))
% 母線ごとの和 (NaN は 0) と rm_I。地絡中の B007 は除く
E = abs(bus_sum(r) - r.rm_I);
i_f = find(r.sv_bus == "B007");
lv_fault = r.rv_t >= 1 & r.rv_t <= 1.05;
E(lv_fault, 2*i_f - 1 + (0:1)) = 0;
assert(max(E, [], "all") < 1e-9, "機器電流の和と rm_I の差 %.3g", max(E, [], "all"))
% 地絡中の B007 では rm_I に地絡電流が入る
assert(max(abs(bus_sum(r) - r.rm_I), [], "all") > 1e-3)


%% A generator's current is its own f_I at a sample
net = ieee9();
sc = net.add_scenario("f", Time=[0, 2]);
sc.add_fault("B007", [1, 1.05]);
r = net.simulate("f");
gen = net.a_Bus{2}.a_Component{1};
tab = r.tab_variable;
iv_x = find(tab.Owner == gen.s_tag & tab.Kind == "x");
iv_u = find(tab.Owner == gen.s_tag & tab.Kind == "u");
iv_V = find(ismember(tab.Kind, ["Vre","Vim"]) & tab.Bus == "B002");
j = component_index(r, gen.s_tag);
for k = [1, find(r.rv_t > 1.02, 1), find(r.rv_t > 1.5, 1), numel(r.rv_t)]
    tp = r.rv_t(k) - phase_start(r.rv_t(k));          % 区間の始まりからの時刻 (ソルバーと同じ)
    I  = gen.f_I(tp, r.rm_variable(k, iv_x).', r.rm_variable(k, iv_V).', r.rm_variable(k, iv_u).');
    assert(isequal(r.rm_Icomponent(k, 2*j - 1 + (0:1)), [real(I), imag(I)]), "t = %g の電流が f_I と違う", r.rv_t(k))
end
% Format="struct" の機器電流と同じ (解列なし)
s = net.simulate("f", Format="struct");
sc_gen = s.a_Bus{2}.a_Component{1};
assert(isequal(sc_gen.I{:,:}, r.rm_Icomponent(:, 2*j - 1 + (0:1))))


%% The view field, the export and the output times of SampleTime
% IEEE9bus の B008 の地絡 [1, 1.05] と B002 の発電機の解列 [1.5, 1.7]、出力時刻は SampleTime
% (Tutorial3bus は定電力負荷 (load-power) のため地絡でも解列でも整合な初期値が得られない)
net = ieee9();
sc = net.add_scenario("f", Time=[0, 2]);
sc.add_fault("B008", [1, 1.05]);
sc.add_trip("B002SG1", [1.5, 1.7]);
r = net.simulate("f", SampleTime=0.01, Tolerance=1e-10, AbsoluteTolerance=1e-10);
o = r.odeResults;
k = 0;
for i = 1:numel(o.Bus)
    for jj = 1:numel(r.c_component{i})
        k = k + 1;
        T = o.Bus(i).Component(jj).I;
        assert(istable(T) && isequal(string(T.Properties.VariableNames), ["Ireal","Iimag"]))
        assert(isequaln(T{:,:}, r.rm_Icomponent(:, 2*k - 1 + (0:1))))
    end
end
% 和の確認 (地絡中の B008 を除く)。区間の境目 (同じ時刻が 2 回) を含む
assert(nnz(diff(r.rv_t) == 0) == 4)
E = abs(bus_sum(r) - r.rm_I);
i_f = find(r.sv_bus == "B008");
E(r.rv_t >= 1 & r.rv_t <= 1.05, 2*i_f - 1 + (0:1)) = 0;
assert(max(E, [], "all") < 1e-9, "機器電流の和と rm_I の差 %.3g", max(E, [], "all"))
% 解列中の発電機は NaN
assert(all(isnan(o.Bus(2).Component(1).I{r.rv_t > 1.5 & r.rv_t < 1.7, :}), "all"))
% export の表に <機器>_Ireal, <機器>_Iimag の列 (母線の電流と同じ名前の付け方)
s_file = string(tempname) + ".csv";
c_del = onCleanup(@() delete(s_file));
r.export(s_file);
tab_csv = readtable(s_file);
sv_col = string(tab_csv.Properties.VariableNames);
assert(all(ismember(["B002_Ireal","B002_Iimag","B002SG1_Ireal","B002SG1_Iimag"], sv_col)), strjoin(sv_col, ", "))
v = tab_csv.B002SG1_Ireal;
lv = ~isnan(v);
assert(max(abs(v(lv) - r.rm_Icomponent(lv, 3))) < 1e-12)


%% A result without component currents has NaN columns
% sct_sol に rm_Icomponent がない ResultODE (直接作る場合) は NaN で埋める
net = ieee9();
r = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,0.1]));
sct_sol = struct("rv_t", r.rv_t, "rm_variable", r.rm_variable, "rm_I", r.rm_I, "rv_phase", ones(numel(r.rv_t), 1));
sct_dae = struct("tab_variable", r.tab_variable, "c_comp", {cell(0,1)}, "c_lc", {cell(0,1)}, "c_gc", {cell(0,1)});
r0 = ResultODE(sct_sol, sct_dae, struct(net, false), struct("flag", 1));
assert(isequal(size(r0.rm_Icomponent), size(r.rm_Icomponent)) && all(isnan(r0.rm_Icomponent), "all"))
assert(all(isnan(r0.odeResults.Bus(2).Component(1).I{:,:}), "all"))


function net = ieee9()
% 初期化した IEEE9bus
    net = network.IEEE9bus;
    DebugScript.helper.quiet(@() net.initialize);
end

function j = component_index(r, s_tag)
% rm_Icomponent での機器の番号 (sv_bus / c_component の順)
    j = find(vertcat(r.c_component{:}) == s_tag);
end

function S = bus_sum(r)
% 母線ごとの機器電流の和 (NaN は 0): rm_I と同じ並び
    n_b = cellfun(@numel, r.c_component);
    iv_bus = repelem((1:numel(n_b)).', n_b);
    Ic = r.rm_Icomponent;
    Ic(isnan(Ic)) = 0;
    S = zeros(size(r.rm_I));
    for j = 1:numel(iv_bus)
        iv = 2*iv_bus(j) - 1 + (0:1);
        S(:, iv) = S(:, iv) + Ic(:, 2*j - 1 + (0:1));
    end
end

function t1 = phase_start(t)
% 「A generator's current」の計算の区間の始まり (地絡 [1, 1.05]、時刻 t は区間の内側)
    rv_b = [0, 1, 1.05];
    t1 = rv_b(find(rv_b <= t, 1, "last"));
end
