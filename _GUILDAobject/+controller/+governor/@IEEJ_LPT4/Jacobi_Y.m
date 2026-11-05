function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0)
% Return the Jacobians of fcn_y.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        I      double        % [pu] Terminal current of the parent [real; imag].
        u      double        % Inputs in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        Cyx  % Jacobian of `fcn_y` with respect to `x`.
        Dyv  % Jacobian of `fcn_y` with respect to `V` `[real; imag]`.
        Dyi  % Jacobian of `fcn_y` with respect to `I` `[real; imag]`.
        Dyu  % Jacobian of `fcn_y` with respect to `u`.
    end
    Cyx = param(1)*[0, 0, param(14), param(13)];
    Dyv = zeros(1,2);
    Dyi = zeros(1,2);
    Dyu = zeros(1,3);
end
