classdef Component < PowerSystemModel
% Abstract class of the equipment connected to a bus, such as generators and loads.
%
% A component is a dynamical system with state $x$, input $u$ and output $y$, connected to
% its bus through the bus voltage $V$ and the current $I$ it injects (positive for generation):
%
% - `fcn_dx`, `fcn_Mass`: the state equation M*dx/dt = fcn_dx(t, x, V, u)
% - `fcn_I`: the current injected into the bus, fcn_I(t, x, V, u)
% - `fcn_Y`: the output signals fcn_Y(t, x, V), read by the local and global controllers.
%   The output does not depend on u (no feedthrough), so there is no algebraic loop through
%   the inputs.
%
% No model function takes the bus current: it is the sum of all the components on the bus.
%
% Subclasses in the `component` package define these static methods, the names of the
% variables (`sv_x`, `sv_u`, `sv_y`, `sv_para`) and the equilibrium (`get_equilibrium`).
% Components are created by `Bus.add_component`. Their parameters are in
% `tab_parameter`: dynamics, operation limits, power-flow settings (P, Q), OPF costs and
% diagram settings, set by `add_component` (dynamics by the subclass constructor) or by
% writing the table. An edit of dynamics makes the handles and the equilibrium of the
% component stale (stale tags odefcn and equilibrium), an edit of powerflow the power flow
% of the network; operation, OPF and graph make nothing stale. The OPF
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
%   when the subclass gives none. The handles @(t,x,V,u) (f_Y and f_JacobiY: @(t,x,V)) bind the parameters and omega0;
%   `set_odefcn` builds them, called by `PowerNetwork.initialize` when they are stale
%   (`sct_stale.odefcn`, or a network frequency other than `r_odefcnHz`).
% - Stale tags (`sct_stale`): `equilibrium` (its dynamics, its local controllers, its
%   attachment) and `odefcn` (its dynamics). `initialize`, called by
%   PowerNetwork.initialize through the bus, rebuilds the handles and recomputes the
%   equilibrium from the held V and I when they are stale.
% - Does not own the bus voltage (it reads `a_Bus.c_Vequilibrium`), the network frequency
%   (it reads `get_Hz()`) or the system base.
% - Created only by `Bus.add_component` and `Bus.replace_component`. Only the bus sets and
%   clears `a_Bus` (`SetAccess`) and logs the attachment as a "Topology" edit of the
%   component; the component sets `LocalController.a_Component` of its controllers. A
%   `GlobalController` refers to controlled components in `controlledUnits`; a controlled
%   component cannot be removed or replaced while the controller is on the network.
%
% A new model inherits from `component.generator.abstract` or `component.load.abstract`.
% The framework relies on three more rules:
%
% - `get_equilibrium` is always called with all of c_V, c_I, r_P and r_Q (a trip of
%   `simulate` passes c_I = r_P = r_Q = 0).
% - `fcn_Mass` is constant: `simulate` calls it with empty t, x, V and u.
% - `getCompPQ(obj, x, V, u, param)`, which returns the injected power [P; Q], is needed only
%   by the continuation power flow with `UseInternalState=true`.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% gen = net.a_Bus{1}.a_Component{1};
% gen.tab_parameter.powerflow                  % P, Q settings of the power flow
% gen.add_local_controller("avr-ST1");
% net.initialize();
% gen.rv_Xequilibrium                          % state equilibrium
% sys = gen.get_sys();                         % linear model from V to I
% ```
%
% See also Bus.add_component, LocalController, component.generator.abstract

%% Abstract properties
    properties(Abstract,Constant) % Subclass contract
        key (1,1) string                     % Key of the component type, used by Bus.add_component.
        sv_x (:,1) string                    % Names of the states.
        sv_u (:,1) string                    % Names of the inputs.
        sv_y (:,1) string                    % Names of the outputs.
        sv_para (:,1) string                 % Names of the dynamic parameters passed to the model functions.
    end
    

%% Parameter
    properties(SetAccess={?Bus}) % Layer Structure
        a_Bus = []                           % Bus the component is connected to ([] when removed). <@Type> Bus
    end
    properties(SetAccess=protected) % Layer Structure
        a_LocalController (:,1) = cell(0,1)  % Top-level local controllers, in slot order whatever the attach order: the AVR or "local" controller (a PSS hangs under an AVR), then the governor. <@Stale> equilibrium
    end
    properties(SetAccess=protected) % Cached function handles
        f_Mass                               % Mass matrix function @(t,x,V,u) with the parameters bound.
        f_dx                                 % State equation function @(t,x,V,u) with the parameters bound.
        f_I                                  % Current injection function @(t,x,V,u) with the parameters bound.
        f_Y                                  % Output function @(t,x,V) with the parameters bound (no input).
        f_JacobiDx                           % Jacobian function of f_dx (analytic or numerical).
        f_JacobiI                            % Jacobian function of f_I (analytic or numerical).
        f_JacobiY                            % Jacobian function of f_Y (analytic or numerical).
    end
    properties(SetAccess=protected, Hidden) % Cached function handles
        r_odefcnHz double = []               % [Hz] Network frequency bound into the f_* handles (empty: never built).
    end
    properties(SetAccess=protected) % Steady State
        rv_Xequilibrium = zeros(0,1)         % State equilibrium.
        rv_Uequilibrium = zeros(0,1)         % Input equilibrium (edited by set_input; held by initialize(Method="FixedInput")).
        c_Iequilibrium                       % [pu] Current injected into the bus at the equilibrium (complex).
    end
    properties (SetAccess={?SolverODE, ?Component}, Hidden) % Simulation working data
        iv_odeX = [];                        % Positions of the states in the simulation vector.
        iv_odeU = [];                        % Positions of the inputs in the simulation vector.
        iv_odeY = [];                        % Not set for a component (stays []); read by the Jacobian of the simulation.
        lv_odeUfromLC = false(0,1);          % Inputs driven by an output of a top-level local controller.
        iv_odeYtoU = zeros(0,1);             % Index of each such input in the outputs of the top-level controllers, stacked in order.
    end
    properties(Dependent) % Steady State
        c_Vequilibrium                       % [pu] Terminal voltage at the equilibrium (= a_Bus.c_Vequilibrium; [] without a bus).
        rv_Xequilibrium_all                  % State equilibrium of the component, then of its controllers depth first (the order of get_variable_map).
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent                               % Parent in the layer structure: the bus.
        children                             % Children in the layer structure: the local controllers, then the Parameter objects.
    end
    properties (Access={?SolverODE, ?Component}) % Simulation working data
        l_hasController = false;             % Whether a local controller is attached.
        l_isConnect = true                   % False while an active trip of a scenario names the component (simulation working data).
    end
    properties (SetAccess={?SolverODE}, Hidden) % Simulation working data
        rv_Xoffset                           % State offset of the active disturbances in the current phase (built by Scenario.compile).
        rv_Uoffset                           % Input change of the active disturbances in the current phase (built by Scenario.compile).
    end
    properties (SetAccess={?SolverCPF}) % Continuation Power Flow
        iv_CPFX = zeros(0,1)                 % Indices of the states in the CPF variable vector (CPF working data).
        f_PQ2Bus = @(t,V,u) zeros(2,1)       % Function of the injected power [P; Q] [pu] used by the CPF (CPF working data).
    end

%% Abstract methods
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
        % bus voltage rv_V = [Vre; Vim] [pu], the inputs rv_u (not for fcn_Y), the dynamic
        % parameters rr_param (in the order of sv_para) and the nominal frequency r_omega0
        % [Hz]. A subclass may define them as ordinary methods instead, with obj before r_t.
        rv_dx = fcn_dx(  r_t, rv_x, rv_V, rv_u, rr_param, r_omega0)

        % Return the current injected into the bus as a complex number.
        c_I   = fcn_I(   r_t, rv_x, rv_V, rv_u, rr_param, r_omega0)

        % Return the outputs of the model. They do not depend on the inputs.
        rv_y  = fcn_Y(   r_t, rv_x, rv_V, rr_param, r_omega0)

        % Return the mass matrix of the state equation.
        %
        % It must be constant: simulate calls it with empty r_t, rv_x, rv_V and rv_u.
        rm_M  = fcn_Mass(r_t, rv_x, rv_V, rv_u, rr_param, r_omega0)
    end

%% override recommended
    % methods(Static)
    %     [rm_Axx,rm_Bxv,rm_Bxu] = Jacobi_dx(r_t,rv_x,rv_V,rv_u,rr_param,r_omega0);
    %     [rm_Cyx,rm_Dyv]        = Jacobi_Y( r_t,rv_x,rv_V,rr_param,r_omega0);
    %     [rm_Cix,rm_Div,rm_Diu] = Jacobi_I( r_t,rv_x,rv_V,rv_u,rr_param,r_omega0);
    % end



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
            obj.sct_stale      = struct("equilibrium", obj.s_notInitialized, "odefcn", obj.s_notInitialized);
            % tab_parameter columns:
            % - dynamics: model parameters, per unit on the system base; the sv_para columns are passed to the model functions
            % - operation: operating limits and rating: Pmin, Pmax, Qmin, Qmax [pu]: output limits (-Inf/Inf: none), also used by the "Qmax" rule of set_equilibrium; baseMVA [MVA]: rating, to share Q on a bus and exported to MATPOWER (not the system base)
            % - powerflow: P, Q [pu]: injection settings of the power flow (negative for a load); Q = NaN makes the bus a PV bus
            % - OPF: P0, Q0 [pu]: OPF initial values; HP, fP, HQ, fQ: cost coefficients (default 1, 1, 0, 0; 0 for a load); startup, shutdown: reserved
            % - graph: Xaxis, Yaxis, Marker, MidXaxis, MidYaxis: drawing data
            a_Pd = Parameter(obj,"dynamics");
            % Default cost (NaN): 0 for a load (a fixed load adds nothing to the cost), 1 otherwise
            r_cost0 = double(~isa(obj,"component.load.abstract"));
            if isnan(opt.OPFcost_HP); opt.OPFcost_HP = r_cost0; end
            if isnan(opt.OPFcost_fP); opt.OPFcost_fP = r_cost0; end

            a_Po = Parameter(obj, "operation", struct( ...
                "baseMVA", opt.baseMVA, ...
                   "Pmin", opt.Pmin, ...
                   "Pmax", opt.Pmax, ...
                   "Qmin", opt.Qmin, ...
                   "Qmax", opt.Qmax));
            a_Pp = Parameter(obj, "powerflow", struct( ...
                "P", opt.P, ...
                "Q", opt.Q));
            a_PO = Parameter(obj, "OPF", struct( ...
                      "P0", opt.OPFinit_P0, ...
                      "Q0", opt.OPFinit_Q0, ...
                      "HP", opt.OPFcost_HP, ...
                      "HQ", opt.OPFcost_HQ, ...
                      "fP", opt.OPFcost_fP, ...
                      "fQ", opt.OPFcost_fQ, ...
                 "startup", opt.OPFcost_startup, ...
                "shutdown", opt.OPFcost_shutdown));
            a_Pg = Parameter(obj, "graph", struct( ...
                   "Xaxis", opt.Xaxis, ...
                   "Yaxis", opt.Yaxis, ...
                  "Marker", opt.Marker, ...
                "MidXaxis", opt.MidXaxis, ...
                "MidYaxis", opt.MidYaxis));
            obj.a_Parameter = {a_Pd; a_Po; a_Pp; a_PO; a_Pg};
        end        

        set_odefcn(obj)
        handle_edit(obj, a_layer, tag, log)
        sct_page = gui_content(obj)
    end
            

%% Methods
    methods
        % Layer Structure
        con = add_local_controller(obj, Key, opt)
        remove_local_controller(obj, s_tag, opt)

        % get_sys
        [sys, varargout] = get_sys(obj, x, V, u, opt)

        % get dx, I and y
        DAEvec = get_dx_algebraic(obj, t, x, Vi, u, y, y_GC, DAEvec)

        % Steady State
        set_input(obj, rv_u)

    end
    methods(Hidden)
        % Debugger
        flag = validate(obj)
    end

    methods(Access={?Bus})
        initialize(obj)
        set_equilibrium(obj,c_V,c_I,r_P,r_Q,opt)
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
            p = [obj.a_LocalController; obj.a_Parameter];
        end
    end
end
