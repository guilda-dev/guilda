function set_odefcn(obj)
% Bind the parameters and the network frequency into the f_* function handles, with
% Prate resolved as in get_equilibrium (see LocalController.set_odefcn). Does nothing
% when they are up to date; initialize marks them stale after a new equilibrium.
    arguments (Input)
        obj
    end
    omega0 = obj.get_Hz();
    if isempty(obj.sct_stale.odefcn) && isequal(obj.r_odefcnHz, omega0)
        return    % up to date
    end
    param = obj.tab_parameter.dynamics{:,obj.sv_para}.';
    param(1) = rated_power(obj);    % sv_para(1) is Prate

    obj.f_dx   = @(t,x,V,u) obj.fcn_dx(t, x, V, u, param, omega0);
    obj.f_Mass = @(t,x,V,u) obj.fcn_Mass(t, x, V, u, param, omega0);
    obj.f_Y    = @(t,x,V,u) obj.fcn_y(t, x, V, u, param, omega0);

    obj.f_JacobiDx = @(t,x,V,u) obj.Jacobi_dx(t,x,V,u,param,omega0);
    obj.f_JacobiY  = @(t,x,V,u) obj.Jacobi_Y(t,x,V,u,param,omega0);

    obj.r_odefcnHz = omega0;
    obj.sct_stale.odefcn = strings(0,1);
end
