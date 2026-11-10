function y = fcn_y(t, x, V, u, param, omega0)
    % Return the output of the broadcast_PI_AGC controller.
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_dx, controller.agc.broadcast_PI_AGC.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu*s] Integral `xi` of the weighted frequency deviation.
        V      double        % [pu] Voltages of all buses `[Vre1; Vim1; Vre2; ...]` (unused).
        u      double        % [pu] Frequency deviations `omega` of the controlled generators, one row per unit.
        param  double        % Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        y  % [pu] Mechanical power commands `Pmech`, one row per controlled unit.
    end
    alpha = param(:,1);
    beta  = param(:,2);
    kP    = param(1,3);
    kI    = param(1,4);
                
    w = beta.' * u;
    y = -alpha * (kP * w + kI * x);
end                    