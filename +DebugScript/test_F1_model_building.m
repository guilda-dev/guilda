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


%% Add bus with deprecated baseMVA option
% 母線の baseMVA は廃止: 値は無視して警告 (系統の baseMVA と違えばその旨も出す)、1セッション1回
net = PowerNetwork();
clear Deprecated
lastwarn("");
evalc('bus = net.add_bus("baseMVA", 100);');
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:BusBaseMVA")
assert(~ismember("baseMVA", string(bus.tab_parameter.operation.Properties.VariableNames)))
lastwarn("");
evalc('net.add_bus("baseMVA", 50);');
[str_warn, id] = lastwarn();
assert(string(id) == "GUILDA:Deprecated:BusBaseMVAMismatch" && contains(str_warn, "50") && contains(str_warn, "100"))
assert(net.tab_parameter.base.baseMVA == 100 && numel(net.a_Bus) == 2)
lastwarn("");
evalc('net.add_bus("baseMVA", 50);');
[~, id] = lastwarn();
assert(isempty(id), "警告は1セッションに1回")


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
assert(br.a_PowerNetwork == net)

% タグ指定と番号指定は同じ系統になる (逆向き [to, from] も同じ)
net2 = PowerNetwork();
net2.add_bus();
net2.add_bus();
net2.add_branch("pi", [1,2], "X", 0.1);
assert(isequal(net.get_admittance_matrix, net2.get_admittance_matrix))
br = net.add_branch("pi", ["B002","B001"], "X", 0.2);
assert(isequal(string(br.a_Bus)', ["B002","B001"]))

% 存在しないタグはエラー
try
    net.add_branch("pi", ["B001","B099"]);
    error("DebugScript:noError", "存在しない母線タグがエラーにならない")
catch ME
    assert(ME.identifier ~= "DebugScript:noError", ME.message)
end


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

% 親への参照は追加した側が設定する (PSS の親は AVR、AVR の親は発電機)
assert(gen.a_Bus == net.a_Bus{1})
assert(avr.a_Component == gen && pss.a_Component == avr)

% 平衡点の計算で制御器の平衡点も設定される
DebugScript.helper.quiet(@() net.initialize);
assert(numel(avr.rv_Xequilibrium) == numel(avr.sv_x))
assert(numel(pss.rv_Xequilibrium) == numel(pss.sv_x))
assert(numel(gen.rv_Xequilibrium_all) == numel(gen.sv_x) + numel(avr.sv_x))


%% Replace AVR keeps its PSS
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
avr1 = controller.avr.AVR_ST1("avr1");
pss1 = controller.pss.PSS1("pss1");
gen.add_local_controller(avr1, pss1)

% 新しい AVR で置き換えると (警告が出る)、PSS は新しい AVR へ移る (PSS は AVR へ信号を送る)
avr2 = controller.avr.AVR_DC1("avr2");
lastwarn("");
evalc("gen.add_local_controller(avr2)");
[~, id] = lastwarn();
assert(string(id) == "GUILDA:Component:ReplaceController")
assert(numel(gen.a_LocalController) == 1 && gen.a_LocalController{1} == avr2)
assert(numel(avr2.a_LocalController) == 1 && avr2.a_LocalController{1} == pss1)
assert(avr2.a_Component == gen && pss1.a_Component == avr2)

% 外した AVR は機器・PSS への参照を持たない
assert(isempty(avr1.a_Component) && isempty(avr1.a_LocalController))

% PSS の置き換え: 古い PSS は外れる
pss2 = controller.pss.PSS1("pss2");
evalc("gen.add_local_controller(pss2)");
assert(numel(avr2.a_LocalController) == 1 && avr2.a_LocalController{1} == pss2)
assert(pss2.a_Component == avr2 && isempty(pss1.a_Component))

% AVR と PSS を同時に与えると、与えた PSS が新しい AVR に付く
avr3 = controller.avr.AVR_ST1("avr3");
pss3 = controller.pss.PSS1("pss3");
evalc("gen.add_local_controller(avr3, pss3)");
assert(gen.a_LocalController{1} == avr3 && avr3.a_LocalController{1} == pss3)
assert(isempty(pss2.a_Component) && isempty(avr2.a_LocalController))

% 置き換え後も平衡点を計算できる
DebugScript.helper.quiet(@() net.initialize);
assert(numel(pss3.rv_Xequilibrium) == numel(pss3.sv_x))
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)


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
% 状態フィードバックの LQR (key "local") は AVR の位置に付き、予約語 "X" で機器の全状態を観測する
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr)
assert(isa(gen.a_LocalController{1}, "controller.local_LQR"))
assert(gen.a_LocalController{1} == lqr && lqr.a_Component == gen && lqr.key == "local")

