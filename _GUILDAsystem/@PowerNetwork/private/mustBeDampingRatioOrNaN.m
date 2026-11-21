function mustBeDampingRatioOrNaN(x)
% Validate MinDampingRatio of the OPF: a damping ratio in [0, 1), or NaN for no limit.
    arguments (Input)
        x  % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(x)
        mustBeInRange(x, 0, 1, "exclude-upper");
    end
end
