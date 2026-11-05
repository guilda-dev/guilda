function [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0)
% Calculate the Jacobians of the bus current.
%
% Analytic derivatives of `fcn_I`, with the current split as `[real; imag]`.
%
% See also fcn_I
    arguments (Input)
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        I      double        % [pu] Bus current as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        Cix % Jacobian of the bus current `[real; imag]` with respect to `x`.
        Div % Jacobian of the bus current `[real; imag]` with respect to `V` `[real; imag]`.
        Dii % Jacobian of the bus current `[real; imag]` with respect to `I` `[real; imag]`.
        Diu % Jacobian of the bus current `[real; imag]` with respect to `u`.
    end
    Cix = zeros(2,0);
    P = u(1);
    Q = u(2);

    Vre  = V(1);
    Vim  = V(2);
    Vabs = abs([1,1j]*V);

    Div = [-P, Q; Q, P]*(Vre^2-Vim^2)/Vabs^4 - 2*[Q, P; P, -Q]*Vre*Vim/Vabs^4;
    Dii = zeros(2,2);
    
    % Vsq = Vre^2 + Vim^2;
    Vsq = Vabs^2;

    Diu = [ Vre/Vsq,  Vim/Vsq; Vim/Vsq, -Vre/Vsq];
end