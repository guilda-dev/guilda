function sct_options = get_options(obj, nv)
% Get the effective settings of one run as a struct.
%
% The stored settings of the solver with the
% Name-Value overrides of the call applied. The solver itself is not changed.
% A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
% an invalid value stops with the validation error of the option.
    arguments (Input)
        obj % Solver holding the defaults (net.solver_LIN).
        nv (1,:) cell = {} % Name-Value overrides: Algorithm, Point, Coordinate.
    end
    arguments (Output)
        sct_options % Fields Algorithm, Point, Coordinate.
    end
    [nv, rv_nonUnit] = v3_linearize_args(nv, obj.NonUnit);              % COMPAT(v3)
    sct_options = tools.resolve_options(obj, SolverLIN.OptionMap, nv);
    validate_options(nv{:});
    sct_options.Algorithm = string(sct_options.Algorithm);
    sct_options.Coordinate = string(sct_options.Coordinate);
    SolverLIN.check_point(sct_options.Point);
    if ~isempty(rv_nonUnit), sct_options.NonUnit = rv_nonUnit; end        % COMPAT(v3)
end
