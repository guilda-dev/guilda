classdef Component < PowerSystemModel
% Abstract class of the equipment connected to a bus, such as generators and loads.
%
% A component is a dynamical system with state $x$, input $u$ and output $y$, connected to
% its bus through the bus voltage $V$ and the current $I$ it injects (positive for generation):
%
% - `fcn_dx`, `fcn_Mass`: the state equation M*dx/dt = fcn_dx(t, x, V, I, u)
% - `fcn_I`: the current injected into the bus
% - `fcn_Y`: the output signals (read by the local controllers)
%
% Subclasses in the `component` package define these static methods, the names of the
% variables (`sv_x`, `sv_u`, `sv_y`, `sv_para`) and the equilibrium (`get_equilibrium`).
% Components are created by `Bus.add_component`. Their parameters are in
% `tab_parameter`: dynamics, operation limits, power-flow settings (P, Q), OPF costs and
% diagram settings, set by `add_component` (dynamics by the subclass constructor) or by
% writing the table. An edit of dynamics makes the handles and the equilibrium stale, an
% edit of powerflow the equilibrium; operation, OPF and graph make nothing stale. The OPF
% cost of a component is $H_P P^2 + f_P P + H_Q Q^2 + f_Q Q$. Analytic Jacobians (static
% methods Jacobi_dx, Jacobi_I, Jacobi_Y) are optional; without them the Jacobians are
% computed numerically.
%
% Role in the model:
%
% - Owns the device equations (through its subclass), its parameters (dynamics, power-flow
%   P and Q, operation limits, OPF cost, drawing), its equilibrium (`rv_Xequilibrium`,
%   `rv_Uequilibrium`, `c_Iequilibrium`) and its local controllers (`a_LocalController`).
% - The base class turns the static model functions into the cached handles `f_*`, adds its
%   local controllers to the DAE and the linear model, and computes Jacobians numerically
%   when the subclass gives none. The handles @(t,x,V,I,u) bind the parameters and omega0;
%   `set_odefcn` builds them, called by `check_edit` at the start of an analysis, and
%   `sct_edit.s_odefcn` tells whether they are "unset", "editted" or "updated".
% - Does not own the bus voltage (it reads `a_Bus.c_Vequilibrium`), the network frequency
%   (it reads `get_Hz()`) or the system base.
% - Created only by `Bus.add_component` and `Bus.replace_component`. Only the bus sets and
%   clears `a_Bus` (through `set_bus`, which also marks the handles of the subtree stale);
%   the component sets `LocalController.a_Component` of its controllers. A
%   `GlobalController` refers to controlled components in `controlledUnits`; a controlled
%   component cannot be removed or replaced while the controller is on the network.
%
% A new model inherits from `component.generator.abstract` or `component.load.abstract`.
% The framework relies on three more rules:
%
% - `get_equilibrium` is always called with all of c_V, c_I, r_P and r_Q (a trip of
%   `simulate` passes c_I = r_P = r_Q = 0).
% - `fcn_Mass` is constant: `simulate` calls it with empty t, x, V, I and u.
% - `getCompPQ(obj, x, V, u, param)`, which returns the injected power [P; Q], is needed only
%   by the continuation power flow with `UseInternalState=true`.
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
    properties(Abstract,Constant) % Subclass contract
        key (1,1) string  % Key of the component type, used by Bus.add_component.
        sv_x (:,1) string  % Names of the states.
        sv_u (:,1) string  % Names of the inputs.
        sv_y (:,1) string  % Names of the outputs.
        sv_para (:,1) string  % Names of the dynamic parameters passed to the model functions.
    end
    methods(Abstract)
        % Return the state and input equilibria for a bus voltage and current.
        %
        % Called by set_equilibrium during PowerNetwork.initialize and by simulate for a
        % tripped generator, always with four arguments; c_V and c_I are the voltage and
        % injected current phasors [pu], r_P and r_Q the injected power [pu].
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q);
    end
    methods(Abstract, Static)      
        % Return the state derivatives of the model.
        %
        % The arguments of all model functions are the time r_t [s], the states rv_x, the
        % bus voltage rv_V = [Vre; Vim] [pu], the current rv_I = [Ire; Iim] [pu], the inputs
        % rv_u, the dynamic parameters rr_param (in the order of sv_para) and the nominal
        % frequency r_omega0 [Hz]. A subclass may define them as ordinary methods instead,
        % with obj before r_t.
        rv_dx = fcn_dx(  r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)

        % Return the current injected into the bus as a complex number.
        c_I   = fcn_I(   r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)        

        % Return the outputs of the model.
        rv_y  = fcn_Y(   r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)

        % Return the mass matrix of the state equation.
        %
        % It must be constant: simulate calls it with empty r_t, rv_x, rv_V, rv_I and rv_u.
        rm_M  = fcn_Mass(r_t, rv_x, rv_V, rv_I, rv_u, rr_param, r_omega0)
    end

