function reset_opffcn(obj)
% <@Desc>
% Removes the OPF terms set by set_opffcn: the branch gets its default limits again and
% no cost. The edit is logged and does not make the equilibrium stale.
% <@Role> Settings
% <@Summary> Restore the default OPF cost and constraints of the branch.
% <@Signatures>
% [
%   "obj.reset_opffcn()"
% ]
% <@Parameters>
% []
% <@Returns>
% []
% <@Examples>
% [
%   "```matlab\nnet.a_Branch{1}.reset_opffcn();\n```"
% ]
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
