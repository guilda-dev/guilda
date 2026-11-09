function [Cyx, Dyv, Dyi, Dyu] = Jacobi_Y_num(obj,r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0)
% Jacobian of fcn_Y by central differences, for a class that defines no Jacobi_Y.
%
% Called through f_JacobiY at each Jacobian evaluation of the simulation (hot path:
% class and size only).
    arguments (Input)
        obj
        r_t      (1,1) double   % [s] Time.
        rv_x     (:,1) double   % States.
        rv_V     (2,1) double   % [pu] Bus voltage [Vre; Vim].
        rv_I     (2,1) double   % [pu] Bus current [Ire; Iim].
        rv_u     (:,1) double   % Inputs.
        rr_param (1,:) double   % Dynamic parameters, in the order of sv_para.
        r_omega0 (1,1) double   % [Hz] Nominal frequency.
    end
    arguments (Output)
        Cyx double   % Derivative of fcn_Y with respect to the states x.
        Dyv double   % Derivative of fcn_Y with respect to the voltage [Vre; Vim].
        Dyi double   % Derivative of fcn_Y with respect to the current [Ire; Iim].
        Dyu double   % Derivative of fcn_Y with respect to the inputs u.
    end
    % [x; V; I; u] stacked into one vector (step 1e-5: x +- 0.5e-5)
    nx = numel(rv_x);
    J  = tools.fd_jacobian(@f, [rv_x; rv_V; rv_I; rv_u], Step=0.5e-5);

    Cyx = J(:,1:nx);
    Dyv = J(:,nx+1:nx+2);
    Dyi = J(:,nx+3:nx+4);
    Dyu = J(:,nx+5:end);

    function r = f(z)
        r = obj.fcn_Y(r_t, z(1:nx), z(nx+1:nx+2), z(nx+3:nx+4), z(nx+5:end), rr_param, r_omega0);
    end
end
