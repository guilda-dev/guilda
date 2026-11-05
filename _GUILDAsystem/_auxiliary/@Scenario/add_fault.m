function s_tag = add_fault(obj, bus, time, opt)
% Add a ground fault (voltage 0) on buses from t_start to t_end.
%
% <@Examples>
% ```matlab
% sc.add_fault("B008", [0.10, 0.17]);           % tag "fault1"
% ```
    arguments (Input)
        obj
        bus  (:,1) string % Tags of the faulted buses.
        time (1,2) double % [s] [t_start, t_end] of the fault.
        opt.Tag (1,1) string = "" % Tag of the disturbance; default fault<n>.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = blank_record(opt.Tag, time);
    d.FaultBus = bus;
    s_tag = obj.add_record(d, "fault");
end
