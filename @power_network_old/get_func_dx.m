function a_func_dx = get_func_dx(obj, t, u, idx_u, fault, options)

n_bus = numel(obj.a_bus);

idx_bus_empty = find(tools.vcellfun(@(b) isa(b.component, 'component_empty'), obj.a_bus));
idx_bus_component = setdiff(1:n_bus, idx_bus_empty);
idx_controller = unique(...
    tools.vcellfun(@(c) [c.idx_observe(:); c.idx_input(:)],...
    [obj.a_controller_global; obj.a_controller_local]));
idx_require = union(idx_bus_component, idx_controller, 'sorted');

Y = obj.get_admittance_matrix();

if options.linear
else
    a_dx_con_global = tools.cellfun(@(c) @(varargin) c.get_dx_constraint(varargin{:}), obj.a_controller_global);
    a_dx_con_local = tools.cellfun(@(c) @(varargin) c.get_dx_constraint(varargin{:}), obj.a_controller_local);
end
a_nx_con_global = tools.vcellfun(@(c) @(varargin) c.get_nx(), obj.a_controller_global);
a_nx_con_local = tools.vcellfun(@(c) @(varargin) c.get_nx(), obj.a_controller_local);

a_func_dx = cell(numel(t)-1, 1);
for k = 1:numel(t)-1
    if strcmp(options.method, 'zoh')
        uk = u(k);
        func_u = @(t) u;
    else
        uk = u(k);
        uk1 = u(k + 1);
        tk = t(k);
        tk1 = t(k+1);
        func_u = @(t) (uk*(tk1-t)+uk1*(t-tk))/(tk1-tk);
    end
    
    is_simulated = union(idx_require, fault{k}, 'sorted');
    [~, Ymat_reduced, ~, Amat_reproduce] = obj.reduce_admittance_matrix(Y, is_simulated);
    if options.linear
        a_dx_sys = tools.cellfun(@(b) @(varargin) b.component.get_dx_constraint_linear(varargin{:}), obj.a_bus(is_simulated));
    else
        a_dx_sys = tools.cellfun(@(b) @(varargin) b.component.get_dx_constraint(varargin{:}), obj.a_bus(is_simulated));
    end
    a_nx_sys = tools.vcellfun(@(b) b.component.get_nx(), obj.a_bus(is_simulated));
    a_nu_sys = tools.vcellfun(@(b) b.component.get_nu(), obj.a_bus(is_simulated));
    S = struct();
    S.linear = options.linear;
    S.is_simulated = is_simulated;
    fault_k = fault{k};
    S.fault = fault_k;
    S.A_reproduce = Amat_reproduce;
    S.func_dx = @(t, x) obj.get_dx(a_dx_sys, a_dx_con_global,a_dx_con_local,...
        a_nx_sys, a_nx_con_global, a_nx_con_local, a_nu_sys,...
        Ymat_reduced, t, x, func_u, idx_u, fault_k);
    a_func_dx{k} = S;
end

end
