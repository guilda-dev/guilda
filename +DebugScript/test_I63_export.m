% Issue 63: result.export は拡張子を検査し、制御器の状態も書き出す (simulate の Export オプションは廃止)
%
% 実行: runtests("DebugScript.test_I63_export")  または  DebugScript.run_all("Features","I63")

% 共通設定 (各テストの前に毎回実行される)
% AVR を 2 台の発電機に付ける (タグは発電機ごとに自動で付く)
net = DebugScript.helper.build_ieee14();
avr1 = net.a_Bus{1}.a_Component{1}.add_local_controller("avr-ST1");
pss1 = net.a_Bus{1}.a_Component{1}.add_local_controller("pss-PSS1");
avr2 = net.a_Bus{2}.a_Component{1}.add_local_controller("avr-ST1");
agc  = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
DebugScript.helper.quiet(@() net.initialize);
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.1,0.15], "FaultBus", "B008");
s_dir = tempname;  mkdir(s_dir);
c_dir = onCleanup(@() rmdir(s_dir, "s"));
tab_ctrl = net.get_variable_map();
tab_ctrl = tab_ctrl(ismember(tab_ctrl.Owner, [avr1.s_tag, pss1.s_tag, avr2.s_tag, agc.s_tag]) & tab_ctrl.Kind == "x", :);


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Invalid file name stops the export
sol = net.simulate(ev.s_tag, Time=[0,0.2]);
c_case = {"a.json", "a", "", 'a.json', ".csv.bak"};
for k = 1:numel(c_case)
    try
        sol.export(fullfile(s_dir, c_case{k}));
        error("DebugScript:noError", "エラーにならない: %d", k)
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:ResultODE:ExportFormat", ME.message)
    end
end
assert(isempty(dir(s_dir + "/*.*")) || all([dir(s_dir).isdir]), "ファイルを書いた")
% simulate の Export オプションは廃止
try
    net.simulate(ev.s_tag, Time=[0,0.2], Export=true);
    error("DebugScript:noError", "Export を受け付けた")
catch ME
    assert(DebugScript.helper.msg_id(ME) ~= "DebugScript:noError", ME.message)
end


%% Every format of export is accepted and written
sol = net.simulate(ev.s_tag, Time=[0,0.2]);
for s_ext = [".csv", ".CSV", ".txt", ".xlsx", ".xls", ".mat"]
    s_file = fullfile(s_dir, "accepted" + s_ext);
    assert(sol.export(s_file) == s_file)
    assert(isfile(s_file), s_file)
    delete(s_file)
end
% 名前を省くと既定の名前で現在のフォルダに書く
s_old = cd(s_dir);
c_back = onCleanup(@() cd(s_old));
sol.export();
assert(numel(dir("*_simulation.csv")) == 1)
delete("*_simulation.csv")


%% Table has the controller states, by Label, after the existing columns
sol = net.simulate(ev.s_tag, Time=[0,0.2]);
s_csv = sol.export(fullfile(s_dir, "sim.csv"));
tab = readtable(s_csv, "VariableNamingRule", "preserve");
sv  = string(tab.Properties.VariableNames);
assert(height(tab) == numel(sol.rv_t))
assert(numel(unique(sv)) == numel(sv))
n_out = height(sol.tab_output);
assert(isequal(sv(end-n_out-height(tab_ctrl)+1:end-n_out), tab_ctrl.Label'))
% 出力 y, yc の列 (tab_output の Label) が最後
assert(isequal(sv(end-n_out+1:end), sol.tab_output.Label'))
for k = 1:height(tab_ctrl)
    rv = sol.rm_variable(:, tab_ctrl.Index(k));
    assert(max(abs(tab.(tab_ctrl.Label(k)) - rv)) < 1e-10, tab_ctrl.Label(k))
end
% 既存の列はそのまま
assert(sv(1) == "t" && any(sv == "B001SG1_omega") && any(sv == "B008_Q"))
assert(max(abs(tab.B001SG1_omega - sol.odeResults.Bus(1).Component(1).X.omega)) < 1e-10)


%% Network without controllers keeps its columns
net0 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net0.initialize);
sol0 = net0.simulate(DebugScript.helper.no_disturbance(net0), Time=[0,0.1]);
tab0 = readtable(sol0.export(fullfile(s_dir, "sim0.csv")), "VariableNamingRule", "preserve");
n_bus = numel(net0.a_Bus);
n_comp = 0;
for i = 1:n_bus
    for j = 1:numel(sol0.odeResults.Bus(i).Component)
        c = sol0.odeResults.Bus(i).Component(j);
        if isfield(c, "X")
            n_comp = n_comp + width(c.X) + width(c.U) + width(c.I);   % I: Ireal, Iimag of the component
        end
    end
end
assert(width(tab0) == 1 + 6*n_bus + n_comp + height(sol0.tab_output))


%% MAT file has the controller states
sol = net.simulate(ev.s_tag, Time=[0,0.2]);
s_mat = sol.export(fullfile(s_dir, "sim.mat"));
s = load(s_mat);
assert(isequal(s.rm_variable, sol.rm_variable) && isequal(s.tab_variable, sol.tab_variable))
assert(isequal(s.odeResults.t, sol.odeResults.t) && s.flag == sol.flag)
assert(all(ismember(tab_ctrl.Label, s.tab_variable.Label)))
assert(isequaln(s.rm_output, sol.rm_output) && isequal(s.tab_output, sol.tab_output))
