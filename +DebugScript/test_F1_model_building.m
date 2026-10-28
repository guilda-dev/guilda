% F1 モデル構築 (PowerNetwork / Bus / Branch / Component / Controller)
%
% 系統モデルを組み立てる API の使い方と結果を確認する。
%   add_bus / add_branch / add_component / add_local_controller / add_global_controller
%   replace_component / remove_component / remove_branch / remove_bus / remove_global_controller
%   タグ、tab_parameter の編集、編集ログ (tab_editLog, str_editFlag)
%
% 実行: runtests("DebugScript.test_F1_model_building")  または  DebugScript.run_all("Features","F1")

% 共通設定 (各テストの前に毎回実行される)
str_genKeys  = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop"];
str_loadKeys = ["load-impedance","load-power"];


%% Add buses with default tags
% ネットワーククラスの定義
net = PowerNetwork("TestSystem");
assert(net.str_tag == "TestSystem")

% Busクラスは add_bus で追加する (Bus のコンストラクタは直接呼べない)
for i = 1:3
    net.add_bus();
end

% タグは "B" + 3桁の通し番号
assert(numel(net.a_Bus) == 3)
assert(isequal(string(net.a_Bus)', ["B001","B002","B003"]))
assert(net.a_Bus{1}.a_PowerNetwork == net)


%% Add bus with options
net = PowerNetwork();
bus = net.add_bus("V", 1.05, "Varg", 0.1, "Bshunt", 0.2, "baseKV", 154, "Tag", "Bus");

% 戻り値は追加された Bus、オプションは tab_parameter に入る
assert(isa(bus, "Bus") && bus == net.a_Bus{1})
assert(bus.str_tag == "Bus001")
tp = bus.tab_parameter;
assert(tp.powerflow.V == 1.05 && tp.powerflow.Varg == 0.1)
assert(tp.dynamics.Bshunt == 0.2 && tp.operation.baseKV == 154)


%% Add branch by bus index
net = PowerNetwork();
for i = 1:4
    net.add_bus();
end

% Branchクラスは種類 (key) と接続する母線番号 [from, to] で追加する
br1 = net.add_branch("pi",             [1,2], "R",0.01, "X",0.1, "C",0.02);
br2 = net.add_branch("pi_transformer", [2,3], "X",0.05, "Tap",1.02);
br3 = net.add_branch("T",              [3,4], "X",0.08);
br4 = net.add_branch("two_winding_transformer", [1,4], "X",0.06);

assert(numel(net.a_Branch) == 4)
assert(isa(br1,"branch.pi") && isa(br2,"branch.pi_transformer") && isa(br3,"branch.T") && isa(br4,"branch.two_winding_transformer"))

% 接続先の母線とパラメータ
assert(isequal(string(br1.a_Bus)', ["B001","B002"]))
assert(br1.tab_parameter.dynamics.R == 0.01 && br1.tab_parameter.dynamics.C == 0.02)
assert(br2.tab_parameter.dynamics.tap == 1.02)

% タグは種類ごとのヘッダ + 通し番号で一意
str_tag = string(net.a_Branch);
assert(numel(unique(str_tag)) == 4)


%% Add branch by bus tag
net = PowerNetwork();
net.add_bus();
net.add_bus();

% 接続先は母線のタグでも指定できる
br = net.add_branch("pi", ["B001","B002"], "X", 0.1);
assert(isequal(string(br.a_Bus)', ["B001","B002"]))


%% Add every component type
net = PowerNetwork();
for i = 1:numel(str_genKeys)+numel(str_loadKeys)
    net.add_bus();
end

% Componentクラスは母線から key を指定して追加する
str_keys = [str_genKeys, str_loadKeys];
str_cls  = ["component.generator.classical","component.generator.one_axis","component.generator.two_axis", ...
            "component.generator.park","component.generator.droop","component.load.impedance","component.load.power"];
for k = 1:numel(str_keys)
    comp = net.a_Bus{k}.add_component(str_keys(k), "P", 0.1);
    assert(isa(comp, str_cls(k)), str_keys(k))
    assert(comp.key == str_keys(k))
    assert(comp.a_Bus == net.a_Bus{k})                         % 接続先の母線
    assert(comp.tab_parameter.powerflow.P == 0.1)              % 潮流設定
    assert(numel(comp.sv_x) == size(comp.rv_Xequilibrium,1) || isempty(comp.rv_Xequilibrium))
end

% タグ: 発電機は "SG", 負荷は "L" + 機種記号 + 母線内番号 + 母線タグ
assert(net.a_Bus{4}.a_Component{1}.str_tag == "SG1B004")
assert(startsWith(net.a_Bus{7}.a_Component{1}.str_tag, "L") && endsWith(net.a_Bus{7}.a_Component{1}.str_tag, "1B007"))

% 発電機の Q は既定で NaN (PV 母線)、負荷は指定値
assert(isnan(net.a_Bus{4}.a_Component{1}.tab_parameter.powerflow.Q))


%% Add component with parameter table
% 発電機定数は parameter に table で渡す (Tutorial3bus と同じ書き方)
para = table(1.569, 0.963, 0.963*0.8, 0.963, 0.963*0.9, 0.963*0.8, 0.1, 5.14, 5.14, 5.14, 5.14, 100, 10, ...
             'VariableNames', ["Xd","Xd_p","Xd_pp","Xq","Xq_p","Xq_pp","X_ls","Td_p","Td_pp","Tq_p","Tq_pp","M","D"]);
net = PowerNetwork();
net.add_bus();
comp = net.a_Bus{1}.add_component("gen-park", "P", 0.5, "parameter", para);

tp = comp.tab_parameter.dynamics;
assert(tp.M == 100 && tp.D == 10 && tp.Xd == 1.569)
assert(all(ismember(comp.sv_para, string(tp.Properties.VariableNames))))


%% Add local controller AVR and PSS
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};

% AVR と PSS を同時に付ける (旧 Task11)
avr = controller.avr.AVR_ST1("avr1");
pss = controller.pss.PSS1("pss1");
gen.add_local_controller(avr, pss)

% 機器には AVR が付き、PSS は AVR の下に付く
assert(numel(gen.a_LocalController) == 1)
assert(gen.a_LocalController{1} == avr)
assert(numel(avr.a_LocalController) == 1 && avr.a_LocalController{1} == pss)
assert(avr.key == "avr" && pss.key == "pss")

% 平衡点の計算で制御器の平衡点も設定される
DebugScript.helper.quiet(@() net.initialize);
assert(numel(avr.rv_Xequilibrium) == numel(avr.sv_x))
assert(numel(pss.rv_Xequilibrium) == numel(pss.sv_x))
assert(numel(gen.rv_Xequilibrium_all) == numel(gen.sv_x) + numel(avr.sv_x))


%% Add local controller AVR_DC1
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{2}.a_Component{1};
avr = controller.avr.AVR_DC1("dc1");
gen.add_local_controller(avr)
DebugScript.helper.quiet(@() net.initialize);

assert(gen.a_LocalController{1} == avr)
assert(numel(avr.rv_Xequilibrium) == numel(avr.sv_x))
assert(all(isfinite(avr.rv_Xequilibrium)))


%% PSS without AVR is rejected
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};

% PSS は AVR が付いていないと追加できない
try
    gen.add_local_controller(controller.pss.PSS1("pss"));
    error("DebugScript:noError", "PSS が AVR 無しで追加できてしまった")
catch ME
    assert(ME.identifier ~= "DebugScript:noError", ME.message)
end
assert(isempty(gen.a_LocalController))


%% Add local controller LQR
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);

% LQR 制御器 (controller.local_LQR) を作成して発電機に付ける
lqr = controller.local_LQR(net, 1);
net.a_Bus{1}.a_Component{1}.add_local_controller(lqr)
assert(isa(net.a_Bus{1}.a_Component{1}.a_LocalController{1}, "controller.local_LQR"))


%% Add global controller AGC
net = DebugScript.helper.build_ieee14();

% 制御対象の発電機を指定して AGC を作成 (旧 Task13)
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);

assert(numel(net.a_GlobalController) == 1 && net.a_GlobalController{1} == agc)
assert(isequal(string(agc.controlledUnits)', ["SG1B001","SG1B002"]))
assert(isequal(agc.tab_parameter.dynamics.kI, [500;500]))

% 機器はタグでも指定できる
agc2 = controller.agc.broadcast_PI_AGC(net, "agc2", "SG1B003");
assert(string(agc2.controlledUnits) == "SG1B003")


%% AGC default parameters cover all controlled units
% alpha, beta を省略しても、制御対象の台数分のパラメータが用意されるべき
net = DebugScript.helper.build_ieee14();
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002");
tp  = agc.tab_parameter.dynamics;
assert(height(tp) == 2 && isequal(tp.kP, [100;100]))


%% Two global controllers are initialized
net = DebugScript.helper.build_ieee14();
agc1 = controller.agc.broadcast_PI_AGC(net, "agc1", "SG1B001");
agc2 = controller.agc.broadcast_PI_AGC(net, "agc2", "SG1B002");
net.add_global_controller(agc1);
net.add_global_controller(agc2);
DebugScript.helper.quiet(@() net.initialize);

% すべての大域制御器に平衡点が設定されるべき
assert(numel(agc1.rv_Uequilibrium) == 1, "1台目の AGC の平衡点が未設定")
assert(numel(agc2.rv_Uequilibrium) == 1, "2台目の AGC の平衡点が未設定")


%% Replace component
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
str_old = string(net.a_Bus{5}.a_Component{1});

% 定電力負荷を定インピーダンス負荷に置き換える
net.a_Bus{5}.replace_component(str_old, "load-impedance");
comp = net.a_Bus{5}.a_Component{1};
assert(isa(comp, "component.load.impedance"))
assert(numel(net.a_Bus{5}.a_Component) == 1)
assert(comp.tab_parameter.powerflow.P == -1.0)       % 潮流設定は引き継がれる


%% Remove component
net = DebugScript.helper.build_9bus();
str_tag = string(net.a_Bus{5}.a_Component{1});

net.a_Bus{5}.remove_component(str_tag);
assert(isempty(net.a_Bus{5}.a_Component))

% 存在しないタグはエラー
try
    net.a_Bus{5}.remove_component("NoSuchTag");
    error("DebugScript:noError", "存在しないタグの削除がエラーにならない")
catch ME
    assert(ME.identifier ~= "DebugScript:noError", ME.message)
end


%% Remove branch
net = DebugScript.helper.build_9bus();
str_tag = string(net.a_Branch{9});
Y_before = net.get_admittance_matrix;

net.remove_branch(str_tag);
assert(numel(net.a_Branch) == 8)
assert(~ismember(str_tag, string(net.a_Branch)))

% 削除した送電線 (B008-B009) の分だけアドミタンス行列が変わる
Y_after = net.get_admittance_matrix;
assert(Y_after{"B008","B009"} == 0 && Y_before{"B008","B009"} ~= 0)


%% Remove bus
net = DebugScript.helper.build_9bus();
net.add_bus();                               % 何もつながっていない母線 B010
net.remove_bus("B010");
assert(numel(net.a_Bus) == 9)
assert(~ismember("B010", string(net.a_Bus)))


%% Remove global controller
net = DebugScript.helper.build_ieee14();
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001");
net.add_global_controller(agc);
net.remove_global_controller("agc");
assert(isempty(net.a_GlobalController))


%% Edit tab_parameter of bus component and branch
net = DebugScript.helper.build_9bus();

% tab_parameter は入れ子の table。列を指定して書き換えると各クラスに反映される
net.a_Bus{2}.tab_parameter.powerflow.V = 1.01;
net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]} = [-1.1, -0.15];
net.a_Branch{4}.tab_parameter.dynamics.X = 0.09;
net.a_Bus{1}.a_Component{1}.tab_parameter.dynamics.M = 12;

assert(net.a_Bus{2}.tab_parameter.powerflow.V == 1.01)
assert(isequal(net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]}, [-1.1, -0.15]))
assert(net.a_Bus{1}.a_Component{1}.tab_parameter.dynamics.M == 12)

