function varargout = disp_summary(obj)
% Display a summary of the optimal power flow result.
%
% Shows a title line with the outcome (Method, solver, solved or not, flag) and one bullet
% per item: the calculation (iterations, elapsed time), the optimal cost, the generation
% (buses with a positive P), the load (buses with a negative P) and the losses (sums over
% all buses; 0 in "DC OPF" and "ELD"), each with P and, in "AC OPF", Q, the number of
% binding constraints (see disp_binding; branch limits among them), the range of the
% locational marginal prices (see get_lmp) with their buses, and for a stability-
% constrained "AC OPF" (sct_stability) the smallest damping ratio and the largest real
% part of the eigenvalues at the solution with the number of outer iterations. The values
% are those of get_summary. It reads only the stored result. With one output it returns
% the text instead of displaying it.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_optimal_powerflow(Method="DC OPF");
% res.disp_summary()
% s = res.disp_summary();      % as text
% ```
%
% See also ResultOPF.get_summary, ResultOPF.disp_binding, ResultOPF.get_lmp, ResultPF.disp_summary
    arguments (Input)
        obj
    end
    arguments (Output, Repeating)
        varargout  % Summary text when one output is requested; displayed otherwise.
    end
    sct = obj.get_summary();
    s_state = "not solved";
    if sct.l_success
        s_state = "solved";
    end
    s_solver = "";
    if sct.s_Solver ~= ""
        s_solver = ", " + sct.s_Solver;
    end
    s_it = "-";
    if ~isnan(sct.n_iteration)
        s_it = string(sct.n_iteration);
    end
    sv = "Optimal power flow of " + sct.s_network + " (" + sct.s_Method + s_solver + "): " ...
       + s_state + ", flag " + string(sct.r_flag);
    sv(end+1) = sprintf("- Calculation: %s iterations, elapsed %.3g s", s_it, sct.r_elapsed);
    sv(end+1) = sprintf("- Cost: %.6g", sct.r_cost);
    if ~isnan(sct.r_Pgeneration)
        sv(end+1) = "- Generation: " + pq_text(sct.r_Pgeneration, sct.r_Qgeneration);
        sv(end+1) = "- Load: "       + pq_text(sct.r_Pload, sct.r_Qload);
        sv(end+1) = "- Losses: "     + pq_text(sct.r_Ploss, sct.r_Qloss);
        sv(end+1) = sprintf("- Binding constraints: %d (branch limits %d)", sct.n_binding, sct.n_bindingBranch);
        sv(end+1) = sprintf("- LMP: %.6g at %s to %.6g at %s (cost per pu)", sct.r_LMPmin, sct.s_LMPminBus, ...
            sct.r_LMPmax, sct.s_LMPmaxBus);
        if ~isnan(sct.n_outerIteration)
            sv(end+1) = sprintf("- Stability: minimum damping ratio %.4g, largest real part %.4g 1/s, outer iterations %d", ...
                sct.r_minDampingRatio, sct.r_maxRealPart, sct.n_outerIteration);
        end
    end
    sv = join(sv, newline);
    if nargout == 1
        varargout = {sv};
    else
        disp(sv)
    end
end


function s = pq_text(r_P, r_Q)
% "P = x pu, Q = y pu", without Q when the method has none (NaN)
    s = sprintf("P = %.4f pu", r_P);
    if ~isnan(r_Q)
        s = s + sprintf(", Q = %.4f pu", r_Q);
    end
end
