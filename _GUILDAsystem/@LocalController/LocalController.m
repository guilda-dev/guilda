classdef LocalController < PowerSystemModel
    properties(Abstract, Constant, Hidden=true)
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

    properties(SetAccess=protected)
        a_Component       
        a_LocalController = cell(0,1)          
    end
    properties(SetAccess=protected)                   
        rm_odeMass       
        fv_odeDiff       
        fv_odeConY

        JacobiAxx        
        JacobiBxv        
        JacobiBxu        
        
        JacobiCyx        
        JacobiDyv        
        JacobiDyu        
    end    
    properties (SetAccess={?odeSimulator, ?odeEventSet}, Hidden)
        iv_odeX  = zeros(0,1);
        iv_odeU  = zeros(0,1);
        iv_odeY  = zeros(0,1);

        X_offset = 0
        U_offset = @(t) 0
        
        isConnect (1,1) logical = true
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
    
    methods
        function obj = LocalController(tag)
            obj.str_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");
        end        
    end    
    methods (Access={?Component,?LocalController})
        function add_local_controller(obj,a_Controller)
            obj.a_LocalController = {a_Controller};
        end
        function set_parent(obj,a_Component)
            obj.a_Component = a_Component; 
        end
    end
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
