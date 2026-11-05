function o = makeODE(sct_options)
% MATLAB ode object with the settings of sct_options: every public property of ode that is
% a field of sct_options is set, in the property order of ode (Solver before SolverOptions).
    o = ode;

    cls = metaclass(o);
    pList = arrayfun(@(P) P.Name, cls.PropertyList, 'UniformOutput', false);
    pLogc = arrayfun(@(P) strcmp(P.SetAccess, 'public'), cls.PropertyList);

    props = pList(pLogc);

    for ip = 1:numel(props)
        if isfield(sct_options, props{ip})
            o.(props{ip}) = sct_options.(props{ip});
        end
    end
end
