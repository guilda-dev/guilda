function y = fcn_y(t, x, V, u, param, omega0)
    % Return the output of the Static AVR: `Vfield = Vfd_ref + Vpss`.
    %
    % See also controller.avr.Static.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % State (none, 0x1).
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `[Vfd_ref; Vpss]`.
        param  double        % Parameter vector (empty).
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        y  % [pu] Field voltage, the `Vfield` input of the generator.
    end
    y = u(1) + u(2);
end
