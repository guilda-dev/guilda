function dx = get_dx(bus, controllers_global, controllers, Ymat,...
    nx_bus, nx_controller_global, nx_controller, nu_bus,...
    t, x_all, u, idx_u, idx_fault, simulated_bus, disconnected_bus, GridCode_checker, OutputEq_manager)

GridCode_checker.newline(t);

has_state_bus = union(simulated_bus,disconnected_bus,'sorted');
n_has_state_bus = numel(has_state_bus);
n1 = sum(nx_bus(has_state_bus));
n2 = sum(nx_controller_global);
n3 = sum(nx_controller);
n4 = 2*numel(simulated_bus);
n5 = 2*numel(idx_fault);
n6 = 2*numel(disconnected_bus);

x = x_all(1:n1);
xkg = x_all(n1+(1:n2));
xk = x_all(n1+n2+(1:n3));


V = reshape(x_all(n1+n2+n3+(1:n4)), 2, []);
I_fault = reshape(x_all(n1+n2+n3+n4+(1:n5)), 2, []);
V_disconnected = reshape(x_all(n1+n2+n3+n4+n5+(1:n6)), 2, []);

I = reshape(Ymat*V(:), 2, []);
GridCode_checker.report_branch(V(:))

Vall = zeros(2, numel(bus));
Iall = zeros(2, numel(bus));

Vall(:, simulated_bus) = V;
Iall(:, simulated_bus) = I;
Iall(:, idx_fault)     = I_fault;

Vall_disconnected = zeros(2, numel(bus));
Vall_disconnected(:, disconnected_bus) = V_disconnected;

idx = 0;

x_bus = cell(numel(bus), 1);
U_bus = cell(numel(bus), 1);

for i = 1:n_has_state_bus
%     b = bus{itr};
    x_bus{has_state_bus(i)} = x(idx+(1:nx_bus(has_state_bus(i))));
    idx = idx + nx_bus(has_state_bus(i));
    U_bus{has_state_bus(i)} = zeros(nu_bus(has_state_bus(i)), 1);
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
for i = 1:numel(controllers_global)
   c = controllers_global{i};
   [dxkg{i}, ug_] = c.get_dx_u_func(t, xkg_cell{i}, x_bus(c.index_observe), Vall(:, c.index_observe), Iall(:, c.index_observe), []);
   idx = 0;
   for i_input = c.index_input(:)'
       U_bus{i_input} = U_bus{i_input} + ug_(idx+(1:nu_bus(i_input)));
       idx = idx + nu_bus(i_input);
   end
end
U_global = U_bus;

dxk = cell(numel(controllers), 1);
for i = 1:numel(controllers)
   c = controllers{i};
   
   [dxk{i}, u_] = c.get_dx_u_func(t, xk_cell{i}, x_bus(c.index_observe), Vall(:, c.index_observe), Iall(:, c.index_observe), U_global(c.index_observe));
   idx = 0;
   for i_input = c.index_input(:)'
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


dx_component = cell(numel(bus), 1);
constraint_I = cell(numel(bus), 1);
constraint_V = cell(numel(bus), 1);

OutputEq_manager.new_time(t)
idx_connected = ~ismember(simulated_bus, disconnected_bus);
for i = 1:numel(simulated_bus)
    idx = simulated_bus(i);
    if idx_connected(i)
        [dx_component{idx}, constraint_I{idx}] = bus{idx}.component.get_dx_con_func(t, x_bus{idx}, Vall(:, idx), Iall(:, idx), U_bus{idx}); 
        GridCode_checker.report_component(idx,t, x_bus{idx}, Vall(:, idx), Iall(:, idx), U_bus{idx});
        OutputEq_manager.add_data(idx,t,x_bus{idx}, Vall(:, idx), Iall(:, idx), U_bus{idx});
    else
        [dx_component{idx}, constraint_V{idx}] = bus{idx}.component.get_dx_con_func(t, x_bus{idx}, Vall_disconnected(:, idx), [0;0], U_bus{idx}); 
        constraint_I{i} = Iall(:,idx);
        GridCode_checker.report_component(idx,t, x_bus{idx}, Vall_disconnected(:, idx), [0;0], U_bus{idx});
        OutputEq_manager.add_data(idx,t,x_bus{idx}, Vall_disconnected(:, idx), [0;0], U_bus{idx});
    end
end
for idx = reshape(setdiff(disconnected_bus, simulated_bus)',1,[])
    [dx_component{idx}, constraint_V{idx}] = bus{idx}.component.get_dx_con_func(t, x_bus{idx}, Vall_disconnected(:, idx), [0;0], U_bus{idx}); 
    GridCode_checker.report_component(idx,t, x_bus{idx}, Vall_disconnected(:, idx), [0;0], U_bus{idx});
    OutputEq_manager.add_data(idx,t,x_bus{idx}, Vall_disconnected(:, idx), [0;0], U_bus{idx});
end

dx_algebraic = vertcat(constraint_I{:}, reshape(Vall(:, idx_fault), [], 1), constraint_V{:});
dx = [vertcat(dx_component{:}); vertcat(dxkg{:}); vertcat(dxk{:}); dx_algebraic];

end
