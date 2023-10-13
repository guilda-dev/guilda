function [Y, Ymat] = get_admittance_matrix(obj, a_idx_bus, a_idx_branch)
if nargin < 2 || isempty(a_idx_bus)
    a_idx_bus = 1:numel(obj.a_bus);
end

if nargin < 3
    a_idx_branch = 1:numel(obj.a_branch);
end

n_bus = numel(obj.a_bus);
Y = sparse(n_bus, n_bus);

for i = a_idx_branch(:)' 
   br = obj.a_branch{i};
   if ismember(br.from, a_idx_bus) || ismember(br.to, a_idx_bus)
       Y_branch = br.get_admittance_matrix();
       Y([br.from, br.to], [br.from, br.to]) = Y([br.from, br.to], [br.from, br.to]) + Y_branch;
   end
end

shunt = tools.vcellfun(@(b) b.shunt, obj.a_bus(a_idx_bus));
S = sparse(a_idx_bus, a_idx_bus, shunt, n_bus, n_bus);

Y = Y + S;
if nargout == 2
    Ymat = tools.complex2matrix(Y);
end
end