classdef Bus < PowerSystemModel
% <@Desc>
% Represents a bus (node) in the power system model.
% It stores connected Component objects, equilibrium state values, and
% power flow settings. Bus objects are created and managed by the PowerNetwork class.
% <@Role>
% Power System Model
% <@Constructor>
% Bus instances are created via PowerNetwork.add_bus().
%  i.e.
%  >> bus = net.add_bus(Tag="B", V=1.0, Varg=0, Gshunt=0, Bshunt=0)
%      - Tag:     tag prefix string (default: "B")
%      - V:       voltage magnitude at steady state (default: 1.0)
%      - Varg:    voltage angle at steady state [rad] (default: 0)
%      - Gshunt:  shunt conductance (default: 0)
%      - Bshunt:  shunt susceptance (default: 0)
%      - Vmin:    minimum voltage limit (default: 0.5)
%      - Vmax:    maximum voltage limit (default: 1.5)
%      - baseKV:  base voltage [kV] (default: 230)
%      - baseMVA: base power [MVA] (default: 100)

%% Properties
    properties

        % <@Desc> Flag indicating whether this bus is designated as the Slack Bus.
        % <@Role> PowerFlow
        % <@Type> logical
        % <@Size> 1x1
        l_isSlack      (1,1) logical = false;
    end
    properties (SetAccess=protected)

        % <@Desc> PowerNetwork object to which this bus belongs.
        % <@Role> Layer Structure
        % <@Type> PowerNetwork
        % <@Size> 1x1
        a_PowerNetwork

        % <@Desc> Cell array of Component objects connected to this bus.
        % <@Role> Layer Structure
        % <@Type> Component cell array
        % <@Size> Nx1
        a_Component

        % <@Desc> Steady-state values of the bus state variables.
        % <@Role> Steady State
        % <@Type> double
        % <@Size> Nx1
        cv_Xequilibrium     = zeros(0,1);

        % <@Desc> Steady-state bus voltage (complex phasor).
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> 1x1
        c_Vequilibrium      = 1;

        % <@Desc> Steady-state injection current at this bus (complex phasor).
        % <@Role> Steady State
        % <@Type> complex double
        % <@Size> 1x1
        c_Iequilibrium      = 0;
    end
    properties (Dependent)

        % <@Desc> Power flow bus type string: "PQ", "PV", or "Slack".
        % <@Role> PowerFlow
        % <@Type> string
        % <@Size> 1x1
        str_bustype

        % <@Desc> Steady-state values including all connected controller states.
        % <@Role> Steady State
        % <@Type> double
        % <@Size> Nx1
        cv_Xequilibrium_all

        % <@Desc> Parameter table containing all bus parameters (dynamics, operation, powerflow, OPF, status, graph).
        % <@Role> Parameter
        % <@Type> table
        % <@Size> 1x1
        tab_parameter
    end
    properties (Hidden,SetAccess=protected)

        % <@Desc> Parameter container for bus dynamics settings (Gshunt, Bshunt).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_dynamics

        % <@Desc> Parameter container for AC OPF initialization settings.
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_OPF

        % <@Desc> Parameter container for power flow settings (V, Varg).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_powerflow

        % <@Desc> Parameter container for bus operating limits (baseKV, baseMVA, Vmin, Vmax).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_operation

        % <@Desc> Parameter container for bus status flags (fault).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_status

        % <@Desc> Parameter container for graph plotting settings (Xaxis, Yaxis, Marker).
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_graph
    end
    properties (Dependent, Access=protected)

        % <@Desc> Parent PowerNetwork object in the layer hierarchy.
        % <@Role> Layer Structure
        % <@Type> PowerNetwork
        % <@Size> 1x1
        parent

        % <@Desc> Child components and parameter objects in the layer hierarchy.
        % <@Role> Layer Structure
        % <@Type> cell array
        % <@Size> Nx1
        children
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)

        % <@Desc> ODE index mapping for bus state variables.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        iv_odeX  = zeros(0,1);

        % <@Desc> ODE index mapping for bus input variables.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        iv_odeU  = zeros(0,1);

        % <@Desc> Initial ODE state vector [Re(V); Im(V)] for the bus.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> 2x1
        rv_odeX0 = zeros(2,1);
    end
    properties (Access=public)

        % <@Desc> User-defined initial state values for the bus simulation.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        rv_odeInit
    end
    properties (Access={?odeSimulator})

        % <@Desc> Flag indicating whether a fault is currently applied to this bus.
        % <@Role> Simulation
        % <@Type> logical
        % <@Size> 1x1
        l_isFault (1,1) logical = false
    end
    properties (Access={?odeSimulator, ?odeLinearizer})

        % <@Desc> Flag indicating whether this bus is a non-unit bus (no connected Component).
        % <@Role> Simulation
        % <@Type> logical
        % <@Size> 1x1
        l_isNonUnit (1,1) logical = false
    end

