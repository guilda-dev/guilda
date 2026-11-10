classdef PowerNetwork < PowerSystemModel
% Root of the model: holds the buses, branches and global controllers of one grid and runs the analyses.
%
% - Owns the topology (which buses, branches and global controllers exist), the system
%   base in `tab_parameter.base` (Hz, baseMVA) and the solver objects `solver_*`.
% - Every analysis starts here: the method reads its settings from a solver object, hands
%   the network to it and returns a result object.
% - Not where the numbers are: bus voltages belong to `Bus`, the model equations to
%   `Component` and the controllers, the numerical methods to the Solver classes.
% - Results are returned, never stored in the network. The one exception: `initialize`
%   writes the equilibrium into the buses, components and controllers.
% - Top of the object tree, with no parent. It is the parent of its buses, branches and
%   global controllers and the owner of its scenarios; only the network sets and clears
%   their back references (`Bus.a_PowerNetwork`, `Branch.a_PowerNetwork`, `Branch.a_Bus`,
%   `GlobalController.a_PowerNetwork`, `Scenario.a_PowerNetwork`).
% - Every edit is reported to the network's `handle_edit` (`LayerPackage.log_edit`), also
%   before the first initialize. It keeps at most one slack bus, and marks the stale tag
%   `powerflow` (`sct_stale`) for the edits that change the power flow: baseMVA, buses and
%   branches added, removed or replaced, bus parameters (powerflow, dynamics), the slack
%   bus, components connected, replaced or removed, branch dynamics and component
%   powerflow parameters. A Hz edit marks its stale tag `odefcn` (the function handles of
%   every model; the edit does not reach them). The components and controllers mark
%   their own stale tags.
% - `initialize` brings every layer up to date; the analyses only read the stale tags
%   they need and stop with their own error (GUILDA:SolverODE:Stale, SolverLIN:Stale,
%   SolverCPF:Stale, and the Stale errors of the get_sys of each layer), naming the
%   reasons, until it has run.
%
% A network is built by adding buses (`add_bus`) and branches (`add_branch`); the
% components (generators, loads, ...) are added to the buses (`Bus.add_component`) and
% local controllers to the components. The network runs the analyses:
%
% - power flow (`calculate_powerflow`) and optimal power flow (`optimize_powerflow`)
% - continuation power flow (`calculate_continuation_powerflow`)
% - equilibrium (`initialize`), time simulation (`simulate`) of the scenarios it holds
%   (`add_scenario`, `remove_scenario`, `a_Scenario`)
% - linearization and eigenvalue analysis (`linearize`, `get_sys`)
% - network diagrams (`draw_diagram`) and CSV / MATPOWER import and export
%
% Each analysis runs a solver object stored in a `solver_*` property; a subclass of the
% network may replace it with a subclass of the solver. `solver_PF` keeps no settings
% (they are in GUILDA.setting), only the warm start solution and the cache of the
% network; the other solvers hold stored defaults, kept between runs. Name-Value options
% of a call override the settings for that call only. Results are returned as result
% objects and never stored in the network or the solver.
%
% The scenarios (`a_Scenario`) are added by `add_scenario` and removed by
% `remove_scenario`; they are not model data and do not make the equilibrium stale.
%
% The parameters of the network (`tab_parameter.base`):
%
% - `Hz` [Hz]: nominal frequency. Models read it with get_Hz() and receive it as omega0.
%   Set by the constructor (GUILDA.config("Model","Hz")), by writing the table and by
%   import_csv. An edit marks the stale tag `odefcn` of the network: initialize only
%   rebuilds the function handles (each model compares the frequency it was built with).
% - `baseMVA` [MVA]: system base of all per-unit values (default 100). Stored per-unit
%   values are not converted when it changes. Set by the constructor, by writing the
%   table, import_csv and import_matpower. An edit makes the power flow stale.
%
% Power-flow settings are parameters of the buses (`tab_parameter.powerflow`: V, Varg)
% and the components (`tab_parameter.powerflow`: P, Q). OPF limits and costs are in
% `tab_parameter.operation` and `tab_parameter.OPF` of the buses, components and
% branches; user-defined costs and constraints are the options Cost and Constraint of
% `optimize_powerflow` (stored defaults in `solver_OPF`).
%
% <@Examples>
% ```matlab
% net = PowerNetwork("ThreeBus");
% net.add_bus(V=1.0, Varg=0);
% net.add_bus(V=1.0);
% net.add_bus();
% net.add_branch("pi", [1,2], R=0.010, X=0.085);
% net.add_branch("pi", [2,3], R=0.017, X=0.092);
% net.a_Bus{1}.add_component("gen-park", P=0.0);
% net.a_Bus{2}.add_component("gen-park", P=0.5);
% net.a_Bus{3}.add_component("load-power", P=-0.5, Q=0);
% net.a_Bus{1}.l_isSlack = true;
%
% res = net.calculate_powerflow();          % ResultPF
% net.initialize();                         % equilibrium for the dynamic analyses
% sc  = Scenario("fault", Time=[0,10]);
% sc.add_fault("B003", [1,1.05]);
% net.add_scenario(sc);
% sim = net.simulate(sc);                   % ResultODE
% res = net.get_sys();                      % ResultLIN: linear model in res.A, res.B, ...
% ```
%
% See also Bus, Branch, Component, GlobalController, Scenario, network.IEEE9bus

