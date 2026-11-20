function y = fcn_y(t, x, V, u, param, omega0)
    % Return the output of the AVR_DC1 controller.
    %
    % See also controller.avr.AVR_DC1.fcn_dx, controller.avr.AVR_DC1.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vfld; Vst]`: transducer output, amplifier output, field voltage and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        u      double        % [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        y  % [pu] Field voltage `Vfield` applied to the generator.
    end

    y = x(3);
end