% Issue 56: initialize は KCL を満たす平衡点を作るか、失敗して stale にする
%
% OPF の配分が機器に渡らず、P 編集後の Method="equilibrium" は編集を無視したうえ KCL を
% 満たさない点で stale を解除していた。書き込み途中の失敗でも平衡点が混在していた。
%
% 実行: runtests("DebugScript.test_I56_initialize_equilibrium")  または  DebugScript.run_all("Features","I56")


%% OPF initialize gives a real equilibrium
tol_kcl   = 1e-8;
tol_drift = 1e-6;
for c_net = {DebugScript.helper.build_9bus(), DebugScript.helper.build_ieee14()}
    net = c_net{1};
    res = DebugScript.helper.quiet(@() net.initialize(Method="OPF", Verbose=false));
    assert(kcl_residual(net) < tol_kcl)
    assert(~net.l_staleEquilibrium)
    assert(drift(net) < tol_drift)
    assert_component_power(net, res)

    % 続けて equilibrium を実行しても同じ点が保たれる
    V = net.cv_Vequilibrium;
    I = component_currents(net);
    DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
    assert(norm(net.cv_Vequilibrium - V) < 1e-10 && norm(component_currents(net) - I) < 1e-10)
    assert(kcl_residual(net) < tol_kcl)
end


%% OPF initialize with several components on one bus
net = build_shared_bus();
res = DebugScript.helper.quiet(@() net.initialize(Method="OPF", Verbose=false));
assert(numel(net.a_Bus{2}.a_Component) == 3)
assert(kcl_residual(net) < 1e-8)
assert_component_power(net, res)
assert(drift(net) < 1e-6)


%% Powerflow and equilibrium with several components on one bus
net = build_shared_bus();
DebugScript.helper.quiet(@() net.initialize);
assert(kcl_residual(net) < 1e-8)
assert(drift(net) < 1e-6)

% 機器ごとの電流 (スラックの残りと Q の配分) がそのまま残る
I = component_currents(net);
DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
assert(norm(component_currents(net) - I) < 1e-10)
assert(kcl_residual(net) < 1e-8)


%% Powerflow initialize still distributes from the settings
net = build_shared_bus();
DebugScript.helper.quiet(@() net.initialize);
a_Comp = net.a_Bus{2}.a_Component;
assert(abs(real(a_Comp{1}.c_Vequilibrium*conj(a_Comp{1}.c_Iequilibrium)) - a_Comp{1}.para_powerflow.P) < 1e-10)


%% Slack bus whose components all fix Q takes the remaining Q on the first one
net = PowerNetwork("LoadOnly");
net.add_bus("V",1);
net.add_bus();
net.add_branch("pi",[1,2], "R",0.01, "X",0.085);
net.a_Bus{1}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
net.a_Bus{2}.add_component("load-impedance", "P",-0.5, "Q",-0.1);
DebugScript.helper.quiet(@() net.initialize);
assert(kcl_residual(net) < 1e-8)


%% Edits that the equilibrium method would lose stop with an error
str_id = "GUILDA:PowerNetwork:InitializeEquilibriumEdited";