%% Properties

    properties(SetAccess=private) % Layer Structure
        a_Bus (:,1) cell = cell(0,1);               % Buses of the network, in the order of the bus index. <@Stale> powerflow
        a_Branch (:,1) cell = cell(0,1);            % Branches of the network. <@Stale> powerflow
        a_GlobalController (:,1) cell = cell(0,1);  % Global controllers of the network. <@Stale> equilibrium of the added controller
    end
    properties(SetAccess=private) % Scenarios
        a_Scenario (:,1) cell = cell(0,1);          % Simulation scenarios (Scenario), in the order added by add_scenario; not model data. <@Stale> nothing
    end
    properties(SetAccess=protected) % Solvers
        solver_PF SolverPF {mustBeScalarOrEmpty}    % Solver of calculate_powerflow (returns a ResultPF); keeps the warm start solution and the cache, no settings (GUILDA.setting). <@Type> SolverPF <@Stale> nothing
        solver_OPF SolverOPF {mustBeScalarOrEmpty}  % Solver of optimize_powerflow (returns a ResultOPF); stored defaults: Method, Solver, Display, MaxIteration, ... <@Type> SolverOPF <@Stale> nothing
        solver_CPF SolverCPF {mustBeScalarOrEmpty}  % Solver of calculate_continuation_powerflow (returns a ResultCPF); stored defaults: LoadBus, MaxIterations, StepSize, ... <@Type> SolverCPF <@Stale> nothing
        solver_ODE SolverODE {mustBeScalarOrEmpty}  % Solver of simulate (returns a ResultODE); stored defaults: Solver, RelativeTolerance, AbsoluteTolerance, Progress, TimeLimit, ... <@Type> SolverODE <@Stale> nothing
        solver_LIN SolverLIN {mustBeScalarOrEmpty}  % Solver of linearize and get_sys (returns a ResultLIN); stored defaults: Method, Point, Coordinate. <@Type> SolverLIN <@Stale> nothing
    end
    properties(SetAccess=private, GetAccess={?PowerNetwork,?SolverPF,?SolverOPF}) % Revisions
        n_revY (1,1) double = 0                     % Revision of the bus admittance matrix, increased by handle_edit (see there); compared by the caches of the solvers.
        n_revPF (1,1) double = 0                    % Revision of the power flow equations (every n_revY edit and the power flow settings), increased by handle_edit.
        n_revTopology (1,1) double = 0              % Revision of the topology (buses and branches added, removed or replaced), increased by handle_edit; discards the warm start.
    end
    properties(Dependent) % Steady State
        cv_Vequilibrium                             % [pu] Bus voltage phasors at the equilibrium, one per bus.
        cv_Iequilibrium                             % [pu] Bus current injections at the equilibrium, one per bus.
        rv_Xequilibrium                             % State equilibrium, in the order of the x rows of get_variable_map.
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent                                      % Parent in the layer structure: none (the network is the top).
        children                                    % Children in the layer structure: the buses, branches and global controllers, then the Parameter object.
    end

