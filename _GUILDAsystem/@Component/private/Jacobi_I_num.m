function [Cix, Div, Diu] = Jacobi_I_num(obj,r_t,rv_x,rv_V,rv_u,rr_param,r_omega0)
% Jacobian of fcn_I by central differences, for a class that defines no Jacobi_I.
%
% Called through f_JacobiI at each Jacobian evaluation of the simulation (hot path:
% class and size only).
    arguments (Input)
        obj
        r_t      (1,1) double   % [s] Time.
        rv_x     (:,1) double   % States.
        rv_V     (2,1) double   % [pu] Bus voltage [Vre; Vim].
        rv_u     (:,1) double   % Inputs.
        rr_param (1,:) double   % Dynamic parameters, in the order of sv_para.
        r_omega0 (1,1) double   % [Hz] Nominal frequency.
    end
    arguments (Output)
        Cix double   % Derivative of fcn_I ([Ire; Iim]) with respect to the states x.
        Div double   % Derivative of fcn_I ([Ire; Iim]) with respect to the voltage [Vre; Vim].
        Diu double   % Derivative of fcn_I ([Ire; Iim]) with respect to the inputs u.
    end
    % [x; V; u] stacked into one vector (step 1e-5: x +- 0.5e-5)
    nx = numel(rv_x);
    J  = tools.fd_jacobian(@f, [rv_x; rv_V; rv_u], Step=0.5e-5);

    Cix = J(:,1:nx);
    Div = J(:,nx+1:nx+2);
    Diu = J(:,nx+3:end);

    function r = f(z)
        c_I = obj.fcn_I(r_t, z(1:nx), z(nx+1:nx+2), z(nx+3:end), rr_param, r_omega0);
        r = [real(c_I); imag(c_I)];
    end
end