% 入力 "X" は発電機の状態名に展開され、出力 (駆動する入力) は既定で発電機の全入力
assert(isequal(lqr.sv_u, gen.sv_x))
assert(isequal(lqr.iv_obsX, (1:numel(gen.sv_x))') && all(lqr.iv_obsY == 0))
assert(isequal(lqr.sv_y, gen.sv_u))

% initialize でゲインが決まり、平衡点では u = u* を出力する (u = u* - K (x - x*))
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(size(lqr.K), [numel(gen.sv_u), numel(gen.sv_x)]) && all(isfinite(lqr.K(:))))
assert(isequal(lqr.rv_Uequilibrium, gen.rv_Xequilibrium) && isempty(lqr.rv_Xequilibrium))
assert(norm(lqr.f_Y(0, [], [], [], gen.rv_Xequilibrium) - gen.rv_Uequilibrium) < 1e-12)

% 駆動する入力を選べる。Q, R はベクトルなら対角行列
lqr2 = controller.local_LQR("lqr2", Input="Vfield", Q=[1 10 1 1 1 1], R=2);
evalc("gen.add_local_controller(lqr2)");      % 置き換え (警告)
assert(gen.a_LocalController{1} == lqr2 && isempty(lqr.a_Component))
assert(lqr2.sv_y == "Vfield" && isequal(lqr2.Q, diag([1 10 1 1 1 1])) && lqr2.R == 2)
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(size(lqr2.K), [1, numel(gen.sv_x)]))

% 機器にない入力を駆動しようとするとエラー
try
    evalc("net.a_Bus{2}.a_Component{1}.add_local_controller(controller.local_LQR(""lqr3"", Input=""Vref""))");
    error("DebugScript:noError", "存在しない入力 Vref を駆動する LQR が付いてしまった")
catch ME
    assert(ME.identifier == "GUILDA:local_LQR:UnknownInput", ME.message)
end


%% LQR replaces an AVR and its PSS
% LQR は AVR と同じ位置に付くので、AVR を置き換え、AVR に付いていた PSS は外れる
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
avr = controller.avr.AVR_ST1("avr1");
pss = controller.pss.PSS1("pss1");
gen.add_local_controller(avr, pss)

% PSS は発電機の出力 omega を名前で観測する (状態にも omega があるが出力が優先)
assert(pss.iv_obsY == 1 && pss.iv_obsX == 0)
assert(all(avr.iv_obsY == 0) && all(avr.iv_obsX == 0))

lqr = controller.local_LQR("lqr1");
str = evalc("gen.add_local_controller(lqr)");
assert(contains(str, "replaces"))
assert(gen.a_LocalController{1} == lqr)
assert(isempty(avr.a_Component) && isempty(pss.a_Component) && isempty(avr.a_LocalController))

% LQR の下には PSS を付けられない
try
    gen.add_local_controller(controller.pss.PSS1("pss2"));
    error("DebugScript:noError", "LQR の下に PSS が付いてしまった")
catch ME
    assert(ME.identifier ~= "DebugScript:noError", ME.message)
end

