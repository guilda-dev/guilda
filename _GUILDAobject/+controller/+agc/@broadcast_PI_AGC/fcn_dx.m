function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok
    % Return the right-hand side of the broadcast_PI_AGC state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`, where `M` is given by fcn_Mass.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu*s] Integral `xi` of the weighted frequency deviation.
    % - `V`, `I` Bus voltage and current (unused; empty for a global controller).
    % - `u` [pu] Frequency deviations `omega` of the controlled generators, one row per unit.
    % - `param` Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_Mass, controller.agc.broadcast_PI_AGC.fcn_y, controller.agc.broadcast_PI_AGC.Jacobi_dx
    arguments (Output)
        dx % Right-hand side `f`, one row per state.
    end
    beta  = param(:,2);
    
    dx = beta.' * u;
end