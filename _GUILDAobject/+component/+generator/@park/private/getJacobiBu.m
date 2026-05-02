function JacobiBu = getJacobiBu(t, x, V, u, array, omega0) %#ok
    nx = numel(x);
    nu = numel(u);
    JacobiBu = zeros(nx,nu);
    JacobiBu([2,3],[1,2]) = 1;
end