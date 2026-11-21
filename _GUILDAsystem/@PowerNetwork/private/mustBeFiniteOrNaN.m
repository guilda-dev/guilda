function mustBeFiniteOrNaN(x)
% Validate MaxRealPart of the OPF: a finite value, or NaN for no limit.
    arguments (Input)
        x  % Value to check (a real scalar, by the arguments block).
    end
    if ~isnan(x)
        mustBeFinite(x);
    end
end
