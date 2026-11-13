function mustBePositiveIntegerOrNaN(r)
% Validate an iteration limit (MaxIteration of the OPF): a positive integer, or NaN for the solver default.
    arguments (Input)
        r   % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(r)
        mustBePositive(r)
        mustBeInteger(r)
    end
end
