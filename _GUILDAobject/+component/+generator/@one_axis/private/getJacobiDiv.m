function Div = getJacobiDiv(t,x,V,I,u,param,omega0) %#ok

    delta = x(1);

    Xq  = param(4);
    Xdp = param(5);

    dVd_dVre = sin(delta);
    dVq_dVre = cos(delta);
    dVd_dVim = -cos(delta);
    dVq_dVim = sin(delta);

    Div = zeros(2, 2);

    Div([1,2], 1) = [(dVd_dVre/Xq)*cos(delta) - (dVq_dVre/Xdp)*sin(delta); ...
                     (dVd_dVre/Xq)*sin(delta) + (dVq_dVre/Xdp)*cos(delta)];

    Div([1,2], 2) = [(dVd_dVim/Xq)*cos(delta) - (dVq_dVim/Xdp)*sin(delta); ...
                     (dVd_dVim/Xq)*sin(delta) + (dVq_dVim/Xdp)*cos(delta)];

end
