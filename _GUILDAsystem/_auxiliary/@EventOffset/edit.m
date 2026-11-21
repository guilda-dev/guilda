function edit(obj, opt)
% Change the offset: the options of add_offset, each optional (one not given keeps its value).
%
% In a scenario, all its events are checked again (the tag too); when a check fails, the
% offset gets back its values and the error is thrown.
%
% <@Examples>
% ```matlab
% ev = sc.add_offset("B001SG1", "delta", 0.1, 0);
% ev.edit(Value=0.2, Time=1, Tag="kick");
% ```
    arguments (Input)
        obj
        opt.Unit  (1,1) string   % Tag of the component. Default: obj.s_unit.
        opt.State (:,1) string   % Names of the states (e.g. "delta"). Default: obj.sv_state.
        opt.Value (:,1) double   % Offsets, one per state or one for all. Default: obj.rv_value.
        opt.Time  (1,1) double   % [s] Time of the offset. Default: obj.r_time.
        opt.Tag   (1,1) string   % Tag of the offset (not Fault or Parallel followed by digits). Default: obj.s_tag.
    end
    sct = struct();
    if isfield(opt, "Unit"),  sct.s_unit   = opt.Unit;  end
    if isfield(opt, "State"), sct.sv_state = opt.State; end
    if isfield(opt, "Value"), sct.rv_value = opt.Value; end
    if isfield(opt, "Time"),  sct.r_time   = opt.Time;  end
    if isfield(opt, "Tag"),   sct.s_tag    = opt.Tag;   end
    obj.apply_edit(sct);
end
