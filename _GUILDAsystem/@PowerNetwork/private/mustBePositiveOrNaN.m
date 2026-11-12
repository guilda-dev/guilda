function mustBePositiveOrNaN(x)
% Validate a step option of net.simulate (MaxStep, InitialStep): positive, or NaN for the solver default.
    arguments (Input)
        x   % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(x)
        mustBePositive(x);
    end
end
