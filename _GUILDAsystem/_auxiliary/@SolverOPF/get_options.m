function sct_options = get_options(obj, nv)
% Get the effective settings of one run as a struct.
%
% The OptimalPowerFlow section of GUILDA.setting (GUILDA.config("OptimalPowerFlow")) and the
% conditions of the solver (Cost, Constraint, DefaultCost, ReferenceBus), with the
% Name-Value overrides of the call applied. Neither the solver nor the settings file is
% changed. A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
% an invalid value stops with the validation error of the option.
    arguments (Input)
        obj % Solver holding the conditions (net.solver_OPF).
        nv (1,:) cell = {} % Name-Value overrides: Method, Solver, Tolerance, MaxIteration, Verbose, Cost, Constraint, DefaultCost, ReferenceBus, PlotFcn.
    end
    arguments (Output)
        sct_options % One field per setting of the section (Method, Solver, Algorithm_*, Verbose, MaxIteration, Tolerance, ..., PlotFcn) and per condition.
    end
    sct_options = default_options(obj);
    sct_given   = tools.resolve_options(sct_options, SolverOPF.OptionMap, nv);
    validate_options(nv{:});
    for s_name = string(fieldnames(sct_given)).'
        sct_options.(s_name) = sct_given.(s_name);
    end
    sct_options.Method       = string(sct_options.Method);
    sct_options.Solver       = string(sct_options.Solver);
    sct_options.Verbose      = logical(sct_options.Verbose);
    sct_options.ReferenceBus = string(sct_options.ReferenceBus);
    for s_alg = ["Algorithm_linprog","Algorithm_quadprog","Algorithm_fmincon"]
        sct_options.(s_alg) = string(sct_options.(s_alg));
    end
    sct_options.PlotFcn = tools.check_plotfcn(sct_options.PlotFcn, "optimize_powerflow", plot_keys());
end


function sct = default_options(obj)
% Values of the OptimalPowerFlow section and the conditions of the solver
    sct_cfg = GUILDA.config("OptimalPowerFlow");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    sct = rmfield(sct, intersect("WarmStart", fieldnames(sct)));   % a call option of optimize_powerflow
    for s_name = ["Cost","Constraint","DefaultCost","ReferenceBus"]
        sct.(s_name) = obj.(s_name);
    end
end