% AVR を付け直すと LQR が外れる
avr2 = controller.avr.AVR_ST1("avr2");
evalc("gen.add_local_controller(avr2)");
assert(gen.a_LocalController{1} == avr2 && isempty(lqr.a_Component))
DebugScript.helper.quiet(@() net.initialize);


%% Add global controller AGC
net = DebugScript.helper.build_ieee14();

% 制御対象の発電機を指定して AGC を作成 (旧 Task13)
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);

assert(numel(net.a_GlobalController) == 1 && net.a_GlobalController{1} == agc)
assert(agc.a_PowerNetwork == net)                   % 親への参照は add_global_controller が設定する
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
assert(isequal(tp.alpha, [1;1]) && isequal(tp.beta, [1;1]))

% スカラーで与えた alpha, beta も全台に適用される
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002", "SG1B003", alpha=2, beta=0.5);
tp  = agc.tab_parameter.dynamics;
assert(isequal(tp.alpha, [2;2;2]) && isequal(tp.beta, [0.5;0.5;0.5]))

% 台数と合わない長さはエラー
try
    controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002", alpha=[1;1;1]);
    error("DebugScript:noError", "台数と合わない alpha がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:broadcast_PI_AGC:InvalidSize", ME.message)
end


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
assert(agc1.a_PowerNetwork == net && agc2.a_PowerNetwork == net)
assert(isequal(agc1.rv_Xequilibrium, 0) && isequal(agc2.rv_Xequilibrium, 0))


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

% 置き換えられた機器は母線への参照を持たない
assert(comp.a_Bus == net.a_Bus{5})
comp_old = net.a_Bus{5}.a_Component{1};
net.a_Bus{5}.replace_component(string(comp_old), "load-power");
assert(isempty(comp_old.a_Bus) && isempty(comp_old.c_Vequilibrium))


%% Remove component
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
str_tag = string(net.a_Bus{5}.a_Component{1});

comp = net.a_Bus{5}.a_Component{1};
net.a_Bus{5}.remove_component(str_tag);
assert(isempty(net.a_Bus{5}.a_Component))

% 削除した機器は母線への参照を持たない (元の母線の電圧に追従しない)
assert(isempty(comp.a_Bus))
assert(isempty(comp.c_Vequilibrium))

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

% 削除した送電線は系統・母線への参照を持たない
br = net.a_Branch{1};
net.remove_branch(string(br));
assert(isempty(br.a_PowerNetwork) && isempty(br.a_Bus))


%% Automatic branch tags stay unique after remove_branch
% 自動タグの番号は「使用中の最大番号 + 1」(種類 EL/ET をまたいだ通し番号)
net = DebugScript.helper.build_9bus();
net.remove_branch(string(net.a_Branch{3}));
br = net.add_branch("pi", [1,2]);
assert(br.str_tag == "EL010")
assert(numel(unique(string(net.a_Branch))) == numel(net.a_Branch))

% 途中の番号を消しても再利用しない
net.remove_branch(["EL004","EL005"]);
br = net.add_branch("two_winding_transformer", [1,2]);
assert(br.str_tag == "ET011")
assert(numel(unique(string(net.a_Branch))) == numel(net.a_Branch))


