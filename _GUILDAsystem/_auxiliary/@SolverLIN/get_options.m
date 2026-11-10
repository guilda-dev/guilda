function sct_options = get_options(obj, nv)
% Get the effective settings of one run as a struct.
%
% The Linearization section of GUILDA.setting (GUILDA.config("Linearization")) with the
% Name-Value overrides of the call applied; Point is [] (the equilibrium) unless given.
% Neither the solver nor the settings file is changed. A name that is not in OptionMap
% stops with GUILDA:resolve_options:UnknownName; an invalid value stops with the
% validation error of the option.
    arguments (Input)
        obj % Solver (net.solver_LIN); it holds no settings.
        nv (1,:) cell = {} % Name-Value overrides: Method, Point, Coordinate, PlotFcn.
    end
    arguments (Output)
        sct_options % Fields Method, Coordinate, PlotFcn (settings of the section) and Point.
    end
    [nv, rv_nonUnit] = v3_linearize_args(nv, obj.NonUnit);              % COMPAT(v3)
    sct_options = default_options();
    sct_given   = tools.resolve_options(sct_options, SolverLIN.OptionMap, nv);
    validate_options(nv{:});
    for s_name = string(fieldnames(sct_given)).'
        sct_options.(s_name) = sct_given.(s_name);
    end
    sct_options.Method = string(sct_options.Method);
    sct_options.Coordinate = string(sct_options.Coordinate);
    SolverLIN.check_point(sct_options.Point);
    tools.check_plotfcn(sct_options.PlotFcn, "linearize");
    if ~isempty(rv_nonUnit), sct_options.NonUnit = rv_nonUnit; end        % COMPAT(v3)
end


function sct = default_options()
% Values of the Linearization section, and Point [] (the equilibrium)
    sct_cfg = GUILDA.config("Linearization");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    sct.Point = [];
end
