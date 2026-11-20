classdef (Sealed) EventOffset < EventBase
% Offset of the states of a component at one time (Scenario.add_offset).
%
% The values are added to the states at the time (to the initial states when it is the
% start of the simulation). In tab_offset the offset is one row. Its tag is Tag, or
% offset<n> when Tag is empty; it names the column of output.phases. The component, the
% state names and the number of values are checked when the event is added to a scenario.
%
% <@Examples>
% ```matlab
% ev = sc.add_offset("B001SG1", ["delta"; "omega"], [0.1; 0], 0);
% ev.edit(Value=[0.2; 0]);
% ```
%
% See also EventBase, Scenario.add_offset

    properties (SetAccess={?EventBase}) % Offset
        s_unit (1,1) string = ""               % Tag of the component whose states are offset.
        sv_state (:,1) string = strings(0,1)   % Names of the states (e.g. "delta"). <@Type> string
        rv_value (:,1) double = zeros(0,1)     % Offsets, one per state or one for all.
        r_time (1,1) double = 0                % [s] Time of the offset.
    end

    properties (Constant, Hidden) % Kind
        s_prefix = "offset"                    % Prefix of the automatic tag.
        s_table  = "offset"                    % Table the event contributes to.
    end

    methods
        function obj = EventOffset(unit, state, value, time, opt)
        % Create an offset event (not in a scenario).
            arguments (Input)
                unit  (1,1) string         % Tag of the component.
                state (:,1) string         % Names of the states (e.g. "delta").
                value (:,1) double         % Offsets, one per state or one for all.
                time  (1,1) double = 0     % [s] Time of the offset.
                opt.Tag (1,1) string = ""  % Tag of the offset; "" for offset<n> (not Fault or Parallel followed by digits).
            end
            arguments (Output)
                obj  % The new event.
            end
            obj.s_unit   = unit;
            obj.sv_state = state;
            obj.rv_value = value;
            obj.r_time   = time;
            obj.s_tag    = opt.Tag;
        end
    end

    methods (Access={?Scenario, ?EventBase})
        tab = table_rows(obj)
    end
end
