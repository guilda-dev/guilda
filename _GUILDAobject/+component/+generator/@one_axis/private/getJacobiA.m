function A = getJacobiA(t, x, V, u, param, omega0) %#ok

    delta = x(1);
    Eq    = x(3);

    D   = param(2);
    Xd  = param(3);
    Xq  = param(4);
    Xdp = param(5);

    Vre = V(1);
    Vim = V(2);

    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);

    Id = (Eq - Vq) / Xdp;
    Iq = Vd / Xq;

    dVd_ddelta = Vq;
    dVq_ddelta = -Vd;
    dId_ddelta = Vd / Xdp;
    dIq_ddelta = Vq / Xq;

    dPout_ddelta = dVd_ddelta*Id + Vd*dId_ddelta + dVq_ddelta*Iq + Vq*dIq_ddelta;

    A = zeros(3, 3);

    A(1, 2) = 2 * pi * omega0;

    A(2, 1) = -dPout_ddelta;
    A(2, 2) = -D;
    A(2, 3) = -Vd / Xdp;

    A(3, 1) = -(Xd - Xdp) * Vd / Xdp;
    A(3, 3) = -Xd / Xdp;

end
