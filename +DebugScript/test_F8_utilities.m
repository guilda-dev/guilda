% F8 補助機能 (アドミタンス行列 / info / draw_diagram / CSV 入出力 / 系統テンプレート)
%
% 実行: runtests("DebugScript.test_F8_utilities")  または  DebugScript.run_all("Features","F8")

% 共通設定 (各テストの前に毎回実行される)
str_templates = ["IEEE14bus","IEEE14bus_lossless","Ishizaki6Bus","TEST31bus","Txt3Bus","Tutorial3bus"];


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
% CSV に書き出して読み込むと同じ系統になる (保存先を指定してダイアログを出さない)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
str_dir = tempname;  mkdir(str_dir);
c = onCleanup(@() rmdir(str_dir, "s"));

str_path = CsvNetHandler.export(net, "RoundTrip14", "savepath", str_dir);
assert(isfolder(fullfile(str_path, "bus")) && isfolder(fullfile(str_path, "branch")) && isfolder(fullfile(str_path, "component")))
assert(isfile(fullfile(str_path, "RoundTrip14.m")))

net2 = DebugScript.helper.quiet(@() CsvNetHandler.import(str_path));
assert(numel(net2.a_Bus) == numel(net.a_Bus) && numel(net2.a_Branch) == numel(net.a_Branch))
n_comp = @(n) sum(cellfun(@(b) numel(b.a_Component), n.a_Bus));
assert(n_comp(net2) == n_comp(net))
assert(norm(net2.get_admittance_matrix.Variables - net.get_admittance_matrix.Variables, "fro") < 1e-10)
assert(norm(net2.cv_Vequilibrium - net.cv_Vequilibrium) < 1e-8)

% 同じフォルダへの再出力は Overwrite 指定が必要
try
    CsvNetHandler.export(net, "RoundTrip14", "savepath", str_dir);
    error("DebugScript:noError", "既存フォルダへの出力がエラーにならない")
catch ME
    assert(ME.identifier ~= "DebugScript:noError", ME.message)
end


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


%% Template IEEE14bus_lossless
net = DebugScript.helper.quiet(@() network.IEEE14bus_lossless);
[tab, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(numel(net.a_Bus) == 14 && flag > 0)
% 抵抗 0 の系統なので有効電力の損失は 0
assert(all(cellfun(@(b) b.tab_parameter.dynamics.R, net.a_Branch) == 0))
assert(abs(sum(tab.P)) < 1e-8)
DebugScript.helper.quiet(@() net.initialize);


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
