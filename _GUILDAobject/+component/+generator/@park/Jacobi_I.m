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
    Ed    = x(4);
    psiq  = x(5);  
    psid  = x(6);  

    Vre   = V(1);   
    Vim   = V(2);
        
    Xdp  = param(4);
    Xdpp = param(5);    
    Xqp  = param(7);    
    Xqpp = param(8);
    Xls  = param(13);    

    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
        
    term_q = ((Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid)/(Xdp-Xls);
    term_d = ((Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq)/(Xqp-Xls);
    Id = (term_q - Vq) / Xdpp;
    Iq = (Vd - term_d) / Xqpp;

    dVd_ddel = Vq;  
    dVq_ddel = -Vd; 

    dId_dEq    = (Xdpp-Xls)/(Xdpp*(Xdp-Xls));
    dId_dpsid  = (Xdp-Xdpp)/(Xdpp*(Xdp-Xls));
    dId_dVq    = -1/Xdpp;
    
    dIq_dEd    = -(Xqpp-Xls)/(Xqpp*(Xqp-Xls));
    dIq_dpsiq  = (Xqp-Xqpp)/(Xqpp*(Xqp-Xls));
    dIq_dVd    = 1/Xqpp;

    Cix = zeros(2, 6);    
    
    Cix(1,1) = -Iq*sin(delta) + Id*cos(delta) + cos(delta)*(dIq_dVd*dVd_ddel) + sin(delta)*(dId_dVq*dVq_ddel);
    Cix(2,1) =  Iq*cos(delta) + Id*sin(delta) + sin(delta)*(dIq_dVd*dVd_ddel) - cos(delta)*(dId_dVq*dVq_ddel);
    
    Cix(1,3:6) = [  sin(delta)*dId_dEq, ...
                    cos(delta)*dIq_dEd, ...
                  cos(delta)*dIq_dpsiq, ...
                  sin(delta)*dId_dpsid];         

    Cix(2,3:6) = [   -cos(delta)*dId_dEq, ...
                      sin(delta)*dIq_dEd, ...
                    sin(delta)*dIq_dpsiq, ...
                   -cos(delta)*dId_dpsid];            
            
    dVd_dVre = sin(delta);  dVd_dVim = -cos(delta);
    dVq_dVre = cos(delta);  dVq_dVim = sin(delta);
        
    Div = zeros(2, 2);
   
    Div(1,[1,2]) = [cos(delta)*(dIq_dVd*dVd_dVre) + sin(delta)*(dId_dVq*dVq_dVre), ...
                    cos(delta)*(dIq_dVd*dVd_dVim) + sin(delta)*(dId_dVq*dVq_dVim)];    

    Div(2,[1,2]) = [sin(delta)*(dIq_dVd*dVd_dVre) - cos(delta)*(dId_dVq*dVq_dVre), ...
                    sin(delta)*(dIq_dVd*dVd_dVim) - cos(delta)*(dId_dVq*dVq_dVim)];    

    Dii = zeros(2,2);

    nu = numel(u);
    Diu = zeros(2,nu);
end