function Bxv = getJacobiBxv(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);    
    Eq    = x(3);
    Ed    = x(4);
    
    Vre   = V(1);
    Vim   = V(2);
        
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
            
    dVd_dVre = sn;  dVd_dVim = -cs;
    dVq_dVre = cs;  dVq_dVim = sn;
        
    dId_dVre = -dVq_dVre / Xdp;  dId_dVim = -dVq_dVim / Xdp;
    dIq_dVre =  dVd_dVre / Xqp;  dIq_dVim =  dVd_dVim / Xqp;
            
    dPout_dVre   = dVd_dVre*Id + Vd*dId_dVre + dVq_dVre*Iq + Vq*dIq_dVre;
    dPout_dVim   = dVd_dVim*Id + Vd*dId_dVim + dVq_dVim*Iq + Vq*dIq_dVim;
            
    Bxv = zeros(4, 2);
                    
    Bxv(2, [1,2]) = [-dPout_dVre, ...
                     -dPout_dVim];                
    Bxv(3, [1,2]) = [-(Xd - Xdp) * dId_dVre, ...
                     -(Xd - Xdp) * dId_dVim];                
    Bxv(4, [1,2]) = [(Xq - Xqp) * dIq_dVre, ...
                     (Xq - Xqp) * dIq_dVim];    
end