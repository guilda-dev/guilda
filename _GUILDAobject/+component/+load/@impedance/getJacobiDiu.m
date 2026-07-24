function Diu = getJacobiDiu(t, x, V, I, u, param, omega0) %#ok
    Vre = V(1);
    Vim = V(2);    

    R = u(1);
    X = u(2);

    RX = R^2 + X^2;

    Diu = [Vre*(R^2-X^2) + 2*Vim*R*X,  Vim*(X^2-R^2) + 2*Vre*R*X;
           Vim*(R^2-X^2) - 2*Vre*R*X, -Vre*(X^2-R^2) + 2*Vim*R*X] / RX^2;
end