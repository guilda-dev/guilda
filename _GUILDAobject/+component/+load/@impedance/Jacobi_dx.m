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
    Axx = zeros(0,0);
    Bxv = zeros(0,2);
    Bxi = zeros(0,2);
    Bxu = zeros(0,2);
end
