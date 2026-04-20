function [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
    arguments
        obj 
        c_V %#ok
        c_I %#ok
        r_P = real( c_V*conj(c_I) );
        r_Q = imag( c_V*conj(c_I) ); 
    end
    obj.PQ_st       = [r_P;r_Q];
    cv_Xequilibrium = zeros(0,1);
    cv_Uequilibrium = obj.PQ_st;
end