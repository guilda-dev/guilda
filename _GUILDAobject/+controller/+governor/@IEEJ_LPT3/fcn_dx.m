function dx = fcn_dx(t, x, V, I, u, param, omega0)
% Return the right-hand side `f` of `M*dx/dt = f` (M: fcn_Mass).
    arguments (Input)
        t      double        % [s] Time.
        x      double        % [pu] State `[Pgov; Psv]`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        I      double        % [pu] Terminal current of the parent [real; imag].
        u      double        % [pu] Input `[omega; Pref; Plimit]`.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        dx  % Right side of the state equation in the order of `sv_x`.
    end
    [r_rate, ~] = rate(x, u, param);
    dx = [-x(1) + 100/param(3)*u(1);
          r_rate];
end
