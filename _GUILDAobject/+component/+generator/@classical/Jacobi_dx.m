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

    D  = param(2);
    Xd = param(3);
    Xq = param(4);
    
    Vfd = u(2);
    
    Vre = V(1);
    Vim = V(2);
    
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);            
       
    dP_ddelta = (1/Xq - 1/Xd) * (Vq^2 - Vd^2) + (Vfd/Xd) * Vq;     
    
    Axx = zeros(2, 2);
        
    Axx(1, [1,2]) = [0, 2*pi*omega0];              
    Axx(2, [1,2]) = [-dP_ddelta, -D];      
        
    K = (1/Xq - 1/Xd);
        
    dP_dVre = K * (Vq*sin(delta) + Vd*cos(delta)) + (Vfd/Xd)*sin(delta);        
    dP_dVim = K * (Vq*(-cos(delta)) + Vd*sin(delta)) - (Vfd/Xd)*cos(delta);       
    
    Bxv = zeros(2, 2);
        
    Bxv(1, [1,2]) = zeros(1,2);        
    Bxv(2, [1,2]) = [-dP_dVre, -dP_dVim];     

    nx  = numel(x);
    Bxi = zeros(nx,2);                
    
    Bxu = [zeros(1,2); [1,-Vd/Xd]];
end
