function apply_edit(obj, s_target)
% Bind the parameters and the network frequency into the f_* function handles.
% check_edit calls it with "odefcn" at the start of every analysis, so the handles
% follow every edit of the parameters, the network frequency and the attachment.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        s_target (1,1) string  % What to rebuild: "odefcn" (the f_* handles).
    end
    if s_target ~= "odefcn"
        apply_edit@PowerSystemModel(obj, s_target);
        return
    end
    omega0 = obj.get_Hz();
    array = obj.para_dynamics.tab_parameter{:,obj.sv_para};

    if ismethod(obj, "Jacobi_dx")
        obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,array,omega0);
    else
        obj.f_JacobiDx = @(t,x,V,I,u) Jacobi_dx_num(obj,t,x,V,I,u,array,omega0);
    end

    if ismethod(obj, "Jacobi_I")
        obj.f_JacobiI  = @(t,x,V,I,u) obj.Jacobi_I(t,x,V,I,u,array,omega0);
    else
        obj.f_JacobiI  = @(t,x,V,I,u) Jacobi_I_num(obj,t,x,V,I,u,array,omega0);
    end

    if ismethod(obj, "Jacobi_Y")
        obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,array,omega0);
    else
        obj.f_JacobiY  = @(t,x,V,I,u) Jacobi_Y_num(obj,t,x,V,I,u,array,omega0);
    end

    obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, array, omega0);
    obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, array, omega0);
    obj.f_I    = @(t,x,V,I,u) obj.fcn_I(t, x, V, I, u, array, omega0);
    obj.f_Y    = @(t,x,V,I,u) obj.fcn_Y(t, x, V, I, u, array, omega0);
end
