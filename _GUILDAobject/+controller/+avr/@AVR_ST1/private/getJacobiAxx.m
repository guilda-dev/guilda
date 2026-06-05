function Axx = getJacobiAxx(t, x, V, I, u, param, omega0) %#ok

    kap  = param(4);
    % kst  = param(6);

    Axx = [  -1,   0,    0;
           -kap,  -1, -kap;
              0,   0,   -1];
end