% 送電線定数の変更はアドミタンス行列に反映される
br = net.a_Branch{4};
Y  = net.get_admittance_matrix;
assert(abs(Y{"B004","B005"} + 1/(0.010 + 1j*0.09)) < 1e-12)


%% Edit log and edit flag
net = DebugScript.helper.build_9bus();

% initialize 前は "unset" で、編集ログは記録されない
assert(DebugScript.helper.edit_flag(net) == "unset")

% initialize 後は "initialized"、ログは空
DebugScript.helper.quiet(@() net.initialize);
assert(DebugScript.helper.edit_flag(net) == "initialized")
assert(height(net.tab_editLog) == 0)

% パラメータを変更すると "editted" になり、変更前後の値が記録される
net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.1;
assert(DebugScript.helper.edit_flag(net) == "editted")
lv = net.tab_editLog.log == "edit P";
assert(any(lv))
assert(net.tab_editLog.before{find(lv,1)} == -1.0 && net.tab_editLog.after{find(lv,1)} == -1.1)

% 構成の変更 (機器の削除) も記録される
net.a_Bus{8}.remove_component(string(net.a_Bus{8}.a_Component{1}));
assert(any(contains(net.tab_editLog.log, "remove")))

% 再度 initialize するとログはリセットされる
net.a_Bus{8}.add_component("load-power", "P", -1.2, "Q", -0.4);
DebugScript.helper.quiet(@() net.initialize);
assert(DebugScript.helper.edit_flag(net) == "initialized" && height(net.tab_editLog) == 0)


%% Edit log records only changed parameters
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);

% 1つのパラメータを変更したらログは1行だけのはず
net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.1;
assert(height(net.tab_editLog) == 1, ...
       "1つの変更で " + height(net.tab_editLog) + " 行記録された: " + join(net.tab_editLog.log, ", "))
