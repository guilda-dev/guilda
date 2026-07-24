function [rv_Xequilibrium,rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q) %#ok
        
    Vabs = abs(c_V);
    Varg = angle(c_V);
            
    Xd   = para(3);
    Xq   = para(5);
    Xdp  = para(4);
    Xqp  = para(6);
    
    dst = Varg + atan(r_P/(r_Q+Vabs^2/Xq));
    wst = 0;
    
    Idq = exp(1j*dst) * conj(c_I);
    Iq  = real(Idq);
    Id  = imag(Idq);
    Vfd = Xd/Vabs * ( (r_Q+Vabs^2/Xq)*(r_Q+Vabs^2/Xd) + r_P^2 ) / sqrt( (r_Q+Vabs^2/Xq)^2 + r_P^2 );
    Est = [ -(Xd-Xdp)*Id + Vfd; ...
             (Xq-Xqp)*Iq      ];
    
    rv_Xequilibrium = [dst; wst; Est];
    rv_Uequilibrium = [r_P;Vfd];
end