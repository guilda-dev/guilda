function o = makeODE(sct_options)
% MATLAB ode object with the settings of sct_options: every public property of ode that is
% a field of sct_options is set, in the property order of ode (Solver before SolverOptions).
    arguments (Input)
        sct_options  (1,1) struct  % Effective settings (output of SolverODE.get_options).
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
    if isempty(sct_ode.SolverOptions)
        sct_ode = rmfield(sct_ode, "SolverOptions");      % the options of the Solver
    end
    for ip = 1:numel(props)
        if isfield(sct_ode, props{ip})
            o.(props{ip}) = sct_ode.(props{ip});
        end
    end
end
