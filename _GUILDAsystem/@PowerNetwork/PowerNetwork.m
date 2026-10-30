classdef PowerNetwork < PowerSystemModel
% <@Desc>
% A package for constructing a single electric power system (or power grid).
% By storing classes corresponding to buses and transmission lines in this class's properties, 
% various analyses can be performed. Component classes should be stored within the Bus class.
%
%
% << This class primarily provides the following analyses >>
%   * Power Flow Calculation (Load Flow)
%   * Optimal Power Flow (OPF)
%   * Time-Domain Simulation (Dynamic Simulation)
%   * Construction of an Approximate Linearized Model
%   * Eigenvalue Analysis
%   * Others (e.g., Graph Plotting of the system structure)
%
%
% << Power Flow Setting >>
%
%  Changes to the powerflow settings should be made from the Bus/Component class.
%
%   -> To check power flow settings
%      >> obj.disp_pf_set
%
%   -> When changing the bus voltage settings
%      >> obj.a_Bus{i}.tab_parameter.powerflow.Varg = value
%      >> obj.a_Bus{i}.tab_parameter.powerflow.V    = value
%
%   -> When changing the P or Q settings
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.powerflow.P = value
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.powerflow.Q = value
%
%   -> Method for obtaining tide calculation results
%      >> [result, flag, output] = obj.calculate_powerflow(Name, Value)
%
%   -> By executing the following command, steady-state values will be set.
%      ( The internal process executes obj.calculate_powerflow and then sets 
% 　　　the steady-state values of the Bus class using the result. )
%      >> net.initialize("methods","powerflow calculation")
%
%
% << Optimal PowerFlow(OPF) >>
%
%  If you intend to set the power flow based on the solution obtained from AC Optimal PowerFlow (AC OPF) calculation, 
%  first, you adjust the hyperparameters used in the OPF calculation.
%  Adjust the table data within the following properties, depending on the class:
%
%   -> Bus Class: Modify the following properties:
%      >> obj.a_Bus{i}.tab_parameter.operation
%      >> obj.a_Bus{i}.tab_parameter.OPF
%
%   -> Component Class: Modify the following properties:
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.operation
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.OPF
%
%  -> Branch Class: Modify the following properties:
%      >> obj.a_Branch{i}.tab_parameter.operation
%      >> obj.a_Branch{i}.tab_parameter.OPF
%
%  -> After modifying the hyperparameters, execute the following command to set the optimized power flow:
%      >> net.initialize("methods","optimal powerflow")
%
%
% << Time Simulation >>
%    TBD
% << Approximate Linearized Model >>
%    TBD
% << Eigenvalue Analysis >> 
%    TBD

%% Properties

    properties%(SetAccess=protected) 
       a_Bus              (:,1) cell = cell(0,1);   % Layer Structure
       a_Branch           (:,1) cell = cell(0,1);   % Layer Structure
       a_GlobalController (:,1) cell = cell(0,1);   % Layer Structure       
    end
    properties(SetAccess=protected)

        % <@Summary> "PowerFlowCalculation" class
        % <@Desc>
        % Solver of net.calculate_powerflow (runs obj.solver_PF.solve). Its properties are
        % the stored defaults (Method, Tolerance, MaxIterations, ...) and are kept between
        % runs; Name-Value options of a call override them for that call only.
        % Results are returned as a PowerFlowResult, never stored in the solver.
        % <@Role> calculate power-flow
        % <@Size> 1×1
        % <@Default> PowerFlowCalculation()
        solver_PF  

        % <@Summary> "OptimalPowerFlow" class
        % <@Desc>
        % Solver of net.optimize_powerflow (runs obj.solver_OPF.solve). Its properties are
        % the stored defaults (Method, Solver, Display, MaxIteration, ...) and are kept
        % between runs; Name-Value options of a call override them for that call only.
        % Results are returned as an OPFResult, never stored in the solver.
        % <@Role> optimal power-flow
        % <@Size> 1×1
        % <@Default> OptimalPowerFlow()
        solver_OPF 

        % <@Summary> "ContinuationPowerFlow" class
        % <@Desc>
        % Solver of net.calculate_continuation_powerflow (runs obj.solver_CPF.solve). Its
        % properties are the stored defaults (LoadBus, MaxIterations, StepSize, ...) and are
        % kept between runs; Name-Value options of a call override them for that call only.
        % Results are returned as a CPFResult, never stored in the solver.
        % <@Role> continuation power-flow
        % <@Size> 1×1
        % <@Default> ContinuationPowerFlow()
        solver_CPF

        % <@Summary> "odeSimulator" class
        % <@Desc>
        % Solver of net.simulate (runs obj.solver_ODE.solve). Its properties are the stored
        % defaults (Solver, RelativeTolerance, AbsoluteTolerance, Progress, TimeLimit, ...)
        % and are kept between runs; Name-Value options of a call override them for that
        % call only. Results are returned as an odeSimulationResult, never stored in the
        % solver.
        % <@Role> time simulation
        % <@Size> 1×1
        % <@Default> odeSimulator()
        % <@Since> 4.0
        solver_ODE 

        % <@Summary> "odeLinearizer" class
        % <@Desc>
        % Solver of net.linearize and net.get_sys (runs obj.solver_LIN.solve). Its
        % properties are the stored defaults (Algorithm, NonUnit, Point) and are kept
        % between runs; Name-Value options of a call override them for that call only.
        % Results are returned as a LinearizationResult, never stored in the solver.
        % <@Role> linearization
        % <@Size> 1×1
        % <@Default> odeLinearizer()
        solver_LIN
    end
    properties(Dependent) 
        cv_Vequilibrium         % Steady State
        cv_Iequilibrium         % Steady State
        rv_Xequilibrium         % Steady State
        tab_parameter           % Parameter
    end
    properties(Hidden,SetAccess=protected)
        para_base               % Parameter: Hz (nominal frequency) and baseMVA (system base) of the whole network
    end
    properties(Dependent, Access=protected)
        parent                  % Layer Structure
        children                % Layer Structure
    end    

%% Constructor
    methods
        function obj = PowerNetwork(tag)
            arguments
                tag (1,1) string = "PowerNetwork";
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
