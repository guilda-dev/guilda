classdef GlobalController < PowerSystemModel
% Abstract class of a controller that acts on several components of a network, such as an AGC.
%
% A global controller is a dynamical system with state $x$, input $u$ and output $y$. Its
% input signals are states of the controlled components (`controlledUnits`), read by the names
% in `sv_u`, and its outputs are inputs of those components. Subclasses in the
% `controller` package define the static model functions (`fcn_dx`, `fcn_y`, `fcn_Mass`), their Jacobians and the
% variable names. A global controller is built for a network and added with
% `PowerNetwork.add_global_controller`.
%
% - Owns its parameters (one row per controlled unit), its equations (through its
%   subclass) and its equilibrium. Its parent is the network.
% - The components it acts on, `controlledUnits`, are associations fixed by its
%   constructor, which receives the network only to look them up. While the controller is
%   on the network, its units cannot be removed or replaced, nor their buses removed.
% - Input signals `sv_u`: states of each controlled unit, matched by name in the `sv_x` of the
%   unit. Output signals `sv_y`: added to the inputs of the same name in the `sv_u` of the unit.
%   For example, `controller.agc.broadcast_PI_AGC` reads the speed state "omega" of each
%   generator and adds to its input "Pmech".
% - Unlike a `LocalController`: no port V or I (its functions receive [] or zeros(2,1),
%   which they must not use), no nested controller, no observation by output name. It
%   does not own its units and is not a child of any bus.
% - Only the network sets and clears `a_PowerNetwork` (`PowerNetwork.add_global_controller`
%   calls `set_parent`, which marks the handles stale).
% - The handles `f_*` @(t,x,V,I,u) bind param and omega0; `set_odefcn` builds them, called
%   by `check_edit`. An edit of `tab_parameter` makes the handles and the equilibrium stale.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% g1  = net.a_Bus{1}.a_Component{1};
% g2  = net.a_Bus{2}.a_Component{1};
% agc = controller.agc.broadcast_PI_AGC(net, "agc", g1, g2, alpha=[1;1], beta=[1;1], kP=100, kI=500);
% net.add_global_controller(agc);
% net.initialize();
% sys = agc.get_sys();
% ```
%
% See also PowerNetwork.add_global_controller, controller.agc.broadcast_PI_AGC, LocalController

    properties(Abstract, Constant, Hidden=true) % Subclass contract
        key (1,1) string  % Kind of controller.
        sv_x (:,1) string  % Names of the states.
        sv_u (:,1) string  % Names of the inputs (states of the controlled units).
        sv_y (:,1) string  % Names of the outputs (inputs of the controlled units).
        sv_para (:,1) string  % Names of the dynamic parameters passed to the model functions.
    end
    methods (Abstract)
        % Return the state and input equilibria of the controller.
        %
        % Returns x (nx x 1) and u (nu x 1). Takes no network values: PowerNetwork.initialize
        % calls it before it sets the equilibria of the buses and components.
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj)
    end
    methods (Abstract, Static)        
        % Return the state derivatives of the controller.
        %
        % The arguments of all model functions are the time t [s], the states x, the
        % ports V and I (a global controller has none: [] in a simulation, zeros(2,1) in
        % get_sys and get_hessian; do not use them), the inputs u, the dynamic parameters
        % param and the nominal frequency omega0 [Hz].
        dx = fcn_dx(t, x, V, I, u, param, omega0)

        % Return the outputs of the controller: one value per driven unit input, added to that input.
        y  = fcn_y(t, x, V, I, u, param, omega0)

        % Return the mass matrix of the state equation.
        %
        % It must be constant: simulate calls it with empty t, x, V, I and u.
        M  = fcn_Mass(t, x, V, I, u, param, omega0)
    end       

    properties(SetAccess=protected) % Cached function handles
        f_Mass  % Mass matrix function @(t,x,V,I,u) with the parameters bound.
        f_dx  % State equation function @(t,x,V,I,u) with the parameters bound.
        f_Y  % Output function @(t,x,V,I,u) with the parameters bound.
        f_JacobiDx  % Jacobian function of f_dx.
        f_JacobiY  % Jacobian function of f_Y.
    end
    properties (SetAccess=protected) % Layer Structure
        a_PowerNetwork  % PowerNetwork the controller belongs to (set by add_global_controller).
    end
    properties (SetAccess=protected, Hidden) % Layer Structure
        controlledUnits  % Controlled components, in the order given to the constructor.
    end
    properties (SetAccess={?SolverODE}, Hidden) % Simulation working data
        iv_odeX (:,1) double = zeros(0,1);  % Positions of the states in the simulation vector.
        iv_odeU (:,1) double = zeros(0,1);  % Positions of the observed unit states (the inputs) in the simulation vector.
        iv_odeY (:,1) double = zeros(0,1);  % Positions of the driven unit inputs (the outputs) in the simulation vector.
        rv_Xoffset = 0  % State offset added to the initial state (0 for a global controller).
        rv_Uoffset = @(t) 0  % Input change over time (zero for a global controller).
        l_isConnect (1,1) logical = true  % False while an active trip of a scenario names the controller (set by SolverODE); its output is then zero.
    end
    properties(SetAccess={?PowerNetwork}) % Steady State
        rv_Xequilibrium (:,1) double = zeros(0,1)  % State equilibrium (from get_equilibrium, set by PowerNetwork.initialize).
        rv_Uequilibrium (:,1) double = zeros(0,1)  % Equilibrium of the observed states, one entry per input of each unit.
    end
    properties(SetAccess=protected) % Parameter
        para_dynamics  % Dynamic parameters, one row per controlled unit; the sv_para columns are passed as param.
    end
    properties(Dependent) % Parameter
        tab_parameter  % Parameter table: the para_* tables side by side (row names: the unit tags); writing it writes the parameters.
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent  % Parent in the layer structure: the network.
        children  % Children in the layer structure: none.
    end

    methods
        function obj = GlobalController(net, tag, varargin)
            % Create a global controller of the network net that controls the given components.
            %
            % `varargin` lists the controlled components of net, as Component objects or
            % tags. Anything else stops with GUILDA:GlobalController:InvalidComponent.
            arguments (Input)
                net (1,1) PowerNetwork   % Network whose components are controlled.
                tag (1,1) string         % Tag of the controller.
            end
            arguments (Input, Repeating)
                varargin   % Controlled components of net, as Component objects or tags.
            end
            arguments (Output)
                obj   % New GlobalController object.
            end
            obj.s_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");

            cls_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);            
            cls_comp = vertcat(cls_comp{:});            

            idx = 1;
            while idx <= nargin-2
                arg = varargin{idx};
                if isa(arg, 'Component')
                    varargin{idx} = arg.s_tag;
                end

                lv_comp = strcmp(varargin{idx}, string(cls_comp));
                % A component of another network can have the same tag as one of net
                if all(~lv_comp) || (isa(arg, 'Component') && cls_comp{lv_comp} ~= arg)
                    if isa(arg, 'Component') || isstring(arg) || ischar(arg)
                        s_arg = char(strjoin(string(varargin{idx})));
                    else
                        s_arg = class(arg);
                    end
                    error(msg("GUILDA:GlobalController:InvalidComponent", s_arg, char(tag), char(net.s_tag)))
                end

                obj.controlledUnits = [obj.controlledUnits; cls_comp(lv_comp)];

                idx = idx + 1;
            end

        end

        % get sys
        [sys, varargout] = get_sys(obj, x, V, I, u, opt)
    end
    methods (Access=protected)
        set_odefcn(obj)
    end
    methods (Access={?Component,?LocalController,?PowerNetwork})        
        set_parent(obj,net)
    end
    methods        
        function p = get.parent(obj)
            p = obj.a_PowerNetwork;
        end
        function p = get.children(~) 
            p = {};
        end
        function tab = get.tab_parameter(obj)
            dynamics = obj.para_dynamics.tab_parameter;            
            dynamics.Properties.RowNames = string(obj.controlledUnits);
            tab = table(dynamics);
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
    end
end