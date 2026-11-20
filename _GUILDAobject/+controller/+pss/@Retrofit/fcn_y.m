function y = fcn_y(t, x, V, u, param, omega0) %#ok<INUSD>
% Output equation `Vpss = -K (x - hat_x)`.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % Compensator states hat_x.
        V      double        % [pu] Terminal voltage of the generator [real; imag].
        u      double        % Observed states x of the generator.
        param  (1,1) struct  % Gain K, A_d, E, the equilibrium input u0 and the handles of the generator.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        y  % [pu] Vpss, the Vpss input of the AVR.
    end
    y = -param.K * (u - x);
end
