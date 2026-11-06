function build_odefcn(obj)
% Build the f_* handles from the gain K (initialize when they are stale, and
% get_equilibrium after the design).
% A Hz edit leaves the equilibrium up to date, so K is redesigned here when the design
% frequency differs and the equilibrium of the controller is up to date (the component,
% the parent, has rebuilt its handles first). Otherwise get_equilibrium designs K.
    arguments (Input)
        obj
    end
    omega0 = obj.get_Hz();
    if ~isempty(obj.r_designHz) && obj.r_designHz ~= omega0 && isempty(obj.sct_stale.equilibrium)
        try
            obj.design_gain(obj.a_Component.c_Vequilibrium, obj.a_Component.rv_Uequilibrium);
        catch ME
            % K stays for the old frequency: the equilibrium is stale, so the analyses ask
            % for net.initialize, which designs K again in get_equilibrium
            warning(msg("GUILDA:local_LQR:RedesignFailed", obj.s_tag, sprintf("%g", omega0), ME.message))
            obj.mark_stale("equilibrium", obj.s_tag + ": redesign failed at " + omega0 + " Hz");
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
    obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, param, omega0);
    obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, param, omega0);
    obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t, x, V, I, u, param, omega0);
    obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
    obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
    obj.r_odefcnHz = omega0;
    obj.clear_stale("odefcn");
end
