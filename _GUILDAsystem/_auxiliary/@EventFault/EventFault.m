classdef (Sealed) EventFault < EventBase
% Ground fault on buses, or on branches, from t_start to t_end (Scenario.add_fault).
%
% A bus fault ("BG", the default) holds the voltage of the bus at 0. A branch fault needs
% Status and Point: "3LG" grounds one circuit, "6LG" all circuits, at Point along the
% branch (0 < Point < 1, from the from end 0 to the to end 1). The targets are all buses or
% all branches. In tab_event the fault has two rows per target with its tag Fault<n>:
% (t_start, Status, Point) and (t_end, "none", Point).
%
% The constructor checks only the types and sizes; the targets, the time span and Status
% and Point are checked when the event is added to a scenario.
%
% <@Examples>
% ```matlab
% ev = sc.add_fault("B008", [0.10, 0.17]);
% ev.edit(Target="EL003", Status="3LG", Point=0.3);
% sc2 = net.add_scenario("case2", Event={EventFault("B008", [0.1, 0.17])});
% ```
%
% See also EventBase, Scenario.add_fault

    properties (SetAccess={?EventBase}) % Fault
        sv_target (:,1) string = strings(0,1)  % Tags of the faulted buses, or of the faulted branches (repeated ones once). <@Type> string
        rr_time (1,2) double = [0, 0]          % [s] [t_start, t_end] of the fault.
        s_status (1,1) string = "BG"           % "BG" (buses), "3LG" or "6LG" (branches).
        r_point (1,1) double = NaN             % Fault position along a branch, 0 < r_point < 1 (NaN for buses).
    end

    properties (Constant, Hidden) % Kind
        s_prefix = "Fault"                     % Prefix of the automatic tag.
        s_table  = "event"                     % Table the event contributes to.
    end

    methods
        function obj = EventFault(target, time, opt)
        % Create a fault event (not in a scenario).
            arguments (Input)
                target (:,1) string  % Tags of the faulted buses, or of the faulted branches.
                time   (1,2) double  % [s] [t_start, t_end] of the fault.
                opt.Status (1,1) string {mustBeMember(opt.Status, ["BG","3LG","6LG"])} = "BG"  % "BG" for buses; "3LG" or "6LG" for branches (required there).
                opt.Point  (1,1) double = NaN  % Fault position along a branch, 0 < Point < 1 (required for branches, NaN for buses).
            end
            arguments (Output)
                obj  % The new event.
            end
            obj.sv_target = unique(target, "stable");
            obj.rr_time   = time;
            obj.s_status  = opt.Status;
            obj.r_point   = opt.Point;
        end
    end

    methods (Access={?Scenario, ?EventBase})
        tab = table_rows(obj)
    end
end
