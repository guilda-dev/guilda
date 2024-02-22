% V,Iを極座標表示で出力する（angleV,absV,angleI,absI）
% with_controllerは未確認
function sys = get_sys_polar(obj, with_controller)
if nargin < 2
    with_controller = false;
end

[A_each, B_each, C_each, D_each, BV_each, DV_each, BI_each, DI_each, R_each, S_each] =...
    tools.cellfun(@(b) b.component.get_linear_matrix(), obj.a_bus);
[A, B, C, D, BV, DV, BI, DI, R, S] = tools.cell2var(tools.cellfun(@(a) blkdiag(a{:}), {A_each, B_each, C_each, D_each, BV_each, DV_each, BI_each, DI_each, R_each, S_each}));

[~, Ymat] = obj.get_admittance_matrix();

nx = size(A, 1);
nV = size(BV, 2);
nI = size(C, 1);
nd = size(R, 2);
nu = size(B, 2);
nz = size(S, 1);

A11 = A;
A12 = [BV, BI];
A21 = [C; zeros(nI, nx)];
A22 = [DV, DI; Ymat, -eye(nI)];

B1 = [B, R];
B2 = [D, zeros(nV, nd); zeros(nI, nu+nd)];

C1 = [eye(nx); S; zeros(nI+nV, nx)];
C2 = [zeros(nx+nz, nV+nI); eye(nV+nI)];

A_ = A11-A12/A22*A21;
B_ = B1-A12/A22*B2;
C_ = C1-C2/A22*A21;
D_ = -C2/A22*B2;

% V,Iの極座標表示への変換
R_V = tools.matrix_polar_transform(obj.V_equilibrium);
R_I = tools.matrix_polar_transform(obj.I_equilibrium);
R = blkdiag(eye(nx+nz), R_V, R_I);
C_ = R*C_;
D_ = R*D_;

InputGroup = struct();
OutputGroup = struct();

sys = ss(A_, B_, C_, D_);
InputGroup.u = 1:nu;
InputGroup.d = nu+(1:nd);
OutputGroup.x = 1:nx;
OutputGroup.z = nx+(1:nz);
OutputGroup.V = nx+nz+(1:nV);
OutputGroup.I = nx+nz+nV+(1:nI);

idx = 0;
for i = 1:numel(obj.a_bus)
    nu = obj.a_bus{i}.component.get_nu();
    if nu~=0
        InputGroup.(['u', num2str(i)]) = idx+(1:nu);
        idx = idx + nu;
    end
end

idx_y = 0;
for i = 1:numel(obj.a_bus)
    nd = size(R_each{i}, 2);
    nx = size(A_each{i}, 1);
    if nd~=0
        InputGroup.(['d', num2str(i)]) = idx+(1:nd);
        idx = idx + nd;
    end
    if nx~=0
        OutputGroup.(['x', num2str(i)]) = idx_y+(1:nx);
        idx_y = idx_y + nx;
    end
end

for i = 1:numel(obj.a_bus)
    nz = size(S_each{i}, 1);
    if nz~=0
        OutputGroup.(['z', num2str(i)]) = idx_y+(1:nz);
        idx_y = idx_y + nz;
    end
end

for i = 1:numel(obj.a_bus)
    OutputGroup.(['V', num2str(i)]) = idx_y + (1:2);
    idx_y = idx_y + 2;
end
for i = 1:numel(obj.a_bus)
    OutputGroup.(['I', num2str(i)]) = idx_y + (1:2);
    idx_y = idx_y + 2;
end

sys.InputGroup = InputGroup;
sys.OutputGroup = OutputGroup;

if with_controller
    sys_controller = get_sys_controllers(obj, obj.a_controller_local, obj.a_controller_global);
    nu = size(B, 2);
    nx = size(A, 1);
    sys1 = blkdiag(sys, sys_controller);
    sys2 = ss(eye(nu+nx+nV+nI));
    feedin = [sys1.InputGroup.u, sys1.InputGroup.x, sys1.InputGroup.V, sys1.InputGroup.I];
    feedout = [sys1.OutputGroup.u, sys1.OutputGroup.x,...
        sys1.OutputGroup.V, sys1.OutputGroup.I];
    sys = feedback(sys1, sys2, feedin, feedout, 1);
end

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sys = get_sys_controllers(net, controllers, controllers_global)

sys_global = get_sys_controllers_(net, controllers_global, '_global');
sys_local = get_sys_controllers_(net, controllers, '');

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
