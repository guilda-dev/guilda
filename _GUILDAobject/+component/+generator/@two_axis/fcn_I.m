function I = fcn_I(obj,t,x,V,I,u,param,omega0) %#ok

    c_V = [1,1j]*V;
       
    Xdp  = param(4);
    Xqp  = param(6);
   
    delta = x(1);
    Eq    = x(3);
    Ed    = x(4);
    
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xqp  *(Vd-Ed);
    Idq = Iq + 1j*Id;

    I = exp(1j*delta) * conj(Idq);
end