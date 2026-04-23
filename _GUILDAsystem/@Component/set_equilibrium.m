function set_equilibrium(obj,c_V,c_I,r_P,r_Q)
    arguments
        obj 
        c_V
        c_I
        r_P = real( c_V*conj(c_I) );
        r_Q = imag( c_V*conj(c_I) ); 
    end
    [cv_Xst,cv_Ust] = obj.get_equilibrium(c_V,c_I,r_P,r_Q);
    
    obj.c_Vequilibrium  = c_V;
    obj.c_Iequilibrium  = c_I;
    obj.cv_Xequilibrium = cv_Xst;
    obj.cv_Uequilibrium = cv_Ust;
    
    obj.cv_Xcurrent = cv_Xst;
    obj.cv_Ucurrent = cv_Ust;

    if ~isempty(obj.a_LocalController)
        obj.a_LocalController.get_equilibrium(c_V,cv_Ust);
    end
end