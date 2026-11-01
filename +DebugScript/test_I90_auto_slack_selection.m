% Issue 90: スラック未指定のときの母線の選び方と、選べないときのエラー
%
% 第1母線が負荷だと負荷がスラックになって残差が残り、第1母線に機器がなければ他に発電機が
% あっても BUS001 の固定文のエラーになっていた。
%
% 実行: runtests("DebugScript.test_I90_auto_slack_selection")  または  DebugScript.run_all("Features","I90")


%% The first bus with Q = NaN is selected even if the first bus has a load
net = three_bus();
net.a_Bus{1}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{2}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{3}.add_component("gen-1axis", "P",0.2, "Q",nan);
assert(quiet_powerflow(net) == "")
assert(slack_index(net) == 2)


%% The first bus may have no component
net = three_bus();
net.a_Bus{2}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{3}.add_component("gen-1axis", "P",0.3, "Q",nan);
assert(quiet_powerflow(net) == "")
assert(slack_index(net) == 3)


%% A first bus with Q = NaN stays the slack bus
net = three_bus();
net.a_Bus{1}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{2}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{3}.add_component("load-power", "P",-0.5, "Q",-0.1);
assert(quiet_powerflow(net) == "")
assert(slack_index(net) == 1)


%% A slack bus that is already set is kept
net = three_bus();
net.a_Bus{1}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{2}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{3}.add_component("gen-1axis", "P",0.3, "Q",nan);
evalc("net.a_Bus{3}.l_isSlack = true;");
assert(quiet_powerflow(net) == "")
assert(slack_index(net) == 3)


%% Without Q = NaN the first bus with a component is selected, with the warning
net = three_bus();
net.a_Bus{2}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
net.a_Bus{3}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
assert(quiet_powerflow(net) == "GUILDA:Bus:SlackWithoutQnan")
assert(slack_index(net) == 2)


%% A load-only network still initializes and passes KCL
net = three_bus();
net.a_Bus{1}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
net.a_Bus{3}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
DebugScript.helper.quiet(@() net.initialize);
assert(slack_index(net) == 1 && ~net.l_staleEquilibrium)
str_Bus = string(net.a_Bus);
tab_Y   = net.get_admittance_matrix;
assert(max(abs(tab_Y{str_Bus,str_Bus}*net.cv_Vequilibrium - net.cv_Iequilibrium)) < 1e-6)   % initialize の許容値


%% A network without buses names the cause
net = PowerNetwork("NoBuses");
ME = powerflow_error(net);
assert(ME.identifier == "GUILDA:PowerNetwork:NoBus", ME.identifier)
assert(contains(ME.message, "NoBuses") && ~contains(ME.message, "BUS001"), ME.message)


%% A network without components names the cause
net = three_bus();
ME = powerflow_error(net);
assert(ME.identifier == "GUILDA:PowerNetwork:NoSlackCandidate", ME.identifier)
assert(contains(ME.message, "add_component") && ~contains(ME.message, "BUS001"), ME.message)
assert(isempty(slack_index(net)))


%% initialize passes on these errors
net = PowerNetwork("NoBuses");
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize);
catch ME
end
assert(~isempty(ME) && ME.identifier == "GUILDA:PowerNetwork:NoBus")

net = three_bus();
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize);
catch ME
end
assert(~isempty(ME) && ME.identifier == "GUILDA:PowerNetwork:NoSlackCandidate")
assert(isempty(slack_index(net)))


%% initialize releases the selected slack bus when the power flow fails
net = three_bus();
net.a_Bus{1}.add_component("load-power", "P",-0.5, "Q",-0.1);
net.a_Bus{2}.add_component("gen-1axis", "P",0.3, "Q",nan);
net.a_Bus{3}.add_component("load-power", "P",-500, "Q",-100);
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize(MaxIteration=1));
catch ME
end
assert(~isempty(ME) && ME.identifier == "GUILDA:PowerNetwork:InitializePowerflowFailed")
assert(isempty(slack_index(net)))


% ---- local functions ----
function net = three_bus()
    net = PowerNetwork("ThreeBus");
    net.add_bus("V",1);
    net.add_bus();
    net.add_bus();
    net.add_branch("pi",[1,2], "R",0.01, "X",0.085);
    net.add_branch("pi",[2,3], "R",0.01, "X",0.085);
end

function str_id = quiet_powerflow(net)
% 潮流計算を実行し、収束を確かめて、出た警告の ID を返す (なければ "")
    lastwarn("", "");
    [~, flag] = DebugScript.helper.quiet(@() net.calculate_powerflow);
    assert(flag > 0)
    [~, str_id] = lastwarn;
    str_id = string(str_id);
end

function ME = powerflow_error(net)
    ME = [];
    try
        DebugScript.helper.quiet(@() net.calculate_powerflow);
    catch ME
    end
    assert(~isempty(ME), "エラーになるはず")
end

function i = slack_index(net)
    i = find(cellfun(@(b) b.l_isSlack, net.a_Bus));
end
