classdef PowerNetwork < PowerSystemModel
% Root of the model: holds the buses, branches and global controllers of one grid and runs the analyses.
%
% - Owns the topology (which buses, branches and global controllers exist), the system
%   base in `tab_parameter.base` (Hz, baseMVA), the solver objects `solver_*` and the
%   network-wide OPF terms (`f_opfcost`, `f_opfconst`, `l_opfdefault`).
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
% - Every layer below reports its edits upward with `log_edit`; the network appends them to
%   `tab_editLog` (`report_edit`) and passes each one to `handle_edit`, which keeps at most
%   one slack bus. `l_staleEquilibrium` is derived from that log.
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
% Each analysis runs a solver object stored in a `solver_*` property. The properties of
% that solver are the stored defaults; Name-Value options of a call override them for
% that call only. Results are returned as result objects and never stored in the network.
%
% Power-flow settings are parameters of the buses (`tab_parameter.powerflow`: V, Varg)
% and the components (`tab_parameter.powerflow`: P, Q). OPF limits and costs are in
% `tab_parameter.operation` and `tab_parameter.OPF` of the buses, components and
% branches; `set_opffcn` adds user-defined costs and constraints.
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
% sys = net.get_sys();                      % linear state-space model
% ```
%
% See also Bus, Branch, Component, GlobalController, Scenario, network.IEEE9bus

%% Properties

    properties(SetAccess=private) % Layer Structure
       a_Bus              (:,1) cell = cell(0,1);   % Buses of the network, in the order of the bus index. <@Stale> equilibrium
       a_Branch           (:,1) cell = cell(0,1);   % Branches of the network. <@Stale> equilibrium
       a_GlobalController (:,1) cell = cell(0,1);   % Global controllers of the network. <@Stale> equilibrium
    end
    properties(SetAccess=private) % Scenarios
       % Simulation scenarios of the network (Scenario objects), in the order they were added.
       % Added by add_scenario and removed by remove_scenario; not model data (they do not make
       % the equilibrium stale).
       % <@Stale> nothing (not logged)
       a_Scenario (:,1) cell = cell(0,1);
    end
    properties(SetAccess=private) % Edit log
        % Log of the edits made to the network and its layers since the last initialize.
        % Columns: timestamp, ID, log message, tag, and the states before and after the edit.
        % Rows are appended once initialize has run and cleared at the end of initialize.
        % <@Type> table (Nx6)
        % <@Stale> nothing
        tab_editLog = table('Size',[0 6], 'VariableTypes',["string","string","string","string","cell","cell"], ...
                            'VariableNames',["timestamp","ID","log","tag","before","after"]);
    end
    properties(Dependent, Hidden) % Edit log
        % True when the equilibrium set by initialize no longer matches the model: initialize
        % has not run, or a row of tab_editLog affects the equilibrium (see edit_effect;
        % edits of "dynamics", "base" (baseMVA) and "powerflow" parameters, topology and
        % slack-bus changes, and an initialize that stopped while writing the equilibrium).
        % <@Type> logical
        l_staleEquilibrium
    end
    properties(SetAccess=protected) % Solvers

        % SolverPF solver of net.calculate_powerflow.
        % Its properties are the stored defaults (Method, Tolerance, MaxIterations, ...),
        % kept between runs; Name-Value options of a call override them for that call
        % only. Results are returned as a ResultPF, never stored in the solver.
        % <@Type> SolverPF
        % <@Stale> nothing
        solver_PF  

        % SolverOPF solver of net.optimize_powerflow.
        % Its properties are the stored defaults (Method, Solver, Display, MaxIteration,
        % ...), kept between runs; Name-Value options of a call override them for that
        % call only. Results are returned as a ResultOPF, never stored in the solver.
        % <@Type> SolverOPF
        % <@Stale> nothing
        solver_OPF 

        % SolverCPF solver of net.calculate_continuation_powerflow.
        % Its properties are the stored defaults (LoadBus, MaxIterations, StepSize, ...),
        % kept between runs; Name-Value options of a call override them for that call
        % only. Results are returned as a ResultCPF, never stored in the solver.
        % <@Type> SolverCPF
        % <@Stale> nothing
        solver_CPF

        % SolverODE solver of net.simulate.
        % Its properties are the stored defaults (Solver, RelativeTolerance,
        % AbsoluteTolerance, Progress, TimeLimit, ...), kept between runs; Name-Value
        % options of a call override them for that call only. Results are returned as an
        % ResultODE, never stored in the solver.
        % <@Type> SolverODE
        % <@Stale> nothing
        solver_ODE 

        % SolverLIN solver of net.linearize and net.get_sys.
        % Its properties are the stored defaults (Algorithm, Point, Coordinate), kept between
        % runs; Name-Value options of a call override them for that call only. Results are
        % returned as a ResultLIN, never stored in the solver.
        % <@Type> SolverLIN
        % <@Stale> nothing
        solver_LIN
    end
    properties(Dependent) % Steady State
        cv_Vequilibrium         % [pu] Bus voltage phasors at the equilibrium, one per bus.
        cv_Iequilibrium         % [pu] Bus current injections at the equilibrium, one per bus.
        rv_Xequilibrium         % State equilibrium, in the order of the x rows of get_variable_map.
    end
    properties(Dependent) % Parameter
        % Parameter table of the network (base: Hz and baseMVA); writing it writes the parameters.
        %
        % - `Hz` [Hz]: nominal frequency. Models read it with get_Hz() and receive it as omega0.
        %   Set by the constructor (GUILDA.config("Model","Hz")), by writing the table and by
        %   import_csv. An edit makes the function handles of every layer stale.
        % - `baseMVA` [MVA]: system base of all per-unit values (default 100). Stored per-unit
        %   values are not converted when it changes. Set by the constructor, by writing the
        %   table, import_csv and import_matpower. An edit makes the equilibrium stale.
        tab_parameter
    end
    properties(Hidden,SetAccess=protected) % Parameter
        para_base               % Parameter: Hz (nominal frequency) and baseMVA (system base) of the whole network
    end
    properties(SetAccess=protected) % OPF
        f_opfcost    = []   % OPF cost handle @(v, p) set by set_opffcn; it replaces the default cost of the network ([]: none). <@Stale> nothing (logged)
        f_opfconst   = []   % OPF constraint handle @(v, p) set by set_opffcn, returning a struct of named constraints ([]: none). <@Stale> nothing (logged)
        l_opfdefault = true % Whether the default OPF constraints of the network are kept (DefaultConstraint of set_opffcn). <@Stale> nothing (logged)
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent                  % Layer Structure
        children                % Layer Structure
    end    

%% Constructor
    methods
        function obj = PowerNetwork(tag)
            % Create an empty network with the given tag.
            %
            % The nominal frequency is GUILDA.config("Model","Hz") and the system base is
            % 100 MVA (net.tab_parameter.base).
            arguments
                tag (1,1) string = "PowerNetwork";   % Tag of the network.
            end
            arguments (Output)
                obj   % New PowerNetwork without buses.
            end
            obj.s_tag     = tag;
            obj.para_base = Parameter(obj,"base");
            obj.para_base.add_entry(     "Hz", GUILDA.config("Model","Hz"), "double",...
                                    "baseMVA", 100                        , "double");
            obj.reset_solver;
        end
    end

%% Methods
    methods
        % Layer Structure
        bus = add_bus(   obj, opt)
        % <@Group> Model building
        bra = add_branch(obj, Type, from_to, opt)
        add_global_controller(obj, a_Gcon)
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

        function obj = loadobj(obj)
            % A MAT file does not hold listeners: restore those of the parameters so that
            % edits of a loaded network are checked and logged. MATLAB turns an error here
            % into a warning, so an incomplete restore is reported as a warning.
            %
            % <@Group> Data IO
            if ~restore_parameter_listeners(obj)
                warning(msg("GUILDA:PowerNetwork:IncompleteLoad", obj.s_tag))
            end
        end
    end
    methods(Access=protected)
        % Edit handling: build the f_* handles that are not up to date, check the equilibrium
        flag = check_edit(obj, opt)

        function report_edit(obj, tab)
            % Record an edit reported by a layer (log_edit) once initialize has run, and keep
            % the network-wide rules (handle_edit), also before the first initialize.
            %
            % <@Group> Called by analyses
            if obj.sct_edit.l_initialized
                obj.tab_editLog = [obj.tab_editLog; tab];
            end
            obj.handle_edit(tab);
        end

        function reset_edit(obj)
            % Mark every layer as initialized and clear the edit log (end of initialize).
            %
            % <@Group> Called by analyses
            reset_edit@LayerPackage(obj);
            obj.tab_editLog(1:end,:) = [];
        end

        function handle_edit(obj, tab)
            % At most one slack bus: a bus reports bus.l_isSlack = true as a
            % "Slack" edit (ID starts with its tag); the network releases the others.
            %
            % <@Group> Called by analyses
            if tab.tag ~= "Slack"
                return
            end
            sv_id   = split(tab.ID, "/");
            lv_this = string(obj.a_Bus) == sv_id(1);
            if ~any(lv_this) || ~obj.a_Bus{lv_this}.l_isSlack
                return
            end
            for i = find(~lv_this(:)')
                bus = obj.a_Bus{i};
                if bus.l_isSlack
                    bus.l_isSlack = false;
                end
            end
        end
    end
    methods(Access={?SolverODE, ?SolverLIN})
        function require_equilibrium(obj)
            % Called at the start of solver_ODE.solve and solver_LIN.solve (the one place
            % of this check for simulate, linearize and get_sys): build the f_* handles
            % that are not up to date; error if net.initialize() is needed.
            %
            % <@Group> Called by analyses
            obj.check_edit("RequireEquilibrium", true);
        end
    end

%% Get Method
    methods
        function l = get.l_staleEquilibrium(obj)
            [~, lv] = obj.edit_effect(obj.tab_editLog);
            l = ~obj.sct_edit.l_initialized || any(lv);
        end

        function tp = get.tab_parameter(obj)
            base = obj.para_base.tab_parameter;
            tp   = table(base);
        end
        function p = get.parent(~)
            p = {};
        end
        function p = get.children(obj)
            p = [obj.a_Bus; obj.a_Branch; obj.a_GlobalController; {obj.para_base}];
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
        function set.tab_parameter(obj,val)
            fieldname = val.Properties.VariableNames;
            for i = 1:numel(fieldname)
                propname = "para_"+fieldname{i};
                tabdata  = val.(fieldname{i});
                paraname = tabdata.Properties.VariableNames;
                for j = 1:numel(paraname)
                    obj.(propname).(paraname{j}) = tabdata.(paraname{j});
                end
            end
        end
        
        % function set.s_methodPF(~,~)
        %     error("Property: Records the power flow calculation method used by obj.initialize()."+newline+...
        %           " Update : Automatically refreshes based on the method used upon each execution of obj.initialize().")
        % end
    end
end


function l_complete = restore_parameter_listeners(layer)
% Attach the class check and the listeners of Parameter.add_entry again on a layer and all
% layers below it. The class a parameter must keep is taken from its value.
% l_complete is false when a layer is still being loaded (the MAT file holds a variable
% below the network, which loads the network from inside that layer): its parameters are
% not available yet.
    l_complete = true;
    mc = metaclass(layer);
    lv = startsWith(string({mc.PropertyList.Name}), "para_") & ~[mc.PropertyList.Dependent];
    for s_para = string({mc.PropertyList(lv).Name})
        para = layer.(s_para);
        if ~isa(para, "Parameter")
            l_complete = false;
            continue
        end
        for name = setdiff(string(properties(para)), string(properties("Parameter"))).'
            para.attach_callbacks(name, class(para.(name)));
        end
    end
    if isa(layer, "PowerNetwork")
        a_lower = [layer.a_Bus; layer.a_Branch; layer.a_GlobalController];
    elseif isa(layer, "Bus")
        a_lower = layer.a_Component;
    elseif isprop(layer, "a_LocalController")
        a_lower = layer.a_LocalController;
    else
        a_lower = {};
    end
    l_complete = all([l_complete, cellfun(@restore_parameter_listeners, a_lower(:).')]);
end
