% F73 結果の要約 (get_summary)、disp_summary の箇条書き、ResultPF.tab_branch の From/To
%
%   get_summary は disp_summary が出す数値を構造体で返す (ResultPF、ResultOPF)。収束しなかった
%   潮流計算の結果では、注入の合計・|V|・違反数を NaN (母線のタグは "") にする (disp_summary が
%   出さないのと同じ)。disp_summary は 1 行目に結果、そのあと項目ごとに "- " で始まる箇条書き。
%   tab_branch の From/To は各ブランチの a_Bus{1}、a_Bus{2} のタグ。
%
% 実行: runtests("DebugScript.test_F73_result_summary")  または  DebugScript.run_all("Features","F73")


%% get_summary of a power flow holds the sums, the |V| range and the counts
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
sct = res.get_summary();
tab = res.tab_bus;
assert(isstruct(sct) && sct.l_success && sct.r_flag > 0 && sct.s_Solver == string(res.options.Solver))
assert(sct.n_bus == 9 && sct.n_slack == 1 && sct.n_PV == 2 && sct.n_PQ == 6 && sct.n_branch == 9)
assert(abs(sct.r_Pgeneration - sum(tab.P(tab.P > 0))) < 1e-12 && abs(sct.r_Qgeneration - sum(tab.Q(tab.P > 0))) < 1e-12)
assert(abs(sct.r_Pload + sum(tab.P(tab.P < 0))) < 1e-12 && abs(sct.r_Qload + sum(tab.Q(tab.P < 0))) < 1e-12)
assert(abs(sct.r_Ploss - sum(tab.P)) < 1e-12 && abs(sct.r_Qloss - sum(tab.Q)) < 1e-12)
assert(abs(sct.r_Ploss - sum(res.tab_branch.Ploss)) < 1e-8)
[r_max, i_max] = max(tab.V);
[r_min, i_min] = min(tab.V);
sv_bus = string(tab.Properties.RowNames);
assert(sct.r_Vmax == r_max && sct.s_VmaxBus == sv_bus(i_max) && sct.r_Vmin == r_min && sct.s_VminBus == sv_bus(i_min))
assert(sct.n_violation == height(res.tab_violation) && sct.n_iteration == res.output.iterations)


%% disp_summary of a power flow is a title line and bullets with the values of get_summary
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
sct = res.get_summary();
sv = splitlines(res.disp_summary());
assert(startsWith(sv(1), "Power flow of ") && contains(sv(1), "converged") && all(startsWith(sv(2:end), "- ")), join(sv, newline))
assert(any(sv == sprintf("- Generation: P = %.4f pu, Q = %.4f pu", sct.r_Pgeneration, sct.r_Qgeneration)), join(sv, newline))
assert(any(sv == sprintf("- Load: P = %.4f pu, Q = %.4f pu", sct.r_Pload, sct.r_Qload)), join(sv, newline))
assert(any(sv == sprintf("- Losses: P = %.4f pu, Q = %.4f pu", sct.r_Ploss, sct.r_Qloss)), join(sv, newline))
assert(any(sv == sprintf("- |V|: max %.4f pu at %s, min %.4f pu at %s", sct.r_Vmax, sct.s_VmaxBus, sct.r_Vmin, sct.s_VminBus)), join(sv, newline))
assert(any(sv == "- Network: 9 buses (slack 1, PV 2, PQ 6), 9 branches") && any(sv == "- Violated operating limits: 0"), join(sv, newline))


%% A power flow that did not converge has NaN sums in get_summary and one bullet in disp_summary
net = network.IEEE9bus();
for k = 1:numel(net.a_Bus)
    for c = 1:numel(net.a_Bus{k}.a_Component)
        tab_c = net.a_Bus{k}.a_Component{c}.tab_parameter.powerflow;
        if ismember("P", tab_c.Properties.VariableNames) && tab_c.P < 0     % 負荷を 2.5 倍
            net.a_Bus{k}.a_Component{c}.tab_parameter.powerflow{:,["P","Q"]} = 2.5*[tab_c.P, tab_c.Q];
        end
    end
