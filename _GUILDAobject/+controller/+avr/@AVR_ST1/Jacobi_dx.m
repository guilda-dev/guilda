function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0) %#ok
    kap = param(4);    
    nx  = numel(x);

    Axx = [  -1,   0,    0;
           -kap,  -1, -kap;
              0,   0,   -1];

    Vre = V(1);
    Vim = V(2);
    Vsq = abs([1,1j]*V);

    Bxv = [[Vre/Vsq, Vim/Vsq]; zeros(2,2)];
    
    Bxi = zeros(nx,2);
    
    Bxu = [zeros(1,2); kap*ones(1,2); zeros(1,2)];
end