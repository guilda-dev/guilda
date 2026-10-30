classdef LocalController < PowerSystemModel
%% LOCALCONTROLLER is superclass for defining controllers that connect to devices    

%% Abstract properties/methods    
    properties(Abstract, SetAccess=protected, Hidden)
        key      (1,1) string 
        sv_x    (:,1) string
        sv_u    (:,1) string 
        sv_y    (:,1) string
        sv_para (:,1) string
    end
    methods (Abstract, Static)        
        dx = fcn_dx(obj, t, x, V, u, param, omega0)
        y  = fcn_y(obj, t, x, V, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)

        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)        
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    end   
    
%% Parameter    
    properties(SetAccess=protected)            
        a_Component       
        a_LocalController = cell(0,1)          
        
        f_Mass       
        f_dx       
        f_Y

        f_JacobiDx        
        f_JacobiY        
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
    properties (SetAccess=private, Hidden)
        % <@Desc> Where each input sv_u(k) is read on the observed component (the
        % component the controller is attached to, directly or through the controllers
        % above it): iv_obsY(k) is its index in sv_y, iv_obsX(k) its index in sv_x, and
        % both are 0 for an input that is not observed (its equilibrium value, or the
        % output of a nested controller of the same name). Set by resolve_observe.
        % <@Role> Layer
        % <@Type> double
        % <@Size> nu x 1
        iv_obsY (:,1) double = zeros(0,1)
        iv_obsX (:,1) double = zeros(0,1)
    end
    properties (Access=private)
        sv_uRequest (:,1) string = strings(0,1)   % sv_u as defined, before "X" / "Y" are expanded
    end
    properties (Constant, Hidden)
        % <@Desc> Reserved input names: an input "X" observes all the states sv_x of the
        % component and an input "Y" all its outputs sv_y (expanded when attached).
        % <@Role> Layer
        % <@Type> string
        % <@Size> 1x2
        sv_reserved = ["X","Y"]
    end
    properties(SetAccess=protected)
        rv_Xequilibrium (:,1) double = zeros(0,1)   
        rv_Uequilibrium (:,1) double = zeros(0,1)   
    end    

    properties(Dependent)
        c_Vequilibrium                         % parent's c_Vequilibrium (zeros(0,1) without a parent)
        c_Iequilibrium                         % parent's c_Iequilibrium (zeros(0,1) without a parent)
    end    
    
    properties(SetAccess=protected)
        para_dynamics
    end
    properties(Dependent)
        tab_parameter
    end
    properties(Dependent, Access=protected)
        parent 
        children
    end
    
%% Constructor    
    methods
        function obj = LocalController(tag)
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
            obj.resolve_observe();        % inputs read on the component (also of nested controllers)
            obj.rebuild_odefcn_tree();    % use the frequency of the parent's network
        end

        function resolve_observe(obj)
            % Expand the reserved inputs "X" / "Y" and find where each input is read on
            % the observed component (iv_obsY / iv_obsX), for this controller and the
            % controllers nested in it. An input name found in both sv_y and sv_x is read
            % from sv_y. Without a component, the inputs stay as defined.
            if isempty(obj.sv_uRequest)
                obj.sv_uRequest = obj.sv_u;
            end
            comp = obj.observed_component();
            if isempty(comp)
                sv_req = obj.sv_uRequest;
                if any(ismember(sv_req, obj.sv_reserved))
                    obj.set_inputs(sv_req);
                end
                obj.iv_obsY = zeros(numel(obj.sv_u),1);
                obj.iv_obsX = zeros(numel(obj.sv_u),1);
            else
                obj.resolve_ports(comp);
                sv_name = strings(0,1);  sv_src = strings(0,1);
                for k = 1:numel(obj.sv_uRequest)
                    switch obj.sv_uRequest(k)
                        case "X"
                            sv_add = comp.sv_x;  str_src = "X";
                        case "Y"
                            sv_add = comp.sv_y;  str_src = "Y";
                        otherwise
                            sv_add = obj.sv_uRequest(k);  str_src = "";
                    end
                    sv_name = [sv_name; sv_add(:)];                              %#ok<AGROW>
                    sv_src  = [sv_src; repmat(str_src, numel(sv_add), 1)];       %#ok<AGROW>
                end
                if ~isequal(sv_name, obj.sv_u)
                    obj.set_inputs(sv_name);
                end
                [~, iv_y] = ismember(sv_name, comp.sv_y);
                [~, iv_x] = ismember(sv_name, comp.sv_x);
                iv_y(sv_src == "X") = 0;
                iv_x(sv_src == "Y" | iv_y > 0) = 0;
                obj.iv_obsY = iv_y;
                obj.iv_obsX = iv_x;
            end
            cellfun(@(c) c.resolve_observe(), obj.a_LocalController);
        end

        % get dx and y
        [DAEvec, y, y_name] = get_dx_algebraic(obj, t, x, Vi, Ii, obs, DAEvec)

    end

    methods (Access=protected)
        function resolve_ports(obj, comp) %#ok
            % Called by resolve_observe with the observed component before the inputs
            % are resolved: a controller whose ports depend on the component (e.g. the
            % inputs of the component it drives) sets them here. Does nothing by default.
        end

        function set_inputs(obj, sv_name)
            % Set the input names sv_u after "X" / "Y" are expanded. A controller that
            % uses "X" or "Y" in sv_u overrides this (sv_u is defined by the subclass).
            error("GUILDA:LocalController:ReservedInput", ...
                  "%s uses the reserved input names ""X"" / ""Y"" but does not override set_inputs.", class(obj))
        end

        function comp = observed_component(obj)
            % The component the controller observes: its parent, or for a nested
            % controller (e.g. a PSS under an AVR) the component above them ([] if none)
            comp = obj.a_Component;
            while isa(comp, "LocalController")
                comp = comp.a_Component;
            end
            if ~isa(comp, "Component")
                comp = [];
            end
        end

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


%% Analysis
    methods
        % get sys (public: the linear model of the controller alone)
        [sys, varargout] = get_sys(obj,x,V,I,u,opt)
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
