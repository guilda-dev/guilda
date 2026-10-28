% F4 最適潮流計算 (optimize_powerflow)
%
% 3 つの方式 "ELD" / "DC OPF" / "AC OPF" で最適潮流を計算し、物理的な妥当性を確認する。
%   - 解が得られる (flag > 0)
%   - 需給バランス (発電の合計 = 負荷 (+ 損失))、母線ごとの電力・電流のつり合い
%   - 負荷は潮流設定の値のまま、発電機出力・電圧は上下限の範囲内
%   - ELD は等増分費用、DC OPF (送電制約なし) は ELD と同じ配分
%   - AC OPF の費用は ELD 以上、潮流計算の解での費用以下
% 費用関数は機器の tab_parameter.OPF、制約は各クラスの tab_parameter.operation で設定する。
%
% 実行: runtests("DebugScript.test_F4_opf")  または  DebugScript.run_all("Features","F4")
%
% [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob] = net.optimize_powerflow("methods", ...)
%   powerflow_bus : 母線ごとの解
%   powerflow_cub : 母線への接続 (機器 "<機器名>"、送電線の端 "<送電線名>_<母線名>") ごとの、母線への注入

% 共通設定 (各テストの前に毎回実行される)
tol = 1e-5;
is_load = @(c) isa(c,"component.load.abstract");


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

% 機器の行の合計 = 母線の P、負荷は指定値のまま、送電線の端は NaN
assert(abs(tab_cub{"LPQ1B005","P"} + 1.0) < tol)
assert(all(isnan(tab_cub{"EL004_B004","P"})))
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    if isempty(bus.a_Component); continue; end
    assert(abs(sum(tab_cub{string(bus.a_Component),"P"}) - tab_bus{string(bus),"P"}) < tol)
end

% 3 台とも費用 P^2 + P で同じなので、等分 (各 1.0) が最適
assert(all(abs(tab_bus{["B001","B002","B003"],"P"} - 1) < 1e-4))


%% ELD with a binding generator limit
% 上限に達した発電機以外は等増分費用 (2*HP*P + fP が等しい)
net = DebugScript.helper.build_9bus();
net.a_Bus{1}.a_Component{1}.tab_parameter.operation.Pmax = 0.5;
net.a_Bus{3}.a_Component{1}.tab_parameter.OPF.HP = 2;

