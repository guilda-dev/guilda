function dx = fcn_dx(t, x, V, I, u, param, omega0)
% Return the right-hand side `f` of `M*dx/dt = f` (M: fcn_Mass).
    arguments (Input)
        t      double        % [s] Time.
        x      double        % [pu] State `[Pgov; Pdr; Psv; Pw]`.
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
    dx = [-u(1) - param(3)/100*x(1) - param(5)/param(6)*(x(1) - x(2));
          -x(2) + x(1);
          r_rate;
          -x(4) + x(3)];
end
