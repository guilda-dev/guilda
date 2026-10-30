function reset_opffcn(obj)
% <@Desc>
% Removes the OPF terms set by set_opffcn: the component gets its default cost and
% default constraints again. The edit is logged and does not make the equilibrium stale.
% <@Role> Settings
% <@Summary> Restore the default OPF cost and constraints of the component.
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
%   "```matlab\ngen.reset_opffcn();\n```"
% ]
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
