function simulateFcn_mustBeProgress(val)
% Validate the Progress option of net.simulate: true, false, "dialog", "disp" or "none".
    arguments (Input)
        val   % Value to check.
    end
    if (islogical(val) || isnumeric(val)) && isscalar(val)
        return
    end
    mustBeMember(string(val), ["none","disp","dialog"]);
end
