classdef Bus < PowerSystemModel
% Node of a power network that connects branches and components.
%
% A bus holds its components (generators, loads, ...) and its own parameters: shunt
% admittance (`tab_parameter.dynamics`), voltage limits and base voltage
% (`tab_parameter.operation`), power-flow settings (`tab_parameter.powerflow`) and
% diagram coordinates (`tab_parameter.graph`). Buses are created by
% `PowerNetwork.add_bus`, not by their constructor.
%
% The bus type for the power flow follows from the settings: the slack bus
% (`l_isSlack`) fixes V and Varg, a bus whose components leave Q as NaN is a PV bus, and
% any other bus is a PQ bus.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% bus = net.a_Bus{1};
% bus.tab_parameter.powerflow          % V, Varg, V0, Varg0
% bus.str_bustype                      % "slack", "PV" or "PQ"
% gen = bus.add_component("gen-park", P=0.5);
% bus.remove_component(gen.str_tag);
% sys = bus.get_sys();                 % linear model from V to I
% ```
%
% See also PowerNetwork.add_bus, Component, Branch

    %% Properties
    properties (Dependent) % Power Flow
        str_bustype              % Power-flow type of the bus: "slack", "PV" or "PQ".
        tab_parameter            % Parameter table: dynamics, operation, powerflow and graph.
        c_Iequilibrium           % [pu] Current injection at the equilibrium: sum of the component currents (0 without components).
    end
    properties % Power Flow
        l_isSlack      (1,1) logical = false;   % True for the slack bus (at most one per network).
    end
    properties (Access={?odeSimulator, ?odeEventSet})
        l_isFault (1,1) logical = false
    end

    properties (SetAccess=protected) % Layer Structure
        a_PowerNetwork                          % PowerNetwork the bus belongs to ([] when removed).
        a_Component (:,1) = cell(0,1)           % Components connected to the bus.
        c_Vequilibrium      = 1;                % [pu] Voltage phasor at the equilibrium (the bus owns it; components read it).
        s_opffcn = opffcn.default()             % OPF terms (Cost, Constraint, DefaultConstraint) set by set_opffcn.
    end
    properties (Hidden,SetAccess=protected) % Parameter
        para_dynamics                           % Parameter: Gshunt, Bshunt
        para_powerflow                          % Parameter: V, Varg, V0, Varg0
        para_operation                          % Parameter: baseKV, Vmin, Vmax
        para_graph                              % Parameter: Xaxis, Yaxis, Marker
    end
    properties (Dependent, Access=protected) % Layer Structure
        parent                                  % Layer Structure
        children                                % Layer Structure
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)
        iv_odeX  = zeros(0,1);
        iv_odeI  = zeros(0,1);
        iv_odeU  = zeros(0,1);
    end
    properties (SetAccess={?ContinuationPowerFlow})
        iv_CPFV = zeros(0,1)        
    end

%% Constructor
    methods (Access={?PowerNetwork ?Bus})
        function obj = Bus(net,tag,opt)
            % Create a bus of the network net (called by PowerNetwork.add_bus).
            obj.a_PowerNetwork = net;
            obj.str_tag        = tag;
            obj.para_dynamics  = Parameter(obj,"dynamics");
            obj.para_operation = Parameter(obj,"operation");
            obj.para_powerflow = Parameter(obj,"powerflow");
            obj.para_graph     = Parameter(obj,"graph");
            
            obj.para_dynamics.add_entry(  "Gshunt", opt.Gshunt   , "double",...
                                          "Bshunt", opt.Bshunt   , "double");
            obj.para_operation.add_entry( "baseKV", opt.baseKV   , "double",...
                                            "Vmin", opt.Vmin     , "double",...
                                            "Vmax", opt.Vmax     , "double");
            obj.para_powerflow.add_entry(      "V", opt.V        , "double",...
                                            "Varg", opt.Varg     , "double",...
                                              "V0", opt.V0       , "double",...
                                           "Varg0", opt.Varg0    , "double");
            obj.para_graph.add_entry(      "Xaxis", opt.Xaxis    , "double",...
                                           "Yaxis", opt.Yaxis    , "double",...
                                          "Marker", opt.Marker   , "string");
        end
        
        % Set equilibrium
        set_equilibrium(obj, c_V, c_I, r_P, r_Q, opt)
    end
    methods (Access={?PowerNetwork})
        function set_network(obj, net)
            % net = [] detaches the bus (PowerNetwork.remove_bus)
            obj.a_PowerNetwork = net;
        end
    end
    
    methods
        % Layer Structure
        remove_component(obj,str_tag)
        comp = add_component(obj,Type,varargin)
        comp = replace_component(obj, str_tag, Type, parameter)

        % PF(powerflow) calculation
        tab_PFset    = get_pf_set(obj)

        % OPF
        [prob, x0, const, Vvar] = build_opf_problem(obj, prob, x0, const, Vvar, option)

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
            graph     =  obj.para_graph.tab_parameter;
            tp        =  table(dynamics,operation,powerflow,graph);
        end
        function I = get.c_Iequilibrium(obj)
            % Components without an equilibrium yet (c_Iequilibrium = []) add nothing.
            if isempty(obj.a_Component)
                I = 0;
            else
                I = sum(tools.vcellfun(@(c) c.c_Iequilibrium, obj.a_Component));
            end
        end
        function p = get.parent(obj)
            p = obj.a_PowerNetwork; 
        end
        function p = get.children(obj)
            p = [ obj.a_Component;   ...
                 {obj.para_dynamics; ...
                  obj.para_operation;...
                  obj.para_powerflow;...
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
            if val == obj.l_isSlack
                return
            end
            if val
                a_com = obj.a_Component;%#ok
                if isempty(a_com)
                    error(msg('GUILDA:Bus:NonUnitBus' ,string(obj)))
                else
                    disp(msg('GUILDA:Bus:SetSlack' ,string(obj),string(a_com{1})))
                end
            end
            obj.l_isSlack = val;
            % Reported to the network, which keeps at most one slack bus by
            % releasing the other buses (PowerNetwork.handle_edit).
            if val
                obj.log_edit("slack bus -> "+obj.str_tag,"Slack");
            else
                obj.log_edit("slack bus released: "+obj.str_tag,"Slack");
            end
        end
    end
end