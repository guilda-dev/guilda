function [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);
    Vfd = u(2);
    Xd = param(2);
    Xq = param(3);
    
    Vre = V(1);
    Vim = V(2);
        
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
    
    dVd_dd = Vq;
    dVq_dd = -Vd;
    
    Cix = zeros(2,1);
    
    Cix([1,2],1) = [(dVd_dd/Xq)*cos(delta) - (Vd/Xq)*sin(delta) - (dVq_dd/Xd)*sin(delta) + ((Vfd-Vq)/Xd)*cos(delta), ...
                    (dVd_dd/Xq)*sin(delta) + (Vd/Xq)*cos(delta) + (dVq_dd/Xd)*cos(delta) + ((Vfd-Vq)/Xd)*sin(delta)];               

    dVd_dre = sin(delta);
    dVq_dre = cos(delta);
    dVd_dim = -cos(delta);
    dVq_dim = sin(delta);
    
    Div = zeros(2, 2);
        
        
    Div([1,2],1) = [(dVd_dre/Xq)*cos(delta) - (dVq_dre/Xd)*sin(delta), ...
                    (dVd_dre/Xq)*sin(delta) + (dVq_dre/Xd)*cos(delta)];    
        
    Div([1,2],2) = [(dVd_dim/Xq)*cos(delta) - (dVq_dim/Xd)*sin(delta), ...
                    (dVd_dim/Xq)*sin(delta) + (dVq_dim/Xd)*cos(delta)];    

    Dii = zeros(2,2);
    
    Diu = [0, sin(delta)/Xd; 0, -cos(delta)/Xd];
end