function C = getJacobiC(t, x, V, u, param, omega0) %#ok
    
    delta = x(1);
    Vfd = u(2);
    Xd = param(3);
    Xq = param(4);
    
    Vre = V(1);
    Vim = V(2);
        
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
    
    dVd_dd = Vq;
    dVq_dd = -Vd;
    
    C = zeros(2, 2);
    
    C([1,2],1) = [(dVd_dd/Xq)*cos(delta) - (Vd/Xq)*sin(delta) - (dVq_dd/Xd)*sin(delta) + ((Vfd-Vq)/Xd)*cos(delta), ...
                  (dVd_dd/Xq)*sin(delta) + (Vd/Xq)*cos(delta) + (dVq_dd/Xd)*cos(delta) + ((Vfd-Vq)/Xd)*sin(delta)];
        
    C([1,2],2) = zeros(2,1);    
        
end