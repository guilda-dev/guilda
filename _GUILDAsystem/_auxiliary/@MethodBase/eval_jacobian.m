function J = eval_jacobian(obj, x)
% Jacobian of Fcn at x: Jac(x), or central differences with the step Increment without Jac.
%
% Called at each iteration (hot path: class and size only).
    arguments (Input)
        obj
        x (:,1) double  % Point.
    end
    arguments (Output)
        J double        % Jacobian (sparse when Jac returns a sparse matrix).
    end
    if isempty(obj.Jac)
        J = tools.fd_jacobian(obj.Fcn, x, Step=obj.Increment);
    else
        J = obj.Jac(x);
    end
end
