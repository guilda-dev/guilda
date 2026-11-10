function set_odefcn(obj)
% Build the f_* handles from the gain K (initialize, and get_equilibrium after the
% design, which marks them stale). Does nothing when they are up to date: the stale tag
% odefcn is empty and the network frequency equals r_odefcnHz.
% A Hz edit leaves the equilibrium up to date, so K is redesigned here when the design
% frequency differs and the equilibrium of the controller is up to date (the component,
% the parent, has rebuilt its handles first). Otherwise get_equilibrium designs K.
    arguments (Input)
        obj
    end
    omega0 = obj.get_Hz();
    if isempty(obj.sct_stale.odefcn) && isequal(obj.r_odefcnHz, omega0)
        return    % up to date
    end
    if ~isempty(obj.r_designHz) && obj.r_designHz ~= omega0 && isempty(obj.sct_stale.equilibrium)
        try
            obj.design_gain(obj.a_Component.c_Vequilibrium, obj.a_Component.rv_Uequilibrium);
        catch ME
            % K stays for the old frequency: the equilibrium is stale, so the analyses ask
            % for net.initialize, which designs K again in get_equilibrium
            show_msg("warning", "GUILDA:local_LQR:RedesignFailed", obj.s_tag, sprintf("%g", omega0), ME.message)
            obj.sct_stale.equilibrium(end+1,1) = obj.s_tag + ": redesign failed at " + omega0 + " Hz";
        end
    end

    % u = u* - K (x - x*); before net.initialize the gain is zero
    nu = numel(obj.sv_y);
    nx = numel(obj.sv_u);
    param.K  = zeros(nu, nx);
    param.x0 = zeros(nx, 1);
    param.u0 = zeros(nu, 1);
    if isequal(size(obj.K), [nu nx]) && numel(obj.rv_Uequilibrium) == nx && numel(obj.rv_u0) == nu
        param.K  = obj.K;
        param.x0 = obj.rv_Uequilibrium;
        param.u0 = obj.rv_u0;
    end
    obj.f_dx   = @(t,x,V,u) obj.fcn_dx(t, x, V, u, param, omega0);
    obj.f_Mass = @(t,x,V,u) obj.fcn_Mass(t, x, V, u, param, omega0);
    obj.f_Y    = @(t,x,V,u) obj.fcn_y(t, x, V, u, param, omega0);
    obj.f_JacobiDx = @(t,x,V,u) obj.Jacobi_dx(t,x,V,u,param,omega0);
    obj.f_JacobiY  = @(t,x,V,u) obj.Jacobi_Y(t,x,V,u,param,omega0);
    obj.r_odefcnHz = omega0;
    obj.sct_stale.odefcn = strings(0,1);
end
