function M = fcn_Mass(obj, t, x, V, u, param, omega0) %#ok    
    M = diag([1,param(1)]);
end