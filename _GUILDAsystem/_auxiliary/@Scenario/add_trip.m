function s_tag = add_trip(obj, unit, time, opt)
% Add a trip of components or global controllers from t_start to t_end.
%
% A tripped unit is disconnected (its states are NaN in the result) and reconnected at
% t_end. A local controller cannot be tripped.
    arguments (Input)
        obj
        unit (:,1) string % Tags of the components or global controllers.
        time (1,2) double % [s] [t_start, t_end] of the trip.
        opt.Tag (1,1) string = "" % Tag of the disturbance; default trip<n>.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = blank_record(opt.Tag, time);
    d.TripUnit = unit;
    s_tag = obj.add_record(d, "trip");
end