%% Automatic component tags stay unique after remove_component
% 番号は母線ごとの「使用中の最大番号 + 1」(機種をまたいだ通し番号)
net = PowerNetwork();
bus = net.add_bus();
bus.add_component("load-power");
bus.add_component("load-power");
bus.remove_component("LPQ1B001");
comp = bus.add_component("load-power");
assert(comp.str_tag == "LPQ3B001")
assert(isequal(string(bus.a_Component)', ["LPQ2B001","LPQ3B001"]))

for i = 1:8
    bus.add_component("gen-classical");
end
assert(bus.a_Component{end}.str_tag == "SG11B001")
bus.remove_component("LPQ2B001");
comp = bus.add_component("load-power");
assert(comp.str_tag == "LPQ12B001")
assert(numel(unique(string(bus.a_Component))) == numel(bus.a_Component))


%% Replace component keeps the tag number
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
bus = net.a_Bus{5};
assert(string(bus.a_Component{1}) == "LPQ1B005")
comp = bus.replace_component("LPQ1B005", "load-impedance");
assert(comp.str_tag == "LRX1B005")
comp = bus.replace_component("LRX1B005", "load-power");
assert(comp.str_tag == "LPQ1B005")


%% Global controller tag in use is rejected
% 大域制御器のタグは利用者が与えるので、使用中のタグはエラー (系統は変わらない)
net = DebugScript.helper.build_ieee14();
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001"));
agc2 = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B002");
try
    net.add_global_controller(agc2);
    error("DebugScript:noError", "使用中のタグの大域制御器を追加できてしまう")
catch ME
    assert(ME.identifier == "GUILDA:PowerNetwork:GconTagInUse", ME.message)
    assert(contains(ME.message, "'agc'"), ME.message)
end
assert(numel(net.a_GlobalController) == 1 && isempty(agc2.a_PowerNetwork))


%% Remove bus
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);    % 編集ログは initialize 後に記録される
net.add_bus();                               % 何もつながっていない母線 B010
bus = net.a_Bus{10};
net.remove_bus("B010");
assert(numel(net.a_Bus) == 9)
assert(~ismember("B010", string(net.a_Bus)))
assert(isempty(bus.a_PowerNetwork))                 % 削除した母線は系統への参照を持たない
assert(net.tab_editLog.tag(end) == "Topology")

% 存在しないタグはエラー
try
    net.remove_bus("B099");
    error("DebugScript:noError", "存在しない母線の削除がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:PowerNetwork:BusNotFound", ME.message)
end

% 送電線がつながった母線は、既定ではエラー (系統は変わらない)
n_branch = numel(net.a_Branch);
try
    net.remove_bus("B005");
    error("DebugScript:noError", "送電線がつながった母線の削除がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:PowerNetwork:BusHasBranches", ME.message)
end
assert(numel(net.a_Bus) == 9 && numel(net.a_Branch) == n_branch)

% RemoveBranches=true なら、つながった送電線も一緒に削除する
lv_conn = cellfun(@(br) any(string(br.a_Bus) == "B005"), net.a_Branch);
a_conn  = net.a_Branch(lv_conn);
net.remove_bus("B005", "RemoveBranches", true);
assert(numel(net.a_Bus) == 8 && numel(net.a_Branch) == n_branch - nnz(lv_conn))
assert(all(cellfun(@(br) isempty(br.a_PowerNetwork), a_conn)))

% 新しい母線のタグは既存のタグと重ならない
bus = net.add_bus();
assert(numel(unique(string(net.a_Bus))) == 9 && bus.str_tag == "B010")

% 大域制御器が制御している機器のある母線は削除できない
net = DebugScript.helper.build_ieee14();
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001");
net.add_global_controller(agc);
try
    net.remove_bus("B001", "RemoveBranches", true);
    error("DebugScript:noError", "大域制御器が制御する機器のある母線の削除がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:PowerNetwork:BusHasControlledUnits", ME.message)
end
assert(numel(net.a_Bus) == 14)


%% Remove global controller
net = DebugScript.helper.build_ieee14();
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001");
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);
net.remove_global_controller("agc");
assert(isempty(net.a_GlobalController))
assert(isempty(agc.a_PowerNetwork))                   % 削除した制御器は系統への参照を持たない
assert(net.tab_editLog.tag(end) == "Topology")

% 存在しないタグはエラー
try
    net.remove_global_controller("agc");
    error("DebugScript:noError", "存在しない大域制御器の削除がエラーにならない")
catch ME
    assert(ME.identifier == "GUILDA:PowerNetwork:GconNotFound", ME.message)
end


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
