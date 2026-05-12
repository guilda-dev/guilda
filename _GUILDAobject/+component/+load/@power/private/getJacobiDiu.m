function Diu = getJacobiDiu(t, x, V, I, u, param) %#ok
    Vre = V(1);
    Vim = V(2);
    Vsq = Vre^2 + Vim^2;

    Diu = [ Vre/Vsq,  Vim/Vsq; Vim/Vsq, -Vre/Vsq];
end