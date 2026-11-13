function mustBeIntegerOrNaN(r)
% Validate MaxIteration of the power flow methods: NaN (the automatic value) or a nonnegative integer.
    arguments (Input)
        r   % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(r)
        mustBeNonnegative(r)
        mustBeInteger(r)
    end
end
