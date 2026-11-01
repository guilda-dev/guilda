% Issue 92: 島に分かれた系統を initialize で報告する
%
% 孤立母線や島は「収束せず」とだけ出てソルバー設定を勧め、収支の合う島は無言で成功していた。
% 収支の合う島は有効な平衡点なので警告に留め、失敗時は島の母線を示す。
%
% 実行: runtests("DebugScript.test_I92_network_islands")  または  DebugScript.run_all("Features","I92")


%% A balanced island succeeds with a warning that lists the islands
net = balanced_island();
[str_id, str_msg] = warning_of(@() net.initialize);
assert(str_id == "GUILDA:PowerNetwork:NetworkIsland", str_id)
assert(contains(str_msg, "[B001, B002, B003], [B004, B005]"), str_msg)
assert(~net.s_edit.l_staleEquilibrium && kcl_residual(net) < 1e-6)


%% The warning of a balanced island can be turned off
net = balanced_island();
s_warn = warning("off", "GUILDA:PowerNetwork:NetworkIsland");
c_warn = onCleanup(@() warning(s_warn));
str_out = evalc("net.initialize;");   % 無効な警告も lastwarn には残るので表示で確かめる
assert(~contains(str_out, "split into"), str_out)
clear c_warn


%% Method="OPF" and Method="equilibrium" warn on a balanced island too
net = balanced_island();
assert(warning_of(@() net.initialize(Method="OPF")) == "GUILDA:PowerNetwork:NetworkIsland")
net = balanced_island();
warning_of(@() net.initialize);
assert(warning_of(@() net.initialize(Method="equilibrium")) == "GUILDA:PowerNetwork:NetworkIsland")


%% An isolated bus without components is named, and solver settings are not recommended
net = connected_network();
net.add_bus();
check_failure(net, "powerflow", "InitializePowerflowFailed", "[B004]");


%% An isolated load or generator is named
net = connected_network();
net.add_bus();
net.a_Bus{4}.add_component("load-power", "P",-0.5, "Q",-0.1);
check_failure(net, "powerflow", "InitializePowerflowFailed", "[B004]");

net = connected_network();
net.add_bus("V",1);
net.a_Bus{4}.add_component("gen-park", "P",0.5, "Q",nan);
check_failure(net, "powerflow", "InitializePowerflowFailed", "[B004]");


%% An island without a generator is named
net = no_generator_island();
check_failure(net, "powerflow", "InitializePowerflowFailed", "[B004, B005]");


%% An island whose power does not balance is named
net = balanced_island();
net.a_Bus{5}.a_Component{1}.para_powerflow.P = -0.9;
check_failure(net, "powerflow", "InitializePowerflowFailed", "[B004, B005]");


%% A network without branches is named
net = no_branch_network();
check_failure(net, "powerflow", "InitializePowerflowFailed", "[B001], [B002]");


%% A failed OPF on a split network names the islands, also when the OPF stops with an internal error
check_failure(no_generator_island(), "OPF", "InitializeOPFFailed", "[B004, B005]");
net = connected_network();
net.add_bus();
check_failure(net, "OPF", "InitializeOPFFailed", "[B004]");
check_failure(no_branch_network(), "OPF", "InitializeOPFFailed", "[B001], [B002]");


%% A failure releases the slack bus that the power flow set
net = connected_network();
net.add_bus();
assert(~any(cellfun(@(b) b.l_isSlack, net.a_Bus)))
check_failure(net, "powerflow", "InitializePowerflowFailed", "[B004]");
assert(~any(cellfun(@(b) b.l_isSlack, net.a_Bus)))


%% A failure on a connected network keeps its message about the solver settings
net = connected_network();
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize(MaxIteration=1));
catch ME
end
assert(~isempty(ME) && ME.identifier == "GUILDA:PowerNetwork:InitializePowerflowFailed")
assert(contains(ME.message, "MaxIteration") && ~contains(ME.message, "islands"), ME.message)


%% Errors about the options and the empty network are unchanged on a split network
net = balanced_island();
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize(Method="OPF", NoSuchOption=1));
catch ME
end
assert(~isempty(ME) && ME.identifier == "GUILDA:resolve_options:UnknownName", ME.identifier)

