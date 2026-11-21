function edit(obj, opt)
% Change the opening: the options of add_open_branch, each optional (one not given keeps its value).
%
% In a scenario, all its events are checked again; when a check fails, the opening gets
% back its values and the error is thrown.
%
% <@Examples>
% ```matlab
% ev = sc.add_open_branch("EL003", 0.17);
% ev.edit(Time=0.2, Status="3open");
% ```
    arguments (Input)
        obj
        opt.Branch (:,1) string  % Tags of the branches (see string(net.a_Branch)). Default: obj.sv_branch.
        opt.Time   (1,1) double  % [s] Time of the opening. Default: obj.r_time.
        opt.Status (1,1) string {mustBeMember(opt.Status, ["6open","3open"])}  % All circuits or one circuit. Default: obj.s_status.
    end
    sct = struct();
    if isfield(opt, "Branch"), sct.sv_branch = unique(opt.Branch, "stable"); end
    if isfield(opt, "Time"),   sct.r_time    = opt.Time;   end
    if isfield(opt, "Status"), sct.s_status  = opt.Status; end
    obj.apply_edit(sct);
end
