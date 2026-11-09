function print_iter(obj, s_algorithm, k, r_res, s_extra)
% Print one iteration line when Display is "iter" or "iter-detailed".
    arguments (Input)
        obj
        s_algorithm (1,1) string      % Name at the start of the line.
        k           (1,1) double      % Iteration number.
        r_res       (1,1) double      % Largest |F| (mismatch) at the iterate.
        s_extra     (1,1) string = "" % Text appended to the line.
    end
    if startsWith(obj.Display, "iter")
        fprintf('  %s  iter %4d   max mismatch %.3e%s\n', s_algorithm, k, r_res, s_extra);
    end
end
