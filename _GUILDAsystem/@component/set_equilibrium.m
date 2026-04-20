function set_equilibrium(obj,c_V,c_I,r_P,r_Q)
    arguments
        obj 
        c_V
        c_I
        r_P = real( c_V*conj(c_I) );
        r_Q = imag( c_V*conj(c_I) ); 
    end
    [cv_Xst,cv_Ust] = obj.get_equilibrium(c_V,c_I,r_P,r_Q);
    
    obj.c_Iequilibrium  = c_I;
    obj.cv_Xequilibrium = cv_Xst;
    obj.cv_Uequilibrium = cv_Ust;
    
    obj.cv_Xcurrent = cv_Xst;
    obj.cv_Ucurrent = cv_Ust;
end