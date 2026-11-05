function s_tag = add_disturbance(obj, tag, opt)
% Add a disturbance given by any of the disturbance fields.
%
% The general form, with the fields of the deprecated ODEevent: one disturbance may
% combine a fault, a trip, a branch opening, an offset and an input with one time
% span. When the scenario is attached to a network, the tags are checked against it
% now; otherwise when the scenario is added to a network. The checks are those of the
% simulation: unknown tags, states and inputs, a TimeSpan without duration for a
% lasting disturbance, value counts and the number of arguments of input functions.
% Nothing is added when a check fails.
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
        opt.InputValue  (:,1) {mustBeA(opt.InputValue, {'double','cell','function_handle'})} = zeros(0,1) % Values added to InputName: numbers, or a cell of numbers and functions f(t) of the time since t_start.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = opt;
    d.Tag = tag;
    s_tag = obj.add_record(d, "");
end
