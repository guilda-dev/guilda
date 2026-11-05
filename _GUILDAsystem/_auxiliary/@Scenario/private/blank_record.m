function d = blank_record(tag, time)
% Disturbance record with only a tag and a time span
    d = struct();
    d.Tag         = string(tag);
    d.TimeSpan    = time;
    d.FaultBus    = strings(0,1);
    d.TripUnit    = strings(0,1);
    d.OpenBranch  = strings(0,1);
    d.OffsetUnit  = "";
    d.OffsetState = strings(0,1);
    d.OffsetValue = zeros(0,1);
    d.InputUnit   = "";
    d.InputName   = strings(0,1);
    d.InputValue  = zeros(0,1);
end
