% F8 補助機能 (アドミタンス行列 / info / draw_diagram / CSV 入出力 / 系統テンプレート)
%
% 実行: runtests("DebugScript.test_F8_utilities")  または  DebugScript.run_all("Features","F8")

% 共通設定 (各テストの前に毎回実行される)
str_templates = ["IEEE14bus","IEEE14bus_NoTap","IEEE14bus_lossless","Ishizaki6Bus","TEST31bus","Txt3Bus","Tutorial3bus"];


%% Admittance matrix is symmetric and matches branch data
net = DebugScript.helper.build_9bus();
tab_Y = net.get_admittance_matrix;

% 行・列名は母線タグ
assert(istable(tab_Y) && isequal(string(tab_Y.Properties.RowNames), string(net.a_Bus)))
Y = tab_Y.Variables;

% 位相器のない系統では対称行列
assert(norm(Y - Y.', "fro") < 1e-12)

% 送電線定数から組み立てた行列と一致 (π 型: 直列 1/(R+jX)、両端に jC)
Y_ref = zeros(9);
for k = 1:numel(net.a_Branch)
    br = net.a_Branch{k};
    p  = br.tab_parameter.dynamics;
    [~, ij] = ismember(string(br.a_Bus), string(net.a_Bus));
    y = 1/(p.R + 1j*p.X);
    Y_ref(ij,ij) = Y_ref(ij,ij) + [y + 1j*p.C, -y; -y, y + 1j*p.C] ./ [p.tap^2, p.tap; p.tap, 1];
end
assert(norm(Y - Y_ref, "fro") < 1e-10)

% 非対角成分は送電線の get_admittance_matrix の非対角成分
Y45 = net.a_Branch{4}.get_admittance_matrix;
assert(abs(tab_Y{"B004","B005"} - Y45(1,2)) < 1e-12)


%% Admittance matrix includes bus shunts
net = PowerNetwork();
net.add_bus("Gshunt", 0.01, "Bshunt", 0.2);
net.add_bus();
net.add_branch("pi", [1,2], "X", 0.5);
Y = net.get_admittance_matrix.Variables;
assert(abs(Y(1,1) - (1/(0.5j) + 0.01 + 0.2j)) < 1e-12)
assert(abs(sum(Y(2,:))) < 1e-12)          % シャントのない母線は行和 0


%% Info prints summary
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
txt = evalc("net.info");
assert(contains(txt, "Total Buses: 14"))
assert(contains(txt, "Total Branches: " + numel(net.a_Branch)))
assert(contains(txt, "SG1B001"))

% 表示する項目は選べる
txt = evalc("net.info(""parameter"", false, ""equilibrium"", false)");
assert(contains(txt, "Total Buses: 14"))


%% Draw diagram
% 図は非表示で作成して閉じる
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
fig = figure("Visible", "off");
c   = onCleanup(@() close(fig));
ax  = axes(fig);
G   = DebugScript.helper.quiet(@() net.draw_diagram(ax));
assert(isa(G, "DrawerNetDiagram"))
assert(~isempty(ax.Children))


%% CSV export import round trip
% CSV に書き出して読み込むと同じ系統になる
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
str_dir = tempname;  mkdir(str_dir);
c = onCleanup(@() rmdir(str_dir, "s"));

% フォルダ名が @ で始まるとクラスファイルも書き出す
str_path = net.export_csv(fullfile(str_dir, "@RoundTrip14"));
assert(all(isfolder(fullfile(str_path, ["network","bus","branch","component"]))))
assert(isfile(fullfile(str_path, "RoundTrip14.m")))
assert(contains(fileread(fullfile(str_path, "RoundTrip14.m")), "PowerNetwork.import_csv(str_dirpath, Network=obj)"))

net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path));
assert(isa(net2, "PowerNetwork") && string(net2.str_tag) == "RoundTrip14")
assert(numel(net2.a_Bus) == numel(net.a_Bus) && numel(net2.a_Branch) == numel(net.a_Branch))
n_comp = @(n) sum(cellfun(@(b) numel(b.a_Component), n.a_Bus));
assert(n_comp(net2) == n_comp(net))
assert(norm(net2.get_admittance_matrix.Variables - net.get_admittance_matrix.Variables, "fro") < 1e-10)
assert(norm(net2.cv_Vequilibrium - net.cv_Vequilibrium) < 1e-8)
assert(isequal(cellfun(@(b) b.l_isSlack, net2.a_Bus), cellfun(@(b) b.l_isSlack, net.a_Bus)))

