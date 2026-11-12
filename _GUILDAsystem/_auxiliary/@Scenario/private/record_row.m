function row = record_row(d)
% One table row from a disturbance record
    ts = d.TimeSpan;
    if isscalar(ts)
        ts = [ts, ts];
    end
    row = table(d.Tag, ts, {d.FaultBus}, {d.TripUnit}, {d.OpenBranch}, d.OffsetUnit, ...
                {d.OffsetState}, {d.OffsetValue}, d.InputUnit, {d.InputName}, {d.InputValue}, d.InputMethod, ...
                'VariableNames', ["Tag","TimeSpan","FaultBus","TripUnit","OpenBranch","OffsetUnit", ...
                                  "OffsetState","OffsetValue","InputUnit","InputName","InputValue","InputMethod"]);
end
