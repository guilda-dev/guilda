function [Mass, svec_x, svec_v, svec_w, svec_u, svec_y, svec_func_dx,  svec_func_w, svec_func_y] = get_ODE(obj,opt)
    arguments
        obj 
        opt.parameter (1,1) string {mustBeMember(opt.parameter,["sym","val"])};
    end

    str_mode = config.systemFunc.get("dynamics","port_vw","Value");;


    [svec_x, svec_v, svec_w, svec_u, svec_y] = get_ODE_vars(obj,true);
    if str_mode == "logV to Q"
        svec_v(2) = exp(svec_v(2));
    end


    [Mass, svec_func_dx, svec_func_PQ, svec_func_y] = get_ODE_function(obj, sscl_t, svec_x, svec_v, svec_u, opt.parameter);
    switch str_mode
        case "absV to Q/V"
            svec_func_w  = [svec_func_PQ(1);svec_func_PQ(2)/svec_v(2)];
        case "logV to Q"
            svec_func_w  =  svec_func_PQ;
    end

end
