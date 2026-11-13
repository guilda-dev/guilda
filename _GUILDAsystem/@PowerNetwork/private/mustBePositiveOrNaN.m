function mustBePositiveOrNaN(x)
% Validate a positive option (MaxStep, InitialStep of net.simulate; Tolerance of the OPF): positive, or NaN for the solver default.
    arguments (Input)
        x   % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(x)
        mustBePositive(x);
    end
end
