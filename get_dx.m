function dx = get_dx(obj, a_dx_sys, a_dx_con_global,a_dx_con_local,...
    a_nx_sys, a_nx_con_global, a_nx_con_local, a_nu_sys,...
    Ymat, t, x_all, u, idx_u, idx_fault)

n_bus = numel(a_dx_sys);
n_con_global = numel(a_dx_con_global);
n_con_local = numel(a_dx_con_local);

idx_V_start = sum(a_nx_sys) + sum(a_nx_con_global) + sum(a_nx_con_local) + 1;
idx_I_start = idx_V_start + 2*n_bus;

V = x_all(idx_V_start:idx_I_start-1);
I = reshape(Ymat*V, 2, []);

V = reshape(V, 2, []);
I_fault = reshape(x_all(idx_I_start:end), 2, []);

I(:, idx_fault) = I_fault;

idx = 0;

a_x_bus = cell(n_bus, 1);
a_u_bus = cell(n_bus, 1);

for i = 1:n_bus
    nx = a_nx_sys(i);
    a_x_bus{i} = x_all(idx+(1:nx));
    idx = idx + nx;
    a_u_bus{i} = zeros(a_nu_sys(i), 1);
end

a_x_con_global = cell(n_con_global, 1);
a_x_con_local = cell(n_con_local, 1);

for i = 1:n_con_global
    nx = a_nx_con_global(i);
    a_x_con_global{i} = x_all(idx+(1:nx));
    idx = idx + nx;
end

for i = 1:n_con_local
    nx = a_nx_con_local(i);
    a_x_con_local{i} = x_all(idx+(1:nx));
    idx = idx + nx;
end

% a_x_con_global = cell(n_con_global, 1);
% 
% for i = 1:n_con_global
%     f = a_dx_con_global{i};
%     [dxkg{i}, ug_] = c.get_dx_u_func(t, xkg_cell{i}, a_x_bus(c.idx_observe), Vall(:, c.idx_observe), Iall(:, c.idx_observe), []);
%     idx = 0;
%     for i_input = c.idx_input(:)'
%         a_u_bus{i_input} = a_u_bus{i_input} + ug_(idx+(1:nu_bus(i_input)));
%         idx = idx + nu_bus(i_input);
%     end
% end
% 

dx_component = cell(n_bus, 1);
constraint = cell(n_bus, 1);
for i = 1:n_bus
    f = a_dx_sys{i};
    [dx_component{i}, constraint{i}] = f(...
        t, a_x_bus{i}, V(:, i), I(:, i), a_u_bus{i}...
        );
end


keyboard
% a_dx_con_global = cell(n_con_global, 1);
% for i = 1:n_con_global
%     c = controllers_global{i};
%     [dxkg{i}, ug_] = c.get_dx_u_func(t, xkg_cell{i}, a_x_bus(c.idx_observe), Vall(:, c.idx_observe), Iall(:, c.idx_observe), []);
%     idx = 0;
%     for i_input = c.idx_input(:)'
%         a_u_bus{i_input} = a_u_bus{i_input} + ug_(idx+(1:nu_bus(i_input)));
%         idx = idx + nu_bus(i_input);
%     end
% end
% U_global = a_u_bus;
% 
% dxk = cell(numel(controllers), 1);
% for i = 1:numel(controllers)
%     c = controllers{i};
%     
%     [dxk{i}, u_] = c.get_dx_u_func(t, xk_cell{i}, a_x_bus(c.idx_observe), Vall(:, c.idx_observe), Iall(:, c.idx_observe), U_global(c.idx_observe));
%     idx = 0;
%     for i_input = c.idx_input(:)'
%         a_u_bus{i_input} = a_u_bus{i_input} + u_(idx+(1:nu_bus(i_input)));
%         idx = idx + nu_bus(i_input);
%     end
% end
% 
% idx = 0;
% for i = idx_u(:)'
%     a_u_bus{i} = a_u_bus{i} + u(idx+(1:nu_bus(i)));
%     idx = idx + nu_bus(i);
% end
% 
% % [dx_component, constraint] = tools.arrayfun(...
% %     @(i) bus{i}.component.get_dx_con(t, x_bus{i}, Vall(:, i), Iall(:, i), U_bus{i}),...
% %     simulated_bus);
% 
% 
% dx_component = cell(numel(simulated_bus), 1);
% constraint = cell(numel(simulated_bus), 1);
% for i = 1:numel(simulated_bus)
%     idx = simulated_bus(i);
%     [dx_component{i}, constraint{i}] = bus{idx}.component.get_dx_con_func(...
%         t, a_x_bus{idx}, Vall(:, idx), Iall(:, idx), a_u_bus{idx}...
%         );
% end
% 
dx_algebraic = vertcat(constraint{:}, reshape(Vall(:, idx_fault), [], 1));

dx = [vertcat(dx_component{:});dx_algebraic];
end
