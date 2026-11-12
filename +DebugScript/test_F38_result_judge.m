% F38 シミュレーションの結果 (ResultODE): 判定、出力 y、系統を読まないこと
%
%   result  = net.simulate([0,5], sc);
%   verdict = result.judge_out_of_step();                 % "stable" / "out-of-step" / "incomplete"
%   verdict = result.judge_out_of_step(Reference="COI", Threshold=180);
%   result.tab_output, result.rm_output                   % 機器と制御器の出力 (y, yc) の軌道
%
% ResultODE はデータ (軌道、変数の表、出力の関数、系統のスナップショット sct_network) から作られ、
% 系統を参照しない。判定 judge_out_of_step はスナップショットからスラック母線と慣性 M を読む。
% 判定の節は F31 から移した (旧 Scenario.out_of_step, sc.judge)。
%
% 実行: runtests("DebugScript.test_F38_result_judge")  または  DebugScript.run_all("Features","F38")

% 各テストは新しい系統で始める (共通設定の handle はテストの間で共有されるため)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Default judge: stable and out-of-step on IEEE9bus
n9 = network.IEEE9bus;
DebugScript.helper.quiet(@() n9.initialize);
short = Scenario("short", Time=[0,5]);
short.add_fault("B007", [1,1.05]);
long  = Scenario("long", Time=[0,5]);
long.add_fault("B007", [1,1.5]);
n9.add_scenario({short, long});
[r_short, f_short] = DebugScript.helper.quiet(@() n9.simulate(short));
v = r_short.judge_out_of_step();
assert(f_short == 1 && v.Verdict == "stable" && isnan(v.Time) && isempty(v.Units), v.Verdict)
assert(v.Reference == "B001SG1" && v.Threshold == 360 && v.MaxAngle < 360)

ws = warning("off", "all");  c_ws = onCleanup(@() warning(ws));
r_long = DebugScript.helper.quiet(@() n9.simulate(long));
clear c_ws
v = r_long.judge_out_of_step();
assert(v.Verdict == "out-of-step" && v.Time > 1 && ~isempty(v.Units) && v.MaxAngle > 360, v.Verdict)

% 基準: 重心 (COI) と機器のタグ
v = r_short.judge_out_of_step(Reference="COI");
assert(v.Verdict == "stable" && v.Reference == "COI")
v = r_long.judge_out_of_step(Reference="B002SG1");
assert(v.Verdict == "out-of-step" && v.Reference == "B002SG1")
assert(error_id(@() r_short.judge_out_of_step(Reference="B001")) == "GUILDA:ResultODE:UnknownReference")
% しきい値を小さくすると短い地絡でも脱調と判定する
v = r_short.judge_out_of_step(Threshold=1);
assert(v.Verdict == "out-of-step")


%% Incomplete verdict and a judge function of the user
n9 = network.IEEE9bus;
DebugScript.helper.quiet(@() n9.initialize);
sc = Scenario("limit", Time=[0,5]);
sc.add_fault("B007", [1,1.05]);
n9.add_scenario(sc);
ws = warning("off", "all");  c_ws = onCleanup(@() warning(ws));
[res, flag] = DebugScript.helper.quiet(@() n9.simulate(sc, TimeLimit=1e-3));
clear c_ws
assert(flag == 0)
v = res.judge_out_of_step();
assert(v.Verdict == "incomplete" && isnan(v.Time), v.Verdict)
% 利用者の判定は結果の関数を直接呼ぶ
my_judge = @(r) struct("Verdict", "custom", "tEnd", r.output.tEnd);
v = my_judge(res);
assert(v.Verdict == "custom" && v.tEnd == res.output.tEnd)


