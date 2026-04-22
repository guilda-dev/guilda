function B = getJacobiB(t, x, V, u, param, omega0) %#ok

    delta = x(1);
    Eq    = x(3);

    Xd  = param(3);
    Xq  = param(4);
    Xdp = param(5);

    Vre = V(1);
    Vim = V(2);

    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);

    Id = (Eq - Vq) / Xdp;
    Iq = Vd / Xq;

    dVd_dVre = sin(delta);
    dVq_dVre = cos(delta);
    dVd_dVim = -cos(delta);
    dVq_dVim = sin(delta);

    dId_dVre = -dVq_dVre / Xdp;
    dIq_dVre =  dVd_dVre / Xq;
    dId_dVim = -dVq_dVim / Xdp;
    dIq_dVim =  dVd_dVim / Xq;

    dPout_dVre = dVd_dVre*Id + Vd*dId_dVre + dVq_dVre*Iq + Vq*dIq_dVre;
    dPout_dVim = dVd_dVim*Id + Vd*dId_dVim + dVq_dVim*Iq + Vq*dIq_dVim;

    B = zeros(3, 2);

    B(2, 1) = -dPout_dVre;
    B(2, 2) = -dPout_dVim;

    B(3, 1) = (Xd - Xdp) * dVq_dVre / Xdp;
    B(3, 2) = (Xd - Xdp) * dVq_dVim / Xdp;

end
