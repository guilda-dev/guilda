function [x, flag, output, rm_history, rv_step] = solve(obj)
% Solve F(x) = 0 from InitVal with fsolve (see the class help). rm_history holds the
% iterates of fsolve (one column each), rv_step their iteration numbers.
    arguments (Input)
        obj
    end
    arguments (Output)
        x           % Solution of fsolve.
        flag        % 1: converged, 0: MaxIter (or MaxFunEvals) reached, -2: no solution (see the class help).
        output      % Details: iterations, algorithm, residual (largest |F|), message, exitflag.
        rm_history  % Iterates of fsolve (one column each).
        rv_step     % Iteration numbers.
    end
    tools.require_toolbox("optim", obj.Feature);

    l_jac = ~isempty(obj.Jac);
    opt = optimoptions("fsolve", "UseParallel", obj.UseParallel, "Display", obj.Display, ...
                       "SpecifyObjectiveGradient", l_jac, "OutputFcn", @record);
    if obj.PlotFcn ~= "none"
        opt = optimoptions(opt, "PlotFcn", obj.PlotFcn);
    end
    if obj.MaxFunEvals ~= 0
        opt = optimoptions(opt, "MaxFunctionEvaluations", obj.MaxFunEvals);
    end
    if obj.MaxIter ~= 0
        opt = optimoptions(opt, "MaxIterations", obj.MaxIter);
    end
    r_tol = 1e-6;     % fsolve default FunctionTolerance
    if obj.ConvTol ~= 0
        % FunctionTolerance bounds the change of the sum of squares |F|^2 and OptimalityTolerance
        % the first-order optimality |J'F| (fsolve stops on it, default 1e-6); ConvTol the largest |F|
        opt   = optimoptions(opt, "FunctionTolerance", obj.ConvTol^2, "OptimalityTolerance", obj.ConvTol^2);
        r_tol = obj.ConvTol;
    end

    rm_history = nan(numel(obj.InitVal), 0);
    n_iter = 0;
    [x, rv_F, exitflag, sct_fsolve] = fsolve(@func, obj.InitVal, opt);
    rm_history = rm_history(:, 1:n_iter);
    rv_step    = 0:n_iter-1;

    r_res = full(max(abs(rv_F)));
    if exitflag > 0 && r_res <= r_tol
        flag = 1;
    elseif exitflag == 0
        flag = 0;
    else
        flag = -2;
    end
    s_fail = sprintf('✘ No solution was found: fsolve stopped with exitflag %d and the largest mismatch %.3e.', exitflag, r_res);
    output = obj.make_output(flag, sct_fsolve.iterations, r_res, "fsolve", "fsolve iteration", s_fail, ...
                             " or MaxFunEvals");
    output.exitflag = exitflag;

    function [F, J] = func(x)
        F = obj.Fcn(x);
        if nargout > 1
            J = obj.Jac(x);
        end
    end

    function stop = record(x, ~, state)
        stop = false;
        if state == "iter"
            n_iter = n_iter + 1;
            if n_iter > size(rm_history,2)
                rm_history = [rm_history, nan(numel(x),1000)];
            end
            rm_history(:,n_iter) = x;
        end
    end
end
