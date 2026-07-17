function Axx = getJacobiAxx(t, x, V, I, u, param, omega0) %#ok

    delta = x(1);
    
    Xd = param(2);
    Xq = param(3);
    
    Vfd = u(2);
    
    Vre = V(1);
    Vim = V(2); 
    
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);            
       
    dP_ddelta = (1/Xq - 1/Xd) * (Vq^2 - Vd^2) + (Vfd/Xd) * Vq;           
            
    Axx = -dP_ddelta;  
end