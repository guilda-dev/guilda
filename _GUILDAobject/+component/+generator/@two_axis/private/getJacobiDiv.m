function Div = getJacobiDiv(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);    
            
    Xdp = param(4);    
    Xqp = param(6);
        
    sn = sin(delta);
    cs = cos(delta);
    
    dVd_dVre = sn;  dVd_dVim = -cs;
    dVq_dVre = cs;  dVq_dVim = sn;
            
    dId_dVre = -dVq_dVre / Xdp;  dId_dVim = -dVq_dVim / Xdp;
    dIq_dVre =  dVd_dVre / Xqp;  dIq_dVim =  dVd_dVim / Xqp;
            
    dIre_dVre = dIq_dVre*cs + dId_dVre*sn;
    dIre_dVim = dIq_dVim*cs + dId_dVim*sn;
    
    dIim_dVre = dIq_dVre*sn - dId_dVre*cs;
    dIim_dVim = dIq_dVim*sn - dId_dVim*cs;
    
    Div = zeros(2, 2);        
            
    Div(1, [1,2]) = [dIre_dVre,dIre_dVim];                
    Div(2, [1,2]) = [dIim_dVre,dIim_dVim];    
end