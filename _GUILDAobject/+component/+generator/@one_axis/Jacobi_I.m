function [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);
    Eq    = x(3);

    Xq  = param(4);
    Xdp = param(5);

    Vre = V(1);
    Vim = V(2);

    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);

    Id = (Eq - Vq) / Xdp;

    dVd_ddelta = Vq;
    dVq_ddelta = -Vd;

    Cix = zeros(2, 3);

    Cix([1,2], 1) = [(dVd_ddelta/Xq)*cos(delta) - (Vd/Xq)*sin(delta) - (dVq_ddelta/Xdp)*sin(delta) + Id*cos(delta); ...
                     (dVd_ddelta/Xq)*sin(delta) + (Vd/Xq)*cos(delta) + (dVq_ddelta/Xdp)*cos(delta) + Id*sin(delta)];

    Cix([1,2], 3) = [ sin(delta)/Xdp; ...
                    -cos(delta)/Xdp];    

    dVd_dVre = sin(delta);
    dVq_dVre = cos(delta);
    dVd_dVim = -cos(delta);
    dVq_dVim = sin(delta);

    Div = zeros(2, 2);

    Div([1,2], 1) = [(dVd_dVre/Xq)*cos(delta) - (dVq_dVre/Xdp)*sin(delta); ...
                     (dVd_dVre/Xq)*sin(delta) + (dVq_dVre/Xdp)*cos(delta)];

    Div([1,2], 2) = [(dVd_dVim/Xq)*cos(delta) - (dVq_dVim/Xdp)*sin(delta); ...
                     (dVd_dVim/Xq)*sin(delta) + (dVq_dVim/Xdp)*cos(delta)];

    Dii = zeros(2,2);

    Diu = zeros(2,2);
end