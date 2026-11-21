function [Cyx,Dyv,Dyu] = Jacobi_Y(t, x, V, u, param, omega0)
% Jacobian of the output equation.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        u      double        % Inputs in the order of `sv_u`.
        param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        Cyx  % Jacobian with respect to x (ny-by-0).
        Dyv  % Jacobian with respect to V (zero).
        Dyu  % Jacobian with respect to the observed states (`-K`).
    end
    ny  = size(param.K,1);
    Cyx = zeros(ny,0);
    Dyv = zeros(ny,2);
    Dyu = -param.K;
end
