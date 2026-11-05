function Mass = fcn_Mass(t, x, V, I, u, param, omega0)
% Return the mass matrix `diag([Tg, 1, Tch, Trh])` of the state equation.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        I      double        % [pu] Terminal current of the parent [real; imag].
        u      double        % Inputs in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        Mass  % Mass matrix of the state equation.
    end
    Mass = diag([param(4), 1, param(10), param(11)]);
end
