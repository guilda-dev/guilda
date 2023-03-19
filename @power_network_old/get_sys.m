function [sys] =get_sys(obj, with_controller)
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
    if nz~=0
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
    sys_controller = obj.get_sys_controllers(obj, obj.a_controller_local, obj.a_controller_global);
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
