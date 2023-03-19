function out = solve_odes(obj, t, u, idx_u, fault, x, xkg, xk, V0, I0, linear, options)

bus = obj.a_bus;
controllers_global = obj.a_controller_global;
controllers = obj.a_controller_local;

fault_time = tools.cellfun(@(c) c{1}, fault);
idx_fault = tools.cellfun(@(c) c{2}, fault);

uf = sample2f(t, u);
fault_f = idx2f(fault_time, idx_fault);
t_cand = t(:);
if iscell(fault_time)
    for i = 1:numel(fault_time)
        tf = fault_time{i};
        t_cand = [t_cand; tf(:)]; %#ok
    end
else
    t_cand = [t_cand; fault_time(:)];
end

t_cand = unique(sort(t_cand));
t_cand = t_cand(:);
% f_jacobi = {};
nx_bus = tools.vcellfun(@(b) b.get_nx, bus);
nu_bus = tools.vcellfun(@(b) b.get_nu, bus);
nx_kg = tools.vcellfun(@(c) c.get_nx, controllers_global);
nx_k = tools.vcellfun(@(c) c.get_nx, controllers);
idx_non_unit = find(tools.vcellfun(@(b) isa(b.component, 'component_empty'), bus));
idx_controller = unique(...
    tools.vcellfun(@(c) [c.index_observe(:); c.index_input(:)],...
    [controllers(:); controllers_global(:)]));

[Y, Ymat_all] = obj.get_admittance_matrix();

switch options.method
    case 'zoh'
        t_simulated = get_t_simulated(t_cand, uf, fault_f);
    case 'foh'
        t_simulated = t_cand;
end

sols = cell(numel(t_simulated)-1, 1);
reporter = tools.Reporter(t_simulated(1), t_simulated(end), options.do_report, options.OutputFcn);
out_X = cell(numel(t_simulated)-1, 1);
out_V = cell(numel(t_simulated)-1, 1);
out_I = cell(numel(t_simulated)-1, 1);
x0 = [x; xkg; xk];

if linear
    for i = 1:numel(controllers_global)
        c = controllers_global{i};
        c.get_dx_u_func = @c.get_dx_u_linear;
    end
    for i = 1:numel(controllers)
        c = controllers{i};
        c.get_dx_u_func = @c.get_dx_u_linear;
    end
    for i = 1:numel(bus)
        c = bus{i}.component;
        c.get_dx_con_func = @c.get_dx_constraint_linear;
    end
else
    for i = 1:numel(controllers_global)
        c = controllers_global{i};
        c.get_dx_u_func = @c.get_dx_u;
    end
    for i = 1:numel(controllers)
        c = controllers{i};
        c.get_dx_u_func = @c.get_dx_u;
    end
    for i = 1:numel(bus)
        c = bus{i}.component;
        c.get_dx_con_func = @c.get_dx_constraint;
    end
end

out = struct();
out.simulated_bus = cell(numel(t_simulated)-1, 1);
out.fault_bus = cell(numel(t_simulated)-1, 1);
out.Ymat_reproduce = cell(numel(t_simulated)-1, 1);

OutputEq_manager = tools.Outputeq_manager(obj);


