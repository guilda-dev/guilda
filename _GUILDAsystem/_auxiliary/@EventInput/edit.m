function edit(obj, opt)
% Change the input: the options of add_input, each optional (one not given keeps its value).
%
% Value given without Method sets the method again from the value ("foh" for a time
% series, none for a constant). Method alone applies to the stored value (a constant stops
% with GUILDA:EventInput:MethodWithoutSeries). In a scenario, all its events are checked
% again (the tag too); when a check fails, the input gets back its values and the error is
% thrown.
%
% <@Examples>
% ```matlab
% ev = sc.add_input("B002SG1", "Pmech", [0, 0; 2, 0.02], [1, 3]);
% ev.edit(Method="zoh");
% ev.edit(Value=0.05, Time=[1, 1.5]);
% ```
    arguments (Input)
        obj
        opt.Unit   (1,1) string                                  % Tag of the component. Default: obj.s_unit.
        opt.Name   (:,1) string                                  % Names of the inputs (e.g. "Pmech"). Default: obj.sv_name.
        opt.Value  {mustBeA(opt.Value, ["double","table"])}      % Constants, or a time series [t, v_1, ..., v_n] or table. Default: obj.rm_value.
        opt.Time   (1,2) double                                  % [s] [t_start, t_end] of the input. Default: obj.rr_time.
        opt.Method (1,1) string {mustBeMember(opt.Method, ["zoh","foh","spline"])}  % Interpolation of a time series: "zoh", "foh" or "spline". Default: obj.s_method.
        opt.Tag    (1,1) string                                  % Tag of the input (not Fault or Parallel followed by digits). Default: obj.s_tag.
    end
    sct = struct();
    if isfield(opt, "Unit"), sct.s_unit  = opt.Unit; end
    if isfield(opt, "Time"), sct.rr_time = opt.Time; end
    if isfield(opt, "Tag"),  sct.s_tag   = opt.Tag;  end
    if any(isfield(opt, ["Name", "Value", "Method"]))
        sv_name = obj.sv_name;
        if isfield(opt, "Name")
            sv_name = opt.Name;
        end
        value    = obj.rm_value;
        s_method = obj.s_method;
        if isfield(opt, "Value")
            value    = opt.Value;
            s_method = "";
        end
        if isfield(opt, "Method")
            s_method = opt.Method;
        end
        s_lbl = obj.s_tag;
        if s_lbl == ""
            s_lbl = "EventInput";
        end
        s_sc = "(none)";
        if ~isempty(obj.a_Scenario) && isvalid(obj.a_Scenario)
            s_sc = obj.a_Scenario.s_tag;
        end
        [sct.rm_value, sct.s_method] = normalize_input(value, sv_name, s_method, {char(s_lbl), char(s_sc)});
        sct.sv_name = sv_name;
    end
    obj.apply_edit(sct);
end
