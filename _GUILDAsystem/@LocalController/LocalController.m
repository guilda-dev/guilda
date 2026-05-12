classdef LocalController < PowerSystemModel
%% LOCALCONTROLLER is superclass for defining controllers that connect to devices    

%% Abstract properties/methods    
    properties(Abstract, SetAccess=protected, Hidden)
        key      (1,1) string 
        str_x    (:,1) string
        str_u    (:,1) string 
        str_y    (:,1) string
        str_para (:,1) string
    end
    methods (Abstract)        
        dx = fcn_dx(obj, t, x, V, u, param, omega0)
        y  = fcn_y(obj, t, x, V, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)

        set_odefcn(obj,omega0)
    end   
    
%% Parameter    
    properties(SetAccess=protected)            
        a_Component       
        a_LocalController = cell(0,1)          
        
        rm_odeMass       
        fv_odeDiff       
        fv_odeY

        JacobiAxx        
        JacobiBxv        
        JacobiBxi        
        JacobiBxu        

        JacobiCix = @(t,x,V,I,u)[]        
        JacobiDiv = @(t,x,V,I,u)[]                
        JacobiDii = @(t,x,V,I,u)[]                
        JacobiDiu = @(t,x,V,I,u)[]               
        
        JacobiCyx        
        JacobiDyv        
        JacobiDyi        
        JacobiDyu        
    end    
    properties (SetAccess={?odeSimulator, ?odeEventSet}, Hidden)
        iv_odeX  = zeros(0,1);
        iv_odeU  = zeros(0,1);
        iv_odeY  = zeros(0,1);

        X_offset = 0
        U_offset = @(t) 0
        
        isConnect    (1,1) logical = true
        isController (1,1) logical = false
    end    
    properties(SetAccess=protected)
        cv_Xequilibrium (:,1) double = zeros(0,1)   
        cv_Uequilibrium (:,1) double = zeros(0,1)   
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
    methods %(Access={?Component,?LocalController})
        function add_local_controller(obj,a_Controller)
            obj.a_LocalController = {a_Controller};
            obj.isController = true;
        end

        function set_parent(obj,a_Component)
            obj.a_Component = a_Component; 
        end

        % get dx and y
        [DAEvec, u, y_name] = get_dx_algebraic(obj, t, x, Vi, Ii, u, y_name, DAEvec)                

        % get sys
        sys = get_sys(obj,x,V,u,opt)
    end


%% Get Methods    
    methods        
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
