function y = fcn_Y(obj,t,x,V,param,omega0)
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
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        y  % Output vector in the order of `sv_y`: `[omega; Ifield]`.
    end
    % Ifield (textbook (5.30)): the field current, Vfield minus the right-hand side of the Eq equation
    Xd    = param(3);
    Xdp   = param(4);
    delta = x(1);
    Eq    = x(3);
    Vq    = V(1)*cos(delta) + V(2)*sin(delta);
    Id    = (Eq - Vq)/Xdp;
    y = [x(2); Eq + (Xd - Xdp)*Id];
end