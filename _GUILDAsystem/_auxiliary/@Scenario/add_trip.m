function ev = add_trip(obj, unit, time)
% Add a trip of components, global controllers or local controllers at time t.
%
% A tripped unit is disconnected at t and stays disconnected until the end of the
% simulation (its states are NaN in the result). The trip is an EventTrip with a new tag
% Parallel<n>, returned: change it with ev.edit and remove it with remove_event(ev.s_tag).
% It gives one row per unit in tab_event: (t, "open"). A unit is tripped by one parallel
% event at most. An input whose source is tripped takes its equilibrium value (see the
% Scenario help). The local controllers under a tripped component or local controller
% keep running; give them too to stop them.
%
% <@Examples>
% ```matlab
% ev = sc.add_trip("B003LPQ2", 1);  % Parallel001
% sc.add_trip("B001SG1CA1", 2);     % a local controller (an AVR of IEEE14bus with avr-ST1 added)
% ```
    arguments (Input)
        obj
        unit (:,1) string  % Tags of components, global controllers or local controllers.
        time (1,1) double  % [s] Time of the trip.
    end
    arguments (Output)
        ev EventTrip  % The added event (a handle: edit it with ev.edit).
    end
    ev = EventTrip(unit, time);
    obj.insert_event(ev, false);
end