[tab_bus, ~, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","ELD"));
assert(flag > 0)
assert(abs(sum(tab_bus.P)) < tol)
P = tab_bus{["B001","B002","B003"],"P"};
assert(P(1) <= 0.5 + tol && abs(P(1) - 0.5) < 1e-4)
% 残り 2.5 を 2*P2 + 1 = 4*P3 + 1 で配分 → P2 = 5/3, P3 = 5/6
assert(abs(2*P(2) + 1 - (4*P(3) + 1)) < 1e-4)
assert(abs(P(2) - 5/3) < 1e-4 && abs(P(3) - 5/6) < 1e-4)


%% DC optimal power flow
% DC 近似 (|V| = 1、損失なし) の最適潮流
net = DebugScript.helper.build_9bus();
[tab_bus, tab_cub, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","DC OPF"));
assert(flag > 0)
assert(all(ismember(["Varg","V","P"], tab_bus.Properties.VariableNames)))
assert(abs(sum(tab_bus.P)) < tol)
assert(all(tab_bus.V == 1))

% 基準母線 (B001) の位相は 0
assert(abs(tab_bus{"B001","Varg"}) < tol)

% 送電線の端の P = 母線への流入 b_ij*(θj-θi)、両端の和 = 0 (損失なし)
for k = 1:numel(net.a_Branch)
    br  = net.a_Branch{k};
    str = string(br) + "_" + string(br.a_Bus);
    Y   = br.get_admittance_matrix();
    th  = tab_bus{string(br.a_Bus),"Varg"};
    assert(abs(tab_cub{str(1),"P"} - imag(Y(1,2))*(th(2)-th(1))) < tol)
    assert(abs(tab_cub{str(1),"P"} + tab_cub{str(2),"P"}) < tol)
end

% 母線ごとのつり合い: 機器と送電線の端の注入の合計 = 0
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    l_bus = endsWith(tab_cub.Properties.RowNames, "_"+string(bus)) | ismember(tab_cub.Properties.RowNames, string(bus.a_Component));
    assert(abs(sum(tab_cub.P(l_bus))) < tol)
end

% 送電制約が無いので、配分は ELD と同じ
tab_ELD = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","ELD"));
assert(max(abs(tab_bus.P - tab_ELD.P)) < 1e-4)


%% AC optimal power flow
% 交流潮流方程式を制約にした最適潮流。電圧は 0.95-1.05 に制限する
net = DebugScript.helper.build_9bus();
for i = 1:numel(net.a_Bus)
    net.a_Bus{i}.tab_parameter.operation{1,["Vmin","Vmax"]} = [0.95, 1.05];
end
[tab_bus, tab_cub, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","AC OPF"));
assert(flag > 0)
assert(all(ismember(["Varg","V","P","Q","Vphasor","Iphasor"], tab_bus.Properties.VariableNames)))

% 解は潮流方程式を満たし、注入の合計 = 送電損失 (> 0)
Y = net.get_admittance_matrix.Variables;
assert(norm(tab_bus.Vphasor .* conj(Y*tab_bus.Vphasor) - (tab_bus.P + 1j*tab_bus.Q)) < 1e-4)
S_loss = DebugScript.helper.branch_losses(net, tab_bus.Vphasor);
assert(abs(sum(tab_bus.P) - real(S_loss)) < 1e-4)
assert(real(S_loss) > 0)

% 負荷は指定値のまま、電圧は上下限 (Vmin, Vmax) の範囲内、基準母線の位相は 0
assert(abs(tab_bus{"B005","P"} + 1.0) < tol && abs(tab_bus{"B005","Q"} + 0.1) < tol)
assert(all(tab_bus.V >= 0.95 - tol & tab_bus.V <= 1.05 + tol))
assert(abs(tab_bus{"B001","Varg"}) < tol)

% 母線ごとの電流のつり合い (KCL): 機器と送電線の端の注入電流の合計 = 母線シャントの電流
for i = 1:numel(net.a_Bus)
    bus = net.a_Bus{i};
    l_bus = endsWith(tab_cub.Properties.RowNames, "_"+string(bus)) | ismember(tab_cub.Properties.RowNames, string(bus.a_Component));
    y_sh  = bus.tab_parameter.dynamics{1,["Gshunt","Bshunt"]} * [1;1j];
    assert(abs(sum(tab_cub.Iphasor(l_bus)) - y_sh*tab_bus{string(bus),"Vphasor"}) < 1e-4)
end

% 費用: ELD (損失なしの緩和問題) 以上、潮流計算の解 (実行可能解) 以下
J_AC = DebugScript.helper.opf_cost(net, tab_cub);
[~, tab_cub_ELD] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","ELD"));
assert(J_AC >= DebugScript.helper.opf_cost(net, tab_cub_ELD) - 1e-6)
tab_PF = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(all(tab_PF.V >= 0.95 & tab_PF.V <= 1.05))   % 潮流解が OPF の制約を満たすことの確認
assert(J_AC <= DebugScript.helper.opf_cost(net, DebugScript.helper.pf_component_power(net, tab_PF)) + 1e-6)


%% AC OPF respects generator limits
% 発電機の出力上限・無効電力の範囲が守られ、上限に達する
net = DebugScript.helper.build_9bus();
gen = net.a_Bus{1}.a_Component{1};
gen.tab_parameter.operation{1,["Pmax","Qmin","Qmax"]} = [0.6, -0.3, 0.3];
[tab_bus, tab_cub, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","AC OPF"));
assert(flag > 0)
P1 = tab_cub{string(gen),"P"};
Q1 = tab_cub{string(gen),"Q"};
assert(P1 <= 0.6 + tol && abs(P1 - 0.6) < 1e-4)
assert(Q1 >= -0.3 - tol && Q1 <= 0.3 + tol)
assert(abs(tab_bus{"B001","P"} - P1) < tol)


%% IEEE14 ELD and DC OPF
% IEEE 14 母線系統。負荷はそのまま、ELD と DC OPF (送電制約なし) の配分は一致する
net = DebugScript.helper.build_ieee14();
a_Com  = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
l_load = cellfun(is_load, a_Com);
str_load = string(a_Com(l_load));
P_load = cellfun(@(c) c.tab_parameter.powerflow.P, a_Com(l_load));

[tab_bus, tab_cub, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","ELD"));
assert(flag > 0)
assert(abs(sum(tab_bus.P)) < tol)
assert(max(abs(tab_cub{str_load,"P"} - P_load)) < tol)
% 全発電機が同じ費用 P^2 + P で制約も無いので、等増分費用 = 等分
P_gen = tab_cub{string(a_Com(~l_load)),"P"};
assert(max(abs(P_gen - mean(P_gen))) < 1e-4)

[tab_DC, tab_cub_DC, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","DC OPF"));
assert(flag > 0)
assert(abs(sum(tab_DC.P)) < tol)
assert(max(abs(tab_cub_DC{string(a_Com),"P"} - tab_cub{string(a_Com),"P"})) < 1e-4)


%% IEEE14 AC OPF
% 潮流方程式・負荷・電圧制約を満たし、費用は潮流計算の解以下
net = DebugScript.helper.build_ieee14();
a_Com  = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
l_load = cellfun(is_load, a_Com);
str_load = string(a_Com(l_load));
PQ_load = cell2mat(cellfun(@(c) c.tab_parameter.powerflow{1,["P","Q"]}, a_Com(l_load), "UniformOutput", false));

[tab_bus, tab_cub, flag] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","AC OPF"));
assert(flag > 0)
Y = net.get_admittance_matrix.Variables;
assert(norm(tab_bus.Vphasor .* conj(Y*tab_bus.Vphasor) - (tab_bus.P + 1j*tab_bus.Q)) < 1e-4)
S_loss = DebugScript.helper.branch_losses(net, tab_bus.Vphasor);
assert(abs(sum(tab_bus.P) - real(S_loss)) < 1e-4)
assert(max(abs(tab_cub{str_load,["P","Q"]} - PQ_load), [], "all") < tol)
Vmin = cellfun(@(b) b.tab_parameter.operation.Vmin, net.a_Bus);
Vmax = cellfun(@(b) b.tab_parameter.operation.Vmax, net.a_Bus);
assert(all(tab_bus.V >= Vmin - tol & tab_bus.V <= Vmax + tol))

J_AC  = DebugScript.helper.opf_cost(net, tab_cub);
[~, tab_cub_ELD] = DebugScript.helper.quiet(@() net.optimize_powerflow("methods","ELD"));
assert(J_AC >= DebugScript.helper.opf_cost(net, tab_cub_ELD) - 1e-6)
tab_PF = DebugScript.helper.quiet(@() net.calculate_powerflow);
assert(J_AC <= DebugScript.helper.opf_cost(net, DebugScript.helper.pf_component_power(net, tab_PF)) + 1e-6)
