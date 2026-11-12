function varargout = disp_summary(obj)
% Display a summary of the power flow result.
%
% Shows the outcome of the calculation (Solver, flag, iterations, largest residual,
% elapsed time and the message), the number of buses of each type and of branches, the
% sums of the bus injections (generation: the positive P; load: the negative P; losses:
% the sum of P and of Q), the largest and smallest |V| with their buses, and the number
% of violated operating limits (tab_violation). It reads only the stored result. With one
% output it returns the text instead of displaying it.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% res.disp_summary()
% s = res.disp_summary();      % as text
% ```
%
% See also ResultPF.disp_bus, ResultPF.disp_branch, ResultPF.disp_violation
    arguments (Input)
        obj
    end
    arguments (Output, Repeating)
        varargout % Summary text when one output is requested; displayed otherwise.
    end
    sct = bus_data(obj);
    tab = obj.tab_bus;
    s_solver = "";
    if isfield(obj.options, "Solver")
        s_solver = " (Solver " + string(obj.options.Solver) + ")";
    end
    s_state = "not converged";
    if obj.l_success
        s_state = "converged";
    end
    sv = "Power flow of " + obj.s_network + s_solver + ": " + s_state + ", flag " + string(obj.flag);
    sv(end+1) = "  iterations " + field_text(obj.output, "iterations") + ", largest residual " + ...
                field_text(obj.output, "residual") + " pu, elapsed " + sprintf("%.3g", obj.r_elapsed) + " s";
    if isfield(obj.output, "message")
        sv(end+1) = "  " + strip(string(obj.output.message));
    end
    if height(tab) == 0
        varargout = show_text(join(sv, newline), nargout);
        return
    end
    sv(end+1) = sprintf("  buses %d (slack %d, PV %d, PQ %d), branches %d", height(tab), ...
        sum(sct.sv_type == "slack"), sum(sct.sv_type == "PV"), sum(sct.sv_type == "PQ"), height(obj.tab_branch));
    sv(end+1) = sprintf("  generation P %.4f pu, load P %.4f pu, losses P %.4f pu, Q %.4f pu", ...
        sum(tab.P(tab.P > 0)), -sum(tab.P(tab.P < 0)), sum(tab.P), sum(tab.Q));
    [r_max, i_max] = max(tab.V);
    [r_min, i_min] = min(tab.V);
    sv(end+1) = sprintf("  |V| max %.4f pu at %s, min %.4f pu at %s", r_max, sct.sv_tag(i_max), r_min, sct.sv_tag(i_min));
    sv(end+1) = sprintf("  violated operating limits: %d", height(obj.tab_violation));
    varargout = show_text(join(sv, newline), nargout);
end


function s = field_text(sct, s_name)
% A numeric field of the solver output as text ("-" when absent)
    s = "-";
    if isfield(sct, s_name) && isnumeric(sct.(s_name)) && isscalar(sct.(s_name))
        s = string(sprintf("%.3g", sct.(s_name)));
    end
end
