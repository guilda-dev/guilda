classdef Component < PowerSystemModel
% <@Desc>
% Abstract base class for equipment (machine/load) models connected to a bus.
% It defines the interface for dynamics, power flow settings, and linearization.
% Inherit from this class to implement a new equipment model.
% <@Role>
% Power System Model
% <@Constructor>
% Component instances are created via Bus.add_component().
%  i.e.
%  >> comp = bus.add_component(Type, P=0, Q=0, baseMVA=100, ...)
%      - Type:    component type string (e.g., 'gen-classical', 'gen-1axis', 'load-power')
%      - P:       active power injection [pu] (default: 0)
%      - Q:       reactive power injection [pu] (default: 0)
%      - baseMVA: base power [MVA] (default: 100)

%% Abstract properties/methods
    properties(Abstract,Constant)
        key      (1,1) string
        str_x    (:,1) string
        str_u    (:,1) string 
        str_y    (:,1) string
        str_para (:,1) string
    end
    methods(Abstract)
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q);
        set_odefcn(obj, omega0)
    end
    

%% Parameter
    properties(SetAccess=protected)

        % <@Desc> Bus object to which this component is connected.
        % <@Role> Layer Structure
        % <@Type> Bus
        % <@Size> 1x1
        a_Bus

        % <@Desc> Cell array of local controller objects connected to this component.
        % <@Role> Layer Structure
        % <@Type> LocalController cell array
        % <@Size> Nx1
        a_LocalController  = cell(0,1)

        % <@Desc> Mass matrix function handle for the ODE numerical integration.
        % <@Role> Dynamics
        % <@Type> function_handle
        % <@Size> 1x1
        rm_odeMass

        % <@Desc> Differential equation function handle for the ODE numerical integration.
        % <@Role> Dynamics
        % <@Type> function_handle
        % <@Size> 1x1
        fv_odeDiff

        % <@Desc> Connection equation function handle for the ODE numerical integration.
        % <@Role> Dynamics
        % <@Type> function_handle
        % <@Size> 1x1
        fv_odeI

        % <@Desc> Jacobian matrix A (state-to-state) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiA

        % <@Desc> Jacobian matrix B (input-to-state) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiB

        % <@Desc> Jacobian matrix C (state-to-output) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiC

        % <@Desc> Jacobian matrix D (input-to-output) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiD

        % <@Desc> Cached linearized state-space system object.
        % <@Role> Linearize
        % <@Type> ss
        % <@Size> 1x1
        odeLinearSystem
    end
    properties

        % <@Desc> Current state vector during simulation.
        % <@Role> Simulation
        % <@Type> complex double
        % <@Size> Nx1
        cv_Xcurrent = zeros(0,1)

        % <@Desc> Current input vector during simulation.
        % <@Role> Simulation
        % <@Type> complex double
        % <@Size> Nx1
        cv_Ucurrent = zeros(0,1)
    end
    properties(SetAccess=protected)

        % <@Desc> Equilibrium (steady-state) state vector.
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> Nx1
        cv_Xequilibrium = zeros(0,1)

        % <@Desc> Equilibrium (steady-state) input vector.
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> Nx1
        cv_Uequilibrium = zeros(0,1)

        % <@Desc> Steady-state injection current at the connected bus (complex).
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> 1x1
        c_Iequilibrium

        % <@Desc> Steady-state voltage at the connected bus (complex).
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> 1x1
        c_Vequilibrium
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)

        % <@Desc> ODE index mapping for component state variables.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        iv_odeX  = zeros(0,1);

        % <@Desc> ODE index mapping for component input variables.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        iv_odeU  = zeros(0,1);
    end    
    properties(Dependent)

        % <@Desc> Equilibrium state vector including all connected controller states.
        % <@Role> Steady State
        % <@Type> double
        % <@Size> Nx1
        cv_Xequilibrium_all

        % <@Desc> Parameter table containing all component parameters (dynamics, operation, powerflow, OPF, graph).
        % <@Role> Parameter
        % <@Type> table
        % <@Size> 1x1
        tab_parameter
    end
    properties(SetAccess=protected)

        % <@Desc> Parameter container for component dynamics settings.
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_dynamics

        % <@Desc> Parameter container for power flow settings (P, Q).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_powerflow

        % <@Desc> Parameter container for operating limits (baseMVA, Pmin, Pmax, Qmin, Qmax).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_operation

        % <@Desc> Parameter container for OPF cost and initialization settings.
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_OPF

        % <@Desc> Parameter container for graph plotting settings.
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_graph
    end  
    properties(Dependent, Access=protected)

        % <@Desc> Parent Bus object in the layer hierarchy.
        % <@Role> Layer Structure
        % <@Type> Bus
        % <@Size> 1x1
        parent

        % <@Desc> Child controllers and parameter objects in the layer hierarchy.
        % <@Role> Layer Structure
        % <@Type> cell array
        % <@Size> Nx1
        children
    end
    properties (Access={?odeSimulator, ?Component})
        isController = false
        isConnect    = true
    end
    properties (Hidden)
        X_offset 
        U_offset 
    end

    
    
