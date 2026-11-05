function M = fcn_Mass(t, x, V, I, u, param, omega0)
    % Return the mass matrix of the broadcast_PI_AGC state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`. The diagonal of `M` holds the time constants [s];
    % a zero time constant makes the corresponding equation algebraic.
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu*s] Integral `xi` of the weighted frequency deviation.
        V      double        % , `I` Bus voltage and current (unused; empty for a global controller).
        I      double        % Unused: empty for a global controller.
        u      double        % [pu] Frequency deviations `omega` of the controlled generators, one row per unit.
        param  double        % Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        M  % Mass matrix `M`, one row and column per state.
    end
    M = 1;
end