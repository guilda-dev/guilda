function [x, flag, output, rm_history, rv_step] = solve(obj)
% Solve F(x) = 0 from InitVal with fsolve. rm_history holds the iterates of fsolve (one
% column each), rv_step their iteration numbers.
    arguments (Input)
        obj
    end
    arguments (Output)
        x           % Solution of fsolve.
        flag        % exitflag of fsolve.
        output      % Output structure of fsolve.
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
    if obj.MaxIterations ~= 0
        opt = optimoptions(opt, "MaxIterations", obj.MaxIterations);
    end
    if obj.FunctionTolerance ~= 0
        opt = optimoptions(opt, "FunctionTolerance", obj.FunctionTolerance);
    end

    rm_history = nan(numel(obj.InitVal), 0);
    n_iter = 0;
    [x, ~, flag, output] = fsolve(@func, obj.InitVal, opt);
    rm_history = rm_history(:, 1:n_iter);
    rv_step    = 0:n_iter-1;

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
