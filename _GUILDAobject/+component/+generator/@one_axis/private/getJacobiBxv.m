function Bxv = getJacobiBxv(t,x,V,I,u,param,omega0) %#ok

    delta = x(1);
    Eq    = x(3);

    Xd  = param(3);
    Xq  = param(4);
    Xdp = param(5);

    Vre = V(1);
    Vim = V(2);
    
    Vd  = Vre*sin(delta) - Vim*cos(delta);
    Vq  = Vre*cos(delta) + Vim*sin(delta);
    
    invXdp = 1 / Xdp;
    invXq  = 1 / Xq;
    X_diff = invXq - invXdp;
    Xd_ratio = (Xd - Xdp) * invXdp;
            
    dP_dVre   = (Eq * invXdp * sin(delta)) + X_diff * (Vq * sin(delta) + Vd * cos(delta));
    dP_dVim   = -(Eq * invXdp * cos(delta)) + X_diff * (-Vq * cos(delta) + Vd * sin(delta));        

    Bxv = zeros(3, 2);    
                
    Bxv(2, 1) = -dP_dVre;
    Bxv(2, 2) = -dP_dVim;
        
    Bxv(3, 1) = Xd_ratio * cos(delta);
    Bxv(3, 2) = Xd_ratio * sin(delta);
    
end
