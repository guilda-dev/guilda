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
    % Row 2: Ifield = Eq + (Xd - Xd')*Id with Id = (Eq - Vq)/Xd' (fcn_Y)
    Xd    = param(3);
    Xdp   = param(5);
    delta = x(1);
    c = cos(delta);
    s = sin(delta);
    Vd = V(1)*s - V(2)*c;
    k  = (Xd - Xdp)/Xdp;
    Cyx = [   0, 1,      0;
           k*Vd, 0, Xd/Xdp];
    Dyv = [0, 0;
           -k*c, -k*s];
end