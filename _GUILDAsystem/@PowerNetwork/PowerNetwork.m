classdef PowerNetwork < PowerSystemModel
% <@Desc>
% A package for constructing a single electric power system (or power grid).
% By storing Bus, Branch, and GlobalController objects in this class's properties,
% various analyses can be performed.
%
% << This class primarily provides the following analyses >>
%   * Power Flow Calculation (Load Flow)
%   * Optimal Power Flow (OPF)
%   * Time-Domain Simulation (Dynamic Simulation)
%   * Construction of an Approximate Linearized Model
%   * Eigenvalue Analysis
%   * Others (e.g., Graph Plotting of the system structure)
%
% << Power Flow Setting >>
%   -> To check power flow settings
%      >> obj.disp_pf_set
%   -> When changing the bus voltage settings
%      >> obj.a_Bus{i}.tab_parameter.powerflow.Varg = value
%      >> obj.a_Bus{i}.tab_parameter.powerflow.V    = value
%   -> When changing the P or Q settings
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.powerflow.P = value
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.powerflow.Q = value
%   -> Method for obtaining power flow calculation results
%      >> [powerflow_bus, powerflow_cub] = obj.calculate_powerflow()
%   -> By executing the following command, steady-state values will be set
%      >> net.initialize("methods","powerflow calculation")
%
% << Optimal PowerFlow (OPF) >>
%   -> Bus Class: Modify the following properties
%      >> obj.a_Bus{i}.tab_parameter.operation
%      >> obj.a_Bus{i}.tab_parameter.OPF
%   -> Component Class: Modify the following properties
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.operation
%      >> obj.a_Bus{i}.a_Component{j}.tab_parameter.OPF
%   -> Branch Class: Modify the following properties
%      >> obj.a_Branch{i}.tab_parameter.operation
%      >> obj.a_Branch{i}.tab_parameter.OPF
%   -> After modifying the hyperparameters, execute the following command
%      >> net.initialize("methods","optimal powerflow")
%
% << Time Simulation >>
%    TBD
% << Approximate Linearized Model >>
%    TBD
% << Eigenvalue Analysis >> 
%    TBD
%
% <@Role>
% Power System Model
% <@Constructor>
% PowerNetwork(tag, struct_default, baseHz=value)
%  i.e.
%  >> net = PowerNetwork()
%  >> net = PowerNetwork("MyNet", baseHz=50)
%      - tag:     name string for the network (default: "PowerNetwork")
%      - baseHz:  base system frequency [Hz] (default: from GUILDA config)

%% Properties

    properties%(SetAccess=protected) 

        % <@Desc> Cell array of Bus objects in the power system.
        % <@Role> Layer Structure
        % <@Type> Bus cell array
        % <@Size> Nx1
       a_Bus              (:,1) cell = cell(0,1);
    end
    properties

        % <@Desc> Cell array of Branch objects (transmission lines/transformers) in the power system.
        % <@Role> Layer Structure
        % <@Type> Branch cell array
        % <@Size> Nx1
       a_Branch           (:,1) cell = cell(0,1);
    end
    properties

        % <@Desc> Cell array of GlobalController objects in the power system.
        % <@Role> Layer Structure
        % <@Type> GlobalController cell array
        % <@Size> Nx1
       a_GlobalController (:,1) cell = cell(0,1);
    end
    properties(SetAccess=protected)

        % <@Desc> Power flow solver object used for steady-state calculations.
        % <@Role> Power Flow
        % <@Type> SolverPF
        % <@Size> 1x1
        solver_PF  = SolverPF();
        % solver_OPF (1,1) OptimalPowerFlow     = OptimalPowerFlow();
    end

    properties

        % <@Desc> String indicating which method was last used to initialize steady-state values.
        % <@Role> Steady State
        % <@Type> string
        % <@Size> 1x1
       str_methodPF       (1,1) string {mustBeMember(str_methodPF,["optimal powerflow","powerflow calculation","calculate from Xequilibrium","unset"])} = "unset";
    end
    properties(Dependent) 

        % <@Desc> Steady-state bus voltage vector (complex).
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> Nx1
        cv_Vequilibrium

        % <@Desc> Steady-state bus injection current vector (complex).
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> Nx1
        cv_Iequilibrium

        % <@Desc> Steady-state state vector of the entire network.
        % <@Role> Steady State
        % <@Type> double
        % <@Size> Nx1
        cv_Xequilibrium

        % <@Desc> Parameter table containing network parameters (base frequency, etc.).
        % <@Role> Parameter
        % <@Type> table
        % <@Size> 1x1
        tab_parameter
    end
    properties(Hidden,SetAccess=protected)

        % <@Desc> Parameter container for base network settings (Hz).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_base
    end
    properties(Dependent, Access=protected)

        % <@Desc> Parent object in the layer hierarchy (none for PowerNetwork).
        % <@Role> Layer Structure
        % <@Type> cell array
        % <@Size> 0x1
        parent

        % <@Desc> Child Bus, Branch, GlobalController, and parameter objects in the layer hierarchy.
        % <@Role> Layer Structure
        % <@Type> cell array
        % <@Size> Nx1
        children
    end    
    properties

        % <@Desc> User-defined initial state values for the network simulation.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        rv_odeInit
    end

