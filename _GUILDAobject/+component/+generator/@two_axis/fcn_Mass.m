function M = fcn_Mass(obj,t,x,V,I,u,param,omega0) %#ok
    
    M    = param(1);
    Tdp  = para(7);
    Tqp  = para(8);
    
    M = diag( [1,M,Tdp,Tqp] );
end