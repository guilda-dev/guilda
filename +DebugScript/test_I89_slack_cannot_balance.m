% Issue 89: 残りの電力を引き受ける機器 (Q = NaN) がないスラック母線の指定で警告する
%
% 負荷をスラックにすると負荷が残りの電力を発電するが、利用者には何も知らされなかった。
%
% 実行: runtests("DebugScript.test_I89_slack_cannot_balance")  または  DebugScript.run_all("Features","I89")


%% A load-only slack bus warns, names the bus and the fix, and still takes effect
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
bus = net.a_Bus{3};
[s_id, s_msg] = set_slack(bus);
assert(s_id == "GUILDA:Bus:SlackWithoutQnan", s_id)
assert(contains(s_msg, string(bus)) && contains(s_msg, "Q = NaN"), s_msg)
assert(bus.l_isSlack && ~net.a_Bus{1}.l_isSlack)


%% A load-only network still initializes and passes KCL
net = load_only_network();
[s_id, ~] = set_slack(net.a_Bus{1});
assert(s_id == "GUILDA:Bus:SlackWithoutQnan", s_id)
DebugScript.helper.quiet(@() net.initialize);
assert(~DebugScript.helper.is_stale(net) && kcl_residual(net) < 1e-8)


%% A component with Q = NaN does not warn
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
assert(set_slack(net.a_Bus{1}) == "")
assert(net.a_Bus{1}.l_isSlack)

net = load_only_network();
net.a_Bus{1}.a_Component{1}.para_powerflow.Q = nan;
assert(set_slack(net.a_Bus{1}) == "")


%% One component with Q = NaN among others is enough
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
net.a_Bus{1}.add_component("load-power", "P",-0.1, "Q",-0.05);
assert(set_slack(net.a_Bus{1}) == "")


%% Releasing the slack bus and setting it again without a change do not warn
net = load_only_network();
set_slack(net.a_Bus{1});
assert(set_slack(net.a_Bus{1}) == "")
lastwarn("", "");
evalc("net.a_Bus{1}.l_isSlack = false;");
s_id = DebugScript.helper.msg_id();
assert(string(s_id) == "")


%% A bus without components still stops with NonUnitBus
net = PowerNetwork("Empty");
net.add_bus("V",1);
ME = [];
try
    set_slack(net.a_Bus{1});
catch ME
end
assert(~isempty(ME) && contains(ME.message, "cannot be assigned as the slack bus"))
assert(~net.a_Bus{1}.l_isSlack)


%% Removing the Q = NaN component later does not warn, and the load takes the remainder
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
net.a_Bus{1}.add_component("load-power", "P",-0.1, "Q",-0.05);
set_slack(net.a_Bus{1});
lastwarn("", "");
evalc("net.a_Bus{1}.remove_component(string(net.a_Bus{1}.a_Component{1}));");
s_id = DebugScript.helper.msg_id();
assert(string(s_id) == "")
DebugScript.helper.quiet(@() net.initialize);
assert(~DebugScript.helper.is_stale(net) && kcl_residual(net) < 1e-8)
load1 = net.a_Bus{1}.a_Component{1};
assert(abs(real(load1.c_Vequilibrium*conj(load1.c_Iequilibrium)) - load1.para_powerflow.P) > 1e-3)


%% Removing the last component later stops at the KCL check of initialize
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
set_slack(net.a_Bus{1});
lastwarn("", "");
evalc("net.a_Bus{1}.remove_component(string(net.a_Bus{1}.a_Component{1}));");
s_id = DebugScript.helper.msg_id();
assert(string(s_id) == "")
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize);
catch ME
end
assert(~isempty(ME) && DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:InitializeNotEquilibrium")
assert(DebugScript.helper.is_stale(net))


% ---- local functions ----
function [s_id, s_msg] = set_slack(bus)
% スラックに指定し、出た警告の ID と文を返す (なければ "")
    lastwarn("", "");
    evalc("bus.l_isSlack = true;");
    [s_msg, s_id] = lastwarn(); s_id = DebugScript.helper.msg_id(s_msg, s_id);
    s_msg   = string(s_msg);
    s_id    = string(s_id);
end

function net = load_only_network()
    net = PowerNetwork("LoadOnly");
    net.add_bus("V",1);
    net.add_bus();
    net.add_branch("pi",[1,2], "R",0.01, "X",0.085);
    net.a_Bus{1}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
    net.a_Bus{2}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
end

function r = kcl_residual(net)
    sv_Bus  = string(net.a_Bus);
    tab_Y   = net.get_admittance_matrix;
    r = max(abs(tab_Y{sv_Bus,sv_Bus}*net.cv_Vequilibrium - net.cv_Iequilibrium));
end
