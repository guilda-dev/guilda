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
        % Tag of the scenario, unique among the scenarios of its network.
        % <@Type> string
        str_tag (1,1) string = ""
    end

    properties (SetAccess=private) % Layer Structure
        % PowerNetwork the scenario belongs to; empty when it is not attached.
        % Set by net.add_scenario and cleared by net.remove_scenario.
        % <@Type> PowerNetwork (1x1 or empty)
        a_PowerNetwork = []
    end

    properties (SetAccess=private) % Disturbances
        % Disturbances, one row each, in the order they were added.
        % Columns: Tag, TimeSpan ([t_start, t_end]; t_end = t_start for an offset), FaultBus,
        % TripUnit, OpenBranch, OffsetUnit, OffsetState, OffsetValue, InputUnit, InputName,
        % InputValue. The list columns are cells of column vectors. Add rows with
        % add_disturbance or add_fault, add_trip, add_open_branch, add_offset, add_input.
        % <@Type> table (n x 11)
        tab_disturbance table = table()
    end

    properties (Access=public) % Settings
        % [s] Simulation time [t0, tend] used by net.simulate(sc), or [] for the time span of
        % the disturbances. A time given to net.simulate replaces it.
        % <@Type> double (0x0 or 1x2)
        Time double {mustBeSimulationTime} = []

        % Stored Name-Value options of net.simulate, as a struct (e.g.
        % struct("Tolerance", 1e-6)). The options given in the call replace them. The names are
        % those of SolverODE.OptionMap and Export.
        Options (1,1) struct = struct()

        % Function that judges a result: verdict = Judge(result), result a ResultODE (with
        % result.flag and result.output). Default: Scenario.out_of_step with its default
        % options. Used by judge.
        Judge (1,1) function_handle = @Scenario.out_of_step

        % Free text describing the scenario.
        Description (1,1) string = ""
    end

    properties (Hidden) % Compatibility
        % True for a scenario made by the deprecated ODEevent(tag, net, ...) (set by _VersionSupport/ODEevent.m).
        l_compat (1,1) logical = false
    end

    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 2.0 % Version of this class (1.x: ODEevent).
    end

    properties (Constant, Hidden) % Disturbance fields
        % Disturbance fields, in the column order of tab_disturbance (after Tag and TimeSpan).
        sv_field = ["FaultBus","TripUnit","OpenBranch","OffsetUnit","OffsetState","OffsetValue", ...
                    "InputUnit","InputName","InputValue"]
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
            obj.str_tag = tag;
            obj.tab_disturbance = empty_disturbances();
            for str_name = string(fieldnames(opt)).'
                obj.(str_name) = opt.(str_name);
            end
        end

        function set.Options(obj, s)
            sv_ok = [string(fieldnames(SolverODE.OptionMap)); "Export"];
            for str_name = string(fieldnames(s)).'
                if ~any(strcmpi(str_name, sv_ok))
                    error(msg("GUILDA:Scenario:UnknownOption", char(obj.str_tag), char(str_name), char(join(sv_ok, ", "))));
                end
            end
            obj.Options = s;
        end

        function str_tag = add_disturbance(obj, tag, opt)
        % Add a disturbance given by any of the disturbance fields.
        %
        % The general form, with the fields of the deprecated ODEevent: one disturbance may
        % combine a fault, a trip, a branch opening, an offset and an input with one time
        % span. When the scenario is attached to a network, the tags are checked against it
        % now; otherwise when the scenario is added to a network. The checks are those of the
        % simulation: unknown tags, states and inputs, a TimeSpan without duration for a
        % lasting disturbance, value counts and the number of arguments of input functions.
        % Nothing is added when a check fails.
        %
        % <@Examples>
        % ```matlab
        % sc.add_disturbance("fault+open", TimeSpan=[1, 1.05], FaultBus="B008", OpenBranch="EL003");
        % ```
            arguments (Input)
                obj
                tag (1,1) string % Tag of the disturbance, unique in the scenario (the column of output.phases).
                opt.TimeSpan {mustBeRow, validateTimeSpanSize} = [0,10] % [s] [t_start, t_end], or t_start alone for an offset only.
                opt.FaultBus    (:,1) string = strings(0,1) % Tags of the buses with a ground fault (voltage 0).
                opt.TripUnit    (:,1) string = strings(0,1) % Tags of the components or global controllers disconnected.
                opt.OpenBranch  (:,1) string = strings(0,1) % Tags of the branches left out of the network (reconnected at t_end).
                opt.OffsetUnit  (1,1) string = ""           % Tag of the component whose initial states are offset at t_start.
                opt.OffsetState (:,1) string = strings(0,1) % Names of the states to offset (e.g. "delta").
                opt.OffsetValue (:,1) double = zeros(0,1)   % Offsets of OffsetState, one per name or one for all.
                opt.InputUnit   (1,1) string = ""           % Tag of the component to which an input is added.
                opt.InputName   (:,1) string = strings(0,1) % Names of the inputs of InputUnit (e.g. "Pmech").
                opt.InputValue  (:,1) {mustBeA(opt.InputValue, {'double','cell','function_handle'})} = zeros(0,1) % Values added to InputName: numbers, or a cell of numbers and functions f(t) of the time since t_start.
            end
            arguments (Output)
                str_tag (1,1) string % Tag of the added disturbance.
            end
            d = opt;
            d.Tag = tag;
            str_tag = obj.add_record(d, "");
        end

        function str_tag = add_fault(obj, bus, time, opt)
        % Add a ground fault (voltage 0) on buses from t_start to t_end.
        %
        % <@Examples>
        % ```matlab
        % sc.add_fault("B008", [0.10, 0.17]);           % tag "fault1"
        % ```
            arguments (Input)
                obj
                bus  (:,1) string % Tags of the faulted buses.
                time (1,2) double % [s] [t_start, t_end] of the fault.
                opt.Tag (1,1) string = "" % Tag of the disturbance; default fault<n>.
            end
            arguments (Output)
                str_tag (1,1) string % Tag of the added disturbance.
            end
            d = blank_record(opt.Tag, time);
            d.FaultBus = bus;
            str_tag = obj.add_record(d, "fault");
        end

        function str_tag = add_trip(obj, unit, time, opt)
        % Add a trip of components or global controllers from t_start to t_end.
        %
        % A tripped unit is disconnected (its states are NaN in the result) and reconnected at
        % t_end. A local controller cannot be tripped.
            arguments (Input)
                obj
                unit (:,1) string % Tags of the components or global controllers.
                time (1,2) double % [s] [t_start, t_end] of the trip.
                opt.Tag (1,1) string = "" % Tag of the disturbance; default trip<n>.
            end
            arguments (Output)
                str_tag (1,1) string % Tag of the added disturbance.
            end
            d = blank_record(opt.Tag, time);
            d.TripUnit = unit;
            str_tag = obj.add_record(d, "trip");
        end

        function str_tag = add_open_branch(obj, branch, time, opt)
        % Add the opening of branches from t_start to t_end.
        %
        % The branches are left out of the bus admittance matrix and reconnected at t_end; a
        % t_end at or after the end of the simulation keeps them open.
        %
        % <@Examples>
        % ```matlab
        % sc.add_open_branch(["EL003"; "EL004"], [0.17, 20]);   % open until the end
        % ```
            arguments (Input)
                obj
                branch (:,1) string % Tags of the branches (see string(net.a_Branch)).
                time   (1,2) double % [s] [t_start, t_end] of the opening.
                opt.Tag (1,1) string = "" % Tag of the disturbance; default open<n>.
            end
            arguments (Output)
                str_tag (1,1) string % Tag of the added disturbance.
            end
            d = blank_record(opt.Tag, time);
            d.OpenBranch = branch;
            str_tag = obj.add_record(d, "open");
        end

        function str_tag = add_offset(obj, unit, state, value, time, opt)
        % Add an offset of the states of a component at one time.
        %
        % The values are added to the states at time (to the initial states when time is the
        % start of the simulation).
        %
        % <@Examples>
        % ```matlab
        % sc.add_offset("SG1B001", ["delta"; "omega"], [0.1; 0], 0);
        % ```
            arguments (Input)
                obj
                unit  (1,1) string % Tag of the component.
                state (:,1) string % Names of the states (e.g. "delta").
                value (:,1) double % Offsets, one per state or one for all.
                time  (1,1) double = 0 % [s] Time of the offset.
                opt.Tag (1,1) string = "" % Tag of the disturbance; default offset<n>.
            end
            arguments (Output)
                str_tag (1,1) string % Tag of the added disturbance.
            end
            d = blank_record(opt.Tag, time);
            d.OffsetUnit  = unit;
            d.OffsetState = state;
            d.OffsetValue = value;
            str_tag = obj.add_record(d, "offset");
        end

        function str_tag = add_input(obj, unit, name, value, time, opt)
        % Add values to inputs of a component from t_start to t_end.
        %
        % A value is a number or a function f(t) of the time since t_start; several inputs take
        % a vector of numbers or a cell of numbers and functions.
        %
        % <@Examples>
        % ```matlab
        % sc.add_input("SG1B002", ["Pmech"; "Vfield"], {0.05; @(t) 0.01*t}, [1, 1.5]);
        % ```
            arguments (Input)
                obj
                unit  (1,1) string % Tag of the component.
                name  (:,1) string % Names of the inputs (e.g. "Pmech", "Vfield").
                value (:,1) {mustBeA(value, {'double','cell','function_handle'})} % Values, one per input or one for all.
                time  (1,2) double % [s] [t_start, t_end] of the input.
                opt.Tag (1,1) string = "" % Tag of the disturbance; default input<n>.
            end
            arguments (Output)
                str_tag (1,1) string % Tag of the added disturbance.
            end
            d = blank_record(opt.Tag, time);
            d.InputUnit  = unit;
            d.InputName  = name;
            d.InputValue = value;
            str_tag = obj.add_record(d, "input");
        end

        function remove_disturbance(obj, tag)
        % Remove disturbances by tag.
            arguments (Input)
                obj
                tag (:,1) string % Tags of the disturbances to remove.
            end
            lv_bad = ~ismember(tag, obj.tab_disturbance.Tag);
            if any(lv_bad)
                error(msg("GUILDA:Scenario:DisturbanceNotFound", char(join(tag(lv_bad), ", ")), char(obj.str_tag)));
            end
            obj.tab_disturbance = obj.tab_disturbance(~ismember(obj.tab_disturbance.Tag, tag), :);
        end

        function verdict = judge(obj, result)
        % Judge a simulation result with the Judge function of the scenario.
        %
        % Returns Judge(result). With the default Judge (Scenario.out_of_step) the verdict is a
        % struct with Verdict ("stable", "out-of-step" or "incomplete"), Time, Units,
        % MaxAngle, Reference and Threshold. net.simulate does not judge: call this method on
        % its result.
        %
        % <@Examples>
        % ```matlab
        % result  = net.simulate(sc);
        % verdict = sc.judge(result);
        % sc.Judge = @(r) Scenario.out_of_step(r, Reference="COI", Threshold=180);
        % ```
            arguments (Input)
                obj
                result (1,1) ResultODE % Result of net.simulate.
            end
            arguments (Output)
                verdict % Output of Judge (a struct for Scenario.out_of_step).
            end
            verdict = obj.Judge(result);
        end

        function sc = copy(obj)
        % Return an unattached duplicate of the scenario.
        %
        % The duplicate has the same tag, disturbances, Time, Options, Judge and
        % Description, and no network: add it to another network with net.add_scenario.
            arguments (Input)
                obj
            end
            arguments (Output)
                sc % New Scenario, not attached to a network.
            end
            sc = Scenario(obj.str_tag, Time=obj.Time, Options=obj.Options, Judge=obj.Judge, ...
                          Description=obj.Description);
            sc.tab_disturbance = obj.tab_disturbance;
        end
    end

    methods (Static)
        verdict = out_of_step(result, opt)
        c_scenario = import_csv(path, opt)
        path = export_csv(path, scenarios, opt)
    end

    methods (Hidden)
        function str = string(obj)
        % Tag of the scenario.
            arguments (Input)
                obj
            end
            arguments (Output)
                str % Tag string.
            end
            str = obj.str_tag;
        end
    end

    methods (Access={?PowerNetwork})
        function set_parent(obj, net)
            % Called by net.add_scenario / net.remove_scenario only ([] detaches).
            arguments (Input)
                obj
                net % Network the scenario belongs to, or [] to detach it.
            end
            obj.a_PowerNetwork = net;
        end
    end

    methods (Access={?PowerNetwork, ?SolverODE, ?Scenario})
        function validate(obj, net)
            % Check every disturbance against the network net as it is now.
            arguments (Input)
                obj
                net % Network to check against ([] checks only what needs no network).
            end
            for k = 1:height(obj.tab_disturbance)
                validate_disturbance(get_record(obj.tab_disturbance, k), obj.str_tag, net);
            end
        end
    end

    methods (Static, Access={?SolverODE})
        [tab_phase, s_phase] = compile(c_scenario, net, time)
    end

    methods (Access=private)
        function str_tag = add_record(obj, d, str_kind)
            % Add the disturbance record d; an empty tag takes <str_kind><n>.
            arguments (Input)
                obj
                d        % Disturbance record (struct with the fields of add_disturbance).
                str_kind % Prefix of the automatic tag ("" keeps the tag as given).
            end
            arguments (Output)
                str_tag  % Tag of the added disturbance.
            end
            if strlength(d.Tag) == 0 && ~ismissing(d.Tag) && str_kind ~= ""
                d.Tag = next_tag(obj.tab_disturbance.Tag, str_kind);
            end
            check_tag(d.Tag, obj.str_tag, obj.tab_disturbance.Tag);
            validate_disturbance(d, obj.str_tag, obj.a_PowerNetwork);
            obj.tab_disturbance = [obj.tab_disturbance; record_row(d)];
            str_tag = d.Tag;
        end
    end

    methods (Static, Access=private)
        % Helpers shared with the method files (compile, import_csv, export_csv)
        function d = record(tab, k),               d = get_record(tab, k);              end
        function d = blank(tag, time),             d = blank_record(tag, time);         end
        function tab = empty_table(),              tab = empty_disturbances();          end
        function check(d, str_scenario, net),      validate_disturbance(d, str_scenario, net); end
    end

    methods (Access={?Scenario})
        function str_tag = add_checked(obj, d)
            % Add a record read from a file (import_csv); "" takes event<n>.
            arguments (Input)
                obj
                d       % Disturbance record (struct with the fields of add_disturbance).
            end
            arguments (Output)
                str_tag % Tag of the added disturbance.
            end
            str_tag = obj.add_record(d, "event");
        end
    end
