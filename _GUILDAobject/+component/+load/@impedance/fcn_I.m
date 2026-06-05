function  I = fcn_I(obj,t,x,V,I,u,param) %#ok
    V = [1,1j]*V;
    Z = [1,1j]*u;
    I = -V/Z;
end