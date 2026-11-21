function varargout = disp_summary(obj)
% Display a summary of the power flow result.
%
% Shows a title line with the outcome (Solver, converged or not, flag) and one bullet per
% item: the calculation (iterations, largest residual, elapsed time), the message of the
% solver, the numbers of buses of each type and of branches, the generation (buses with a
% positive P), the load (buses with a negative P) and the losses (sums over all buses),
% each with P and Q, the largest and smallest |V| with their buses, and the number of
% violated operating limits (tab_violation). The values are those of get_summary. For a
% result that did not converge (flag <= 0) the injection sums, |V| and violations are
% left out, with a bullet saying so: the values of the last iterate are not a solution.
% It reads only the stored result. With one output it returns the text instead of
% displaying it, by the same rule.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% res.disp_summary()
% s = res.disp_summary();      % as text
% ```
%
% See also ResultPF.get_summary, ResultPF.disp_bus, ResultPF.disp_branch, ResultPF.disp_violation
    arguments (Input)
        obj
    end
    arguments (Output, Repeating)
        varargout  % Summary text when one output is requested; displayed otherwise.
    end
    sct = obj.get_summary();
    s_solver = "";
    if sct.s_Solver ~= ""
        s_solver = " (Solver " + sct.s_Solver + ")";
    end
    s_state = "not converged";
    if sct.l_success
        s_state = "converged";
    end
    sv = "Power flow of " + sct.s_network + s_solver + ": " + s_state + ", flag " + string(sct.r_flag);
    sv(end+1) = "- Calculation: " + number_text(sct.n_iteration) + " iterations, largest residual " + ...
                number_text(sct.r_residual) + " pu, elapsed " + number_text(sct.r_elapsed) + " s";
    if isfield(obj.output, "message")
        sv(end+1) = "- Message: " + strip(string(obj.output.message));
    end
    if sct.n_bus > 0
        sv(end+1) = sprintf("- Network: %d buses (slack %d, PV %d, PQ %d), %d branches", ...
            sct.n_bus, sct.n_slack, sct.n_PV, sct.n_PQ, sct.n_branch);
        if sct.l_success
            sv(end+1) = sprintf("- Generation: P = %.4f pu, Q = %.4f pu", sct.r_Pgeneration, sct.r_Qgeneration);
            sv(end+1) = sprintf("- Load: P = %.4f pu, Q = %.4f pu", sct.r_Pload, sct.r_Qload);
            sv(end+1) = sprintf("- Losses: P = %.4f pu, Q = %.4f pu", sct.r_Ploss, sct.r_Qloss);
            sv(end+1) = sprintf("- |V|: max %.4f pu at %s, min %.4f pu at %s", sct.r_Vmax, sct.s_VmaxBus, sct.r_Vmin, sct.s_VminBus);
            sv(end+1) = sprintf("- Violated operating limits: %d", sct.n_violation);
        else
            sv(end+1) = "- Not converged: injection sums, |V| and violated limits are not shown";
        end
    end
    varargout = show_text(join(sv, newline), nargout);
end


function s = number_text(r)
% A number of the summary as text ("-" when not held)
    s = "-";
    if ~isnan(r)
        s = string(sprintf("%.3g", r));
    end
end
