function dx = fcn_dx(obj, t, x, V, u, param, omega0)
% Calculate the right side of the state equation.
%
% The state equation is `M*dx/dt = fcn_dx(...)`, with `M` from `fcn_Mass`.
% The class description gives the equations: the electrical power of the swing equation
% is the virtual power P~ = Re(V conj(I0)) of the classical current I0, before the rotation
% by `alpha` (not the power of the rotated current that enters the bus).
%
% See also fcn_Mass, Jacobi_dx
    arguments (Input)
        obj
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        dx  % Right side of the state equation in the order of `sv_x`.
    end

    D     = param(2);
    Xd    = param(3);
    Xq    = param(4);
    delta = x(1);
    omega = x(2);

    Pref  = u(1);
    Vref  = u(2);

    c_V = [1,1j]*V;
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    Id  = (Vref-Vq)/Xd;
    Iq  = Vd/Xq;
    I0  = exp(1j*delta) * (Iq - 1j*Id);
    Pv  = real(c_V*conj(I0));

    ddelta = 2 * pi * omega0 * omega;
    domega = - D*omega - Pv + Pref;

    dx  = [ddelta; domega];
end