% クラスファイルを使うとフォルダがそのまま系統クラスになる
addpath(str_dir);
c_path = onCleanup(@() rmpath(str_dir));
net3 = DebugScript.helper.quiet(@() feval("RoundTrip14"));
assert(isa(net3, "PowerNetwork") && norm(net3.cv_Vequilibrium - net.cv_Vequilibrium) < 1e-8)
clear c_path

% 母線の baseMVA は廃止: 書き出さず、読み込み時は列があっても無視する (テンプレートの CSV には残っている)
tab_bus = readtable(fullfile(str_path, "bus", "parameter.csv"));
assert(~ismember("baseMVA", string(tab_bus.Properties.VariableNames)))
tab_bus.baseMVA = repmat(50, height(tab_bus), 1);
writetable(tab_bus, fullfile(str_path, "bus", "parameter.csv"));
net3 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path));
assert(norm(net3.cv_Vequilibrium - net.cv_Vequilibrium) < 1e-8)
assert(~ismember("baseMVA", string(net3.a_Bus{1}.tab_parameter.operation.Properties.VariableNames)))
assert(net3.tab_parameter.base.baseMVA == 100 && net3.tab_parameter.base.Hz == GUILDA.config("Model","Hz"))

% 同じフォルダへの再出力は Overwrite 指定が必要
assert(error_id(@() net.export_csv(str_path)) == "GUILDA:export_csv:FolderExists")
% Overwrite は前回の機器フォルダを消してから書き出す (古い機器が残らない)
mkdir(fullfile(str_path, "component", "gen-classical"));
net.export_csv(str_path, Overwrite=true);
assert(~isfolder(fullfile(str_path, "component", "gen-classical")))
% @ で始まらないフォルダにはクラスファイルを書かない
str_plain = net.export_csv(fullfile(str_dir, "Plain14"));
assert(isempty(dir(fullfile(str_plain, "*.m"))))
assert(error_id(@() PowerNetwork.import_csv(fullfile(str_dir, "NoSuchFolder"))) == "GUILDA:import_csv:NotFound")


%% CSV round trip keeps Hz baseMVA and the slack bus
% 系統の Hz と baseMVA は network/parameter.csv に保存され、読み込むと戻る
net = PowerNetwork("Base2Bus");
net.add_bus();  net.add_bus("V", 1.02);
net.add_branch("pi", [1,2], "X", 0.2);
net.a_Bus{1}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{2}.add_component("gen-park");
net.tab_parameter.base.Hz      = 50;
net.tab_parameter.base.baseMVA = 250;
DebugScript.helper.quiet(@() set_slack(net.a_Bus{2}));
str_dir = tempname;  mkdir(str_dir);
c = onCleanup(@() rmdir(str_dir, "s"));
str_path = net.export_csv(fullfile(str_dir, "Base2Bus"));
tab_net  = readtable(fullfile(str_path, "network", "parameter.csv"));
assert(isequal(string(tab_net.Properties.VariableNames), ["Hz","baseMVA"]) && height(tab_net) == 1)
assert(tab_net.Hz == 50 && tab_net.baseMVA == 250)

net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
assert(net2.tab_parameter.base.Hz == 50 && net2.tab_parameter.base.baseMVA == 250)
assert(net2.a_Bus{2}.l_isSlack && ~net2.a_Bus{1}.l_isSlack)
assert(net2.a_Bus{1}.a_Component{1}.r_Hz == 50)

% network/parameter.csv の無い古いフォルダ・値が NaN の列は既定値 (GUILDA.config の Hz, 100 MVA)
writetable(table(nan, 300, 'VariableNames', ["Hz","baseMVA"]), fullfile(str_path, "network", "parameter.csv"));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
assert(net2.tab_parameter.base.Hz == GUILDA.config("Model","Hz") && net2.tab_parameter.base.baseMVA == 300)
rmdir(fullfile(str_path, "network"), "s");
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
assert(net2.tab_parameter.base.Hz == GUILDA.config("Model","Hz") && net2.tab_parameter.base.baseMVA == 100)

% Network= で既存の系統へ追加できる (母線番号は CSV の行番号)
net3 = PowerNetwork("Host");
net3.add_bus();
net3.a_Bus{1}.add_component("load-power");
out  = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Network=net3, Initialize=false));
assert(out == net3 && numel(net3.a_Bus) == 3 && numel(net3.a_Branch) == 1)
assert(isequal(string(net3.a_Branch{1}.a_Bus(:)).', string(net3.a_Bus(2:3)).'))


