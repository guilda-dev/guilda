function Bxv = getJacobiBxv(t, x, V, I, u, param, omega0) %#ok
    Vre = V(1);
    Vim = V(2);
    Vsq = abs([1,1j]*V);

    Bxv = [[Vre/Vsq, Vim/Vsq]; zeros(2,2)];
end