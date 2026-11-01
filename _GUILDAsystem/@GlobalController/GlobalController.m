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
    methods (Abstract, Static)        
        % Return the state derivatives of the controller.
        %
        % The arguments of all model functions are the time t [s], the states x, the
        % ports V and I (a global controller has none: [] in a simulation, zeros(2,1) in
        % get_sys and get_hessian; do not use them), the inputs u, the dynamic parameters
        % param and the nominal frequency omega0 [Hz].
        dx = fcn_dx(t, x, V, I, u, param, omega0)

        % Return the outputs of the controller.
        y  = fcn_y(t, x, V, I, u, param, omega0)

        % Return the mass matrix of the state equation.
        M  = fcn_Mass(t, x, V, I, u, param, omega0)
    end       
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
    properties (SetAccess={?odeSimulator, ?odeEventSet}, Hidden)
        iv_odeX (:,1) double = zeros(0,1);
        iv_odeU (:,1) double = zeros(0,1);
        iv_odeY (:,1) double = zeros(0,1);        

        rv_Xoffset = 0
        rv_Uoffset = @(t) 0

        l_isConnect (1,1) logical = true       % false while a trip event names it (set by odeSimulator); its output is zero
    end        
    properties(SetAccess={?PowerNetwork}) % Steady State
        rv_Xequilibrium (:,1) double = zeros(0,1)   % State equilibrium.
        rv_Uequilibrium (:,1) double = zeros(0,1)   % Input equilibrium.
    end    
    properties(SetAccess=protected) % Parameter
        para_dynamics                          % Parameter object of tab_parameter.dynamics.
    end
    properties(Dependent) % Parameter
        tab_parameter                          % Parameter table; one row per controlled unit.
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
                    error('GUILDA:GlobalController:InvalidComponent', '%s', ...
                          msg('GUILDA:GlobalController:InvalidComponent', str_arg, char(tag), char(net.str_tag)))
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
            % Stale f_* handles are rebuilt first. A controller on a network stops with the
            % error GUILDA:PowerNetwork:EquilibriumStale when net.initialize() is needed.
            % A controlled unit without the states sv_u or the inputs sv_y stops with the
            % error GUILDA:GlobalController:GlobalControllerPort.
            %
            % See also GlobalController.get_hessian, PowerNetwork.get_sys
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
                    error("GUILDA:GlobalController:GlobalControllerPort", ...
                          "The global controller '%s' needs the states [%s] and the inputs [%s] of its units, but '%s' (%s) has the states [%s] and the inputs [%s].", ...
                          obj.str_tag, join(obj.sv_u, " "), join(obj.sv_y, " "), s.str_tag, class(s), join(s.sv_x, " "), join(s.sv_u, " "))
                end
            end

            obj.check_edit();
            if ~isempty(obj.a_PowerNetwork)
                net = obj.a_PowerNetwork;
                if net.s_edit.str_flag == "unset" || net.s_edit.l_staleEquilibrium
                    net.check_edit("RequireEquilibrium", true);
                end
            end

            % Same Jacobian contract as odeSimulator: f_JacobiDx/Y(t,x,V,I,u).
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
        function set_odefcn(obj, omega0)
            % Bind the parameters and the frequency omega0 into the f_* function handles.
            param = obj.tab_parameter.dynamics{:,obj.sv_para};

            obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t,x,V,I,u,param,omega0);
            obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t,x,V,I,u,param,omega0);
            obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t,x,V,I,u,param,omega0);
            
            obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
            obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
            obj.s_edit.l_staleOdefcn = false;
        end

        function rebuild_odefcn(obj)
            % Called by check_edit after a dynamics edit or a network Hz edit.
            obj.set_odefcn(obj.r_Hz);
        end
    end
    methods (Access={?Component,?LocalController,?PowerNetwork})        
        function set_parent(obj,net)
            % net = [] detaches the controller (PowerNetwork.remove_global_controller)
            obj.a_PowerNetwork = net;
            obj.rebuild_odefcn_tree();    % use the frequency of the network
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