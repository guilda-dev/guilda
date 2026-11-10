function [Cyx, Dyv, Dyu] = Jacobi_Y(t,x,V,u,param,omega0)
    % Return the Jacobians of the broadcast_PI_AGC output.
    % The derivatives of the output `y` of fcn_y are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_y, controller.agc.broadcast_PI_AGC.Jacobi_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu*s] Integral `xi` of the weighted frequency deviation.
        V      double        % [pu] Voltages of all buses `[Vre1; Vim1; Vre2; ...]` (unused).
        u      double        % [pu] Frequency deviations `omega` of the controlled generators, one row per unit.
        param  double        % Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Cyx  % Derivative of `y` with respect to `x`.
        Dyv  % Derivative of `y` with respect to `V` (`[real; imag]`).
        Dyu  % Derivative of `y` with respect to `u`.
    end
    
    alpha = param(:,1);
    kI    = param(1,4);

    Cyx = -kI * alpha;
    Dyv = [];
    
    beta  = param(:,2);
    kP    = param(1,3);            

    Dyu = -kP * (alpha * beta.');    
end