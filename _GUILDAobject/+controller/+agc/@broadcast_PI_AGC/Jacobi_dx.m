function [Axx, Bxv, Bxi, Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0) %#ok    
    % Return the Jacobians of the broadcast_PI_AGC state equation.
    % The derivatives of the right-hand side `f` of fcn_dx are taken with respect to
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
    % - `Axx` Derivative of `f` with respect to `x`.
    % - `Bxv` Derivative of `f` with respect to `V` (`[real; imag]`).
    % - `Bxi` Derivative of `f` with respect to `I` (`[real; imag]`).
    % - `Bxu` Derivative of `f` with respect to `u`.
    %
    % See also controller.agc.broadcast_PI_AGC.fcn_dx, controller.agc.broadcast_PI_AGC.Jacobi_Y
    Axx = 0;
    Bxv = []; 
    Bxi = [];
    beta = param(:,2);
    Bxu  = beta.';
end