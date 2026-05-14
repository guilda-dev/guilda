function Bxv = getJacobiBxv(t, x, V, I, u, param, omega0) %#ok

    Vre  = V(1);
    Vim  = V(2);
    
    Vabs = sqrt(Vre^2 + Vim^2);
    dVabs_dVre = Vre / Vabs;
    dVabs_dVim = Vim / Vabs;

    Bxv = zeros(4, 2);
    
    Bxv(1,[1,2]) = [dVabs_dVre,dVabs_dVim];      
    
end