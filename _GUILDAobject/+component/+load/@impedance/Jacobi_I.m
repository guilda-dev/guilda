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
    % I = -V/Z with Z = R + jX
    Vre = V(1);
    Vim = V(2);

    R = u(1);
    X = u(2);

    RX = R^2 + X^2;

    Cix = zeros(2,0);

    Div = [ -R, -X; 
             X, -R] / RX;

    Dii = zeros(2,2);

    Diu = [Vre*(R^2-X^2) + 2*Vim*R*X,  Vim*(X^2-R^2) + 2*Vre*R*X;
           Vim*(R^2-X^2) - 2*Vre*R*X, -Vre*(X^2-R^2) + 2*Vim*R*X] / RX^2;
end
