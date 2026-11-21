function set_odefcn(obj)
% Design K and build the f_* handles (initialize). Does nothing when they are up to
% date: the stale tag odefcn is empty and the network frequency equals r_odefcnHz.
%
% The handles bind the handles f_dx and f_JacobiDx of the generator, which the generator
% (the component above) rebuilds first, so a network Hz edit rebuilds them here too.
% When the equilibrium of the controller is up to date, K is designed at the equilibrium
% of the generator (also after a Hz edit, which keeps the equilibrium). Otherwise the
% gain and A_d are zero until net.initialize.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    omega0 = obj.get_Hz();
    if isempty(obj.sct_stale.odefcn) && isequal(obj.r_odefcnHz, omega0)
        return    % up to date
    end
    comp = obj.observed_component();
    nx = numel(comp.sv_x);
    nu = numel(comp.sv_u);
    x0 = comp.rv_Xequilibrium;
    u0 = comp.rv_Uequilibrium;
    if isempty(obj.sct_stale.equilibrium) && numel(x0) == nx && numel(u0) == nu
        % Design model: the generator alone, V and u fixed at the equilibrium
        V0  = comp.c_Vequilibrium;
        lin = comp.get_linear_matrix(x0, [real(V0); imag(V0)], u0);
        A_d = lin.A;
        E   = lin.E;
        B   = lin.B(:, 2 + find(comp.sv_u == "Vfield", 1));
        if rank(E) < nx
            error(msg("GUILDA:Retrofit:SingularMass", obj.s_tag, comp.s_tag))
        end
        Qw = obj.Q;  if isempty(Qw); Qw = eye(nx); end
        Rw = obj.R;  if isempty(Rw); Rw = 1; end
        if ~isequal(size(Qw), [nx nx]) || ~isequal(size(Rw), [1 1])
            error(msg("GUILDA:Retrofit:WeightSize", obj.s_tag, string(nx), string(nx), join(comp.sv_x, ",")))
        end
        obj.K = lqr(E\A_d, E\B, Qw, Rw);
        obj.sys_design = ss(E\A_d, E\B, eye(nx), 0, 'StateName', cellstr(comp.sv_x), ...
                            'InputName', {'Vfield'}, 'OutputName', cellstr(comp.sv_x));
        param.K = obj.K;
    else
        % before net.initialize: no gain
        A_d = zeros(nx);
        E   = comp.f_Mass(0, zeros(nx,1), [0;0], zeros(nu,1));
        param.K = zeros(1, nx);
        if numel(u0) ~= nu
            u0 = zeros(nu,1);
        end
    end
    param.u0 = u0;
    param.A  = A_d;
    param.E  = E;
    param.f_dx       = comp.f_dx;
    param.f_JacobiDx = comp.f_JacobiDx;

    obj.f_dx   = @(t,x,V,u) obj.fcn_dx(t, x, V, u, param, omega0);
    obj.f_Mass = @(t,x,V,u) obj.fcn_Mass(t, x, V, u, param, omega0);
    obj.f_Y    = @(t,x,V,u) obj.fcn_y(t, x, V, u, param, omega0);
    obj.f_JacobiDx = @(t,x,V,u) obj.Jacobi_dx(t,x,V,u,param,omega0);
    obj.f_JacobiY  = @(t,x,V,u) obj.Jacobi_Y(t,x,V,u,param,omega0);
    obj.r_odefcnHz = omega0;
    obj.sct_stale.odefcn = strings(0,1);
end
