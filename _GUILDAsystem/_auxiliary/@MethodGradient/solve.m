function [x, flag, output, rm_history, rv_step] = solve(obj)
% Iterate x = x + StepSize*d(x) from InitVal until max|r(x)| <= ConvTol.
%
% rm_history holds the iterates 0 to 999, every 1000th and the last; rv_step their
% iteration numbers.
    arguments (Input)
        obj
    end
    arguments (Output)
        x           % Last iterate.
        flag        % 1: converged, 0: MaxIter reached, -2: diverged (non-finite d or r).
        output      % Details: iterations, algorithm, residual (largest |r|), StepSize, message.
        rm_history  % Recorded iterates (one column each).
        rv_step     % Iteration numbers of rm_history.
    end
    l_iter = startsWith(obj.Display, "iter");
    n_out  = nargout(obj.Fcn);
    x = obj.InitVal;
    rm_history = zeros(numel(x), 0);
    rv_step    = zeros(1, 0);
    flag = 0;
    for k = 0:obj.MaxIter
        if k < 1000 || mod(k, 1000) == 0
            rm_history(:,end+1) = x; %#ok<AGROW>
            rv_step(end+1)      = k; %#ok<AGROW>
        end
        if n_out >= 2
            [d, r] = obj.Fcn(x);
        else
            d = obj.Fcn(x);  r = d;
        end
        r_res = max(abs(r));
        if l_iter
            obj.print_iter("gradient", k, r_res);
        end
        if ~(isfinite(r_res) && all(isfinite(d)))
            flag = -2;
            break
        elseif r_res <= obj.ConvTol
            flag = 1;
            break
        elseif k == obj.MaxIter
            break
        end
        x = x + obj.StepSize*d;
    end
    if rv_step(end) ~= k
        rm_history(:,end+1) = x;
        rv_step(end+1)      = k;
    end

    output = obj.make_output(flag, k, r_res, "gradient", "gradient iteration", ...
        '✘ The process was terminated: the gradient iteration diverged; reduce StepSize.', ...
        "; a different StepSize may help");
    output.StepSize = obj.StepSize;
end
