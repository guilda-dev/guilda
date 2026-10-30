function M = fcn_Mass(t, x, V, I, u, param, omega0) %#ok
    % Return the mass matrix of the broadcast_PI_AGC state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`. The diagonal of `M` holds the time constants [s];
    % a zero time constant makes the corresponding equation algebraic.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu*s] Integral `xi` of the weighted frequency deviation.
    % - `V`, `I` Bus voltage and current (unused; empty for a global controller).
    % - `u` [pu] Frequency deviations `omega` of the controlled generators, one row per unit.
    % - `param` Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_dx
    arguments (Output)
        M % Mass matrix `M`, one row and column per state.
    end
    M = 1;
end