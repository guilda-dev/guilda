function [rv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)
    arguments
        obj 
        c_V
        c_I
        r_P = real( c_V*conj(c_I) );
        r_Q = imag( c_V*conj(c_I) ); 
    end
        
    Vabs = abs(c_V);
    Varg = angle(c_V);
        
    para = obj.para_dynamics;
    Xd   = para.Xd;
    Xq   = para.Xq;
    Xdp  = para.Xd_p;
    
    dst = Varg + atan2(r_P, r_Q+Vabs^2/Xq);    

    wst = 0;

    Idq = exp(1j*dst) * conj(c_I);    
    Id  = imag(Idq);        

    Vfd = Xd/Vabs * ( (r_Q+Vabs^2/Xq)*(r_Q+Vabs^2/Xd) + r_P^2 ) / sqrt( (r_Q+Vabs^2/Xq)^2 + r_P^2 );
    Est =  -(Xd-Xdp)*Id + Vfd;
    
    rv_Xequilibrium = [dst; wst; Est];
    cv_Uequilibrium = [r_P; Vfd];
end
