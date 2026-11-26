classdef (Sealed = true) Scenario < auxiliary & LayerPackage
% Simulation scenario: the time, the timed disturbances and a description of one time simulation.
%
% A scenario holds its disturbances as events (a_Event, in the order added), and the
% simulation time (Time, default [0, 10]) and a description. It holds data only, no
% function handles and no settings of the solver (GUILDA.setting, or the Name-Value options
% of net.simulate).
%
% Each event is an object of a subclass of EventBase: add_fault (EventFault), add_trip
% (EventTrip), add_open_branch (EventOpenBranch), add_offset (EventOffset) and add_input
% (EventInput) add one and return it. Change an event with `ev.edit(Name=Value)` (the
% options of its add_* method): all events are checked again, and a failing edit is
% undone. remove_event(tag) removes events. The three tables are built from the events:
%
% - tab_event: faults and parallel events (trips, branch openings), one row per change of
%   the state of one target (Tag, Target, Time, Status, Point). A fault has two rows per
%   target that share its tag: the start and the return to "none". A trip or opening has
%   one row per target: it lasts to the end of the simulation. The tags are Fault001,
%   Fault002, ... and Parallel001, ...; they are given by the scenario, not by the user.
% - tab_offset: offsets of the states at one time (Tag, TimeSpan, OffsetUnit, OffsetState,
%   OffsetValue).
% - tab_input: inputs added to a component over a time span (Tag, TimeSpan, InputUnit,
%   InputName, InputValue, InputMethod).
%
% A scenario is a child of one network: `sc = net.add_scenario(tag)` creates it
% (net.a_Scenario, sc.a_PowerNetwork) and `net.remove_scenario(tag)` deletes it. Its tag
% shares the name space of the buses, branches and global controllers of the network: a
% tag in use gets a number suffix (LayerPackage). `net.add_scenario(tag, From=sc)` copies
% the events and settings of another scenario, of this or another network, and
% `net.add_scenario(tag, Event={...})` copies events made with their constructors.
% Events refer to buses, branches, components and controllers by tag. All events are
% checked when an event is added or edited, and again at the start of each simulation against
% the network as it is then. Scenarios are not model data: adding, renaming, editing or
% removing them makes nothing stale (log_edit does nothing).
%
% Run it by its tag with `net.simulate(tag)` (over Time) or `net.simulate(tag, Time=[t0,
% tend], Name=Value)`: the simulation is split into phases where the state of the
% disturbances does not change.
%
% Events:
%
% | Kind | Tag | Target | Status | Point |
% |---|---|---|---|---|
% | fault | Fault<n> | bus | "BG", then "none" at the end | NaN |
% | fault | Fault<n> | branch | "3LG" (one circuit) or "6LG" (all circuits), then "none" | 0 < Point < 1 |
% | parallel | Parallel<n> | component, global or local controller | "open" | NaN |
% | parallel | Parallel<n> | branch | "3open" (one circuit) or "6open" (all circuits) | NaN |
%
% - The state of a target at time t is the Status of its last row with Time <= t; faults
%   and parallel events are counted apart. Without rows a target is not faulted ("none")
%   and connected. At one time the end of one fault is applied before the start of the
%   next, so two faults of one target may touch ([1 2] and [2 3]); two faults of one
%   target that overlap, and two parallel events of one target, are an error
%   (GUILDA:Scenario:OverlappingEvents).
% - Point is the position of a branch fault from the from end (0) to the to end (1). A
%   fault at an end of a branch is a fault of the bus (add_fault(bus, ...)).
% - A fault end at or after the end of the simulation (Inf too) keeps the state to the
%   end of the run: the rows stay in the table, and Time of a later run may reach them.
% - The admittance matrix of each phase is net.get_admittance_matrix(BranchStatus=...) of
%   the branch states of the phase (the table of Branch.get_admittance_matrix: a branch
%   with a fault and an opening at once gets one combined matrix). A branch opened with
%   "6open" is left out of the matrix; a bus fault holds the bus voltage at 0. Opening
%   branches, or grounding all their circuits ("6LG"), so that a part of the network is
%   left without any component is an error (GUILDA:PowerNetwork:OpenBranchIsland). A part
%   with components is simulated as an island; a constant-power load cut off from all
%   generators usually makes the phase fail (flag = -1).
% - A tripped component, global controller or local controller has NaN states in the
%   result from its trip to the end of the run. An input whose source is tripped (the observed component, the local
%   controller that drives it, or a global controller) takes its equilibrium value, as if
%   the source were not connected; the other sources of the input stay. A tripped AVR thus
%   keeps the field voltage of the generator at its equilibrium; a loss of excitation is
%   modelled by an input, e.g. add_input(gen, "Vfield", -Vfield0, [t1, t2]). The local
%   controllers of a tripped local controller keep running.
%
% Offsets and inputs:
%
% - An offset applies at its time (TimeSpan t_start) to the states of a component, a local
%   controller or a global controller. An input acts on the inputs of a component and
%   lasts from t_start to t_end (TimeSpan [t_start, t_end], t_start < t_end).
% - An input value is a constant (one number per input name, or one for all) or a time
%   series [t, v_1, ..., v_n] (or a table with the variables Time and the input names), t
%   from t_start, starting at 0 and increasing. The series is interpolated by InputMethod:
%   "zoh" (hold the last point), "foh" (linear, the default) or "spline"; after its last
%   point it keeps the last value. A "zoh" series with many points makes the run slower.
% - Offsets and inputs on the same unit are summed over the active disturbances.
%
% The tag of an event names its column in output.phases. It is unique within the
% scenario; t1, t2, Properties, Row, Variables, an empty tag, NoAction followed by digits,
% and Fault or Parallel followed by digits are reserved for offsets and inputs.
%
% <@Examples>
% A fault on bus B008 for 70 ms, then the branch EL003 opened until the end:
%
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% sc = net.add_scenario("case1", Time=[0, 20], Description="fault B008, EL003 opened");
% ev = sc.add_fault("B008", [0.10, 0.17]);        % EventFault, tag Fault001
% sc.add_open_branch("EL003", 0.17);              % Parallel001
% [result, flag] = net.simulate("case1", Progress="none");
% sc.tab_event                                    % three rows
% ev.edit(Time=[0.10, 0.20]);                     % a longer fault
% sc.remove_event(ev.s_tag);
% ```
%
% One circuit of the branch EL003 grounded at 30 % from its from end, then that circuit
% opened (EL003 has the default 2 circuits):
%
% ```matlab
% sc3 = net.add_scenario("case3", Time=[0, 20]);
% sc3.add_fault("EL003", [0.10, 0.17], Status="3LG", Point=0.3);   % Fault001
% sc3.add_open_branch("EL003", 0.17, Status="3open");              % Parallel001
% [result, flag] = net.simulate("case3", Progress="none");
% ```
%
% A trip of the AVR of a generator: the field voltage stays at its equilibrium. A loss of
% excitation is an input that cancels it:
%
% ```matlab
% net68 = network.IEEE68bus();
% gen = net68.a_Bus{1}.a_Component{1};
% sc4 = net68.add_scenario("avr", Time=[0, 10]);
% sc4.add_trip(gen.avr.s_tag, 1);                                % the AVR
% Vfield0 = gen.rv_Uequilibrium(gen.sv_u == "Vfield");
% sc4.add_input(gen.s_tag, "Vfield", -Vfield0, [1, 10]);          % field voltage 0
% ```
%
% Other disturbances, and a copy for another network:
%
% ```matlab
% sc2 = net.add_scenario("steps");
% sc2.add_offset("B001SG1", "delta", 0.1, 0);
% sc2.add_input("B002SG1", "Pmech", [0, 0; 0.5, 0.005], [1, 1.5]);   % ramp, then held
% result = net.simulate(sc2.s_tag);
% other = network.IEEE14bus();
% other.add_scenario("case1", From=sc);         % sc stays in net
% ```
%
% See also PowerNetwork.add_scenario, PowerNetwork.remove_scenario, PowerNetwork.simulate, ResultODE, EventBase

    properties (SetAccess=private) % Layer Structure
        a_PowerNetwork                                       % Network the scenario belongs to (set by net.add_scenario; never empty). <@Type> PowerNetwork
    end

    properties (SetAccess=private) % Events
        a_Event (:,1) cell = cell(0,1)                       % Events of the scenario, in the order added (EventFault, EventTrip, EventOpenBranch, EventOffset, EventInput). <@Type> EventBase
    end

    properties (Dependent, SetAccess=private) % Disturbances
        tab_event                                            % Fault and parallel events (Tag, Target, Time, Status, Point), in the order added. <@Type> table (n x 5)
        tab_input                                            % Input signals over time, one row each (Tag, TimeSpan, InputUnit, InputName, InputValue, InputMethod). <@Type> table (n x 6)
        tab_offset                                           % Offsets of the initial states, one row each (Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue). <@Type> table (n x 5)
    end

    properties (Access=public) % Settings
        Time (1,2) double {mustBeSimulationTime} = [0, 10]   % [s] Simulation time [t0, tend] of net.simulate(tag); the Time option of the call replaces it for that call. <@Type> double (1x2)
        Description (1,1) string = ""                        % Free text describing the scenario.
    end

    properties (Dependent) % Parameter
        tab_parameter                                        % Empty table: a scenario has no parameters. <@Type> table
    end

    properties (Dependent, Access=protected) % Layer structure
        parent                                               % Parent in the layer structure: a_PowerNetwork.
        children                                             % Children in the layer structure: none.
    end

    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 4.0                               % Version of this class.
    end

    methods (Access={?PowerNetwork})
        function obj = Scenario(net, s_tag)
        % Create an empty scenario of net (net.add_scenario).
        %
        % The parent is set before the tag, so that a tag in use among the children of net
        % gets a number suffix.
            arguments (Input)
                net PowerNetwork    % Parent network.
                s_tag (1,1) string  % Tag (renamed with a number when a child of net has it).
            end
            arguments (Output)
                obj  % New scenario without disturbances.
            end
            obj.a_PowerNetwork  = net;
            obj.s_tag = s_tag;
        end
    end

    methods
        function tab = get.tab_parameter(~)
            tab = table();
        end
        function p = get.parent(obj)
            p = obj.a_PowerNetwork;
        end
        function p = get.children(~)
            p = cell(0,1);
        end
        function tab = get.tab_event(obj)
            [tab, ~, ~] = empty_disturbances();
            for k = 1:numel(obj.a_Event)
                if obj.a_Event{k}.s_table == "event"
                    tab = [tab; obj.a_Event{k}.table_rows()]; %#ok<AGROW>
                end
            end
        end
        function tab = get.tab_offset(obj)
            [~, tab, ~] = empty_disturbances();
            for k = 1:numel(obj.a_Event)
                if obj.a_Event{k}.s_table == "offset"
                    tab = [tab; obj.a_Event{k}.table_rows()]; %#ok<AGROW>
                end
            end
        end
        function tab = get.tab_input(obj)
            [~, ~, tab] = empty_disturbances();
            for k = 1:numel(obj.a_Event)
                if obj.a_Event{k}.s_table == "input"
                    tab = [tab; obj.a_Event{k}.table_rows()]; %#ok<AGROW>
                end
            end
        end

        ev = add_fault(obj, target, time, opt)
        ev = add_trip(obj, unit, time)
        ev = add_open_branch(obj, branch, time, opt)
        ev = add_offset(obj, unit, state, value, time, opt)
        ev = add_input(obj, unit, name, value, time, opt)
        remove_event(obj, tag)
    end

    methods (Access=protected)
        log_edit(obj, log, tag)
        sct_page = gui_content(obj)
    end

    methods (Access={?PowerNetwork, ?Scenario, ?EventBase})
        validate(obj)
    end

    methods (Access={?PowerNetwork, ?Scenario})
        insert_event(obj, ev, l_keepTag)    % Add an event with its tag (add_*, add_scenario Event and From, JSON).
    end

    methods (Access={?PowerNetwork})
        [tab_phase, sct_event] = compile(obj, sct_dae, time)
        sct = to_json_struct(obj)       % Content of scenario/<tag>.json (net.export).
        add_from_json_struct(obj, sct)  % Time, Description and events from scenario/<tag>.json (PowerNetwork.import).
    end
end
