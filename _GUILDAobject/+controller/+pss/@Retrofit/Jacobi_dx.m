function [Axx,Bxv,Bxu] = Jacobi_dx(t, x, V, u, param, omega0) %#ok<INUSD>
% Jacobian of the state equation: `A_d`, `df/dV` and `df/dx - A_d` at (x, V, u*).
    arguments (Input)
        t      double        % [s] Time.
        x      double        % Compensator states hat_x.
        V      double        % [pu] Terminal voltage of the generator [real; imag].
        u      double        % Observed states x of the generator.
        param  (1,1) struct  % Gain K, A_d, E, the equilibrium input u0 and the handles of the generator.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        Axx  % Jacobian with respect to hat_x (A_d).
        Bxv  % Jacobian with respect to V (df/dV of the generator).
        Bxu  % Jacobian with respect to the observed states (df/dx - A_d).
    end
    [Ax, Bxv] = param.f_JacobiDx(t, u, V, param.u0);
    Axx = param.A;
    Bxu = Ax - param.A;
end
