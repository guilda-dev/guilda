function y  = fcn_y(obj, t, x, V, u, para, omega0)
% Return the output of the base PSS, which is always 0.
%
% Inputs are those of controller.pss.PSS1.fcn_dx; the base PSS uses none of them.
    arguments (Input)
        obj
        t      double        % [s] Time.
        x      double        % States in the order of `sv_x`.
        V      double        % [pu] Terminal voltage of the parent [real; imag].
        u      double        % Inputs in the order of `sv_u`.
        para   double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency of the network.
    end
    arguments (Output)
        y  % [pu] Stabilizing signal `Vpss` (0).
    end
    y = 0;
end
