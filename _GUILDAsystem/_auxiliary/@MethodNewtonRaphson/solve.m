function [x, flag, output, rm_history, rv_step] = solve(obj)
% Solve F(x) = 0 from InitVal (see the class help).
    arguments (Input)
        obj
    end
    arguments (Output)
        x           % Last iterate.
        flag        % 1: converged, 0: MaxIter reached, -2: diverged or no solution (see the class help).
        output      % Details: iterations, algorithm, residual (largest |F|), message.
        rm_history  % Iterates: InitVal and x after each step (one column each).
        rv_step     % Iteration numbers of rm_history.
    end
    l_iter = startsWith(obj.Display, "iter");
    Gamma  = obj.StepSize;
    f_F    = obj.Fcn;

    x = obj.InitVal;
    rm_history = x;
    flag   = 0;
    s_fail = "";
    for k = 0:obj.MaxIter
        rv_F  = f_F(x);
        r_res = full(max(abs(rv_F)));
        if l_iter
            obj.print_iter("newton", k, r_res);
        end
        if r_res <= obj.ConvTol
            flag = 1;
            break
        elseif ~(isfinite(r_res) && all(isfinite(x)))
            flag   = -2;
            s_fail = '✘ The process was terminated: the Newton-Raphson iteration diverged.';
            break
        elseif k == obj.MaxIter
            break
        end
        rm_J = obj.eval_jacobian(x);
        [s_warn, s_id] = lastwarn();
        w = warning("off", "MATLAB:singularMatrix");
        warning("off", "MATLAB:nearlySingularMatrix");
        lastwarn("");
        dx = rm_J \ rv_F;
        [~, s_singular] = lastwarn();
        warning(w);
        if ~all(isfinite(dx)) || s_singular ~= ""
            % singular Jacobian (e.g. an undetermined angle): minimum norm step
            dx = lsqminnorm(rm_J, rv_F, "nowarn");
        end
        lastwarn(s_warn, s_id);

        dx = Gamma * dx;
        if full(max(abs(dx))) <= 10*eps(max(1, max(abs(x))))
            % the step is at the rounding level of x while |F| > ConvTol: no solution from here
            flag   = -2;
            s_fail = sprintf('✘ No solution was found: the Newton-Raphson step became negligible, but the largest mismatch is %.3e.', r_res);
            break
        end
        x = x - dx;
        rm_history(:,end+1) = x; %#ok<AGROW>
    end
    rv_step = 0:size(rm_history,2)-1;
    output  = obj.make_output(flag, rv_step(end), r_res, "newton", "Newton-Raphson iteration", s_fail);

    if nargout < 2 && flag == 0
        show_msg("warning", "GUILDA:MethodNewtonRaphson:MaxIteration")
    end
end
