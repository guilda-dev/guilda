function [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0) %#ok
% Calculate the Jacobians of the bus current.
%
% Analytic derivatives of `fcn_I`, with the current split as `[real; imag]`.
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
% See also fcn_I
    arguments (Output)
        Cix % Jacobian of the bus current `[real; imag]` with respect to `x`.
        Div % Jacobian of the bus current `[real; imag]` with respect to `V` `[real; imag]`.
        Dii % Jacobian of the bus current `[real; imag]` with respect to `I` `[real; imag]`.
        Diu % Jacobian of the bus current `[real; imag]` with respect to `u`.
    end
    delta = x(1);
    Eq    = x(3);

    Xq  = param(4);
    Xdp = param(5);

    Vre = V(1);
    Vim = V(2);

    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);

    Id = (Eq - Vq) / Xdp;

    dVd_ddelta = Vq;
    dVq_ddelta = -Vd;

    Cix = zeros(2, 3);

    Cix([1,2], 1) = [(dVd_ddelta/Xq)*cos(delta) - (Vd/Xq)*sin(delta) - (dVq_ddelta/Xdp)*sin(delta) + Id*cos(delta); ...
                     (dVd_ddelta/Xq)*sin(delta) + (Vd/Xq)*cos(delta) + (dVq_ddelta/Xdp)*cos(delta) + Id*sin(delta)];

    Cix([1,2], 3) = [ sin(delta)/Xdp; ...
                    -cos(delta)/Xdp];    

    dVd_dVre = sin(delta);
    dVq_dVre = cos(delta);
    dVd_dVim = -cos(delta);
    dVq_dVim = sin(delta);

    Div = zeros(2, 2);

    Div([1,2], 1) = [(dVd_dVre/Xq)*cos(delta) - (dVq_dVre/Xdp)*sin(delta); ...
                     (dVd_dVre/Xq)*sin(delta) + (dVq_dVre/Xdp)*cos(delta)];

    Div([1,2], 2) = [(dVd_dVim/Xq)*cos(delta) - (dVq_dVim/Xdp)*sin(delta); ...
                     (dVd_dVim/Xq)*sin(delta) + (dVq_dVim/Xdp)*cos(delta)];

    Dii = zeros(2,2);

    Diu = zeros(2,2);
end