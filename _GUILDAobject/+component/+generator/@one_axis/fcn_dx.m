function dx = fcn_dx(obj, t, x, V, u, param, omega0) %#ok
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