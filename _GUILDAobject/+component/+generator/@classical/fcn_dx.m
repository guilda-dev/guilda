function dx = fcn_dx(obj, t, x, V, I, u, param, omega0) %#ok
           
    D  = param(2);
    Xd = param(3);
    Xq = param(4);    
        
    delta = x(1);
    omega = x(2);
    
    Pm    = u(1);
    Vfd   = u(2);

    Vdq = exp(1j*delta) * conj([1,1j]*V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    Id  = (Vfd-Vq)/Xd;
    Iq  = Vd/Xq;
    Pout = Vq*Iq + Vd*Id;

    ddelta = omega0 * omega;
    domega = - D*omega - Pout + Pm;
    
    dx  = [ddelta; domega];
end