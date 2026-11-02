% Issue 63: simulate の Export は拡張子を計算前に検査し、制御器の状態も書き出す
%
% 実行: runtests("DebugScript.test_I63_export")  または  DebugScript.run_all("Features","I63")

% 共通設定 (各テストの前に毎回実行される)
% 同じタグの AVR を 2 台の発電機に付ける (タグの重複は許されている)
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr"), controller.pss.PSS1("pss"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr"));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002"));
DebugScript.helper.quiet(@() net.initialize);
ev = ODEevent("fault", net, "TimeSpan", [0.1,0.15], "FaultBus", "B008");
str_dir = tempname;  mkdir(str_dir);
c_dir = onCleanup(@() rmdir(str_dir, "s"));
tab_ctrl = net.get_variable_map();
tab_ctrl = tab_ctrl(ismember(tab_ctrl.Owner, ["CAavr","CPpss","agc"]), :);


%% Invalid file name fails before the integration
% 終わらない長さの計算が一瞬で止まれば、積分の前に検査している
c_case = {"a.json", "a", "", 'a.json', strings(0,1), ".csv.bak"};
for k = 1:numel(c_case)
    t_start = tic;
    try
        net.simulate([0,1e6], Export=c_case{k}, TimeLimit=Inf);
        error("DebugScript:noError", "エラーにならない: %d", k)
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:SimulateExport", ME.message)
    end
    assert(toc(t_start) < 5, "計算前に止まっていない: %d", k)
end


%% Every format of Export is accepted and written
for str_ext = [".csv", ".CSV", ".txt", ".xlsx", ".xls", ".mat"]
    str_file = fullfile(str_dir, "accepted" + str_ext);
    net.simulate([0,0.2], ev, Export=str_file);
    assert(isfile(str_file), str_file)
    delete(str_file)
end
% Export=true も Export=false も従来どおり (true は既定の名前で現在のフォルダに書く)
str_old = cd(str_dir);
c_back = onCleanup(@() cd(str_old));
net.simulate([0,0.2], ev, Export=true);
assert(numel(dir("*_simulation.csv")) == 1)
delete("*_simulation.csv")
net.simulate([0,0.2], ev, Export=false);
assert(isempty(dir("*_simulation.csv")))


%% Table has the controller states, by Label, after the existing columns
sol = net.simulate([0,0.2], ev);
str_csv = sol.Export(fullfile(str_dir, "sim.csv"));
tab = readtable(str_csv, "VariableNamingRule", "preserve");
sv  = string(tab.Properties.VariableNames);
assert(height(tab) == numel(sol.rv_t))
assert(numel(unique(sv)) == numel(sv))
assert(isequal(sv(end-height(tab_ctrl)+1:end), tab_ctrl.Label'))
for k = 1:height(tab_ctrl)
    rv = sol.rm_variable(:, tab_ctrl.Index(k));
    assert(max(abs(tab.(tab_ctrl.Label(k)) - rv)) < 1e-10, tab_ctrl.Label(k))
end
% 既存の列はそのまま
assert(sv(1) == "t" && any(sv == "SG1B001_omega") && any(sv == "B008_Q"))
assert(max(abs(tab.SG1B001_omega - sol.odeResults.Bus(1).Component(1).X.omega)) < 1e-10)


%% Network without controllers keeps its columns
net0 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net0.initialize);
sol0 = net0.simulate([0,0.1]);
tab0 = readtable(sol0.Export(fullfile(str_dir, "sim0.csv")), "VariableNamingRule", "preserve");
n_bus = numel(net0.a_Bus);
n_comp = 0;
for i = 1:n_bus
    for j = 1:numel(sol0.odeResults.Bus(i).Component)
        c = sol0.odeResults.Bus(i).Component(j);
        if isfield(c, "X")
            n_comp = n_comp + width(c.X) + width(c.U);
        end
    end
end
assert(width(tab0) == 1 + 6*n_bus + n_comp)


%% MAT file has the controller states
sol = net.simulate([0,0.2], ev);
str_mat = sol.Export(fullfile(str_dir, "sim.mat"));
s = load(str_mat);
assert(isequal(s.rm_variable, sol.rm_variable) && isequal(s.tab_variable, sol.tab_variable))
assert(isequal(s.odeResults.t, sol.odeResults.t) && s.flag == sol.flag)
assert(all(ismember(tab_ctrl.Label, s.tab_variable.Label)))
