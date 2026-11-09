function J = fd_jacobian(f, x, opt)
% Jacobian of f: R^n -> R^m at x by central differences.
%
% Column i is (f(x + Step*e_i) - f(x - Step*e_i)) / (2*Step), where e_i is the i-th unit
% vector. f returns a column (a row or matrix output is used as f(:)). Called by the
% numerical Jacobians of the Method classes (MethodBase) and of the components
% (Jacobi_dx_num, Jacobi_I_num, Jacobi_Y_num, validate), at each Jacobian evaluation
% (hot path: class and size only).
%
% <@Examples>
% ```matlab
% J = tools.fd_jacobian(@(x) [x(1)^2; x(1)*x(2)], [1; 2], Step=1e-6);   % [2 0; 2 1]
% ```
%
% See also MethodBase
    arguments (Input)
        f    (1,1) function_handle  % Function of a column x, returning a column of length m.
        x    (:,1) double           % Point at which to differentiate.
        opt.Step (1,1) double       % Half-width of the difference: x is moved by +-Step.
    end
    arguments (Output)
        J    double                 % m x n Jacobian.
    end
    h = opt.Step;
    n = numel(x);
    if n == 0
        J = zeros(numel(f(x)), 0);
        return
    end
    xp = x;
    xm = x;
    for i = 1:n
        xp(i) = x(i) + h;
        xm(i) = x(i) - h;
        d = f(xp) - f(xm);
        if i == 1
            J = zeros(numel(d), n);
        end
        J(:,i) = d(:);
        xp(i) = x(i);
        xm(i) = x(i);
    end
    J = J / (2*h);
end
