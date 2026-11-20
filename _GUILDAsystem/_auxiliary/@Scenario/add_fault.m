function ev = add_fault(obj, target, time, opt)
% Add a ground fault on buses, or on branches, from t_start to t_end.
%
% A bus fault ("BG", the default) holds the voltage of the bus at 0. A branch fault needs
% Status and Point: "3LG" grounds one circuit, "6LG" all circuits, at Point along the
% branch (0 < Point < 1, from the from end 0 to the to end 1; a fault at an end is a fault
% of that bus). The targets are all buses or all branches.
%
% The fault is an EventFault with a new tag Fault<n>, returned: change it with ev.edit and
% remove it with remove_event(ev.s_tag). It gives two rows per target in tab_event:
% (t_start, Status, Point) and (t_end, "none", Point). Bus rows have Point NaN. Two faults of one target may touch but not overlap. "3LG" needs a branch of
% two or more circuits (GUILDA:Scenario:SingleCircuit).
%
% <@Examples>
% ```matlab
% ev = sc.add_fault("B008", [0.10, 0.17]);                          % Fault001
% sc.add_fault("EL003", [0.10, 0.17], Status="3LG", Point=0.3);     % one circuit of EL003
% ```
    arguments (Input)
        obj
        target (:,1) string      % Tags of the faulted buses, or of the faulted branches.
        time   (1,2) double      % [s] [t_start, t_end] of the fault.
        opt.Status (1,1) string {mustBeMember(opt.Status, ["BG","3LG","6LG"])} = "BG"  % "BG" for buses; "3LG" or "6LG" for branches (required there).
        opt.Point  (1,1) double = NaN  % Fault position along a branch, 0 < Point < 1 (required for branches, NaN for buses).
    end
    arguments (Output)
        ev EventFault  % The added event (a handle: edit it with ev.edit).
    end
    ev = EventFault(target, time, Status=opt.Status, Point=opt.Point);
    obj.insert_event(ev, false);
end
