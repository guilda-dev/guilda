function Axx = getJacobiAxx(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);
    Eq    = x(3);
    Ed    = x(4);
    
    Vre   = V(1);
    Vim   = V(2);
    
    D   = param(2);
    Xd  = param(3);
    Xdp = param(4);
    Xq  = param(5);
    Xqp = param(6);
        
    sn = sin(delta);
    cs = cos(delta);
    
    Vd = Vre*sn - Vim*cs;
    Vq = Vre*cs + Vim*sn;
    
    Id = (Eq - Vq) / Xdp;
    Iq = (Vd - Ed) / Xqp;
        
    dVd_ddelta = Vq;
    dVq_ddelta = -Vd;
            
    dId_ddelta = -dVq_ddelta / Xdp;
    dIq_ddelta =  dVd_ddelta / Xqp;
    
    dId_dEq =  1 / Xdp;
    dIq_dEd = -1 / Xqp;        
        
    dPout_ddelta = dVd_ddelta*Id + Vd*dId_ddelta + dVq_ddelta*Iq + Vq*dIq_ddelta;
    dPout_dEq    = Vd * dId_dEq;
    dPout_dEd    = Vq * dIq_dEd;            
    
    Axx = zeros(4, 4);
    
    Axx(1, 2) = omega0;
        
    Axx(2, 1:4) = [-dPout_ddelta, ...
                              -D, ...
                      -dPout_dEq, ...
                      -dPout_dEd];
        
    Axx(3, [1,3]) = [   -(Xd - Xdp) * dId_ddelta, ...
                     -1 -(Xd - Xdp) * dId_dEq];    
        
    Axx(4, [1,4]) = [     (Xq - Xqp) * dIq_ddelta, ...
                     -1 + (Xq - Xqp) * dIq_dEd];                
end