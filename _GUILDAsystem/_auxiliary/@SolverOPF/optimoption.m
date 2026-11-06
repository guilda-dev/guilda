function [s_solver, c_nv] = optimoption(obj, prob, sct_options)
% Get the solver name and the solve() options for the effective settings.
%
% Returns the Name-Value arguments of solve (Optimization Toolbox) for the effective settings.
% Only settings that differ from the defaults of the solver are passed, so that the
% stored defaults (Solver="auto", Display="default", NaN) call solve(prob, x0) as is.
    arguments (Input)
        obj  %#ok<INUSA>
        prob                       % Problem built by build_opf_problem.
        sct_options  (1,1) struct  % Effective settings (output of get_options).
    end
    arguments (Output)
        s_solver                   % Solver that runs the problem (linprog, quadprog or fmincon).
        c_nv                       % Name-Value arguments of solve: Solver and Options when needed.
    end
    if sct_options.Solver == "auto"
        s_solver = string(solvers(prob));
    else
        s_solver = sct_options.Solver;
        check_solver(prob, s_solver);
    end

    c_opt = {};
    s_alg = "Algorithm_" + s_solver;
    if isfield(sct_options, s_alg)
        o_def = optimoptions(s_solver);
        if sct_options.(s_alg) ~= string(o_def.Algorithm)
            c_opt = [c_opt, {"Algorithm", sct_options.(s_alg)}];
        end
    end
    if sct_options.Display ~= "default"
        c_opt = [c_opt, {"Display", sct_options.Display}];
    end
    sct_num = struct("MaxIteration","MaxIterations", "OptimalityTolerance","OptimalityTolerance", ...
                   "StepTolerance","StepTolerance", "MaxFunctionEvaluations","MaxFunctionEvaluations");
    for s_name = string(fieldnames(sct_num)).'
        if ~isnan(sct_options.(s_name))
            c_opt = [c_opt, {sct_num.(s_name), sct_options.(s_name)}]; %#ok<AGROW>
        end
    end
    if sct_options.UseParallel && s_solver == "fmincon"
        c_opt = [c_opt, {"UseParallel", true}];
    end

    c_nv = {};
    if sct_options.Solver ~= "auto"
        c_nv = {"Solver", s_solver};
    end
    if ~isempty(c_opt)
        c_nv = [c_nv, {"Options", optimoptions(s_solver, c_opt{:})}];
    end
end


function check_solver(prob, s_solver)
% Backend check: a Solver that cannot express the problem (e.g. linprog with a quadratic
% cost or a nonlinear Cost or Constraint term) stops here with the Solver names that can.
% External backends (stage 3) add their own capability check at this point.
    [~, c_valid] = solvers(prob);
    sr_usable = intersect(["linprog","quadprog","fmincon"], string(c_valid), "stable");
    if ~any(sr_usable == s_solver)
        error(msg("GUILDA:SolverOPF:UnsupportedSolver", s_solver, join("""" + sr_usable + """", ", ")))
    end
end
