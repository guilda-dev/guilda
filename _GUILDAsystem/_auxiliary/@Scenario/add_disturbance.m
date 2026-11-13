function s_tag = add_disturbance(obj, tag, opt)
% Add an offset and an input with one tag.
%
% The general form of add_offset and add_input: the offset (applied at t_start) goes to
% tab_offset and the input (from t_start to t_end) to tab_input, both with the tag. Faults,
% trips and branch openings are added with add_fault, add_trip and add_open_branch. The
% tags are checked against the network of the scenario now, and again at the start of
% each simulation. The checks are those of the simulation: unknown tags, states and
% inputs, a TimeSpan without duration for an input, value counts and the input time
% series (see add_input). Nothing is added when a check fails. Without an offset and an
% input, the tag only marks its time span (a column of output.phases).
%
% <@Examples>
% ```matlab
% sc.add_disturbance("kick", TimeSpan=[1, 1.5], OffsetUnit="B001SG1", OffsetState="delta", ...
%     OffsetValue=0.01, InputUnit="B002SG1", InputName="Pmech", InputValue=0.05);
% ```
    arguments (Input)
        obj
        tag (1,1) string % Tag of the disturbance, unique in the scenario (the column of output.phases; not Fault or Parallel followed by digits).
        opt.TimeSpan {mustBeRow, validateTimeSpanSize} = [0,10] % [s] [t_start, t_end], or t_start alone without an input.
        opt.OffsetUnit  (1,1) string = ""           % Tag of the component whose initial states are offset at t_start.
        opt.OffsetState (:,1) string = strings(0,1) % Names of the states to offset (e.g. "delta").
        opt.OffsetValue (:,1) double = zeros(0,1)   % Offsets of OffsetState, one per name or one for all.
        opt.InputUnit   (1,1) string = ""           % Tag of the component to which an input is added.
        opt.InputName   (:,1) string = strings(0,1) % Names of the inputs of InputUnit (e.g. "Pmech").
        opt.InputValue  {mustBeA(opt.InputValue, ["double","table"])} = zeros(0,1) % Values added to InputName: constants, or a time series [t, v_1, ..., v_n] or table (see add_input).
        opt.InputMethod (1,1) string {mustBeMember(opt.InputMethod, ["zoh","foh","spline"])} % Interpolation of a time series InputValue: "zoh", "foh" or "spline". Default: "foh".
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = blank_record(tag, opt.TimeSpan);
    for s_name = string(fieldnames(opt)).'
        d.(s_name) = opt.(s_name);
    end
    s_tag = obj.add_record(d, "");
end
