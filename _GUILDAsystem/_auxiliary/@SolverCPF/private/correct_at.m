function [x, N] = correct_at(NRM, f_PF, f_Jac, x0, x_center)
% Corrector to the path point near x0, where the path meets an operating limit: at the
% lambda of x0 when x_center is empty, otherwise on the sphere around x_center through x0
% (which also works at the nose). Reaching MaxIter warns GUILDA:MethodNewtonRaphson:MaxIteration.
    arguments (Input)
        NRM      (1,1) MethodNewtonRaphson  % Newton-Raphson solver of the corrector.
        f_PF     (1,1) function_handle      % Power flow equations of the CPF (pf_equation).
        f_Jac    (1,1) function_handle      % Jacobian of f_PF.
        x0       (:,1) double               % Start point [unknowns; lambda] (interpolated crossing).
        x_center (:,1) double               % Last point of the path, or [] to fix lambda.
    end
    arguments (Output)
        x        (:,1) double               % Corrected point.
        N        (1,1) double               % Number of Newton-Raphson steps.
    end
    n = numel(x0);
    if isempty(x_center)
        rv_e = [zeros(1, n-1), 1];
        NRM.Fcn = @(x) [f_PF(x); x(end) - x0(end)];
        NRM.Jac = @(x) [f_Jac(x); rv_e];
    else
        r_s = (x0 - x_center)' * (x0 - x_center);
        if r_s == 0
            x = x0;      % the crossing is the last point itself
            N = 0;
            return
        end
        NRM.Fcn = @(x) [f_PF(x); (x - x_center)' * (x - x_center) - r_s];
        NRM.Jac = @(x) [f_Jac(x); 2 * (x - x_center)'];
    end
    NRM.InitVal = x0;
    [x, flag, output] = NRM.solve();
    N = output.iterations;
    if flag == 0
        show_msg("warning", "GUILDA:MethodNewtonRaphson:MaxIteration")
    end
end
