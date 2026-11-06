function build_odefcn(obj)
% Bind the parameters and the network frequency into the f_* function handles.
% Called by initialize when the stale tag odefcn is not empty or the network frequency
% differs from r_odefcnHz. Clears odefcn and stores the frequency in r_odefcnHz.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    omega0 = obj.get_Hz();
    param = obj.tab_parameter.dynamics{:,obj.sv_para};

    obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t,x,V,I,u,param,omega0);
    obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t,x,V,I,u,param,omega0);
    obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t,x,V,I,u,param,omega0);

    obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
    obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);

    obj.r_odefcnHz = omega0;
    obj.sct_stale.odefcn = strings(0,1);
end
