function [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0)
% Calculate the Jacobians of the state equation.
%
% Analytic derivatives of `fcn_dx` at the given point, used for linearization. The power
% of the swing equation is the virtual power P~ = Vre*I0re + Vim*I0im with the classical
% current I0 = e^{-j alpha} I, so its derivatives come from those of the bus current
% (`Jacobi_I`) rotated back by `alpha`.
%
% See also fcn_dx, Jacobi_I
    arguments (Input)
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        Axx  % Jacobian of `fcn_dx` with respect to `x`.
        Bxv  % Jacobian of `fcn_dx` with respect to `V` `[real; imag]`.
        Bxu  % Jacobian of `fcn_dx` with respect to `u`.
    end
    delta = x(1);
    Vref  = u(2);
    D     = param(2);
    Xd    = param(3);
    Xq    = param(4);
    alpha = param(5);

    Vd  = V(1)*sin(delta) - V(2)*cos(delta);
    Vq  = V(1)*cos(delta) + V(2)*sin(delta);
    c_I0 = exp(1j*delta) * (Vd/Xq - 1j*(Vref-Vq)/Xd);
    rv_I0 = [real(c_I0), imag(c_I0)];

    % Jacobians of I0 = e^{-j alpha} I: the bus-current Jacobians rotated back by alpha
    [Cix, Div, Diu] = component.GFMInverter.VSG_classical.Jacobi_I(t,x,V,u,param,omega0);
    Rot_b = [cos(alpha), sin(alpha); -sin(alpha), cos(alpha)];
    rv_V = reshape(V, 1, 2)*Rot_b;
    dP_dx = rv_V*Cix;
    dP_dV = rv_I0 + rv_V*Div;
    dP_du = rv_V*Diu;

    Axx = [0, 2*pi*omega0; -dP_dx(1), -D - dP_dx(2)];
    Bxv = [zeros(1,2); -dP_dV];
    Bxu = [zeros(1,2); [1, 0] - dP_du];
end
