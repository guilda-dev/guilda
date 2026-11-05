function mustBeProgress(val)
    if (islogical(val) || isnumeric(val)) && isscalar(val)
        return
    end
    mustBeMember(string(val), ["none","disp","dialog"]);
end
