function [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
    arguments
        obj 
        c_V 
        c_I 
        r_P = real(c_V*conj(c_I)) %#ok
        r_Q = real(c_V*conj(c_I)) %#ok
    end
    
    obj.Z = -c_V/c_I;
    cv_Xequilibrium = zeros(0,1);
    cv_Uequilibrium = [real(obj.Z); imag(obj.Z)];
end