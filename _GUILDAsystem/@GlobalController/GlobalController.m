classdef GlobalController < PowerSystemModel
    properties(Abstract, Constant, Hidden=true)
        key      (1,1) string 
        sv_x    (:,1) string
        sv_u    (:,1) string 
        sv_y    (:,1) string
        sv_para (:,1) string
    end
    methods (Abstract, Static)        
        dx = fcn_dx(t, x, V, I, u, param, omega0)
        y  = fcn_y(t, x, V, I, u, param, omega0)
        M  = fcn_Mass(t, x, V, I, u, param, omega0)
    end       
    properties(SetAccess=protected)                   
        f_Mass       
        f_dx       
        f_Y

        f_JacobiDx
        f_JacobiY                
    end    
    properties(SetAccess=protected, Hidden)
        r_omega0                               % omega0 last passed to set_odefcn (reused by rebuild_odefcn)
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

        rv_Xoffset = 0
        rv_Uoffset = @(t) 0

        l_isConnect (1,1) logical = true
    end        
    properties(SetAccess={?PowerNetwork})
        rv_Xequilibrium (:,1) double = zeros(0,1)   
        rv_Uequilibrium (:,1) double = zeros(0,1)   
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

        % get sys
        function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
            arguments
                obj                 
                x        (:,1) double  = obj.rv_Xequilibrium
                V        (:,1) double  = zeros(2,1)
                I        (:,1) double  = zeros(2,1)
                u        (:,1) double  = obj.rv_Uequilibrium
                opt.full (1,1) logical = true 
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

            a_Comp = obj.controlledUnits;            
            xNames = obj.attach_tag(obj.sv_x);
            uNames = cellfun(@(s) s.attach_tag(s.sv_y), a_Comp);
            yNames = cellfun(@(s) s.attach_tag(s.sv_u(s.sv_u==obj.sv_y)), a_Comp);

            sys.StateName  = xNames;
            sys.InputName  = uNames;
            sys.OutputName = yNames;
        end
    end   
    methods (Access=protected)
        function set_odefcn(obj, omega0)
            param = obj.tab_parameter.dynamics{:,obj.sv_para};

            obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t,x,V,I,u,param,omega0);
            obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t,x,V,I,u,param,omega0);
            obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t,x,V,I,u,param,omega0);
            
            obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,param,omega0);
            obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,param,omega0);
            obj.r_omega0   = omega0;
            obj.l_staleOdefcn = false;
        end

        function rebuild_odefcn(obj)
            % Called by check_edit after a dynamics parameter edit.
            obj.set_odefcn(obj.r_omega0);
        end
    end
    methods (Access={?Component,?LocalController,?PowerNetwork})        
        function set_parent(obj,net)
            obj.PowerNetwork = {net}; 
        end
    end
    methods        
        function p = get.parent(obj)
            p = obj.PowerNetwork;
            if iscell(p) && ~isempty(p)
                p = p{1};    % stored in a cell; edits are logged to this network
            end
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