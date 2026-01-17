function [Mass, svec_x, svec_v, svec_w, svec_func_dx,  svec_func_v] = odeget(obj)
    Mass = zeros(2);
    [svec_x, svec_v, svec_w] = get_ODE_vars(obj,lscl_flagtag);

    shuntGB = [ obj.shunt(1) ;...
               -obj.shunt(2) ];
    switch config.systemFunc.get("dynamics","port_vw","Value");
        case "absV to Q/V"; V0 = 0; V2 = svec_x(2)^2;
        case "logV to Q"  ; V0 = 1; V2 = exp(2*svec_x(2));
    end

    if obj.isFault
        svec_func_dx = -svec_x + [0;V0];
    else
        svec_func_dx = -svec_w + shuntGB*V2;
    end
    svec_func_v = svec_x;
end
