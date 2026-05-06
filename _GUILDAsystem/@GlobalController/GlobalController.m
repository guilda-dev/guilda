classdef GlobalController < PowerSystemModel
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
        rm_odeMass       
        fv_odeDiff       
        fv_odeY

        JacobiAxx        
        JacobiBxv        
        JacobiBxu        

        JacobiCix = @(t,x,V,u)[]               
        JacobiDiv = @(t,x,V,u)[]               
        JacobiDiu = @(t,x,V,u)[]               
        
        JacobiCyx        
        JacobiDyv        
        JacobiDyu        
    end    
    properties (SetAccess=protected)
        PowerNetwork
    end
    properties (SetAccess=protected, Hidden)
        controlledUnits
    end
    properties (SetAccess={?odeSimulator, ?odeEventSet}, Hidden)
        iv_odeX (:,1) double = zeros(0,1);
        iv_odeU (:,1) double = zeros(0,1);
        iv_odeY (:,1) double = zeros(0,1);        

        X_offset = 0
        U_offset = @(t) 0

        isConnect (1,1) logical = true
    end        
    properties(SetAccess={?PowerNetwork})
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
        function obj = GlobalController(net, tag, varargin)
            obj.str_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");

            cls_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);            
            cls_comp = vertcat(cls_comp{:});            

            idx = 1;
            while idx <= nargin-2
                if isa(varargin{idx}, 'component.generator.abstract')
                    varargin{idx} = varargin{idx}.str_tag;                    
                end

                lv_comp = strcmp(varargin{idx}, string(cls_comp));
                if all(~lv_comp)
                    error(msg('GUILDA:GlobalController:InvalidComponent'))
                end

                obj.controlledUnits = [obj.controlledUnits; cls_comp(lv_comp)];

                idx = idx + 1;
            end
            
        end        
    end    
    methods (Access={?Component,?LocalController})        
        function set_parent(obj,net)
            obj.PowerNetwork = {net}; 
        end
    end
    methods        
        function p = get.parent(obj)
            p = obj.PowerNetwork;
        end
        function p = get.children(~) 
            p = {};
        end
        function tab = get.tab_parameter(obj)
            dynamics = obj.para_dynamics.tab_parameter;            
            dynamics.Properties.RowNames = string(obj.controlledUnits);
            tab = table(dynamics);
        end
    end
end