function reset_opffcn(obj)
% <@Desc>
% Removes the network-wide OPF terms set by net.set_opffcn and restores the fixed angle
% of the reference bus. Terms set on components, buses and branches are kept (use their
% own reset_opffcn). The edit is logged and does not make the equilibrium stale.
% <@Role> Settings
% <@Summary> Restore the default network-wide OPF terms.
% <@Signatures>
% [
%   "net.reset_opffcn()"
% ]
% <@Parameters>
% []
% <@Returns>
% []
% <@Examples>
% [
%   "```matlab\nnet.reset_opffcn();\n```"
% ]
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
