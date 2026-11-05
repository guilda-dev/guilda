function dx = fcn_dx(obj,t,x,V,I,u,param,omega0)
% Calculate the right side of the state equation.
%
% The state equation is `M*dx/dt = fcn_dx(...)`, with `M` from `fcn_Mass`.
% The class description gives the equations.
%
% See also fcn_Mass, Jacobi_dx
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
        dx % Right side of the state equation in the order of `sv_x`.
    end
    % Parameter    
    D    = param(2);
    Xd   = param(3);
    Xq   = param(4);
    Xdp  = param(5);       

    % State
    delta = x(1);
    omega = x(2);
    Eq    = x(3);

    % Input
    Pm    = u(1);
    Vfd   = u(2);
    
    % dq-trans
    Vdq = exp(1j*delta) * conj([1,1j]*V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    % Current
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xq  * (Vd);
    Pout =  Vd*Id + Vq*Iq;
    
    % Diff Fcn
    ddelta = 2 * pi * omega0 *omega;
    domega = - D*omega - Pout + Pm;
    dE     = - Eq - (Xd-Xdp)*Id + Vfd;
    dx     = [ddelta; domega; dE];
end