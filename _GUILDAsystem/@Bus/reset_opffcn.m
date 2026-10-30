function reset_opffcn(obj)
% Restore the default OPF cost and constraints of the bus.
%
% Removes the OPF terms set by set_opffcn: the bus gets its default constraints again
% and no cost. The edit is logged and does not make the equilibrium stale.
%
% <@Examples>
% ```matlab
% net.a_Bus{5}.reset_opffcn();
% ```
%
% See also Bus.set_opffcn
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
