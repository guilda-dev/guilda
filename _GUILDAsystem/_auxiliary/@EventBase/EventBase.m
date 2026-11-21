classdef (Abstract) EventBase < auxiliary & matlab.mixin.Copyable
% Base class of the events of a Scenario: one fault, trip, branch opening, offset or input.
%
% An event is one disturbance of a scenario. Each subclass belongs to one add_* method of
% Scenario and takes the same arguments in its constructor:
%
% | Class | Scenario method | Table | Tag |
% |---|---|---|---|
% | EventFault | add_fault | tab_event | Fault<n> |
% | EventTrip | add_trip | tab_event | Parallel<n> |
% | EventOpenBranch | add_open_branch | tab_event | Parallel<n> |
% | EventOffset | add_offset | tab_offset | Tag, default offset<n> |
% | EventInput | add_input | tab_input | Tag, default input<n> |
%
% The add_* methods return the added event. Its properties are read-only: change them with
% `ev.edit(Name=Value)`, whose options are those of the add_* method. After an edit, the
% scenario checks all its events again (against its network); when a check fails, the
% event gets back its values and the error is thrown. An event not in a scenario is only
% checked by its arguments blocks.
%
% The constructors are public and need no network, so events can be made first and copied
% into a new scenario with `net.add_scenario(tag, Event={...})`. They are checked when they
% are added. The tables tab_event, tab_offset and tab_input of the scenario are built from
% its events (Scenario.a_Event).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% sc = net.add_scenario("case1", Time=[0, 20]);
% ev = sc.add_fault("B008", [0.10, 0.17]);        % EventFault, tag Fault001
% ev.edit(Time=[0.10, 0.20]);                     % sc.tab_event shows the new end
% sc2 = net.add_scenario("case2", Event={EventFault("B008", [0.1, 0.17]), EventOpenBranch("EL003", 0.17)});
% ```
%
% See also Scenario, PowerNetwork.add_scenario, EventFault, EventTrip, EventOpenBranch, EventOffset, EventInput

    properties (SetAccess={?Scenario, ?EventBase}) % Identity
        s_tag (1,1) string = ""     % Tag in the scenario (Fault<n>, Parallel<n>, or the tag of an offset or input); "" until the event is added. <@Type> string
    end

    properties (SetAccess={?Scenario, ?EventBase}) % Layer structure
        a_Scenario = []             % Scenario that holds the event ([] for an event not in a scenario). <@Type> Scenario
    end

    properties (Abstract, Constant, Hidden) % Kind
        s_prefix                    % Prefix of the automatic tag: "Fault", "Parallel", "offset" or "input".
        s_table                     % Table the event contributes to: "event", "offset" or "input".
    end

    methods (Abstract)
        % Change the event: the options of its add_* method, each optional (an option not
        % given keeps its value). The scenario of the event checks all its events again;
        % when a check fails, the event gets back its values and the error is thrown.
        edit(obj, opt)
    end

    methods (Abstract, Access={?Scenario, ?EventBase})
        % Rows of the event in its table (s_table), with the columns of that table.
        tab = table_rows(obj)
    end

    methods (Access=protected)
        cp = copyElement(obj)
        apply_edit(obj, sct)
    end
end