%% CSV round trip keeps transformer tap and phase
% export は tap/phase の列名で書き出し、import はその列 (と Tap/Phase) を読む
net = PowerNetwork("Tap2Bus");
net.add_bus();  net.add_bus();
net.add_branch("pi_transformer", [1,2], "X",0.2, "Tap",0.95, "Phase",5/180*pi);
net.a_Bus{1}.add_component("gen-park");
net.a_Bus{2}.add_component("load-power", "P",-0.5, "Q",-0.1);
str_dir = tempname;  mkdir(str_dir);
c = onCleanup(@() rmdir(str_dir, "s"));
str_path = net.export_csv(fullfile(str_dir, "@Tap2Bus"));
str_csv  = fullfile(str_path, "branch", "parameter.csv");
tab_bra  = readtable(str_csv);
assert(all(ismember(["tap","phase"], string(tab_bra.Properties.VariableNames))))

get_tp = @(n) n.a_Branch{1}.tab_parameter.dynamics{1,["tap","phase"]};
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
assert(max(abs(get_tp(net2) - [0.95, 5/180*pi])) < 1e-12)
assert(norm(net2.get_admittance_matrix.Variables - net.get_admittance_matrix.Variables, "fro") < 1e-12)

% 列名 Tap/Phase でも読める
writetable(renamevars(tab_bra, ["tap","phase"], ["Tap","Phase"]), str_csv);
net3 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
assert(max(abs(get_tp(net3) - [0.95, 5/180*pi])) < 1e-12)

% 両方の綴りがあるとエラー
tab_bra.Tap = tab_bra.tap;
writetable(tab_bra, str_csv);
assert(error_id(@() PowerNetwork.import_csv(str_path, Initialize=false)) == "GUILDA:import_csv:DuplicateColumns")

