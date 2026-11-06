function reset_opffcn(obj)
% Restore the default network-wide OPF terms.
%
% Removes the network-wide OPF terms set by net.set_opffcn and restores the fixed angle
% of the reference bus. Terms set on components, buses and branches are kept (use their
% own reset_opffcn). The edit (tag "opffcn") makes nothing stale.
%
% <@Examples>
% ```matlab
% net.reset_opffcn();
% ```
%
% See also PowerNetwork.set_opffcn
%
% <@Group> Model building
    arguments (Input)
        obj
    end
    obj.f_opfcost    = [];
    obj.f_opfconst   = [];
    obj.l_opfdefault = true;
    obj.log_edit("reset_opffcn", "opffcn");
end
