function I = fcn_I(obj,t,x,V,I,u,param,omega0) %#ok
    % Parameter    
    Xdp  = param(5);
    Xq   = param(4);

    % State
    delta = x(1);
    Eq    = x(3);
    
    % dq-trans
    Vdq = exp(1j*delta) * conj([1,1j]*V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    % Current
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xq  * (Vd);
    Idq = Iq + 1j*Id;

    I = exp(1j*delta) * conj(Idq);
end