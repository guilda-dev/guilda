function dx = fcn_dx(t, x, V, I, u, param, omega0)
% State equation of the controller (no state).
    arguments (Input)
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        I      double        % [pu] Terminal current of the parent [real; imag].
        u      double        % Inputs in the order of `sv_u`.
        param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        dx  % Empty state derivative (0-by-1).
    end
    dx = zeros(0,1);
end
