function s = default()
% Return the default s_opffcn: no user cost, no user constraint, default constraints kept.
    s = struct("Cost", [], "Constraint", [], "DefaultConstraint", true);
end