end


function tab = empty_disturbances()
% Disturbance table without rows
    tab = table(strings(0,1), zeros(0,2), cell(0,1), cell(0,1), cell(0,1), strings(0,1), ...
                cell(0,1), cell(0,1), strings(0,1), cell(0,1), cell(0,1), ...
                'VariableNames', ["Tag","TimeSpan","FaultBus","TripUnit","OpenBranch","OffsetUnit", ...
                                  "OffsetState","OffsetValue","InputUnit","InputName","InputValue"]);
end

function d = blank_record(tag, time)
% Disturbance record with only a tag and a time span
    d = struct();
    d.Tag         = string(tag);
    d.TimeSpan    = time;
    d.FaultBus    = strings(0,1);
    d.TripUnit    = strings(0,1);
    d.OpenBranch  = strings(0,1);
    d.OffsetUnit  = "";
    d.OffsetState = strings(0,1);
    d.OffsetValue = zeros(0,1);
    d.InputUnit   = "";
    d.InputName   = strings(0,1);
    d.InputValue  = zeros(0,1);
end

function row = record_row(d)
% One table row from a disturbance record
    ts = d.TimeSpan;
    if isscalar(ts)
        ts = [ts, ts];
    end
    row = table(d.Tag, ts, {d.FaultBus}, {d.TripUnit}, {d.OpenBranch}, d.OffsetUnit, ...
                {d.OffsetState}, {d.OffsetValue}, d.InputUnit, {d.InputName}, {d.InputValue}, ...
                'VariableNames', ["Tag","TimeSpan","FaultBus","TripUnit","OpenBranch","OffsetUnit", ...
                                  "OffsetState","OffsetValue","InputUnit","InputName","InputValue"]);
