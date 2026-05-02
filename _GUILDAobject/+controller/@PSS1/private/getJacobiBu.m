function JacobiBu = getJacobiBu(t, x, V, u, param, omega0) %#ok
    nx = numel(x);
    nu = numel(u);

    kpss = param(1);     

    tn1 = param(3);
    td1 = param(4);

    JacobiBu = zeros(nx,nu);
    JacobiBu([1,2],1) = [kpss; ...
                         kpss*(1-td1/tn1)];
end