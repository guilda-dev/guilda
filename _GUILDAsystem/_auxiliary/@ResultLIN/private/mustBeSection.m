function mustBeSection(v)
% Index of the methods of ResultLIN that take every section: a positive integer or "all"
    arguments (Input)
        v  % Value of the option Index.
    end
    if (isstring(v) || ischar(v)) && isscalar(string(v)) && string(v) == "all"
        return
    end
    if ~(isnumeric(v) && isscalar(v) && isreal(v) && v >= 1 && v == round(v))
        error(msg("GUILDA:ResultLIN:IndexForm"))
    end
end
