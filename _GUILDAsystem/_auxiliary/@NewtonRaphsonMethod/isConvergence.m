function flag = isConvergence(obj,dx,Tol)
% Return true when every element of the step is smaller than the tolerance.
    arguments (Input)
        obj   %#ok<INUSA>
        dx    % Newton step.
        Tol   % Absolute tolerance.
    end
    arguments (Output)
        flag  % true when all(abs(dx) < Tol).
    end
    flag = all(abs(dx) < Tol);
end
