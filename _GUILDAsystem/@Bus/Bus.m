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
%   powerflow or dynamics (shunt), a slack-bus change and a component added, replaced or
%   removed make the power flow of the network stale (`net.sct_stale.powerflow`);
%   operation and graph make nothing stale. A bus has no stale tags of its own.
% - Down: splits the equilibrium bus power among its components (`set_equilibrium`).
%   Up: aggregates them (current, linear model, variable map).
% - Does not own the system base (baseMVA belongs to `PowerNetwork`; a bus baseMVA given
%   to `add_bus` or in a CSV bus table is accepted and ignored), the branches that end at
%   it (a branch only refers to it; a bus does not know its branches), or any dynamics
%   (components carry the equations).
% - Created only by `PowerNetwork.add_bus`. Only the parent sets and clears a parent
%   reference: the network sets `a_PowerNetwork`, and the bus sets `Component.a_Bus` of
%   its components.
%
% What differs from bus to bus (slack, PV, PQ, shunt) is data, not a type, so Bus has
% no subclasses.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% bus = net.a_Bus{1};
% bus.tab_parameter.powerflow          % V, Varg, V0, Varg0
% bus.s_bustype                        % "slack", "PV" or "PQ"
% gen = bus.add_component("gen-park", P=0.5);
% bus.remove_component(gen.s_tag);
% sys = bus.get_sys();                 % linear model from V to I
% ```
%
% See also PowerNetwork.add_bus, Component, Branch

    %% Properties
    properties (Dependent) % Power Flow
        s_bustype                         % Power-flow type of the bus: "slack", "PV" or "PQ" (from get_pf_condition).
        c_Iequilibrium                    % [pu] Current injection at the equilibrium: sum of the component currents (0 without components).
    end
    properties % Power Flow
        l_isSlack (1,1) logical = false;  % True for the slack bus (at most one per network; setting it requires a component). <@Stale> powerflow
    end
    properties (Access={?SolverODE}) % Simulation working data
        l_isFault (1,1) logical = false   % True while an active fault of a scenario is applied at the bus (simulation working data).
    end

    properties (SetAccess={?PowerNetwork}) % Layer Structure
        a_PowerNetwork = []               % PowerNetwork the bus belongs to ([] when removed). <@Type> PowerNetwork
    end
    properties (SetAccess=protected) % Layer Structure
        a_Component (:,1) = cell(0,1)     % Components connected to the bus. <@Stale> powerflow
        c_Vequilibrium = 1;               % [pu] Voltage phasor at the equilibrium (owned by the bus; components and controllers read it).
    end
    properties (Dependent, Access=protected) % Layer Structure
        parent                            % Parent in the layer structure: the network.
        children                          % Children in the layer structure: the components, then the Parameter objects.
    end
    properties (SetAccess={?SolverODE, ?Component}, Hidden) % Simulation working data
        iv_odeX = zeros(0,1);             % Positions of the bus voltage [Vre; Vim] in the simulation vector.
        iv_odeI = zeros(0,1);             % Positions of the bus current [Ire; Iim] in the simulation vector.
        iv_odeU = zeros(0,1);             % Not set by the simulation (a bus has no inputs).
    end
    properties (SetAccess={?SolverCPF}) % Continuation Power Flow
        iv_CPFV = zeros(0,1)              % Indices of the bus voltage in the CPF variable vector (CPF working data).
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
            obj.s_tag          = tag;
            % tab_parameter columns:
            % - dynamics: shunt admittance Gshunt, Bshunt [pu], added to the diagonal of the network admittance matrix
            % - operation: Vmin, Vmax [pu]: OPF voltage bounds (-Inf/Inf: none); baseKV [kV]: base voltage, stored but used in no calculation
            % - powerflow: V [pu], Varg [rad]: voltage settings of a slack bus (V also of a PV bus); V0 [pu], Varg0 [rad]: solver initial values
            % - graph: Xaxis, Yaxis: drawing position (NaN: automatic layout); Marker: marker of the bus

            a_Pd = Parameter(obj, "dynamics", struct( ...
                "Gshunt", opt.Gshunt, ...
                "Bshunt", opt.Bshunt));
            a_Po = Parameter(obj, "operation", struct( ...
                "baseKV", opt.baseKV, ...
                  "Vmin", opt.Vmin, ...
                  "Vmax", opt.Vmax));
            a_Pp = Parameter(obj, "powerflow", struct( ...
                    "V", opt.V, ...
                 "Varg", opt.Varg, ...
                   "V0", opt.V0, ...
                "Varg0", opt.Varg0));
            a_Pg = Parameter(obj, "graph", struct( ...
                 "Xaxis", opt.Xaxis, ...
                 "Yaxis", opt.Yaxis, ...
                "Marker", opt.Marker));
            obj.a_Parameter = {a_Pd; a_Po; a_Pp; a_Pg};
        end
        
        % Set equilibrium
        set_equilibrium(obj, c_V, c_I, r_P, r_Q, opt)
    end
    methods (Access={?PowerNetwork})
        initialize(obj)
    end
    
    methods
        % Layer Structure
        remove_component(obj,s_tag)
        % <@Group> Construction and editing
        comp = add_component(obj,Type,varargin)
        % <@Group> Construction and editing
        comp = replace_component(obj, s_tag, Type, parameter)

        % PF(powerflow) calculation
        tab_PFcondition = get_pf_condition(obj)

        %get_sys
        [sys, varargout] = get_sys(obj, opt)
    end

%% Get Methods
    methods
        function type = get.s_bustype(obj)
            s = obj.get_pf_condition;
            type = s.Type;
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
            p = [obj.a_Component; obj.a_Parameter];
        end
    end

%% Set Methods
    methods
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
                    i_rest = find(cellfun(@(c) isnan(c.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", c.a_Parameter)}.tab_parameter.Q), a_com), 1);
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
                obj.log_edit("slack bus -> "+obj.s_tag,"Slack");
            else
                obj.log_edit("slack bus released: "+obj.s_tag,"Slack");
            end
        end
    end
end