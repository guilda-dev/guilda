function [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);    
    Eq    = x(3);
    Ed    = x(4);

    Vre   = V(1);
    Vim   = V(2);    
    
    Xdp = param(4);    
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
    
    dIre_ddelta = -Iq*sn + dIq_ddelta*cs + Id*cs + dId_ddelta*sn;
    dIre_dEq    =  dId_dEq * sn;
    dIre_dEd    =  dIq_dEd * cs;
    dIre_dVre   =  dIq_dVre*cs + dId_dVre*sn;
    dIre_dVim   =  dIq_dVim*cs + dId_dVim*sn;

    dIim_ddelta =  Iq*cs + dIq_ddelta*sn + Id*sn - dId_ddelta*cs;
    dIim_dEq    = -dId_dEq * cs;
    dIim_dEd    =  dIq_dEd * sn;      
    dIim_dVre   =  dIq_dVre*sn - dId_dVre*cs;
    dIim_dVim   =  dIq_dVim*sn - dId_dVim*cs;
    
    % Cix
    Cix = zeros(2, 4);        
    Cix(1, [1,3,4]) = [dIre_ddelta, dIre_dEq, dIre_dEd];            
    Cix(2, [1,3,4]) = [dIim_ddelta,dIim_dEq,dIim_dEd];    

    % Div
    Div = zeros(2, 2);        
    Div(1, [1,2]) = [dIre_dVre,dIre_dVim];                
    Div(2, [1,2]) = [dIim_dVre,dIim_dVim];   

    % Dii
    Dii = zeros(2,2);

    % Diu
    Diu = zeros(2,2);
end