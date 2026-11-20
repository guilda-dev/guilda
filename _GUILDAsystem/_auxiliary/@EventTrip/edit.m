function edit(obj, opt)
% Change the trip: the options of add_trip, each optional (one not given keeps its value).
%
% In a scenario, all its events are checked again; when a check fails, the trip gets back
% its values and the error is thrown.
%
% <@Examples>
% ```matlab
% ev = sc.add_trip("B003LPQ2", 1);
% ev.edit(Unit=["B003LPQ2"; "B004LPQ1"], Time=1.5);
% ```
    arguments (Input)
        obj
        opt.Unit (:,1) string  % Tags of components, global controllers or local controllers. Default: obj.sv_unit.
        opt.Time (1,1) double  % [s] Time of the trip. Default: obj.r_time.
    end
    sct = struct();
    if isfield(opt, "Unit"), sct.sv_unit = unique(opt.Unit, "stable"); end
    if isfield(opt, "Time"), sct.r_time  = opt.Time; end
    obj.apply_edit(sct);
end
