function sct = get_summary(obj)
% Return the values that disp_summary shows, as a struct.
%
% The fields hold the outcome of the calculation, the optimal cost, the sums of the bus
% injections, the numbers of binding constraints, the range of the locational marginal
% prices (get_lmp) with their buses and, for a stability-constrained "AC OPF"
% (sct_stability), the stability at the solution. The buses with a positive P are the
% generation, those with a negative P the load: r_Pgeneration and r_Qgeneration are the
% sums of P and Q of the first, r_Pload and r_Qload the sums of -P and -Q of the second,
% and r_Ploss and r_Qloss the sums of P and Q of all buses (P losses are 0 in "DC OPF" and
% "ELD"). The Q fields are NaN in "DC OPF" and "ELD", which have no Q, and the stability
% fields NaN without sct_stability. Like disp_summary, it gives the values of the stored
% solution also when the solver did not succeed (l_success false). It reads only the stored
% result.
%
% | Field | Value |
% | --- | --- |
% | `s_network`, `s_Method`, `s_Solver` | Tag of the network; option Method of the run; the optimization solver ("" when not held) |
% | `l_success`, `r_flag` | Success (flag > 0) and the flag (double) |
% | `n_iteration`, `r_elapsed` | Iterations (NaN when not held), elapsed time [s] |
% | `r_cost` | Optimal cost (total generation cost of tab_parameter.OPF) |
% | `r_Pgeneration`, `r_Qgeneration` | [pu] Generation (buses with P > 0) |
% | `r_Pload`, `r_Qload` | [pu] Load (buses with P < 0), positive for a consumption |
% | `r_Ploss`, `r_Qloss` | [pu] Losses: sums of P and Q of all buses |
% | `n_binding`, `n_bindingBranch` | Numbers of binding constraints (disp_binding) and of the branch limits among them |
% | `r_LMPmin`, `s_LMPminBus`, `r_LMPmax`, `s_LMPmaxBus` | Smallest and largest LMP (cost per pu) and their buses |
% | `r_minDampingRatio`, `r_maxRealPart`, `n_outerIteration` | Stability: smallest damping ratio, largest real part [1/s] of the eigenvalues at the solution, outer iterations |
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_optimal_powerflow(Method="AC OPF");
% sct = res.get_summary();
% sct.r_cost                       % optimal cost
% [sct.r_LMPmax, sct.s_LMPmaxBus]  % highest nodal price and its bus
% ```
%
% See also ResultOPF.disp_summary, ResultOPF.get_lmp, ResultOPF.disp_binding
    arguments (Input)
        obj
    end
    arguments (Output)
        sct (1,1) struct  % Summary values (see the table of the help).
    end
    s_Solver = "";
    if isfield(obj.output, "solver")
        s_Solver = string(obj.output.solver);
    end
    n_iteration = NaN;
    if isfield(obj.output, "iterations")
        n_iteration = double(obj.output.iterations);
    end
    sct = struct("s_network", obj.s_network, "s_Method", string(obj.options.Method), "s_Solver", s_Solver, ...
        "l_success", obj.l_success, "r_flag", double(obj.flag), "n_iteration", n_iteration, "r_elapsed", obj.r_elapsed, ...
        "r_cost", obj.r_cost, ...
        "r_Pgeneration", NaN, "r_Qgeneration", NaN, "r_Pload", NaN, "r_Qload", NaN, "r_Ploss", NaN, "r_Qloss", NaN, ...
        "n_binding", NaN, "n_bindingBranch", NaN, ...
        "r_LMPmin", NaN, "s_LMPminBus", "", "r_LMPmax", NaN, "s_LMPmaxBus", "", ...
        "r_minDampingRatio", NaN, "r_maxRealPart", NaN, "n_outerIteration", NaN);
    tab = obj.tab_bus;
    if height(tab) == 0
        return
    end
    lv_gen  = tab.P > 0;
    lv_load = tab.P < 0;
    sct.r_Pgeneration = sum(tab.P(lv_gen));
    sct.r_Pload = -sum(tab.P(lv_load));
    sct.r_Ploss = sum(tab.P);
    if ismember("Q", tab.Properties.VariableNames)
        sct.r_Qgeneration = sum(tab.Q(lv_gen));
        sct.r_Qload = -sum(tab.Q(lv_load));
        sct.r_Qloss = sum(tab.Q);
    end
    tab_b = binding_table(obj);
    sct.n_binding = height(tab_b);
    sct.n_bindingBranch = sum(startsWith(tab_b.Constraint, ["Pmax_","Qmax_","Imax_","Smax_","VargMax1_","VargMax2_"]));
    tab_l = obj.get_lmp();
    sv_bus = string(tab_l.Properties.RowNames);
    [sct.r_LMPmax, i_max] = max(tab_l.LMP);
    [sct.r_LMPmin, i_min] = min(tab_l.LMP);
    sct.s_LMPmaxBus = sv_bus(i_max);
    sct.s_LMPminBus = sv_bus(i_min);
    if isfield(obj.sct_stability, "tab_iteration")
        tab_s = obj.sct_stability.tab_iteration;
        sct.r_minDampingRatio = tab_s.MinDampingRatio(end);
        sct.r_maxRealPart = tab_s.MaxRealPart(end);
        sct.n_outerIteration = height(tab_s);
    end
end
