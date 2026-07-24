function Bxv = getJacobiBxv(t, x, V, I, u, param, omega0) %#ok
    
    delta = x(1);

    Xd = param(3);
    Xq = param(4);
        
    Vfd = u(2);
        
    Vre = V(1);
    Vim = V(2);
        
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
        
    K = (1/Xq - 1/Xd);
        
    dP_dVre = K * (Vq*sin(delta) + Vd*cos(delta)) + (Vfd/Xd)*sin(delta);        
    dP_dVim = K * (Vq*(-cos(delta)) + Vd*sin(delta)) - (Vfd/Xd)*cos(delta);       
    
    Bxv = zeros(2, 2);
        
    Bxv(1, [1,2]) = zeros(1,2);        
    Bxv(2, [1,2]) = [-dP_dVre, -dP_dVim];     
end