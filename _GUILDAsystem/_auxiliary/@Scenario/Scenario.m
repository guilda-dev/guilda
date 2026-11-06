classdef (Sealed = true) Scenario < auxiliary
% Simulation scenario: the timed disturbances of one time simulation (net.simulate).
%
% A scenario holds a list of disturbances, each with its own time span: a bus fault
% (FaultBus), a unit trip (TripUnit), a branch opening (OpenBranch), an offset of the
% initial states (OffsetUnit, OffsetState, OffsetValue) or an input added to a component
% (InputUnit, InputName, InputValue). It may also hold the simulation time (Time), stored
% simulate options (Options), a description and a judge function (Judge) that turns a
% result into a verdict.
%
% A scenario belongs to at most one network: `net.add_scenario(sc)` attaches it
% (net.a_Scenario, sc.a_PowerNetwork) and `net.remove_scenario(tag)` detaches it. Its tag
% is unique among the scenarios of the network. Adding a scenario of another network moves
% it; `sc.copy()` gives an unattached duplicate for another network. Disturbances refer to
% buses, branches and components by tag. The tags are checked when a disturbance is added
% to an attached scenario, when the scenario is added to a network, and again at the start
% of each simulation against the network as it is then. Scenarios are not model data: adding,
% removing or editing them does not make the equilibrium of the network stale.
%
% Run it with `net.simulate(sc)` (the stored Time and Options) or
% `net.simulate(time, sc1, sc2, ..., Name=Value)`: the disturbances of all the given
% scenarios are combined, and the simulation is split into phases where the set of active
% disturbances does not change. `sc.judge(result)` applies Judge to the result.
%
% Disturbances:
%
% - A fault, trip, branch opening or input lasts from t_start to t_end (TimeSpan
%   [t_start, t_end], t_start < t_end). An offset applies at t_start (TimeSpan t_start).
% - An opened branch is left out of the bus admittance matrix and is reconnected at t_end;
%   a t_end at or after the end of the simulation keeps it open. Opening branches so that a
%   part of the network is left without any component is an error
%   (GUILDA:SolverODE:OpenBranchIsland). A part with components is simulated as an island; a
%   constant-power load cut off from all generators usually makes the phase fail (flag = -1).
% - Offsets and inputs on the same unit are summed over the active disturbances.
% - The tag of a disturbance names its column in output.phases. It is unique within the
%   scenario and within one run; t1, t2, Properties, Row, Variables, an empty tag and
%   NoAction followed by digits are reserved.
%
% CSV: `Scenario.import_csv(path, Network=net)` and `Scenario.export_csv(path, scenarios)`
% read and write several scenarios in one file, one row per disturbance (see import_csv).
%
% <@Examples>
% A fault on bus B008 for 70 ms, then the branch EL003 opened until the end:
%
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% sc = Scenario("case1", Time=[0, 20], Description="fault B008, EL003 opened");
% sc.add_fault("B008", [0.10, 0.17]);
% sc.add_open_branch("EL003", [0.17, 20]);
% net.add_scenario(sc);
% [result, flag] = net.simulate(sc, Progress="none");
% verdict = sc.judge(result);       % verdict.Verdict: "stable" | "out-of-step" | "incomplete"
% ```
%
% Other disturbances, several scenarios in one run, and a copy for another network:
%
% ```matlab
% sc2 = Scenario("steps");
% sc2.add_offset("SG1B001", "delta", 0.1, 0);
% sc2.add_input("SG1B002", ["Pmech"; "Vfield"], {0.05; @(t) 0.01*t}, [1, 1.5]);
% net.add_scenario(sc2);
% result = net.simulate([0, 10], sc, sc2);      % the disturbances of both
% sc3 = Scenario("trip");
% sc3.add_trip("SG1B002", [1, 2]);
% net.add_scenario(sc3);
% result = net.simulate([0, 10], sc3);
% other = network.IEEE14bus();
% other.add_scenario(sc.copy());                % sc stays in net
% ```
%
% See also PowerNetwork.add_scenario, PowerNetwork.simulate, ResultODE, SolverODE

    properties (SetAccess=private) % Identity
        s_tag (1,1) string = ""                              % Tag of the scenario, unique among the scenarios of its network. <@Type> string
    end

    properties (SetAccess={?PowerNetwork}) % Layer Structure
        a_PowerNetwork = []                                  % PowerNetwork the scenario belongs to (set by net.add_scenario; [] when not attached). <@Type> PowerNetwork (1x1 or empty)
    end

    properties (SetAccess=private) % Disturbances
        tab_disturbance table = table()                      % Disturbances, one row each, in the order they were added (see the class help). <@Type> table (n x 11)
    end

    properties (Access=public) % Settings
        Time double {mustBeSimulationTime} = []              % [s] Simulation time [t0, tend] of net.simulate(sc), or [] for the time span of the disturbances. <@Type> double (0x0 or 1x2)
        Options (1,1) struct = struct()                      % Stored Name-Value options of net.simulate, e.g. struct("Tolerance", 1e-6); options of the call replace them.
        Judge (1,1) function_handle = @Scenario.out_of_step  % Function verdict = Judge(result) used by judge, result a ResultODE.
        Description (1,1) string = ""                        % Free text describing the scenario.
    end

    properties (Hidden) % Compatibility
        l_compat (1,1) logical = false                       % True for a scenario made by the deprecated ODEevent(tag, net, ...) (set by _VersionSupport/ODEevent.m).
    end

    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 2.0                               % Version of this class (1.x: ODEevent).
    end

    properties (Constant, Hidden) % Disturbance fields
        sr_field = ["FaultBus","TripUnit","OpenBranch","OffsetUnit","OffsetState","OffsetValue", ...
                    "InputUnit","InputName","InputValue"]    % Disturbance fields, in the column order of tab_disturbance (after Tag and TimeSpan).
    end

    methods
        function obj = Scenario(tag, opt)
        % Create an empty scenario, not attached to a network.
        %
        % Add disturbances with add_fault, add_trip, add_open_branch, add_offset, add_input or
        % add_disturbance, then attach it with net.add_scenario(sc).
            arguments (Input)
                tag (1,1) string {mustBeNonzeroLengthText} % Tag of the scenario, unique among the scenarios of a network.
                opt.Time        % [s] Simulation time [t0, tend], or [] (see the property Time).
                opt.Options     % Stored Name-Value options of net.simulate (see the property Options).
                opt.Judge       % Judge function (see the property Judge).
                opt.Description % Free text.
            end
            arguments (Output)
                obj % New scenario without disturbances.
            end
            obj.s_tag = tag;
            obj.tab_disturbance = empty_disturbances();
            for s_name = string(fieldnames(opt)).'
                obj.(s_name) = opt.(s_name);
            end
        end

        function set.Options(obj, s)
            sv_ok = [string(fieldnames(SolverODE.OptionMap)); "Export"];
            for s_name = string(fieldnames(s)).'
                if ~any(strcmpi(s_name, sv_ok))
                    error(msg("GUILDA:Scenario:UnknownOption", char(obj.s_tag), char(s_name), char(join(sv_ok, ", "))));
                end
            end
            obj.Options = s;
        end

        s_tag = add_disturbance(obj, tag, opt)
        s_tag = add_fault(obj, bus, time, opt)
        s_tag = add_trip(obj, unit, time, opt)
        s_tag = add_open_branch(obj, branch, time, opt)
        s_tag = add_offset(obj, unit, state, value, time, opt)
        s_tag = add_input(obj, unit, name, value, time, opt)
        remove_disturbance(obj, tag)
        verdict = judge(obj, result)
        sc = copy(obj)
    end

    methods (Static)
        verdict = out_of_step(result, opt)
        c_scenario = import_csv(path, opt)
        path = export_csv(path, scenarios, opt)
    end

    methods (Hidden)
        str = string(obj)
    end

    methods (Access={?PowerNetwork, ?SolverODE, ?Scenario})
        validate(obj, net)
    end

    methods (Static, Access={?SolverODE})
        [tab_phase, sct_phase] = compile(c_scenario, net, time)
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
