% 指定したエリアに注目したときのローカルシステムと環境を取得する

function [sys_local, sys_env] = get_sys_area(obj, idx_area, with_controller, is_polar)

if nargin < 3
    with_controller = false;
end
if nargin < 4
    is_polar = true;
end

n_bus = numel(obj.a_bus);
if sum(idx_area>n_bus)>0
    error("idx_area contain non-existent bus number");
end
[idx_bound_area, idx_bound_others, idx_branch_bound] = get_bound(obj, idx_area);


% ローカルシステムの取得 (u,I_branch_bound)->(x_local,V_bound,V_local,I_local)
sys_local = get_sys_partial(obj, idx_area, idx_bound_area, is_polar);
sys_local.InputGroup.u_local = sys_local.InputGroup.u;
sys_local.InputGroup = rmfield(sys_local.InputGroup, 'u');
sys_local.OutputGroup.V_local = sys_local.OutputGroup.V;
sys_local.OutputGroup.I_local = sys_local.OutputGroup.I;
if isfield(sys_local.OutputGroup, 'x')
    sys_local.OutputGroup.x_local = sys_local.OutputGroup.x;
    sys_local.OutputGroup = rmfield(sys_local.OutputGroup, {'x', 'V', 'I'});
else
    sys_local.OutputGroup = rmfield(sys_local.OutputGroup, {'V', 'I'});
end


% 環境の取得 (V_bound,x_local,V_local,I_local)->(I_branch_bound,u_global)
idx_others = setdiff(1:n_bus, idx_area);
sys_others = get_sys_partial(obj, idx_others, idx_bound_others, false);

Y_branch_bound_ = obj.get_admittance_matrix([], idx_branch_bound);
idx_bounds = [idx_bound_area; idx_bound_others];
Y_branch_bound = tools.complex2matrix(Y_branch_bound_(idx_bounds, idx_bounds));

n_bound_area = numel(idx_bound_area);
R = struct();
if is_polar
    R.inv_V_bound = tools.matrix_polar_transform(obj.V_equilibrium(idx_bound_area), true);
    R.I_branch_bound = tools.matrix_polar_transform(obj.I_equilibrium(idx_bound_area));
    idx_area_bound = unique([idx_area(:); idx_bound_area(:)], 'sorted');
    R.inv_V = tools.matrix_polar_transform(obj.V_equilibrium(idx_area_bound), true);
    R.inv_I = tools.matrix_polar_transform(obj.I_equilibrium(idx_area_bound), true);
end
sys_env = sys_others2env(obj, sys_others, Y_branch_bound, n_bound_area, with_controller, idx_area, idx_others, is_polar, R);

end

