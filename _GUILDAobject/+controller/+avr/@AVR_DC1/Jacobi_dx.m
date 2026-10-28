function [Axx,Bxv,Bxi,Bxu] = Jaocbi_dx(t,x,V,I,u,param,omega0) %#ok
    Vtr  = x(1);
    Vap  = x(2);
    Vfld = x(3);
    Vst  = x(4);
    
    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4);
    aex1    = param(6);
    aex2    = param(7);
    bex     = param(9);

    Vref = u(1);
    Vpss = u(2);
    Vcom = Vref + Vpss - Vtr - Vst;            

    Axx = zeros(4, 4);

    Axx(1,1) = -1;              

    rv = 0;
    if Vap*Vcom<=0 || (Vap_min < Vap && Vap_max > Vap)
        rv = 1;
    end
    
    Axx(2,[1,2,4]) = [-kap, -1, -kap] * rv;    
    
    exp_part = exp(bex * Vfld);
    Axx(3,[2,3]) = [1, -aex1 - aex2 * exp_part * (1 + bex * Vfld)];         
    
    Axx(4,4) = -1; 

    Vre  = V(1);
    Vim  = V(2);
    
    Vabs = sqrt(Vre^2 + Vim^2);
    dVabs_dVre = Vre / Vabs;
    dVabs_dVim = Vim / Vabs;

    Bxv = zeros(4, 2);
    
    Bxv(1,[1,2]) = [dVabs_dVre,dVabs_dVim];      

    nx  = numel(x);
    Bxi = zeros(nx,2);
    
    nu = numel(u);    

    Bxu = zeros(nx,nu);

    Bxu(2,[1,2]) = [kap,kap]*( tools.heaviside(Vap - Vap_min) - tools.heaviside(Vap - Vap_max) );
end