classdef Component < PowerSystemModel
% Abstract class of the equipment connected to a bus, such as generators and loads.
%
% A component is a dynamic model with states x, inputs u and outputs y, connected to its
% bus through the voltage V and the current I it injects:
%
% - `fcn_dx`, `fcn_Mass`: the state equation M*dx/dt = fcn_dx(t, x, V, I, u)
% - `fcn_I`: the current injected into the bus
% - `fcn_Y`: the outputs (inputs of the local controllers)
%
% Subclasses in the `component` package define these static methods, the names of the
% variables (`sv_x`, `sv_u`, `sv_y`, `sv_para`) and the equilibrium (`get_equilibrium`).
% Components are created by `Bus.add_component`. Their parameters are in
% `tab_parameter`: dynamics, operation limits, power-flow settings (P, Q), OPF costs and
% diagram settings. Analytic Jacobians (static methods Jacobi_dx, Jacobi_I, Jacobi_Y)
% are optional; without them the Jacobians are computed numerically.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% gen = net.a_Bus{1}.a_Component{1};
% gen.tab_parameter.powerflow                  % P, Q settings of the power flow
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"));
% net.initialize();
% gen.rv_Xequilibrium                          % state equilibrium
% sys = gen.get_sys();                         % linear model from V to I
% ```
%
% See also Bus.add_component, LocalController, component.generator.abstract

%% Abstract properties/methods
    properties(Abstract,Constant)
        key      (1,1) string   % Key of the component type, used by Bus.add_component.
        sv_x    (:,1) string    % Names of the states.
        sv_u    (:,1) string    % Names of the inputs.
        sv_y    (:,1) string    % Names of the outputs.
        sv_para (:,1) string    % Names of the dynamic parameters passed to the model functions.
    end
    methods(Abstract)
        % Return the state and input equilibria for a bus voltage and current.
        %
        % Called by set_equilibrium during PowerNetwork.initialize; c_V and c_I are the
        % voltage and injected current phasors [pu], r_P and r_Q the injected power [pu].
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q);
    end
    methods(Abstract, Static)      
        % Return the state derivatives of the model.
        %
        % The arguments of all model functions are the time r_t [s], the states rv_x, the
        % bus voltage rv_V = [Vre; Vim] [pu], the current rv_I = [Ire; Iim] [pu], the inputs
        % rv_u, the dynamic parameters rr_param (in the order of sv_para) and the nominal
        % frequency r_omega0 [Hz].
        rv_dx = fcn_dx(  obj, r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)

        % Return the current injected into the bus as a complex number.
        c_I   = fcn_I(   obj, r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)        

        % Return the outputs of the model.
        rv_y  = fcn_Y(   obj, r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)

        % Return the mass matrix of the state equation.
        rm_M  = fcn_Mass(obj, r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)
    end

%% override recommended
    % methods(Static)
    %     [rm_Axx,rm_Bxv,rm_Bxi,rm_Bxu] = Jacobi_dx(r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
    %     [rm_Cyx,rm_Dyv,rm_Dyi,rm_Dyu] = Jacobi_Y( r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
    %     [rm_Cix,rm_Div,rm_Dii,rm_Diu] = Jacobi_I( r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
    % end
    

%% Parameter
    properties(SetAccess=protected) % Layer Structure
        a_Bus                                  % Bus the component is connected to ([] when removed).
        a_LocalController (:,1) = cell(0,1)    % Local controllers attached to the component (an AVR; a PSS hangs under it).
    end
    properties(SetAccess=protected) % Dynamics
        f_Mass                                 % Mass matrix function @(t,x,V,I,u) with the parameters bound.
        f_dx                                   % State equation function @(t,x,V,I,u) with the parameters bound.
        f_I                                    % Current injection function @(t,x,V,I,u) with the parameters bound.
        f_Y                                    % Output function @(t,x,V,I,u) with the parameters bound.
        f_JacobiDx                             % Jacobian function of f_dx (analytic or numerical).
        f_JacobiI                              % Jacobian function of f_I (analytic or numerical).
        f_JacobiY                              % Jacobian function of f_Y (analytic or numerical).
    end
    properties(SetAccess=protected) % Steady State
        rv_Xequilibrium = zeros(0,1)           % State equilibrium.
        rv_Uequilibrium = zeros(0,1)           % Input equilibrium.
        c_Iequilibrium                         % [pu] Current injected into the bus at the equilibrium.
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)
        iv_odeX  = [];
        iv_odeU  = [];        
        iv_odeY  = [];        
    end    
    properties(Dependent, Hidden)
        para_base                              % COMPAT(v3) ComponentBaseView: Hz is held by the network (use r_Hz)
    end
    properties(Dependent) % Steady State
        c_Vequilibrium                         % [pu] Terminal voltage at the equilibrium (= a_Bus.c_Vequilibrium; [] without a bus).
        rv_Xequilibrium_all                    % State equilibrium including the local controllers.
        tab_parameter                          % Parameter table: dynamics, operation, powerflow, OPF and graph.
    end
    properties(SetAccess=protected) % Parameter
        para_dynamics                          % Parameter object of tab_parameter.dynamics.
        para_powerflow                         % Parameter object of tab_parameter.powerflow (P, Q).
        para_operation                         % Parameter object of tab_parameter.operation (baseMVA, Pmin, Pmax, Qmin, Qmax).
        para_OPF                               % Parameter object of tab_parameter.OPF (P0, Q0, HP, HQ, fP, fQ; startup/shutdown are reserved).
        para_graph                             % Parameter object of tab_parameter.graph.
        s_opffcn = opffcn.default()            % OPF terms (Cost, Constraint, DefaultConstraint) set by set_opffcn.
    end  
    properties(Dependent, Access=protected) % Layer Structure
        parent                                 % Layer Structure: the bus.
        children                               % Layer Structure: the local controllers and Parameter objects.
    end
    properties (Access={?odeSimulator, ?Component, ?odeEventSet})        
        l_hasController = false;
        l_isConnect     = true
    end
    properties (Hidden)
        rv_Xoffset 
        rv_Uoffset 
    end
    properties (SetAccess={?ContinuationPowerFlow})
        iv_CPFX  = zeros(0,1)                
        f_PQ2Bus = @(t,V,u) zeros(2,1)
    end

    
    
%% Constructor
    methods(Access=protected)
        function obj = Component(str_tag, opt)
            % Create the parameters of a component (called by the subclass constructors).
            obj.str_tag        = str_tag;
            obj.para_dynamics  = Parameter(obj,"dynamics");
            obj.para_powerflow = Parameter(obj,"powerflow");
            obj.para_OPF       = Parameter(obj,"OPF");
            obj.para_graph     = Parameter(obj,"graph");
            obj.para_operation = Parameter(obj,"operation");
            % Default cost (NaN): 0 for a load (a fixed load adds nothing to the cost), 1 otherwise
            r_cost0 = double(~isa(obj,"component.load.abstract"));
            if isnan(opt.OPFcost_HP); opt.OPFcost_HP = r_cost0; end
            if isnan(opt.OPFcost_fP); opt.OPFcost_fP = r_cost0; end

            obj.para_operation.add_entry( "baseMVA", opt.baseMVA          , "double",...
                                             "Pmin", opt.Pmin             , "double",...
                                             "Pmax", opt.Pmax             , "double",...
                                             "Qmin", opt.Qmin             , "double",...
                                             "Qmax", opt.Qmax             , "double");
            obj.para_powerflow.add_entry(       "P", opt.P                , "double",...
                                                "Q", opt.Q                , "double");
            obj.para_OPF.add_entry(            "P0", opt.OPFinit_P0       , "double",...
                                               "Q0", opt.OPFinit_Q0       , "double",...
                                               "HP", opt.OPFcost_HP       , "double",...
                                               "HQ", opt.OPFcost_HQ       , "double",...
                                               "fP", opt.OPFcost_fP       , "double",...
                                               "fQ", opt.OPFcost_fQ       , "double",...
                                          "startup", opt.OPFcost_startup  , "double",...
                                         "shutdown", opt.OPFcost_shutdown , "double");
            obj.para_graph.add_entry(       "Xaxis", opt.Xaxis            , "double",...
                                            "Yaxis", opt.Yaxis            , "double",...
                                           "Marker", opt.Marker           , "string",...
                                         "MidXaxis", opt.MidXaxis         , "string",...
                                         "MidYaxis", opt.MidYaxis         , "string");
        end        

        function set_odefcn(obj,omega0)
            array = obj.para_dynamics.tab_parameter{:,obj.sv_para};
            
            if ismethod(obj, "Jacobi_dx")
                obj.f_JacobiDx = @(t,x,V,I,u) obj.Jacobi_dx(t,x,V,I,u,array,omega0);
            else
                obj.f_JacobiDx = @(t,x,V,I,u) Jacobi_dx_num(obj,t,x,V,I,u,array,omega0);
            end

            if ismethod(obj, "Jacobi_I")
                obj.f_JacobiI  = @(t,x,V,I,u) obj.Jacobi_I(t,x,V,I,u,array,omega0);
            else
                obj.f_JacobiI  = @(t,x,V,I,u) Jacobi_I_num(obj,t,x,V,I,u,array,omega0);
            end

            if ismethod(obj, "Jacobi_Y")
                obj.f_JacobiY  = @(t,x,V,I,u) obj.Jacobi_Y(t,x,V,I,u,array,omega0);            
            else
                obj.f_JacobiY  = @(t,x,V,I,u) Jacobi_Y_num(obj,t,x,V,I,u,array,omega0);            
            end

            obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, array, omega0);            
            obj.f_dx   = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, array, omega0);
            obj.f_I    = @(t,x,V,I,u) obj.fcn_I(t, x, V, I, u, array, omega0);
            obj.f_Y    = @(t,x,V,I,u) obj.fcn_Y(t, x, V, I, u, array, omega0);
            obj.l_staleOdefcn = false;
        end

        function rebuild_odefcn(obj)
            % Called by check_edit after a dynamics edit or a network Hz edit.
            obj.set_odefcn(obj.r_Hz);
        end
    end
            

%% Methods
    methods
        % Layer Structure
        add_local_controller(obj, a_Controller)

        % OPF
        [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Busvar, option)

        % get_sys
        [sys, varargout] = get_sys(obj, x, V, I, u, opt)

        % get dx, I and y
        DAEvec = get_dx_algebraic(obj, t, x, Vi, Ii, u, DAEvec) 

    end

    methods(Hidden)
        % Debugger
        flag = validate(obj)
    end

    methods(Access={?Bus})
        set_bus(obj,bus)
        set_equilibrium(obj,c_V,c_I,r_P,r_Q)
    end


%% Get Methods
    methods
        function x = get.rv_Xequilibrium_all(obj)
            x_con = tools.vcellfun(@(comp) comp.rv_Xequilibrium, obj.a_LocalController);
            x     = [obj.rv_Xequilibrium; x_con];
        end
        function V = get.c_Vequilibrium(obj)
            % The bus owns the voltage; a component not attached to a bus has none.
            if isempty(obj.a_Bus)
                V = [];
            else
                V = obj.a_Bus.c_Vequilibrium;
            end
        end
        function p = get.parent(obj)
            p = obj.a_Bus;
        end
        function p = get.children(obj)
            p = [ obj.a_LocalController  ;...
                 {obj.para_dynamics      ; obj.para_powerflow     ;...
                  obj.para_operation     ; obj.para_OPF           ;...
                  obj.para_graph         }];
        end
        function v = get.para_base(obj), v = ComponentBaseView(obj); end                 % COMPAT(v3)
        function tp = get.tab_parameter(obj)
            dynamics  = obj.para_dynamics.tab_parameter;
            powerflow = obj.para_powerflow.tab_parameter;
            OPF       = obj.para_OPF.tab_parameter;
            operation = obj.para_operation.tab_parameter;
            graph     = obj.para_graph.tab_parameter;
            tp        = table(dynamics,operation,powerflow,OPF,graph);
            tp        = ComponentBaseView.add_column(obj, tp);   % COMPAT(v3)
        end
    end

%% Set Methods
    methods
        function set.para_base(~,val), ComponentBaseView.check_assign(val); end         % COMPAT(v3)
        function set.tab_parameter(obj,val)
            val       = ComponentBaseView.remove_column(val);    % COMPAT(v3)
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