%% override recommended
    % methods(Static)
    %     [rm_Axx,rm_Bxv,rm_Bxi,rm_Bxu] = Jacobi_dx(r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
    %     [rm_Cyx,rm_Dyv,rm_Dyi,rm_Dyu] = Jacobi_Y( r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
    %     [rm_Cix,rm_Div,rm_Dii,rm_Diu] = Jacobi_I( r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
    % end
    

%% Parameter
    properties(SetAccess=protected) % Layer Structure
        a_Bus  % Bus the component is connected to ([] when removed).
        a_LocalController (:,1) = cell(0,1)  % Top-level local controllers, in slot order whatever the attach order: the AVR or "local" controller (a PSS hangs under an AVR), then the governor. <@Stale> equilibrium
    end
    properties(SetAccess=protected) % Cached function handles
        f_Mass  % Mass matrix function @(t,x,V,I,u) with the parameters bound.
        f_dx  % State equation function @(t,x,V,I,u) with the parameters bound.
        f_I  % Current injection function @(t,x,V,I,u) with the parameters bound.
        f_Y  % Output function @(t,x,V,I,u) with the parameters bound.
        f_JacobiDx  % Jacobian function of f_dx (analytic or numerical).
        f_JacobiI  % Jacobian function of f_I (analytic or numerical).
        f_JacobiY  % Jacobian function of f_Y (analytic or numerical).
    end
    properties(SetAccess=protected) % Steady State
        rv_Xequilibrium = zeros(0,1)  % State equilibrium.
        rv_Uequilibrium = zeros(0,1)  % Input equilibrium.
        c_Iequilibrium  % [pu] Current injected into the bus at the equilibrium (complex).
    end
    properties (SetAccess={?SolverODE, ?Component}, Hidden) % Simulation working data
        iv_odeX = [];  % Positions of the states in the simulation vector.
        iv_odeU = [];  % Positions of the inputs in the simulation vector.
        iv_odeY = [];  % Not set for a component (stays []); read by the Jacobian of the simulation.
        lv_odeUfromLC = false(0,1);  % Inputs driven by an output of a top-level local controller.
        iv_odeYtoU = zeros(0,1);  % Index of each such input in the outputs of the top-level controllers, stacked in order.
    end
    properties(Dependent, Hidden) % Compatibility
        para_base  % COMPAT(v3) ComponentBaseView: Hz is held by the network (use get_Hz)
    end
    properties(Dependent) % Steady State
        c_Vequilibrium  % [pu] Terminal voltage at the equilibrium (= a_Bus.c_Vequilibrium; [] without a bus).
        rv_Xequilibrium_all  % State equilibrium of the component, then of its controllers depth first (the order of get_variable_map).
    end
    properties(Dependent) % Parameter
        tab_parameter  % Parameter table: the para_* tables side by side; writing it writes the parameters.
    end
    properties(SetAccess=protected) % Parameter
        para_dynamics  % Model parameters, per unit on the system base; the sv_para columns are passed to the model functions.
        para_powerflow  % P, Q [pu]: injection settings of the power flow (negative for a load); Q = NaN makes the bus a PV bus.
        para_operation  % baseMVA [MVA]: rating, only to share Q on a bus (not the system base); Pmin, Pmax, Qmin, Qmax [pu]: OPF bounds and "Qmax" rule.
        para_OPF  % P0, Q0 [pu]: OPF initial values; HP, fP, HQ, fQ: cost coefficients (default 1, 1, 0, 0; 0 for a load); startup, shutdown: reserved.
        para_graph  % Xaxis, Yaxis, Marker, MidXaxis, MidYaxis: drawing data.
    end
    properties(SetAccess=protected) % OPF
        f_opfcost = []  % OPF cost handle @(v, p) from set_opffcn; replaces the default cost of the component ([]: none). <@Stale> nothing (logged)
        f_opfconst = []  % OPF constraint handle @(v, p) from set_opffcn, returning a struct of named constraints ([]: none). <@Stale> nothing (logged)
        l_opfdefault = true  % Whether the default OPF constraints of the component are kept (DefaultConstraint of set_opffcn). <@Stale> nothing (logged)
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent  % Parent in the layer structure: the bus.
        children  % Children in the layer structure: the local controllers, then the Parameter objects.
    end
    properties (Access={?SolverODE, ?Component}) % Simulation working data
        l_hasController = false;  % Whether a local controller is attached.
        l_isConnect = true  % False while an active trip of a scenario names the component (simulation working data).
    end
    properties (SetAccess={?SolverODE}, Hidden) % Simulation working data
        rv_Xoffset  % State offset of the active disturbances in the current phase (built by Scenario.compile).
        rv_Uoffset  % Input change of the active disturbances in the current phase (built by Scenario.compile).
    end
    properties (SetAccess={?SolverCPF}) % Continuation Power Flow
        iv_CPFX = zeros(0,1)  % Indices of the states in the CPF variable vector (CPF working data).
        f_PQ2Bus = @(t,V,u) zeros(2,1)  % Function of the injected power [P; Q] [pu] used by the CPF (CPF working data).
    end



%% Constructor
    methods(Access=protected)
        function obj = Component(s_tag, opt)
            % Create the parameters of a component (called by the subclass constructors).
            arguments (Input)
                s_tag (1,1) string   % Tag of the component.
                opt   (1,1) struct   % Settings of add_component (without parameter).
            end
            arguments (Output)
                obj   % New Component object.
            end
            obj.s_tag          = s_tag;
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

        function set_odefcn(obj)
            % Bind the parameters and the network frequency into the f_* function handles.
            % Called by check_edit when the handles are not up to date (s_odefcn "unset" or
            % "editted": a dynamics edit, a network Hz edit or an attach since the last build).
            %
            % <@Group> Called by analyses
            arguments (Input)
                obj
            end
            omega0 = obj.get_Hz();
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
            obj.sct_edit.s_odefcn = "updated";
        end

        % Raise a constructor message of Component.xml for a subclass in another folder.
        parameter_error(obj, s_key, varargin)
    end
            

%% Methods
    methods
        % Layer Structure
        add_local_controller(obj, a_Controller)
        remove_local_controller(obj, s_tag, opt)

        % OPF
        [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Busvar, option)

        % get_sys
        [sys, varargout] = get_sys(obj, x, V, I, u, opt)

        % get dx, I and y
        DAEvec = get_dx_algebraic(obj, t, x, Vi, Ii, u, DAEvec)

    end
    methods (Hidden)
        % get_sys of the component alone
        sys = get_sys_alone(obj, x, V, I, u, opt)
    end

    methods(Hidden)
        % Debugger
        flag = validate(obj)
    end

    methods(Access={?SolverLIN})
        [rv_dx, rv_I] = point_residual(obj, rv_point)
    end

    methods(Access={?Bus})
        set_bus(obj,bus)
        set_equilibrium(obj,c_V,c_I,r_P,r_Q)
        move_local_controllers(obj,comp_new)
    end


%% Get Methods
    methods
        function x = get.rv_Xequilibrium_all(obj)
            x = equilibrium_depth_first(obj);
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







function x = equilibrium_depth_first(parent)
% States of parent and then of its local controllers, depth first (the order of get_variable_map)
    arguments (Input)
        parent   % Component or LocalController.
    end
    arguments (Output)
        x (:,1) double   % Stacked state equilibria.
    end
    x_con = tools.vcellfun(@equilibrium_depth_first, parent.a_LocalController);
    x     = [reshape(parent.rv_Xequilibrium, [], 1); x_con];
end
