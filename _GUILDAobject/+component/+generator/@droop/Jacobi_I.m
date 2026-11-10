function [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0)
% Calculate the Jacobians of the bus current.
%
% Analytic derivatives of `fcn_I`, with the current split as `[real; imag]`.
%
% See also fcn_I
    arguments (Input)
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        Cix % Jacobian of the bus current `[real; imag]` with respect to `x`.
        Div % Jacobian of the bus current `[real; imag]` with respect to `V` `[real; imag]`.
        Diu % Jacobian of the bus current `[real; imag]` with respect to `u`.
    end
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

    
    Diu = [0, sin(delta)/Xd; 0, -cos(delta)/Xd];
end