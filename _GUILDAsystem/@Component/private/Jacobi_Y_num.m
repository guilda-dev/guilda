function [Cyx, Dyv] = Jacobi_Y_num(obj,r_t,rv_x,rv_V,rr_param,r_omega0)
% Jacobian of fcn_Y by central differences, for a class that defines no Jacobi_Y.
%
% Called through f_JacobiY at each Jacobian evaluation of the simulation (hot path:
% class and size only). The output of a component does not depend on its inputs.
    arguments (Input)
        obj
        r_t      (1,1) double   % [s] Time.
        rv_x     (:,1) double   % States.
        rv_V     (2,1) double   % [pu] Bus voltage [Vre; Vim].
        rr_param (1,:) double   % Dynamic parameters, in the order of sv_para.
        r_omega0 (1,1) double   % [Hz] Nominal frequency.
    end
    arguments (Output)
        Cyx double   % Derivative of fcn_Y with respect to the states x.
        Dyv double   % Derivative of fcn_Y with respect to the voltage [Vre; Vim].
    end
    % [x; V] stacked into one vector (step 1e-5: x +- 0.5e-5)
    nx = numel(rv_x);
    J  = tools.fd_jacobian(@f, [rv_x; rv_V], Step=0.5e-5);

    Cyx = J(:,1:nx);
    Dyv = J(:,nx+1:nx+2);

    function r = f(z)
        r = obj.fcn_Y(r_t, z(1:nx), z(nx+1:nx+2), rr_param, r_omega0);
    end
end
