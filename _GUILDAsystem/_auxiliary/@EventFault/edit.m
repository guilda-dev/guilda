function edit(obj, opt)
% Change the fault: the options of add_fault, each optional (one not given keeps its value).
%
% In a scenario, all its events are checked again; when a check fails, the fault gets
% back its values and the error is thrown.
%
% <@Examples>
% ```matlab
% ev = sc.add_fault("B008", [0.10, 0.17]);
% ev.edit(Time=[0.10, 0.20]);
% ev.edit(Target="EL003", Status="3LG", Point=0.3);
% ```
    arguments (Input)
        obj
        opt.Target (:,1) string  % Tags of the faulted buses, or of the faulted branches. Default: obj.sv_target.
        opt.Time   (1,2) double  % [s] [t_start, t_end] of the fault. Default: obj.rr_time.
        opt.Status (1,1) string {mustBeMember(opt.Status, ["BG","3LG","6LG"])}  % "BG" for buses; "3LG" or "6LG" for branches. Default: obj.s_status.
        opt.Point  (1,1) double  % Fault position along a branch, 0 < Point < 1 (NaN for buses). Default: obj.r_point.
    end
    sct = struct();
    if isfield(opt, "Target"), sct.sv_target = unique(opt.Target, "stable"); end
    if isfield(opt, "Time"),   sct.rr_time   = opt.Time;   end
    if isfield(opt, "Status"), sct.s_status  = opt.Status; end
    if isfield(opt, "Point"),  sct.r_point   = opt.Point;  end
    obj.apply_edit(sct);
end
