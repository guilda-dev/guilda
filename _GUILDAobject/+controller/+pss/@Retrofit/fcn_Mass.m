function M = fcn_Mass(t, x, V, u, param, omega0) %#ok<INUSD>
% Mass matrix: the mass matrix E of the generator.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % Compensator states hat_x.
        V      double        % [pu] Terminal voltage of the generator [real; imag].
        u      double        % Observed states x of the generator.
        param  (1,1) struct  % Gain K, A_d, E, the equilibrium input u0 and the handles of the generator.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        M  % Mass matrix E (nx-by-nx).
    end
    M = param.E;
end