%% Judge of a run stopped by StopOnOutOfStep (flag 2)
% flag = 2 の結果: 角が Threshold を超えていれば "out-of-step"、超えていなければ "incomplete"
n9 = network.IEEE9bus;
DebugScript.helper.quiet(@() n9.initialize);
sc = Scenario("long", Time=[0,5]);
sc.add_fault("B007", [1,1.5]);
n9.add_scenario(sc);
ws = warning("off", "all");  c_ws = onCleanup(@() warning(ws));
r = DebugScript.helper.quiet(@() n9.simulate(sc));
clear c_ws
v_full = r.judge_out_of_step();
assert(v_full.Verdict == "out-of-step")
assert(isempty(n9.a_GlobalController) && all(r.tab_variable.Kind ~= "uc"), "この節は制御器のない系統で、変数がすべて結果にある前提")
k_end = find(r.rv_t < v_full.Time, 1, "last");             % 脱調の前で止まった結果
r_before = from_data(r, n9, 1:k_end, 2);
v = r_before.judge_out_of_step();
assert(r_before.flag == 2 && v.Verdict == "incomplete" && isnan(v.Time) && v.MaxAngle < 360, v.Verdict)
r_after = from_data(r, n9, 1:find(r.rv_t >= v_full.Time, 1), 2);  % 脱調の後で止まった結果
v = r_after.judge_out_of_step();
assert(v.Verdict == "out-of-step" && v.Time == v_full.Time, v.Verdict)


%% The result works after the network is deleted
net = DebugScript.helper.build_ieee14();
for i = 1:2
    net.a_Bus{i}.a_Component{1}.add_local_controller("avr-ST1");
    net.a_Bus{i}.a_Component{1}.add_local_controller("pss-PSS1");
end
DebugScript.helper.quiet(@() net.initialize);
sc = Scenario("fault", Time=[0,2]);
sc.add_fault("B008", [1,1.05]);
net.add_scenario(sc);
r = net.simulate(sc);
v0 = r.judge_out_of_step();
v0c = r.judge_out_of_step(Reference="COI");
x0 = r.get_point(1.5);
s_net = net.s_tag;
delete(net);
assert(isempty(r.a_PowerNetwork) && r.s_network == s_net && r.sct_network.s_tag == s_net)
assert(isequaln(r.judge_out_of_step(), v0) && isequaln(r.judge_out_of_step(Reference="COI"), v0c))
assert(isequal(r.get_point(1.5), x0))
assert(height(r.odeResults.Bus(1).Component(1).X) == numel(r.rv_t))
s_dir = tempname;  mkdir(s_dir);  c_dir = onCleanup(@() rmdir(s_dir, "s"));
assert(isfile(r.export(fullfile(s_dir, "sim.csv"))) && isfile(r.export(fullfile(s_dir, "sim.mat"))))
fig = figure("Visible", "off");  c_fig = onCleanup(@() close(fig));
r.plot_trajectory(Quantity="omega");
assert(size(r.rm_output, 1) == numel(r.rv_t))


%% Outputs y of the components and controllers
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
net.add_global_controller("agc-PI", {net.a_Bus{1}.a_Component{1}, net.a_Bus{2}.a_Component{1}});
DebugScript.helper.quiet(@() net.initialize);
sc = Scenario("trip", Time=[0,4]);
sc.add_trip(net.a_GlobalController{1}.s_tag, [1, 2]);
sc.add_trip(net.a_Bus{2}.a_Component{1}.s_tag, [2.5, 3]);
net.add_scenario(sc);
r = net.simulate(sc);
[tab, ~] = net.get_variable_map();
assert(isequal(r.tab_output, tab(ismember(tab.Kind, ["y","yc"]), :)))
assert(isequal(size(r.rm_output), [numel(r.rv_t), height(r.tab_output)]))

