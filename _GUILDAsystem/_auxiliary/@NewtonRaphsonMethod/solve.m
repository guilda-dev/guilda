function [xi,iteration] = solve(obj)
% Solve F(x) = b from InitVal.
%
% Iterates x = x - StepSize * (J(x) \ (F(x) - b)) until every element of the step is
% smaller than ConvTol, or MaxIter iterations (then with a warning).
    arguments (Input)
        obj
    end
    arguments (Output)
        xi         % Solution x.
        iteration  % Number of iterations.
    end

    AbsTol = obj.ConvTol;
    Gamma  = obj.StepSize;
    MaxIt  = obj.MaxIter;

    NRMF = obj.NRMFcn;
    NRMJ = obj.NRMJac;
    NRMV = obj.NRMVal;

    xi = obj.InitVal;

    isConvergence = false;
    iteration     = 1;
    while ~isConvergence && iteration <= MaxIt
        Ferror = NRMF(xi) - NRMV;
        Jacobi = NRMJ(xi);
        dx = Jacobi \ Ferror;

        if obj.isConvergence(dx,AbsTol)
            isConvergence = true;
        else
            xi = xi - Gamma * dx;
            iteration = iteration + 1;
        end
    end

    if iteration >= MaxIt
        warning(msg("GUILDA:NewtonRaphsonMethod:MaxIteration"))
    end
end
