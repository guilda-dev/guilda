function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)
% Calculate the Jacobians of the state equation.
%
% Analytic derivatives of `fcn_dx` at the given point, used for linearization.
%
% See also fcn_dx
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
        Axx % Jacobian of `fcn_dx` with respect to `x`.
        Bxv % Jacobian of `fcn_dx` with respect to `V` `[real; imag]`.
        Bxi % Jacobian of `fcn_dx` with respect to `I` `[real; imag]`.
        Bxu % Jacobian of `fcn_dx` with respect to `u`.
    end
    Axx = zeros(0,0);
    Bxv = zeros(0,2);
    Bxi = zeros(0,2);
    Bxu = zeros(0,2);
end
