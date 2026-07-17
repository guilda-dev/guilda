function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q) 
    arguments
        obj 
        c_V 
        c_I 
        r_P = real(c_V*conj(c_I))
        r_Q = imag(c_V*conj(c_I))
    end

    Vabs = abs(c_V);
    Varg = angle(c_V);
        
    Xd = obj.tab_parameter.dynamics{:,'Xd'};
    Xq = obj.tab_parameter.dynamics{:,'Xq'};
    
    dst = Varg + atan(r_P/(r_Q+Vabs^2/Xq));    
    
    Id = real(  1j*c_I*exp(-1j*dst) );
    Vq = imag(  1j*c_V*exp(-1j*dst) );
    Vfd = Id*Xd+Vq;
    
    rv_Xequilibrium = dst;
    rv_Uequilibrium = [r_P;Vfd];
end