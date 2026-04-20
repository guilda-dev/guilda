function D = getjacobiD(t, x, V, u, param, omega0) %#ok
    
    delta = x(1);          
    
    Xdpp = param(5);    
    Xqpp = param(8);    
            
    dVd_dVre = sin(delta);  dVd_dVim = -cos(delta);
    dVq_dVre = cos(delta);  dVq_dVim = sin(delta);
    
    dId_dVq    = -1/Xdpp;       
    dIq_dVd    = 1/Xqpp;
    
    D = zeros(2, 2);
   
    D(1,[1,2]) = [cos(delta)*(dIq_dVd*dVd_dVre) + sin(delta)*(dId_dVq*dVq_dVre), ...
                  cos(delta)*(dIq_dVd*dVd_dVim) + sin(delta)*(dId_dVq*dVq_dVim)];    

    D(2,[1,2]) = [sin(delta)*(dIq_dVd*dVd_dVre) - cos(delta)*(dId_dVq*dVq_dVre), ...
                  sin(delta)*(dIq_dVd*dVd_dVim) - cos(delta)*(dId_dVq*dVq_dVim)];    
end