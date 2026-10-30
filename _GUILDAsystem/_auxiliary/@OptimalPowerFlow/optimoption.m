function [str_solver, c_nv] = optimoption(obj, prob, s_options) %#ok<INUSL>
% Get the solver name and the solve() options for the effective settings.
%
% Returns the Name-Value arguments of solve (Optimization Toolbox) for the effective settings.
% Only settings that differ from the defaults of the solver are passed, so that the
% stored defaults (Solver="auto", Display="default", NaN) call solve(prob, x0) as is.
%
% Inputs:
% - `prob`: Problem built by build_opf_problem.
% - `s_options`: Effective settings (output of get_options).
    arguments (Output)
        str_solver % Solver that runs the problem (linprog, quadprog or fmincon).
        c_nv % Name-Value arguments of solve: Solver and Options when needed.
    end
    if s_options.Solver == "auto"
        str_solver = string(solvers(prob));
    else
        str_solver = s_options.Solver;
        check_solver(prob, str_solver);
    end

    c_opt = {};
    str_alg = "Algorithm_" + str_solver;
    if isfield(s_options, str_alg)
        o_def = optimoptions(str_solver);
        if s_options.(str_alg) ~= string(o_def.Algorithm)
            c_opt = [c_opt, {"Algorithm", s_options.(str_alg)}];
        end
    end
    if s_options.Display ~= "default"
        c_opt = [c_opt, {"Display", s_options.Display}];
    end
    s_num = struct("MaxIteration","MaxIterations", "OptimalityTolerance","OptimalityTolerance", ...
                   "StepTolerance","StepTolerance", "MaxFunctionEvaluations","MaxFunctionEvaluations");
    for str_name = string(fieldnames(s_num)).'
        if ~isnan(s_options.(str_name))
            c_opt = [c_opt, {s_num.(str_name), s_options.(str_name)}]; %#ok<AGROW>
        end
    end
    if s_options.UseParallel && str_solver == "fmincon"
        c_opt = [c_opt, {"UseParallel", true}];
    end

    c_nv = {};
    if s_options.Solver ~= "auto"
        c_nv = {"Solver", str_solver};
    end
    if ~isempty(c_opt)
        c_nv = [c_nv, {"Options", optimoptions(str_solver, c_opt{:})}];
    end
end


function check_solver(prob, str_solver)
% Backend check: a Solver that cannot express the problem (e.g. linprog with a quadratic
% cost or a nonlinear set_opffcn term) stops here with the Solver names that can.
% External backends (stage 3) add their own capability check at this point.
    [~, c_valid] = solvers(prob);
    str_usable = intersect(["linprog","quadprog","fmincon"], string(c_valid), "stable");
    if ~any(str_usable == str_solver)
        error("GUILDA:OptimalPowerFlow:UnsupportedSolver", ...
              "Solver ""%s"" cannot solve this OPF problem. Usable Solver names: ""auto"", %s.", ...
              str_solver, join("""" + str_usable + """", ", "))
    end
end
