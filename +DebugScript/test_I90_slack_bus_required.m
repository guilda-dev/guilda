% Issue 90: スラック母線は利用者が指定する。指定がなければ潮流計算は止まり、設定の仕方を示す
%
% 以前は未指定のとき母線を自動で選んでいたが、GUILDA はスラック母線を選ばない
% (2026-11-13 の決定)。潮流計算・入力固定の潮流計算・initialize は
% GUILDA:PowerNetwork:NoSlackBus で止まり、OPF と network_to_mpc は指定がなければ先頭の母線を参照にする。
%
% 実行: runtests("DebugScript.test_I90_slack_bus_required")  または  DebugScript.run_all("Features","I90")


%% Power flow without a slack bus stops with NoSlackBus
net = three_bus();
net.a_Bus{1}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{2}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{3}.add_component("gen-1axis", "P",0.2, "Q",nan);
for f = {@() net.calculate_powerflow(), @() net.calculate_fixed_input_powerflow(), @() net.get_pf_condition(Display=false), @() net.initialize()}
    ME = error_of(f{1});
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:NoSlackBus", DebugScript.helper.msg_id(ME))
end
% 文面は系統の名前と設定の仕方を示す
assert(contains(ME.message, "ThreeBus") && contains(ME.message, "net.a_Bus{1}.l_isSlack = true"), ME.message)
% 何も選ばず、何も変えない
assert(isempty(set_slack(net)) && DebugScript.helper.is_stale(net))


%% The slack bus that is set is used and kept
net = three_bus();
net.a_Bus{1}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{2}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{3}.add_component("gen-1axis", "P",0.2, "Q",nan);
evalc("net.a_Bus{3}.l_isSlack = true;");
[res, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(flag > 0 && res.tab_PFcondition.Type(3) == "slack" && sum(res.tab_PFcondition.Type == "slack") == 1)
DebugScript.helper.quiet(@() net.initialize);
assert(set_slack(net) == 3 && ~DebugScript.helper.is_stale(net))
sv_Bus = string(net.a_Bus);
tab_Y  = net.get_admittance_matrix;
assert(max(abs(tab_Y{sv_Bus,sv_Bus}*net.cv_Vequilibrium - net.cv_Iequilibrium)) < 1e-6)


%% A network without buses names the cause
net = PowerNetwork("NoBuses");
assert(DebugScript.helper.msg_id(error_of(@() net.calculate_powerflow)) == "GUILDA:PowerNetwork:NoBus")
assert(DebugScript.helper.msg_id(error_of(@() net.initialize)) == "GUILDA:PowerNetwork:NoBus")


%% initialize leaves the network unchanged when no slack bus is set
net = three_bus();
net.a_Bus{1}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{3}.add_component("load-power", "P",-0.5, "Q",-0.1);
evalc("net.a_Bus{1}.l_isSlack = true;");
DebugScript.helper.quiet(@() net.initialize);
V0 = net.cv_Vequilibrium;
evalc("net.a_Bus{1}.l_isSlack = false;");
assert(DebugScript.helper.msg_id(error_of(@() net.initialize)) == "GUILDA:PowerNetwork:NoSlackBus")
assert(isequal(net.cv_Vequilibrium, V0) && isempty(set_slack(net)) && DebugScript.helper.is_stale(net))


%% OPF and network_to_mpc use the slack bus, else the first bus
% OPF はスラック母線を必要としないので NoSlackBus で止まらない。ReferenceBus="auto" はスラック母線、なければ先頭の母線
net = three_bus();
net.a_Bus{1}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{2}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{3}.add_component("gen-1axis", "P",0.2, "Q",nan);
mpc = tools.network_to_mpc(net);
assert(find(mpc.bus(:,2) == 3) == 1)
for s_method = ["DC OPF", "AC OPF"]
    res = net.calculate_optimal_powerflow(Method=s_method, Verbose=false);
    assert(res.l_success && abs(res.tab_bus.Varg(1)) < 1e-9 && abs(res.tab_bus.Varg(2)) > 1e-3, s_method)
    assert(isempty(set_slack(net)))
end
evalc("net.a_Bus{3}.l_isSlack = true;");
mpc = tools.network_to_mpc(net);
assert(find(mpc.bus(:,2) == 3) == 3)
res = net.calculate_optimal_powerflow(Method="DC OPF", Verbose=false);
assert(abs(res.tab_bus.Varg(3)) < 1e-9 && abs(res.tab_bus.Varg(1)) > 1e-3)


%% OPF and network_to_mpc keep the first bus when no bus has a component
net = three_bus();
mpc = tools.network_to_mpc(net);
assert(find(mpc.bus(:,2) == 3) == 1)
res = net.calculate_optimal_powerflow(Method="DC OPF", Verbose=false);
assert(res.l_success && isempty(set_slack(net)))


% ---- local functions ----
function net = three_bus()
    net = PowerNetwork("ThreeBus");
    net.add_bus("V",1);
    net.add_bus();
    net.add_bus();
    net.add_branch("pi",[1,2], "R",0.01, "X",0.085);
    net.add_branch("pi",[2,3], "R",0.01, "X",0.085);
end

function ME = error_of(fcn)
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
    assert(~isempty(ME), "エラーになるはず")
end

function i = set_slack(net)
% 指定された (l_isSlack の) スラック母線
    i = find(cellfun(@(b) b.l_isSlack, net.a_Bus));
end
