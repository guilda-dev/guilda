function sct = solver_info(sct)
% Solver information of the ResultODE constructor with the missing fields set to their
% defaults
    arguments (Input)
        sct struct % Given solver information (fields of the constructor input sct_solver).
    end
    arguments (Output)
        sct struct % Every field: solver, options, flag, output, elapsed.
    end
    sct_default = struct("solver", "SolverODE", "options", struct(), "flag", false, ...
        "output", struct(), "elapsed", NaN);
    for s_name = string(fieldnames(sct_default)).'
        if ~isfield(sct, s_name)
            sct.(s_name) = sct_default.(s_name);
        end
    end
end
