classdef Bus < PowerSystemModel

%% Properties
    properties
        l_isSlack      (1,1) logical = false;   % Flag if bus is Slack Bus
    end
    properties (SetAccess=protected)
        a_PowerNetwork                          % Layer Structure
        a_Component                             % Layer Structure
        c_Vequilibrium      = 1;                % Steady State
        c_Iequilibrium      = 0;                % Steady State
    end
    properties (Dependent)
        str_bustype                             % PowerFlow
        tab_parameter                           % Parameter
    end
    properties (Hidden,SetAccess=protected)
        para_dynamics                           % Parameter
        para_powerflow                          % Parameter
        para_operation                          % Parameter
        para_status                             % Parameter
        para_graph                              % Parameter
    end
    properties (Dependent, Access=protected)
        parent                                  % Layer Structure
        children                                % Layer Structure
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)
        iv_odeX  = zeros(0,1);
        iv_odeI  = zeros(0,1);
        iv_odeU  = zeros(0,1);
        rv_odeX0 = zeros(2,1);
    end
    properties (Access=public)
        rv_odeInit
    end
    properties (Access={?odeSimulator, ?odeEventSet})
        l_isFault (1,1) logical = false
    end
    properties (Access={?odeSimulator, ?odeLinearizer})
        l_isNonUnit (1,1) logical = false
    end
    properties (SetAccess={?Continuation_Power_Flow})
        iv_CPFV = zeros(0,1)        
    end

%% Constructor
    methods (Access={?PowerNetwork ?Bus})
        function obj = Bus(tag,opt)
            obj.str_tag        = tag;
            obj.para_dynamics  = Parameter(obj,"dynamics");
            obj.para_operation = Parameter(obj,"operation");
            obj.para_status    = Parameter(obj,"status");
            obj.para_powerflow = Parameter(obj,"powerflow");
            obj.para_graph     = Parameter(obj,"graph");
            
            obj.para_dynamics.add_entry(  "Gshunt", opt.Gshunt   , "double",...
                                          "Bshunt", opt.Bshunt   , "double");
            obj.para_operation.add_entry( "baseKV", opt.baseKV   , "double",...
                                         "baseMVA", opt.baseMVA  , "double",...
                                            "Vmin", opt.Vmin     , "double",...
                                            "Vmax", opt.Vmax     , "double");
            obj.para_status.add_entry(     "fault", false        , "logical");
            obj.para_powerflow.add_entry(      "V", opt.V        , "double",...
                                            "Varg", opt.Varg     , "double",...
                                              "V0", opt.V0       , "double",...
                                           "Varg0", opt.Varg0    , "double");
            obj.para_graph.add_entry(      "Xaxis", opt.Xaxis    , "double",...
                                           "Yaxis", opt.Yaxis    , "double",...
                                          "Marker", opt.Marker   , "string");
        end

        % Layer Structure
        set_network(obj,a_PowerNetwork)
        
        % Set equilibrium
        set_equilibrium(obj, c_V, c_I, r_P, r_Q, opt)
    end
    
    methods
        % Layer Structure
        remove_component(obj,str_tag)
        comp = add_component(obj,Type,varargin)
        replace_component(obj, str_tag, Type, parameter)

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
            status    =  obj.para_status.tab_parameter;
            graph     =  obj.para_graph.tab_parameter;
            tp        =  table(dynamics,operation,powerflow,status,graph);
        end
        function p = get.parent(obj)
            p = obj.a_PowerNetwork; 
        end
        function p = get.children(obj)
            p = [ obj.a_Component;   ...
                 {obj.para_dynamics; ...
                  obj.para_operation;...
                  obj.para_powerflow;...
                  obj.para_status;   ...
                  obj.para_graph}];
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
        function set.l_isSlack(obj,val)
            if val
                a_com = obj.a_Component;%#ok
                if isempty(a_com)
                    error(msg('GUILDA:Bus:NonUnitBus' ,string(obj)))
                else
                    disp(msg('GUILDA:Bus:SetSlack' ,string(obj),string(a_com{1})))
                end
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