function [Mass, svec_x, svec_v, svec_w, svec_func_dx,  svec_func_w] = get_ODE(obj)
    Mass = zeros(0);
    [svec_x, svec_v, svec_w] = get_ODE_vars(obj,lscl_flagtag);
    svec_func_dx = [];

    
    if ~obj.isConnected
        svec_func_w = [0;0];
        return
    end


    thetaj = svec_v([1;3]) * 1j;
    V      = svec_v([2;4]);
    Y      = obj.get_admittance_matrix;
   
    switch config.systemFunc.get("dynamics","port_vw","Value");
        case "absV to Q/V"
            Vvec   = exp(thetaj) .* V;
            Qtimes = 1./svec_v([2;4]); 
        case "logV to Q"  
            Vvec   = exp(thetaj  +  V );
            Qtimes = [1;1];
    end
    PQ = Vvec .* conj(Y*Vvec);
    PQ = simplify( [ real(PQ), imag(PQ).*Qtimes].' );

    svec_func_w = PQ(:);
end
