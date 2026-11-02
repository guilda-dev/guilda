function check_point(Point)
% Check the form of the Point option.
%
% Checks the form of a Point option: [] (the equilibrium), a real vector (values in the
% order of the variable map) or a cell {sim, t} or {sim, t, Side} (a simulation result, a
% time, and "after" | "before" for a phase boundary).
% The length of a vector is checked against the analysed layer by point_vector.
% Any other form stops with GUILDA:odeLinearizer:PointType.
    if isempty(Point) && ~iscell(Point)
        return
    end
    if isnumeric(Point) && isreal(Point) && isvector(Point)
        return
    end
    if iscell(Point) && any(numel(Point) == [2,3]) && isobject(Point{1}) ...
            && isnumeric(Point{2}) && isscalar(Point{2}) && isreal(Point{2}) ...
            && (numel(Point) == 2 || ((isstring(Point{3}) || ischar(Point{3})) && any(string(Point{3}) == ["after","before"])))
        return
    end
    error(msg("GUILDA:odeLinearizer:PointType"))
end
