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
        Cix  % Jacobian of the bus current `[real; imag]` with respect to `x`.
        Div  % Jacobian of the bus current `[real; imag]` with respect to `V` `[real; imag]`.
        Diu  % Jacobian of the bus current `[real; imag]` with respect to `u`.
    end
    % I = (Ip - jIq) V/|V|: Re I = (Ip Vre + Iq Vim)/|V|, Im I = (Ip Vim - Iq Vre)/|V|
    Ip   = u(1);
    Iq   = u(2);
    Vre  = V(1);
    Vim  = V(2);
    Vabs = abs([1,1j]*V);

    Cix = zeros(2,0);

    Diu = [Vre,  Vim;
           Vim, -Vre] / Vabs;

    I = Diu*[Ip; Iq];
    Div = [ Ip, Iq;
           -Iq, Ip] / Vabs - I*[Vre, Vim] / Vabs^2;
end
