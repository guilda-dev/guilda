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
    % I = -V/Z with Z = R + jX
    Vre = V(1);
    Vim = V(2);

    R = u(1);
    X = u(2);

    RX = R^2 + X^2;

    Cix = zeros(2,0);

    Div = [ -R, -X; 
             X, -R] / RX;


    Diu = [Vre*(R^2-X^2) + 2*Vim*R*X,  Vim*(X^2-R^2) + 2*Vre*R*X;
           Vim*(R^2-X^2) - 2*Vre*R*X, -Vre*(X^2-R^2) + 2*Vim*R*X] / RX^2;
end
