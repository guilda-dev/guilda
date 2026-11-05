function set_odefcn(obj)
% Bind the parameters and the network frequency into the f_* function handles.
% Called by check_edit when the handles are not up to date (s_odefcn "unset" or
% "editted": a dynamics edit, a network Hz edit or an attach since the last build).
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    omega0 = obj.get_Hz();
    param = obj.tab_parameter.dynamics{:,obj.sv_para}.';

    obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, param, omega0);
    obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, param, omega0);
    obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t, x, V, I, u, param, omega0);

    obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
    obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
    obj.s_odefcn = "updated";
end
