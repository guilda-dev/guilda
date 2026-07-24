function [Cyx, Dyv, Dyi, Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
    
    alpha = param(:,1);
    kI    = param(1,4);

    Cyx = -kI * alpha;
    Dyv = [];
    Dyi = [];
    
    beta  = param(:,2);
    kP    = param(1,3);            

    Dyu = -kP * (alpha * beta.');    
end