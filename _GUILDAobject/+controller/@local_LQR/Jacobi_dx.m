function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0)
% Jacobian of the state equation (empty: no state).
    arguments (Input)
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        I      double        % [pu] Terminal current of the parent [real; imag].
        u      double        % Inputs in the order of `sv_u`.
        param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        Axx  % Empty Jacobian with respect to x (0-by-0).
        Bxv  % Empty Jacobian with respect to V (0-by-2).
        Bxi  % Empty Jacobian with respect to I (0-by-2).
        Bxu  % Empty Jacobian with respect to u (0-by-nu).
    end
    Axx = zeros(0,0);
    Bxv = zeros(0,2);
    Bxi = zeros(0,2);
    Bxu = zeros(0,numel(u));
end