[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
gen.para_powerflow.P = 0.9;
assert_edit_stops(net, str_id, "edit P")

[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{3}.add_component("load-power", "P",-0.1, "Q",-0.1);
assert_edit_stops(net, str_id, "connect")

[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
evalc("net.a_Bus{2}.l_isSlack = true;");
assert_edit_stops(net, str_id, "slack bus")

[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.para_base.baseMVA = 2*net.para_base.baseMVA;
assert_edit_stops(net, str_id, "baseMVA")


%% The remedy of the edit error works
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
gen.para_powerflow.P = 0.9;
assert(contains(error_of(@() net.initialize(Method="equilibrium")).message, "net.initialize()"))
DebugScript.helper.quiet(@() net.initialize);
assert(kcl_residual(net) < 1e-8 && ~net.l_staleEquilibrium)
assert(abs(real(gen.c_Vequilibrium*conj(gen.c_Iequilibrium)) - 0.9) < 1e-10)


%% Dynamics edits are allowed and give an equilibrium of the new model
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
V = net.cv_Vequilibrium;
U = gen.rv_Uequilibrium;
gen.para_dynamics.Xd = 1.2*gen.para_dynamics.Xd;
assert(net.l_staleEquilibrium)
DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
assert(~net.l_staleEquilibrium)
assert(norm(net.cv_Vequilibrium - V) < 1e-10 && kcl_residual(net) < 1e-8)
assert(norm(gen.rv_Uequilibrium - U) > 1e-6)      % 界磁入力が新しい Xd に合わせて変わる
assert(drift(net) < 1e-6)


%% Failure while setting the point leaves the equilibrium stale
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr);
DebugScript.helper.quiet(@() net.initialize);
lqr.Q = ones(1, numel(gen.sv_x) + 1);           % 重みのサイズが違うので set_equilibrium で失敗する
error_of(@() net.initialize());
assert(net.l_staleEquilibrium)
ME = error_of(@() net.simulate([0 1]));
assert(ME.identifier == "GUILDA:PowerNetwork:EquilibriumStale", ME.identifier)


%% A failure without a stale edit is reported as an unfinished initialize
% operation の編集は stale にしないが、baseMVA = 0 だと Q の配分が NaN になる
net = build_shared_bus();
DebugScript.helper.quiet(@() net.initialize);
a_Comp = net.a_Bus{2}.a_Component;
a_Comp{1}.para_operation.baseMVA = 0;
a_Comp{2}.para_operation.baseMVA = 0;
assert(~net.l_staleEquilibrium)
error_of(@() net.initialize());
assert(net.l_staleEquilibrium)
ME = error_of(@() net.simulate([0 1]));
assert(ME.identifier == "GUILDA:PowerNetwork:EquilibriumStale", ME.identifier)
assert(contains(ME.message, "stopped before it finished"), ME.message)


%% Failed analysis still keeps the previous equilibrium
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
V = net.cv_Vequilibrium;
ME = error_of(@() net.initialize(Method="OPF", MaxIteration=2));
assert(ME.identifier == "GUILDA:PowerNetwork:InitializeOPFFailed", ME.identifier)
assert(~net.l_staleEquilibrium && isequal(net.cv_Vequilibrium, V))


%% Slack bus without a component is not an equilibrium
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);    % B001 がスラックになる
net.a_Bus{1}.remove_component(string(net.a_Bus{1}.a_Component{1}));
ME = error_of(@() net.initialize());
assert(ME.identifier == "GUILDA:PowerNetwork:InitializeNotEquilibrium", ME.identifier)
assert(net.l_staleEquilibrium)


%% A point that violates KCL stops initialize and marks the equilibrium stale
% 許容値を極端に緩めると潮流計算は反復せずに成功を返し、平衡でない点を渡す
net = DebugScript.helper.build_9bus();
ME  = error_of(@() net.initialize(Tolerance=1e3));
assert(ME.identifier == "GUILDA:PowerNetwork:InitializeNotEquilibrium", ME.identifier)
assert(net.l_staleEquilibrium)
assert(error_of(@() net.simulate([0 1])).identifier == "GUILDA:PowerNetwork:EquilibriumStale")
DebugScript.helper.quiet(@() net.initialize);
assert(~net.l_staleEquilibrium && kcl_residual(net) < 1e-8)


% ---- local functions ----
function net = build_shared_bus()
% B002 に発電機 2 台と負荷 1 台。Q は発電機 2 台に NaN で配分する
    net = PowerNetwork("SharedBus");
    net.add_bus("V",1.00);
    net.add_bus("V",1.01);
    net.add_bus();
    net.add_branch("pi",[1,2], "R",0.010, "X",0.085);
    net.add_branch("pi",[2,3], "R",0.017, "X",0.092);
    net.a_Bus{1}.add_component("gen-park");
    net.a_Bus{2}.add_component("gen-1axis", "P",0.4, "Q",nan);
    net.a_Bus{2}.add_component("gen-1axis", "P",0.2, "Q",nan);
    net.a_Bus{2}.add_component("load-power", "P",-0.1, "Q",-0.05);
    net.a_Bus{3}.add_component("load-power", "P",-1.0, "Q",-0.2);
    net.solver_ODE.Progress = "none";
end

function r = kcl_residual(net)
    str_Bus = string(net.a_Bus);
    tab_Y   = net.get_admittance_matrix;
    r = max(abs(tab_Y{str_Bus,str_Bus}*net.cv_Vequilibrium - net.cv_Iequilibrium));
end

function d = drift(net)
    d = DebugScript.helper.max_state_drift(net.simulate([0 5]));
end

function cv = component_currents(net)
    cv = zeros(0,1);
    for i = 1:numel(net.a_Bus)
        a_Comp = net.a_Bus{i}.a_Component;
        for k = 1:numel(a_Comp)
            cv(end+1,1) = a_Comp{k}.c_Iequilibrium;   %#ok
        end
    end
end

function assert_component_power(net, res)
% 機器の平衡点が OPF の解の機器ごとの P, Q と一致する
    for i = 1:numel(net.a_Bus)
        a_Comp = net.a_Bus{i}.a_Component;
        for k = 1:numel(a_Comp)
            c  = a_Comp{k};
            cS = c.c_Vequilibrium*conj(c.c_Iequilibrium);
            rr = real(res.tab_cub{string(c),["P","Q"]});
            assert(abs(real(cS) - rr(1)) < 1e-8 && abs(imag(cS) - rr(2)) < 1e-8, string(c))
        end
    end
end

function assert_edit_stops(net, str_id, str_log)
% エラーで止まり、平衡点も編集記録も変わらない
    V   = net.cv_Vequilibrium;
    n   = height(net.tab_editLog);
    ME  = error_of(@() net.initialize(Method="equilibrium"));
    assert(ME.identifier == str_id, ME.identifier)
    assert(contains(ME.message, str_log))
    assert(isequal(net.cv_Vequilibrium, V) && net.l_staleEquilibrium && height(net.tab_editLog) == n)
end

function ME = error_of(fcn)
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
    assert(~isempty(ME), "エラーにならなかった")
end
