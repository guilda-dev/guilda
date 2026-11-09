function [x_correct,x_current,N] = correct(NRM,f_PF,f_Jac,delta_s,x_current,x_pred)
% Corrector of the CPF: Newton-Raphson on the power flow equations plus the arc
% length condition |x - x_current|^2 = delta_s, starting from x_pred. Reaching MaxIter
% warns GUILDA:MethodNewtonRaphson:MaxIteration.
    arguments (Input)
        NRM       (1,1) MethodNewtonRaphson  % Newton-Raphson solver of the corrector.
        f_PF      (1,1) function_handle      % Power flow equations of the CPF (pf_equation).
        f_Jac     (1,1) function_handle      % Jacobian of f_PF.
        delta_s   (1,1) double               % Arc length of the corrector.
        x_current (:,1) double               % Current point [unknowns; lambda].
        x_pred    (:,1) double               % Predicted point (start of the iteration).
    end
    arguments (Output)
        x_correct (:,1) double               % Corrected point.
        x_current (:,1) double               % Point before the correction (the next x_past).
        N         (1,1) double               % Number of Newton-Raphson steps.
    end

    ArcLength = @(x,s) (x-x_current)' * (x-x_current) - s;
    ArcJacobi = @(x,s) (x-x_current)' * 2;

    NRM.Fcn     = @(x) [f_PF(x); ArcLength(x,delta_s)];
    NRM.Jac     = @(x) [f_Jac(x); ArcJacobi(x,delta_s)];
    NRM.InitVal = x_pred;

    [x_correct, flag, output] = NRM.solve();
    N = output.iterations;
    if flag == 0
        show_msg("warning", "GUILDA:MethodNewtonRaphson:MaxIteration")
    end
end
