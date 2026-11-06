function reset_opffcn(obj)
% Restore the default OPF cost and constraints of the component.
%
% Removes the OPF terms set by set_opffcn: the component gets its default cost and
% default constraints again. The edit (tag "opffcn") makes nothing stale.
%
% <@Examples>
% ```matlab
% gen.reset_opffcn();
% ```
%
% See also Component.set_opffcn
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
