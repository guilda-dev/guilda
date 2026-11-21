function y = fcn_y(t, x, V, u, param, omega0)
    % Return the output of the Static governor: `Pmech = Pmech_ref`.
    %
    % See also controller.governor.Static.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % State (none, 0x1).
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `Pmech_ref`.
        param  double        % Parameter vector (empty).
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        y  % [pu] Mechanical power, the `Pmech` input of the generator.
    end
    y = u(1);
end
