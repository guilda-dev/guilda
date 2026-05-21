function Bxu = getJacobiBxu(t, x, V, I, u, param, omega0) %#ok

    kap = param(4);
    
    Bxu = [zeros(1,2); kap*ones(1,2); zeros(1,2)];
end