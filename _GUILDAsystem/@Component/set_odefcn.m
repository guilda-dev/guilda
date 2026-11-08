function set_odefcn(obj)
% Bind the parameters and the network frequency into the f_* function handles.
% Does nothing when they are up to date: the stale tag odefcn is empty and the network
% frequency equals r_odefcnHz. Otherwise builds them, clears odefcn and stores the
% frequency in r_odefcnHz. Called by initialize, and by get_dx_algebraic when the
% handles were never built.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    omega0 = obj.get_Hz();
    if isempty(obj.sct_stale.odefcn) && isequal(obj.r_odefcnHz, omega0)
        return    % up to date
    end
    array = obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.tab_parameter{:,obj.sv_para};

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

    obj.r_odefcnHz = omega0;
    obj.sct_stale.odefcn = strings(0,1);
end
