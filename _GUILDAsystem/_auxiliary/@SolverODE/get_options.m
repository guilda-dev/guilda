function sct_options = get_options(obj, nv)
% Get the effective settings of one run as a struct.
%
% The TimeSimulation section of GUILDA.setting (GUILDA.config("TimeSimulation")) with the
% Name-Value overrides of the call applied (net.simulate passes the Options of the
% scenarios as Name-Value options). Neither the solver nor the settings file is changed.
% SolverOptions is [] unless given: the ode object then uses the options of its Solver.
% A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName; an invalid
% value stops with the validation error of the option.
    arguments (Input)
        obj %#ok<INUSA> Solver (net.solver_ODE); it holds no settings.
        nv (1,:) cell = {} % Name-Value overrides: Solver, SolverOptions, Tolerance, AbsoluteTolerance, SeparateComplexParts, TimeLimit, Progress, Verbose, PlotFcn.
    end
    arguments (Output)
        sct_options % One field per setting of the section (Solver, Tolerance, AbsoluteTolerance, SeparateComplexParts, Progress, TimeLimit, Verbose, PlotFcn) and SolverOptions.
    end
    sct_options = default_options();
    sct_given   = tools.resolve_options(sct_options, SolverODE.OptionMap, nv);
    validate_options(nv{:});
    for s_name = string(fieldnames(sct_given)).'
        sct_options.(s_name) = sct_given.(s_name);
    end
    sct_options.Solver   = string(sct_options.Solver);
    sct_options.Progress = SolverODE.progress_mode(sct_options.Progress);
    sct_options.Verbose  = logical(sct_options.Verbose);
    sct_options.SeparateComplexParts = matlab.lang.OnOffSwitchState(sct_options.SeparateComplexParts);
    tools.check_plotfcn(sct_options.PlotFcn, "simulate");
end


function sct = default_options()
% Values of the TimeSimulation section, and SolverOptions [] (the options of the Solver)
    sct_cfg = GUILDA.config("TimeSimulation");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    if ~(isnumeric(sct.TimeLimit) && isscalar(sct.TimeLimit) && sct.TimeLimit > 0)
        sct.TimeLimit = Inf;      % 0, empty or invalid: no limit
    end
    sct.SolverOptions = [];
end
