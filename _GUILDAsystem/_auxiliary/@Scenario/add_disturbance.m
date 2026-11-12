function s_tag = add_disturbance(obj, tag, opt)
% Add a disturbance given by any of the disturbance fields.
%
% The general form: one disturbance may
% combine a fault, a trip, a branch opening, an offset and an input with one time
% span. The tags are checked against the network of the scenario now, and again at the
% start of each simulation. The checks are those of the simulation: unknown tags, states
% and inputs, a TimeSpan without duration for a lasting disturbance, value counts and the
% input time series (see add_input). Nothing is added when a check fails.
%
% <@Examples>
% ```matlab
% sc.add_disturbance("fault+open", TimeSpan=[1, 1.05], FaultBus="B008", OpenBranch="EL003");
% ```
    arguments (Input)
        obj
        tag (1,1) string % Tag of the disturbance, unique in the scenario (the column of output.phases).
        opt.TimeSpan {mustBeRow, validateTimeSpanSize} = [0,10] % [s] [t_start, t_end], or t_start alone for an offset only.
        opt.FaultBus    (:,1) string = strings(0,1) % Tags of the buses with a ground fault (voltage 0).
        opt.TripUnit    (:,1) string = strings(0,1) % Tags of the components or global controllers disconnected.
        opt.OpenBranch  (:,1) string = strings(0,1) % Tags of the branches left out of the network (reconnected at t_end).
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