%% Constructor
    methods
        function obj = PowerNetwork(tag,struct_default,opt)
        % <@Desc>
        % Creates a PowerNetwork instance with the given tag and base frequency.
        % <@Role>
        % Constructor
        % <@Abst>
        % Initialize the network tag and base parameter container.
        % <@Signatures>
        % [
        %   "obj = PowerNetwork()",
        %   "obj = PowerNetwork(tag)",
        %   "obj = PowerNetwork(tag, struct_default, baseHz=value)"
        % ]
        % <@varargin>
        % [
        %   {
        %     "Name": "tag",
        %     "Type": "string scalar",
        %     "Description": "Tag string to identify this network.",
        %     "Required": false,
        %     "Default": "\"PowerNetwork\""
        %   },
        %   {
        %     "Name": "baseHz",
        %     "Type": "double scalar",
        %     "Description": "Base frequency of the power system [Hz].",
        %     "Required": false,
        %     "Default": "from GUILDA config"
        %   }
        % ]
        % <@varargout>
        % [
        %   {
        %     "Name": "obj",
        %     "Type": "PowerNetwork",
        %     "Description": "Created PowerNetwork instance."
        %   }
        % ]
            arguments
                tag            (1,1) string = "PowerNetwork";
                struct_default (1,1) struct = GUILDA.config("ModelNetwork"); %#ok 
                opt.baseHz     (1,1) double {mustBePositive} = struct_default.Hz;
            end
            obj.str_tag   = tag;
            obj.para_base = Parameter(obj);
            obj.para_base.add_entry("Hz", opt.baseHz, "double");
        end
    end

%% Methods
    methods
        % Layer Structure
        bus = add_bus(obj, str_Bus, opt)
        branch = add_branch(obj, str_Branch, from_to, opt)
        add_global_controller(obj, a_Gcon, str_CompTag)
        remove_bus( obj, str_BusTag)
        remove_branch( obj, str_BranchTag)
        remove_global_controller( obj, str_GconTag)
        
        % initialize
        set_pf_set(obj, name, para)
        [flag,powerflow_bus,powerflow_cub] = initialize(obj,options)

        % OPF(optimal power-flow)
        [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob] = optimize_powerflow(obj,options)
        varargout = build_opf_problem(obj,method)

        % PF(powerflow) calculations
        [tab_PFsol, flag, output] = calculate_powerflow(obj,opt)
        varargout = disp_pf_set(obj)
    
        % Static Analysis
        sys = get_sys(obj)
        tab_Ybus2bus = get_admittance_matrix(obj)
        
        % Time simulation
        [sim_t, sim_y, out] = simulate(obj, InitialVal, FaultNum, time, u, uidx, opt)
        [diff, mass, x0, para] = get_dae(obj,opt)
        [Mass, x0] = reset_odeset(obj)
        

        % User Interface << Information >>
        G = draw_diagram(obj,ax)
        % G = draw_spring_model(obj,mode)
        % list(obj,options)
        % [fig,G] = graph(obj,opt)
        % out = information(obj,opt)
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
        function x = get.cv_Xequilibrium(obj)
            x_bus = tools.vcellfun(@(b) b.cv_Xequilibrium_all, obj.a_Bus);
            x_bra = tools.vcellfun(@(b) b.cv_Xequilibrium, obj.a_Branch);
            x_con = tools.vcellfun(@(c) c.cv_Xequilibrium, obj.a_GlobalController);
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
