function A = A_AVR_DC1(t, x, V, u, param, omega0) %#ok

    Vap  = x(2);
    Vfld = x(3);
    
    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4);
    aex1    = param(6);
    aex2    = param(7);
    bex     = param(9);
   
    limiter = heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max);

    A = zeros(4, 4);

    A(1,1) = -1;              
    
    A(2,1) = -kap * limiter;
    A(2,2) = -1 * limiter;  
    A(2,4) = -kap * limiter;
    
    exp_part = exp(bex * Vfld);
    A(3,2) = 1;     
    A(3,3) = -aex1 - aex2 * exp_part * (1 + bex * Vfld); 
    
    A(4,4) = -1; 
    
end