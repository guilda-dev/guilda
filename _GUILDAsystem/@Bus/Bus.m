classdef Bus < PowerSystemModel

%% Properties
    properties
        l_isSlack      (1,1) logical = false;   % Flag if bus is Slack Bus
    end
    properties (SetAccess=protected)
        a_PowerNetwork                          % Layer Structure
        a_Component                             % Layer Structure
        cv_Xequilibrium     = zeros(0,1);       % Steady State
        c_Vequilibrium      = 1;                % Steady State
        c_Iequilibrium      = 0;                % Steady State
    end
    properties (Dependent)
        str_bustype                             % PowerFlow
        cv_Xequilibrium_all                     % Steady State
        tab_parameter                           % Parameter
    end
    properties (Hidden,SetAccess=protected)
        para_dynamics                           % Parameter
        para_OPF                                % Parameter
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

%% Constructor
    methods (Access={?PowerNetwork ?Bus})
        function obj = Bus(tag,opt)
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

        % Graph plot
        [last_index, node, edge] = get_geometric(obj, last_index, tab_V, tab_PQ, sct_comp)
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