function y = fcn_y(t, x, V, I, u, param, omega0)
% Return the output `Pmech = Prate*(Kw*Pw + Kv*Psv)` [pu on the system base].
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
        y  % Outputs in the order of `sv_y`.
    end
    y = param(1)*(param(13)*x(4) + param(14)*x(3));
end
