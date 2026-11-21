function M  = fcn_Mass(obj, t, x, V, u, para, omega0)
% Return the empty mass matrix of the base PSS (it has no state).
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
        M  % Empty mass matrix.
    end
    M = [];
end
