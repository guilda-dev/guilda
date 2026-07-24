function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
    arguments
        obj 
        c_V %#ok
        c_I %#ok
        r_P = real( c_V*conj(c_I) );
        r_Q = imag( c_V*conj(c_I) ); 
    end
    obj.PQ_st       = [r_P;r_Q];
    rv_Xequilibrium = zeros(0,1);
    rv_Uequilibrium = obj.PQ_st;
end