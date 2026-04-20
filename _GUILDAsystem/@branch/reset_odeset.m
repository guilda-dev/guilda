function [n_odeX, n_odeU, Mass, x0] = reset_odeset(~, n_odeX, n_odeU, omega0) %#ok
    Mass = zeros(0,0);
    x0   = zeros(0,1);
    return 
end