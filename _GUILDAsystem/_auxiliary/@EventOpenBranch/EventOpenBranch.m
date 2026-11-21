classdef (Sealed) EventOpenBranch < EventBase
% Opening of branches at time t (Scenario.add_open_branch).
%
% "6open" (the default) opens all circuits: the branch is left out of the bus admittance
% matrix. "3open" opens one circuit. The branches stay open until the end of the
% simulation. In tab_event the opening has one row per branch with its tag Parallel<n>:
% (t, Status). The branches and the time are checked when the event is added to a
% scenario.
%
% <@Examples>
% ```matlab
% ev = sc.add_open_branch("EL003", 0.17);
% ev.edit(Status="3open");
% ```
%
% See also EventBase, Scenario.add_open_branch

    properties (SetAccess={?EventBase}) % Opening
        sv_branch (:,1) string = strings(0,1)  % Tags of the opened branches. <@Type> string
        r_time (1,1) double = 0                % [s] Time of the opening.
        s_status (1,1) string = "6open"        % "6open" (all circuits) or "3open" (one circuit).
    end

    properties (Constant, Hidden) % Kind
        s_prefix = "Parallel"                  % Prefix of the automatic tag.
        s_table  = "event"                     % Table the event contributes to.
    end

    methods
        function obj = EventOpenBranch(branch, time, opt)
        % Create a branch opening event (not in a scenario).
            arguments (Input)
                branch (:,1) string  % Tags of the branches (see string(net.a_Branch)).
                time   (1,1) double  % [s] Time of the opening.
                opt.Status (1,1) string {mustBeMember(opt.Status, ["6open","3open"])} = "6open"  % All circuits or one circuit.
            end
            arguments (Output)
                obj  % The new event.
            end
            obj.sv_branch = unique(branch, "stable");
            obj.r_time    = time;
            obj.s_status  = opt.Status;
        end
    end

    methods (Access={?Scenario, ?EventBase})
        tab = table_rows(obj)
    end
end
