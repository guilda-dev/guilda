function reset_opffcn(obj)
% Restore the default OPF cost and constraints of the branch.
%
% Removes the OPF terms set by set_opffcn: the branch gets its default limits again and
% no cost. The edit is logged and does not make the equilibrium stale.
%
% <@Examples>
% ```matlab
% net.a_Branch{1}.reset_opffcn();
% ```
%
% See also Branch.set_opffcn
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
