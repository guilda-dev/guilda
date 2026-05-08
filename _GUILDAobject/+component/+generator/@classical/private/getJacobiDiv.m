function Div = getJacobiDiv(t, x, V, u, param, omega0) %#ok
    
    delta = x(1);

    Xd = param(3);
    Xq = param(4);    

    dVd_dre = sin(delta);
    dVq_dre = cos(delta);
    dVd_dim = -cos(delta);
    dVq_dim = sin(delta);
    
    Div = zeros(2, 2);
        
        
    Div([1,2],1) = [(dVd_dre/Xq)*cos(delta) - (dVq_dre/Xd)*sin(delta), ...
                    (dVd_dre/Xq)*sin(delta) + (dVq_dre/Xd)*cos(delta)];    
        
    Div([1,2],2) = [(dVd_dim/Xq)*cos(delta) - (dVq_dim/Xd)*sin(delta), ...
                    (dVd_dim/Xq)*sin(delta) + (dVq_dim/Xd)*cos(delta)];    
end