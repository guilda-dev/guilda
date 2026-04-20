function M = fcn_Mass(obj, t, x, V, u, param, omega0) %#ok
    M    = param(1);
    Tdp  = param(6);

    M = diag( [1,M,Tdp] );
end