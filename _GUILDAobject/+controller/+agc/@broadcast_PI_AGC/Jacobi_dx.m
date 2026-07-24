function [Axx, Bxv, Bxi, Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0) %#ok    
    Axx = 0;
    Bxv = []; 
    Bxi = [];
    beta = param(:,2);
    Bxu  = beta.';
end