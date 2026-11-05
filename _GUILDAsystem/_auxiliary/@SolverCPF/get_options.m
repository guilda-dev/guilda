function sct_options = get_options(obj, nv)
% Get the effective settings of one run as a struct.
%
% Every stored setting of the solver, with the Name-Value overrides of the call applied. The solver itself is not changed.
% A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
% an invalid value stops with the validation error of the option.
    arguments (Input)
        obj % Solver holding the defaults (net.solver_CPF).
        nv (1,:) cell = {} % Name-Value overrides: LoadBus, MaxIteration, Tolerance, StepSize, ArcLength, InitialLambda, UseInternalState, Verbose.
    end
    arguments (Output)
        sct_options % One field per setting (LoadBus, InitialLambda, MaxIterations, StepSize, ArcLength, Tolerance, UseInternalState, Verbose).
    end
    sct_given = tools.resolve_options(obj, SolverCPF.OptionMap, nv);
    validate_options(nv{:});

    mc = metaclass(obj);
    a_prop = mc.PropertyList(~[mc.PropertyList.Constant] & strcmp({mc.PropertyList.SetAccess}, 'public'));
    sct_options = struct();
    for s_prop = string({a_prop.Name})
        if isfield(sct_given, s_prop)
            sct_options.(s_prop) = sct_given.(s_prop);
        else
            sct_options.(s_prop) = obj.(s_prop);
        end
    end
    sct_options.LoadBus = reshape(string(sct_options.LoadBus), 1, []);
end
