function y = fcn_y(obj, t, x, V, I, u, param, omega0) %#ok   
    
    Vap_max = param(2);
    Vap_min = param(3);

    y = max(min(x(2),Vap_max),Vap_min);
end