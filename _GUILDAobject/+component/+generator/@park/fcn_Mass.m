function M = fcn_Mass(obj, t, x, V, u, para, omega0) %#ok
    
    M    = para(1);
    Tdp  = para(9);
    Tdpp = para(10);
    Tqp  = para(11);    
    Tqpp = para(12);

    M = diag( [1,M,Tdp,Tqp,Tqpp,Tdpp] );
end