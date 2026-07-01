function dx = fcn_dx(obj,t,x,V,I,u,param,omega0) %#ok   

    c_V = [1,1j]*V;
        
    Xd   = param(3);
    Xdp  = param(4);
    Xq   = param(5);
    Xqp  = param(6);
    D    = param(2);
    
    delta = x(1);
    omega = x(2);
    Eq    = x(3);
    Ed    = x(4);

    Pm    = u(1);
    Vfd   = u(2);
    
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xqp  *(Vd-Ed);
    Pout =  Vd*Id + Vq*Iq;
        
    ddelta = 2*pi*omega0 *omega;
    domega = - D*omega - Pout + Pm;
    dEq    = - Eq - (Xd-Xdp)*Id + Vfd;
    dEd    = - Ed + (Xq-Xqp)*Iq;

    dx = [ddelta; domega; dEq; dEd];
end