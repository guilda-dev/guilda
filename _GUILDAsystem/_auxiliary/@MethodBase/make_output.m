function output = make_output(obj, flag, n_iter, r_res, s_algorithm, s_name, s_fail, s_hint)
% Build the output structure of solve and print its message unless Display is "none".
%
% The message names s_name ("Newton-Raphson iteration", ...): converged (flag 1), MaxIter
% reached (flag 0, with n_iter as the limit, followed by s_hint), or s_fail (flag -2).
    arguments (Input)
        obj
        flag        (1,1) double  % 1 converged, 0 MaxIter reached, -2 diverged or no solution.
        n_iter      (1,1) double  % Number of iterations.
        r_res       (1,1) double  % Largest |F| at the last iterate.
        s_algorithm (1,1) string  % Value of output.algorithm.
        s_name      (1,1) string  % Name of the iteration in the message.
        s_fail      (1,1) string = ""  % Message for flag -2.
        s_hint      (1,1) string = ""  % Text after the MaxIter message, e.g. "; a different StepSize may help".
    end
    arguments (Output)
        output (1,1) struct  % Fields iterations, algorithm, residual, message.
    end
    output = struct("iterations", n_iter, "algorithm", s_algorithm, "residual", r_res);
    switch flag
        case 1
            output.message = sprintf('✔ The %s has converged within the tolerance limit (%d iterations).', s_name, n_iter);
        case 0
            output.message = sprintf('✘ The %s did not converge within MaxIterations (%d)%s.', s_name, n_iter, s_hint);
        otherwise
            output.message = char(s_fail);
    end
    if obj.Display ~= "none"
        disp(output.message)
    end
end
