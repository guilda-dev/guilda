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
    param = obj.tab_parameter.dynamics{:,obj.sv_para};

    obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t,x,V,I,u,param,omega0);
    obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t,x,V,I,u,param,omega0);
    obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t,x,V,I,u,param,omega0);

    obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
    obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
end
