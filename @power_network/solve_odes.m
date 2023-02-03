function out = solve_odes(obj, t, u, idx_u, fault, x, xkg, xk, V0, I0, linear, options)

bus = obj.a_bus;
branch = obj.a_branch;
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

switch options.method
    case 'zoh'
        t_simulated = get_t_simulated(t_cand, uf, fault_f);
    case 'foh'
        t_simulated = t_cand;
end

reporter = tools.Reporter(t_simulated(1), t_simulated(end), options.do_report, options.OutputFcn);

x0 = [x; xkg; xk];


logical_connected_comp = tools.vcellfun(@(b) b.component.is_connected_to_grid,bus);
logical_connected_br = tools.vcellfun(@(br) br.is_connected,branch);

% 機器および解析条件に応じて、状態方程式/出力方程式をセットする。
if options.with_grid_code
    logical_grid_code_comp = ~ tools.hcellfun(@(b) ...
           isnan(b.component.grid_code(0,b.component.x_equilibrium,b.component.V_equilibrium,b.component.I_equilibrium,zeros(b.component.get_nu,1))) ...
        && isnan(b.component.restoration(0,b.component.x_equilibrium,b.component.V_equilibrium,b.component.I_equilibrium,zeros(b.component.get_nu,1))),bus);
    logical_grid_code_br   = ~ tools.hcellfun(@(br) isnan(br.grid_code([1.1;1.1],[1;1])) ,branch);
else
    logical_grid_code_comp = false(1,numel(bus));
    logical_grid_code_br   = false(1,numel(branch)); 
end


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
        if logical_grid_code_comp(i)
            c.get_dx_con_func = @c.get_dx_constraint_linear_with_condition;
        else
            if c.is_connected_to_grid
                c.get_dx_con_func = @c.get_dx_constraint_linear;
            else
                c.get_dx_con_func = @c.get_dx_constraint_linear_disconnected;
            end
        end
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
        if logical_grid_code_comp(i)
            c.get_dx_con_func = @c.get_dx_constraint_with_condition;
        else
            if c.is_connected_to_grid
                c.get_dx_con_func = @c.get_dx_constraint;
            else
                c.get_dx_con_func = @c.get_dx_constraint_disconnected;
            end
        end
    end
end


% 以下に条件設定よりcell配列をサイズを決めて定義しているが,数値積分中にgrid codeの違反がある場合はその都度拡張される。
sols = cell(numel(t_simulated)-1, 1);
out_X = cell(numel(t_simulated)-1, 1);
out_V = cell(numel(t_simulated)-1, 1);
out_I = cell(numel(t_simulated)-1, 1);
connected_component = cell(numel(t_simulated)-1, 1);
connected_branch    = cell(numel(t_simulated)-1, 1);

out = struct();
out.simulated_bus = cell(numel(t_simulated)-1, 1);
out.fault_bus = cell(numel(t_simulated)-1, 1);
out.Ymat_reproduce = cell(numel(t_simulated)-1, 1);

i = 1;
br_from_to = tools.vcellfun(@(br) [br.from,br.to], branch);

