function [Axx, Bxv, Bxu] = Jacobi_dx(t,x,V,u,param,omega0)
    % Return the Jacobians of the broadcast_PI_AGC state equation.
    % The derivatives of the right-hand side `f` of fcn_dx are taken with respect to
    % the state, the voltage, the current and the input.
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
        Axx  % Derivative of `f` with respect to `x`.
        Bxv  % Derivative of `f` with respect to `V` (`[real; imag]`).
        Bxu  % Derivative of `f` with respect to `u`.
    end
    Axx = 0;
    Bxv = []; 
    beta = param(:,2);
    Bxu  = beta.';
end