function dx = fcn_dx(t, x, V, u, param, omega0) %#ok<INUSD>
% State equation of the compensator: `f(x, V, u*) - A_d (x - hat_x)` (multiplied by E in fcn_Mass).
    arguments (Input)
        t      double        % [s] Time.
        x      double        % Compensator states hat_x, in the order of the states of the generator.
        V      double        % [pu] Terminal voltage of the generator [real; imag].
        u      double        % Observed states x of the generator.
        param  (1,1) struct  % Gain K, A_d, E, the equilibrium input u0 and the handles of the generator.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        dx  % Right-hand side, one row per state.
    end
    dx = param.f_dx(t, u, V, param.u0) - param.A * (u - x);
end
