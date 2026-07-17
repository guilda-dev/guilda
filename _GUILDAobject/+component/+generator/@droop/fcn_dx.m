function dx = fcn_dx(obj, t, x, V, I, u, param, omega0) %#ok
              
    Xd = param(2);
    Xq = param(3);    
        
    delta = x(1);    
    
    Pm    = u(1);
    Vfd   = u(2);

    Vdq = exp(1j*delta) * conj([1,1j]*V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    Id  = (Vfd-Vq)/Xd;
    Iq  = Vd/Xq;
    Pout = Vq*Iq + Vd*Id;
    
    ddelta = - Pout + Pm;
    
    dx  = ddelta;
end