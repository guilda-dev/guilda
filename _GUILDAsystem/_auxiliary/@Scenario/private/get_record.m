function d = get_record(tab, k)
% Disturbance record of row k (the fields of add_disturbance)
    d = struct();
    d.Tag         = tab.Tag(k);
    d.TimeSpan    = tab.TimeSpan(k,:);
    d.FaultBus    = tab.FaultBus{k};
    d.TripUnit    = tab.TripUnit{k};
    d.OpenBranch  = tab.OpenBranch{k};
    d.OffsetUnit  = tab.OffsetUnit(k);
    d.OffsetState = tab.OffsetState{k};
    d.OffsetValue = tab.OffsetValue{k};
    d.InputUnit   = tab.InputUnit(k);
    d.InputName   = tab.InputName{k};
    d.InputValue  = tab.InputValue{k};
    d.InputMethod = tab.InputMethod(k);
end
