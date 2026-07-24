function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
    Cyx = zeros(1, 4);    
    
    Cyx(1,3) = 1; 

    Dyv = zeros(1,2);

    Dyi = zeros(1,2);

    nu = numel(u);
    Dyu = zeros(1,nu);
end