function d = blank_record(tag, time)
% Offset and input record with only a tag and a time span (the fields of add_disturbance)
    arguments (Input)
        tag   % Tag of the disturbance.
        time  % [s] TimeSpan: t_start, or [t_start, t_end].
    end
    arguments (Output)
        d (1,1) struct  % Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue, InputUnit, InputName, InputValue, InputMethod.
    end
    d = struct();
    d.Tag         = string(tag);
    d.TimeSpan    = time;
    d.OffsetUnit  = "";
    d.OffsetState = strings(0,1);
    d.OffsetValue = zeros(0,1);
    d.InputUnit   = "";
    d.InputName   = strings(0,1);
    d.InputValue  = zeros(0,1);
    d.InputMethod = "";
end
