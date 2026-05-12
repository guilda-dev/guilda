function I = fcn_I(obj, t, x, V, I ,u, param, omega0) %#ok
    
    Xd = param(3);
    Xq = param(4);
        
    delta = x(1);
    
    Vfd   = u(2);
    
    Vdq = exp(1j*delta) * conj([1,1j]*V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    Id  = (Vfd-Vq)/Xd;
    Iq  = Vd/Xq;
    Idq = Iq + 1j*Id;

    I   = exp(1j*delta) * conj(Idq);
end