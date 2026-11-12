function o = makeODE(sct_options)
% MATLAB ode object with the settings of sct_options: every public property of ode that is
% a field of sct_options is set, in the property order of ode; then MaxStep and InitialStep
% go into the SolverOptions of the Solver when they are not NaN (NaN: the solver default).
    arguments (Input)
        sct_options  (1,1) struct  % Effective settings (net.simulate).
    end
    arguments (Output)
        o                          % MATLAB ode object with the settings.
    end
    o = ode;

    cls = metaclass(o);
    pList = arrayfun(@(P) P.Name, cls.PropertyList, 'UniformOutput', false);
    pLogc = arrayfun(@(P) strcmp(P.SetAccess, 'public'), cls.PropertyList);

    props = pList(pLogc);

    sct_ode = sct_options;
    sct_ode.RelativeTolerance = sct_options.Tolerance;    % Name-Value option and setting Tolerance
    if isfield(sct_ode, "SeparateComplexParts")
        sct_ode.SeparateComplexParts = matlab.lang.OnOffSwitchState(sct_ode.SeparateComplexParts);   % logical setting -> "on" / "off"
    end
    for ip = 1:numel(props)
        if isfield(sct_ode, props{ip})
            o.(props{ip}) = sct_ode.(props{ip});
        end
    end
    for s_name = ["MaxStep", "InitialStep"]
        if isfield(sct_options, s_name) && ~isnan(sct_options.(s_name))
            o.SolverOptions.(s_name) = sct_options.(s_name);
        end
    end
end