tic
while numel(t_simulated) > 1
    f_ = fault_f((t_simulated(1)+t_simulated(2))/2);
    except = unique([f_(:); idx_controller(:)]);
    simulated_bus = setdiff(1:numel(bus), setdiff(idx_non_unit, except));
    simulated_bus = simulated_bus(:);
    [Y, Ymat_all] = obj.get_admittance_matrix(1:numel(obj.a_bus),find(logical_connected_br));
    [~, Ymat, ~, Ymat_reproduce] = obj.reduce_admittance_matrix(Y, simulated_bus);
    out.simulated_bus{i} = simulated_bus;
    out.fault_bus{i} = f_;
    out.Ymat_reproduce{i} = Ymat_reproduce;
    idx_simulated_bus = [2*simulated_bus-1; 2*simulated_bus];
   
    idx_fault_bus = [f_(:)*2-1, f_(:)*2]';
    idx_fault_bus = idx_fault_bus(:);
    
    x = [x0; I0(idx_simulated_bus); V0(idx_fault_bus)];
    

    switch options.method
        case 'zoh'
            u_ = uf((t_simulated(1)+t_simulated(2))/2);
            func = @(t, x) power_network.get_dx(...
                bus, controllers_global, controllers, Ymat,...
                nx_bus, nx_kg, nx_k, nu_bus, ...
                t, x, u_, idx_u, f_, simulated_bus...
                );
        case 'foh'
            %%%%%%% 入力に問題あり！%%%%%%%
            us_ = uf(t_simulated(1));
            ue_ = uf(t_simulated(2));
            u_ = @(t) (ue_*(t-t_simulated(1))+us_*(t_simulated(2)-t))/(t_simulated(2)-t_simulated(1));
            func = @(t, x) power_network.get_dx(...
                bus, controllers_global, controllers, Ymat,...
                nx_bus, nx_kg, nx_k, nu_bus, ...
                t, x, u_(t), idx_u, f_, simulated_bus...
                );
    end
    
    nx = numel(x0);
    nVI = numel(x)-nx;
    nV = nVI-numel(f_)*2;
    nI = numel(f_)*2;
    Mf = blkdiag(eye(nx), zeros(nVI));
    %     r = @(t, y, flag) false;
    %     r = @odephas2;
    t_now = datetime;
    r = @(t, y, flag) reporter.report(t, y, flag, options.reset_time, t_now);

    idx_check_br = find(logical_grid_code_br(:) & logical_connected_br(:));
    EventsFcn = @(t,y) check_grid_code_on_branch(t, y, ...
                                               nx+(1:numel(idx_simulated_bus)), ...
                                               idx_check_br, numel(idx_check_br),...
                                               br_from_to, Ymat_reproduce, branch, ...
                                               find(logical_grid_code_comp), sum(logical_grid_code_comp), bus);

    odeoptions = odeset('Mass',Mf, 'RelTol', options.RelTol, 'AbsTol', options.AbsTol, 'OutputFcn', r, 'Events',EventsFcn);
    sol = ode15s(func, t_simulated(1:2)', x, odeoptions);
    tend = t_simulated(2);

    while sol.x(end) < tend && (options.do_retry || ~reporter.reset) && ~ismember('ie',fieldnames(sol))
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
    
    connected_component{i} = false(numel(sol.x),numel(obj.a_bus));
    connected_component{i}(:,logical_connected_comp) = true;
    connected_branch{i}  = false(numel(sol.x),numel(branch));
    connected_branch{i}(:,idx_check_br) = true;
    
    time_next_step =true;
    if ismember('ie',fieldnames(sol))
        if ~isempty(sol.ie) && numel(sol.ie)>0  
        connected_component{i}(:,logical_grid_code_comp) = sol.ye(numel(idx_check_br)+1:end-1,:).';
        idx_disconnected_branch = idx_check_br(sol.ie(sol.ie<numel(idx_check_br)));
        logical_connected_br(idx_disconnected_branch) = false;
        time_next_step = false;
        end
    end

    
    if time_next_step
        t_simulated = t_simulated(2:end);
    else
        t_simulated(1) = sol.te;
    end
    i = i+1;

end
toc

out.t = tools.vcellfun(@(sol) sol.x(:), sols);
X_all = vertcat(out_X{:});
V_all = vertcat(out_V{:});
I_all = vertcat(out_I{:});
out.X = cell(numel(obj.a_bus), 1);
out.V = tools.arrayfun(@(i) V_all(:, i*2-1:i*2), 1:numel(obj.a_bus));
out.I = tools.arrayfun(@(i) I_all(:, i*2-1:i*2), 1:numel(obj.a_bus));

out.idx_connected.component = vertcat(connected_component{:});
out.idx_connected.branch    = vertcat(connected_branch{:});

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

function [value,isterminal,direction] = check_grid_code_on_branch(~, y, idxV, idx_br, nbr, from_to, Ymat_reproduce, branch, idx_comp, ncomp, bus)
    V = Ymat_reproduce*y(idxV);
    val_br      = tools.varrayfun(@(i) branch{i}.grid_code(V(2*from_to(i,1)+[-1,0]),V(2*from_to(i,2)+[-1,0])),idx_br);
    val_comp    = tools.varrayfun(@(i) bus{i}.component.is_connected_to_grid, idx_comp);
    value       = [val_br;val_comp;0];
    isterminal  = [ones(nbr,1); zeros(ncomp+1,1)];
    direction   = [];
end