%% Constructor
    methods
        function obj = PowerNetwork(tag)
            % Create an empty network with the given tag.
            %
            % The nominal frequency is GUILDA.config("Model","Hz") and the system base is
            % 100 MVA (net.tab_parameter.base).
            arguments (Input)
                tag (1,1) string = "PowerNetwork";   % Tag of the network.
            end
            arguments (Output)
                obj   % New PowerNetwork without buses.
            end
            obj.s_tag     = tag;
            obj.sct_stale = struct("powerflow", obj.s_notInitialized, "odefcn", obj.s_notInitialized, "input", strings(0,1));
            % tab_parameter column base: Hz [Hz]: nominal frequency, read with get_Hz() and
            % passed as omega0; baseMVA [MVA]: system base of all per-unit values (default 100)
            a_Pb = Parameter(obj, "base", struct( ...
                     "Hz", GUILDA.config("Model","Hz"), ...
                "baseMVA", 100));
            obj.a_Parameter = {a_Pb};
            obj.reset_solver;
        end
    end

%% Methods
    methods
        % Layer Structure
        bus = add_bus(   obj, opt)
        % <@Group> Model building
        bra = add_branch(obj, Type, from_to, opt)
        con = add_global_controller(obj, Key, a_Unit, opt)
        remove_bus( obj, sr_BusTag, opt)
        remove_branch( obj, tag)
        remove_global_controller( obj, sr_GconTag)

        % Scenarios of the time simulation
        add_scenario(obj, sc)
        remove_scenario(obj, sr_tag)
        
        % initialize
        [result, flag, output] = initialize(obj, varargin)
        reset_solver(obj);

        % OPF(optimal power-flow)
        varargout = optimize_powerflow(obj, varargin)
        varargout = build_opf_problem(obj, varargin)

        % PF(powerflow) calculations
        [result, flag, output] = calculate_powerflow(obj, varargin)

        % CPF(continuation power-flow)
        [result, flag, output] = calculate_continuation_powerflow(obj, varargin)

        % Static Analysis
        [result, flag, output] = linearize(obj, varargin)
        [sys, flag, output] = get_sys(obj, varargin)
        [tab, c_idxBus, c_idxGC] = get_variable_map(obj)
        tab_Ybus2bus = get_admittance_matrix(obj)
        
        % Time simulation
        [result, flag, output] = simulate(obj, time, varargin)

        % User Interface << Information >>
        info(obj, disp)
        G = draw_diagram(obj,ax)

        % IO
        path = export_csv(obj, path, opt)
    end
    methods(Static)
        % IO
        net = import_csv(path, opt)
        net = import_matpower(mpc, opt)
    end
    methods(Access=protected)
        % Edit handling: the one-slack-bus rule and the stale tag powerflow
        handle_edit(obj, a_layer, tag, log)
        sct_page = gui_content(obj)
    end

%% Get Method
    methods
        function p = get.parent(~)
            p = {};
        end
        function p = get.children(obj)
            p = [obj.a_Bus; obj.a_Branch; obj.a_GlobalController; obj.a_Parameter];
        end
        function V = get.cv_Vequilibrium(obj)
            V = tools.vcellfun(@(b) b.c_Vequilibrium, obj.a_Bus);
        end
        function I = get.cv_Iequilibrium(obj)
            I = tools.vcellfun(@(b) b.c_Iequilibrium, obj.a_Bus);
        end
        function x = get.rv_Xequilibrium(obj)
            % Order of the x rows of get_variable_map
            x_bus = tools.vcellfun(@(b) tools.vcellfun(@(c) c.rv_Xequilibrium_all, b.a_Component), obj.a_Bus);
            x_con = tools.vcellfun(@(c) c.rv_Xequilibrium, obj.a_GlobalController);
            x = [zeros(0,1); x_bus; x_con];
        end
    end
%% Get Method
    methods
        % function set.s_methodPF(~,~)
        %     error("Property: Records the power flow calculation method used by obj.initialize()."+newline+...
        %           " Update : Automatically refreshes based on the method used upon each execution of obj.initialize().")
        % end
    end
end
