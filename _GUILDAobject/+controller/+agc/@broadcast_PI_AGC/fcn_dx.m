function dx = fcn_dx(t, x, V, I, u, param, omega0)
    % Return the right-hand side of the broadcast_PI_AGC state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`, where `M` is given by fcn_Mass.
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_Mass, controller.agc.broadcast_PI_AGC.fcn_y, controller.agc.broadcast_PI_AGC.Jacobi_dx
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
        dx  % Right-hand side `f`, one row per state.
    end
    beta  = param(:,2);
    
    dx = beta.' * u;
end