% Issue 89: 残りの電力を引き受ける機器 (Q = NaN) がないスラック母線は initialize のエラーにする
%
% 負荷だけのスラック母線では負荷が残りの電力を発電し、機器のないスラック母線では
% 「KCL 残差」のエラーになるだけで、原因が分からなかった。
%
% 実行: runtests("DebugScript.test_I89_slack_cannot_balance")  または  DebugScript.run_all("Features","I89")


%% A load on the slack bus stops initialize and names the bus
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
evalc("net.a_Bus{3}.l_isSlack = true;");
ME = error_of(@() net.initialize());
assert(ME.identifier == "GUILDA:PowerNetwork:SlackCannotBalance", ME.identifier)
assert(contains(ME.message, string(net.a_Bus{3})) && contains(ME.message, "Q = NaN"), ME.message)


%% A slack bus left without components stops initialize
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);    % B001 がスラックになる
net.a_Bus{1}.remove_component(string(net.a_Bus{1}.a_Component{1}));
ME = error_of(@() net.initialize());
assert(ME.identifier == "GUILDA:PowerNetwork:SlackCannotBalance", ME.identifier)
assert(contains(ME.message, "0 component"), ME.message)
assert(net.l_staleEquilibrium)


%% The error leaves the equilibrium and the edit log as they were
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
V = net.cv_Vequilibrium;
evalc("net.a_Bus{3}.l_isSlack = true;");
n = height(net.tab_editLog);
error_of(@() net.initialize());
assert(isequal(net.cv_Vequilibrium, V) && height(net.tab_editLog) == n)


%% A slack bus chosen by the power flow is released again
net = load_first_network();
error_of(@() net.initialize());
assert(~any(cellfun(@(b) b.l_isSlack, net.a_Bus)))


%% The remedies of the message work
% 発電機を足す
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
evalc("net.a_Bus{3}.l_isSlack = true;");
net.a_Bus{3}.add_component("gen-1axis", "P",0, "Q",nan);
DebugScript.helper.quiet(@() net.initialize);
assert(~net.l_staleEquilibrium && kcl_residual(net) < 1e-8)

% 発電機のある母線へ移す
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
evalc("net.a_Bus{3}.l_isSlack = true;");
error_of(@() net.initialize());
evalc("net.a_Bus{1}.l_isSlack = true;");
DebugScript.helper.quiet(@() net.initialize);
assert(~net.l_staleEquilibrium && kcl_residual(net) < 1e-8)

% 機器の Q を NaN にする
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
evalc("net.a_Bus{3}.l_isSlack = true;");
net.a_Bus{3}.a_Component{1}.para_powerflow.Q = nan;
DebugScript.helper.quiet(@() net.initialize);
assert(~net.l_staleEquilibrium && kcl_residual(net) < 1e-8)


%% calculate_powerflow alone does not distribute power, so it still runs
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
evalc("net.a_Bus{3}.l_isSlack = true;");
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
assert(res.l_success)


%% OPF does not use the slack remainder, so it still runs
net = DebugScript.helper.build_9bus();
evalc("net.a_Bus{5}.l_isSlack = true;");
res = DebugScript.helper.quiet(@() net.initialize(Method="OPF", Verbose=false));
assert(res.l_success && ~net.l_staleEquilibrium)


%% Bundled networks are not affected
for c_net = {DebugScript.helper.build_9bus(), DebugScript.helper.build_ieee14()}
    net = c_net{1};
    DebugScript.helper.quiet(@() net.initialize);
    assert(~net.l_staleEquilibrium && kcl_residual(net) < 1e-8)
end


% ---- local functions ----
function net = load_first_network()
% 第1母線が負荷。スラックを指定していないので潮流計算が第1母線を選ぶ
    net = PowerNetwork("LoadFirst");
    net.add_bus("V",1);
    net.add_bus("V",1);
    net.add_branch("pi",[1,2], "R",0.01, "X",0.085);
    net.a_Bus{1}.add_component("load-power", "P",-0.5, "Q",-0.1);
    net.a_Bus{2}.add_component("gen-1axis", "P",0.5, "Q",nan);
end

function r = kcl_residual(net)
    str_Bus = string(net.a_Bus);
    tab_Y   = net.get_admittance_matrix;
    r = max(abs(tab_Y{str_Bus,str_Bus}*net.cv_Vequilibrium - net.cv_Iequilibrium));
end

function ME = error_of(fcn)
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
    assert(~isempty(ME), "エラーにならなかった")
end
