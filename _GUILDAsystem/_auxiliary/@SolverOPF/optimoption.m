function [s_solver, c_nv] = optimoption(obj, prob, sct_options)
% Get the solver name and the solve() options for the effective settings.
%
% Returns the Name-Value arguments of solve (Optimization Toolbox) for the effective settings.
% Display follows Verbose ("iter" or "none"); the other settings are passed only when they
% differ from the defaults of the solver (NaN: the default). MaxIteration and Tolerance go
% to every solver; a setting <Solver><option> (LinprogAlgorithm, QuadprogStepTolerance,
% FminconUseParallel, ...) only to that solver. PlotFcn becomes the PlotFcn
% option of fmincon (keys k as optimplot<k>, a handle as it is); with linprog or quadprog,
% a PlotFcn other than "none" stops with GUILDA:SolverOPF:PlotFcnUnsupported.
    arguments (Input)
        obj  %#ok<INUSA>
        prob                       % Problem built by build_opf_problem.
        sct_options  (1,1) struct  % Effective settings of the run (built by calculate_optimal_powerflow).
    end
    arguments (Output)
        s_solver                   % Solver that runs the problem (linprog, quadprog or fmincon).
        c_nv                       % Name-Value arguments of solve: Solver and Options when needed.
    end
    if sct_options.Solver == "auto"
        s_solver = string(solvers(prob));
    else
        % a Solver that cannot express the problem (e.g. linprog with a quadratic cost or a
        % nonlinear Cost or Constraint term) stops with the Solver names that can
        s_solver = sct_options.Solver;
        [~, c_valid] = solvers(prob);
        sr_usable = intersect(["linprog","quadprog","fmincon"], string(c_valid), "stable");
        if ~any(sr_usable == s_solver)
            error(msg("GUILDA:SolverOPF:UnsupportedSolver", s_solver, join("""" + sr_usable + """", ", ")))
        end
    end

    c_opt = {};
    s_pre = upper(extractBefore(s_solver, 2)) + extractAfter(s_solver, 1);    % key prefix of the solver: "Fmincon"
    s_alg = s_pre + "Algorithm";
    if isfield(sct_options, s_alg)
        o_def = optimoptions(s_solver);
        if sct_options.(s_alg) ~= string(o_def.Algorithm)
            c_opt = [c_opt, {"Algorithm", sct_options.(s_alg)}];
        end
    end
    if sct_options.Verbose
        c_opt = [c_opt, {"Display", "iter"}];
    else
        c_opt = [c_opt, {"Display", "none"}];
    end
    if ~isequal(sct_options.PlotFcn, "none")
        if s_solver ~= "fmincon"
            error(msg("GUILDA:SolverOPF:PlotFcnUnsupported", s_solver, sct_options.Method))
        end
        if isa(sct_options.PlotFcn, "function_handle")
            c_opt = [c_opt, {"PlotFcn", sct_options.PlotFcn}];
        else
            c_opt = [c_opt, {"PlotFcn", cellstr("optimplot" + sct_options.PlotFcn)}];
        end
    end
    % common settings (every solver), then the settings <Solver><option> of this solver
    sct_num = struct("MaxIteration","MaxIterations", "Tolerance","OptimalityTolerance");
    for s_opt = ["StepTolerance","MaxFunctionEvaluations"]
        if isfield(sct_options, s_pre + s_opt)
            sct_num.(s_pre + s_opt) = s_opt;
        end
    end
    for s_name = string(fieldnames(sct_num)).'
        if ~isnan(sct_options.(s_name))
            c_opt = [c_opt, {sct_num.(s_name), sct_options.(s_name)}]; %#ok<AGROW>
        end
    end
    if isfield(sct_options, s_pre + "UseParallel") && sct_options.(s_pre + "UseParallel")
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