end
w = warning("off"); c_w = onCleanup(@() warning(w));
res = DebugScript.helper.quiet(@() net.calculate_powerflow());
clear c_w
assert(~res.l_success)
sct = res.get_summary();
assert(~sct.l_success && sct.r_flag <= 0 && sct.n_bus == 9 && sct.n_branch == 9)
sv_nan = ["r_Pgeneration","r_Qgeneration","r_Pload","r_Qload","r_Ploss","r_Qloss","r_Vmax","r_Vmin","n_violation"];
assert(all(arrayfun(@(s) isnan(sct.(s)), sv_nan)) && sct.s_VmaxBus == "" && sct.s_VminBus == "")
sv = splitlines(res.disp_summary());
assert(all(startsWith(sv(2:end), "- ")) && any(sv == "- Not converged: injection sums, |V| and violated limits are not shown"), join(sv, newline))
assert(~any(startsWith(sv, ["- Generation", "- Load", "- Losses", "- |V|", "- Violated"])), join(sv, newline))


%% tab_branch has the tags of the end buses in From and To
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
tab = res.tab_branch;
assert(isequal(string(tab.Properties.VariableNames(1:2)), ["From","To"]) && isstring(tab.From) && isstring(tab.To))
for k = 1:numel(net.a_Branch)
    assert(tab.From(k) == string(net.a_Branch{k}.a_Bus{1}) && tab.To(k) == string(net.a_Branch{k}.a_Bus{2}))
end
s = res.disp_branch(Branch=string(net.a_Branch{4}));
assert(contains(s, string(net.a_Branch{4}.a_Bus{1})) && contains(s, string(net.a_Branch{4}.a_Bus{2})), s)
% CSV に書くと From/To も列になる
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
res.export(fullfile(s_dir, "branch.csv"), Table="branch");
tab_r = readtable(fullfile(s_dir, "branch.csv"), "ReadRowNames", true, "TextType", "string");
assert(isequal(tab_r.From, tab.From) && isequal(tab_r.To, tab.To) && max(abs(tab_r.Pfrom - tab.Pfrom)) < 1e-12)


%% get_summary of a DC OPF holds the cost, the P sums, the binding count and the LMP range
check_opf("DC OPF")


%% get_summary of an AC OPF also holds the Q sums
check_opf("AC OPF")


function check_opf(s_method)
% get_summary と disp_summary を IEEE9bus の OPF の結果の表と比べる。"DC OPF" には Q がない
net = DebugScript.helper.build_9bus();
res = DebugScript.helper.quiet(@() net.calculate_optimal_powerflow(Method=s_method));
sct = res.get_summary();
tab = res.tab_bus;
assert(sct.l_success && sct.s_Method == s_method && sct.r_cost == res.r_cost && sct.s_Solver == string(res.output.solver))
assert(abs(sct.r_Pgeneration - sum(tab.P(tab.P > 0))) < 1e-12 && abs(sct.r_Pload + sum(tab.P(tab.P < 0))) < 1e-12 ...
    && abs(sct.r_Ploss - sum(tab.P)) < 1e-12)
tab_l = res.get_lmp();
assert(sct.r_LMPmax == max(tab_l.LMP) && sct.r_LMPmin == min(tab_l.LMP))
assert(tab_l{sct.s_LMPmaxBus, "LMP"} == sct.r_LMPmax && tab_l{sct.s_LMPminBus, "LMP"} == sct.r_LMPmin)
assert(sct.n_binding >= sct.n_bindingBranch && isnan(sct.r_minDampingRatio) && isnan(sct.n_outerIteration))
if s_method == "AC OPF"
    assert(abs(sct.r_Qgeneration - sum(tab.Q(tab.P > 0))) < 1e-12 && abs(sct.r_Qloss - sum(tab.Q)) < 1e-12)
else
    assert(isnan(sct.r_Qgeneration) && isnan(sct.r_Qload) && isnan(sct.r_Qloss))
end
% disp_summary: 1 行目のあとはすべて箇条書き
sv = splitlines(res.disp_summary());
assert(startsWith(sv(1), "Optimal power flow of ") && all(startsWith(sv(2:end), "- ")), join(sv, newline))
assert(any(sv == sprintf("- Cost: %.6g", sct.r_cost)) && any(startsWith(sv, "- Binding constraints: " + sct.n_binding)), join(sv, newline))
assert(any(startsWith(sv, "- Generation: P = ")) && any(contains(sv, "Q = ")) == (s_method == "AC OPF"), join(sv, newline))
end
