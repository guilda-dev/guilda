classdef Bus < PowerSystemModel
% Node of a power network: owns the bus voltage and its components.
%
% The bus voltage is the algebraic variable of the network. A bus turns the settings of
% its components into the power-flow specification of the node.
%
% - Owns its voltage (power-flow settings and the equilibrium `c_Vequilibrium`), its shunt
%   admittance, its voltage limits and the list of its components (`a_Component`).
% - The power-flow type (slack, PV, PQ) is not stored: it follows from `l_isSlack` and the
%   Q settings of the components. The slack bus fixes V and Varg, a bus whose components
%   leave Q as NaN is a PV bus, and any other bus is a PQ bus. Setting `l_isSlack` makes the
%   network clear the flag of the other buses (a bus never changes another bus); with no
%   slack bus, `calculate_powerflow` selects one.
% - Parameters (`tab_parameter`) are set by `add_bus` or by writing the table. An edit of
%   powerflow or dynamics makes the equilibrium stale; operation and graph make nothing stale.
% - Down: splits the equilibrium bus power among its components (`set_equilibrium`).
%   Up: aggregates them (current, linear model, variable map, OPF variables).
% - Does not own the system base (baseMVA belongs to `PowerNetwork`; a bus baseMVA given
%   to `add_bus` or in a CSV bus table is accepted and ignored), the branches that end at
%   it (a branch only refers to it; a bus does not know its branches), or any dynamics
%   (components carry the equations).
% - Created only by `PowerNetwork.add_bus`. Only the parent sets and clears a parent
%   reference: the network sets `a_PowerNetwork`, and the bus sets `Component.a_Bus` of
%   its components. Attaching a component marks the handles of that component and its
%   controllers stale.
%
% What differs from bus to bus (slack, PV, PQ, shunt) is data, not a type, so Bus has
% no subclasses.
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
        str_bustype  % Power-flow type of the bus: "slack", "PV" or "PQ" (from get_pf_set).
        c_Iequilibrium  % [pu] Current injection at the equilibrium: sum of the component currents (0 without components).
    end
    properties % Power Flow
        l_isSlack (1,1) logical = false;  % True for the slack bus (at most one per network; setting it requires a component). <@Stale> equilibrium
    end
    properties (Access={?SolverODE}) % Simulation working data
        l_isFault (1,1) logical = false  % True while an active fault of a scenario is applied at the bus (simulation working data).
    end

    properties (SetAccess=protected) % Layer Structure
        a_PowerNetwork  % PowerNetwork the bus belongs to ([] when removed).
        a_Component (:,1) = cell(0,1)  % Components connected to the bus. <@Stale> equilibrium
        c_Vequilibrium = 1;  % [pu] Voltage phasor at the equilibrium (owned by the bus; components and controllers read it).
    end
    properties (SetAccess=protected) % OPF
        f_opfcost = []  % OPF cost handle @(v, p) from set_opffcn; replaces the default cost of the bus ([]: none). <@Stale> nothing (logged)
        f_opfconst = []  % OPF constraint handle @(v, p) from set_opffcn, returning a struct of named constraints ([]: none). <@Stale> nothing (logged)
        l_opfdefault = true  % Whether the default OPF constraints of the bus are kept (DefaultConstraint of set_opffcn). <@Stale> nothing (logged)
    end
    properties (Dependent) % Parameter
        tab_parameter  % Parameter table: the para_* tables side by side; writing it writes the parameters.
    end
    properties (Hidden,SetAccess=protected) % Parameter
        para_dynamics  % Shunt admittance Gshunt, Bshunt [pu], added to the diagonal of the network admittance matrix.
        para_powerflow  % V [pu], Varg [rad]: voltage settings of a slack bus (V also of a PV bus); V0 [pu], Varg0 [rad]: solver initial values.
        para_operation  % Vmin, Vmax [pu]: OPF voltage bounds; baseKV [kV]: base voltage, stored but used in no calculation.
        para_graph  % Xaxis, Yaxis: drawing position (NaN: automatic layout); Marker: marker of the bus.
    end
    properties (Dependent, Access=protected) % Layer Structure
        parent  % Parent in the layer structure: the network.
        children  % Children in the layer structure: the components, then the Parameter objects.
    end
    properties (SetAccess={?SolverODE, ?Component}, Hidden) % Simulation working data
        iv_odeX = zeros(0,1);  % Positions of the bus voltage [Vre; Vim] in the simulation vector.
        iv_odeI = zeros(0,1);  % Positions of the bus current [Ire; Iim] in the simulation vector.
        iv_odeU = zeros(0,1);  % Not set by the simulation (a bus has no inputs).
    end
    properties (SetAccess={?SolverCPF}) % Continuation Power Flow
        iv_CPFV = zeros(0,1)  % Indices of the bus voltage in the CPF variable vector (CPF working data).
    end

%% Constructor
    methods (Access={?PowerNetwork ?Bus})
        function obj = Bus(net,tag,opt)
            % Create a bus of the network net (called by PowerNetwork.add_bus).
            arguments (Input)
                net (1,1) PowerNetwork   % Network the bus belongs to.
                tag (1,1) string         % Tag of the bus.
                opt (1,1) struct         % Bus settings of add_bus (without Tag and FullTag).
            end
            arguments (Output)
                obj   % New Bus object.
            end
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
            % Set the network of the bus; net = [] detaches it (PowerNetwork.remove_bus).
            %
            % <@Group> Construction and editing
            arguments (Input)
                obj
                net   % PowerNetwork, or [] to detach the bus.
            end
            obj.a_PowerNetwork = net;
        end
    end
    
    methods
        % Layer Structure
        remove_component(obj,str_tag)
        % <@Group> Construction and editing
        comp = add_component(obj,Type,varargin)
        % <@Group> Construction and editing
        comp = replace_component(obj, str_tag, Type, parameter)

        % PF(powerflow) calculation
        tab_PFset    = get_pf_set(obj)

        % OPF
        [prob, x0, const, Vvar] = build_opf_problem(obj, prob, x0, const, Vvar, option)

        %get_sys
        [sys, varargout] = get_sys(obj, opt)
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
                    error(msg("GUILDA:Bus:NonUnitBus", string(obj)))
                else
                    % the component that takes the remaining P (Bus.set_equilibrium)
                    i_rest = find(cellfun(@(c) isnan(c.para_powerflow.Q), a_com), 1);
                    disp(msg('GUILDA:Bus:SetSlack' ,string(obj),string(a_com{max([i_rest,1])})))
                    if isempty(i_rest)
                        warning(msg("GUILDA:Bus:SlackWithoutQnan", string(obj), string(a_com{1})))
                    end
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