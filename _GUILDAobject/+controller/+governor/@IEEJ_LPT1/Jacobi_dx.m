function [Axx,Bxv,Bxu] = Jacobi_dx(t, x, V, u, param, omega0)
% Return the Jacobians of fcn_dx on the active branch of the gate and the limits.
    arguments (Input)
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        u      double        % Inputs in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        Axx  % Jacobian of `fcn_dx` with respect to `x`.
        Bxv  % Jacobian of `fcn_dx` with respect to `V` `[real; imag]`.
        Bxu  % Jacobian of `fcn_dx` with respect to `u`.
    end
    [~, r_slope, l_ref] = rate(x, u, param);
    Axx = [-1,             0,        0,  0;
           -r_slope*l_ref, -r_slope, 0,  0;
            0,             1,       -1,  0;
            0,             0,        1, -1];
    Bxv = zeros(4,2);
    Bxu = [100/param(3), 0,             0;
           0,            r_slope*l_ref, r_slope*~l_ref;
           0,            0,             0;
           0,            0,             0];
end
