function y = fcn_y(t, x, V, I, u, param, omega0) %#ok   
    % Return the output of the AVR_ST1 controller.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu] State `[Vtr; Vap; Vst]`: transducer output, amplifier output and stabilizer feedback.
    % - `V` [pu] Terminal voltage of the generator as `[real; imag]`.
    % - `I` [pu] Terminal current of the generator as `[real; imag]` (unused).
    % - `u` [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
    % - `param` Parameter vector in the order of `sv_para`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % Outputs:
    % - `y` [pu] Field voltage `Vfield` applied to the generator (amplifier output limited to `[Vap_min, Vap_max]`).
    %
    % See also controller.avr.AVR_ST1.fcn_dx, controller.avr.AVR_ST1.Jacobi_Y
    
    Vap_max = param(2);
    Vap_min = param(3);

    y = max(min(x(2),Vap_max),Vap_min);
end