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
    fcn     = @(x,v,i,u) obj.fcn_Y(r_t, x, v, i, u, rr_param, r_omega0);
    
    % make variable
    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);
    
    % make function
    d = 1e-5;
    e = @(i,n) d/2 * ((1:n)==i).';
    
    % get linearized matrix numerically
    jacobi = zeros(ny, nx+2+2+nu);
    for i = 1:nx
        jacobi(:,i)      = fcn(rv_x+e(i,nx), rv_V       , rv_I       , rv_u        ) ...
                         - fcn(rv_x-e(i,nx), rv_V       , rv_I       , rv_u        );
    end
    for i = 1:2
        jacobi(:,nx+i)   = fcn(rv_x        , rv_V+e(i,2), rv_I       , rv_u        ) ...
                         - fcn(rv_x        , rv_V-e(i,2), rv_I       , rv_u        );
    end  
    for i = 1:2
        jacobi(:,nx+2+i) = fcn(rv_x        , rv_V       , rv_I+e(i,2), rv_u        ) ...
                         - fcn(rv_x        , rv_V       , rv_I-e(i,2), rv_u        );
    end
    for i = 1:nu
        jacobi(:,nx+4+i) = fcn(rv_x        , rv_V       , rv_I       , rv_u+e(i,nu)) ...
                         - fcn(rv_x        , rv_V       , rv_I       , rv_u-e(i,nu));
    end
    jacobi = jacobi/d;
    
    Cyx = jacobi(:,(1:nx)     );
    Dyv = jacobi(:,(1: 2)+nx  );
    Dyi = jacobi(:,(1: 2)+nx+2);
    Dyu = jacobi(:,(1:nu)+nx+4);
end
