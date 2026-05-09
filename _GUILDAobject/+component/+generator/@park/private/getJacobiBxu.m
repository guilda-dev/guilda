function Bxu = getJacobiBxu(t, x, V, u, array, omega0) %#ok
    nx = numel(x);
    nu = numel(u);
    Bxu = zeros(nx,nu);
    Bxu([2,3], [1,2]) = eye(2);    
end