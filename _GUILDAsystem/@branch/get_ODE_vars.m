function [svec_x, svec_v, svec_w] = get_ODE_vars(obj,lscl_flagtag)
    arguments
        obj 
        lscl_flagtag (1,1) logical = true;
    end
    [~,svec_vfrom,svec_wfrom] = obj.network.Buses{obj.from}.get_ODE_vars(lscl_flagtag);
    [~,svec_vto  ,svec_wto  ] = obj.network.Buses{obj.to  }.get_ODE_vars(lscl_flagtag);

    svec_x = [];
    svec_v = [svec_vfrom; svec_vto];
    svec_w = [svec_wfrom; svec_wto];
end 