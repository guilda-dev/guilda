function rvec_dx = fcn_dx(obj, t, x, V, I, u, para, omega0) %#ok

    V = [1,1j]*V;
     
    D    = para(2);
    Xd   = para(3);
    Xdp  = para(4);
    Xdpp = para(5);
    Xq   = para(6);
    Xqp  = para(7);    
    Xqpp = para(8);
    Xls  = para(13);    
    
    % State
    delta = x(1);
    omega = x(2);
    Eq    = x(3);
    Ed    = x(4);
    psiq  = x(5);
    psid  = x(6);
    
    % Input
    Pm    = u(1);
    Vfd   = u(2);
    
    % dq-trans
    Vdq = exp(1j*delta) * conj(V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    % Current    
    Id  = 1/Xdpp * (( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls) - Vq); 
    Iq  = 1/Xqpp * (Vd - ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls));
    Pout =  Vd*Id + Vq*Iq;
    
    % Diff Fcn    
    dpsiq  = -psiq -Ed -(Xqp-Xls)*Iq;
    dpsid  = -psid +Eq -(Xdp-Xls)*Id;    
    
    rvec_dx = [                                       2 * pi * omega0 *omega; 
                                                       - D*omega - Pout + Pm;                
                - Eq - (Xd-Xdp)*( Id + (Xdp-Xdpp)/(Xdp-Xls)^2 * dpsid) + Vfd; 
                      - Ed + (Xq-Xqp)*( Iq + (Xqp-Xqpp)/(Xqp-Xls)^2 * dpsiq); 
                                                                       dpsiq;
                                                                       dpsid];

end
