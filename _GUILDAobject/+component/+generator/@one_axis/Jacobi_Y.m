function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
    Cyx = [0,1,0];
    Dyv = zeros(1,2);
    Dyi = zeros(1,2);
    Dyu = zeros(1,2);
end