end

function d = get_record(tab, k)
% Disturbance record of row k (the fields of add_disturbance)
    d = struct();
    d.Tag         = tab.Tag(k);
    d.TimeSpan    = tab.TimeSpan(k,:);
    d.FaultBus    = tab.FaultBus{k};
    d.TripUnit    = tab.TripUnit{k};
    d.OpenBranch  = tab.OpenBranch{k};
    d.OffsetUnit  = tab.OffsetUnit(k);
    d.OffsetState = tab.OffsetState{k};
    d.OffsetValue = tab.OffsetValue{k};
    d.InputUnit   = tab.InputUnit(k);
    d.InputName   = tab.InputName{k};
    d.InputValue  = tab.InputValue{k};
end

function str_tag = next_tag(sv_tag, str_kind)
% <str_kind><n> with n the largest number in use with this prefix plus one
    sv_num = extractAfter(sv_tag(startsWith(sv_tag, str_kind)), strlength(str_kind));
    rv_num = str2double(sv_num(matches(sv_num, digitsPattern)));
    n = max([0; rv_num(:)]) + 1;
    str_tag = str_kind + n;
end

function check_tag(str_tag, str_scenario, sv_tag)
% Tags name the columns of the phase table: unique and not reserved
    if ismissing(str_tag) || ismember(str_tag, ["t1","t2","Properties","Row","Variables",""]) ...
            || matches(str_tag, "NoAction" + digitsPattern)
        error(msg("GUILDA:Scenario:ReservedTag", char(string(str_tag)), char(str_scenario)));
    end
    if ismember(str_tag, sv_tag)
        error(msg("GUILDA:Scenario:DuplicateTag", char(str_tag), char(str_scenario)));
    end
