function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
% Calculate the Jacobians of the output.
%
% Analytic derivatives of `fcn_Y` at the given point.
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
% See also fcn_Y
    arguments (Output)
        Cyx % Jacobian of `fcn_Y` with respect to `x`.
        Dyv % Jacobian of `fcn_Y` with respect to `V` `[real; imag]`.
        Dyi % Jacobian of `fcn_Y` with respect to `I` `[real; imag]`.
        Dyu % Jacobian of `fcn_Y` with respect to `u`.
    end
    ny = 1;
    nx = numel(x);

    Cyx = zeros(ny,nx);
    Cyx(2) = 1; 

    Dyv = zeros(1,2);
    Dyi = zeros(1,2);
    Dyu = zeros(1,2);
end