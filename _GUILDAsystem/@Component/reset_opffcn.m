function reset_opffcn(obj)
% Restore the default OPF cost and constraints of the component.
%
% Removes the OPF terms set by set_opffcn: the component gets its default cost and
% default constraints again. The edit is logged and does not make the equilibrium stale.
%
% <@Examples>
% ```matlab
% gen.reset_opffcn();
% ```
%
% See also Component.set_opffcn
    obj.s_opffcn = opffcn.default();
    obj.log_edit("reset_opffcn", "OPF");
end
