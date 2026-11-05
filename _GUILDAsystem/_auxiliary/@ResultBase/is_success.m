function l = is_success(obj)
% Decide whether flag means success.
%
% Success test behind l_success: a logical flag as it is, a numeric flag when
% positive (as for exitflag of fsolve or fmincon). Override it when an analysis
% uses another convention.
    arguments (Input)
        obj
    end
    arguments (Output)
        l % True when the analysis succeeded.
    end
    f = obj.flag;
    if islogical(f)
        l = isscalar(f) && f;
    elseif isnumeric(f)
        l = isscalar(f) && f > 0;
    else
        l = false;
    end
end
