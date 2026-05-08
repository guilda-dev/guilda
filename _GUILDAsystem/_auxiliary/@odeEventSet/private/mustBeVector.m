function mustBeVector(p)
    if isempty(p)
        return;
    end

    isc = @(x) mustBeColumn(x);
    isc(p);
end