%% Constructor
    methods (Access={?PowerNetwork ?Bus})
        function obj = Bus(tag,opt)
        % <@Desc>
        % Creates a Bus instance with the given tag and parameter options.
        % This constructor is called internally by PowerNetwork.add_bus().
        % <@Role>
        % Constructor
        % <@Abst>
        % Initialize all parameter containers and register bus parameters.
        % <@Signatures>
        % [
        %   "obj = Bus(tag, opt)"
        % ]
        % <@varargin>
        % [
        %   {
        %     "Name": "tag",
        %     "Type": "string scalar",
        %     "Description": "Tag string to identify this bus.",
        %     "Required": true,
        %     "Default": "-"
        %   },
        %   {
        %     "Name": "opt",
        %     "Type": "struct",
        %     "Description": "Option struct with bus parameters (V, Varg, Gshunt, Bshunt, Vmin, Vmax, baseKV, baseMVA, etc.).",
        %     "Required": true,
        %     "Default": "-"
        %   }
        % ]
        % <@varargout>
        % [
        %   {
        %     "Name": "obj",
        %     "Type": "Bus",
        %     "Description": "Created Bus instance."
        %   }
        % ]
            % arguments is satisfied in the caller function (PowerNetwork.add_bus), so no need to validate here.
            % arguments
            %     tag                   (1,1) string = "Bus";
            %     opt.Varg              (1,1) double = 0 /180*pi;
            %     opt.V                 (1,1) double = 1;
            %     opt.Gshunt            (1,1) double = 0;
            %     opt.Bshunt            (1,1) double = 0;
            %     opt.Vmin              (1,1) double = 0.5;
            %     opt.Vmax              (1,1) double = 1.5;
            %     opt.baseKV            (1,1) double = 230;
            %     opt.baseMVA           (1,1) double = 100;
            %     opt.OPFinit_Varg0     (1,1) double = 0 /180*pi;
            %     opt.OPFinit_V0        (1,1) double = 1;
            %     opt.GraphXaxis        (1,1) double = nan;
            %     opt.GraphYaxis        (1,1) double = nan;
            %     opt.GraphMarker       (1,1) string = "s";
            % end
            obj.str_tag        = tag;
            obj.para_dynamics  = Parameter(obj,"dynamics");
            obj.para_operation = Parameter(obj,"operation");
            obj.para_OPF       = Parameter(obj,"OPF");
            obj.para_status    = Parameter(obj,"status");
            obj.para_powerflow = Parameter(obj,"powerflow");
            obj.para_graph     = Parameter(obj,"graph");
            
            obj.para_dynamics.add_entry(  "Gshunt", opt.Gshunt        , "double",...
                                          "Bshunt", opt.Bshunt        , "double");
            obj.para_operation.add_entry( "baseKV", opt.baseKV        , "double",...
                                         "baseMVA", opt.baseMVA       , "double",...
                                            "Vmin", opt.Vmin          , "double",...
                                            "Vmax", opt.Vmax          , "double");
            obj.para_OPF.add_entry(        "Varg0", opt.OPFinit_Varg0 , "double",...
                                              "V0", opt.OPFinit_V0    , "double");
            obj.para_status.add_entry(     "fault", false             , "logical");
            obj.para_powerflow.add_entry(      "V", opt.V             , "double",...
                                            "Varg", opt.Varg          , "double");
            obj.para_graph.add_entry(      "Xaxis", opt.Xaxis         , "double",...
                                           "Yaxis", opt.Yaxis         , "double",...
                                          "Marker", opt.Marker        , "string");
        end

        % Layer Structure
        set_network(obj,a_PowerNetwork)
        
        % Set equilibrium
        set_equilibrium(obj, c_V, c_I, r_P, r_Q, opt)

        % Build component
        c = build_component(obj, key, varargin)
    end
    
    methods
        % Layer Structure
        add_component(obj,a_component)
        remove_component(obj,str_tag)
        replace_component(obj, str_tag, Type, opt)

        % PF(powerflow) calculation
        tab_PFset    = get_pf_set(obj)

        % OPF
        [prob, x0, const, Vvar] = build_opf_problem(obj, prob, x0, const, Vvar, option)

        % ODE
        [n_odeX, n_odeU, Mass, x0] = reset_odeset(obj, n_odeX, n_odeU, omega0)

        %get_sys
        sys = get_sys(obj, opt)
    end

%% Get Methods
    methods
        function type = get.str_bustype(obj)
            s = obj.get_pf_set;
            type = s.Type;
        end
        function tp = get.tab_parameter(obj)
            dynamics  =  obj.para_dynamics.tab_parameter;
            operation =  obj.para_operation.tab_parameter;
            powerflow =  obj.para_powerflow.tab_parameter;
            OPF       =  obj.para_OPF.tab_parameter;
            status    =  obj.para_status.tab_parameter;
            graph     =  obj.para_graph.tab_parameter;
            tp        =  table(dynamics,operation,powerflow,status,OPF,graph);
        end
        function x = get.cv_Xequilibrium_all(obj)
            x_com = tools.vcellfun(@(comp) comp.cv_Xequilibrium_all, obj.a_Component);
            x     = [obj.cv_Xequilibrium; x_com];
        end
        function p = get.parent(obj)
            p = obj.a_PowerNetwork; 
        end
        function p = get.children(obj)
            p = [ obj.a_Component;   ...
                 {obj.para_dynamics; ...
                  obj.para_operation;...
                  obj.para_powerflow;...
                  obj.para_OPF;      ...
                  obj.para_status;
                  obj.para_graph}];
        end
    end

%% Set Methods
    methods
        function set.cv_Xequilibrium(~,~)
            error(msg('GUILDA:Bus:SetXeq'))
        end
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
        function set.l_isSlack(obj,val)
            if val
                a_com = obj.a_Component;%#ok
                if isempty(a_com)
                    error(msg('GUILDA:Bus:NonUnitBus' ,string(obj)))
                end
                disp("INFO: "+string(obj)+" set as slack bus. ")
                disp("      P and Q specifications for "+string(a_com{1})+" ignored in powerflow calculation.")
                for busi = obj.a_PowerNetwork.a_Bus'%#ok
                    if busi{1}~=obj
                        busi{1}.l_isSlack = false; %#ok % Change l_isSlack to false for other buses
                    end
                end
                obj.l_isSlack = true;
            end
        end
    end
end