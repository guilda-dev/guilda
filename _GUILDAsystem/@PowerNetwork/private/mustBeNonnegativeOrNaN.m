function mustBeNonnegativeOrNaN(x)
% Validate SampleTime of net.simulate: nonnegative, or NaN for the steps of the solver.
    arguments (Input)
        x   % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(x)
        mustBeNonnegative(x);
    end
end
