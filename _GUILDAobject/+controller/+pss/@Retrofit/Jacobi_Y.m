function [Cyx,Dyv,Dyu] = Jacobi_Y(t, x, V, u, param, omega0) %#ok<INUSD>
% Jacobian of the output equation: `K`, 0 and `-K`.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % Compensator states hat_x.
        V      double        % [pu] Terminal voltage of the generator [real; imag].
        u      double        % Observed states x of the generator.
        param  (1,1) struct  % Gain K, A_d, E, the equilibrium input u0 and the handles of the generator.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        Cyx  % Jacobian with respect to hat_x (K).
        Dyv  % Jacobian with respect to V (zero).
        Dyu  % Jacobian with respect to the observed states (-K).
    end
    Cyx = param.K;
    Dyv = zeros(1,2);
    Dyu = -param.K;
end
