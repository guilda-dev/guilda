classdef LocalController < PowerSystemModel
% Abstract class of a controller attached to one component, such as an AVR or a PSS.
%
% A local controller is a dynamic model with states x, inputs u and outputs y. Its
% inputs are outputs of its parent (a component, or an AVR for a PSS) and its outputs
% are inputs of the parent; the parent voltage V is available to it. Subclasses in the
% `controller` package define the static model functions (`fcn_dx`, `fcn_y`,
% `fcn_Mass`), their Jacobians and the variable names. Controllers are attached with
% `Component.add_local_controller`.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% gen = net.a_Bus{1}.a_Component{1};
% avr = controller.avr.AVR_ST1("avr1");
% pss = controller.pss.PSS1("pss1");
% gen.add_local_controller(avr, pss);          % the PSS is attached under the AVR
% net.initialize();
% avr.rv_Xequilibrium
% ```
%
% See also Component.add_local_controller, controller.avr.AVR_ST1, controller.pss.PSS1

%% Abstract properties/methods    
    properties(Abstract, SetAccess=protected, Hidden)
        key      (1,1) string   % Kind of controller: "avr" or "pss".
        sv_x    (:,1) string    % Names of the states.
        sv_u    (:,1) string    % Names of the inputs.
        sv_y    (:,1) string    % Names of the outputs.
        sv_para (:,1) string    % Names of the dynamic parameters passed to the model functions.
    end
    methods (Abstract, Static)        
        % Return the state derivatives of the controller.
        %
        % The arguments of all model functions are the time t [s], the states x, the
        % parent voltage V = [Vre; Vim] [pu], the inputs u, the dynamic parameters param
        % (in the order of sv_para) and the nominal frequency omega0 [Hz].
        dx = fcn_dx(obj, t, x, V, u, param, omega0)

        % Return the outputs of the controller.
        y  = fcn_y(obj, t, x, V, u, param, omega0)

        % Return the mass matrix of the state equation.
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)

        % Return the Jacobians of fcn_dx with respect to x, V, I and u.
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)        

        % Return the Jacobians of fcn_y with respect to x, V, I and u.
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    end   
    
%% Parameter    
    properties(SetAccess=protected) % Layer Structure
        a_Component                            % Parent: the component, or the AVR for a PSS ([] when detached).
        a_LocalController = cell(0,1)          % Nested controller (the PSS under an AVR).
    end
    properties(SetAccess=protected) % Dynamics
        f_Mass                                 % Mass matrix function @(t,x,V,I,u) with the parameters bound.
        f_dx                                   % State equation function @(t,x,V,I,u) with the parameters bound.
        f_Y                                    % Output function @(t,x,V,I,u) with the parameters bound.

        f_JacobiDx                             % Jacobian function of f_dx.
        f_JacobiY                              % Jacobian function of f_Y.
    end    
    properties (SetAccess={?odeSimulator, ?odeEventSet}, Hidden)
        iv_odeX  = zeros(0,1);
        iv_odeU  = zeros(0,1);
        iv_odeY  = zeros(0,1);

        rv_Xoffset = 0
        rv_Uoffset = @(t) 0
        
        l_isConnect    (1,1) logical = true
        l_hasController (1,1) logical = false
    end    
    properties(SetAccess=protected) % Steady State
        rv_Xequilibrium (:,1) double = zeros(0,1)   % State equilibrium.
        rv_Uequilibrium (:,1) double = zeros(0,1)   % Input equilibrium.
    end    

    properties(Dependent) % Steady State
        c_Vequilibrium                         % [pu] Voltage equilibrium of the parent (zeros(0,1) without a parent).
        c_Iequilibrium                         % [pu] Current equilibrium of the parent (zeros(0,1) without a parent).
    end    
    
    properties(SetAccess=protected) % Parameter
        para_dynamics                          % Parameter object of tab_parameter.dynamics.
    end
    properties(Dependent) % Parameter
        tab_parameter                          % Parameter table of the controller.
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent                                 % Layer Structure: the parent.
        children                               % Layer Structure: the nested controller.
    end
    
%% Constructor    
    methods
        function obj = LocalController(tag)
            % Create a local controller with the given tag (called by the subclass constructors).
            arguments (Output)
                obj   % New controller, not attached yet.
            end
            obj.str_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");
        end        
    end    

%% Methods    
    methods (Access={?Component,?LocalController})
        function add_local_controller(obj,a_Controller)
            obj.a_LocalController = {a_Controller};
            obj.l_hasController = true;
        end

        function remove_local_controller(obj)
            % Detach the nested controller (Component.add_local_controller, when an AVR is replaced)
            obj.a_LocalController = cell(0,1);
            obj.l_hasController = false;
        end

        function set_parent(obj,a_Component)
            % a_Component = [] detaches the controller (Component.add_local_controller)
            obj.a_Component = a_Component; 
            obj.rebuild_odefcn_tree();    % use the frequency of the parent's network
        end

        % get dx and y
        [DAEvec, u, y_name] = get_dx_algebraic(obj, t, x, Vi, Ii, u, y_name, DAEvec)                

        % get sys
        [sys, varargout] = get_sys(obj,x,V,I,u,opt)        
    end

    methods (Access=protected)
        function set_odefcn(obj, omega0)            
            param = obj.tab_parameter.dynamics{:,obj.sv_para}.';

            obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, param, omega0);            
            obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, param, omega0);
            obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t, x, V, I, u, param, omega0);

            obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
            obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
            obj.l_staleOdefcn = false;
        end

        function rebuild_odefcn(obj)
            % Called by check_edit after a dynamics edit or a network Hz edit.
            obj.set_odefcn(obj.r_Hz);
        end
    end
    methods (Access=private)
        function val = parent_equilibrium(obj, str_prop)
            % Read the parent's (a Component, or an AVR for a PSS) equilibrium.
            % Kept out of the get methods: MATLAB reads the stored value when a
            % get method refers to its own property, even on another object.
            if isempty(obj.a_Component)
                val = zeros(0,1);
            else
                val = obj.a_Component.(str_prop);
            end
        end
    end


%% Get Methods    
    methods        
        function V = get.c_Vequilibrium(obj)
            V = obj.parent_equilibrium("c_Vequilibrium");
        end
        function I = get.c_Iequilibrium(obj)
            I = obj.parent_equilibrium("c_Iequilibrium");
        end
        function p = get.parent(obj)
            p = obj.a_Component;
        end
        function p = get.children(obj) 
            p = obj.a_LocalController;
        end
        function tab = get.tab_parameter(obj)
            tab_tab  = obj.para_dynamics.tab_parameter;
            tab_name = obj.para_dynamics.str_tag;
            tab = table(tab_tab, 'VariableNames', tab_name);
        end
    end
end