end

function validate_disturbance(d, str_scenario, net)
% Checks of one disturbance; with net = [] (scenario not attached), those without the network.
    c_lbl = {char(d.Tag), char(str_scenario)};
    ts = d.TimeSpan;
    if ~isnumeric(ts) || ~isreal(ts) || any(isnan(ts)) || (numel(ts) == 2 && ts(1) > ts(2))
        str_ts = class(ts);
        if isnumeric(ts)
            str_ts = mat2str(ts);
        end
        error(msg("GUILDA:Scenario:InvalidTimeSpan", c_lbl{:}, str_ts));
    end

    % A fault, trip, opening or input needs its end time; only an offset acts at one instant.
    l_lasting = ~isempty(d.FaultBus) || ~isempty(d.TripUnit) || ~isempty(d.OpenBranch) ...
        || strlength(d.InputUnit) > 0 ...
        || ~isempty(d.InputName) || ~isempty(d.InputValue);
    if l_lasting && (isscalar(ts) || ts(1) == ts(2))
        error(msg("GUILDA:Scenario:ZeroLengthTimeSpan", c_lbl{:}, mat2str(ts)));
    end

    l_net = ~isempty(net);
    if l_net
        str_net = char(net.str_tag);
        a_bus  = net.a_Bus;
        sv_bus = string(cellfun(@(b) b.str_tag, a_bus, 'UniformOutput', false));
        lv_bad = ~ismember(d.FaultBus, sv_bus);
        if any(lv_bad)
            error(msg("GUILDA:Scenario:UnknownFaultBus", c_lbl{:}, char(join(d.FaultBus(lv_bad), ", ")), str_net));
        end

        sv_br  = string(net.a_Branch);
        lv_bad = ~ismember(d.OpenBranch, sv_br);
        if any(lv_bad)
            error(msg("GUILDA:Scenario:UnknownOpenBranch", c_lbl{:}, char(join(d.OpenBranch(lv_bad), ", ")), str_net));
        end

        a_comp = cellfun(@(b) b.a_Component, a_bus, 'UniformOutput', false);
        a_comp = vertcat(cell(0,1), a_comp{:});
        sv_tag = string(cellfun(@(c) c.str_tag, a_comp, 'UniformOutput', false));

        sv_gc  = string(cellfun(@(g) g.str_tag, net.a_GlobalController, 'UniformOutput', false));
        lv_bad = ~ismember(d.TripUnit, [sv_tag(:); sv_gc(:)]);
        if any(lv_bad)
            error(msg("GUILDA:Scenario:UnknownTripUnit", c_lbl{:}, char(join(d.TripUnit(lv_bad), ", ")), str_net));
        end
    end

    if strlength(d.OffsetUnit) > 0 || ~isempty(d.OffsetState) || ~isempty(d.OffsetValue)
        if l_net
            lv_cmp = sv_tag == d.OffsetUnit;
            if ~any(lv_cmp)
                error(msg("GUILDA:Scenario:UnknownOffsetUnit", c_lbl{:}, char(d.OffsetUnit), str_net));
            end
            sv_x = string(a_comp{find(lv_cmp,1)}.sv_x(:));
            lv_bad = ~ismember(d.OffsetState, sv_x);
            if any(lv_bad)
                error(msg("GUILDA:Scenario:UnknownOffsetState", c_lbl{:}, ...
                        char(join(d.OffsetState(lv_bad), ", ")), char(d.OffsetUnit), char(join(sv_x, ", "))));
            end
        end
        checkValueCount(c_lbl, "OffsetValue", d.OffsetValue, "OffsetState", d.OffsetState);
    end

    if strlength(d.InputUnit) == 0 && isempty(d.InputName) && isempty(d.InputValue)
        return
    end
    if l_net
        lv_cmp = sv_tag == d.InputUnit;
        if ~any(lv_cmp)
            error(msg("GUILDA:Scenario:UnknownInputUnit", c_lbl{:}, char(d.InputUnit), str_net));
        end
        sv_u = string(a_comp{find(lv_cmp,1)}.sv_u(:));
        lv_bad = ~ismember(d.InputName, sv_u);
        if any(lv_bad)
            error(msg("GUILDA:Scenario:UnknownInputName", c_lbl{:}, ...
                    char(join(d.InputName(lv_bad), ", ")), char(d.InputUnit), char(join(sv_u, ", "))));
        end
    end
    checkValueCount(c_lbl, "InputValue", d.InputValue, "InputName", d.InputName);
    exV = d.InputValue;
    if ~iscell(exV)
        exV = {exV};
    end
    for k = 1:numel(exV)
        if isa(exV{k}, 'function_handle') && nargin(exV{k}) ~= 1
            error(msg("GUILDA:Scenario:InvalidNargin", c_lbl{:}));
        elseif ~isa(exV{k}, 'function_handle') && ~isa(exV{k}, 'double')
            error(msg("GUILDA:Scenario:InvalidInputType", c_lbl{:}, class(exV{k})));
        end
    end
end

function checkValueCount(c_lbl, str_value, values, str_name, names)
    % One value per name, or a single value for all the names
    if isempty(names) || ~(isscalar(values) || numel(values) == numel(names))
        error(msg("GUILDA:Scenario:ValueCountMismatch", c_lbl{:}, char(str_value), ...
                string(numel(values)), string(numel(names)), char(str_name)));
    end
end

function mustBeSimulationTime(time)
% [] or [t0, tend] with finite t0 < tend
    if isempty(time)
        return
    end
    if ~isreal(time) || numel(time) ~= 2 || ~all(isfinite(time)) || time(1) >= time(2)
        error(msg("GUILDA:Scenario:InvalidTime", mat2str(time)));
    end
end
