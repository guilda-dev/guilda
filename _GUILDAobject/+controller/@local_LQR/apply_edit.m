function apply_edit(obj, s_target)
% Build the f_* handles from the gain K ("odefcn"; check_edit calls it at the start of
% every analysis, and get_equilibrium after the design).
% A Hz edit keeps the equilibrium, so K is redesigned here, at the first analysis
% after the edit when the design frequency differs (check_edit has already built the
% component, the parent). When the equilibrium is not up to date, net.initialize
% redesigns K instead.
    arguments (Input)
        obj
        s_target (1,1) string  % What to rebuild: "odefcn" (the f_* handles).
    end
    if s_target ~= "odefcn"
        apply_edit@LocalController(obj, s_target);
        return
    end
    omega0 = obj.get_Hz();
    if ~isempty(obj.r_designHz) && obj.r_designHz ~= omega0 && obj.equilibrium_valid()
        try
            obj.design_gain(obj.a_Component.c_Vequilibrium, obj.a_Component.rv_Uequilibrium);
        catch ME
            % A warning, not an error: check_edit goes on to build the other layers.
            % K stays for the old frequency, so the record makes the equilibrium stale
            % and the analysis that runs check_edit asks for net.initialize.
            warning(msg("GUILDA:local_LQR:RedesignFailed", obj.s_tag, sprintf("%g", omega0), ME.message))
            obj.log_edit(obj.s_tag + " redesign failed", "Parameter(dynamics)");
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
end
