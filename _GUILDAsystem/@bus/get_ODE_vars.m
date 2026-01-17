function [svec_x, svec_v, svec_w] = get_ODE_vars(obj,lscl_flagtag)
    arguments
        obj
        lscl_flagtag (1,1) logical = true;
    end
    
    switch config.systemFunc.get("dynamics","port_vw","Value");
        case "absV to Q/V"
            str_v = ["theta";"absV"];
            str_w = ["P";"QV"];
        case "logV to Q"
            str_v = ["theta";"logV"];
            str_w = ["P";"Q"];
    end
    if lscl_flagtag
        str_v = obj.attach_tag(str_v);
        str_w = obj.attach_tag(str_w);
    end
    svec_v = sym(str_v);
    svec_w = sym(str_w);
    svec_x = svec_v;

    assume([svec_v;svec_w],"real")
end
