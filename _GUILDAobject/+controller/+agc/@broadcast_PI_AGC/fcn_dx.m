function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok
    beta  = param(:,2);
    
    dx = beta.' * u;
end