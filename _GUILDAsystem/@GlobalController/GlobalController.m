classdef GlobalController < PowerSystemModel
% Abstract class of a controller that acts on several components of a network, such as an AGC.
%
% A global controller is a dynamic model with states x, inputs u and outputs y. Its
% inputs are states of the controlled components (`controlledUnits`), read by the names
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
% - Inputs `sv_u`: states of each controlled unit, matched by name in the `sv_x` of the
%   unit. Outputs `sv_y`: added to the inputs of the same name in the `sv_u` of the unit.
%   For example, `controller.agc.broadcast_PI_AGC` reads the speed state "omega" of each
%   generator and adds to its input "Pmech".
% - Unlike a `LocalController`: no port V or I (its functions receive [] or zeros(2,1),
%   which they must not use), no nested controller, no observation by output name. It
%   does not own its units and is not a child of any bus.
% - Only the network sets and clears `a_PowerNetwork` (`PowerNetwork.add_global_controller`
%   calls `set_parent`, which marks the handles stale).
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

    properties(Abstract, Constant, Hidden=true)
        key      (1,1) string   % Kind of controller.
        sv_x    (:,1) string    % Names of the states.
        sv_u    (:,1) string    % Names of the inputs (states of the controlled units).
        sv_y    (:,1) string    % Names of the outputs (inputs of the controlled units).
        sv_para (:,1) string    % Names of the dynamic parameters passed to the model functions.
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

    % Handle cache @(t,x,V,I,u) with param and omega0 bound (set_odefcn, called by check_edit).
    properties(SetAccess=protected) % Dynamics
        f_Mass                                 % Mass matrix function @(t,x,V,I,u) with the parameters bound.
        f_dx                                   % State equation function @(t,x,V,I,u) with the parameters bound.
        f_Y                                    % Output function @(t,x,V,I,u) with the parameters bound.

        f_JacobiDx                             % Jacobian function of f_dx.
        f_JacobiY                              % Jacobian function of f_Y.
    end    
    properties (SetAccess=protected) % Layer Structure
        a_PowerNetwork                         % PowerNetwork the controller belongs to (set by add_global_controller).
    end
    properties (SetAccess=protected, Hidden)
        controlledUnits                        % Controlled components, in the order given to the constructor.
    end
    properties (SetAccess={?SolverODE}, Hidden)
        iv_odeX (:,1) double = zeros(0,1);
        iv_odeU (:,1) double = zeros(0,1);
        iv_odeY (:,1) double = zeros(0,1);        

        rv_Xoffset = 0
        rv_Uoffset = @(t) 0

        l_isConnect (1,1) logical = true       % False while an active trip of a scenario names the controller (set by SolverODE); its output is then zero.
    end        
    properties(SetAccess={?PowerNetwork}) % Steady State
        rv_Xequilibrium (:,1) double = zeros(0,1)   % State equilibrium (from get_equilibrium, set by PowerNetwork.initialize).
        rv_Uequilibrium (:,1) double = zeros(0,1)   % Equilibrium of the observed states, one entry per input of each unit.
    end    
    properties(SetAccess=protected) % Parameter
        para_dynamics                          % Parameter object of tab_parameter.dynamics.
    end
    properties(Dependent) % Parameter
        tab_parameter                          % Parameter table (dynamics): one row per controlled unit (row names: the unit tags); the columns sv_para are passed as param. An edit makes the handles and the equilibrium stale.
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent                                 % Layer Structure: the network.
        children                               % Layer Structure: none.
    end
    
    methods
        function obj = GlobalController(net, tag, varargin)
            % Create a global controller of the network net that controls the given components.
            %
            % `varargin` lists the controlled components of net, as Component objects or
            % tags. Anything else stops with GUILDA:GlobalController:InvalidComponent.
            obj.str_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");

            cls_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);            
            cls_comp = vertcat(cls_comp{:});            

            idx = 1;
            while idx <= nargin-2
                arg = varargin{idx};
                if isa(arg, 'Component')
                    varargin{idx} = arg.str_tag;
                end

                lv_comp = strcmp(varargin{idx}, string(cls_comp));
                % A component of another network can have the same tag as one of net
                if all(~lv_comp) || (isa(arg, 'Component') && cls_comp{lv_comp} ~= arg)
                    if isa(arg, 'Component') || isstring(arg) || ischar(arg)
                        str_arg = char(strjoin(string(varargin{idx})));
                    else
                        str_arg = class(arg);
                    end
                    error(msg("GUILDA:GlobalController:InvalidComponent", str_arg, char(tag), char(net.str_tag)))
                end

                obj.controlledUnits = [obj.controlledUnits; cls_comp(lv_comp)];

                idx = idx + 1;
            end
            
        end

        % get sys
        function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
            % Linearize the global controller.
            %
            % The inputs are the outputs of the controlled units and the outputs are the
            % controller outputs that feed them; the V and I ports are not used. The output
            % sys is a descriptor state-space model (dss) with state, input and output names;
            % `varargout` gives sys.StateName, sys.InputName and sys.OutputName as on the
            % other layers.
            %
            % Out-of-date f_* handles are built first. A controller on a network stops with the
            % error GUILDA:PowerNetwork:EquilibriumStale when net.initialize() is needed.
            % A controlled unit without the states sv_u or the inputs sv_y stops with the
            % error GUILDA:GlobalController:GlobalControllerPort.
            %
            % See also GlobalController.get_hessian, PowerNetwork.get_sys
            %
            % <@Group> Called by analyses
            arguments
                obj                 
                x        (:,1) double  = obj.rv_Xequilibrium   % States (default: the equilibrium).
                V        (:,1) double  = zeros(2,1)   % Not a port: zeros(2,1).
                I        (:,1) double  = zeros(2,1)   % Not a port: zeros(2,1).
                u        (:,1) double  = obj.rv_Uequilibrium   % Inputs (default: the equilibrium).
                opt.full (1,1) logical = false  % Ignored; kept for old calls.
            end

            a_Comp = obj.controlledUnits;
            for k = 1:numel(a_Comp)
                s = a_Comp{k};
                if ~all(ismember(obj.sv_u, s.sv_x)) || ~all(ismember(obj.sv_y, s.sv_u))
                    error(msg("GUILDA:GlobalController:GlobalControllerPort", obj.str_tag, join(obj.sv_u, " "), join(obj.sv_y, " "), s.str_tag, class(s), join(s.sv_x, " "), join(s.sv_u, " ")))
                end
            end

            obj.check_edit();
            if ~isempty(obj.a_PowerNetwork)
                net = obj.a_PowerNetwork;
                if net.s_edit.str_flag == "unset" || net.s_edit.l_staleEquilibrium
                    net.check_edit("RequireEquilibrium", true);
                end
            end

            % Same Jacobian contract as SolverODE: f_JacobiDx/Y(t,x,V,I,u).
            % A global controller has no V port, so only the u columns are used.
            nx = numel(x);
            nu = numel(u);
            [Axx,~,~,Bxu] = obj.f_JacobiDx(0,x,V,I,u);
            [Cyx,~,~,Dyu] = obj.f_JacobiY( 0,x,V,I,u);
            ny = size(Cyx,1);

            A = reshape(Axx,nx,nx);
            B = reshape(Bxu,nx,nu);
            C = reshape(Cyx,ny,nx);
            D = reshape(Dyu,ny,nu);

            E = obj.f_Mass(0,x,V,I,u);

            sys = dss(A,B,C,D,E);

            xNames = obj.attach_tag(obj.sv_x);
            uNames = cellfun(@(s) s.attach_tag(obj.sv_u), a_Comp);
            yNames = cellfun(@(s) s.attach_tag(obj.sv_y), a_Comp);

            sys.StateName  = xNames;
            sys.InputName  = uNames;
            sys.OutputName = yNames;

            varargout{1} = sys.StateName;
            varargout{2} = sys.InputName;
            varargout{3} = sys.OutputName;
        end
    end   
    methods (Access=protected)
        function set_odefcn(obj)
            % Bind the parameters and the network frequency into the f_* function handles.
            % Called by check_edit when the handles are not up to date (str_odefcn "unset" or
            % "editted": a dynamics edit, a network Hz edit or an attach since the last build).
            %
            % <@Group> Called by analyses
            omega0 = obj.get_Hz();
            param = obj.tab_parameter.dynamics{:,obj.sv_para};

            obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t,x,V,I,u,param,omega0);
            obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t,x,V,I,u,param,omega0);
            obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t,x,V,I,u,param,omega0);
            
            obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
            obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
            obj.s_edit.str_odefcn = "updated";
        end
    end
    methods (Access={?Component,?LocalController,?PowerNetwork})        
        function set_parent(obj,net)
            % net = [] detaches the controller (PowerNetwork.remove_global_controller)
            %
            % <@Group> Construction and attachment
            obj.a_PowerNetwork = net;
            obj.mark_odefcn();        % the handles read the frequency of the network
        end
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