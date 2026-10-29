function [str_solver, c_nv] = optimoption(obj, prob, s_options) %#ok<INUSL>
% <@Desc>
% Name-Value arguments of solve (Optimization Toolbox) for the effective settings.
% Only settings that differ from the defaults of the solver are passed, so that the
% stored defaults (Solver="auto", Display="default", NaN) call solve(prob, x0) as is.
% <@Role> Settings
% <@Summary> Solver name and solve() options for the effective settings.
% <@Signatures>
% [
%   "[str_solver, c_nv] = optimoption(obj, prob, s_options)"
% ]
% <@Parameters>
% [
%   {"Name": "obj", "Type": "OptimalPowerFlow", "Description": "Solver (net.solver_OPF).", "Required": true, "Default": "-"},
%   {"Name": "prob", "Type": "optim.problemdef.OptimizationProblem", "Description": "Problem built by build_opf_problem.", "Required": true, "Default": "-"},
%   {"Name": "s_options", "Type": "struct", "Description": "Effective settings (output of get_options).", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "str_solver", "Type": "string scalar", "Description": "Solver that runs the problem (linprog, quadprog or fmincon)."},
%   {"Name": "c_nv", "Type": "cell", "Description": "Name-Value arguments of solve: Solver and Options when needed."}
% ]
    if s_options.Solver == "auto"
        str_solver = string(solvers(prob));
    else
        str_solver = s_options.Solver;
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
