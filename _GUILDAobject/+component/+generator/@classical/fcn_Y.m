function y = fcn_Y(obj, t, x, V, I, u, param, omega0)
% Calculate the output passed to local controllers.
%
% Local controllers read the output by the names in `sv_y`.
%
% See also Jacobi_Y
    arguments (Input)
        obj
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        I      double        % [pu] Bus current as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        y % Output vector in the order of `sv_y`.
    end
    y = x(2);
end