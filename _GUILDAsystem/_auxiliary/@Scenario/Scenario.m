classdef (Sealed = true) Scenario < LayerPackage
% Simulation scenario: the time, the timed disturbances and a description of one time simulation.
%
% A scenario holds its disturbances in three tables, and the simulation time (Time,
% default [0, 10]) and a description. It holds data only, no function handles and no
% settings of the solver (GUILDA.setting, or the Name-Value options of net.simulate).
%
% - tab_event: faults and parallel events (trips, branch openings), one row per change of
%   the state of one target (Tag, Target, Time, Status, Point). add_fault, add_trip and
%   add_open_branch add two rows per target that share one tag: the start and the return
%   to "none" (fault) or "close" (parallel). The tags are Fault001, Fault002, ... and
%   Parallel001, ...; they are given by the scenario, not by the user.
% - tab_offset: offsets of the states at one time (add_offset; Tag, TimeSpan, OffsetUnit,
%   OffsetState, OffsetValue).
% - tab_input: inputs added to a component over a time span (add_input; Tag, TimeSpan,
%   InputUnit, InputName, InputValue, InputMethod).
%
% add_disturbance adds an offset and an input with one tag (one row in each table).
% remove_disturbance(tag) removes all rows of the tag from the three tables.
%
% A scenario is a child of one network: `sc = net.add_scenario(tag)` creates it
% (net.a_Scenario, sc.a_PowerNetwork) and `net.remove_scenario(tag)` deletes it. Its tag
% shares the name space of the buses, branches and global controllers of the network: a
% tag in use gets a number suffix (LayerPackage). `net.add_scenario(tag, From=sc)` copies
% the disturbances and settings of another scenario, of this or another network.
% Disturbances refer to buses, branches, components and controllers by tag. The tags are
% checked when a disturbance is added, and again at the start of each simulation against
% the network as it is then. Scenarios are not model data: adding, renaming, editing or
% removing them makes nothing stale (log_edit does nothing).
%
% Run it by its tag with `net.simulate(tag)` (over Time) or `net.simulate(tag, Time=[t0,
% tend], Name=Value)`: the simulation is split into phases where the state of the
% disturbances does not change.
%
% Events:
%
% | Kind | Tag | Target | Status (start, end) | Point |
% |---|---|---|---|---|
% | fault | Fault<n> | bus | "BG", "none" | NaN |
% | fault | Fault<n> | branch | "3LG" (one circuit) or "6LG" (all circuits), "none" | 0 < Point < 1 |
% | parallel | Parallel<n> | component, global or local controller | "open", "close" | NaN |
% | parallel | Parallel<n> | branch | "3open" (one circuit) or "6open" (all circuits), "close" | NaN |
%
% - The state of a target at time t is the Status of its last row with Time <= t; faults
%   and parallel events are counted apart. Without rows a target is not faulted ("none")
%   and connected ("close"). At one time the end of one event is applied before the start
%   of the next, so two events of one target may touch ([1 2] and [2 3]); two faults, or
%   two parallel events, of one target that overlap are an error
%   (GUILDA:Scenario:OverlappingEvents).
% - Point is the position of a branch fault from the from end (0) to the to end (1). A
%   fault at an end of a branch is a fault of the bus (add_fault(bus, ...)).
% - An end at or after the end of the simulation (Inf too) keeps the state to the end of
%   the run: the rows stay in the table, and Time of a later run may reach them.
% - A branch opened with "6open" is left out of the bus admittance matrix and reconnected
%   at the end; opening branches so that a part of the network is left without any
%   component is an error (GUILDA:PowerNetwork:OpenBranchIsland). A part with components
%   is simulated as an island; a constant-power load cut off from all generators usually
%   makes the phase fail (flag = -1).
% - Branch faults, "3open" and trips of local controllers are recorded but cannot be
%   simulated yet (GUILDA:Scenario:NotYetSupported).
%
% Offsets and inputs:
%
% - An offset applies at its time (TimeSpan t_start). An input lasts from t_start to t_end
%   (TimeSpan [t_start, t_end], t_start < t_end).
% - An input value is a constant (one number per input name, or one for all) or a time
%   series [t, v_1, ..., v_n] (or a table with the variables Time and the input names), t
%   from t_start, starting at 0 and increasing. The series is interpolated by InputMethod:
%   "zoh" (hold the last point), "foh" (linear, the default) or "spline"; after its last
%   point it keeps the last value. A "zoh" series with many points makes the run slower.
% - Offsets and inputs on the same unit are summed over the active disturbances.
%
% The tag of a disturbance names its column in output.phases. It is unique within the
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
% sc.add_fault("B008", [0.10, 0.17]);             % Fault001
% sc.add_open_branch("EL003", [0.17, 20]);        % Parallel001
% [result, flag] = net.simulate("case1", Progress="none");
% sc.tab_event                                    % four rows
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
% See also PowerNetwork.add_scenario, PowerNetwork.remove_scenario, PowerNetwork.simulate, ResultODE

    properties (SetAccess=private) % Layer Structure
        a_PowerNetwork                                       % Network the scenario belongs to (set by net.add_scenario; never empty). <@Type> PowerNetwork
    end

    properties (SetAccess=private) % Disturbances
        tab_event  table = table()                           % Fault and parallel events (Tag, Target, Time, Status, Point), in the order added. <@Type> table (n x 5)
        tab_input  table = table()                           % Input signals over time, one row each (Tag, TimeSpan, InputUnit, InputName, InputValue, InputMethod). <@Type> table (n x 6)
        tab_offset table = table()                           % Offsets of the initial states, one row each (Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue). <@Type> table (n x 5)
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

    properties (Constant, Hidden) % Disturbance fields
        sr_field = ["OffsetUnit","OffsetState","OffsetValue","InputUnit","InputName","InputValue","InputMethod"]    % Offset and input fields of add_disturbance, in the column order of tab_offset and tab_input (after Tag and TimeSpan).
    end

    methods (Access={?PowerNetwork})
        function obj = Scenario(net, s_tag)
        % Create an empty scenario of net (net.add_scenario).
        %
        % The parent is set before the tag, so that a tag in use among the children of net
        % gets a number suffix.
            arguments (Input)
                net PowerNetwork   % Parent network.
                s_tag (1,1) string % Tag (renamed with a number when a child of net has it).
            end
            arguments (Output)
                obj % New scenario without disturbances.
            end
            obj.a_PowerNetwork  = net;
            [obj.tab_event, obj.tab_offset, obj.tab_input] = empty_disturbances();
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

        s_tag = add_disturbance(obj, tag, opt)
        s_tag = add_fault(obj, target, time, opt)
        s_tag = add_trip(obj, unit, time)
        s_tag = add_open_branch(obj, branch, time, opt)
        s_tag = add_offset(obj, unit, state, value, time, opt)
        s_tag = add_input(obj, unit, name, value, time, opt)
        remove_disturbance(obj, tag)
    end

    methods (Access=protected)
        log_edit(obj, log, tag)
        sct_page = gui_content(obj)
    end

    methods (Access={?PowerNetwork, ?Scenario})
        validate(obj)
        add_events(obj, tab)                % Rows of tab_event (add_fault, add_trip, add_open_branch, JSON, add_scenario From).
        s_tag = add_record(obj, d, s_kind)  % Offset and input rows of one tag (add_offset, add_input, add_disturbance, JSON, add_scenario From).
    end

    methods (Access={?PowerNetwork})
        [tab_phase, sct_event] = compile(obj, sct_dae, time)
        sct = to_json_struct(obj)       % Content of scenario/<tag>.json (net.export).
        add_from_json_struct(obj, sct)  % Time, Description and disturbances from scenario/<tag>.json (PowerNetwork.import).
    end
end
