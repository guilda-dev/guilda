function [Cyx, Dyv, Dyi, Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
    Cyx = zeros(1,2);
    Cyx(2) = 1;

    Dyv = zeros(1,2);    
    Dyi = zeros(1,2);
    Dyu = zeros(1,2);    
end