% net: powe_networkクラス, idx_area: 抽出するエリアのindex(列ベクトル)
function [idx_bound_area, idx_bound_others, idx_branch_bound] = get_bound(net, idx_area)
    branch = net.a_branch;
    idx_from = tools.vcellfun(@(b) b.from, branch);
    idx_to = tools.vcellfun(@(b) b.to, branch);
    array_branch_io = ismember(idx_from, idx_area) & ~ismember(idx_to, idx_area);
    array_branch_oi = ~ismember(idx_from, idx_area) & ismember(idx_to, idx_area);
    branch_bound = branch(array_branch_io|array_branch_oi);

    idx_from_branch_bound = tools.hcellfun(@(b) b.from, branch_bound);
    idx_to_branch_bound = tools.hcellfun(@(b) b.to, branch_bound);
    idx_bound_area = unique(intersect([idx_from_branch_bound; idx_to_branch_bound], idx_area'), 'sorted');
    idx_bound_others = unique(setdiff([idx_from_branch_bound; idx_to_branch_bound], idx_area'), 'sorted');
    idx_branch_bound = find(array_branch_io|array_branch_oi);
end

% net: powe_networkクラス, idx_area: 抽出するエリアのindex(列ベクトル), idx_bound: 境界のindex(列ベクトル)
function sys = get_sys_partial(net, idx_area, idx_bound, is_polar)
    [idx_area_bound, ~, ic] = unique([idx_area(:); idx_bound(:)], 'sorted');
    idx_num_bound = ic((numel(idx_area)+1):end); % idx_area_boundでのboundの場所を取得
    idx4Y = [idx_area_bound(:)*2-1, idx_area_bound(:)*2]';
    idx4Y = idx4Y(:);

    [A_each, B_each, C_each, D_each, BV_each, DV_each, BI_each, DI_each, R_each, S_each] =...
    tools.cellfun(@(b) b.component.get_linear_matrix(), net.a_bus(idx_area_bound));
    [A, B, C, D, BV, DV, BI, DI, R, S] = tools.cell2var(tools.cellfun(@(a) blkdiag(a{:}), {A_each, B_each, C_each, D_each, BV_each, DV_each, BI_each, DI_each, R_each, S_each}));
    [~, Y] = net.get_admittance_matrix(idx_area_bound);
    Y = Y(idx4Y, idx4Y);

    nx = size(A, 1); nu = size(B, 2);
    nV = size(BV, 2); nI = size(BI, 2);
    nVb = numel(idx_bound)*2; nIb = nVb;

    selector4I_branch_bound = zeros(nI, nIb);
    for ii = 1:numel(idx_bound)
        idx = idx_num_bound(ii);
        selector4I_branch_bound(idx*2-1:idx*2, ii*2-1:ii*2) = eye(2);
    end
    selector4V_bound = zeros(nVb, nV);
    for ii = 1:numel(idx_bound)
        idx = idx_num_bound(ii);
        selector4V_bound(ii*2-1:ii*2, idx*2-1:idx*2) = eye(2);
    end

    A11 = A;
    A12 = [BV, BI];
    A21 = [C; zeros(nI, nx)];
    A22 = [DV, DI; Y, -eye(nI)];
    B1 = [B, zeros(nx, nIb)];
    B2 = blkdiag(D, selector4I_branch_bound);
    C1 = [eye(nx); zeros(nVb+nV+nI, nx)];
    C2 = [zeros(nx, nV+nI); selector4V_bound, zeros(nVb, nI); eye(nV+nI)];

    [A_, B_, C_, D_] = tools.dae2ode(A11,A12,A21,A22,B1,B2,C1,C2);

    if is_polar
        Rinv_I_branch_bound = tools.matrix_polar_transform(net.I_equilibrium(idx_bound), true);
        Rin = blkdiag(eye(nu), Rinv_I_branch_bound);
        B_ = B_*Rin;
        R_V_bound = tools.matrix_polar_transform(net.V_equilibrium(idx_bound));
        R_V = tools.matrix_polar_transform(net.V_equilibrium(idx_area_bound));
        R_I = tools.matrix_polar_transform(net.I_equilibrium(idx_area_bound));
        Rout = blkdiag(eye(nx), R_V_bound, R_V, R_I);
        C_ = Rout*C_;
        D_ = Rout*D_*Rin;
    end

    sys = ss(A_, B_, C_, D_);
    sys.InputGroup.u = 1:size(B, 2);
    sys.InputGroup.I_branch_bound = size(B, 2)+(1:nIb);
    sys.OutputGroup.x = 1:nx;
    sys.OutputGroup.V_bound = nx+(1:nVb);
    sys.OutputGroup.V = nx+nVb+(1:nV);
    sys.OutputGroup.I = nx+nVb+nV+(1:nI);
end

function sys_env = sys_others2env(net, sys_others, Y_branch_bound, n_bound_area, with_controller, idx_area, idx_others, is_polar, R)
    nv1 = n_bound_area*2; ni1 = nv1;
    nv2 = size(Y_branch_bound, 1)-nv1; ni2 = nv2;
    nx = order(sys_others);

    y11 = Y_branch_bound(1:nv1, 1:nv1);
    y12 = Y_branch_bound(1:nv1, (nv1+1):end);
    y21 = Y_branch_bound((nv1+1):end, 1:nv1);
    y22 = Y_branch_bound((nv1+1):end, (nv1+1):end);

    [A, BI, CV, DVI] = ssdata(sys_others('V_bound', 'I_branch_bound'));
    [~, Bu, ~, DV] = ssdata(sys_others('V_bound', 'u'));
    [~, ~, C, D] = ssdata(sys_others({'x', 'V', 'I'}, 'u'));
    [~, ~, ~, DI] = ssdata(sys_others({'x', 'V', 'I'}, 'I_branch_bound'));
    nu = size(Bu, 2);

    A11 = A;
    A12 = [zeros(nx, nv2+ni1), BI];
    A21 = [CV; zeros(ni1+ni2, nx)];
    A22 = [-eye(nv2), zeros(nv2, ni1), DVI;
        y12, -eye(ni1), zeros(ni1, ni2);
        y22, zeros(ni2, ni1), -eye(ni2)];
    B1 = [Bu, zeros(nx, nv1)];
    B2 = [DV, zeros(nv2, nv1);
        zeros(ni1, nu), y11;
        zeros(ni2, nu), y21];
    C1 = [zeros(ni1, nx); C];
    C2 = [zeros(ni1, nv2), eye(ni1), zeros(ni1, ni2);
        zeros(size(DI, 1), nv2+ni1), DI];
    D__ = [zeros(ni1, nu+nv1); D, zeros(size(DI, 1), nv1)];

    [A_, B_, C_, D_] = tools.dae2ode(A11,A12,A21,A22,B1,B2,C1,C2,D__);

    % if is_polar
    %     B_ = B_*blkdiag(eye(nu), R.inv_V_bound);
    %     R_out = blkdiag(R.I_branch_bound, eye(nx), R.V, R.I);
    %     C_ = R_out*C_;
    %     D_ = R_out*D_;
    % end

    sys_env = ss(A_, B_, C_, D_);
    sys_env.InputGroup.u = 1:nu;
    sys_env.InputGroup.V_bound = nu+(1:nv1);
    sys_env.OutputGroup.I_branch_bound = 1:ni1;
    sys_env.OutputGroup.x = ni1+(1:nx);
    nv_sum = numel(sys_others.OutputGroup.V);
    ni_sum = numel(sys_others.OutputGroup.I);
    sys_env.OutputGroup.V = ni1+nx+(1:nv_sum);
    sys_env.OutputGroup.I = ni1+nx+nv_sum+(1:ni_sum);

    if with_controller
        idx_local = tools.vcellfun(@(c) any(ismember(c.idx, idx_area)), net.a_controller_local);
        controllers = net.a_controller_local(~idx_local);
        sys_controller = net.get_sys_controllers(controllers, net.a_controllers_global);
    else
        sys_controller = net.get_sys_controllers({}, {});
    end

    nx = tools.vcellfun(@(b) b.component.get_nx(), net.a_bus);
    idx_x_end = [cumsum(nx)];
    idx_x_start = [1; idx_x_end(1:end-1)+1];
    nu = tools.vcellfun(@(b) b.component.get_nu(), net.a_bus);
    idx_u_end = [cumsum(nu)];
    idx_u_start = [1; idx_u_end(1:end-1)+1];

    idx_x_local = tools.harrayfun(@(i) idx_x_start(i):idx_x_end(i), sort(idx_area));
    idx_x_others = tools.harrayfun(@(i) idx_x_start(i):idx_x_end(i), sort(idx_others));
    idx_u_global = tools.harrayfun(@(i) idx_u_start(i):idx_u_end(i), sort(idx_area));
    idx_u_others = tools.harrayfun(@(i) idx_u_start(i):idx_u_end(i), sort(idx_others));

    idx_VI_local = false(numel(net.a_bus), 2);
    idx_VI_local(idx_area, :) = true;
    idx_VI_local = reshape(idx_VI_local', [], 1);

    idx_x = sys_controller.InputGroup.x;
    idx_V = sys_controller.InputGroup.V;
    idx_I = sys_controller.InputGroup.I;

    sys_controller.InputGroup.x_local = idx_x(idx_x_local);
    sys_controller.InputGroup.x_others = idx_x(idx_x_others);
    sys_controller.InputGroup.V_local = idx_V(idx_VI_local);
    sys_controller.InputGroup.V_others = idx_V(~idx_VI_local);
    sys_controller.InputGroup.I_local = idx_I(idx_VI_local);
    sys_controller.InputGroup.I_others = idx_I(~idx_VI_local);

    idx_u = sys_controller.OutputGroup.u;
    sys_controller.OutputGroup.u_local = idx_u(idx_u_global);
    sys_controller.OutputGroup.u_others = idx_u(idx_u_others);

    sys_env_ = blkdiag(sys_env, sys_controller);
    feedin = [sys_env_.InputGroup.x_others, sys_env_.InputGroup.V_others, sys_env_.InputGroup.I_others, sys_env_.InputGroup.u];
    feedout = [sys_env_.OutputGroup.x, sys_env_.OutputGroup.V, sys_env_.OutputGroup.I, sys_env_.OutputGroup.u_others];
    sys_env = feedback(sys_env_, eye((numel(feedin))), feedin, feedout, 1);

    fields_in = {'V_bound', 'x_local', 'V_local', 'I_local'};
    fields_out = {'I_branch_bound', 'u_global'};
    sys_env = sys_env(fields_out(isfield(sys_env.OutputGroup, fields_out)), fields_in(isfield(sys_env.InputGroup, fields_in)));

    if is_polar
        [A, B, C, D] = ssdata(sys_env);
        R_in = blkdiag(R.inv_V_bound, eye(numel(idx_x_local)), R.inv_V, R.inv_I);
        B = B*R_in;
        n_ug = size(C,1)-size(R.I_branch_bound, 1);
        R_out = blkdiag(R.I_branch_bound, eye(n_ug));
        C = R_out*C;
        D = R_out*D*R_in;
        ig = sys_env.InputGroup; og = sys_env.OutputGroup;
        sys_env = ss(A, B, C, D);
        sys_env.InputGroup = ig;
        sys_env.OutputGroup = og;
    end
end