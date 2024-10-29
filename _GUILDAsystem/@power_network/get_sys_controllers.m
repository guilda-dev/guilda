function sys = get_sys_controllers(obj, controllers, controllers_global)
obj.check_EditLog("controller")

sys_global = get_sys_controllers_(obj, controllers_global, '_global');
sys_local = get_sys_controllers_(obj, controllers, '');

[nu, nx] = size(sys_local('u', {'x', 'V', 'I'}));
ny_local = size(sys_local, 1);
ny_global = size(sys_global, 1);

sys1 = [eye(nx), zeros(nx, nu); sys_global];

I_ss = ss(eye(ny_global));
I_ss.OutputGroup = sys_global.OutputGroup;
I_ss = I_ss(nu+1:end, nu+1:end);

sys2 = blkdiag(sys_local + ss([zeros(ny_local, nx), eye(ny_local, nu)]), ...
    I_ss);

sys = series(sys1, sys2);
% sys = sys(:, 'x');

nx_local = order(sys_local);
nx_global = order(sys_global);

sys = xperm(sys, [nx_local+(1:nx_global), 1:nx_local]');

sys = sys(:, {'x', 'V', 'I'});
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sys = get_sys_controllers_(net, controllers, cname)
    nu = tools.vcellfun(@(b) b.component.get_nu(), net.a_bus);
    idx_u_end = [cumsum(nu); sum(nu)];
    idx_u_start = [1; idx_u_end(1:end-1)+1];

    nx = tools.vcellfun(@(b) b.component.get_nx(), net.a_bus);
    idx_x_end = [cumsum(nx); sum(nx)];
    idx_x_start = [1; idx_x_end(1:end-1)+1];
if numel(controllers) == 0
    nout = sum(nu);
    nin = sum(nx) + 4*numel(net.a_bus) + sum(nu);
    sys = ss(zeros(nout, nin));
else
    [A, Bx, Bv, Bi, Bu, C, Dx, Dv, Di, Du] = tools.cellfun(@(c) c.get_linear_matrix(), controllers);
    index_observe = tools.cellfun(@(c) c.index_observe, controllers);
    index_input = tools.cellfun(@(c) c.index_input, controllers);

    selector_u = @(idx) tools.varrayfun(@(i) (idx_u_start(i):idx_u_end(i))', idx);
    selector_x = @(idx) tools.varrayfun(@(i) (idx_x_start(i):idx_x_end(i))', idx);
    selector_VI = @(idx) tools.varrayfun(@(i) (i*2-1:i*2)', idx);

    Selectors_u_in = cell(numel(controllers), 1);
    Selectors_u_out = cell(numel(controllers), 1);
    Selectors_x = cell(numel(controllers), 1);
    Selectors_VI = cell(numel(controllers), 1);

    for i = 1:numel(controllers)
        sel_x = selector_x(index_observe{i});
        Selectors_x{i} = zeros(numel(sel_x), sum(nx));
        Selectors_x{i}(:, sel_x) = eye(numel(sel_x));

        sel_VI = selector_VI(index_observe{i});
        Selectors_VI{i} = zeros(numel(sel_VI), 2*numel(net.a_bus));
        Selectors_VI{i}(:, sel_VI) = eye(numel(sel_VI));

        sel_u = selector_u(index_input{i});
        Selectors_u_out{i} = zeros(sum(nu), numel(sel_u));
        Selectors_u_out{i}(sel_u, :) = eye(numel(sel_u));

        sel_u = selector_u(index_observe{i});
        Selectors_u_in{i} = zeros(numel(sel_u), sum(nu));
        Selectors_u_in{i}(:, sel_u) = eye(numel(sel_u));
    end


    Ac = blkdiag(A{:});
    Bcx = tools.vcellfun(@(bx, sel) bx*sel, Bx(:), Selectors_x(:));
    Bcv = tools.vcellfun(@(bx, sel) bx*sel, Bv(:), Selectors_VI(:));
    Bci = tools.vcellfun(@(bx, sel) bx*sel, Bi(:), Selectors_VI(:));
    Bcu = tools.vcellfun(@(bx, sel) bx*sel, Bu(:), Selectors_u_in(:));

    Cc = cell(numel(controllers), 1);
    for i = 1:numel(controllers)
        Cc{i} = Selectors_u_out{i}*C{i};
    end
    Cc = horzcat(Cc{:});

    Dcx = zeros(sum(nu), sum(nx));
    for i = 1:numel(controllers)
        Dcx = Dcx + Selectors_u_out{i}*Dx{i}*Selectors_x{i};
    end

    Dcv = zeros(sum(nu), 2*numel(net.a_bus));
    for i = 1:numel(controllers)
        Dcv = Dcv + Selectors_u_out{i}*Dv{i}*Selectors_VI{i};
    end

    Dci = zeros(sum(nu), 2*numel(net.a_bus));
    for i = 1:numel(controllers)
        Dci = Dci + Selectors_u_out{i}*Di{i}*Selectors_VI{i};
    end

    Dcu = zeros(sum(nu), sum(nu));
    for i = 1:numel(controllers)
        Dcu = Dcu + Selectors_u_out{i}*Du{i}*Selectors_u_in{i};
    end

    D_each_x = tools.vcellfun(@(d, sel) d*sel, Dx(:), Selectors_x(:));
    D_each_v = tools.vcellfun(@(d, sel) d*sel, Dv(:), Selectors_VI(:));
    D_each_i = tools.vcellfun(@(d, sel) d*sel, Di(:), Selectors_VI(:));
    D_each_u = tools.vcellfun(@(d, sel) d*sel, Du(:), Selectors_u_in(:));


    sys = ss(Ac, [Bcx, Bcv, Bci, Bcu], [Cc; blkdiag(C{:})],...
        [Dcx, Dcv, Dci, Dcu; D_each_x, D_each_v, D_each_i, D_each_u]);
end
sys.InputGroup.x = 1:sum(nx);
sys.InputGroup.V = sum(nx) + (1:2*numel(net.a_bus));
sys.InputGroup.I = sum(nx) + 2*numel(net.a_bus) + (1:2*numel(net.a_bus));
sys.InputGroup.u = sum(nx) + 4*numel(net.a_bus) + (1:sum(nu));

idx = 0;
for i = 1:numel(net.a_bus)
    if nx(i) ~= 0
        sys.InputGroup.(strcat('x', num2str(i))) = idx + (1:nx(i));
        idx = idx + nx(i);
    end
end
for i = 1:numel(net.a_bus)
    sys.InputGroup.(strcat('V', num2str(i))) = idx + (1:2);
    idx = idx + 2;
end
for i = 1:numel(net.a_bus)
    sys.InputGroup.(strcat('I', num2str(i))) = idx + (1:2);
    idx = idx + 2;
end
for i = 1:numel(net.a_bus)
    if nu(i) ~= 0
        sys.InputGroup.(strcat('u', num2str(i))) = idx + (1:nu(i));
        idx = idx + nu(i);
    end
end

sys.OutputGroup.(strcat('u', cname)) = 1:sum(nu);
idx = 0;
for i = 1:numel(nu)
    if nu(i) ~= 0
        name = strcat('u', cname, num2str(i));
        sys.OutputGroup.(name) = idx+(1:nu(i));
        idx = idx + nu(i);
    end
end

for i = 1:numel(controllers)
    name = strcat('u_c', cname, num2str(i));
    sys.OutputGroup.(name) = idx + (1:size(Du{i}, 1));
    idx = idx + size(Du{i}, 1);
end
end
