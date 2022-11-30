function out_new = resample(obj, out_, t)

t = sort(t);
nxx = sum(tools.vcellfun(@(b) b.component.get_nx(), obj.a_bus));
nxk = sum(tools.vcellfun(@(c) c.get_nx(), obj.a_controller_local));
nxkg = sum(tools.vcellfun(@(c) c.get_nx(), obj.a_controller_global));

nx = nxx + nxk + nxkg;

T = cell(numel(out_.sols), 1);
X = cell(numel(out_.sols), 1);
V = cell(numel(out_.sols), 1);
I = cell(numel(out_.sols), 1);

[~, Ymat_all] = obj.get_admittance_matrix();

for k = 1:numel(out_.sols)
    idx = out_.sols{k}.x(1) <= t & out_.sols{k}.x(end) >= t;
    ti = t(idx);
    if numel(ti) > 0
        out_mat = deval(out_.sols{k}, ti);
    end
    X{k} = out_mat(1:nx, :)';
    T{k} = ti;
    nV = 2*numel(out_.simulated_bus{k});
    nI = 2*numel(out_.fault_bus{k});
    vk = out_mat(nx+(1:nV), :)';
    ik = out_mat(nx+nV+(1:nI), :)';
    Vall = vk*out_.Ymat_reproduce{k}';
    Iall = Vall * Ymat_all';
    f_ = out_.fault_bus{k};
    idx_fault = [f_(:)*2-1, f_(:)*2]';
    Iall(:, idx_fault) = ik;
    V{k} = Vall;
    I{k} = Iall;
end

out_new = out_;
sols = out_.sols;
bus = obj.a_bus;
controller_global = obj.a_controller_global;
controller_local = obj.a_controller_local;

if out_.linear
    for i = 1:numel(controller_global)
        c = controller_global{i};
        c.get_dx_u_func = @c.get_dx_u_linear;
    end
    for i = 1:numel(controller_local)
        c = controller_local{i};
        c.get_dx_u_func = @c.get_dx_u_linear;
    end
else
    for i = 1:numel(controller_global)
        c = controller_global{i};
        c.get_dx_u_func = @c.get_dx_u;
    end
    for i = 1:numel(controller_local)
        c = controller_local{i};
        c.get_dx_u_func = @c.get_dx_u;
    end
end

for k = 1:numel(out_.sols)-1
    if T{k}(end) == T{k+1}(1)
        X{k}(end, :) = (X{k}(end, :) + X{k+1}(1, :))/2;
        V{k}(end, :) = (V{k}(end, :) + V{k+1}(1, :))/2;
        I{k}(end, :) = (I{k}(end, :) + I{k+1}(1, :))/2;
        T{k+1}(1) = [];
        X{k+1}(1, :) = [];
        V{k+1}(1, :) = [];
        I{k+1}(1, :) = [];
    end
end


out_new.t = t;
X_all = vertcat(X{:});
V_all = vertcat(V{:});
I_all = vertcat(I{:});
out_new.X = cell(numel(obj.a_bus), 1);
out_new.V = tools.arrayfun(@(i) V_all(:, i*2-1:i*2), 1:numel(obj.a_bus));
out_new.I = tools.arrayfun(@(i) I_all(:, i*2-1:i*2), 1:numel(obj.a_bus));

out_new.Xk_global = cell(numel(obj.a_controller_global), 1);
out_new.Xk = cell(numel(obj.a_controller_local), 1);

idx = 0;
for i = 1:numel(obj.a_bus)
    out_new.X{i} = X_all(:, idx+(1:obj.a_bus{i}.get_nx()));
    idx = idx + obj.a_bus{i}.get_nx();
end

for i=1:numel(obj.a_controller_global)
    out_new.Xk_global{i} = X_all(:, idx+(1:obj.a_controller_global{i}.get_nx()));
    idx = idx + obj.a_controller_global{i}.get_nx();
end

for i=1:numel(obj.a_controller_local)
    out_new.Xk{i} = X_all(:, idx+(1:obj.a_controller_local{i}.get_nx()));
    idx = idx + obj.a_controller_local{i}.get_nx();
end

U_bus = tools.arrayfun(@(i) zeros(numel(out_new.t), bus{i}.get_nu()), 1:numel(bus));
U_bus0 = tools.arrayfun(@(i) zeros(numel(out_new.t), bus{i}.get_nu()), 1:numel(bus));

out_new.U_global = cell(numel(obj.a_controller_global), 1);

for i = 1:numel(obj.a_controller_global)
    c = obj.a_controller_global{i};
    out_new.U_global{i} = c.get_input_vectorized(out_new.t, out_new.Xk_global{i}, out_new.X(c.index_observe), out_new.V(c.index_observe),...
        out_new.I(c.index_observe), U_bus0(c.index_observe));
    
    idx = 0;
    for j = 1:numel(c.index_input)
        nu = size(U_bus{j}, 2);
        U_bus{j} = U_bus{j} + out_new.U_global{i}(:, idx+(1:nu));
        idx = idx + nu;
    end
end

out_new.U = cell(numel(obj.a_controller_local), 1);
for i = 1:numel(obj.a_controller_local)
    c = obj.a_controller_local{i};
    out_new.U{i} = c.get_input_vectorized(out_new.t, out_new.Xk{i}, out_new.X(c.index_observe), out_new.V(c.index_observe),...
        out_new.I(c.index_observe), U_bus(c.index_observe));
end

out_new.Vc = tools.hcellfun(@(v) v(:, 1) + 1j*v(:, 2), out_new.V);
end