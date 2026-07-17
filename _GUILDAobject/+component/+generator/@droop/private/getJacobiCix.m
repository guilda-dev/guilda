function Cix = getJacobiCix(t, x, V, I, u, param, omega0) %#ok
    
    delta = x(1);
    Vfd = u(2);
    Xd = param(2);
    Xq = param(3);
    
    Vre = V(1);
    Vim = V(2);
        
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
    
    dVd_dd = Vq;
    dVq_dd = -Vd;
    
    Cix = zeros(2,1);
    
    Cix([1,2],1) = [(dVd_dd/Xq)*cos(delta) - (Vd/Xq)*sin(delta) - (dVq_dd/Xd)*sin(delta) + ((Vfd-Vq)/Xd)*cos(delta), ...
                    (dVd_dd/Xq)*sin(delta) + (Vd/Xq)*cos(delta) + (dVq_dd/Xd)*cos(delta) + ((Vfd-Vq)/Xd)*sin(delta)];           
        
end