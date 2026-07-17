function M = fcn_Mass(obj, t, x, V, I, u, param, omega0) %#ok        
    M = param(1)/(2*pi*omega0);
end