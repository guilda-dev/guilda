function Bxu = getJacobiBxu(t, x, V, I, u, param, omega0) %#ok
    nx = numel(x);
    nu = numel(u);

    Vap  = x(2);

    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4); 

    Bxu = zeros(nx,nu);

    Bxu(2,[1,2]) = [kap,kap]*( heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max) );
end