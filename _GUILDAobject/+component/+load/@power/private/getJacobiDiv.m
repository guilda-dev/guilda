function Div = getJacobiDiv(t, x, V, u, param) %#ok
    P = u(1);
    Q = u(2);

    Vre  = V(1);
    Vim  = V(2);
    Vabs = abs([1,1j]*V);

    Div = [-P, Q; Q, P]*(Vre^2-Vim^2)/Vabs^4 - 2*[Q, P; P, -Q]*Vre*Vim/Vabs^4;
end