function check_point(point)
% Check the form of the point of get_sys.
%
% Checks the form of the point (the first argument of get_sys): [] (the equilibrium), a
% real vector (values in the order of the variable map), a real matrix (one point per
% column), or a cell {sim, rv_t} or {sim, rv_t, Side} (a simulation result, one or more
% times, and "after" | "before" for a phase boundary).
% The length of a vector and the rows of a matrix are checked against the analysed layer
% by point_vector. Any other form stops with GUILDA:SolverLIN:PointType.
    arguments (Input)
        point  % Point to check.
    end
    if isempty(point) && ~iscell(point)
        return
    end
    if isnumeric(point) && isreal(point) && ismatrix(point)
        return
    end
    if iscell(point) && any(numel(point) == [2,3]) && isobject(point{1}) ...
            && isnumeric(point{2}) && isvector(point{2}) && isreal(point{2}) ...
            && (numel(point) == 2 || ((isstring(point{3}) || ischar(point{3})) && any(string(point{3}) == ["after","before"])))
        return
    end
    error(msg("GUILDA:SolverLIN:PointType"))
end
