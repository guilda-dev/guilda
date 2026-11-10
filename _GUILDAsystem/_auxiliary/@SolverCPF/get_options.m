function sct_options = get_options(obj, nv)
% Get the effective settings of one run as a struct.
%
% The ContinuationPowerFlow section of GUILDA.setting (GUILDA.config("ContinuationPowerFlow"))
% and the condition LoadBus of the solver, with the Name-Value overrides of the call
% applied. Neither the solver nor the settings file is changed. A name that is not in
% OptionMap stops with GUILDA:resolve_options:UnknownName; an invalid value stops with the
% validation error of the option.
    arguments (Input)
        obj % Solver holding the condition LoadBus (net.solver_CPF).
        nv (1,:) cell = {} % Name-Value overrides: LoadBus, MaxIteration, Tolerance, StepSize, ArcLength, InitialLambda, UseInternalState, Verbose, Limits, PlotFcn.
    end
    arguments (Output)
        sct_options % One field per setting of the section (InitialLambda, MaxIteration, StepSize, ArcLength, Tolerance, Corrector*, Increment, Limits, UseInternalState, Verbose, PlotFcn) and LoadBus.
    end
    sct_options = default_options(obj);
    sct_given   = tools.resolve_options(sct_options, SolverCPF.OptionMap, nv);
    validate_options(nv{:});
    for s_name = string(fieldnames(sct_given)).'
        sct_options.(s_name) = sct_given.(s_name);
    end
    sct_options.LoadBus = reshape(string(sct_options.LoadBus), 1, []);
    sct_options.Limits  = reshape(string(sct_options.Limits), 1, []);
    sct_options.UseInternalState = logical(sct_options.UseInternalState);
    sct_options.Verbose = logical(sct_options.Verbose);
    validate_options(Limits=sct_options.Limits);    % also the value of GUILDA.setting
    tools.check_plotfcn(sct_options.PlotFcn, "calculate_continuation_powerflow");
end


function sct = default_options(obj)
% Values of the ContinuationPowerFlow section and the condition LoadBus of the solver
    sct_cfg = GUILDA.config("ContinuationPowerFlow");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    sct.LoadBus = obj.LoadBus;
end
