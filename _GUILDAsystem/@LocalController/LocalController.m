classdef LocalController < PowerSystemModel
    properties(Dependent)
        tab_parameter
    end
    properties(Dependent, Access=protected)
        parent 
        children
    end
    properties(SetAccess=protected)
        a_Component 
        para_dynamics
    end

    properties(SetAccess=protected)           
        a_LocalController = cell(0,1)          
        rm_odeMass        = @(t,x,V,u)[]                  
        fv_odeDiff        = @(t,x,V,u)[]                                   
        fv_odeY           = @(t,x,V,u)[]                                   
        JacobiA           = @(t,x,V,u)[]                   
        JacobiB           = @(t,x,V,u)[]                   
        JacobiC           = @(t,x,V,u)[]                   
        JacobiD           = @(t,x,V,u)[]                           
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)
        iv_odeX  = zeros(0,1);
        iv_odeU  = zeros(0,1);
        rv_odeX0 = zeros(0,1);
    end    
    properties(SetAccess=protected)
        cv_Xequilibrium (:,1) double = zeros(0,1)   
        cv_Uequilibrium (:,1) double = zeros(0,1)   
    end
    
    methods
        function obj = LocalController(tag)
            obj.str_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");
        end

    end
    methods (Abstract)
        dx = fcn_dx(obj, t, x, V, u, param, omega0)
        y  = fcn_y(obj, t, x, V, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)
    end
    methods
        function p = get.parent(obj)
            p = obj.a_Component;
        end
        function p = get.children(obj) %#ok
        end
        function tab = get.tab_parameter(obj)
            tab_tab  = obj.para_dynamics.tab_parameter;
            tab_name = obj.para_dynamics.str_tag;
            tab = table(tab_tab, 'VariableNames', tab_name);
        end
    end
end
