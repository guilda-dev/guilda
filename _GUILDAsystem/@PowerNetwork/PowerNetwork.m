classdef PowerNetwork < PowerSystemModel
% Power system model that holds the buses, branches and global controllers of one grid.
%
% A network is built by adding buses (`add_bus`) and branches (`add_branch`); the
% components (generators, loads, ...) are added to the buses (`Bus.add_component`) and
% local controllers to the components. The network runs the analyses:
%
% - power flow (`calculate_powerflow`) and optimal power flow (`optimize_powerflow`)
% - continuation power flow (`calculate_continuation_powerflow`)
% - equilibrium (`initialize`), time simulation (`simulate`)
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
% res = net.calculate_powerflow();          % PowerFlowResult
% net.initialize();                         % equilibrium for the dynamic analyses
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B003");
% sim = net.simulate([0,10], ev);           % odeSimulationResult
% sys = net.get_sys();                      % linear state-space model
% ```
%
% See also Bus, Branch, Component, GlobalController, network.IEEE9bus

%% Properties

    properties % Layer Structure
       a_Bus              (:,1) cell = cell(0,1);   % Buses of the network, in the order of the bus index.
       a_Branch           (:,1) cell = cell(0,1);   % Branches of the network.
       a_GlobalController (:,1) cell = cell(0,1);   % Global controllers of the network.
    end
    properties(SetAccess=protected) % Solvers

        % PowerFlowCalculation solver of net.calculate_powerflow.
        % Its properties are the stored defaults (Method, Tolerance, MaxIterations, ...),
        % kept between runs; Name-Value options of a call override them for that call
        % only. Results are returned as a PowerFlowResult, never stored in the solver.
        % <@Type> PowerFlowCalculation
        solver_PF  

        % OptimalPowerFlow solver of net.optimize_powerflow.
        % Its properties are the stored defaults (Method, Solver, Display, MaxIteration,
        % ...), kept between runs; Name-Value options of a call override them for that
        % call only. Results are returned as an OPFResult, never stored in the solver.
        % <@Type> OptimalPowerFlow
        solver_OPF 

        % ContinuationPowerFlow solver of net.calculate_continuation_powerflow.
        % Its properties are the stored defaults (LoadBus, MaxIterations, StepSize, ...),
        % kept between runs; Name-Value options of a call override them for that call
        % only. Results are returned as a CPFResult, never stored in the solver.
        % <@Type> ContinuationPowerFlow
        solver_CPF

        % odeSimulator solver of net.simulate.
        % Its properties are the stored defaults (Solver, RelativeTolerance,
        % AbsoluteTolerance, Progress, TimeLimit, ...), kept between runs; Name-Value
        % options of a call override them for that call only. Results are returned as an
        % odeSimulationResult, never stored in the solver.
        % <@Type> odeSimulator
        solver_ODE 

        % odeLinearizer solver of net.linearize and net.get_sys.
        % Its properties are the stored defaults (Algorithm, NonUnit, Point), kept between
        % runs; Name-Value options of a call override them for that call only. Results are
        % returned as a LinearizationResult, never stored in the solver.
        % <@Type> odeLinearizer
        solver_LIN
    end
    properties(Dependent) % Steady State
        cv_Vequilibrium         % [pu] Bus voltage phasors at the equilibrium, one per bus.
        cv_Iequilibrium         % [pu] Bus current injections at the equilibrium, one per bus.
        rv_Xequilibrium         % State equilibrium of the buses, branches and global controllers.
        tab_parameter           % Parameter table of the network (base: Hz and baseMVA).
    end
    properties(Hidden,SetAccess=protected) % Parameter
        para_base               % Parameter: Hz (nominal frequency) and baseMVA (system base) of the whole network
    end
    properties(SetAccess=protected) % OPF
        s_opffcn = opffcn.default()   % Network-wide OPF terms (Cost, Constraint, DefaultConstraint) set by set_opffcn.
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
            obj.str_tag   = tag;
            obj.para_base = Parameter(obj,"base");
            obj.para_base.add_entry(     "Hz", GUILDA.config("Model","Hz"), "double",...
                                    "baseMVA", 100                        , "double");
            obj.reset_solver;
        end
    end

%% Methods
    methods
        % Layer Structure
        bus    = add_bus(  obj,  str_Bus,    opt)
        branch = add_branch(obj, str_Branch, from_to, opt)
        add_global_controller(obj, a_Gcon)
        remove_bus( obj, str_BusTag, opt)
        remove_branch( obj, tag)
        remove_global_controller( obj, str_GconTag)
        
        % initialize
        [flag,powerflow_bus,powerflow_cub] = initialize(obj,options)
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
        % Edit handling: rebuild stale f_* handles, check the equilibrium
        flag = check_edit(obj, opt)

        function Hz = get_Hz(obj)
            % The network owns the nominal frequency of all its layers
            Hz = obj.para_base.Hz;
        end

        function handle_edit(obj, tab)
            % At most one slack bus: a bus reports bus.l_isSlack = true as a
            % "Slack" edit (ID starts with its tag); the network releases the others.
            if string(tab{1,4}) ~= "Slack"
                return
            end
            str_id  = split(string(tab{1,2}), "/");
            lv_this = string(obj.a_Bus) == str_id(1);
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
    methods(Access={?odeSimulator, ?odeLinearizer})
        function require_equilibrium(obj)
            % Called at the start of solver_ODE.solve and solver_LIN.solve (the one place
            % of this check for simulate, linearize and get_sys): rebuild stale f_*
            % handles; error if net.initialize() is needed.
            obj.check_edit("RequireEquilibrium", true);
        end
    end

%% Get Method
    methods
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
            x_bus = tools.vcellfun(@(b) b.rv_Xequilibrium_all, obj.a_Bus);
            x_bra = tools.vcellfun(@(b) b.rv_Xequilibrium, obj.a_Branch);
            x_con = tools.vcellfun(@(c) c.rv_Xequilibrium, obj.a_GlobalController);
            x = [x_bus; x_bra; x_con];
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
        function set.a_Bus(obj,val)
            stack = dbstack('-completenames');            
            if ~isempty(stack) && ~contains(stack(2).file, "_GUILDAsystem"+filesep+"@PowerNetwork")                 
                error(msg('GUILDA:PowerNetwork:SetAbus'))
            end
            obj.a_Bus = val;
        end
        function set.a_Branch(obj,val)
            stack = dbstack('-completenames');            
            if ~isempty(stack) && ~contains(stack(2).file, "_GUILDAsystem"+filesep+"@PowerNetwork")                 
                error(msg('GUILDA:PowerNetwork:SetAbranch'))
            end
            obj.a_Branch = val;
        end
        function set.a_GlobalController(obj,val)
            stack = dbstack('-completenames');            
            if ~isempty(stack) && ~contains(stack(2).file, "_GUILDAsystem"+filesep+"@PowerNetwork")                 
                error(msg('GUILDA:PowerNetwork:SetGcon'))
            end
            obj.a_GlobalController = val;
        end
        
        % function set.str_methodPF(~,~)
        %     error("Property: Records the power flow calculation method used by obj.initialize()."+newline+...
        %           " Update : Automatically refreshes based on the method used upon each execution of obj.initialize().")
        % end
    end
end
