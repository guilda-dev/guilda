function reset_opffcn(obj)
% Restore the default network-wide OPF terms.
%
% Removes the network-wide OPF terms set by net.set_opffcn and restores the fixed angle
% of the reference bus. Terms set on components, buses and branches are kept (use their
% own reset_opffcn). The edit is logged and does not make the equilibrium stale.
%
% <@Examples>
% ```matlab
% net.reset_opffcn();
% ```
%
% See also PowerNetwork.set_opffcn
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
