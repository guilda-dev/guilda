function [x_correct,x_current,N] = correct(NRM,f_PF,f_Jac,delta_s,x_current,x_pred)
% Corrector of the CPF: Newton-Raphson on the power flow equations plus the arc
% length condition |x - x_current|^2 = delta_s, starting from x_pred.

    ArcLength = @(x,s) (x-x_current)' * (x-x_current) - s;
    ArcJacobi = @(x,s) (x-x_current)' * 2;

    NRM.NRMFcn  = @(x) [f_PF(x); ArcLength(x,delta_s)];
    NRM.NRMJac  = @(x) [f_Jac(x); ArcJacobi(x,delta_s)];
    NRM.NRMVal  = zeros(size(x_pred));
    NRM.InitVal = x_pred;

    [x_correct,N] = solve(NRM);
end
