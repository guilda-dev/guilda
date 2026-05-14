function Bxu = getJacobiBu(t, x, V, I, u, param, omega0) %#ok
    nx = numel(x);
    nu = numel(u);

    kpss = param(1);     

    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    Bxu = zeros(nx,nu);
    Bxu([1,2,3],1) = [kpss; ...
                      kpss*(1-td1/tn1);
                      kpss*tn1/td1*(1-td2/tn2)];
end