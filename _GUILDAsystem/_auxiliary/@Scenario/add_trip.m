function s_tag = add_trip(obj, unit, time)
% Add a trip of components, global controllers or local controllers from t_start to t_end.
%
% A tripped unit is disconnected (its states are NaN in the result) and reconnected at
% t_end. Two rows per unit are added to tab_event with one new tag Parallel<n>: (t_start,
% "open") and (t_end, "close"). remove_disturbance(tag) removes them. Two parallel events
% of one unit may touch but not overlap. An input whose source is tripped takes its
% equilibrium value (see the Scenario help). A reconnected unit restarts from its
% equilibrium (a generator from its bus voltage). The local controllers under a tripped
% component or local controller keep running; give them too to stop them.
%
% <@Examples>
% ```matlab
% sc.add_trip("B003LPQ2", [1, 1.2]);      % Parallel001
% sc.add_trip("B001SG1CA1", [2, 3]);      % a local controller (an AVR of IEEE14bus with avr-ST1 added)
% ```
    arguments (Input)
        obj
        unit (:,1) string % Tags of components, global controllers or local controllers.
        time (1,2) double % [s] [t_start, t_end] of the trip.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added trip (Parallel<n>).
    end
    tab = new_event_rows(obj.tab_event, "Parallel", unit, time, ["open", "close"], NaN);
    obj.add_events(tab);
    s_tag = tab.Tag(1);
end
