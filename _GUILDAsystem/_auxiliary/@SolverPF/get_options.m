function sct_options = get_options(obj, nv)
% Get the effective settings of one run as a struct.
%
% The PowerFlowCalculation section of GUILDA.setting (GUILDA.config("PowerFlowCalculation"))
% with the Name-Value overrides of the call applied. Neither the solver nor the settings
% file is changed. A name that is not in OptionMap stops with
% GUILDA:resolve_options:UnknownName; an invalid value stops with the validation error of
% the option.
    arguments (Input)
        obj % Solver (net.solver_PF).
        nv (1,:) cell = {} % Name-Value overrides: the names of SolverPF.OptionMap.
    end
    arguments (Output)
        sct_options % One field per setting of the section, and Display ("none" or "iter").
    end
    sct_options = default_options();
    sct_given   = tools.resolve_options(sct_options, SolverPF.OptionMap, nv);
    validate_options(nv{:});
    for s_name = string(fieldnames(sct_given)).'
        sct_options.(s_name) = sct_given.(s_name);
    end
    sct_options.Method = string(sct_options.Method);
    sct_options.WhenFailed = string(sct_options.WhenFailed);
    sct_options.Display = string(sct_options.Display);
    sct_options.WarmStart = logical(sct_options.WarmStart);
end


function sct = default_options()
% Values of the PowerFlowCalculation section, and Display (Verbose=false)
    sct_cfg = GUILDA.config("PowerFlowCalculation");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    sct.Display = "none";
end
