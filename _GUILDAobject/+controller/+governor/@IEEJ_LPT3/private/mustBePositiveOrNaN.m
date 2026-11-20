function mustBePositiveOrNaN(x)
% Validate Prate of the governor: positive, or NaN for the operation Pmax of the generator.
    arguments (Input)
        x  % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(x)
        mustBePositive(x);
    end
end
