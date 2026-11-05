function y = fcn_y(t, x, V, I, u, param, omega0)
% Output equation `y = u* - K*(u - x*)`, where `u` is the observed state of the component.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        I      double        % [pu] Terminal current of the parent [real; imag].
        u      double        % Observed states `x` of the component.
        param  (1,1) struct  % Gain `K`, equilibrium state `x0` and input `u0`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        y  % Driven inputs of the component.
    end
    y = param.u0 - param.K * (u - param.x0);
end
