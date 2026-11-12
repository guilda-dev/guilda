function sct = solver_info(sct)
% Solver information of the ResultPF constructor with the missing fields set to their
% defaults
    arguments (Input)
        sct struct % Given solver information (fields of the constructor input sct_solver).
    end
    arguments (Output)
        sct struct % Every field: solver, options, flag, output, elapsed, cm_Vhistory, rv_step, tab_PFcondition.
    end
    sct_default = struct("solver", "SolverPF", "options", struct(), "flag", false, ...
        "output", struct(), "elapsed", NaN, "cm_Vhistory", zeros(0,0), "rv_step", zeros(1,0), ...
        "tab_PFcondition", table());
    for s_name = string(fieldnames(sct_default)).'
        if ~isfield(sct, s_name)
            sct.(s_name) = sct_default.(s_name);
        end
    end
end
