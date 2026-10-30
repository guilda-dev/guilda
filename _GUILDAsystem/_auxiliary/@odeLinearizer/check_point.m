function check_point(Point)
% <@Desc>
% Checks the form of a Point option: [] (the equilibrium), a real vector (values in the
% order of the variable map) or a cell {sim, t} or {sim, t, Side} (a simulation result, a
% time, and "after" | "before" for a phase boundary).
% The length of a vector is checked against the analysed layer by point_vector.
% Any other form stops with GUILDA:odeLinearizer:PointType.
% <@Role> Settings
% <@Summary> Check the form of the Point option.
% <@Signatures>
% [
%   "odeLinearizer.check_point(Point)"
% ]
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
    error("GUILDA:odeLinearizer:PointType", ...
          "Point must be [] (the equilibrium), a real vector in the order of get_variable_map(), " + ...
          "or {sim, t} with a simulation result sim and a time t (e.g. Point={sim, 1.5}); " + ...
          "{sim, t, ""before""} takes the value before the event at a phase boundary.")
end
