function dx = fcn_dx(obj, t, x, V, I, u, param, omega0) %#ok
    beta  = param(:,2);
    
    dx = beta.' * u;
end