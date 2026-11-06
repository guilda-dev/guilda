function reset_opffcn(obj)
% Restore the default OPF cost and constraints of the branch.
%
% Removes the OPF terms set by set_opffcn: the branch gets its default limits again and
% no cost. The edit (tag "opffcn") makes nothing stale.
%
% <@Examples>
% ```matlab
% net.a_Branch{1}.reset_opffcn();
% ```
%
% See also Branch.set_opffcn
%
% <@Group> Construction and editing
    arguments (Input)
        obj
    end
    obj.f_opfcost    = [];
    obj.f_opfconst   = [];
    obj.l_opfdefault = true;
    obj.log_edit("reset_opffcn", "opffcn");
end
