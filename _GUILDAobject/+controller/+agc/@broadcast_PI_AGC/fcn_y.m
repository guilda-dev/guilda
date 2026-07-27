function y = fcn_y(t, x, V, I, u, param, omega0) %#ok
    alpha = param(:,1);
    beta  = param(:,2);
    kP    = param(1,3);
    kI    = param(1,4);
                
    w = beta.' * u;
    y = -alpha * (kP * w + kI * x);
end                    