% 機器の出力: 同じ時刻の f_Y(t, x, V) の値
gen = net.a_Bus{3}.a_Component{1};
lv_x = r.tab_variable.Owner == gen.s_tag & r.tab_variable.Kind == "x";
lv_V = r.tab_variable.Bus == "B003" & ismember(r.tab_variable.Kind, ["Vre","Vim"]);
lv_y = r.tab_output.Owner == gen.s_tag;
k = find(r.rv_t > 0.5, 1);
y = gen.f_Y(r.rv_t(k), r.rm_variable(k, lv_x).', r.rm_variable(k, lv_V).');
assert(any(lv_y) && max(abs(r.rm_output(k, lv_y) - y.')) < 1e-12)
% odeResults の Y (列は sv_y)
Y = r.odeResults.Bus(3).Component(1).Y;
assert(isequal(string(Y.Properties.VariableNames), reshape(string(gen.sv_y), 1, [])) && isequal(Y{:,:}, r.rm_output(:, lv_y)))
% 解列中の機器と GC の出力は NaN、それ以外は数
lv_g2 = r.tab_output.Owner == net.a_Bus{2}.a_Component{1}.s_tag;
lv_gc = r.tab_output.Owner == net.a_GlobalController{1}.s_tag;
lv_t1 = r.rv_t > 1 & r.rv_t < 2;
lv_t2 = r.rv_t > 2.5 & r.rv_t < 3;
assert(all(isnan(r.rm_output(lv_t1, lv_gc)), "all") && all(isnan(r.rm_output(lv_t2, lv_g2)), "all"))
lv_on = r.rv_t < 1 | (r.rv_t > 2 & r.rv_t < 2.5) | r.rv_t > 3;
assert(~any(isnan(r.rm_output(lv_on, :)), "all"))
% 制御器の出力 (AVR の Vfield) は定常で平衡点の値に近い
lv_avr = r.tab_output.Kind == "yc" & r.tab_output.Name == "Vfield";
assert(nnz(lv_avr) == 1 && all(isfinite(r.rm_output(r.rv_t < 1, lv_avr))))
% export: 表の最後に出力の列 (Label)、MAT に rm_output と tab_output
s_dir = tempname;  mkdir(s_dir);  c_dir = onCleanup(@() rmdir(s_dir, "s"));
tab_csv = readtable(r.export(fullfile(s_dir, "sim.csv")), "VariableNamingRule", "preserve");
sv = string(tab_csv.Properties.VariableNames);
assert(isequal(sv(end-height(r.tab_output)+1:end), reshape(r.tab_output.Label, 1, [])))
s = load(r.export(fullfile(s_dir, "sim.mat")));
assert(isequaln(s.rm_output, r.rm_output) && isequal(s.tab_output, r.tab_output))


%% Errors of the judge
n9 = network.IEEE9bus;
DebugScript.helper.quiet(@() n9.initialize);
r = DebugScript.helper.quiet(@() n9.simulate([0,0.1]));
% 回転子角 delta のない結果
lv_keep = r.tab_variable.Name ~= "delta";
sct_sol = struct("rv_t", r.rv_t, "rm_variable", r.rm_variable(:, lv_keep), "rm_I", r.rm_I, ...
                 "rv_phase", ones(numel(r.rv_t), 1));
sct_dae = struct("tab_variable", r.tab_variable(lv_keep, :), "c_comp", {cell(0,1)}, ...
                 "c_lc", {cell(0,1)}, "c_gc", {cell(0,1)});
r0 = ResultODE(sct_sol, sct_dae, struct(n9, false), struct("flag", 1));
assert(error_id(@() r0.judge_out_of_step()) == "GUILDA:ResultODE:NoRotorAngle")
% スラック母線に delta を持つ機器がない
sct_net = struct(n9, false);
for i = 1:numel(sct_net.a_Bus)
    sct_net.a_Bus{i}.l_isSlack = sct_net.a_Bus{i}.s_tag == "B005";   % 負荷の母線
end
r1 = ResultODE(struct("rv_t", r.rv_t, "rm_variable", r.rm_variable, "rm_I", r.rm_I, "rv_phase", ones(numel(r.rv_t), 1)), ...
               setfield(sct_dae, "tab_variable", r.tab_variable), sct_net, struct("flag", 1)); %#ok<SFLD>
assert(error_id(@() r1.judge_out_of_step()) == "GUILDA:ResultODE:NoSlackGenerator")


function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end

function r = from_data(r_full, net, iv_k, flag)
% 結果 r_full の時刻 iv_k だけの ResultODE を、データから作る (制御器のない系統: 変数はすべて結果にある)
    tab = net.get_variable_map();
    sct_sol = struct("rv_t", r_full.rv_t(iv_k), "rm_variable", r_full.rm_variable(iv_k, :), ...
                     "rm_I", r_full.rm_I(iv_k, :), "rv_phase", ones(numel(iv_k), 1));
    sct_dae = struct("tab_variable", tab(tab.Role == "variable", :), "c_comp", {cell(0,1)}, ...
                     "c_lc", {cell(0,1)}, "c_gc", {cell(0,1)});
    r = ResultODE(sct_sol, sct_dae, struct(net, false), struct("flag", flag, "output", r_full.output));
end
