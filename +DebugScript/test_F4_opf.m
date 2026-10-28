% F4 最適潮流計算 (optimize_powerflow)
%
% 3 つの方式 "ELD" / "DC OPF" / "AC OPF" で最適潮流を計算し、
%   - 解が得られる (flag > 0)
%   - 需給バランス (発電の合計 = 負荷 (+ 損失)) が成り立つ
%   - 発電機出力が上下限の範囲内
% を確認する。費用関数・制約は各クラスの tab_parameter.OPF / operation で設定する。
%
% 実行: runtests("DebugScript.test_F4_opf")  または  DebugScript.run_all("Features","F4")
%
% [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob] = net.optimize_powerflow("methods", ...)

% 共通設定 (各テストの前に毎回実行される)
tol = 1e-5;


%% Economic load dispatch
% 9 母線系統。送電線を無視して、負荷の合計を発電機で経済的に配分する
net = DebugScript.helper.build_9bus();
P_load = -(-1.0 - 0.8 - 1.2);

[tab_bus, tab_cub, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","ELD"));
assert(flag > 0)
assert(istable(tab_bus) && height(tab_bus) == numel(net.a_Bus))

% 需給バランス: 母線注入の合計 = 0 (損失なし)
assert(abs(sum(tab_bus.P)) < tol)
assert(abs(sum(tab_bus{["B001","B002","B003"],"P"}) - P_load) < tol)


%% DC optimal power flow
% DC 近似 (|V| = 1、損失なし) の最適潮流
net = DebugScript.helper.build_9bus();
[tab_bus, ~, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","DC OPF"));
assert(flag > 0)
assert(all(ismember(["Varg","V","P"], tab_bus.Properties.VariableNames)))
assert(abs(sum(tab_bus.P)) < tol)
assert(all(tab_bus.V == 1))


%% AC optimal power flow
% 交流潮流方程式を制約にした最適潮流
net = DebugScript.helper.build_9bus();
[tab_bus, ~, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","AC OPF"));
assert(flag > 0)
assert(all(ismember(["Varg","V","P","Q","Vphasor","Iphasor"], tab_bus.Properties.VariableNames)))

% 解は潮流方程式を満たし、注入の合計 = 送電損失
Y = net.get_admittance_matrix.Variables;
assert(norm(tab_bus.Vphasor .* conj(Y*tab_bus.Vphasor) - (tab_bus.P + 1j*tab_bus.Q)) < 1e-4)
S_loss = DebugScript.helper.branch_losses(net, tab_bus.Vphasor);
assert(abs(sum(tab_bus.P) - real(S_loss)) < 1e-4)

% 負荷は指定値のまま、電圧は上下限 (Vmin, Vmax) の範囲内
assert(abs(tab_bus{"B005","P"} + 1.0) < tol)
Vmin = cellfun(@(b) b.tab_parameter.operation.Vmin, net.a_Bus);
Vmax = cellfun(@(b) b.tab_parameter.operation.Vmax, net.a_Bus);
assert(all(tab_bus.V >= Vmin - tol & tab_bus.V <= Vmax + tol))
