function y = fcn_y(t, x, V, I, u, param, omega0)
    % Return the output of the AVR_ST1 controller.
    %
    % See also controller.avr.AVR_ST1.fcn_dx, controller.avr.AVR_ST1.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vst]`: transducer output, amplifier output and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        I      double        % [pu] Terminal current of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        y  % [pu] Field voltage `Vfield` applied to the generator (amplifier output limited to `[Vap_min, Vap_max]`).
    end
    
    Vap_max = param(2);
    Vap_min = param(3);

    y = max(min(x(2),Vap_max),Vap_min);
end