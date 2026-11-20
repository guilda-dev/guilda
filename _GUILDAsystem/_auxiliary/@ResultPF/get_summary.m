function sct = get_summary(obj)
% Return the values that disp_summary shows, as a struct.
%
% The fields hold the outcome of the calculation, the numbers of buses and branches, the
% sums of the bus injections, the largest and smallest |V| with their buses and the number
% of violated operating limits. The buses with a positive P are the generation, those with
% a negative P the load: r_Pgeneration and r_Qgeneration are the sums of P and Q of the
% first, r_Pload and r_Qload the sums of -P and -Q of the second (Q of a bus with P = 0
% is in neither), and r_Ploss and r_Qloss the sums of P and Q of all buses. For a result
% that did not converge (flag <= 0) these sums, the |V| fields and n_violation are NaN
% (the bus tags "") as disp_summary leaves them out: the values of the last iterate are
% not a solution. It reads only the stored result.
%
% | Field | Value |
% | --- | --- |
% | `s_network`, `s_Solver` | Tag of the network; option Solver of the run ("" when not held) |
% | `l_success`, `r_flag` | Convergence (flag > 0) and the flag (double) |
% | `n_iteration`, `r_residual`, `r_elapsed` | Iterations, largest residual [pu], elapsed time [s] (NaN when not held) |
% | `n_bus`, `n_slack`, `n_PV`, `n_PQ`, `n_branch` | Numbers of buses by type and of branches |
% | `r_Pgeneration`, `r_Qgeneration` | [pu] Generation (buses with P > 0) |
% | `r_Pload`, `r_Qload` | [pu] Load (buses with P < 0), positive for a consumption |
% | `r_Ploss`, `r_Qloss` | [pu] Losses: sums of P and Q of all buses |
% | `r_Vmax`, `s_VmaxBus`, `r_Vmin`, `s_VminBus` | [pu] Largest and smallest \|V\| and their buses |
% | `n_violation` | Number of violated operating limits (rows of tab_violation) |
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% sct = res.get_summary();
% sct.r_Ploss                  % active power losses [pu]
% [sct.r_Vmin, sct.s_VminBus]  % smallest |V| and its bus
% ```
%
% See also ResultPF.disp_summary, ResultPF.tab_bus, ResultPF.tab_violation
    arguments (Input)
        obj
    end
    arguments (Output)
        sct (1,1) struct  % Summary values (see the table of the help).
    end
    tab = obj.tab_bus;
    s_Solver = "";
    if isfield(obj.options, "Solver")
        s_Solver = string(obj.options.Solver);
    end
    sv_type = bus_data(obj).sv_type;
    sct = struct("s_network", obj.s_network, "s_Solver", s_Solver, "l_success", obj.l_success, "r_flag", double(obj.flag), ...
        "n_iteration", output_value(obj.output, "iterations"), "r_residual", output_value(obj.output, "residual"), ...
        "r_elapsed", obj.r_elapsed, ...
        "n_bus", height(tab), "n_slack", sum(sv_type == "slack"), "n_PV", sum(sv_type == "PV"), ...
        "n_PQ", sum(sv_type == "PQ"), "n_branch", height(obj.tab_branch), ...
        "r_Pgeneration", NaN, "r_Qgeneration", NaN, "r_Pload", NaN, "r_Qload", NaN, "r_Ploss", NaN, "r_Qloss", NaN, ...
        "r_Vmax", NaN, "s_VmaxBus", "", "r_Vmin", NaN, "s_VminBus", "", "n_violation", NaN);
    if ~obj.l_success || height(tab) == 0
        return
    end
    lv_gen  = tab.P > 0;
    lv_load = tab.P < 0;
    sct.r_Pgeneration = sum(tab.P(lv_gen));
    sct.r_Qgeneration = sum(tab.Q(lv_gen));
    sct.r_Pload = -sum(tab.P(lv_load));
    sct.r_Qload = -sum(tab.Q(lv_load));
    sct.r_Ploss = sum(tab.P);
    sct.r_Qloss = sum(tab.Q);
    sv_tag = string(tab.Properties.RowNames);
    [sct.r_Vmax, i_max] = max(tab.V);
    [sct.r_Vmin, i_min] = min(tab.V);
    sct.s_VmaxBus = sv_tag(i_max);
    sct.s_VminBus = sv_tag(i_min);
    sct.n_violation = height(obj.tab_violation);
end


function r = output_value(sct_output, s_name)
% A numeric scalar field of the solver output (NaN when absent)
    r = NaN;
    if isfield(sct_output, s_name) && isnumeric(sct_output.(s_name)) && isscalar(sct_output.(s_name))
        r = double(sct_output.(s_name));
    end
end
