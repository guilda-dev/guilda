function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0) %#ok
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
        
    dVd_ddelta =  Vq; 
    dVd_dVre   =  sn;  
    dVd_dVim   = -cs;
    dVq_ddelta = -Vd; 
    dVq_dVre   =  cs;  
    dVq_dVim   =  sn;

    dId_ddelta = -dVq_ddelta / Xdp; 
    dId_dEq    =           1 / Xdp; 
    dId_dVre   = -  dVq_dVre / Xdp;
    dId_dVim   = -  dVq_dVim / Xdp;
    dIq_ddelta =  dVd_ddelta / Xqp; 
    dIq_dEd    = -         1 / Xqp; 
    dIq_dVre   =    dVd_dVre / Xqp;  
    dIq_dVim   =    dVd_dVim / Xqp;

    dPout_ddelta = dVd_ddelta*Id + Vd*dId_ddelta + dVq_ddelta*Iq + Vq*dIq_ddelta;
    dPout_dEq    = Vd * dId_dEq;
    dPout_dEd    = Vq * dIq_dEd;   
    dPout_dVre   = dVd_dVre*Id + Vd*dId_dVre + dVq_dVre*Iq + Vq*dIq_dVre;
    dPout_dVim   = dVd_dVim*Id + Vd*dId_dVim + dVq_dVim*Iq + Vq*dIq_dVim;

    % Axx
    Axx = zeros(4, 4);
    Axx(1, 2) = 2*pi*omega0;
    Axx(2, 1:4) = [-dPout_ddelta, ...
                              -D, ...
                      -dPout_dEq, ...
                      -dPout_dEd];
    Axx(3, [1,3]) = [-(Xd - Xdp) * dId_ddelta, -1 - (Xd - Xdp) * dId_dEq];
    Axx(4, [1,4]) = [ (Xq - Xqp) * dIq_ddelta, -1 + (Xq - Xqp) * dIq_dEd];

    % Bxv
    Bxv = zeros(4, 2);
    Bxv(2, [1,2]) = [-dPout_dVre, -dPout_dVim];                
    Bxv(3, [1,2]) = [-(Xd - Xdp) * dId_dVre, -(Xd - Xdp) * dId_dVim];                
    Bxv(4, [1,2]) = [ (Xq - Xqp) * dIq_dVre,  (Xq - Xqp) * dIq_dVim];    

    % Bxi
    Bxi = zeros(4,2);

    % Bxu
    Bxu = zeros(4, 2);
    Bxu(2, 1) = 1;            
    Bxu(3, 2) = 1;      
end