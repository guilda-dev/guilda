function [R,Hxx,Hxv,Hvv] = hesse(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);

    D  = param(2);
    Xd = param(3);
    Xq = param(4);
    
    Vfd = u(2);
    
    Vre = V(1);
    Vim = V(2);

    Ire = I(1);
    Iim = I(1);
    
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);

    P = 

    % P + j*Q = (Vre + j*Vim)(Ire - j*Iim)
    P =   Vre*Ire + Vim*Iim;
    Q = - Vre*Iim + Vim*Ire;

    Hdd = P + (1/Xq - 1/Xd)*Vd*Vq;

          
    R = [D/omega0 M; -M 0];
    Hxx = []
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
