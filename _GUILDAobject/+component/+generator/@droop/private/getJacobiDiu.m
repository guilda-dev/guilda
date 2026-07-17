function Diu = getJacobiDiu(t, x, V, I, u, param, omega0) %#ok
    
    Xd = param(2);         
    delta = x(1);
    
    Diu = [0, sin(delta)/Xd; 0, -cos(delta)/Xd];
end