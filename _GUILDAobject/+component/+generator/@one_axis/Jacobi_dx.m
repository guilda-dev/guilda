function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0) %#ok
% Calculate the Jacobians of the state equation.
%
% Analytic derivatives of `fcn_dx` at the given point, used for linearization.
%
% Inputs:
% - `t` [s]: time.
% - `x`: state vector in the order of `sv_x`.
% - `V` [pu]: bus voltage as `[real; imag]`.
% - `I` [pu]: bus current as `[real; imag]`.
% - `u`: input vector in the order of `sv_u`.
% - `param`: dynamic parameters in the order of `sv_para`.
% - `omega0` [Hz]: network frequency (`r_Hz`).
%
% See also fcn_dx
    arguments (Output)
        Axx % Jacobian of `fcn_dx` with respect to `x`.
        Bxv % Jacobian of `fcn_dx` with respect to `V` `[real; imag]`.
        Bxi % Jacobian of `fcn_dx` with respect to `I` `[real; imag]`.
        Bxu % Jacobian of `fcn_dx` with respect to `u`.
    end
    delta = x(1);
    Eq    = x(3);

    D   = param(2);
    Xd  = param(3);
    Xq  = param(4);
    Xdp = param(5);

    Vre = V(1);
    Vim = V(2);

    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);

    Id = (Eq - Vq) / Xdp;
    Iq = Vd / Xq;

    dVd_ddelta = Vq;
    dVq_ddelta = -Vd;
    dId_ddelta = Vd / Xdp;
    dIq_ddelta = Vq / Xq;

    dPout_ddelta = dVd_ddelta*Id + Vd*dId_ddelta + dVq_ddelta*Iq + Vq*dIq_ddelta;

    Axx = zeros(3, 3);

    Axx(1, 2) = 2 * pi * omega0;

    Axx(2, 1) = -dPout_ddelta;
    Axx(2, 2) = -D;
    Axx(2, 3) = -Vd / Xdp;

    Axx(3, 1) = -(Xd - Xdp) * Vd / Xdp;
    Axx(3, 3) = -Xd / Xdp;    
    
    invXdp = 1 / Xdp;
    invXq  = 1 / Xq;
    X_diff = invXq - invXdp;
    Xd_ratio = (Xd - Xdp) * invXdp;
            
    dP_dVre   = (Eq * invXdp * sin(delta)) + X_diff * (Vq * sin(delta) + Vd * cos(delta));
    dP_dVim   = -(Eq * invXdp * cos(delta)) + X_diff * (-Vq * cos(delta) + Vd * sin(delta));        

    Bxv = zeros(3, 2);    
                
    Bxv(2, 1) = -dP_dVre;
    Bxv(2, 2) = -dP_dVim;
        
    Bxv(3, 1) = Xd_ratio * cos(delta);
    Bxv(3, 2) = Xd_ratio * sin(delta);

    Bxi = zeros(3,2);

    Bxu = [zeros(1,2);eye(2)];
end