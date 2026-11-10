function [Cyx, Dyv] = Jacobi_Y(t,x,V,param,omega0)
% Calculate the Jacobians of the output.
%
% Analytic derivatives of `fcn_Y` at the given point.
%
% See also fcn_Y
    arguments (Input)
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        Cyx % Jacobian of `fcn_Y` with respect to `x`.
        Dyv % Jacobian of `fcn_Y` with respect to `V` `[real; imag]`.
    end
    Cyx = zeros(1,2);
    Cyx(2) = 1;

    Dyv = zeros(1,2);    
end