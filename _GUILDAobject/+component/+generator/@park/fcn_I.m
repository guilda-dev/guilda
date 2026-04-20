function I = fcn_I(obj, t, x, V, u, para, omega0) %#ok   

    V = [1,1j]*V;
    
    Xdp  = para(4);
    Xdpp = para(5);
    Xqp  = para(7);    
    Xqpp = para(8);
    Xls  = para(13);
    
    delta = x(1);
    Eq    = x(3);
    Ed    = x(4);
    psiq  = x(5);
    psid  = x(6);
    
    Vdq = exp(1j*delta) * conj(V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    terminal_q = ( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls);
    terminal_d = ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls);
    Id  = 1/Xdpp * (terminal_q-Vq); 
    Iq  = 1/Xqpp * (Vd-terminal_d);
    Idq = Iq + 1j*Id;
    I   = exp(1j*delta) * conj(Idq);

end