function dx = get_dx(bus, controllers_global, controllers, Ymat,...
    nx_bus, nx_controller_global, nx_controller, nu_bus,...
    t, x_all, u, idx_u, idx_fault, simulated_bus)

n_simulated_bus = numel(simulated_bus);
n1 = sum(nx_bus(simulated_bus));
n2 = sum(nx_controller_global);
n3 = sum(nx_controller);
n4 = 2*n_simulated_bus;
n5 = 2*numel(idx_fault);

x = x_all(1:n1);
xkg = x_all(n1+(1:n2));
xk = x_all(n1+n2+(1:n3));

V = reshape(x_all(n1+n2+n3+(1:n4)), 2, []);
I_fault = reshape(x_all(n1+n2+n3+n4+(1:n5)), 2, []);

I = reshape(Ymat*V(:), 2, []);
I(:, idx_fault) = I_fault;

Vall = zeros(2, numel(bus));
Iall = zeros(2, numel(bus));

Vall(:, simulated_bus) = V;
Iall(:, simulated_bus) = I;

idx = 0;

x_bus = cell(numel(bus), 1);
U_bus = cell(numel(bus), 1);

for i = 1:n_simulated_bus
%     b = bus{itr};
    x_bus{simulated_bus(i)} = x(idx+(1:nx_bus(simulated_bus(i))));
    idx = idx + nx_bus(simulated_bus(i));
    U_bus{simulated_bus(i)} = zeros(nu_bus(simulated_bus(i)), 1);
end

xkg_cell = cell(numel(controllers_global), 1);
xk_cell = cell(numel(controllers), 1);

idx = 0;
for i = 1:numel(controllers_global)
   xkg_cell{i} = xkg(idx+(1:nx_controller_global(i)));
   idx = idx + nx_controller_global(i);
end

idx = 0;
for i = 1:numel(controllers)
   xk_cell{i} = xk(idx+(1:nx_controller(i)));
   idx = idx + nx_controller(i);
end


dxkg = cell(numel(controllers_global), 1);

%% 機器が系統から開裂された場合は、コントローラもその機器から開裂するように変更。必要があれば要修正
connected_bus = find(tools.vcellfun(@(b) b.component.is_connected_to_grid,bus));
for i = 1:numel(controllers_global)
   c = controllers_global{i};
   c_idx_observe = intersect(c.index_observe,connected_bus,'stable');
   c_idx_input   = intersect(c.index_input  ,connected_bus,'stable');
   [dxkg{i}, ug_] = c.get_dx_u_func(t, xkg_cell{i}, x_bus(c_idx_observe), Vall(:, c_idx_observe), Iall(:, c_idx_observe), []);
   idx = 0;
   for i_input = c_idx_input(:)'
       U_bus{i_input} = U_bus{i_input} + ug_(idx+(1:nu_bus(i_input)));
       idx = idx + nu_bus(i_input);
   end
end
U_global = U_bus;

dxk = cell(numel(controllers), 1);
for i = 1:numel(controllers)
   c = controllers{i};
   c_idx_observe = intersect(c.index_observe,connected_bus,'stable');
   c_idx_input   = intersect(c.index_input  ,simulated_bus,'stable');
   [dxk{i}, u_] = c.get_dx_u_func(t, xk_cell{i}, x_bus(c_idx_observe), Vall(:, c_idx_observe), Iall(:, c_idx_observe), U_global(c_idx_observe));
   idx = 0;
   for i_input = c_idx_input(:)'
       U_bus{i_input} = U_bus{i_input} + u_(idx+(1:nu_bus(i_input)));
       idx = idx + nu_bus(i_input);
   end
end

idx = 0;
for i = idx_u(:)'
   U_bus{i} = U_bus{i} + u(idx+(1:nu_bus(i)));
   idx = idx + nu_bus(i);
end

% [dx_component, constraint] = tools.arrayfun(...
%     @(i) bus{i}.component.get_dx_con(t, x_bus{i}, Vall(:, i), Iall(:, i), U_bus{i}),...
%     simulated_bus);


dx_component = cell(n_simulated_bus, 1);
constraint = cell(n_simulated_bus, 1);
for i = 1:numel(simulated_bus)
    idx = simulated_bus(i);
   [dx_component{i}, constraint{i}] = bus{idx}.component.get_dx_con_func(...
    t, x_bus{idx}, Vall(:, idx), Iall(:, idx), U_bus{idx}...   
    ); 
end

dx_algebraic = vertcat(constraint{:}, reshape(Vall(:, idx_fault), [], 1));

dx = [vertcat(dx_component{:}); vertcat(dxkg{:}); vertcat(dxk{:}); dx_algebraic];
end
