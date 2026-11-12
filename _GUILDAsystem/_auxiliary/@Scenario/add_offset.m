function s_tag = add_offset(obj, unit, state, value, time, opt)
% Add an offset of the states of a component at one time.
%
% The values are added to the states at time (to the initial states when time is the
% start of the simulation).
%
% <@Examples>
% ```matlab
% sc.add_offset("B001SG1", ["delta"; "omega"], [0.1; 0], 0);
% ```
    arguments (Input)
        obj
        unit  (1,1) string % Tag of the component.
        state (:,1) string % Names of the states (e.g. "delta").
        value (:,1) double % Offsets, one per state or one for all.
        time  (1,1) double = 0 % [s] Time of the offset.
        opt.Tag (1,1) string = "" % Tag of the disturbance; default offset<n>.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = blank_record(opt.Tag, time);
    d.OffsetUnit  = unit;
    d.OffsetState = state;
    d.OffsetValue = value;
    s_tag = obj.add_record(d, "offset");
end
