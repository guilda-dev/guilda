function check_point(Point)
% Check the form of the Point option.
%
% Checks the form of a Point option: [] (the equilibrium), a real vector (values in the
% order of the variable map) or a cell {sim, t} (a simulation result and a time).
% The length of a vector is checked against the analysed layer by point_vector.
% Any other form stops with GUILDA:odeLinearizer:PointType.
    if isempty(Point) && ~iscell(Point)
        return
    end
    if isnumeric(Point) && isreal(Point) && isvector(Point)
        return
    end
    if iscell(Point) && numel(Point) == 2 && isobject(Point{1}) ...
            && isnumeric(Point{2}) && isscalar(Point{2}) && isreal(Point{2})
        return
    end
    error("GUILDA:odeLinearizer:PointType", ...
          "Point must be [] (the equilibrium), a real vector in the order of get_variable_map(), " + ...
          "or {sim, t} with a simulation result sim and a time t (e.g. Point={sim, 1.5}).")
end
