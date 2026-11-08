function [xi,iteration,flag,rm_history] = solve(obj)
% Solve F(x) = b from InitVal.
%
% Iterates x = x - StepSize * (J(x) \ (F(x) - b)) until every element of the step is
% smaller than ConvTol, or MaxIter iterations. A singular J(x) gives the minimum norm step
% (lsqminnorm) instead, without a warning. Reaching MaxIter gives a warning unless
% the caller takes flag.
    arguments (Input)
        obj
    end
    arguments (Output)
        xi          % Solution x.
        iteration   % Number of iterations.
        flag        % true when the step became smaller than ConvTol.
        rm_history  % Iterates: InitVal and x after each step (one column each).
    end

    AbsTol = obj.ConvTol;
    Gamma  = obj.StepSize;
    MaxIt  = obj.MaxIter;

    NRMF = obj.NRMFcn;
    NRMJ = obj.NRMJac;
    NRMV = obj.NRMVal;

    xi = obj.InitVal;
    rm_history = xi;
    l_iter = startsWith(obj.Display, "iter");

    isConvergence = false;
    iteration     = 1;
    while ~isConvergence && iteration <= MaxIt
        Ferror = NRMF(xi) - NRMV;
        if l_iter
            fprintf('  newton  iter %4d   max |F-b| %.3e\n', iteration-1, full(max(abs(Ferror))));
        end
        Jacobi = NRMJ(xi);
        [s_warn, s_id] = lastwarn();
        w = warning("off", "MATLAB:singularMatrix");
        warning("off", "MATLAB:nearlySingularMatrix");
        lastwarn("");
        dx = Jacobi \ Ferror;
        [~, s_singular] = lastwarn();
        warning(w);
        if ~all(isfinite(dx)) || s_singular ~= ""
            % singular Jacobian (e.g. an undetermined angle): minimum norm step
            dx = lsqminnorm(Jacobi, Ferror, "nowarn");
        end
        lastwarn(s_warn, s_id);

        if obj.isConvergence(dx,AbsTol)
            isConvergence = true;
        else
            xi = xi - Gamma * dx;
            iteration = iteration + 1;
            if nargout > 3
                rm_history(:,end+1) = xi; %#ok<AGROW>
            end
        end
    end
    flag = isConvergence;

    if nargout < 3 && iteration >= MaxIt
        show_msg("warning", "GUILDA:MethodNewtonRaphson:MaxIteration")
    end
end
