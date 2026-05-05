function Axx = getJacobiAxx(t, x, V, u, param, omega0) %#ok

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
        
    Axx(1, [1,2]) = [0, omega0];              
    Axx(2, [1,2]) = [-dP_ddelta, -D];  
end