for i = 1:numel(t_simulated)-1
    f_ = fault_f((t_simulated(i)+t_simulated(i+1))/2);
    except = unique([f_(:); idx_controller(:)]);
    simulated_bus = setdiff(1:numel(bus), setdiff(idx_non_unit, except));
    simulated_bus = simulated_bus(:);
    [~, Ymat, ~, Ymat_reproduce] = obj.reduce_admittance_matrix(Y, simulated_bus);
    out.simulated_bus{i} = simulated_bus;
    out.fault_bus{i} = f_;
    out.Ymat_reproduce{i} = Ymat_reproduce;
    idx_simulated_bus = [2*simulated_bus-1; 2*simulated_bus];
   
    idx_fault_bus = [f_(:)*2-1, f_(:)*2]';
    idx_fault_bus = idx_fault_bus(:);
    
    x = [x0; V0(idx_simulated_bus); I0(idx_fault_bus)];
    

    switch options.method
        case 'zoh'
            u_ = uf((t_simulated(i)+t_simulated(i+1))/2);
            func = @(t, x) power_network.get_dx(...
                bus, controllers_global, controllers, Ymat,...
                nx_bus, nx_kg, nx_k, nu_bus, ...
                t, x, u_, idx_u, f_, simulated_bus,...
                OutputEq_manager);
        case 'foh'
            us_ = uf(t_simulated(i));
            ue_ = uf(t_simulated(i+1));
            u_ = @(t) (ue_*(t-t_simulated(i))+us_*(t_simulated(i+1)-t))/(t_simulated(i+1)-t_simulated(i));
            func = @(t, x) power_network.get_dx(...
                bus, controllers_global, controllers, Ymat,...
                nx_bus, nx_kg, nx_k, nu_bus, ...
                t, x, u_(t), idx_u, f_, simulated_bus,...
                OutputEq_manager);
    end
    
    nx = numel(x0);
    nVI = numel(x)-nx;
    nV = nVI-numel(f_)*2;
    nI = numel(f_)*2;
    Mf = blkdiag(eye(nx), zeros(nVI));
    %       r = @(t, y, flag) false;
    %     r = @odephas2;
    t_now = datetime;
    r = @(t, y, flag) reporter.report(t, y, flag, options.reset_time, t_now);

    odeoptions = odeset('Mass',Mf, 'RelTol', options.RelTol, 'AbsTol', options.AbsTol, 'OutputFcn', r);
    sol = ode15s(func, t_simulated(i:i+1)', x, odeoptions);
    tend = t_simulated(i+1);

    while sol.x(end) < tend && (options.do_retry || ~reporter.reset)
        t_now = datetime();
        r = @(t, y, flag) reporter.report(t, y, flag, options.reset_time, t_now);
        odeoptions = odeset(odeoptions, 'OutputFcn', r);
        sol = odextend(sol, [], tend, sol.y(:,end),odeoptions);
    end
    y = sol.y(:, end);
    V = y(nx+(1:numel(idx_simulated_bus)));
    x0 = y(1:nx);
    V0 = Ymat_reproduce*V;
    I0 = Ymat_all * V0;
    sols{i} = sol;
    X = sol.y(1:nx, :)';
    V = sol.y(nx+(1:nV), :)'*Ymat_reproduce';
    I = V*Ymat_all';
    ifault = [f_(:)*2-1, f_(:)*2]';
    I(:, ifault(:)) = sol.y(nx+nV+(1:nI), :)';
    out_X{i} = X;
    out_V{i} = V;
    out_I{i} = I;
end

out.t = tools.vcellfun(@(sol) sol.x(:), sols);
X_all = vertcat(out_X{:});
V_all = vertcat(out_V{:});
I_all = vertcat(out_I{:});
out.X = cell(numel(obj.a_bus), 1);
out.V = tools.arrayfun(@(i) V_all(:, i*2-1:i*2), 1:numel(obj.a_bus));
out.I = tools.arrayfun(@(i) I_all(:, i*2-1:i*2), 1:numel(obj.a_bus));

idx = 0;
for i = 1:numel(obj.a_bus)
    out.X{i} = X_all(:, idx+(1:obj.a_bus{i}.get_nx()));
    idx = idx + obj.a_bus{i}.get_nx();
end

for i=1:numel(obj.a_controller_global)
    out.Xk_global{i} = X_all(:, idx+(1:obj.a_controller_global{i}.get_nx()));
    idx = idx + obj.a_controller_global{i}.get_nx();
end

for i=1:numel(obj.a_controller_local)
    out.Xk{i} = X_all(:, idx+(1:obj.a_controller_local{i}.get_nx()));
    idx = idx + obj.a_controller_local{i}.get_nx();
end

U_bus = tools.arrayfun(@(i) zeros(numel(out.t), bus{i}.get_nu()), 1:numel(bus));
U_bus0 = tools.arrayfun(@(i) zeros(numel(out.t), bus{i}.get_nu()), 1:numel(bus));

out.U_global = cell(numel(obj.a_controller_global), 1);

for i = 1:numel(obj.a_controller_global)
    c = obj.a_controller_global{i};
    out.U_global{i} = c.get_input_vectorized(out.t, out.Xk_global{i}, out.X(c.index_observe), out.V(c.index_observe),...
        out.I(c.index_observe), U_bus0(c.index_observe));
    
    idx = 0;
    for j = 1:numel(c.index_input)
        nu = size(U_bus{j}, 2);
        U_bus{j} = U_bus{j} + out.U_global{i}(:, idx+(1:nu));
        idx = idx + nu;
    end
end

out.U = cell(numel(obj.a_controller_local), 1);
for i = 1:numel(obj.a_controller_local)
    c = obj.a_controller_local{i};
    out.U{i} = c.get_input_vectorized(out.t, out.Xk{i}, out.X(c.index_observe), out.V(c.index_observe),...
        out.I(c.index_observe), U_bus(c.index_observe));
end

out.sols = sols;
out.linear = linear;
out.OutputEq = OutputEq_manager.export_y(out.t);

end

function t_simulated = get_t_simulated(t_cand, uf, fault_f)
has_difference = true(numel(t_cand)-1, 1);
u = nan;
f = nan;
for i = 1:numel(t_cand)-1
    unew = uf((t_cand(i)+t_cand(i+1))/2);
    fnew = fault_f((t_cand(i)+t_cand(i+1))/2);
    if any(unew~=u) || numel(f) ~= numel(fnew) || any(fnew~=f)
        u = unew;
        f = fnew;
    else
        has_difference(i) = false;
    end
end

t_simulated = t_cand([has_difference; true]);
end

