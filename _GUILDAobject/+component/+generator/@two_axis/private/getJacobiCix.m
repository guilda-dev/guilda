function Cix = getJacobiCix(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);    
    Eq    = x(3);
    Ed    = x(4);

    Vre   = V(5);
    Vim   = V(6);    
    
    Xdp = param(4);    
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
    
    dIre_ddelta = -Iq*sn + dIq_ddelta*cs + Id*cs + dId_ddelta*sn;
    dIim_ddelta =  Iq*cs + dIq_ddelta*sn + Id*sn - dId_ddelta*cs;
    
    dIre_dEq = dId_dEq * sn;
    dIim_dEq = -dId_dEq * cs;
    
    dIre_dEd = dIq_dEd * cs;
    dIim_dEd = dIq_dEd * sn;        
    
    Cix = zeros(2, 4);        
        
    Cix(1, [1,3,4]) = [dIre_ddelta, dIre_dEq, dIre_dEd];            
    Cix(2, [1,3,4]) = [dIim_ddelta,dIim_dEq,dIim_dEd];    
end