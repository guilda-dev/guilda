function Cyx = getJacobiCyx(t, x, V, I, u, param, omega0) %#ok
    Vap_min = param(3);
    Vap_max = param(2);
    
    Vap = x(2);

    Cyx = [0,1,0] * (heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max));
end