function B = B_AVR_DC1(t, x, V, u, param, omega0) %#ok

    Vre  = V(1);
    Vim  = V(2);
    
    Vabs = sqrt(Vre^2 + Vim^2);
    dVabs_dVre = Vre / Vabs;
    dVabs_dVim = Vim / Vabs;

    B = zeros(4, 2);
    
    B(1,[1,2]) = [dVabs_dVre;dVabs_dVim];      
    
end