function Mass = fcn_Mass(t, x, V, u, param, omega0)
    % Return the mass matrix of the Static AVR: 0x0 (no state).
    %
    % See also controller.avr.Static.fcn_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % State (none, 0x1).
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `[Vfd_ref; Vpss]`.
        param  double        % Parameter vector (empty).
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Mass  % Mass matrix, 0x0.
    end
    Mass = zeros(0,0);
end