net = PowerNetwork("Empty");
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize);
catch ME
end
assert(~isempty(ME) && ME.identifier == "GUILDA:PowerNetwork:NoBus", ME.identifier)


%% Long lists are shortened
net = PowerNetwork("Line");
for k = 1:12
    net.add_bus();
end
for k = 1:11
    net.add_branch("pi",[k,k+1], "R",0.01, "X",0.1);
end
net.add_bus();
check_failure_text(net, ["... (12 buses)", "[B013]"]);

net = PowerNetwork("Separate");
for k = 1:12
    net.add_bus();
end
check_failure_text(net, ["12 islands", "[B010], ..."]);


%% calculate_powerflow alone reports nothing about islands
net = balanced_island();
[str_id, ~, res] = warning_of(@() net.calculate_powerflow);
assert(str_id == "" && res.l_success)

net = connected_network();
net.add_bus();
[str_id, ~, res] = warning_of(@() net.calculate_powerflow);
assert(str_id == "" && ~res.l_success)


%% The built-in networks do not warn
for str_net = ["IEEE9bus","IEEE14bus","IEEE14bus_lossless","IEEE14bus_NoTap","IEEE68bus", ...
               "Ishizaki6Bus","TEST31bus","Txt3Bus","Tutorial3bus"]
    net = network.(str_net)();
    str_id = warning_of(@() net.initialize);
    assert(str_id ~= "GUILDA:PowerNetwork:NetworkIsland", str_net)
end


% ---- local functions ----
function r = kcl_residual(net)
    str_Bus = string(net.a_Bus);
    tab_Y   = net.get_admittance_matrix;
    r = max(abs(tab_Y{str_Bus,str_Bus}*net.cv_Vequilibrium - net.cv_Iequilibrium));
end

function net = connected_network()
    net = DebugScript.helper.build_3bus("gen-1axis");
end

function net = balanced_island()
% B004-B005 は無損失で、発電と負荷の P が一致する
    net = connected_network();
    net.add_bus("V",1);
    net.add_bus();
    net.add_branch("pi",[4,5], "R",0, "X",0.1);
    net.a_Bus{4}.add_component("gen-park", "P",0.5, "Q",nan);
    net.a_Bus{5}.add_component("load-power", "P",-0.5, "Q",-0.1);
end

function net = no_generator_island()
    net = connected_network();
    net.add_bus();
    net.add_bus();
    net.add_branch("pi",[4,5], "R",0.01, "X",0.1);
    net.a_Bus{4}.add_component("load-power", "P",-0.5, "Q",-0.1);
    net.a_Bus{5}.add_component("load-power", "P",-0.5, "Q",-0.1);
end

function net = no_branch_network()
    net = PowerNetwork("NoBranch");
    net.add_bus("V",1);
    net.add_bus();
    net.a_Bus{1}.add_component("gen-park");
    net.a_Bus{2}.add_component("load-power", "P",-0.5, "Q",-0.1);
end

function check_failure(net, str_method, str_id, str_island)
% 失敗の ID と島の一覧を確かめ、ソルバー設定を勧めていないことを確かめる
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize(Method=str_method));
    catch ME
    end
    assert(~isempty(ME), "initialize did not fail")
    assert(ME.identifier == "GUILDA:PowerNetwork:" + str_id, ME.identifier)
    assert(contains(ME.message, str_island), ME.message)
    assert(~contains(ME.message, ["solver settings", "solver_PF"]), ME.message)
end

function check_failure_text(net, sv_text)
% 機器がなくても島の一覧が短くなることを、一覧を作る関数を通して確かめる
    net.a_Bus{1}.add_component("gen-park");
    net.a_Bus{end}.add_component("load-power", "P",-0.5, "Q",-0.1);
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize);
    catch ME
    end
    assert(~isempty(ME) && all(contains(ME.message, sv_text)), string(ME.message))
end

function [str_id, str_msg, varargout] = warning_of(fcn)
% 関数を実行し、最後の警告の ID と文を返す (なければ "")
    lastwarn("", "");
    varargout = cell(1, nargout - 2);
    if nargout > 2
        evalc("[varargout{:}] = fcn();");
    else
        evalc("fcn();");
    end
    [str_msg, str_id] = lastwarn;
    str_msg = string(str_msg);
    str_id  = string(str_id);
end
