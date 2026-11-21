function [Cyx,Dyv] = Jacobi_Y(t,x,V,param,omega0)
% Calculate the Jacobians of the output.
%
% Analytic derivatives of `fcn_Y` at the given point.
%
% See also fcn_Y
    arguments (Input)
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        Cyx  % Jacobian of `fcn_Y` with respect to `x`.
        Dyv  % Jacobian of `fcn_Y` with respect to `V` `[real; imag]`.
    end
    % Row 2: Ifield = Eq + (Xd - Xd')*(Id + kd*dpsid) (fcn_Y) with kd = (Xd' - Xd'')/(Xd' - Xls)^2
    % and dpsid = -psid + Eq - (Xd' - Xls)*Id, that is Eq + (Xd - Xd')*(g*Id + kd*(Eq - psid))
    Xd    = param(3);
    Xdp   = param(4);
    Xdpp  = param(5);
    Xls   = param(13);
    delta = x(1);
    c = cos(delta);
    s = sin(delta);
    Vd = V(1)*s - V(2)*c;
    kd = (Xdp - Xdpp)/(Xdp - Xls)^2;
    g  = 1 - kd*(Xdp - Xls);
    kI = (Xd - Xdp)*g;                       % dIfield/dId
    dId_dEq   = (Xdpp - Xls)/((Xdp - Xls)*Xdpp);
    dId_dpsid = (Xdp - Xdpp)/((Xdp - Xls)*Xdpp);
    Cyx = zeros(2, numel(x));
    Cyx(1,2) = 1;
    Cyx(2,1) = kI*Vd/Xdpp;                   % dVq/ddelta = -Vd, dId/dVq = -1/Xd''
    Cyx(2,3) = 1 + kI*dId_dEq + (Xd - Xdp)*kd;
    Cyx(2,6) = kI*dId_dpsid - (Xd - Xdp)*kd;
    Dyv = [0, 0;
           -kI*c/Xdpp, -kI*s/Xdpp];
end