% 同梱の IEEE14bus の変圧器タップが読み込まれる
net = DebugScript.helper.quiet(@() network.IEEE14bus);
str_bus = string(net.a_Bus(:)).';
r_tap = @(f,t) net.a_Branch{cellfun(@(b) isequal(string(b.a_Bus(:)).', str_bus([f t])), net.a_Branch)}.tab_parameter.dynamics.tap;
assert(isequal([r_tap(4,7), r_tap(4,9), r_tap(5,6)], [0.978, 0.969, 0.932]))


%% Deprecated CsvNetHandler wrappers
% v3 の CsvNetHandler.import / export は警告を出して新しい API を呼ぶ
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
str_dir = tempname;  mkdir(str_dir);
c = onCleanup(@() rmdir(str_dir, "s"));
clear Deprecated
lastwarn("");
str_path = DebugScript.helper.quiet(@() CsvNetHandler.export(net, "Old14", "savepath", str_dir, "version", 3));
[~, id] = lastwarn();
assert(id == "GUILDA:Deprecated:CsvNetHandlerExport", id)
assert(str_path == fullfile(str_dir, "@Old14") && isfile(fullfile(str_path, "Old14.m")))
assert(contains(fileread(fullfile(str_path, "Old14.m")), "ver = 3"))
assert(isfile(fullfile(str_path, "network", "parameter.csv")))
% 既存フォルダは Overwrite が必要
assert(error_id(@() CsvNetHandler.export(net, "Old14", "savepath", str_dir)) == "GUILDA:export_csv:FolderExists")

lastwarn("");
net2 = DebugScript.helper.quiet(@() CsvNetHandler.import(str_path));
[~, id] = lastwarn();
assert(id == "GUILDA:Deprecated:CsvNetHandlerImport", id)
assert(norm(net2.cv_Vequilibrium - net.cv_Vequilibrium) < 1e-8)
% 既存の系統へ読み込む v3 の形 (系統クラスのコンストラクタで使っていた形)
net3 = PowerNetwork();
out  = DebugScript.helper.quiet(@() CsvNetHandler.import(str_path, net3, "Initialize", false));
assert(out == net3 && numel(net3.a_Bus) == 14)


%% MATPOWER import reproduces case14
% import_matpower は tools.network_to_mpc の逆変換 (MATPOWER 不要)。
% case14 を読み込んで mpc に戻すと元のデータになり、潮流計算・OPF は network.IEEE14bus と一致する。
mpc14 = DebugScript.helper.case14_data();
net   = DebugScript.helper.quiet(@() PowerNetwork.import_matpower(mpc14));
assert(numel(net.a_Bus) == 14 && numel(net.a_Branch) == 20)
assert(net.tab_parameter.base.baseMVA == 100 && net.tab_parameter.base.Hz == GUILDA.config("Model","Hz"))
assert(net.a_Bus{1}.l_isSlack && sum(cellfun(@(b) b.l_isSlack, net.a_Bus)) == 1)
assert(all(isfinite(net.cv_Vequilibrium)))                  % Initialize=true が既定

mpc = tools.network_to_mpc(net);
for str_f = ["bus","gen","branch","gencost"]
    assert(isequal(size(mpc.(str_f)), size(mpc14.(str_f))), str_f)
    assert(max(abs(mpc.(str_f) - mpc14.(str_f)), [], "all") < 1e-12, str_f)
end

% 機器: 発電機は gen-park (既定)、負荷は load-power で P, Q は消費が負
gen = net.a_Bus{2}.a_Component{1};
ld  = net.a_Bus{2}.a_Component{2};
assert(isa(gen, "component.generator.park") && isa(ld, "component.load.power"))
assert(isnan(gen.tab_parameter.powerflow.Q) && abs(gen.tab_parameter.powerflow.P - 0.4) < 1e-15)
assert(max(abs(ld.tab_parameter.powerflow{1,["P","Q"]} - [-0.217, -0.127])) < 1e-15)
assert(abs(net.a_Bus{9}.tab_parameter.dynamics.Bshunt - 0.19) < 1e-15)
assert(isempty(net.a_Bus{7}.a_Component))                   % 負荷も発電機も無い母線
str_type = string(cellfun(@(b) b.key, net.a_Branch, "UniformOutput", false));
assert(sum(str_type == "pi_transformer") == 3 && sum(str_type == "pi") == 17)

% 潮流計算は network.IEEE14bus と一致
ref = DebugScript.helper.quiet(@() network.IEEE14bus);
r1  = DebugScript.helper.quiet(@() ref.calculate_powerflow);
[r2, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(flag > 0)
assert(max(abs(r2.tab_bus.V - r1.tab_bus.V)) < 1e-8 && max(abs(r2.tab_bus.Varg - r1.tab_bus.Varg)) < 1e-8)
% OPF は MATPOWER の case14 の最適値 (8081.53 $/hr)
[res, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF", Tolerance=1e-10));
assert(flag > 0 && abs(res.r_cost - 8081.53) < 0.01, sprintf("AC cost %.4f", res.r_cost))

% 入力の形: 関数ハンドル・ケースファイル・オプション
net = DebugScript.helper.quiet(@() PowerNetwork.import_matpower(@DebugScript.helper.case14_data, ...
          GeneratorModel="gen-classical", Hz=50, Tag="My14", Initialize=false));
assert(string(net.str_tag) == "My14" && net.tab_parameter.base.Hz == 50)
assert(isa(net.a_Bus{1}.a_Component{1}, "component.generator.classical"))
str_dir = tempname;  mkdir(str_dir);
c = onCleanup(@() rmdir(str_dir, "s"));
writelines(["function mpc = mycase14()", "mpc = DebugScript.helper.case14_data();", "end"], fullfile(str_dir, "mycase14.m"));
net = DebugScript.helper.quiet(@() PowerNetwork.import_matpower(fullfile(str_dir, "mycase14.m"), Initialize=false));
assert(string(net.str_tag) == "mycase14" && numel(net.a_Bus) == 14)
assert(~contains(path, str_dir))                            % 一時的に追加したパスは戻す
assert(error_id(@() PowerNetwork.import_matpower("no_such_case_xyz")) == "GUILDA:import_matpower:CaseNotFound")

% 停止中の発電機・送電線は読み込まない。CSV を経由しても同じ mpc に戻る
mpc_off = mpc14;
mpc_off.branch(16, 11) = 0;
net = DebugScript.helper.quiet(@() PowerNetwork.import_matpower(mpc_off, Initialize=false));
assert(numel(net.a_Branch) == 19)
str_path = net.export_csv(fullfile(str_dir, "Csv14"));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
mpc2 = tools.network_to_mpc(net2);
assert(max(abs(mpc2.bus - mpc14.bus), [], "all") < 1e-12 && max(abs(mpc2.gen - mpc14.gen), [], "all") < 1e-12)


%% MATPOWER import rejects unsupported gencost
mpc = DebugScript.helper.case14_data();
% 区分線形の費用 (MODEL = 1) はエラー
mpc_pw = mpc;
mpc_pw.gencost(2,:) = [1 0 0 2 0 0 100];          % MODEL = 1 (区分線形)
assert(error_id(@() PowerNetwork.import_matpower(mpc_pw, Initialize=false)) == "GUILDA:import_matpower:Unsupported")
% 3 次以上の多項式もエラー
mpc_cu = mpc;
mpc_cu.gencost = [mpc_cu.gencost(:,1:3), 4*ones(5,1), [1; zeros(4,1)], mpc_cu.gencost(:,5:7)];
assert(error_id(@() PowerNetwork.import_matpower(mpc_cu, Initialize=false)) == "GUILDA:import_matpower:Unsupported")
% 定数項は落として警告 (最適解は同じ)
mpc_c0 = mpc;
mpc_c0.gencost(1,7) = 10;
lastwarn("");
net = DebugScript.helper.quiet(@() PowerNetwork.import_matpower(mpc_c0, Initialize=false));
[~, id] = lastwarn();
assert(id == "GUILDA:import_matpower:ConstantCost", id)
assert(net.a_Bus{1}.a_Component{1}.tab_parameter.OPF.fP == 2000)
% 1 次の費用 (NCOST = 2) と Q の費用の行 (2*ng 行)
mpc_q = mpc;
mpc_q.gencost = [mpc.gencost; repmat([2 0 0 2 3 0 0], 5, 1)];
net = DebugScript.helper.quiet(@() PowerNetwork.import_matpower(mpc_q, Initialize=false));
opf = net.a_Bus{1}.a_Component{1}.tab_parameter.OPF;
assert(opf.HQ == 0 && opf.fQ == 300)
% version 1 の mpc と孤立母線は対象外
mpc_v1 = mpc;  mpc_v1.version = '1';
assert(error_id(@() PowerNetwork.import_matpower(mpc_v1)) == "GUILDA:import_matpower:Unsupported")
mpc_iso = mpc;  mpc_iso.bus(14,2) = 4;
assert(error_id(@() PowerNetwork.import_matpower(mpc_iso)) == "GUILDA:import_matpower:Unsupported")


%% Template IEEE14bus
net = DebugScript.helper.quiet(@() network.IEEE14bus);
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(numel(net.a_Bus) == 14 && numel(net.a_Branch) == 20 && flag > 0)
DebugScript.helper.quiet(@() net.initialize);
assert(all(isfinite(net.cv_Vequilibrium)))


%% IEEE14bus generator limits are numbers
% 発電機の出力制限は数値 (-Inf を含む) であり NaN ではないはず
net = DebugScript.helper.quiet(@() network.IEEE14bus);
for i = 1:numel(net.a_Bus)
    for j = 1:numel(net.a_Bus{i}.a_Component)
        op = net.a_Bus{i}.a_Component{j}.tab_parameter.operation;
        assert(~any(isnan(op{1,["Pmin","Pmax","Qmin","Qmax"]})), string(net.a_Bus{i}.a_Component{j}) + " の出力制限が NaN")
    end
end


%% Template IEEE14bus_NoTap differs from IEEE14bus only in the taps
% IEEE14bus_NoTap は IEEE14bus (case14) の変圧器 4-7, 4-9, 5-6 のタップを 1 にした系統
net = DebugScript.helper.quiet(@() network.IEEE14bus_NoTap);
ref = DebugScript.helper.quiet(@() network.IEEE14bus);
assert(numel(net.a_Bus) == 14 && numel(net.a_Branch) == 20)
assert(all(cellfun(@(b) b.tab_parameter.dynamics.tap, net.a_Branch) == 1))
assert(all(cellfun(@(b) b.tab_parameter.dynamics.phase, net.a_Branch) == 0))

% アドミタンス行列が変わるのは 3 台の変圧器の要素だけ: 非対角と、タップ側 (from) の対角
% (two_winding_transformer のタップは from 側だけに掛かる)
D = net.get_admittance_matrix.Variables - ref.get_admittance_matrix.Variables;
l_tr = false(14);
for ij = [4 7; 4 9; 5 6]'
    l_tr(ij(1), ij(1)) = true;
    l_tr(ij(1), ij(2)) = true;
    l_tr(ij(2), ij(1)) = true;
end
assert(all(D(~l_tr) == 0))
assert(all(abs(D(l_tr)) > 1e-3))

% 母線・機器のデータは IEEE14bus と同じ (base は系統の値を見せるだけの view なので除く)
data = @(o) o.tab_parameter(:, setdiff(string(o.tab_parameter.Properties.VariableNames), "base"));
for i = 1:14
    assert(isequaln(data(net.a_Bus{i}), data(ref.a_Bus{i})))
    for j = 1:numel(ref.a_Bus{i}.a_Component)
        assert(isequaln(data(net.a_Bus{i}.a_Component{j}), data(ref.a_Bus{i}.a_Component{j})))
    end
end

% 参照値 (このブランチで計算した値)
net.solver_ODE.Progress = "none";
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(flag > 0)
V_ref = [1.06 1.045 1.01 1.0294893 1.0348827 1.07 1.0558758 1.09 1.0496724 1.045822 1.0542952 1.0546926 1.0494854 1.0315436]';
assert(max(abs(res.tab_bus.V - V_ref)) < 1e-6)
res = DebugScript.helper.quiet(@() net.optimize_powerflow(Method="AC OPF"));
assert(abs(res.r_cost - 8079.9528) < 1e-2)
DebugScript.helper.quiet(@() net.initialize);
e = eig(net.get_sys("Algorithm","Kron").A);
e = e(abs(e) > 1e-6);
assert(abs(max(real(e)) - (-0.5297416)) < 1e-6)


%% Template IEEE14bus_lossless
% IEEE14bus_lossless は IEEE14bus (case14) の全ブランチの抵抗 R を 0 にした系統
% (線路の充電容量・母線シャント・変圧器タップはそのまま)
net = DebugScript.helper.quiet(@() network.IEEE14bus_lossless);
ref = DebugScript.helper.quiet(@() network.IEEE14bus);
assert(numel(net.a_Bus) == 14 && numel(net.a_Branch) == 20)
assert(all(cellfun(@(b) b.tab_parameter.dynamics.R, net.a_Branch) == 0))

% R 以外のブランチのデータと、母線・機器のデータは IEEE14bus と同じ
data = @(o) o.tab_parameter(:, setdiff(string(o.tab_parameter.Properties.VariableNames), "base"));
for i = 1:20
    d = net.a_Branch{i}.tab_parameter.dynamics;  dr = ref.a_Branch{i}.tab_parameter.dynamics;
    assert(isequaln(removevars(d, "R"), removevars(dr, "R")))
    assert(net.a_Branch{i}.key == ref.a_Branch{i}.key)
end
for i = 1:14
    assert(isequaln(data(net.a_Bus{i}), data(ref.a_Bus{i})))
    for j = 1:numel(ref.a_Bus{i}.a_Component)
        assert(isequaln(data(net.a_Bus{i}.a_Component{j}), data(ref.a_Bus{i}.a_Component{j})))
    end
end

% アドミタンス行列は純虚数、有効電力の損失は 0
Y = net.get_admittance_matrix.Variables;
assert(all(real(Y(:)) == 0))
net.solver_ODE.Progress = "none";
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow); tab = res.tab_bus;
assert(flag > 0)
assert(abs(sum(tab.P)) < 1e-8)

% 参照値 (このブランチで計算した値)
V_ref = [1.06 1.045 1.01 1.0325439 1.031804 1.07 1.0695736 1.09 1.0652518 1.0616713 1.0640645 1.0636242 1.0617756 1.056307]';
assert(max(abs(tab.V - V_ref)) < 1e-6)
DebugScript.helper.quiet(@() net.initialize);
e = eig(net.get_sys.A);
e = e(abs(e) > 1e-6);
assert(abs(max(real(e)) - (-0.594552)) < 1e-5)
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = DebugScript.helper.quiet(@() net.simulate([0,3], ev));
assert(sol.odeResults.t(end) == 3)


%% Template Ishizaki6Bus
% 注意: Ishizaki6Bus はコンストラクタで branch/parameter.csv をリポジトリ内に書き出す
net = DebugScript.helper.quiet(@() network.Ishizaki6Bus);
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(numel(net.a_Bus) == 6 && flag > 0)
DebugScript.helper.quiet(@() net.initialize);
assert(all(isfinite(net.cv_Vequilibrium)))


%% Template TEST31bus
net = DebugScript.helper.quiet(@() network.TEST31bus);
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(numel(net.a_Bus) == 31 && flag > 0)
DebugScript.helper.quiet(@() net.initialize);
assert(all(isfinite(net.cv_Vequilibrium)))


%% Template Txt3Bus
net = DebugScript.helper.quiet(@() network.Txt3Bus);
[~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(numel(net.a_Bus) == 3 && flag > 0)
DebugScript.helper.quiet(@() net.initialize);
assert(all(isfinite(net.cv_Vequilibrium)))


%% Template Tutorial3bus
% Tutorial3bus はコンストラクタ内で initialize まで行う
net = DebugScript.helper.quiet(@() network.Tutorial3bus);
assert(numel(net.a_Bus) == 3)
assert(all(isfinite(net.cv_Vequilibrium)) && abs(net.a_Bus{1}.c_Vequilibrium) > 0)


%% Template IEEE9bus keeps the v2 data
% network.IEEE9bus は v2 の IEEE9bus_past (archive/IEEE9bus_past) の CSV を変換したもの
net = DebugScript.helper.quiet(@() network.IEEE9bus);
assert(numel(net.a_Bus) == 9 && numel(net.a_Branch) == 9)
assert(net.tab_parameter.base.Hz == 60 && net.a_Bus{1}.l_isSlack)
check_v2_network(net, fullfile(fileparts(which("network.IEEE9bus")), "..", "archive", "IEEE9bus_past"))

% 潮流計算は Anderson & Fouad (Fig. 2.18, 丸めた値) の WSCC 9 母線の潮流解と一致
net.solver_ODE.Progress = "none";
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);  tab = res.tab_bus;
assert(flag > 0)
V_lit   = [1.04 1.025 1.025 1.026 0.996 1.013 1.026 1.016 1.032]';
deg_lit = [0 9.3 4.7 -2.2 -4.0 -3.7 3.7 0.7 2.0]';
assert(max(abs(tab.V - V_lit)) < 1e-3)
assert(max(abs(rad2deg(tab.Varg) - deg_lit)) < 0.05)
assert(abs(tab.P(1) - 0.716) < 1e-3)

DebugScript.helper.quiet(@() net.initialize);
e = DebugScript.helper.finite_eigs(net.get_sys("Algorithm","Kron"));
e = e(abs(e) > 1e-6);
assert(abs(max(real(e)) - (-0.0069046)) < 1e-6)     % AVR・PSS 付きで安定
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = DebugScript.helper.quiet(@() net.simulate([0,3], ev));
assert(sol.odeResults.t(end) == 3)
Vfd = sol.odeResults.Bus(1).Component(1).U.Vfield;     % AVR が動作する
assert(max(Vfd) - min(Vfd) > 1e-3)

% LocalController=false では AVR・PSS を付けない
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=false));
assert(all(cellfun(@(b) isempty(b.a_Component) || isempty(b.a_Component{1}.a_LocalController), net.a_Bus)))


%% Template IEEE68bus keeps the v2 data
% network.IEEE68bus は v2 の IEEE68bus (archive/IEEE68bus) の CSV を変換したもの
% (B. Pal and B. Chaudhuri, Robust Control in Power Systems, pp. 171-178)
net = DebugScript.helper.quiet(@() network.IEEE68bus);
assert(numel(net.a_Bus) == 68 && numel(net.a_Branch) == 83)
assert(net.tab_parameter.base.Hz == 60 && net.a_Bus{16}.l_isSlack)
check_v2_network(net, fullfile(fileparts(which("network.IEEE68bus")), "..", "archive", "IEEE68bus"))

% v2 の CSV には潮流解が無いので、参照値はこのブランチで計算した値
net.solver_ODE.Progress = "none";
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);  tab = res.tab_bus;
assert(flag > 0)
assert(abs(tab.P(16) - 33.7953168) < 1e-6 && abs(sum(tab.P) - 1.6683168) < 1e-6)
assert(abs(min(tab.V) - 0.8366601) < 1e-6 && abs(rad2deg(tab.Varg(39)) - (-39.290156)) < 1e-5)

DebugScript.helper.quiet(@() net.initialize);
e = DebugScript.helper.finite_eigs(net.get_sys("Algorithm","Kron"));
e = e(abs(e) > 1e-6);
assert(abs(max(real(e)) - (-0.0051275)) < 1e-6)     % AVR・PSS 付きで安定
ev  = odeEventSet("fault", net, "TimeSpan", [0.2,0.25], "FaultBus", "B030");
sol = DebugScript.helper.quiet(@() net.simulate([0,1], ev, TimeLimit=Inf));
assert(sol.odeResults.t(end) == 1)


% ---- local functions ----
function check_v2_network(net, old_dir)
% net のデータが v2 (network.build) の CSV フォルダ old_dir の値と同じかを調べる
    tb = readtable(fullfile(old_dir, "bus.csv"), "TextType", "string");
    tr = readtable(fullfile(old_dir, "branch.csv"));
    tg = readtable(fullfile(old_dir, "generator_1axis.csv"), "TextType", "string");
    ta = readtable(fullfile(old_dir, "avr_sadamoto2019.csv"));
    tp = readtable(fullfile(old_dir, "pss.csv"));

    % 母線: 電圧の設定値とシャント
    for i = 1:height(tb)
        pf = net.a_Bus{i}.tab_parameter.powerflow;  dy = net.a_Bus{i}.tab_parameter.dynamics;
        assert(pf.V == tb.V_abs(i) && dy.Gshunt == tb.G_shunt(i) && dy.Bshunt == tb.B_shunt(i))
    end
    % ブランチ: tap 0 は pi、それ以外は pi_transformer (v2 の y は片端の値 = C)
    for k = 1:height(tr)
        br = net.a_Branch{k};  d = br.tab_parameter.dynamics;
        assert(isequal(string(br.a_Bus{1}), string(net.a_Bus{tr.bus_from(k)})) && ...
               isequal(string(br.a_Bus{2}), string(net.a_Bus{tr.bus_to(k)})))
        assert(d.R == tr.x_real(k) && d.X == tr.x_imag(k) && d.C == tr.y(k))
        if tr.tap(k) == 0
            assert(br.key == "pi")
        else
            assert(br.key == "pi_transformer" && d.tap == tr.tap(k) && d.phase == tr.phase(k))
        end
    end
    % 機器: 発電機 (gen-1axis, AVR_ST1, PSS1) と負荷 (load-impedance)
    for i = 1:height(tb)
        a_comp = net.a_Bus{i}.a_Component;
        switch string(tb.SetClass(i))
            case "generator_1axis"
                gen = a_comp{1};  g = tg(tg.ID == tb.ID(i), :);
                assert(numel(a_comp) == 1 && gen.key == "gen-1axis")
                p = gen.tab_parameter.dynamics;
                assert(isequal(p{1,["M","D","Xd","Xq","Xd_p","Td_p"]}, g{1,["M","D","Xd","Xq","Xd_p","Td_p"]}))
                if ~ismember(string(tb.type(i)), ["slack","1"])
                    assert(gen.tab_parameter.powerflow.P == tb.P_gen(i))
                end
                avr = gen.a_LocalController{1};  pss = avr.a_LocalController{1};
                assert(isa(avr, "controller.avr.AVR_ST1") && isa(pss, "controller.pss.PSS1"))
                a  = ta(ta.ID == g.ID, :);   q  = tp(tp.ID == g.ID, :);
                pa = avr.tab_parameter.dynamics;  pp = pss.tab_parameter.dynamics;
                assert(pa.kap == a.Ka && pa.tap == a.Te && pa.ttr == 0 && pa.kst == 0 && pa.tst == 0)
                % v2 の PSS は Kpss/Tpss * Tpss*s/(1+Tpss*s) * ... なので kpss = Kpss/Tpss
                assert(abs(pp.kpss - q.Kpss/q.Tpss) < 1e-12 && pp.tWS == q.Tpss)
                assert(pp.tn1 == q.TL1p && pp.td1 == q.TL1 && pp.tn2 == q.TL2p && pp.td2 == q.TL2)
            case "load_impedance"
                assert(numel(a_comp) == 1 && a_comp{1}.key == "load-impedance")
                pf = a_comp{1}.tab_parameter.powerflow;
                assert(pf.P == -tb.P_load(i) && pf.Q == -tb.Q_load(i))
            otherwise
                assert(isempty(a_comp))
        end
    end
end


function id = error_id(fcn)
% fcn を実行し、エラーの ID を返す (エラーにならなければ "")
    id = "";
    try
        DebugScript.helper.quiet(fcn);
    catch ME
        id = string(ME.identifier);
    end
end

function set_slack(bus)
    bus.l_isSlack = true;
end
