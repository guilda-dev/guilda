classdef (Sealed) EventTrip < EventBase
% Trip of components, global controllers or local controllers at time t (Scenario.add_trip).
%
% A tripped unit is disconnected at t and stays disconnected until the end of the
% simulation (its states are NaN in the result). In tab_event the trip has one row per unit
% with its tag Parallel<n>: (t, "open"). The units and the time are checked when the event
% is added to a scenario.
%
% <@Examples>
% ```matlab
% ev = sc.add_trip("B003LPQ2", 1);
% ev.edit(Time=1.5);
% ```
%
% See also EventBase, Scenario.add_trip

    properties (SetAccess={?EventBase}) % Trip
        sv_unit (:,1) string = strings(0,1)  % Tags of the tripped components, global controllers or local controllers. <@Type> string
        r_time (1,1) double = 0              % [s] Time of the trip.
    end

    properties (Constant, Hidden) % Kind
        s_prefix = "Parallel"                % Prefix of the automatic tag.
        s_table  = "event"                   % Table the event contributes to.
    end

    methods
        function obj = EventTrip(unit, time)
        % Create a trip event (not in a scenario).
            arguments (Input)
                unit (:,1) string  % Tags of components, global controllers or local controllers.
                time (1,1) double  % [s] Time of the trip.
            end
            arguments (Output)
                obj  % The new event.
            end
            obj.sv_unit = unique(unit, "stable");
            obj.r_time  = time;
        end
    end

    methods (Access={?Scenario, ?EventBase})
        tab = table_rows(obj)
    end
end