%% Constructor
    methods(Access=protected)
        function obj = Component(str_tag, opt)
        % <@Desc>
        % Creates a Component instance with the given tag and parameter options.
        % This is a protected constructor called by subclass constructors.
        % <@Role>
        % Constructor
        % <@Abst>
        % Initialize all parameter containers and register component parameters.
        % <@Signatures>
        % [
        %   "obj = Component(str_tag, opt)"
        % ]
        % <@varargin>
        % [
        %   {
        %     "Name": "str_tag",
        %     "Type": "string scalar",
        %     "Description": "Tag string to identify this component.",
        %     "Required": true,
        %     "Default": "-"
        %   },
        %   {
        %     "Name": "opt",
        %     "Type": "struct",
        %     "Description": "Option struct with component parameters (P, Q, baseMVA, Pmin, Pmax, Qmin, Qmax, OPF settings, graph settings).",
        %     "Required": true,
        %     "Default": "-"
        %   }
        % ]
        % <@varargout>
        % [
        %   {
        %     "Name": "obj",
        %     "Type": "Component",
        %     "Description": "Created Component instance."
        %   }
        % ]
            obj.str_tag        = str_tag;
            obj.para_dynamics  = Parameter(obj,"dynamics");
            obj.para_powerflow = Parameter(obj,"powerflow");
            obj.para_OPF       = Parameter(obj,"OPF");
            obj.para_graph     = Parameter(obj,"graph");
            obj.para_operation = Parameter(obj,"operation");

            obj.para_operation.add_entry( "baseMVA", opt.baseMVA          , "double",...
                                             "Pmin", opt.Pmin             , "double",...
                                             "Pmax", opt.Pmax             , "double",...
                                             "Qmin", opt.Qmin             , "double",...
                                             "Qmax", opt.Qmax             , "double");
            obj.para_powerflow.add_entry(       "P", opt.P                , "double",...
                                                "Q", opt.Q                , "double");
            obj.para_OPF.add_entry(            "P0", opt.OPFinit_P0       , "double",...
                                               "Q0", opt.OPFinit_Q0       , "double",...
                                               "HP", opt.OPFcost_HP       , "double",...
                                               "HQ", opt.OPFcost_HQ       , "double",...
                                               "fP", opt.OPFcost_fP       , "double",...
                                               "fQ", opt.OPFcost_fQ       , "double",...
                                          "startup", opt.OPFcost_startup  , "double",...
                                         "shutdown", opt.OPFcost_shutdown , "double");
            obj.para_graph.add_entry(       "Xaxis", opt.Xaxis            , "double",...
                                            "Yaxis", opt.Yaxis            , "double",...
                                           "Marker", opt.Marker           , "string",...
                                         "MidXaxis", opt.MidXaxis         , "string",...
                                         "MidYaxis", opt.MidYaxis         , "string",...
                                         "BusPoint", opt.BusPoint        , "string");
        end
    end

%% Methods
    methods
        % Layer Structure
        add_local_controller(obj, a_Controller)
        remove_local_controller(obj,str_tag)

        % OPF
        [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Busvar, option)

        % Dynamics
        [n_odeX, n_odeU, Mass, x0] = reset_odeset(obj, n_odeX, n_odeU, omega0)

        %get_sys
        sys = get_sys(obj, x, V, u)

    end

    methods(Access={?Bus})
        set_bus(obj,bus)
        set_equilibrium(obj)
    end


%% Get Methods
    methods
        function x = get.cv_Xequilibrium_all(obj)
            a_con = [obj.a_GlobalController; obj.a_LocalController];
            x_con = tools.vcellfun(@(comp) comp.cv_Xequilibrium, a_con);
            x     = [obj.cv_Xequilibrium; x_con];
        end
        function p = get.parent(obj)
            p = obj.a_Bus;
        end
        function p = get.children(obj)
            p = [ obj.a_LocalController  ;...
                 {obj.para_dynamics       ; obj.para_powerflow     ;...
                  obj.para_operation      ; obj.para_OPF           ;...
                  obj.para_graph          }];
        end
        function tp = get.tab_parameter(obj)
            dynamics  = obj.para_dynamics.tab_parameter;
            powerflow = obj.para_powerflow.tab_parameter;
            OPF       = obj.para_OPF.tab_parameter;
            operation = obj.para_operation.tab_parameter;
            graph     = obj.para_graph.tab_parameter;
            tp        = table(dynamics,operation,powerflow,OPF,graph);
        end
    end

%% Set Methods
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
    end   
end





