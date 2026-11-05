function l = is_success(obj)
% Decide whether flag means success.
%
% Success test behind l_success: the exitflag of solve (an
% optim.problemdef.ExitFlag or a number) is positive.
    arguments (Input)
        obj
    end
    arguments (Output)
        l % True when the problem was solved.
    end
    f = obj.flag;
    if islogical(f)
        l = isscalar(f) && f;
    else
        l = isscalar(f) && double(f) > 0;
    end
end
