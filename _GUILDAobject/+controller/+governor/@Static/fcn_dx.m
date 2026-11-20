function dx = fcn_dx(t, x, V, u, param, omega0)
    % Return the right-hand side of the state equation of the Static governor: empty (no state).
    %
    % See also controller.governor.Static.fcn_y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % State (none, 0x1).
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `Pmech_ref`.
        param  double        % Parameter vector (empty).
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        dx  % Right-hand side, 0x1.
    end
    dx = zeros(0,1);
end
