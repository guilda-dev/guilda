function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
    Vap_min = param(3);
    Vap_max = param(2);
    
    Vap = x(2);

    Cyx = [0,1,0] * (tools.heaviside(Vap - Vap_min) - tools.heaviside(Vap - Vap_max));

    Dyv = zeros(1,2);
    Dyi = zeros(1,2);
    Dyu = zeros(1,2);
end