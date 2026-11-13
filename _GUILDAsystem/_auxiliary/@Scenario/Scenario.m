classdef (Sealed = true) Scenario < LayerPackage
% Simulation scenario: the time, the timed disturbances and a description of one time simulation.
%
% A scenario holds a list of disturbances, each with its own time span: a bus fault
% (FaultBus), a unit trip (TripUnit), a branch opening (OpenBranch), an offset of the
% initial states (OffsetUnit, OffsetState, OffsetValue) or an input added to a component
% (InputUnit, InputName, InputValue, InputMethod). It also holds the simulation time
% (Time, default [0, 10]) and a description. It holds data only, no function handles and
% no settings of the solver (GUILDA.setting, or the Name-Value options of net.simulate).
%
% A scenario is a child of one network: `sc = net.add_scenario(tag)` creates it
% (net.a_Scenario, sc.a_PowerNetwork) and `net.remove_scenario(tag)` deletes it. Its tag
% shares the name space of the buses, branches and global controllers of the network: a
% tag in use gets a number suffix (LayerPackage). `net.add_scenario(tag, From=sc)` copies
% the disturbances and settings of another scenario, of this or another network.
% Disturbances refer to buses, branches and components by tag. The tags are checked when
% a disturbance is added, and again at the start of each simulation against the network as
% it is then. Scenarios are not model data: adding, renaming, editing or removing them makes
% nothing stale (log_edit does nothing).
%
% Run it by its tag with `net.simulate(tag)` (over Time) or `net.simulate(tag, Time=[t0,
% tend], Name=Value)`: the simulation is split into phases where the set of active
% disturbances does not change.
%
% Disturbances:
%
% - A fault, trip, branch opening or input lasts from t_start to t_end (TimeSpan
%   [t_start, t_end], t_start < t_end). An offset applies at t_start (TimeSpan t_start).
% - An opened branch is left out of the bus admittance matrix and is reconnected at t_end;
%   a t_end at or after the end of the simulation keeps it open. Opening branches so that a
%   part of the network is left without any component is an error
%   (GUILDA:PowerNetwork:OpenBranchIsland). A part with components is simulated as an island; a
%   constant-power load cut off from all generators usually makes the phase fail (flag = -1).
% - An input value is a constant (one number per input name, or one for all) or a time
%   series [t, v_1, ..., v_n] (or a table with the variables Time and the input names), t
%   from t_start, starting at 0 and increasing. The series is interpolated by InputMethod:
%   "zoh" (hold the last point), "foh" (linear, the default) or "spline"; after its last
%   point it keeps the last value. A "zoh" series with many points makes the run slower.
% - Offsets and inputs on the same unit are summed over the active disturbances.
% - The tag of a disturbance names its column in output.phases. It is unique within the
%   scenario and within one run; t1, t2, Properties, Row, Variables, an empty tag and
%   NoAction followed by digits are reserved.
%
% <@Examples>
% A fault on bus B008 for 70 ms, then the branch EL003 opened until the end:
%
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% sc = net.add_scenario("case1", Time=[0, 20], Description="fault B008, EL003 opened");
% sc.add_fault("B008", [0.10, 0.17]);
% sc.add_open_branch("EL003", [0.17, 20]);
% [result, flag] = net.simulate("case1", Progress="none");
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
        tab_disturbance table = table()                      % Disturbances, one row each, in the order they were added (see the class help). <@Type> table (n x 12)
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
        Ver (1,1) double = 3.0                               % Version of this class.
    end

    properties (Constant, Hidden) % Disturbance fields
        sr_field = ["FaultBus","TripUnit","OpenBranch","OffsetUnit","OffsetState","OffsetValue", ...
                    "InputUnit","InputName","InputValue","InputMethod"]    % Disturbance fields, in the column order of tab_disturbance (after Tag and TimeSpan).
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
            obj.tab_disturbance = empty_disturbances();
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
        s_tag = add_fault(obj, bus, time, opt)
        s_tag = add_trip(obj, unit, time, opt)
        s_tag = add_open_branch(obj, branch, time, opt)
        s_tag = add_offset(obj, unit, state, value, time, opt)
        s_tag = add_input(obj, unit, name, value, time, opt)
        remove_disturbance(obj, tag)
    end

    methods (Static)
        c_scenario = import_csv(path, opt)
        path = export_csv(path, scenarios, opt)
    end

    methods (Access=protected)
        log_edit(obj, log, tag)
        sct_page = gui_content(obj)
    end

    methods (Access={?PowerNetwork, ?Scenario})
        validate(obj)
    end

    methods (Access={?PowerNetwork})
        [tab_phase, sct_event] = compile(obj, sct_dae, time)
    end

    methods (Access=private)
        s_tag = add_record(obj, d, s_kind)
    end

    methods (Static, Access=private)
        d = record(tab, k)
        d = blank(tag, time)
        tab = empty_table()
        check(d, s_scenario, net)
        % The four above: helpers shared with the method files (compile, import_csv, export_csv)
    end

    methods (Access={?Scenario})
        s_tag = add_checked(obj, d)
    end
end
