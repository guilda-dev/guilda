function y = fcn_y(t, x, V, I, u, param, omega0) %#ok
    % Return the output of the broadcast_PI_AGC controller.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu*s] Integral `xi` of the weighted frequency deviation.
    % - `V`, `I` Bus voltage and current (unused; empty for a global controller).
    % - `u` [pu] Frequency deviations `omega` of the controlled generators, one row per unit.
    % - `param` Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_dx, controller.agc.broadcast_PI_AGC.Jacobi_Y
    arguments (Output)
        y % [pu] Mechanical power commands `Pmech`, one row per controlled unit.
    end
    alpha = param(:,1);
    beta  = param(:,2);
    kP    = param(1,3);
    kI    = param(1,4);
                
    w = beta.' * u;
    y = -alpha * (kP * w + kI * x);
end                    