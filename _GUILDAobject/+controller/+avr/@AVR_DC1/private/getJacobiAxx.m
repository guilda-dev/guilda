function Axx = getJacobiAxx(t, x, V, I, u, param, omega0) %#ok

    Vap  = x(2);
    Vfld = x(3);
    
    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4);
    aex1    = param(6);
    aex2    = param(7);
    bex     = param(9);
   
    limiter = heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max);

    Axx = zeros(4, 4);

    Axx(1,1) = -1;              
    
    Axx(2,[1,2,4]) = [-kap * limiter, ...
                        -1 * limiter, ...
                      -kap * limiter];    
    
    exp_part = exp(bex * Vfld);
    Axx(3,[2,3]) = [1, ...
                    -aex1 - aex2 * exp_part * (1 + bex * Vfld)];         
    
    Axx(4,4) = -1; 
    
end