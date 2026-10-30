function reset_opffcn(obj)
% <@Desc>
% Removes the OPF terms set by set_opffcn: the bus gets its default constraints again
% and no cost. The edit is logged and does not make the equilibrium stale.
% <@Role> Settings
% <@Summary> Restore the default OPF cost and constraints of the bus.
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
%   "```matlab\nnet.a_Bus{5}.reset_opffcn();\n```"
% ]
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
