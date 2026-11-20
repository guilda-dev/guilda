% F99 IEEE39Bus の動特性: 慣性 M = 2H と母線の地絡
%
%   gen-2axis の omega は pu (ddelta/dt = 2*pi*f0*omega, M domega/dt = ...) なので、慣性は
%   M = 2H [s] (H はシステム基準)。M = 2H/omega0 では電気機械モードが 10 Hz を超える。
%   定電力負荷 (load-power) のままの地絡は、地絡の始まりで整合な初期値が無い
%   (GUILDA:SolverODE:InitialConditionFailed)。負荷を load-impedance に替えれば解ける
%
% 実行: runtests("DebugScript.test_F99_ieee39_dynamics")  または  DebugScript.run_all("Features","F99")

% 共通設定 (各テストの前に毎回実行される)
c_warn = {warning("off", "GUILDA:PowerNetwork:SimulationIncomplete")};
c_warn{2} = onCleanup(@() warning(c_warn{1}));
c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)
net = DebugScript.helper.quiet(@() network.IEEE39Bus());


%% The inertia is M = 2H and the electromechanical modes are below 2 Hz
tab = net.get_parameter("dynamics", Key="gen-2axis");
% H [s] (システム基準) は 1 号機 (B039) 500、10 号機 (B030) 42
assert(abs(tab{"B039SG1", "M"} - 1000) < 1e-12 && abs(tab{"B030SG1", "M"} - 84) < 1e-12)
sys = net.get_sys(Type="ODE", Format="struct");
lam = eig(sys.A, sys.E);
lam = lam(isfinite(lam) & imag(lam) > 1e-6);
assert(~isempty(lam) && max(imag(lam))/(2*pi) < 2, "largest oscillation %g Hz", max(imag(lam))/(2*pi))


%% A fault with the constant-power loads has no consistent initial condition
sc = net.add_scenario("fault");
sc.add_fault("B016", [1, 1.05]);
[res, flag, output] = net.simulate(sc.s_tag, Time=[0, 2]);
assert(flag == -1 && output.tEnd == 1)
assert(DebugScript.helper.msg_id(output.exception) == "GUILDA:SolverODE:InitialConditionFailed")
assert(contains(output.message, "load-power"))
assert(res.rv_t(end) == 1)


%% The same fault runs with load-impedance loads (example of the class help)
for b = 1:numel(net.a_Bus)
    c = net.a_Bus{b}.a_Component;
    for k = 1:numel(c)
        if isa(c{k}, "component.load.power") && any(c{k}.tab_parameter.powerflow{1, ["P","Q"]} ~= 0)
            net.a_Bus{b}.replace_component(c{k}.s_tag, "load-impedance");
        end
    end
end
DebugScript.helper.quiet(@() net.initialize());
sc = net.add_scenario("fault");
sc.add_fault("B016", [1, 1.05]);
[res, flag] = net.simulate(sc.s_tag, Time=[0, 5]);
assert(flag == 1 && res.rv_t(end) == 5)
assert(res.judge_out_of_step().Verdict == "stable")


%% With stiffer generators the fault has a consistent initial condition with load-power
% Xd と Xd_p を 1/5 にした発電機 (以前の版の研究用データ) では、定電力負荷のままでも B028 の地絡に
% 整合な初期値がある (地絡中の B029 の電圧は約 0.26 pu。以前の版の decic の解は 0.2566 pu)。
% 初期値の計算は、解があれば微分状態を保ったまま解く。この地絡点の電圧は実行の順で変わる
% ことがある (このファイルを通して実行すると 0.293 pu) ため、範囲で確かめる
tab = net.get_parameter("dynamics", Key="gen-2axis");
tab.Xd   = tab.Xd/5;
tab.Xd_p = tab.Xd_p/5;
net.set_parameter("dynamics", tab);
DebugScript.helper.quiet(@() net.initialize());
sc = net.add_scenario("fault");
sc.add_fault("B028", [1, 1.01]);
[res, flag] = net.simulate(sc.s_tag, Time=[0, 3]);
assert(flag == 1 && res.rv_t(end) == 3)
tv = res.tab_variable;
iv = find(tv.Kind == "Vre" & tv.Bus == "B029");
k0 = find(res.rv_t == 1);
r_V29 = hypot(res.rm_variable(k0(end), iv), res.rm_variable(k0(end), iv+1));
assert(r_V29 > 0.2 && r_V29 < 0.35, "|V| of B029 at the start of the fault: %g", r_V29)
iv_x = find(tv.Kind == "x");
assert(numel(k0) == 2 && max(abs(res.rm_variable(k0(2), iv_x) - res.rm_variable(k0(1), iv_x))) == 0)
