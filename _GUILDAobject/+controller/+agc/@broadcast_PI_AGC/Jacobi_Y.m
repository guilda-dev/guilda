function [Cyx, Dyv, Dyi, Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
    % Return the Jacobians of the broadcast_PI_AGC output.
    % The derivatives of the output `y` of fcn_y are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu*s] Integral `xi` of the weighted frequency deviation.
    % - `V`, `I` Bus voltage and current (unused; empty for a global controller).
    % - `u` [pu] Frequency deviations `omega` of the controlled generators, one row per unit.
    % - `param` Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % Outputs:
    % - `Cyx` Derivative of `y` with respect to `x`.
    % - `Dyv` Derivative of `y` with respect to `V` (`[real; imag]`).
    % - `Dyi` Derivative of `y` with respect to `I` (`[real; imag]`).
    % - `Dyu` Derivative of `y` with respect to `u`.
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_y, controller.agc.broadcast_PI_AGC.Jacobi_dx
    
    alpha = param(:,1);
    kI    = param(1,4);

    Cyx = -kI * alpha;
    Dyv = [];
    Dyi = [];
    
    beta  = param(:,2);
    kP    = param(1,3);            

    Dyu = -kP * (alpha * beta.');    
end