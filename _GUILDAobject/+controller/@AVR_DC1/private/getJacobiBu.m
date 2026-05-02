function JacobiBu = getJacobiBu(t, x, V, u, param, omega0) %#ok
    nx = numel(x);
    nu = numel(u);

    Vap  = x(2);

    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4); 

    JacobiBu = zeros(nx,nu);

    JacobiBu(2,2) = kap*( heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max) );
end