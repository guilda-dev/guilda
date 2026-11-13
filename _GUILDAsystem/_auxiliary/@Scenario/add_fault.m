function s_tag = add_fault(obj, target, time, opt)
% Add a ground fault on buses, or on branches, from t_start to t_end.
%
% A bus fault ("BG", the default) holds the voltage of the bus at 0. A branch fault needs
% Status and Point: "3LG" grounds one circuit, "6LG" all circuits, at Point along the
% branch (0 < Point < 1, from the from end 0 to the to end 1; a fault at an end is a fault
% of that bus). The targets are all buses or all branches.
%
% Two rows per target are added to tab_event with one new tag Fault<n>: (t_start, Status,
% Point) and (t_end, "none", Point). Bus rows have Point NaN. remove_disturbance(tag)
% removes them. Two faults of one target may touch but not overlap. Branch faults cannot be
% simulated yet (GUILDA:Scenario:NotYetSupported).
%
% <@Examples>
% ```matlab
% sc.add_fault("B008", [0.10, 0.17]);                               % Fault001
% sc.add_fault("EL003", [0.10, 0.17], Status="3LG", Point=0.3);     % one circuit of EL003
% ```
    arguments (Input)
        obj
        target (:,1) string % Tags of the faulted buses, or of the faulted branches.
        time   (1,2) double % [s] [t_start, t_end] of the fault.
        opt.Status (1,1) string {mustBeMember(opt.Status, ["BG","3LG","6LG"])} % "BG" (buses, the default) or "3LG"/"6LG" (branches; required).
        opt.Point  (1,1) double % Fault position along a branch, 0 < Point < 1 (branches; required).
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added fault (Fault<n>).
    end
    s_status = "BG";
    if isfield(opt, "Status")
        s_status = opt.Status;
    end
    point = NaN;
    if isfield(opt, "Point")
        point = opt.Point;
    end
    tab = new_event_rows(obj.tab_event, "Fault", target, time, [s_status, "none"], point);
    obj.add_events(tab);
    s_tag = tab.Tag(1);
end
